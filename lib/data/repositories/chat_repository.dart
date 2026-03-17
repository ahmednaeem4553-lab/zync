import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatRepository {
  final ChatService _chatService = ChatService();

  Future<void> sendMessage({
  required String senderId,
  required String receiverId,
  required String message,
  String senderName = '',
}) async {
  await _chatService.sendMessage(
    senderId: senderId,
    receiverId: receiverId,
    message: message,
    senderName: senderName,
  );
}

  // Add these inside ChatRepository class:

  Future<void> updateTypingStatus({
    required String currentUserId,
    required String receiverId,
    required bool isTyping,
  }) async {
    await _chatService.updateTypingStatus(
      currentUserId: currentUserId,
      receiverId: receiverId,
      isTyping: isTyping,
    );
  }

  // Add these inside ChatRepository class:

  Future<void> deleteMessageForEveryone({
    required String currentUserId,
    required String receiverId,
    required String messageId,
  }) async {
    await _chatService.deleteMessageForEveryone(
      currentUserId: currentUserId,
      receiverId: receiverId,
      messageId: messageId,
    );
  }

  // Add this inside ChatRepository class:

  Future<void> sendImageMessage({
  required String senderId,
  required String receiverId,
  required String base64Image,
  String senderName = '',
}) async {
  await _chatService.sendImageMessage(
    senderId: senderId,
    receiverId: receiverId,
    base64Image: base64Image,
    senderName: senderName,
  );
}

  Future<void> deleteMessageForMe({
    required String currentUserId,
    required String receiverId,
    required String messageId,
  }) async {
    await _chatService.deleteMessageForMe(
      currentUserId: currentUserId,
      receiverId: receiverId,
      messageId: messageId,
    );
  }

  Stream<bool> getTypingStatus({
    required String currentUserId,
    required String receiverId,
  }) {
    return _chatService.getTypingStatus(
      currentUserId: currentUserId,
      receiverId: receiverId,
    );
  }

  Stream<List<MessageModel>> getMessages(String senderId, String receiverId) {
    return _chatService.getMessages(senderId, receiverId);
  }

  Stream<int> getUnreadCount(String currentUserId, String otherUserId) {
    return _chatService.getUnreadCount(currentUserId, otherUserId);
  }

  Stream<MessageModel?> getLastMessage(String uid1, String uid2) {
    return _chatService.getLastMessage(uid1, uid2);
  }

  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    await _chatService.markMessagesAsRead(senderId, receiverId);
  }
}
