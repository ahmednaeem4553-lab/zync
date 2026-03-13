import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatRepository {
  final ChatService _chatService = ChatService();

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    await _chatService.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      message: message,
    );
  }

  Stream<List<MessageModel>> getMessages(
      String senderId, String receiverId) {
    return _chatService.getMessages(senderId, receiverId);
  }

  Stream<int> getUnreadCount(String currentUserId, String otherUserId) {
    return _chatService.getUnreadCount(currentUserId, otherUserId);
  }

  Stream<MessageModel?> getLastMessage(String uid1, String uid2) {
    return _chatService.getLastMessage(uid1, uid2);
  }

  Future<void> markMessagesAsRead(
      String senderId, String receiverId) async {
    await _chatService.markMessagesAsRead(senderId, receiverId);
  }
}