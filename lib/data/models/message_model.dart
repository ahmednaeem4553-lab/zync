class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime sentAt;
  final bool isRead;
  final bool isDeleted;
  final String messageType;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.sentAt,
    this.isRead = false,
    this.isDeleted = false,
    this.messageType = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'isDeleted': isDeleted,
      'messageType': messageType,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      sentAt: DateTime.parse(map['sentAt'] ?? DateTime.now().toIso8601String()),
      isRead: map['isRead'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      messageType: map['messageType'] ?? 'text',
    );
  }
}
