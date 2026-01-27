# Task 03: Contact Permission & Import

## Priority: HIGH
## Estimated Time: 3-4 hours
## Platform Focus: iOS First

---

## Objective
Implement contact permission handling and contact import functionality with proper iOS privacy compliance.

---

## Context
Social Roots needs access to the user's contacts to create plants. This is a sensitive permission that requires:
- Clear privacy messaging
- Graceful handling of permission denial
- Manual mode fallback for users who deny access

### Privacy Requirements
- Contact data is processed locally only
- No contact data is sent to external servers
- User must be informed before permission request

---

## Implementation

### 1. Contact Service (`lib/core/services/contact_service.dart`)
```dart
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ContactPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  notDetermined,
}

class ContactService {
  /// Check current permission status
  Future<ContactPermissionStatus> checkPermission() async {
    final status = await Permission.contacts.status;
    
    if (status.isGranted) return ContactPermissionStatus.granted;
    if (status.isDenied) return ContactPermissionStatus.denied;
    if (status.isPermanentlyDenied) return ContactPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return ContactPermissionStatus.restricted;
    return ContactPermissionStatus.notDetermined;
  }
  
  /// Request contact permission
  Future<ContactPermissionStatus> requestPermission() async {
    final status = await Permission.contacts.request();
    
    if (status.isGranted) return ContactPermissionStatus.granted;
    if (status.isDenied) return ContactPermissionStatus.denied;
    if (status.isPermanentlyDenied) return ContactPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return ContactPermissionStatus.restricted;
    return ContactPermissionStatus.notDetermined;
  }
  
  /// Open app settings for manual permission grant
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
  
  /// Fetch all contacts from device
  Future<List<Contact>> getAllContacts() async {
    final status = await checkPermission();
    if (status != ContactPermissionStatus.granted) {
      throw ContactPermissionException('Contact permission not granted');
    }
    
    return await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
      withThumbnail: true,
    );
  }
  
  /// Search contacts by name
  Future<List<Contact>> searchContacts(String query) async {
    final allContacts = await getAllContacts();
    final lowerQuery = query.toLowerCase();
    
    return allContacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }
  
  /// Get a specific contact by ID
  Future<Contact?> getContact(String id) async {
    try {
      return await FlutterContacts.getContact(
        id,
        withProperties: true,
        withPhoto: true,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get contact's primary phone number
  String? getPrimaryPhone(Contact contact) {
    if (contact.phones.isEmpty) return null;
    
    // Prefer mobile numbers
    final mobile = contact.phones.firstWhere(
      (p) => p.label == PhoneLabel.mobile,
      orElse: () => contact.phones.first,
    );
    
    return mobile.number;
  }
  
  /// Get contact's primary email
  String? getPrimaryEmail(Contact contact) {
    if (contact.emails.isEmpty) return null;
    return contact.emails.first.address;
  }
  
  /// Sort contacts by most likely importance
  /// (This is a heuristic based on available data)
  List<Contact> sortByImportance(List<Contact> contacts) {
    // For now, just sort alphabetically
    // iOS doesn't expose contact frequency data
    contacts.sort((a, b) => 
      a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase())
    );
    return contacts;
  }
}

class ContactPermissionException implements Exception {
  final String message;
  ContactPermissionException(this.message);
  
  @override
  String toString() => 'ContactPermissionException: $message';
}

final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

// State provider for permission status
final contactPermissionProvider = StateNotifierProvider<ContactPermissionNotifier, ContactPermissionStatus>((ref) {
  return ContactPermissionNotifier(ref.read(contactServiceProvider));
});

class ContactPermissionNotifier extends StateNotifier<ContactPermissionStatus> {
  final ContactService _service;
  
  ContactPermissionNotifier(this._service) : super(ContactPermissionStatus.notDetermined) {
    _checkInitialStatus();
  }
  
  Future<void> _checkInitialStatus() async {
    state = await _service.checkPermission();
  }
  
  Future<void> requestPermission() async {
    state = await _service.requestPermission();
  }
  
  Future<void> refresh() async {
    state = await _service.checkPermission();
  }
}

// Provider for fetching contacts
final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  final permission = ref.watch(contactPermissionProvider);
  if (permission != ContactPermissionStatus.granted) {
    return [];
  }
  
  final service = ref.read(contactServiceProvider);
  return service.getAllContacts();
});
```

### 2. Permission Request Screen (`lib/features/onboarding/screens/permission_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';

class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatus = ref.watch(contactPermissionProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Garden illustration
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_florist,
                  size: 100,
                  color: Colors.green.shade700,
                ),
              ),
              
              const SizedBox(height: 48),
              
              Text(
                'Plant Your First Seeds',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Social Roots needs access to your contacts to create your digital garden. Each contact becomes a unique plant that you\'ll nurture.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Privacy assurance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your contacts stay on your device. We never upload or sell your data.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Action buttons based on status
              _buildActionButton(context, ref, permissionStatus),
              
              const SizedBox(height: 16),
              
              // Manual mode option
              TextButton(
                onPressed: () => _enterManualMode(context),
                child: const Text('Or enter contacts manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    ContactPermissionStatus status,
  ) {
    switch (status) {
      case ContactPermissionStatus.notDetermined:
      case ContactPermissionStatus.denied:
        return ElevatedButton(
          onPressed: () => _requestPermission(ref),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: Colors.green,
          ),
          child: const Text(
            'Allow Contact Access',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        );
        
      case ContactPermissionStatus.permanentlyDenied:
        return Column(
          children: [
            Text(
              'Permission was denied. Please enable it in Settings.',
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openSettings(ref),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
        
      case ContactPermissionStatus.granted:
        // Navigate to contact selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/contact-selection');
        });
        return const CircularProgressIndicator();
        
      case ContactPermissionStatus.restricted:
        return Text(
          'Contact access is restricted on this device. You can still use Manual Mode.',
          style: TextStyle(color: Colors.orange.shade700),
          textAlign: TextAlign.center,
        );
    }
  }
  
  Future<void> _requestPermission(WidgetRef ref) async {
    await ref.read(contactPermissionProvider.notifier).requestPermission();
  }
  
  Future<void> _openSettings(WidgetRef ref) async {
    final service = ref.read(contactServiceProvider);
    await service.openSettings();
    // Refresh status when user returns
    await ref.read(contactPermissionProvider.notifier).refresh();
  }
  
  void _enterManualMode(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/manual-mode');
  }
}
```

### 3. Contact Selection Screen (`lib/features/onboarding/screens/contact_selection_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contact_service.dart';
import '../../../data/models/plant.dart';

// Selected contacts state
final selectedContactsProvider = StateProvider<Set<String>>((ref) => {});

class ContactSelectionScreen extends ConsumerStatefulWidget {
  const ContactSelectionScreen({super.key});

  @override
  ConsumerState<ContactSelectionScreen> createState() => _ContactSelectionScreenState();
}

class _ContactSelectionScreenState extends ConsumerState<ContactSelectionScreen> {
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
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
              error: (e, _) => Center(child: Text('Error loading contacts: $e')),
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
    return contacts.where((c) => 
      c.displayName.toLowerCase().contains(query)
    ).toList();
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
            ? Text(contact.displayName.isNotEmpty 
                ? contact.displayName[0].toUpperCase()
                : '?')
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
```

### 4. Manual Mode Screen (`lib/features/onboarding/screens/manual_mode_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/plant.dart';

// Manual contacts state
final manualContactsProvider = StateProvider<List<ManualContact>>((ref) => []);

class ManualContact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  
  ManualContact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });
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
      appBar: AppBar(
        title: const Text('Add Contacts Manually'),
        actions: [
          if (manualContacts.isNotEmpty)
            TextButton(
              onPressed: () => _proceedToQuiz(context),
              child: Text('Next (${manualContacts.length})'),
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
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'Phone (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                      border: OutlineInputBorder(),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(),
          
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
                          child: Text(contact.name[0].toUpperCase()),
                        ),
                        title: Text(contact.name),
                        subtitle: Text(contact.phone ?? contact.email ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
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
              icon: const Icon(Icons.arrow_forward),
              label: Text('Continue with ${manualContacts.length}'),
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
      
      ref.read(manualContactsProvider.notifier).update((state) => [...state, contact]);
      
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
    }
  }
  
  void _removeContact(String id) {
    ref.read(manualContactsProvider.notifier).update(
      (state) => state.where((c) => c.id != id).toList(),
    );
  }
  
  void _proceedToQuiz(BuildContext context) {
    Navigator.of(context).pushNamed('/plant-quiz');
  }
}
```

---

## Acceptance Criteria
- [ ] Contact permission request shows privacy-focused messaging
- [ ] Permission denial handled gracefully with option to try again
- [ ] Permanently denied permission shows "Open Settings" button
- [ ] Contact list loads and displays with photos
- [ ] Search functionality filters contacts in real-time
- [ ] Multiple contacts can be selected
- [ ] Manual mode allows adding contacts without permission
- [ ] Selected contacts persist when navigating to quiz

---

## iOS-Specific Notes
- Info.plist must have `NSContactsUsageDescription` key
- iOS 14+ requires explicit permission request
- Contact photos may not be available for all contacts
- Contact frequency data is NOT available on iOS (unlike Android)

---

## Dependencies
- Task 01: Project Setup
- Task 02: Data Models

## Blocks
- Task 09: Onboarding Flow (Plant Quiz)
