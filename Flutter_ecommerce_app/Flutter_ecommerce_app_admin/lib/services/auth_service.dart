import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService extends GetxController {
  final isLoggedIn = false.obs;
  String? _token;

  String? get token => _token;

  static const _baseUrl = 'https://ecommerce-server-a6ma.onrender.com';

  @override
  void onInit() {
    super.onInit();
    loadToken();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    isLoggedIn.value = _token != null;
  }

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/admin/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      isLoggedIn.value = true;
      return true;
    } else {
      Get.snackbar("Login Failed", "Invalid username or password");
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    isLoggedIn.value = false;
    Get.offAllNamed('/login');
  }
}
