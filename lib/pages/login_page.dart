import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants.dart';
import '../routes/app_routes.dart';
import 'setting/reset_password_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 语言切换按钮
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () => Get.toNamed(AppRoutes.language),
                  color: primaryColor,
                ),
              ),
              // 应用标志
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'SN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SunBox',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const Text(
                      'ENERGY',
                      style: TextStyle(fontSize: 14, color: textLightColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 邮箱输入框
              TextField(
                controller: authController.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'email'.tr,
                  hintText: 'enter_email'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 密码输入框
              Obx(
                () => TextField(
                  controller: authController.passwordController,
                  obscureText: !authController.isPasswordVisible.value,
                  decoration: InputDecoration(
                    labelText: 'password'.tr,
                    hintText: 'enter_password'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        authController.isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: textLightColor,
                      ),
                      onPressed: authController.togglePasswordVisibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 忘记密码链接
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Get.to(const ResetPasswordPage());
                  },
                  child: Text(
                    'forgot_password'.tr,
                    style: const TextStyle(color: primaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 登录按钮
              Obx(
                () => ElevatedButton(
                  onPressed: authController.isLoading.value
                      ? null
                      : authController.login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authController.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'login'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // 隐私政策同意
              Text(
                'by_continuing'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: textLightColor),
              ),

              const SizedBox(height: 16),

              // 社交登录
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 苹果登录按钮
                      GestureDetector(
                        onTap: authController.loginWithApple,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // 谷歌登录按钮
                      GestureDetector(
                        onTap: authController.loginWithGoogle,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 注册链接
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'start_journey'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: textLightColor),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    child: Text(
                      'register_here'.tr,
                      style: const TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
