// services/MessageServices/supabaseMessageService.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/messageModel.dart';

class SupabaseMessageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Send a message to Supabase
  Future<Message?> sendMessage(Message message) async {
    try {
      final response = await _client.from('messages').insert({
        'chat_room_id': message.chatRoomId,
        'sender_id': message.senderId,
        'receiver_id': message.receiverId,
        'content': message.content,
        'status': message.status.name,
        'message_type': message.messageType.name,
        'file_url': message.fileUrl,
        'is_deleted': message.isDeleted,
      }).select().single();

      final sentMessage = Message.fromJson(response);
      print('✅ Message sent to Supabase: ${sentMessage.id}');
      return sentMessage;
    } catch (e) {
      print('❌ Error sending message to Supabase: $e');
      return null;
    }
  }

  /// Fetch messages for a chat room
  Future<List<Message>> fetchMessages(String chatRoomId, {int limit = 50}) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching messages: $e');
      return [];
    }
  }

  /// Fetch messages with pagination
  Future<List<Message>> fetchMessagesWithPagination(
      String chatRoomId, {
        required int limit,
        required int offset,
      }) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final messages = (response as List)
          .map((json) => Message.fromJson(json))
          .toList();

      // Reverse to get chronological order
      return messages.reversed.toList();
    } catch (e) {
      print('❌ Error fetching paginated messages: $e');
      return [];
    }
  }

  /// Update message status (delivered, read)
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    try {
      await _client.from('messages').update({
        'status': status.name,
      }).eq('id', messageId);

      print('✅ Updated message status to ${status.name}: $messageId');
    } catch (e) {
      print('❌ Error updating message status: $e');
    }
  }

  /// Mark messages as delivered for a chat room
  Future<void> markMessagesAsDelivered(String chatRoomId, String receiverId) async {
    try {
      await _client.from('messages').update({
        'status': MessageStatus.delivered.name,
      }).eq('chat_room_id', chatRoomId)
          .eq('receiver_id', receiverId)
          .eq('status', MessageStatus.sent.name);

      print('✅ Marked messages as delivered for chat: $chatRoomId');
    } catch (e) {
      print('❌ Error marking messages as delivered: $e');
    }
  }

  /// Mark messages as read for a chat room
  Future<void> markMessagesAsRead(String chatRoomId, String receiverId) async {
    try {
      await _client.from('messages').update({
        'status': MessageStatus.read.name,
      }).eq('chat_room_id', chatRoomId)
          .eq('receiver_id', receiverId)
          .neq('status', MessageStatus.read.name);

      print('✅ Marked messages as read for chat: $chatRoomId');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').update({
        'is_deleted': true,
        'content': 'This message was deleted',
      }).eq('id', messageId);

      print('🗑️ Soft deleted message: $messageId');
    } catch (e) {
      print('❌ Error deleting message: $e');
    }
  }

  /// Get message by ID
  Future<Message?> getMessageById(String messageId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return null;

      return Message.fromJson(response);
    } catch (e) {
      print('❌ Error fetching message: $e');
      return null;
    }
  }

  /// Get unread message count for a chat
  Future<int> getUnreadCount(String chatRoomId, String currentUserId) async {
    try {
      final count = await _client
          .from('messages')
          .count()
          .eq('chat_room_id', chatRoomId)
          .eq('receiver_id', currentUserId)
          .neq('status', MessageStatus.read.name)
          .eq('is_deleted', false);
           ;


      return count;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Subscribe to new messages in a chat room (real-time)
  RealtimeChannel subscribeToMessages(
      String chatRoomId,
      Function(Message) onNewMessage,
      Function(Message) onMessageUpdate,
      ) {
    return _client
        .channel('messages:$chatRoomId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_room_id',
        value: chatRoomId,
      ),
      callback: (payload) {
        final newMessage = Message.fromJson(payload.newRecord);
        onNewMessage(newMessage);
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_room_id',
        value: chatRoomId,
      ),
      callback: (payload) {
        final updatedMessage = Message.fromJson(payload.newRecord);
        onMessageUpdate(updatedMessage);
      },
    )
        .subscribe();
  }

  /// Search messages by content
  Future<List<Message>> searchMessages(String chatRoomId, String query) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .ilike('content', '%$query%')
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error searching messages: $e');
      return [];
    }
  }

  /// Get messages by type (images, files, etc.)
  Future<List<Message>> getMessagesByType(
      String chatRoomId,
      MessageType type
      ) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .eq('message_type', type.name)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching messages by type: $e');
      return [];
    }
  }
}
