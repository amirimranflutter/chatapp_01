

import 'package:flutter/material.dart';
import '../models/messageModel.dart';
import '../services/MessageServices/messageRepository.dart';

class ChatProvider extends ChangeNotifier {
  final MessageRepository _repo;

  /// store messages for the current chat screen
  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  /// current logged-in userId (you can inject this or fetch from auth)
  final String currentUserId;

  ChatProvider(this._repo, {required this.currentUserId});

  /// Load local messages for a specific contact
  void loadMessages(String contactId) {
    _messages = _repo.getLocalMessages(currentUserId, contactId);
    notifyListeners();
  }

  /// Send a new message
  Future<void> sendMessage(String text, String contactId) async {
    final newMessage = MessageModel.create(
      senderId: currentUserId,
      receiverId: contactId,
      text: text,
    );

    await _repo.sendMessage(newMessage);

    _messages.add(newMessage);
    notifyListeners();
  }

  /// Sync from remote to local (manual pull if needed)
  Future<void> fetchRemoteMessages(String contactId) async {
    await _repo.syncFromServer(currentUserId, contactId);
    loadMessages(contactId);
  }

  /// Push unsynced messages to remote (optional background trigger)
  Future<void> syncPendingMessages() async {
    await _repo.syncPending();
  }
}
