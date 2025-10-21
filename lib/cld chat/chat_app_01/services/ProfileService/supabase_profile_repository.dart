import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Utils/showSnackBar.dart';
import '../../models/userModel.dart';
import 'abstructClass/profile_repository_base.dart';

class SupabaseProfileRepository implements ProfileRepositoryBase {
  final _supabase = Supabase.instance.client;

  @override
  Future<UserModel?> getProfile(String userId, BuildContext context) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url, email, created_at')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        print('✅ [Remote] Profile fetched for $userId');
        SnackbarService.showSuccess(context, 'Profile fetched from Supabase');
        return UserModel.fromMap(response);
      } else {
        print('⚠️ [Remote] No profile found for $userId');
        return null;
      }
    } catch (e) {
      print('❌ [Remote] Error fetching profile: $e');
      SnackbarService.showError(context, 'Error fetching from Supabase: $e');
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserModel profile, BuildContext context) async {
    try {
      await _supabase.from('profiles').upsert(profile.toMap());
      print('✅ [Remote] Profile saved or updated to Supabase');
      SnackbarService.showSuccess(context, 'Profile saved to Supabase');
    } catch (e) {
      print('❌ [Remote] Error saving profile: $e');
      SnackbarService.showError(context, 'Error saving to Supabase: $e');
    }
  }
  @override
  Future<UserModel?> getProfileByEmail(String email, BuildContext context) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromMap(response);
      }
      return null;
    } catch (e) {
      SnackbarService.showError(context, 'Error fetching profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateDisplayName(String userId, String name, BuildContext context) async {
    try {
      await _supabase.from('profiles').update({'display_name': name}).eq('id', userId);
      print('✅ [Remote] Display name updated for $userId');
      SnackbarService.showSuccess(context, 'Remote display name updated');
    } catch (e) {
      print('❌ [Remote] Error updating display name: $e');
      SnackbarService.showError(context, 'Error updating name on Supabase: $e');
    }
  }

  @override
  Future<void> updateAvatar(String userId, String avatarUrlOrFile, BuildContext context) async {
    try {
      String avatarUrl;

      if (avatarUrlOrFile.startsWith('http')) {
        avatarUrl = avatarUrlOrFile;
      } else {
        final file = File(avatarUrlOrFile);
        final fileExt = avatarUrlOrFile.split('.').last;
        final fileName = 'avatar_$userId.$fileExt';
        final mimeType = lookupMimeType(avatarUrlOrFile);

        final storageResponse = await _supabase.storage
            .from('avatars')
            .upload(fileName, file, fileOptions: FileOptions(upsert: true, contentType: mimeType));

        if (storageResponse.isEmpty) throw Exception('Failed to upload avatar.');

        avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final response = await _supabase.from('profiles').update({'avatar_url': avatarUrl}).eq('id', userId);

      if (response.error != null) throw Exception('Failed to update avatar: ${response.error!.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating avatar: $e')));
      rethrow;
    }
  }
}
