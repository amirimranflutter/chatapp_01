import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileLookupService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static User? get currentUser =>  Supabase.instance.client.auth.currentUser;

  /// Fetch user profile (id, name, email) from `profiles` table by email.
  Future<Map<String, dynamic>?> getProfileByEmail(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, email,avatar_url')
          .eq('email', email)
          .maybeSingle(); // ✅ Directly returns the row or null

      if (response == null) {
        print('⚠️ No user found for email: $email');
        return null;
      }

      print('✅ Profile found: $response');
      return response; // a map like {'id': ..., 'name': ..., 'email': ...}

    } catch (e) {
      print('❌ Error fetching profile by email: $e');
      return null;
    }
  }
}
