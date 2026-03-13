import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/auth_viewmodel.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.put(AuthViewModel());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: vm.registerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                const Icon(Icons.bolt_rounded,
                    size: 48, color: AppTheme.primary),
                const SizedBox(height: 16),
                const Text('Create account',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                const Text('Join Zync and start chatting',
                    style: TextStyle(
                        fontSize: 15, color: AppTheme.textSecondary)),

                const SizedBox(height: 40),

                // Name
                TextFormField(
                  controller: vm.nameController,
                  validator: vm.validateName,
                  decoration: const InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppTheme.textHint),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: vm.emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: vm.validateEmail,
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppTheme.textHint),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                Obx(() => TextFormField(
                      controller: vm.passwordController,
                      obscureText: !vm.isPasswordVisible.value,
                      validator: vm.validatePassword,
                      decoration: InputDecoration(
                        hintText: 'Password (min 6 characters)',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppTheme.textHint),
                        suffixIcon: IconButton(
                          icon: Icon(
                            vm.isPasswordVisible.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textHint,
                          ),
                          onPressed: vm.togglePasswordVisibility,
                        ),
                      ),
                    )),

                const SizedBox(height: 32),

                // Register Button
                Obx(() => ElevatedButton(
                      onPressed: vm.isLoading.value ? null : vm.register,
                      child: vm.isLoading.value
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Create Account'),
                    )),

                const SizedBox(height: 24),

                // Login redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Sign In',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}