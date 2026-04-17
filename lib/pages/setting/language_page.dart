import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunboxcloud/utils/constants.dart' as LanguageManager;
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 返回按钮
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Get.back();
                },
                color: primaryColor,
              ),

              const SizedBox(height: 32),

              // 标题
              Text(
                'select_language'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 32),

              // 语言列表
              Obx(
                () => Column(
                  children: LanguageManager.languages.asMap().entries.map((
                    entry,
                  ) {
                    int index = entry.key;
                    String language = entry.value;
                    return RadioListTile<int>(
                      title: Text(
                        language,
                        style: const TextStyle(fontSize: 16, color: textColor),
                      ),
                      value: index,
                      groupValue: authController.currentLanguageIndex.value,
                      onChanged: (value) {
                        if (value != null) {
                          authController.switchLanguage(value);
                        }
                      },
                      activeColor: primaryColor,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
