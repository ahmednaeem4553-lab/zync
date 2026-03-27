import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/message_model.dart';
import '../viewmodel/chat_viewmodel.dart';
import 'dart:convert';
import 'dart:typed_data';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.put(ChatViewModel());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatId = _generateChatId(vm.currentUserId, vm.receiver.uid);
      vm.setCurrentChat(chatId);
      print('ChatView opened with chatId: $chatId'); // for debugging
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,

        // ✅ Obx wraps the entire title for real time updates
        title: Obx(() {
          final user = vm.receiverUser.value ?? vm.receiver;
          return Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.divider,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.photoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Text(
                          user.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ✅ Online dot — updates in real time
                  if (user.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  // ✅ Online/Offline text — updates in real time
                  Text(
                    user.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isOnline
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),

      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Obx(() {
              if (vm.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (vm.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Say hi to ${vm.receiver.name}! 👋',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Replace the return ListView.builder(...) block with this:
              return ListView.builder(
                controller: vm.scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: vm.messages.length + 1, // +1 for typing bubble
                itemBuilder: (context, index) {
                  // Last item — show typing bubble if receiver is typing
                  if (index == vm.messages.length) {
                    return Obx(
                      () => vm.isReceiverTyping.value
                          ? _TypingBubble(name: vm.receiver.name)
                          : const SizedBox.shrink(),
                    );
                  }

                  final message = vm.messages[index];
                  final isMine = vm.isMine(message);
                  final showDate =
                      index == 0 ||
                      !_isSameDay(
                        vm.messages[index - 1].sentAt,
                        message.sentAt,
                      );

                  return Column(
                    children: [
                      if (showDate) _DateChip(date: message.sentAt),
                      _MessageBubble(message: message, isMine: isMine, vm: vm),
                    ],
                  );
                },
              );
            }),
          ),

          // Message Input
          _MessageInput(vm: vm),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Date chip between messages
class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.divider,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            DateFormat('MMMM d, yyyy').format(date),
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

// Message Bubble
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final ChatViewModel vm;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.isDeleted;
    final isImage = message.messageType == 'image';

    return GestureDetector(
      onLongPress: () => vm.showDeleteOptions(message),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: isDeleted
                ? (isMine
                      ? AppTheme.primary.withOpacity(0.4)
                      : AppTheme.surface)
                : (isMine ? AppTheme.primary : AppTheme.surface),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isDeleted
              ? _deletedContent(isMine)
              : isImage
              ? _imageContent(context)
              : _textContent(isMine),
        ),
      ),
    );
  }

  // Deleted message content
  Widget _deletedContent(bool isMine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_rounded,
                size: 13,
                color: isMine ? Colors.white70 : AppTheme.textHint,
              ),
              const SizedBox(width: 5),
              Text(
                'This message was deleted',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isMine ? Colors.white70 : AppTheme.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a').format(message.sentAt),
            style: TextStyle(
              fontSize: 11,
              color: isMine ? Colors.white.withOpacity(0.7) : AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // Text message content
  Widget _textContent(bool isMine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            message.message,
            style: TextStyle(
              fontSize: 15,
              color: isMine ? Colors.white : AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('h:mm a').format(message.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isMine
                      ? Colors.white.withOpacity(0.7)
                      : AppTheme.textHint,
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Image message content
  Widget _imageContent(BuildContext context) {
    try {
      final bytes = base64Decode(message.message);
      return ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 16),
        ),
        child: Stack(
          children: [
            // Image
            GestureDetector(
              onTap: () => _openFullImage(context, bytes),
              child: Image.memory(
                bytes,
                width: MediaQuery.of(context).size.width * 0.45,
                fit: BoxFit.cover,
              ),
            ),

            // Time overlay on image
            Positioned(
              bottom: 6,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.sentAt),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 3),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Failed to load image',
          style: TextStyle(color: AppTheme.textHint),
        ),
      );
    }
  }

  // Open full screen image viewer
  void _openFullImage(BuildContext context, Uint8List bytes) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
      ),
    );
  }
}

String _generateChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

// Message Input Bar
class _MessageInput extends StatelessWidget {
  final ChatViewModel vm;
  const _MessageInput({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            Obx(
              () => IconButton(
                onPressed: vm.isSendingImage.value
                    ? null
                    : vm.showAttachmentOptions,
                icon: vm.isSendingImage.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : const Icon(
                        Icons.attach_file_rounded,
                        color: AppTheme.textSecondary,
                      ),
              ),
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: vm.messageController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => vm.sendMessage(),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Obx(
              () => GestureDetector(
                onTap: vm.isSending.value ? null : vm.sendMessage,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: vm.isSending.value
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  final String name;
  const _TypingBubble({required this.name});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animations = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0,
            end: -6,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();

    // Stagger the dot animations
    Future.delayed(const Duration(milliseconds: 0), () => _startLoop(0));
    Future.delayed(const Duration(milliseconds: 150), () => _startLoop(1));
    Future.delayed(const Duration(milliseconds: 300), () => _startLoop(2));
  }

  void _startLoop(int index) {
    if (!mounted) return;
    _controllers[index].repeat(reverse: true);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animations[index].value),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.textHint,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
