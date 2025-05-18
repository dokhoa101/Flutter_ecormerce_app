import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utility/extensions.dart';
import '../../utility/snack_bar_helper.dart';
import '../../utility/functions.dart';
import 'verify_screen.dart';
import 'components/login_button.dart';
import 'components/login_textfield.dart';

class ForgotPwdScreen extends StatefulWidget {
  const ForgotPwdScreen({super.key});

  @override
  State<ForgotPwdScreen> createState() => _ForgotPwdScreenState();
}

class _ForgotPwdScreenState extends State<ForgotPwdScreen> {
  final TextEditingController emailController = TextEditingController();

  void sendResetCode() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      SnackBarHelper.showErrorSnackBar('Email cannot be empty!');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      SnackBarHelper.showErrorSnackBar('Invalid email format!');
      return;
    }

    showLoadingDialog(context);
    final result = await context.userProvider.sendForgotPasswordCode(email);
    Navigator.pop(context);

    if (result == null) {
      Get.to(() => VerifyScreen(email: email));
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
                const Icon(Icons.lock_open, size: 100, color: Colors.black87),
                const SizedBox(height: 30),
                const Text(
                  'Forgot your password?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('Enter your email to receive a reset code.'),
                const SizedBox(height: 25),
                LoginTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 25),
                LoginButton(
                  onTap: sendResetCode,
                  buttonText: 'Send Code',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
