import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  String getChatRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // ==================== SEND TEXT MESSAGE ====================
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String senderName = '',
  }) async {
    final chatRoomId = getChatRoomId(senderId, receiverId);
    final messageId = _uuid.v4();

    final newMessage = MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      sentAt: DateTime.now(),
      messageType: 'text',
    );

    try {
      // Write message
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatRoomId)
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .set(newMessage.toMap());

      // Update chat room metadata
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatRoomId)
          .set({
        'lastMessage': message,
        'lastMessageTime': newMessage.sentAt.toIso8601String(),
        'lastMessageSenderId': senderId,
        'participants': [senderId, receiverId],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Message sent successfully to chat: $chatRoomId');
    } catch (e) {
      print('Error sending message: $e');
      rethrow; // Let ViewModel catch and show snackbar
    }
  }

  // ==================== SEND IMAGE MESSAGE ====================
  Future<void> sendImageMessage({
    required String senderId,
    required String receiverId,
    required String base64Image,
    String senderName = '',
  }) async {
    final chatRoomId = getChatRoomId(senderId, receiverId);
    final messageId = _uuid.v4();

    final newMessage = MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      message: base64Image,
      sentAt: DateTime.now(),
      messageType: 'image',
    );

    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatRoomId)
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .set(newMessage.toMap());

      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatRoomId)
          .set({
        'lastMessage': '📷 Photo',
        'lastMessageTime': newMessage.sentAt.toIso8601String(),
        'lastMessageSenderId': senderId,
        'participants': [senderId, receiverId],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Image message sent successfully');
    } catch (e) {
      print('Error sending image: $e');
      rethrow;
    }
  }

  // ==================== TYPING STATUS ====================
  Future<void> updateTypingStatus({
    required String currentUserId,
    required String receiverId,
    required bool isTyping,
  }) async {
    final chatRoomId = getChatRoomId(currentUserId, receiverId);
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .set({'typing_$currentUserId': isTyping}, SetOptions(merge: true));
  }

  Stream<bool> getTypingStatus({
    required String currentUserId,
    required String receiverId,
  }) {
    final chatRoomId = getChatRoomId(currentUserId, receiverId);
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .snapshots()
        .map((doc) => doc.data()?['typing_$receiverId'] ?? false);
  }

  // ==================== MESSAGES STREAM ====================
  Stream<List<MessageModel>> getMessages(String senderId, String receiverId) {
    final chatRoomId = getChatRoomId(senderId, receiverId);
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesCollection)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> markMessagesAsRead(String currentUserId, String otherUserId) async {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);

    final unreadMessages = await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesCollection)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ==================== DELETE MESSAGE ====================
  Future<void> deleteMessageForEveryone({
    required String currentUserId,
    required String receiverId,
    required String messageId,
  }) async {
    final chatRoomId = getChatRoomId(currentUserId, receiverId);
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .update({
      'isDeleted': true,
      'message': 'This message was deleted',
    });
  }

  Future<void> deleteMessageForMe({
    required String currentUserId,
    required String receiverId,
    required String messageId,
  }) async {
    final chatRoomId = getChatRoomId(currentUserId, receiverId);
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .delete();
  }
  // ==================== LAST MESSAGE & UNREAD COUNT ====================
Stream<MessageModel?> getLastMessage(String uid1, String uid2) {
  final chatRoomId = getChatRoomId(uid1, uid2);
  return _firestore
      .collection(AppConstants.chatsCollection)
      .doc(chatRoomId)
      .collection(AppConstants.messagesCollection)
      .orderBy('sentAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isEmpty
          ? null
          : MessageModel.fromMap(snapshot.docs.first.data()));
}

Stream<int> getUnreadCount(String currentUserId, String otherUserId) {
  final chatRoomId = getChatRoomId(currentUserId, otherUserId);
  return _firestore
      .collection(AppConstants.chatsCollection)
      .doc(chatRoomId)
      .collection(AppConstants.messagesCollection)
      .where('receiverId', isEqualTo: currentUserId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}
}