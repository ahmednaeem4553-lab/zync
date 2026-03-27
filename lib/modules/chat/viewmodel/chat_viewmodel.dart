import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zync/data/services/images_services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/auth_service.dart';

class ChatViewModel extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();
  final AuthService _authService = AuthService();
  String? currentChatId;

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxBool isReceiverTyping = false.obs;
  final RxBool isSendingImage = false.obs;
  final RxString currentUserName = ''.obs;
  final Rx<UserModel?> receiverUser = Rx<UserModel?>(null);

  final messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late UserModel receiver;
  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  Timer? _typingTimer;


  void setCurrentChat(String chatId) {
    currentChatId = chatId;
    update(); // or refresh if needed
  }

    @override
  void onInit() {
    super.onInit();
    receiver = Get.arguments as UserModel;
    receiverUser.value = receiver;

    // Generate and set chatId consistently
    currentChatId = _generateChatId(currentUserId, receiver.uid);
    
    _authService.updateOnlineStatus(true);
    listenToMessages();
    listenToReceiverStatus();
    listenToTypingStatus();
    markAsRead();
    _loadCurrentUserName();

    messageController.addListener(_onTextChanged);
  }

  String _generateChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  @override
  void onClose() {
    // Stop typing when leaving
    _stopTyping();
    _typingTimer?.cancel();
    messageController.removeListener(_onTextChanged);
    _authService.updateOnlineStatus(false);
    messageController.dispose();
    scrollController.dispose();
    currentChatId = null;
    super.onClose();
  }

  void _onTextChanged() {
    if (messageController.text.trim().isNotEmpty) {
      _startTyping();
    } else {
      _stopTyping();
    }
  }

  Future<void> _loadCurrentUserName() async {
  final doc = await FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(currentUserId)
      .get();
  if (doc.exists) {
    currentUserName.value = doc.data()?['name'] ?? '';
  }
}

  void _startTyping() {
    // Reset timer every keystroke
    _typingTimer?.cancel();
    _chatRepository.updateTypingStatus(
      currentUserId: currentUserId,
      receiverId: receiver.uid,
      isTyping: true,
    );
    // Auto stop typing after 2 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _chatRepository.updateTypingStatus(
      currentUserId: currentUserId,
      receiverId: receiver.uid,
      isTyping: false,
    );
  }

  void showAttachmentOptions() {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Send Image',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: () {
                  Get.back();
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              _attachOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () {
                  Get.back();
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Widget _attachOption({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}

Future<void> _pickAndSendImage(ImageSource source) async {
  final imageService = ImageService();
  isSendingImage.value = true;

  try {
    final file = await imageService.pickImage(source);
    if (file == null) {
      isSendingImage.value = false;
      return;
    }

    final base64 = await imageService.convertToBase64(file);
    if (base64 == null) {
      Get.snackbar(
        'Image Too Large',
        'Please pick a smaller image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      isSendingImage.value = false;
      return;
    }

    await _chatRepository.sendImageMessage(
      senderId: currentUserId,
      receiverId: receiver.uid,
      base64Image: base64,
      senderName: currentUserName.value, // ADD THIS
    );
    _scrollToBottom();
  } catch (e) {
    Get.snackbar('Error', 'Failed to send image',
        snackPosition: SnackPosition.BOTTOM);
  } finally {
    isSendingImage.value = false;
  }
}

  void listenToTypingStatus() {
    _chatRepository
        .getTypingStatus(
          currentUserId: currentUserId,
          receiverId: receiver.uid,
        )
        .listen((isTyping) {
      isReceiverTyping.value = isTyping;
      if (isTyping) _scrollToBottom();
    });
  }

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
  _stopTyping();
  isSending.value = true;

  try {
    await _chatRepository.sendMessage(
      chatid: _generateChatId(currentUserId, receiver.uid),
      senderId: currentUserId,
      receiverId: receiver.uid,
      message: text,
      senderName: currentUserName.value, // ADD THIS
    );
    _scrollToBottom();
  } catch (e) {
    Get.snackbar('Error', 'Failed to send message',
        snackPosition: SnackPosition.BOTTOM);
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

  // Add these inside ChatViewModel class:

void showDeleteOptions(MessageModel message) {
  // Only allow deleting own messages
  if (!isMine(message)) return;

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Delete Message',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Message preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),

          // Delete for everyone
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_rounded,
                  color: Colors.red, size: 20),
            ),
            title: const Text(
              'Delete for everyone',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Remove this message for all users',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Get.back();
              _deleteForEveryone(message);
            },
          ),

          // Delete for me
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.orange, size: 20),
            ),
            title: const Text(
              'Delete for me',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Remove this message only for you',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Get.back();
              _deleteForMe(message);
            },
          ),

          // Cancel
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.grey, size: 20),
            ),
            title: const Text('Cancel'),
            onTap: () => Get.back(),
          ),

          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _deleteForEveryone(MessageModel message) async {
  try {
    await _chatRepository.deleteMessageForEveryone(
      currentUserId: currentUserId,
      receiverId: receiver.uid,
      messageId: message.messageId,
    );
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to delete message',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

Future<void> _deleteForMe(MessageModel message) async {
  try {
    await _chatRepository.deleteMessageForMe(
      currentUserId: currentUserId,
      receiverId: receiver.uid,
      messageId: message.messageId,
    );
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to delete message',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
}