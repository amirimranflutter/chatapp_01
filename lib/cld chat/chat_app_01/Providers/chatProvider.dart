// Providers/chatProvider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/messageModel.dart';
import '../services/ChatRoomService/syncService.dart';
import '../services/MessageServices/messageRepository.dart';


class ChatProvider extends ChangeNotifier {
  final SyncMessageService _syncMessageService;
  final ChatRoomSyncService _chatRoomSyncService;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Store messages for the current chat screen
  List<Message> _messages = [];
  List<Message> get messages => _messages;

  /// Current logged-in userId
  final String currentUserId;

  /// Real-time subscription
  RealtimeChannel? _messageSubscription;

  /// Current active chat room ID
  String? _currentChatId;

  /// Loading states
  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  ChatProvider(
      this._syncMessageService,
      this._chatRoomSyncService, {
        required this.currentUserId,
      });

  /// Expose sync service for external use (e.g., chat list screen)
  SyncMessageService get messageSyncService => _syncMessageService;

  /// Load messages for a specific chat room and subscribe to real-time updates
  Future<void> loadMessages(String chatId) async {
    _currentChatId = chatId;
    _isLoadingMessages = true;
    notifyListeners();

    try {
      // Fetch and sync messages (local first, then remote)
      _messages = await _syncMessageService.fetchAndSyncMessages(chatId);

      // Subscribe to real-time updates
      _subscribeToMessages(chatId);

      // Mark messages as delivered when opening chat
      await _markMessagesAsDelivered(chatId);
    } catch (e) {
      print('❌ Error loading messages: $e');
      // Even if server fails, show local messages
      _messages = await _syncMessageService.getLocalMessages(chatId);
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Subscribe to real-time message updates
  void _subscribeToMessages(String chatId) {
    // Remove existing subscription if any
    _unsubscribeFromMessages();

    _messageSubscription = _supabase
        .channel('messages:$chatId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_room_id',
        value: chatId,
      ),
      callback: (payload) {
        final newMessage = Message.fromJson(payload.newRecord);

        // Add to list if not already present
        if (!_messages.any((msg) => msg.id == newMessage.id)) {
          _messages.add(newMessage);

          // Mark as delivered if it's from the other user
          if (newMessage.senderId != currentUserId) {
            _updateMessageStatus(newMessage.id, MessageStatus.delivered);
          }

          notifyListeners();
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_room_id',
        value: chatId,
      ),
      callback: (payload) {
        final updatedMessage = Message.fromJson(payload.newRecord);

        // Update message in list
        final index = _messages.indexWhere((msg) => msg.id == updatedMessage.id);
        if (index != -1) {
          _messages[index] = updatedMessage;
          notifyListeners();
        }
      },
    )
        .subscribe();

    print('🔔 Subscribed to real-time updates for chat: $chatId');
  }

  /// Unsubscribe from real-time updates
  void _unsubscribeFromMessages() {
    if (_messageSubscription != null) {
      _supabase.removeChannel(_messageSubscription!);
      _messageSubscription = null;
      print('🔕 Unsubscribed from real-time updates');
    }
  }

  /// Send a new message
  Future<void> sendMessage(String text, String chatId, {String? receiverId}) async {
    if (text.trim().isEmpty) return;

    _isSendingMessage = true;
    notifyListeners();

    try {
      // Create message with temporary ID
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final optimisticMessage = Message(
        id: tempId,
        chatRoomId: chatId,
        senderId: currentUserId,
        receiverId: receiverId ?? '',
        content: text,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
        messageType: MessageType.text,
      );

      // Add to UI immediately (optimistic update)
      _messages.add(optimisticMessage);
      notifyListeners();

      // Send via sync service (handles local + remote)
      final sentMessage = await _syncMessageService.sendMessage(optimisticMessage);

      if (sentMessage != null) {
        // Replace temporary message with server version
        final index = _messages.indexWhere((msg) => msg.id == tempId);
        if (index != -1) {
          _messages[index] = sentMessage;
        }

        // Update chat room's last message
        await _chatRoomSyncService.updateLastMessage(
          chatId,
          text,
          sentMessage.createdAt,
        );

        notifyListeners();
      }
    } catch (e) {
      print('❌ Error sending message: $e');
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Update message status (delivered, read)
  Future<void> _updateMessageStatus(String messageId, MessageStatus status) async {
    try {
      await _syncMessageService.updateMessageStatus(messageId, status);

      // Update in local list
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: status);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error updating message status: $e');
    }
  }

  /// Mark all received messages as delivered when opening chat
  Future<void> _markMessagesAsDelivered(String chatId) async {
    try {
      await _syncMessageService.markMessagesAsDelivered(chatId, currentUserId);

      // Refresh messages to show updated status
      _messages = await _syncMessageService.getLocalMessages(chatId);
      notifyListeners();
    } catch (e) {
      print('❌ Error marking messages as delivered: $e');
    }
  }

  /// Mark messages as read when user is actively viewing them
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await _syncMessageService.markMessagesAsRead(chatId, currentUserId);

      // Update local message list
      for (var i = 0; i < _messages.length; i++) {
        if (_messages[i].receiverId == currentUserId &&
            _messages[i].status != MessageStatus.read) {
          _messages[i] = _messages[i].copyWith(status: MessageStatus.read);
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _syncMessageService.deleteMessage(messageId);

      // Update in local list
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          content: 'This message was deleted',
          isDeleted: true,
        );
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
    }
  }

  /// Sync pending messages (called when network becomes available)
  Future<void> syncPendingMessages() async {
    try {
      await _syncMessageService.syncPendingMessages();

      // Reload current chat messages if active
      if (_currentChatId != null) {
        _messages = await _syncMessageService.getLocalMessages(_currentChatId!);
        notifyListeners();
      }

      print('✅ Pending messages synced');
    } catch (e) {
      print('❌ Error syncing pending messages: $e');
    }
  }

  /// Cleanup when leaving chat screen
  void leaveChatScreen() {
    _unsubscribeFromMessages();
    _currentChatId = null;
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribeFromMessages();
    super.dispose();
  }
}
