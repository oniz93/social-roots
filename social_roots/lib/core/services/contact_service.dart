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
  /// Local cache for manually added contacts
  final Map<String, Contact> _manualContacts = {};

  void addManualContact(Contact contact) {
    final id = contact.id;
    if (id == null) return;
    _manualContacts[id] = contact;
  }

  /// Check current permission status
  Future<ContactPermissionStatus> checkPermission() async {
    final status = await Permission.contacts.status;

    if (status.isGranted) return ContactPermissionStatus.granted;
    if (status.isDenied) return ContactPermissionStatus.denied;
    if (status.isPermanentlyDenied) {
      return ContactPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return ContactPermissionStatus.restricted;
    return ContactPermissionStatus.notDetermined;
  }

  /// Request contact permission
  Future<ContactPermissionStatus> requestPermission() async {
    final status = await Permission.contacts.request();

    if (status.isGranted) return ContactPermissionStatus.granted;
    if (status.isDenied) return ContactPermissionStatus.denied;
    if (status.isPermanentlyDenied) {
      return ContactPermissionStatus.permanentlyDenied;
    }
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

    return await FlutterContacts.getAll(
      properties: {
        ...ContactProperties.allProperties,
        ContactProperty.photoThumbnail,
      },
    );
  }

  /// Search contacts by name
  Future<List<Contact>> searchContacts(String query) async {
    final allContacts = await getAllContacts();
    final lowerQuery = query.toLowerCase();

    return allContacts.where((contact) {
      final name = (contact.displayName ?? '').toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  /// Get a specific contact by ID
  Future<Contact?> getContact(String id) async {
    if (_manualContacts.containsKey(id)) {
      return _manualContacts[id];
    }

    try {
      return await FlutterContacts.get(
        id,
        properties: {
          ...ContactProperties.allProperties,
          ContactProperty.photoThumbnail,
        },
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
      (p) => p.label.label == PhoneLabel.mobile,
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
    contacts.sort(
      (a, b) =>
          (a.displayName ?? '').toLowerCase().compareTo(
            (b.displayName ?? '').toLowerCase(),
          ),
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
final contactPermissionProvider =
    StateNotifierProvider<ContactPermissionNotifier, ContactPermissionStatus>((
      ref,
    ) {
      return ContactPermissionNotifier(ref.read(contactServiceProvider));
    });

class ContactPermissionNotifier extends StateNotifier<ContactPermissionStatus> {
  final ContactService _service;

  ContactPermissionNotifier(this._service)
    : super(ContactPermissionStatus.notDetermined) {
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
