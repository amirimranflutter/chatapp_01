import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/userModel.dart';

class AuthRemoteService {
  final _supabase = Supabase.instance.client;

  Future<UserModel?> signUp(String email, String password, String displayName, File? profileImage) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    final user = response.user ?? response.session?.user;
    if (user == null) throw Exception("Signup failed");

    String? avatarUrl;
    if (profileImage != null) {
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('image').upload(fileName, profileImage);
      avatarUrl = _supabase.storage.from('image').getPublicUrl(fileName);
    }

    final profile = {
      'id': user.id,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('profiles').insert(profile);

    return UserModel.fromMap(profile);
  }

  Future<UserModel?> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception("Invalid login");

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) throw Exception("User profile not found");

    return UserModel.fromMap(profile);
  }

  Future<void> signOut() async => await _supabase.auth.signOut();
}
