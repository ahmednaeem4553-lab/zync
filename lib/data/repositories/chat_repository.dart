import 'package:get/get.dart';
import 'package:zync/data/services/spn.dart';
import 'package:zync/modules/profile/viewmodel/profile_viewmodel.dart';

import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatRepository {
  final ChatService _chatService = ChatService();

  // ==================== MESSAGE SENDING ====================
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    required String chatid,
    String senderName = '',
  }) async {
    print('Noted');
    sendNotification(chatid, Get.find<ProfileViewModel>().currentUser.value?.name??'', message, 'message', receiverId, );
    await _chatService.sendMessage(

      senderId: senderId,
      receiverId: receiverId,
      message: message,
      senderName: senderName,
    );
  }

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

  // ==================== TYPING STATUS ====================
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

  Stream<bool> getTypingStatus({
    required String currentUserId,
    required String receiverId,
  }) {
    return _chatService.getTypingStatus(
      currentUserId: currentUserId,
      receiverId: receiverId,
    );
  }

  // ==================== MESSAGES ====================
  Stream<List<MessageModel>> getMessages(
      String senderId, String receiverId) {
    return _chatService.getMessages(senderId, receiverId);
  }

  Future<void> markMessagesAsRead(
      String senderId, String receiverId) async {
    await _chatService.markMessagesAsRead(senderId, receiverId);
  }

  // ==================== LAST MESSAGE & UNREAD ====================
  // needed by UserChatTile on home screen
  Stream<MessageModel?> getLastMessage(String uid1, String uid2) {
    return _chatService.getLastMessage(uid1, uid2);
  }

  Stream<int> getUnreadCount(
      String currentUserId, String otherUserId) {
    return _chatService.getUnreadCount(currentUserId, otherUserId);
  }

  // ==================== DELETE MESSAGES ====================
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
}