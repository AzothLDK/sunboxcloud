import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants.dart';
import '../../../routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import 'edit_field_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthController authController = Get.find<AuthController>();

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
          'account'.tr,
          style: const TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Obx(() {
            final userInfo = authController.userInfo.value;
            final username =
                userInfo?['nickName'] ?? userInfo?['userName'] ?? '';
            final phone = userInfo?['phonenumber'] ?? userInfo?['phone'] ?? '';
            final email = userInfo?['email'] ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          'username'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textLightColor,
                          ),
                        ),
                        subtitle: Text(
                          username.isNotEmpty ? username : 'not_set'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: textLightColor,
                        ),
                        onTap: () async {
                          await Get.to(
                            () => EditFieldPage(
                              fieldType: EditFieldType.username,
                              currentValue: username,
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16),
                      ListTile(
                        title: Text(
                          'phone_number'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textLightColor,
                          ),
                        ),
                        subtitle: Text(
                          phone.isNotEmpty ? phone : 'not_set'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: textLightColor,
                        ),
                        onTap: () async {
                          await Get.to(
                            () => EditFieldPage(
                              fieldType: EditFieldType.phone,
                              currentValue: phone,
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16),
                      ListTile(
                        title: Text(
                          'email'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textLightColor,
                          ),
                        ),
                        subtitle: Text(
                          email.isNotEmpty ? email : 'not_set'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: textLightColor,
                        ),
                        onTap: () {
                          Get.toNamed(AppRoutes.changeEmail);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                OutlinedButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.resetPassword);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'reset_password'.tr,
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ),
      ),
    );
  }
}
