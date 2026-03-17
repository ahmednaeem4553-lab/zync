import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchViewModel extends GetxController {
  final UserRepository _userRepository = UserRepository();

  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxList<UserModel> searchResults = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString query = ''.obs;

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  void loadUsers() {
    _userRepository.getUsers(currentUserId).listen((users) {
      allUsers.value = users;
      searchResults.value = users;
      isLoading.value = false;
    });
  }

  void search(String value) {
    query.value = value;
    if (value.trim().isEmpty) {
      searchResults.value = allUsers;
    } else {
      searchResults.value = allUsers
          .where((user) =>
              user.name.toLowerCase().contains(value.toLowerCase()) ||
              user.email.toLowerCase().contains(value.toLowerCase()))
          .toList();
    }
  }

  void clearSearch() {
    query.value = '';
    searchResults.value = allUsers;
  }
}