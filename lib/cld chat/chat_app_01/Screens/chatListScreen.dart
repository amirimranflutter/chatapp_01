import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../databaseServices/authService.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    final dummyChats = [
      {'name': 'Amir Imran', 'lastMessage': 'Hey, how are you?', 'time': '10:30 AM'},
      {'name': 'Anza', 'lastMessage': 'Let’s meet tomorrow.', 'time': '09:15 AM'},
      {'name': 'Ali Raza', 'lastMessage': 'Send me the file.', 'time': 'Yesterday'},
      {'name': 'John Doe', 'lastMessage': 'Ok, done!', 'time': 'Mon'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 1,
        actions: [
          IconButton(onPressed: ()async{
            await authService.signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }, icon: Icon(Icons.logout)),
        ],
      ),
      body: ListView.separated(
        itemCount: dummyChats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final chat = dummyChats[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              child: Text(
                chat['name']![0],
                style: const TextStyle(fontSize: 20, color: Colors.blue),
              ),
            ),
            title: Text(
              chat['name']!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              chat['lastMessage']!,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              chat['time']!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Open chat with ${chat['name']}')),
              );
            },
          );
        },
      ),
    );
  }
}
