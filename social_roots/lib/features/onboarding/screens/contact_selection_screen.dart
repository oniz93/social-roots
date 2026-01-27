import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';

// Selected contacts state
final selectedContactsProvider = StateProvider<Set<String>>((ref) => {});

class ContactSelectionScreen extends ConsumerStatefulWidget {
  const ContactSelectionScreen({super.key});

  @override
  ConsumerState<ContactSelectionScreen> createState() =>
      _ContactSelectionScreenState();
}

class _ContactSelectionScreenState
    extends ConsumerState<ContactSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final selectedContacts = ref.watch(selectedContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Core Circle'),
        actions: [
          if (selectedContacts.isNotEmpty)
            TextButton(
              onPressed: () => _proceedToQuiz(context),
              child: Text('Next (${selectedContacts.length})'),
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
                final filtered = _filterContacts(contacts);

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No contacts found'
                          : 'No contacts match "$_searchQuery"',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
                    final isSelected = selectedContacts.contains(contact.id);

                    return _ContactListItem(
                      contact: contact,
                      isSelected: isSelected,
                      onTap: () => _toggleContact(contact.id),
                    );
                  },
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
              onPressed: () => _proceedToQuiz(context),
              icon: const Icon(Icons.arrow_forward),
              label: Text('Continue with ${selectedContacts.length}'),
            )
          : null,
    );
  }

  List<Contact> _filterContacts(List<Contact> contacts) {
    if (_searchQuery.isEmpty) return contacts;

    final query = _searchQuery.toLowerCase();
    return contacts
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

  void _proceedToQuiz(BuildContext context) {
    Navigator.of(context).pushNamed('/plant-quiz');
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
