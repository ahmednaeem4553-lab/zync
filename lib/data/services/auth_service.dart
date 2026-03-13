import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current firebase user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email & password
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      photoUrl: AppConstants.defaultAvatar + Uri.encodeComponent(name),
      createdAt: DateTime.now(),
    );

    // Save user to Firestore
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());

    return user;
  }

  // Login with email & password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .get();

    return UserModel.fromMap(doc.data()!);
  }

  // Logout
  Future<void> logout() async {
    try {
      if (currentUser != null) {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(currentUser!.uid)
            .get();

        // Only update if document actually exists
        if (doc.exists) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(currentUser!.uid)
              .update({'isOnline': false});
        }
      }
    } catch (_) {
      // Silently ignore — logout should never be blocked
    } finally {
      await _auth.signOut();
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUser == null) return;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .update({
            'isOnline': isOnline,
            'lastSeen': DateTime.now().toIso8601String(),
          });
    } catch (_) {}
  }
}
