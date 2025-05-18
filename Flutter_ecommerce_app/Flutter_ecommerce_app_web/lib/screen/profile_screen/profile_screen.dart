import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/user.dart';
import '../../utility/app_color.dart';
import '../../widget/navigation_tile.dart';
import '../../utility/animation/open_container_wrapper.dart';
import '../auth_screen/login_screen.dart';
import '../my_address_screen/my_address_screen.dart';
import '../my_order_screen/my_order_screen.dart';
import '../../utility/extensions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  io.File? _imageFile; // chỉ dùng cho mobile
  Uint8List? _webImageBytes; // dùng cho web
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _didInit = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _webImageBytes = bytes);
      } else {
        setState(() => _imageFile = io.File(picked.path));
      }
    }
  }

  void _initUserFields(User user) {
    if (_didInit) return;
    _nameController.text = user.name ?? "";
    _didInit = true;
  }

  Future<void> _saveProfile(User user) async {
    try {
      setState(() => _isLoading = true);

      String? imageUrl = user.imgUrl;

      if (kIsWeb && _webImageBytes != null) {
        imageUrl = await context.userProvider
            .uploadWebImageToCloudinary(_webImageBytes!);
      } else if (!kIsWeb && _imageFile != null && _imageFile!.existsSync()) {
        imageUrl =
            await context.userProvider.uploadImageToCloudinary(_imageFile!);
      }

      await context.userProvider.updateProfile(
        name: _nameController.text.trim(),
        password: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(),
        imageUrl: imageUrl,
      );

      if (mounted) {
        Get.snackbar("Success", "Profile updated");
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar("Error", e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 56.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Get.back(),
              ),
              elevation: 0.0,
              title: const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkAccent,
                ),
              ),
              backgroundColor: Colors.black.withOpacity(0),
            ),
          ),
        ),
      ),
      body: FutureBuilder<User?>(
        future: context.userProvider.getLoginUsr(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;
          _initUserFields(user);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundImage: _webImageBytes != null
                            ? MemoryImage(_webImageBytes!)
                            : _imageFile != null
                                ? FileImage(_imageFile!)
                                : (user.imgUrl != null &&
                                            user.imgUrl!.isNotEmpty
                                        ? NetworkImage(user.imgUrl!)
                                        : const AssetImage(
                                            'assets/images/profile_pic.png'))
                                    as ImageProvider,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () => _saveProfile(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.darkAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(fontSize: 18)),
                    ),
              const SizedBox(height: 40),
              const OpenContainerWrapper(
                nextScreen: MyOrderScreen(),
                child: NavigationTile(
                  icon: Icons.list,
                  title: 'Order History',
                ),
              ),
              const SizedBox(height: 15),
              const OpenContainerWrapper(
                nextScreen: MyAddressPage(),
                child: NavigationTile(
                  icon: Icons.location_on,
                  title: 'Shipping Address',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  context.userProvider.logOutUser();
                  Get.offAll(const LoginScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.darkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Logout', style: TextStyle(fontSize: 18)),
              ),
            ],
          );
        },
      ),
    );
  }
}
