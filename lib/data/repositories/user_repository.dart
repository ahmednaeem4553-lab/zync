import '../models/user_model.dart';
import '../services/user_service.dart';

class UserRepository {
  final UserService _userService = UserService();

  Stream<List<UserModel>> getUsers(String currentUserId) {
    return _userService.getUsers(currentUserId);
  }

  Future<UserModel> getUserById(String uid) async {
    return await _userService.getUserById(uid);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _userService.updateUser(uid, data);
  }
}