import 'dart:io';
import 'package:flutter/material.dart';

import '../../../models/userModel.dart';

abstract class ProfileRepositoryBase {
  Future<UserModel?> getProfile(String userId, BuildContext context);
  Future<void> saveProfile(UserModel profile, BuildContext context);
  Future<void> updateDisplayName(String userId, String name, BuildContext context);
  Future<void> updateAvatar(String userId, String avatarUrlOrFile, BuildContext context);
  Future<UserModel?> getProfileByEmail(String email, BuildContext context);
}
