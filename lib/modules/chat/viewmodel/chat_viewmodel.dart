import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/auth_service.dart';

class ChatViewModel extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();
  final AuthService _authService = AuthService();

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final Rx<UserModel?> receiverUser = Rx<UserModel?>(null);

  final messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late UserModel receiver;
  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    receiver = Get.arguments as UserModel;
    receiverUser.value = receiver;

    // Set current user online
    _authService.updateOnlineStatus(true);

    listenToMessages();
    listenToReceiverStatus(); // real time receiver status
    markAsRead();
  }

  @override
  void onClose() {
    // Set current user offline when leaving chat
    _authService.updateOnlineStatus(false);
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // Real time receiver online status stream
  void listenToReceiverStatus() {
    FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(receiver.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        receiverUser.value = UserModel.fromMap(doc.data()!);
      }
    });
  }

  void listenToMessages() {
    _chatRepository
        .getMessages(currentUserId, receiver.uid)
        .listen((messageList) {
      messages.value = messageList;
      isLoading.value = false;
      _scrollToBottom();
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    isSending.value = true;

    try {
      await _chatRepository.sendMessage(
        senderId: currentUserId,
        receiverId: receiver.uid,
        message: text,
      );
      _scrollToBottom();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> markAsRead() async {
    await _chatRepository.markMessagesAsRead(currentUserId, receiver.uid);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool isMine(MessageModel message) => message.senderId == currentUserId;
}