import 'dart:convert' as convert;
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sunboxcloud/utils/network/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/storage.dart';

class CompleteProfilePage extends StatefulWidget {
  final String email;

  const CompleteProfilePage({super.key, required this.email});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _avatarPath;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getInitials() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return 'U';
    final words = username.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length > 1 ? 2 : 1).toUpperCase();
  }

  Future<void> _showImageSourceDialog() async {
    await Get.dialog(
      AlertDialog(
        title: Text('select_avatar'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryColor),
              title: Text('take_photo'.tr),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryColor),
              title: Text('choose_from_gallery'.tr),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _avatarPath = image.path;
      });
    }
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'please_enter_username'.tr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userInfoJson = GlobalStorage.getLoginInfo();
      String? userId;
      if (userInfoJson != null && userInfoJson.isNotEmpty) {
        final userInfo =
            convert.jsonDecode(userInfoJson) as Map<String, dynamic>;
        userId = userInfo['userId'];
      }

      if (userId == null || userId.isEmpty) {
        setState(() {
          _errorMessage = 'user_id_not_found'.tr;
        });
        return;
      }

      dio.FormData formData = dio.FormData.fromMap({
        'userId': userId,
        'nickName': username,
        if (phone.isNotEmpty) 'phonenumber': phone,
      });

      if (_avatarPath != null) {
        String fileName = _avatarPath!.split('/').last;
        formData.files.add(
          MapEntry(
            'file',
            await dio.MultipartFile.fromFile(_avatarPath!, filename: fileName),
          ),
        );
      }

      final response = await ApiService.editUser(formData);

      if (response['code'] == 200) {
        final userInfoResponse = await ApiService.getLoginInfo();
        if (userInfoResponse['code'] == 200 &&
            userInfoResponse['data'] != null) {
          final userData = userInfoResponse['data'] as Map<String, dynamic>;
          final user = userData['user'] as Map<String, dynamic>?;
          if (user != null) {
            await GlobalStorage.saveLoginInfo(user);
          }
        }

        Get.snackbar(
          'success'.tr,
          'profile_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          colorText: primaryColor,
        );
        Get.offAllNamed('/home');
      } else {
        setState(() {
          _errorMessage = response['msg'] ?? 'update_failed'.tr;
        });
      }
    } catch (e) {
      developer.log('Complete profile error: $e', name: 'CompleteProfilePage');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _skip() async {
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'complete_profile'.tr,
          style: const TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'skip'.tr,
              style: const TextStyle(color: primaryColor, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.2),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: _avatarPath != null
                              ? Image.file(
                                  File(_avatarPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        _getInitials(),
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    _getInitials(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              spreadRadius: 0,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'tap_to_change_avatar'.tr,
                  style: const TextStyle(fontSize: 12, color: textLightColor),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'email'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  color: textLightColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  widget.email,
                  style: const TextStyle(fontSize: 16, color: textLightColor),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'username'.tr,
                  hintText: 'enter_username'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                  prefixIcon: const Icon(Icons.person, color: textLightColor),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'phone_number'.tr,
                  hintText: 'enter_phone_number'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                  prefixIcon: const Icon(Icons.phone, color: textLightColor),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'save_and_continue'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
