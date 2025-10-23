import 'package:chat_app_cld/cld%20chat/chat_app_01/Providers/profileProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.service.loadUserProfile(); // ✅ Load profile when screen opens
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.service.currentProfile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 10),
          Text(profile.displayName ?? "No name"),
          Text(profile.email ?? "No email"),
        ],
      ),
    );
  }
}
