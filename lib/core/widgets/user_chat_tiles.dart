import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:zync/core/widgets/zync_avatart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/message_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';

class UserChatTile extends StatelessWidget {
  final UserModel user;
  final String currentUserId;
  final ChatRepository chatRepository;

  const UserChatTile({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.chatRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MessageModel?>(
      stream: chatRepository.getLastMessage(currentUserId, user.uid),
      builder: (context, lastMsgSnapshot) {
        final lastMessage = lastMsgSnapshot.data;

        return StreamBuilder<int>(
          stream: chatRepository.getUnreadCount(currentUserId, user.uid),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.data ?? 0;

            return InkWell(
              onTap: () => Get.toNamed('/chat', arguments: user),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Avatar with online dot
                    Stack(
                      children: [
                        // ✅ ZyncAvatar handles both base64 and URL
                        ZyncAvatar(
                          photoUrl: user.photoUrl,
                          name: user.name,
                          radius: 28,
                        ),
                        if (user.isOnline)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Name + last message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + time row
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (lastMessage != null)
                                Text(
                                  timeago.format(
                                    lastMessage.sentAt,
                                    locale: 'en_short',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: unreadCount > 0
                                        ? AppTheme.primary
                                        : AppTheme.textHint,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Last message + unread badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getLastMessageText(lastMessage),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: unreadCount > 0
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Unread badge
                              if (unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getLastMessageText(MessageModel? lastMessage) {
    if (lastMessage == null) return user.status;

    final isMe = lastMessage.senderId == currentUserId;
    final prefix = isMe ? 'You: ' : '';

    if (lastMessage.isDeleted) {
      return '${prefix}This message was deleted';
    }

    if (lastMessage.messageType == 'image') {
      return '${prefix}📷 Photo';
    }

    return '$prefix${lastMessage.message}';
  }
}