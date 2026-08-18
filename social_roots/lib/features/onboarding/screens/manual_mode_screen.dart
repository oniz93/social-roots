import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/contact_service.dart';
import '../providers/onboarding_provider.dart';

// Manual contacts state
final manualContactsProvider = StateProvider<List<ManualContact>>((ref) => []);

class ManualContact {
  final String id;
  final String name;
  final String? phone;
  final String? email;

  ManualContact({required this.id, required this.name, this.phone, this.email});
}

class ManualModeScreen extends ConsumerStatefulWidget {
  const ManualModeScreen({super.key});

  @override
  ConsumerState<ManualModeScreen> createState() => _ManualModeScreenState();
}

class _ManualModeScreenState extends ConsumerState<ManualModeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manualContacts = ref.watch(manualContactsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Contacts Manually'),
        actions: [
          if (manualContacts.isNotEmpty)
            TextButton(
              onPressed: () => _proceedToQuiz(context),
              child: Text(
                'Next (${manualContacts.length})',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Add contact form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Name *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Phone (optional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email (optional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Contact'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white10),

          // Added contacts list
          Expanded(
            child: manualContacts.isEmpty
                ? Center(
                    child: Text(
                      'No contacts added yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    itemCount: manualContacts.length,
                    itemBuilder: (context, index) {
                      final contact = manualContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          child: Text(
                            contact.name.isNotEmpty
                                ? contact.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        title: Text(
                          contact.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          contact.phone ?? contact.email ?? '',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white54),
                          onPressed: () => _removeContact(contact.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: manualContacts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _proceedToQuiz(context),
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              backgroundColor: Colors.green,
              label: Text(
                'Continue with ${manualContacts.length}',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  void _addContact() {
    if (_formKey.currentState!.validate()) {
      final contact = ManualContact(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      );

      ref
          .read(manualContactsProvider.notifier)
          .update((state) => [...state, contact]);

      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
    }
  }

  void _removeContact(String id) {
    ref
        .read(manualContactsProvider.notifier)
        .update((state) => state.where((c) => c.id != id).toList());
  }

  void _proceedToQuiz(BuildContext context) {
    final manualContacts = ref.read(manualContactsProvider);
    final contactService = ref.read(contactServiceProvider);

    // Register manual contacts and collect their IDs
    final selectedIds = <String>{};
    for (final mc in manualContacts) {
      final contact = Contact(
        id: mc.id,
        displayName: mc.name,
        phones: mc.phone != null ? [Phone(number: mc.phone!)] : [],
        emails: mc.email != null ? [Email(address: mc.email!)] : [],
      );
      contactService.addManualContact(contact);
      selectedIds.add(mc.id);
    }

    // Set the selected contacts in the onboarding provider
    ref.read(onboardingProvider.notifier).setSelectedContacts(selectedIds);

    Navigator.of(context).pushNamed('/plant-quiz');
  }
}
