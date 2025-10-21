import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/userModel.dart';
import '../services/ProfileService/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  File? _avatarFile;
  bool isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final currentUserId = profileService.currentProfile?.id;
    isOwnProfile = widget.userId == currentUserId;

    // Load profile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await profileService.loadCurrentUserProfile(context, forceRefresh: true);
      final user = profileService.currentProfile;
      if (user != null) _nameController.text = user.displayName;
      setState(() {}); // Refresh UI
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileService>(
      builder: (context, profileService, _) {
        final UserModel? user = profileService.currentProfile;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isOwnProfile ? 'My Profile' : user.displayName),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: isOwnProfile ? _pickAvatar : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarFile != null
                        ? FileImage(_avatarFile!)
                        : (user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null) as ImageProvider<Object>?,
                    child: (_avatarFile == null && user.avatarUrl == null)
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Display Name
                TextField(
                  controller: _nameController,
                  enabled: isOwnProfile,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                const SizedBox(height: 16),

                // Save Button
                if (isOwnProfile)
                  ElevatedButton(
                    onPressed: () async {
                      final newName = _nameController.text.trim();
                      if (newName.isNotEmpty) {
                        await profileService.updateDisplayName(newName, context);
                      }
                      if (_avatarFile != null) {
                        await profileService.updateAvatar(_avatarFile!, context);
                        setState(() {
                          _avatarFile = null; // reset after upload
                        });
                      }
                    },
                    child: const Text('Save'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
