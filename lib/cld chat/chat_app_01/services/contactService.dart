import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter/foundation.dart';
class ContactService extends ChangeNotifier{
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> get contacts => _contacts;

  List<Map<String, dynamic>> _contacts = [];


  Future<List<Map<String, dynamic>>> loadContacts() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];
    try {
      final response = await _supabase
          .from('contacts')
          .select(
        'id, contact_id, profile:profiles!inner(id,display_name, avatar_url, email)',
      )
          .eq('user_id', currentUserId);
      // print("response --->>>$response");
      _contacts = List<Map<String, dynamic>>.from(response as List);
      notifyListeners();
      return _contacts;
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }
  Future<String?> removeContact(String contactId) async {
    final String? id = _supabase.auth.currentUser?.id;
    if (id == null) return 'Not authenticated';

    final String currentUserId = id;
    try {
      // ✅ Delete contact from "contacts" table
      await _supabase
          .from('contacts')
          .delete()
          .eq('contact_id', contactId)
          .eq('user_id', currentUserId);

      // ✅ Remove from local list if you're storing it
      _contacts.removeWhere((c) => c['contact_id'] == contactId);
      notifyListeners();
      loadContacts();
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}