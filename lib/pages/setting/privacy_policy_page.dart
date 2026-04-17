import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'privacy_policy'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'privacy_policy_title'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'last_updated'.tr,
                style: TextStyle(fontSize: 14, color: textLightColor),
              ),
              const SizedBox(height: 32),

              // 1. 我们是谁 / Who We Are
              Text(
                'section_1_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'section_1_content'.tr,
                style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
              ),
              const SizedBox(height: 24),

              // 2. 我们收集什么信息 / What We Collect
              Text(
                'section_2_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'section_2_content'.tr,
                style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
              ),
              const SizedBox(height: 24),

              // 3. 我们如何使用这些信息 / How We Use It
              Text(
                'section_3_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'section_3_content'.tr,
                style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
              ),
              const SizedBox(height: 24),

              // 4. 我们如何分享这些信息 / How We Share It
              Text(
                'section_4_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'section_4_content'.tr,
                style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
              ),
              const SizedBox(height: 24),

              // 5. 您的权利 / Your Rights
              Text(
                'section_5_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'section_5_content'.tr,
                style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
              ),
              const SizedBox(height: 24),

              // 6. 数据安全 / Security
              Text(
                'section_6_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'section_6_content'.tr,
                style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
              ),
              const SizedBox(height: 24),

              // 7. 国际数据传输 / International Transfers
              Text(
                'section_7_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'section_7_content'.tr,
                style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
