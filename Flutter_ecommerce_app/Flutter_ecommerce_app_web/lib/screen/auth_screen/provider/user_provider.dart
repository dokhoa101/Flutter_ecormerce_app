import 'dart:convert';
import 'dart:developer';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ecommerce_app/utility/snack_bar_helper.dart';
import 'package:http/http.dart' as http;
import '../../../core/data/data_provider.dart';
import '../../../models/api_response.dart';
import '../../../models/user.dart';
import '../../../services/http_services.dart';
import '../../../utility/constants.dart';
import '../../../utility/functions.dart';
import '../login_screen.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';

class UserProvider extends ChangeNotifier {
  HttpService service = HttpService();
  DataProvider? _dataProvider;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordController2 = TextEditingController();

  UserProvider(this._dataProvider);

  void update(DataProvider dataProvider) {
    _dataProvider = dataProvider;
  }

  Future<String?> login() async {
    String email = emailController.text.trim().toLowerCase();
    String pass = passwordController.text;

    String? validate = _isEmailPasswordValid(email, pass);

    if (validate != null) {
      return validate;
    }

    try {
      Map<String, dynamic> user = {'name': email, 'password': pass};

      final response =
          await service.addItem(endpointUrl: 'users/login', itemData: user);

      if (response.isOk) {
        final ApiResponse<User> apiResponse = ApiResponse<User>.fromJson(
            response.body,
            (json) => User.fromJson(json as Map<String, dynamic>));

        if (apiResponse.success == true) {
          User? user = apiResponse.data;
          await saveLoginInfo(user);

          log('login success');
          return null;
        } else {
          return 'Failed to login: ${apiResponse.message}';
        }
      } else {
        return 'Error: ${response.body?['message'] ?? response.statusText}';
      }
    } catch (e) {
      log(e.toString());
      return 'An error occurred: $e';
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/dblgojh9l/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'Flutter_preset'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = jsonDecode(resStr);
      return resJson['secure_url'];
    } else {
      throw Exception("Image upload failed");
    }
  }

  Future<String?> uploadWebImageToCloudinary(Uint8List imageBytes) async {
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/dblgojh9l/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'Flutter_preset'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'upload.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = jsonDecode(resStr);
      return resJson['secure_url'];
    } else {
      throw Exception("Image upload failed on web");
    }
  }

  Future<void> updateProfile({
    required String name,
    String? password,
    String? imageUrl,
  }) async {
    try {
      final user = await getLoginUsr(); // lấy từ local

      final Map<String, dynamic> body = {
        'name': name,
        if (imageUrl != null) 'imgUrl': imageUrl,
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await service.updateItem(
        endpointUrl: 'users/',
        itemId: user!.sId ?? '',
        itemData: body,
      );

      if (response.statusCode == 200) {
        final updatedUser = User.fromJson(response.body['data']);

        await saveLoginInfo(updatedUser);
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? "Failed to update profile");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> register() async {
    String email = emailController.text.trim().toLowerCase();
    String pass = passwordController.text;
    String pass2 = passwordController2.text;

    String? validate = _isEmailPasswordValid(email, pass);

    if (validate != null) {
      return validate;
    } else if (pass2.isEmpty) {
      return 'Confirm password to proceed.';
    } else if (pass != pass2) {
      return 'Passwords do not match!';
    }

    try {
      Map<String, dynamic> user = {
        'name': email,
        'email': email,
        'password': pass
      };

      final response =
          await service.addItem(endpointUrl: 'users/register', itemData: user);

      if (response.isOk) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.body, null);

        if (apiResponse.success == true) {
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          log('register success');
          return null;
        } else {
          return 'Failed to register: ${apiResponse.message}';
        }
      } else {
        return 'Error: ${response.body?['message'] ?? response.statusText}';
      }
    } catch (e) {
      log(e.toString());
      return 'An error occurred: $e';
    }
  }

  Future<String?> sendForgotPasswordCode(String email) async {
    if (email.isEmpty) {
      return 'Email cannot be empty!';
    } else if (!EmailValidator.validate(email)) {
      return 'Email is not valid!';
    }

    try {
      final response = await service.addItem(
        endpointUrl: 'users/forgotpwd',
        itemData: {'email': email},
      );

      if (response.isOk) {
        final resBody = response.body;
        if (resBody is Map<String, dynamic> && resBody['success'] == true) {
          log('Verification code sent to $email');
          return null;
        } else if (resBody is Map && resBody.containsKey('message')) {
          return 'Failed: ${resBody['message']}';
        } else {
          return 'Failed to send code. Unexpected response.';
        }
      } else {
        final resBody = response.body;
        if (resBody is Map && resBody.containsKey('message')) {
          return 'Error: ${resBody['message']}';
        } else if (resBody is List && resBody.isNotEmpty) {
          return 'Error: ${resBody[0]}';
        } else {
          return 'Error: ${response.statusText ?? "Unknown error"}';
        }
      }
    } catch (e) {
      log(e.toString());
      return 'An error occurred: $e';
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (email.isEmpty || code.isEmpty || newPassword.isEmpty) {
      return 'All fields are required!';
    } else if (!validatePassword(newPassword)) {
      return 'Please use a stronger password!';
    }

    try {
      final response = await service.addItem(
        endpointUrl: 'users/verifypwd',
        itemData: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );

      if (response.isOk) {
        final Map<String, dynamic> resBody = response.body;
        if (resBody['success'] == true) {
          log('Password reset successful for $email');
          return null;
        } else {
          return 'Failed: ${resBody['message']}';
        }
      } else {
        return 'Error: ${response.body?['message'] ?? response.statusText}';
      }
    } catch (e) {
      log(e.toString());
      return 'An error occurred: $e';
    }
  }

  Future<void> saveLoginInfo(User? loginUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = json.encode(loginUser?.toJson());
    await prefs.setString(USER_INFO_BOX, userJsonString);
  }

  Future<User?> getLoginUsr() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonString = prefs.getString(USER_INFO_BOX);

      if (userJsonString != null) {
        final userMap = json.decode(userJsonString) as Map<String, dynamic>;
        final user = User.fromJson(userMap);

        print("Loaded user from SharedPreferences: ${user.sId}");
        return user;
      } else {
        print("ℹNo user info found in SharedPreferences.");
      }
    } catch (e, stack) {
      print("Error while loading user from SharedPreferences: $e");
      print(stack);
    }

    return null;
  }

  Future<void> logOutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(USER_INFO_BOX);
    Get.offAll(const LoginScreen());
  }

  String? _isEmailPasswordValid(String email, String password) {
    bool isEmailEmpty = email.trim().toLowerCase().isEmpty;
    bool isPasswordEmpty = password.isEmpty;
    bool isValidEmail = EmailValidator.validate(email.trim().toLowerCase());
    bool isStrongPassword = validatePassword(password);

    if (isEmailEmpty && isPasswordEmpty) {
      return 'Email and password cannot be empty!';
    } else if (isEmailEmpty) {
      return 'Email cannot be empty!';
    } else if (isPasswordEmpty) {
      return 'Password cannot be empty!';
    } else if (!isValidEmail) {
      return 'Email is not valid!';
    } else if (!isStrongPassword) {
      return 'Please use strong password!';
    }
    return null;
  }
}
