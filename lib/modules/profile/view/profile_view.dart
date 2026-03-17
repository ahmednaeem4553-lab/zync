import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zync/core/widgets/zync_avatart.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/profile_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.put(ProfileViewModel());

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('My Profile'),
        actions: [
          Obx(() => TextButton(
                onPressed: vm.isSaving.value ? null : vm.saveProfile,
                child: vm.isSaving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primary),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              )),
        ],
      ),

      body: Obx(() {
        if (vm.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (vm.currentUser.value == null) {
          return const Center(child: Text('Failed to load profile'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: vm.formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      // Avatar — shows selected image or current photo
                      Obx(() => vm.selectedImage.value != null
                          ? CircleAvatar(
                              radius: 56,
                              backgroundImage: FileImage(
                                  vm.selectedImage.value!),
                            )
                          : ZyncAvatar(
                              photoUrl: vm.currentUser.value!.photoUrl,
                              name: vm.currentUser.value!.name,
                              radius: 56,
                            )),

                      // Camera button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: vm.showImagePickerOptions,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Email (read only)
                Obx(() => Text(
                      vm.currentUser.value!.email,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    )),

                const SizedBox(height: 36),

                // Name field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Display Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: vm.nameController,
                  validator: vm.validateName,
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppTheme.textHint),
                  ),
                ),

                const SizedBox(height: 20),

                // Status field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: vm.statusController,
                  validator: vm.validateStatus,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: 'What\'s on your mind?',
                    prefixIcon: Icon(Icons.edit_outlined,
                        color: AppTheme.textHint),
                  ),
                ),

                const SizedBox(height: 32),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Profile photo is stored securely. Keep image size small for best performance.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}