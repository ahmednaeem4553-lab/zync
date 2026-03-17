class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String status;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    this.status = 'Hey there! I am using Zync.',
    this.isOnline = false,
    required this.createdAt,
    this.lastSeen,
    this.fcmToken,
  });

  // Convert UserModel → Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'status': status,
      'isOnline': isOnline,
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'fcmToken': fcmToken,
    };
  }

  // Convert Firestore Map → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      status: map['status'] ?? 'Hey there! I am using Zync.',
      isOnline: map['isOnline'] ?? false,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastSeen:
          map['lastSeen'] !=
              null // ADD THIS
          ? DateTime.parse(map['lastSeen'])
          : null,
      fcmToken: map['fcmToken'],
    );
  }

  // CopyWith — useful for updating single fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? status,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? lastSeen,
     String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
