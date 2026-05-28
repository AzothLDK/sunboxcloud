import 'dart:convert' as convert;
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:sunboxcloud/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/storage.dart';
import '../../utils/network/api_service.dart';
import '../../utils/network/http_manager.dart' show host;
import '../../utils/toast_utils.dart';
import '../mine/my_site_page.dart';

class MeTab extends StatefulWidget {
  const MeTab({super.key});

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  final AuthController authController = Get.find<AuthController>();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
  }

  String _getAvatarUrl(Map<String, dynamic>? userInfo) {
    if (userInfo == null) return '';
    String avatar = userInfo['avatar'] ?? '';
    if (avatar.isNotEmpty) {
      final token = GlobalStorage.getToken() ?? '';
      return '${host}admin/system/file/readFile?recordId=$avatar&token=$token';
    }
    return '';
  }

  String _getDisplayName(Map<String, dynamic>? userInfo) {
    if (userInfo == null) return '';
    return userInfo['nickName'] ?? userInfo['userName'] ?? '';
  }

  String _getInitials(String username) {
    if (username.isEmpty) return 'U';
    final words = username.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length > 1 ? 2 : 1).toUpperCase();
  }

  Future<void> _showImageSourceDialog() async {
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'select_avatar'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'take_photo'.tr,
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_outlined,
                  label: 'choose_from_gallery'.tr,
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    final userInfo = authController.userInfo.value;
    final userId = userInfo?['userId'] ?? '';
    if (userId.isEmpty) {
      ToastUtils.error('user_id_not_found'.tr);
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
        'userId': userId,
      });

      final response = await ApiService.editUser(formData);

      if (response['code'] == 200) {
        // 使用封装好的 GetX 方法重新获取并更新用户信息
        await authController.fetchUserInfoAndRouters();
        ToastUtils.success('avatar_updated'.tr);
      } else {
        ToastUtils.error(response['msg'] ?? 'upload_failed'.tr);
      }
    } catch (e) {
      developer.log('Upload avatar failed: $e', name: 'MeTab');
      ToastUtils.error('upload_failed'.tr);
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
        child: Obx(() {
          final userInfo = authController.userInfo.value;
          final avatarUrl = _getAvatarUrl(userInfo);
          final displayName = _getDisplayName(userInfo);
          final email = userInfo?['email'] ?? '';

          return Column(
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
                          child: avatarUrl.isNotEmpty
                              ? (avatarUrl.startsWith('http')
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  _getInitials(displayName),
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              );
                                            },
                                      )
                                    : Image.file(
                                        File(avatarUrl),
                                        fit: BoxFit.cover,
                                      ))
                              : Center(
                                  child: Text(
                                    _getInitials(displayName),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (_isUploading)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (!_isUploading)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName.isNotEmpty ? displayName : 'User Name',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email.isNotEmpty ? email : 'user@example.com',
                style: const TextStyle(fontSize: 14, color: textLightColor),
              ),
              const SizedBox(height: 40),
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
                        child: const Icon(
                          Icons.location_on,
                          color: primaryColor,
                        ),
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
                      onTap: () => Get.to(() => const SitePage()),
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
                        child: const Icon(
                          Icons.device_hub,
                          color: primaryColor,
                        ),
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
                      onTap: () => Get.toNamed(AppRoutes.myDevices),
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
                      onTap: () => Get.toNamed(AppRoutes.feedback),
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
                      onTap: () => Get.toNamed(AppRoutes.settings),
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
          );
        }),
      ),
    );
  }
}
