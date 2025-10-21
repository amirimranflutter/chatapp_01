// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../models/messageModel.dart';
//
// class MessageBubble extends StatelessWidget {
//   final MessageModel message;
//   final bool isMe;
//
//   const MessageBubble({
//     Key? key,
//     required this.message,
//     required this.isMe,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: isMe
//             ? MainAxisAlignment.end
//             : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!isMe) ...[
//             CircleAvatar(
//               radius: 16,
//               backgroundColor: Colors.grey[400],
//               backgroundImage: message.sender?.avatarUrl != null
//                   ? NetworkImage(message.sender!.avatarUrl!)
//                   : null,
//               child: message.sender?.avatarUrl == null
//                   ? Text(
//                 message.sender?.displayName[0].toUpperCase() ?? 'U',
//                 style: TextStyle(fontSize: 12),
//               )
//                   : null,
//             ),
//             SizedBox(width: 8),
//           ],
//           Flexible(
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue[600] : Colors.grey[200],
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                   bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
//                   bottomRight: isMe ? Radius.circular(4) : Radius.circular(20),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (!isMe && message.sender != null)
//                     Padding(
//                       padding: EdgeInsets.only(bottom: 4),
//                       child: Text(
//                         message.sender!.displayName,
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ),
//                   Text(
//                     message.content,
//                     style: TextStyle(
//                       color: isMe ? Colors.white : Colors.black87,
//                       fontSize: 16,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     DateFormat('HH:mm').format(message.createdAt),
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: isMe ? Colors.white70 : Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (isMe) ...[
//             SizedBox(width: 8),
//             CircleAvatar(
//               radius: 16,
//               backgroundColor: Colors.blue[700],
//               child: Text(
//                 'You'[0],
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }
