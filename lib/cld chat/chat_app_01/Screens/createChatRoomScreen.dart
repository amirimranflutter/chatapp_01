// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/chatService.dart';
// import '../Utils/showSnackBar.dart';
//
// class CreateChatRoomScreen extends StatefulWidget {
//   const CreateChatRoomScreen({super.key});
//
//   @override
//   State<CreateChatRoomScreen> createState() => _CreateChatRoomScreenState();
// }
//
// class _CreateChatRoomScreenState extends State<CreateChatRoomScreen> {
//   final _nameController = TextEditingController();
//   final List<String> _selectedContacts = [];
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadContacts();
//   }
//
//   Future<void> _loadContacts() async {
//     final contactService = Provider.of<ContactService>(context, listen: false);
//     await contactService.getAllContacts();
//     await contactService.syncPendingContacts(context); // optional
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Consumer2<ChatService, ContactService>(
//       builder: (context, chatService, contactService, _) {
//         final contacts = contactService.contacts;
//
//         return Scaffold(
//           appBar: AppBar(
//             title: const Text('Create Chat Room'),
//             actions: [
//               TextButton(
//                 onPressed:
//                 _selectedContacts.isNotEmpty && !_isLoading ? _createChatRoom : null,
//                 child: _isLoading
//                     ? const SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//                     : Text(
//                   'Create',
//                   style: TextStyle(
//                     color: _selectedContacts.isNotEmpty
//                         ? Colors.white
//                         : Colors.white54,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           body: Column(
//             children: [
//               // Chat Room Name Input
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: TextField(
//                   controller: _nameController,
//                   decoration: InputDecoration(
//                     labelText: 'Chat Room Name',
//                     filled: true,
//                     fillColor: theme.colorScheme.secondaryContainer,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Contacts Header
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     'Select Contacts',
//                     style: theme.textTheme.titleMedium
//                         ?.copyWith(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               // Contacts List
//               Expanded(
//                 child: contacts.isEmpty
//                     ? const Center(child: Text("No contacts available"))
//                     : RefreshIndicator(
//                   onRefresh: () async {
//                     await contactService.syncPendingContacts(context);
//                   },
//                   child: ListView.builder(
//                     itemCount: contacts.length,
//                     itemBuilder: (context, index) {
//                       final contact = contacts[index];
//                       final id = contact.localId;
//                       final isSelected = _selectedContacts.contains(id);
//
//                       return CheckboxListTile(
//                         value: isSelected,
//                         onChanged: (value) {
//                           setState(() {
//                             if (value == true) {
//                               _selectedContacts.add(id);
//                             } else {
//                               _selectedContacts.remove(id);
//                             }
//                           });
//                         },
//                         title: Text(contact.name ?? contact.email),
//                         subtitle: Text(contact.isSynced
//                             ? "Synced"
//                             : "Pending Sync"),
//                         secondary: CircleAvatar(
//                           backgroundImage: contact.avatarUrl != null
//                               ? NetworkImage(contact.avatarUrl!)
//                               : null,
//                           child: contact.avatarUrl == null
//                               ? Text(
//                             contact.email.isNotEmpty
//                                 ? contact.email[0].toUpperCase()
//                                 : '?',
//                           )
//                               : null,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _createChatRoom() async {
//     final roomName = _nameController.text.trim();
//
//     if (roomName.isEmpty) {
//       SnackbarService.showError(context, "Please enter a chat room name");
//       return;
//     }
//
//     if (_selectedContacts.isEmpty) {
//       SnackbarService.showError(context, "Select at least one contact");
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       final chatService = Provider.of<ChatService>(context, listen: false);
//       final error = await chatService.createChatRoom(roomName, _selectedContacts);
//
//       if (error != null) {
//         SnackbarService.showError(context, error);
//       } else {
//         SnackbarService.showSuccess(context, "Chat room created successfully");
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       SnackbarService.showError(context, "Failed to create chat room: $e");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
// }
