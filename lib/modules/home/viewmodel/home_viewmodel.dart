import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';

class HomeViewModel extends GetxController {
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();
  final AuthService _authService = AuthService();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<UserModel> filteredUsers = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSearching = false.obs; // ADD THIS
  final RxString searchQuery = ''.obs;

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    _authService.updateOnlineStatus(true);
    listenToUsers();
  }

  @override
  void onClose() {
    _authService.updateOnlineStatus(false);
    super.onClose();
  }

  // ADD THIS
  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) filterUsers('');
  }

  void listenToUsers() {
    _userRepository.getUsers(currentUserId).listen((userList) {
      users.value = userList;
      filterUsers(searchQuery.value);
      isLoading.value = false;
    });
  }

  void filterUsers(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      filteredUsers.value = users;
    } else {
      filteredUsers.value = users
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<void> logout() async {
    await _authService.updateOnlineStatus(false);
    await _authRepository.logout();
    Get.offAllNamed('/login');
  }
}