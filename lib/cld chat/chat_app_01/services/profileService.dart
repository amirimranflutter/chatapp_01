import 'dart:io';

import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/showSnackBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
   get supabase=>_supabase;
  Map<String, dynamic>? _currentProfile;

  Map<String, dynamic>? get currentProfile => _currentProfile;

  //fetch curren user profile from profile table
  Future<void> loadCurrentUserProfile(String? otherUser) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('User id is null in profile loadCurrentUser');
      return;
    }
    try {
      if(otherUser!=null){
        final profile = await _supabase
            .from('profiles')
            .select('id,display_name,avatar_url,email')
            .eq('id', userId)
            .single();
        _currentProfile = profile;
      }else{
      final profile = await _supabase
          .from('profiles')
          .select('id,display_name,avatar_url,email')
          .eq('id', userId)
          .single();
      _currentProfile = profile;
      notifyListeners();}
    } catch (e) {
      debugPrint('error fetching profile:$e');
    }
  }

  Future<void> updateDisplayName(String name, BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('User id is null in profile updateDisplayName');
      return;
    }
    try {
      final response = await _supabase
          .from('profiles')
          .update({'display_name': name})
          .eq('id', userId);
      if (response.error == null) {
        SnackbarService.showSuccess(context, "Profile sucessfully Updated");
      } else {
        SnackbarService.showError(
          context,
          'Faild to updated Profile : ${response.error!.message}',
        );
        print('Faild to updated Profile : ${response.error!.message}');
      }
      _currentProfile?['display_name'] = name;
      notifyListeners();
    } catch (e) {
      debugPrint('error update Profile:$e');
      SnackbarService.showError(context, 'Faild to updated Profile : $e');
      print('Faild to updated Profile : $e');
    }
  }

  //Update Avatar Url
  Future<void> updateAvatar(File avatarFile, BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('User id is null ');
      return;
    }
    try {
      //upload to supabase storage
      final path = 'avatar/$userId.png';
      await _supabase.storage
          .from('avatars')
          .upload(path, avatarFile, fileOptions: FileOptions(upsert: true));

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);
      if (publicUrl != null)
        SnackbarService.showSuccess(context, "avatar sucessfully Updated");
      _currentProfile?['avatar_url'] = publicUrl;
      notifyListeners();
    } catch (e) {
      print('error in profile Updateavatar $e');
      SnackbarService.showError(context, 'error in profile updateAvatar $e');
    }
  }


  //
  //

  //
  //
}
