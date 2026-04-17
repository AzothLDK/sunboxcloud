import 'dart:convert' as convert;
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:sunboxcloud/routes/app_routes.dart';
import '../../utils/constants.dart';
import '../../utils/storage.dart';
import '../../utils/network/api_service.dart';
import '../../utils/network/http_manager.dart' show host;
import '../../pages/site_page.dart';

class MeTab extends StatefulWidget {
  const MeTab({super.key});

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  String _username = '';
  String _email = '';
  String _avatar = '';
  String _userId = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final userInfoJson = GlobalStorage.getLoginInfo();
    final token = GlobalStorage.getToken() ?? '';
    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      try {
        final userInfo =
            convert.jsonDecode(userInfoJson) as Map<String, dynamic>;
        String avatar = userInfo['avatar'] ?? '';
        if (avatar.isNotEmpty) {
          avatar =
              '${host}admin/system/file/readFile?recordId=$avatar&token=$token';
        }
        setState(() {
          _username = userInfo['nickName'] ?? userInfo['userName'] ?? '';
          _email = userInfo['email'] ?? '';
          _avatar = avatar;
          _userId = userInfo['userId'] ?? '';
        });
      } catch (e) {
        developer.log('Failed to parse user info: $e', name: 'MeTab');
      }
    }
  }

  String _getInitials() {
    if (_username.isEmpty) return 'U';
    final words = _username.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return _username.substring(0, _username.length > 1 ? 2 : 1).toUpperCase();
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
      _uploadAvatar(File(image.path));
    }
  }

  Future<void> _uploadAvatar(File imageFile) async {
    if (_userId.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'user_id_not_found'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String fileName = imageFile.path.split('/').last;
      dio.FormData formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'userId': _userId,
      });

      final response = await ApiService.editUser(formData);

      if (response['code'] == 200) {
        final userInfoResponse = await ApiService.getLoginInfo();
        if (userInfoResponse['code'] == 200 &&
            userInfoResponse['data'] != null) {
          final userData = userInfoResponse['data'] as Map<String, dynamic>;
          final user = userData['user'] as Map<String, dynamic>?;
          if (user != null) {
            await GlobalStorage.saveLoginInfo(user);
            _loadUserInfo();
          }
        }
        Get.snackbar(
          'success'.tr,
          'avatar_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          colorText: primaryColor,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          response['msg'] ?? 'upload_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      developer.log('Upload avatar failed: $e', name: 'MeTab');
      Get.snackbar(
        'error'.tr,
        'upload_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _showImageSourceDialog,
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
                        child: _avatar.isNotEmpty
                            ? (_avatar.startsWith('http')
                                  ? Image.network(
                                      _avatar,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                                  : Image.file(
                                      File(_avatar),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                                    ))
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
                    onTap: _isUploading ? null : _showImageSourceDialog,
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
                      child: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _username.isNotEmpty ? _username : 'not_set'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _email.isNotEmpty ? _email : 'not_set'.tr,
              style: TextStyle(fontSize: 14, color: textLightColor),
            ),
            const SizedBox(height: 60),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on, color: primaryColor),
                    ),
                    title: Text(
                      'site'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: textLightColor,
                    ),
                    onTap: () {
                      Get.to(const SitePage());
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.device_hub, color: primaryColor),
                    ),
                    title: Text(
                      'device'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: textLightColor,
                    ),
                    onTap: () {
                      Get.toNamed(AppRoutes.myDevices);
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.feedback, color: primaryColor),
                    ),
                    title: Text(
                      'feedback'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: textLightColor,
                    ),
                    onTap: () {
                      Get.toNamed(AppRoutes.feedback);
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings, color: primaryColor),
                    ),
                    title: Text(
                      'settings'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: textLightColor,
                    ),
                    onTap: () {
                      Get.toNamed(AppRoutes.settings);
                    },
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 12, color: textLightColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
