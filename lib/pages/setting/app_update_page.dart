import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';

class AppUpdatePage extends StatelessWidget {
  const AppUpdatePage({super.key});

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
          'app_update'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo 和名称
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 这里可以替换为实际的 Logo
                        Icon(Icons.home, size: 48, color: primaryColor),
                        SizedBox(height: 8),
                        Text(
                          'SunBox',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 版本号
                Text(
                  'Version:1.0.0',
                  style: TextStyle(fontSize: 14, color: textLightColor),
                ),
                const SizedBox(height: 40),
                // 更新按钮
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      'update'.tr,
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: textLightColor,
                    ),
                    onTap: () {
                      // 处理更新点击
                    },
                  ),
                ),
                const SizedBox(height: 80),
                // // 最新版本提示
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     vertical: 12,
                //     horizontal: 24,
                //   ),
                //   decoration: BoxDecoration(
                //     color: Colors.grey[200],
                //     borderRadius: BorderRadius.circular(24),
                //   ),
                //   child: Text(
                //     'already_latest_version'.tr,
                //     style: TextStyle(fontSize: 14, color: textLightColor),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
