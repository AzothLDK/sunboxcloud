import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../routes/app_routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Get.back();
          },
        ),
        title: Text(
          'settings'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 功能列表
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 6),
                  // 账户设置
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: primaryColor),
                    ),
                    title: Text(
                      'account'.tr,
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
                      Get.toNamed(AppRoutes.account);
                      // 处理账户设置点击
                    },
                  ),
                  SizedBox(height: 6),
                  // 语言设置
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.language, color: primaryColor),
                    ),
                    title: Text(
                      'language'.tr,
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
                      Get.toNamed(AppRoutes.language);
                    },
                  ),
                  SizedBox(height: 6),
                  // 隐私政策
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield, color: primaryColor),
                    ),
                    title: Text(
                      'privacy_policy'.tr,
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
                      Get.toNamed(AppRoutes.privacyPolicy);
                      // 处理隐私政策点击
                    },
                  ),
                  SizedBox(height: 6),
                  // 通知设置
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: primaryColor,
                      ),
                    ),
                    title: Text(
                      'notifications'.tr,
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
                      Get.toNamed(AppRoutes.notificationSettings);
                      // 处理通知设置点击
                    },
                  ),
                  SizedBox(height: 6),
                  // 应用更新
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.system_update,
                        color: primaryColor,
                      ),
                    ),
                    title: Text(
                      'app_update'.tr,
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
                      Get.toNamed(AppRoutes.appUpdate);
                      // 处理应用更新点击
                    },
                  ),
                  SizedBox(height: 6),
                ],
              ),
            ),

            const Spacer(),

            // 登出按钮
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: () {
                  // 处理登出逻辑
                  Get.offNamed(AppRoutes.login);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'logout'.tr,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),


            // 版本信息
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                'version'.tr,
                style: TextStyle(fontSize: 12, color: textLightColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
