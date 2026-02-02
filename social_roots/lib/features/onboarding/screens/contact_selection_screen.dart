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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Select Your Core Circle'),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
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
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            )
          else
            TextButton(
              onPressed: () => _createGardenAndProceed(context, []),
              child: const Text('Skip', style: TextStyle(color: Colors.white70)),
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
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
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade400),
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
                          style: const TextStyle(color: Colors.white54),
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
                      const Center(child: CircularProgressIndicator(color: Colors.green)),
                  error: (_, __) =>
                      const Center(child: Text('Error loading garden data', style: TextStyle(color: Colors.red))),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
              error: (e, _) =>
                  Center(child: Text('Error loading contacts: $e', style: const TextStyle(color: Colors.red))),
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
              icon: const Icon(Icons.check, color: Colors.white),
              backgroundColor: Colors.green,
              label: Text(
                _isProcessing
                    ? 'Processing...'
                    : (widget.isOnboarding
                          ? 'Next (${selectedContacts.length})'
                          : 'Create Garden (${selectedContacts.length})'),
                style: const TextStyle(color: Colors.white),
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

    // Update state with selected contacts (resets quiz index)
    ref.read(onboardingProvider.notifier).setSelectedContacts(selectedIds);

    if (widget.isOnboarding) {
      // Proceed to next step in onboarding flow
      ref.read(onboardingProvider.notifier).nextStep();
    } else {
      // Standalone mode: Navigate to Quiz Screen
      // Clear selection local state as we've passed it to provider
      ref.read(selectedContactsProvider.notifier).state = {};
      Navigator.of(context).pushNamed('/plant-quiz');
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
        backgroundColor: Colors.green.withOpacity(0.2),
        backgroundImage: contact.thumbnail != null
            ? MemoryImage(contact.thumbnail!)
            : null,
        child: contact.thumbnail == null
            ? Text(
                contact.displayName.isNotEmpty
                    ? contact.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.green),
              )
            : null,
      ),
      title: Text(contact.displayName, style: const TextStyle(color: Colors.white)),
      subtitle: contact.phones.isNotEmpty
          ? Text(contact.phones.first.number, style: const TextStyle(color: Colors.white54))
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) => onTap(),
        activeColor: Colors.green,
        side: const BorderSide(color: Colors.white54),
      ),
      onTap: onTap,
    );
  }
}