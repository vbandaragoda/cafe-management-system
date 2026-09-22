import 'package:flutter_contacts/flutter_contacts.dart';

/// Explicit stored-contacts access, used by the Profile screen's
/// "Invite a Friend" feature — requests contacts permission and lets
/// the customer pick someone from their device's address book to send
/// a referral message to (a real system contact picker, not a mock).
class ContactsService {
  Future<bool> requestPermission() => FlutterContacts.requestPermission(readonly: true);

  Future<List<Contact>> pickableContacts() async {
    final granted = await requestPermission();
    if (!granted) return [];
    return FlutterContacts.getContacts(withProperties: true, withPhoto: false);
  }
}
