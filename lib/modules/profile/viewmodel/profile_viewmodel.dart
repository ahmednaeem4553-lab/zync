import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zync/data/services/images_services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

class ProfileViewModel extends GetxController {
  final UserRepository _userRepository = UserRepository();
  final ImageService _imageService = ImageService();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);

  final nameController = TextEditingController();
  final statusController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    statusController.dispose();
    super.onClose();
  }

  void loadProfile() {
    isLoading.value = true;
    FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        currentUser.value = UserModel.fromMap(doc.data()!);
        // Only set text if user hasn't started editing
        if (!isSaving.value) {
          nameController.text = currentUser.value!.name;
          statusController.text = currentUser.value!.status;
        }
      }
      isLoading.value = false;
    });
  }

  void showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Profile Photo',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _imageOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _imageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _imageService.pickImage(source);
    if (file != null) {
      selectedImage.value = file;
    }
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    isSaving.value = true;

    try {
      String photoUrl = currentUser.value!.photoUrl;

      // Convert selected image to base64 if picked
      if (selectedImage.value != null) {
        final base64 = await _imageService
            .convertToBase64(selectedImage.value!);

        if (base64 == null) {
          Get.snackbar(
            'Image Too Large',
            'Please pick a smaller image',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.error,
            colorText: Colors.white,
          );
          isSaving.value = false;
          return;
        }
        photoUrl = base64; // store base64 in Firestore
      }

      await _userRepository.updateUser(currentUserId, {
        'name': nameController.text.trim(),
        'status': statusController.text.trim(),
        'photoUrl': photoUrl,
      });

      selectedImage.value = null;

      Get.snackbar(
        'Success ✅',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.error,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name too short';
    return null;
  }

  String? validateStatus(String? value) {
    if (value == null || value.trim().isEmpty) return 'Status is required';
    if (value.trim().length > 100) return 'Status too long (max 100)';
    return null;
  }
}