import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
final _supabase=Supabase.instance.client;
final currentUserId=_supabase.auth.currentUser!.id;
class DateUtils {
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}

// Enhanced ChatService with better error handling and features
// Add this to the existing ChatService class:

Future<List<Map<String, dynamic>>> searchUsers(String query) async {
  if (query.isEmpty) return [];

  try {
    final response = await _supabase
        .from('profiles')
        .select('id, display_name, email, avatar_url')
        .or('display_name.ilike.%$query%,email.ilike.%$query%')
        .neq('id', currentUserId)
        .limit(10);

    return response;
  } catch (e) {
    print('Error searching users: $e');
    return [];
  }
}

Future<void> markMessagesAsRead(String chatId) async {
  final currentUserId = _supabase.auth.currentUser?.id;
  if (currentUserId == null) return;

  try {
    await _supabase.from('message_reads').upsert({
      'user_id': currentUserId,
      'chat_id': chatId,
      'last_read_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print('Error marking messages as read: $e');
  }
}

Future<int> getUnreadMessageCount(String chatId) async {
  final currentUserId = _supabase.auth.currentUser?.id;
  if (currentUserId == null) return 0;

  try {
    // Get last read timestamp
    final readResponse = await _supabase
        .from('message_reads')
        .select('last_read_at')
        .eq('user_id', currentUserId)
        .eq('chat_id', chatId)
        .maybeSingle();

    DateTime? lastReadAt = readResponse != null
        ? DateTime.parse(readResponse['last_read_at'])
        : null;

    // Count unread messages
    var query = _supabase
        .from('messages')
        .select('id')
        .eq('chat_id', chatId)
        .neq('sender_id', currentUserId);


    if (lastReadAt != null) {
      query = query.gt('created_at', lastReadAt.toIso8601String());
    }

    final response = await query;
    return response.length;
  } catch (e) {
    print('Error getting unread count: $e');
    return 0;
  }
}

void dispose() {
  _supabase.removeAllChannels();
}
