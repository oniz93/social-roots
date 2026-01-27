import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';
import '../../../data/models/plant.dart';
import '../../../data/repositories/plant_repository.dart';
import '../providers/onboarding_provider.dart';

// Selected contacts state
final selectedContactsProvider = StateProvider<Set<String>>((ref) => {});

class ContactSelectionScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;

  const ContactSelectionScreen({super.key, this.isOnboarding = false});

  @override
  ConsumerState<ContactSelectionScreen> createState() =>
      _ContactSelectionScreenState();
}

class _ContactSelectionScreenState
    extends ConsumerState<ContactSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final plantsAsync = ref.watch(plantsStreamProvider);
    final selectedContacts = ref.watch(selectedContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Core Circle'),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (selectedContacts.isNotEmpty)
            TextButton(
              onPressed: () =>
                  _createGardenAndProceed(context, contactsAsync.value ?? []),
              child: Text(
                widget.isOnboarding
                    ? 'Next (${selectedContacts.length})'
                    : 'Finish (${selectedContacts.length})',
              ),
            )
          else
            TextButton(
              onPressed: () => _createGardenAndProceed(context, []),
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Help text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Select the people you want to stay connected with. You can add more later.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),

          const SizedBox(height: 8),

          // Contact list
          Expanded(
            child: contactsAsync.when(
              data: (contacts) {
                // Wait for plants to load to ensure filtering is correct
                return plantsAsync.when(
                  data: (plants) {
                    final existingContactIds = plants
                        .map((p) => p.contactId)
                        .toSet();
                    final filtered = _filterContacts(
                      contacts,
                      existingContactIds,
                    );

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No new contacts found'
                              : 'No contacts match "$_searchQuery"',
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final contact = filtered[index];
                        final isSelected = selectedContacts.contains(
                          contact.id,
                        );

                        return _ContactListItem(
                          contact: contact,
                          isSelected: isSelected,
                          onTap: () => _toggleContact(contact.id),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Error loading garden data')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error loading contacts: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: selectedContacts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isProcessing
                  ? null
                  : () => _createGardenAndProceed(
                      context,
                      contactsAsync.value ?? [],
                    ),
              icon: const Icon(Icons.check),
              label: Text(
                _isProcessing
                    ? 'Processing...'
                    : (widget.isOnboarding
                          ? 'Next (${selectedContacts.length})'
                          : 'Create Garden (${selectedContacts.length})'),
              ),
            )
          : null,
    );
  }

  List<Contact> _filterContacts(
    List<Contact> contacts,
    Set<String> existingContactIds,
  ) {
    var filtered = contacts;

    // Filter out existing plants
    if (existingContactIds.isNotEmpty) {
      filtered = filtered
          .where((c) => !existingContactIds.contains(c.id))
          .toList();
    }

    if (_searchQuery.isEmpty) return filtered;

    final query = _searchQuery.toLowerCase();
    return filtered
        .where((c) => c.displayName.toLowerCase().contains(query))
        .toList();
  }

  void _toggleContact(String contactId) {
    final notifier = ref.read(selectedContactsProvider.notifier);
    final current = ref.read(selectedContactsProvider);

    if (current.contains(contactId)) {
      notifier.state = {...current}..remove(contactId);
    } else {
      notifier.state = {...current, contactId};
    }
  }

  Future<void> _createGardenAndProceed(
    BuildContext context,
    List<Contact> allContacts,
  ) async {
    final selectedIds = ref.read(selectedContactsProvider);

    if (widget.isOnboarding) {
      // Update onboarding state and proceed to quiz
      ref.read(onboardingProvider.notifier).setSelectedContacts(selectedIds);
      ref.read(onboardingProvider.notifier).nextStep();
      return;
    }

    // Standalone mode: Create plants immediately
    setState(() => _isProcessing = true);
    final repository = ref.read(plantRepositoryProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      for (final id in selectedIds) {
        final contact = allContacts.firstWhere(
          (c) => c.id == id,
          orElse: () => Contact(id: id, displayName: 'Unknown'),
        );

        await repository.createPlant(
          contactId: contact.id,
          displayName: contact.displayName,
          plantType: PlantType.succulent,
          difficultyLevel: 1,
          photoUrl: null, // TODO: Handle photo persistence
        );
      }

      if (mounted) {
        // Clear selection
        ref.read(selectedContactsProvider.notifier).state = {};

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Garden updated successfully!')),
        );

        // Return to previous screen (Garden)
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error creating garden: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _ContactListItem extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactListItem({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: contact.thumbnail != null
            ? MemoryImage(contact.thumbnail!)
            : null,
        child: contact.thumbnail == null
            ? Text(
                contact.displayName.isNotEmpty
                    ? contact.displayName[0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Text(contact.displayName),
      subtitle: contact.phones.isNotEmpty
          ? Text(contact.phones.first.number)
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) => onTap(),
        activeColor: Colors.green,
      ),
      onTap: onTap,
    );
  }
}
