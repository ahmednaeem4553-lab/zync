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

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final chatRoomId = getChatRoomId(senderId, receiverId);
    final messageId = _uuid.v4();
    final newMessage = MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      sentAt: DateTime.now(),
    );

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
      'lastMessage': message,
      'lastMessageTime': newMessage.sentAt.toIso8601String(),
      'lastMessageSenderId': senderId,
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

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

  // Get unread message count for a specific chat
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

  // Get last message for a chat
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

  Future<void> markMessagesAsRead(
      String senderId, String receiverId) async {
    final chatRoomId = getChatRoomId(senderId, receiverId);
    final unreadMessages = await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesCollection)
        .where('receiverId', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}