import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zync/core/widgets/user_chat_tiles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/chat_repository.dart';
import '../viewmodel/home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.put(HomeViewModel());
    final chatRepository = ChatRepository();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Zync',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppTheme.textSecondary),
            onPressed: () => _confirmLogout(vm),
          ),
        ],
      ),

      body: Column(
        children: [
          // Inline search bar always visible
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: vm.filterUsers,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textHint),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Chat list
          Expanded(
            child: Obx(() {
              if (vm.isLoading.value) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (vm.filteredUsers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: AppTheme.textHint),
                      const SizedBox(height: 12),
                      const Text(
                        'No chats yet',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Search for users to start chatting',
                        style: TextStyle(
                            color: AppTheme.textHint, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: vm.filteredUsers.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 80,
                  color: AppTheme.divider,
                ),
                itemBuilder: (context, index) {
                  final user = vm.filteredUsers[index];
                  return UserChatTile(
                    user: user,
                    currentUserId: vm.currentUserId,
                    chatRepository: chatRepository,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(HomeViewModel vm) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              vm.logout();
            },
            child: const Text('Logout',
                style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}