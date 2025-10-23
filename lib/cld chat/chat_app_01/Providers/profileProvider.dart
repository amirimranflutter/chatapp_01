import 'package:flutter/material.dart';

import '../services/ProfileService/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();
  ProfileService get service => _service;
}
