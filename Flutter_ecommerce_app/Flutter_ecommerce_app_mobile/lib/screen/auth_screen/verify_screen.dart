import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utility/extensions.dart';
import '../../utility/snack_bar_helper.dart';
import '../../utility/functions.dart';
import '../auth_screen/login_screen.dart';
import 'components/login_button.dart';
import 'components/login_textfield.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  const VerifyScreen({super.key, required this.email});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  void resetPassword() async {
    final code = codeController.text.trim();
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      SnackBarHelper.showErrorSnackBar("All fields are required");
      return;
    }

    if (!validatePassword(newPassword)) {
      SnackBarHelper.showErrorSnackBar("Please use a stronger password!");
      return;
    }

    if (newPassword != confirmPassword) {
      SnackBarHelper.showErrorSnackBar("Passwords do not match");
      return;
    }

    showLoadingDialog(context);
    final result = await context.userProvider.resetPassword(
      email: widget.email,
      code: code,
      newPassword: newPassword,
    );
    Navigator.pop(context);

    if (result == null) {
      SnackBarHelper.showSuccessSnackBar("Password reset successful!");
      Get.offAll(() => const LoginScreen());
    } else {
      SnackBarHelper.showErrorSnackBar(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user,
                    size: 100, color: Colors.black87),
                const SizedBox(height: 30),
                const Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                LoginTextField(
                  controller: codeController,
                  hintText: 'Reset Code',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                LoginTextField(
                  controller: passwordController,
                  hintText: 'New Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                LoginTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(height: 25),
                LoginButton(
                  onTap: resetPassword,
                  buttonText: 'Send',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
