import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../Utils/showSnackBar.dart';
import '../../models/userModel.dart';

import 'abstructClass/profile_repository_base.dart';

class LocalProfileRepository extends ProfileRepositoryBase {
  final String _boxName = 'profilesBox';

  Future<Box> _openBox() async => await Hive.openBox<Map>(_boxName);

  @override
  Future<UserModel?> getProfile(String userId, BuildContext context) async {
    try {
      final box = await _openBox();
      final data = box.get(userId)?.cast<String, dynamic>();
      if (data != null) {
        print('✅ [Local] Profile loaded for $userId');
        SnackbarService.showSuccess(context, 'Loaded from local storage');
        return UserModel.fromMap(data);
      } else {
        print('⚠️ [Local] No profile found for $userId');
        return null;
      }
    } catch (e) {
      print('❌ [Local] Error loading profile: $e');
      SnackbarService.showError(context, 'Error loading from local: $e');
      return null;
    }
  }
  @override
  Future<UserModel?> getProfileByEmail(String email, BuildContext context) async {
    try {
      final box = await _openBox();
      final profile = box.values
          .map((e) => UserModel.fromMap(Map<String, dynamic>.from(e)))
          .firstWhere((u) => u.email == email, orElse: () => UserModel(
          id: '', displayName: '', email: '', avatarUrl: null, createdAt: DateTime.now()
      ),);

      return profile;
    } catch (e) {
      SnackbarService.showError(context, 'Error loading profile: $e');
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserModel profile, BuildContext context) async {
    try {
      final box = await _openBox();
      await box.put(profile.id, profile.toMap());
      print('✅ [Local] Profile saved for ${profile.id}');
      SnackbarService.showSuccess(context, 'Profile saved locally');
    } catch (e) {
      print('❌ [Local] Error saving profile: $e');
      SnackbarService.showError(context, 'Error saving locally: $e');
    }
  }

  @override
  Future<void> updateDisplayName(String userId, String name, BuildContext context) async {
    try {
      final box = await _openBox();
      final data = box.get(userId)?.cast<String, dynamic>() ?? {};
      final profile = data.isNotEmpty ? UserModel.fromMap(data) : null;

      if (profile != null) {
        final updatedProfile = UserModel(
          id: profile.id,
          displayName: name,
          email: profile.email,
          avatarUrl: profile.avatarUrl,
          createdAt: profile.createdAt,
        );
        await box.put(userId, updatedProfile.toMap());
        print('✅ [Local] Display name updated for $userId');
        SnackbarService.showSuccess(context, 'Local name updated');
      }
    } catch (e) {
      print('❌ [Local] Error updating display name: $e');
      SnackbarService.showError(context, 'Error updating local name: $e');
    }
  }

  @override
  Future<void> updateAvatar(String userId, String avatarUrl, BuildContext context) async {
    try {
      final box = await _openBox();
      final data = box.get(userId)?.cast<String, dynamic>() ?? {};
      final profile = data.isNotEmpty ? UserModel.fromMap(data) : null;

      if (profile != null) {
        final updatedProfile = UserModel(
          id: profile.id,
          displayName: profile.displayName,
          email: profile.email,
          avatarUrl: avatarUrl,
          createdAt: profile.createdAt,
        );
        await box.put(userId, updatedProfile.toMap());
        print('✅ [Local] Avatar updated for $userId');
        SnackbarService.showSuccess(context, 'Local avatar updated');
      }
    } catch (e) {
      print('❌ [Local] Error updating avatar: $e');
      SnackbarService.showError(context, 'Error updating local avatar: $e');
    }
  }
}
