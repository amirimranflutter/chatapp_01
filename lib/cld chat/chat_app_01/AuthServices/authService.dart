import 'dart:io';
import 'package:imgbb_uploader/imgbb.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/userModel.dart';

class AuthRemoteService {
  final _supabase = Supabase.instance.client;
// Initialize the uploader with your API key
  final imgbbUploader = ImgbbUploader('5f7f1a6ac88c9fb95f0f940cd390b288');
  Future<UserModel?> signUp(String email, String password, String displayName, File? profileImage) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    // final user = response.user ?? response.session?.user;


    await _supabase.auth.refreshSession();
    final user = _supabase.auth.currentUser;
    await Future.delayed(const Duration(seconds: 1));
    if (user == null) throw Exception("Signup failed");
    String? avatarUrl;

    if (profileImage != null) {
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload image file to ImgBB
      final response = await imgbbUploader.uploadImageFile(
        imageFile: profileImage,  // Your File object
        name: fileName,
        expiration: 0,  // Set to 0 for no expiration, or specify seconds (60-15552000)
      );

      // Check if upload was successful
      if (response?.status == 200) {
        // Get the public URL
        avatarUrl = response?.data?.image?.url;
        print('signup ->> avatarUrl---->>>$avatarUrl');
        // Save avatarUrl to your local storage and remote database
        // Example: save to SharedPreferences or your backend
      } else {
        // Handle upload failure
        print('Upload failed');
      }
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
