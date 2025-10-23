import 'package:flutter/material.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyCalls = [
      {'name': 'Amir Imran', 'type': 'Incoming', 'time': 'Today, 11:45 AM'},
      {'name': 'Anza', 'type': 'Missed', 'time': 'Yesterday, 5:12 PM'},
      {'name': 'Ali Raza', 'type': 'Outgoing', 'time': 'Mon, 2:00 PM'},
      {'name': 'John Doe', 'type': 'Incoming', 'time': 'Sun, 8:45 PM'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        elevation: 1,
      ),
      body: ListView.separated(
        itemCount: dummyCalls.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final call = dummyCalls[index];
          final isMissed = call['type'] == 'Missed';

          return ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.green.withOpacity(0.15),
              child: Icon(
                Icons.phone,
                color: isMissed ? Colors.red : Colors.green,
              ),
            ),
            title: Text(call['name']!),
            subtitle: Text(
              '${call['type']} • ${call['time']}',
              style: TextStyle(
                color: isMissed ? Colors.redAccent : Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Call details: ${call['name']}')),
              );
            },
          );
        },
      ),
    );
  }
}
