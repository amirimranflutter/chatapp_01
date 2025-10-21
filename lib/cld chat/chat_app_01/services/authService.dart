
import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../databaseServices/authDBService.dart';
class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _init();
  }

  void _init() {
    _currentUser = _supabase.auth.currentUser;
    _isLoading = false;
    notifyListeners();

    _supabase.auth.onAuthStateChange.listen((AuthState state) {
      _currentUser=state.session?.user;
      notifyListeners();
    });
  }





  Future<String?> signUp(String email, String password, String displayName) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      final user = response.user ?? response.session?.user;
      if (user != null) {
        // Create user profile
        await _supabase.from('profiles').insert({
          'id': user.id,
          'display_name': displayName,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      if (response.user!= null) {
        final hiveAuth = HiveAuthService();
        hiveAuth.saveSession(
          userId: response.user!.id,
          email: response.user!.email ?? 'email',
          token: response.session!.accessToken,
        );
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      print("Login press------");
      final response =await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response != null) {
        final hiveAuth = HiveAuthService();
        hiveAuth.saveSession(
          userId: response.user!.id,
          email: response.user!.email ?? 'email',
          token: response.session!.accessToken,
        );
        print('response====>>>>>$response');
        return null;
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (_currentUser == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', _currentUser!.id)
        .maybeSingle();

    return response;
  }

}
