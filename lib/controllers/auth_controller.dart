import 'dart:developer' as developer;
import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunboxcloud/services/social_auth_service.dart';
import 'package:sunboxcloud/utils/network/crypto_util.dart';
import '../utils/network/api_service.dart';
import '../utils/storage.dart';

class AuthController extends GetxController {
  // 登录表单
  final email = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final verificationCode = ''.obs;

  // TextEditingControllers 用于 UI 绑定
  late TextEditingController emailController;
  late TextEditingController passwordController;

  // 密码可见性
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // 加载状态
  final isLoading = false.obs;

  // 语言索引
  final currentLanguageIndex = 0.obs;

  // 社交登录服务
  SocialAuthService? _socialAuthService;

  @override
  void onInit() {
    super.onInit();

    emailController = TextEditingController();
    passwordController = TextEditingController();

    // 监听控制器变化同步到 obs
    emailController.addListener(() => email.value = emailController.text);
    passwordController.addListener(
      () => password.value = passwordController.text,
    );

    // 加载保存的凭据
    _loadSavedCredentials();

    // 根据当前语言设置初始化语言索引
    final currentLocale = Get.locale;
    if (currentLocale != null && currentLocale.languageCode == 'zh') {
      currentLanguageIndex.value = 1;
    } else {
      currentLanguageIndex.value = 0;
    }

    // 初始化社交登录服务
    _initSocialAuthService();
  }

  void _initSocialAuthService() {
    try {
      if (Get.isRegistered<SocialAuthService>()) {
        _socialAuthService = Get.find<SocialAuthService>();
      } else {
        _socialAuthService = Get.put(SocialAuthService());
      }
    } catch (e) {
      developer.log(
        'Failed to init social auth service: $e',
        name: 'AuthController',
        error: e,
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // 加载保存的账号密码
  void _loadSavedCredentials() {
    try {
      // 获取保存的密码
      final passwordInfoStr = GlobalStorage.getPassword();
      if (passwordInfoStr != null && passwordInfoStr.isNotEmpty) {
        final passwordInfo = convert.jsonDecode(passwordInfoStr);
        if (passwordInfo is Map && passwordInfo.containsKey('password')) {
          passwordController.text = passwordInfo['password'] ?? '';
        }
        if (passwordInfo is Map && passwordInfo.containsKey('username')) {
          emailController.text = passwordInfo['username'] ?? '';
        }
      }
    } catch (e) {
      developer.log(
        'Error loading saved credentials: $e',
        name: 'AuthController',
      );
    }
  }

  // 切换密码可见性
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // 登录
  Future<void> login() async {
    if (email.value.trim().isEmpty || password.value.trim().isEmpty) {
      Get.snackbar(
        'login_failed'.tr,
        'please_enter_email_password'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      // 构建登录请求对象
      Map<String, dynamic> loginData = {
        'userName': email.value,
        'password': password.value,
      };

      // 将请求对象转换为JSON字符串并加密
      String jsonData = convert.jsonEncode(loginData);
      String encryptedData = CryptoUtil.encryptRequest(jsonData); // 整个对象被加密

      final response = await ApiService.login(encryptedData);

      // http_manager 中已经统一处理了外层的异常和结构，直接判断 code 即可
      if (response['code'] == 200) {
        developer.log('Login successful: $response', name: 'AuthController');
        if (response['data'] != null) {
          GlobalStorage.saveToken(response['data']);
        }

        // 获取用户信息
        try {
          final userInfo = await ApiService.getLoginInfo();
          developer.log('User Info: $userInfo', name: 'AuthController');
          if (userInfo['code'] == 200 && userInfo['data'] != null) {
            final userData = userInfo['data'] as Map<String, dynamic>;
            final user = userData['user'] as Map<String, dynamic>?;
            if (user != null) {
              await GlobalStorage.saveLoginInfo(user);
            }
          }
        } catch (e) {
          developer.log('Failed to get user info: $e', name: 'AuthController');
        }

        // 导航到主页
        Get.offNamed('/home');
        // 如果选择记住密码，则保存密码
        // if (rememberPassword) {
        Map<String, dynamic> credentials = {
          'username': email.value,
          'password': password.value,
          'saveTime': DateTime.now().toIso8601String(),
        };
        await GlobalStorage.saveUserPassWord(credentials);
        // } else {
        //   // 否则清除保存的密码
        //   await GlobalStorage.deleteKeyValue('password');
        // }
      } else {
        Get.snackbar(
          'login_failed'.tr,
          response['msg'] ?? 'unknown_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      developer.log('Login Exception: $e', name: 'AuthController', error: e);
      Get.snackbar(
        'login_failed'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 注册
  Future<void> register() async {
    isLoading.value = true;
    // 模拟注册过程
    await Future.delayed(const Duration(seconds: 2));
    isLoading.value = false;
    // 注册成功后导航到登录页
    Get.offNamed('/login');
  }

  // 发送验证码
  Future<void> sendVerificationCode({String codeType = 'register'}) async {
    if (email.value.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_email'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.sendEmailCode({
        'email': email.value.trim(),
        'codeType': codeType,
      });

      if (response['code'] == 200) {
        Get.snackbar(
          'success'.tr,
          'verification_code_sent'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          response['msg'] ?? 'send_code_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      developer.log(
        'Send verification code error: $e',
        name: 'AuthController',
        error: e,
      );
      Get.snackbar(
        'error'.tr,
        'send_code_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 切换语言
  void switchLanguage(int index) {
    currentLanguageIndex.value = index;
    final locale = index == 0
        ? const Locale('en', 'US')
        : const Locale('zh', 'CN');
    Get.updateLocale(locale);
    update(); // 通知UI更新
  }

  // 获取翻译文本
  String translate(String key) {
    return key.tr;
  }

  // 苹果登录
  Future<void> loginWithApple() async {
    if (_socialAuthService == null) {
      Get.snackbar(
        'error'.tr,
        'social_login_not_available'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final result = await _socialAuthService!.signInWithApple();

      if (result != null) {
        developer.log('Apple login success: $result', name: 'AuthController');

        // TODO: 将Apple登录凭证发送到后端进行验证
        // final response = await ApiService.socialLogin({
        //   'provider': 'apple',
        //   'identityToken': result['identityToken'],
        //   'userIdentifier': result['userIdentifier'],
        //   'email': result['email'],
        //   'givenName': result['givenName'],
        //   'familyName': result['familyName'],
        // });

        // 模拟登录成功
        Get.snackbar(
          'success'.tr,
          'apple_login_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offNamed('/home');
      } else {
        Get.snackbar(
          'login_failed'.tr,
          'apple_login_cancelled'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      developer.log('Apple login error: $e', name: 'AuthController', error: e);
      Get.snackbar(
        'login_failed'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 谷歌登录
  Future<void> loginWithGoogle() async {
    if (_socialAuthService == null) {
      Get.snackbar(
        'error'.tr,
        'social_login_not_available'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final result = await _socialAuthService!.signInWithGoogle();

      if (result != null) {
        developer.log('Google login success: $result', name: 'AuthController');

        final idToken = result['idToken'];
        if (idToken == null || idToken.toString().isEmpty) {
          Get.snackbar(
            'login_failed'.tr,
            'google_token_invalid'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        // 调用后端谷歌登录接口
        final response = await ApiService.loginByGoogleToken({
          'access_token': idToken,
        });

        if (response['code'] == 200) {
          developer.log(
            'Google backend login success: $response',
            name: 'AuthController',
          );

          // 保存token
          if (response['data'] != null) {
            GlobalStorage.saveToken(response['data']);
          }

          // 获取用户信息
          try {
            final userInfo = await ApiService.getLoginInfo();
            if (userInfo['code'] == 200 && userInfo['data'] != null) {
              final userData = userInfo['data'] as Map<String, dynamic>;
              final user = userData['user'] as Map<String, dynamic>?;
              if (user != null) {
                await GlobalStorage.saveLoginInfo(user);
              }
            }
          } catch (e) {
            developer.log(
              'Failed to get user info: $e',
              name: 'AuthController',
            );
          }

          Get.snackbar(
            'success'.tr,
            'google_login_success'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offNamed('/home');
        } else if (response['code'] == 206) {
          developer.log(
            'Google user not found, need to register',
            name: 'AuthController',
          );

          final email = result['email'];
          if (email == null || email.toString().isEmpty) {
            Get.snackbar(
              'error'.tr,
              'google_email_not_found'.tr,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          Get.snackbar(
            'info'.tr,
            'google_user_need_register'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );

          Get.toNamed('/google-register', arguments: {'email': email});
        } else {
          Get.snackbar(
            'login_failed'.tr,
            response['msg'] ?? 'google_login_failed'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        Get.snackbar(
          'login_failed'.tr,
          'google_login_cancelled'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      developer.log('Google login error: $e', name: 'AuthController', error: e);
      Get.snackbar(
        'login_failed'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 登出
  Future<void> logout() async {
    await GlobalStorage.clearUserInfo();
    Get.offAllNamed('/login');
  }

  // 获取保存的账号密码
  Future<Map<String, String>?> getSavedCredentials() async {
    String? passwordStr = GlobalStorage.getPassword();

    if (passwordStr != null) {
      try {
        Map<String, dynamic> credentials = convert.jsonDecode(passwordStr);
        return {
          'username': credentials['username'] ?? '',
          'password': credentials['password'] ?? '',
        };
      } catch (e) {
        print('解析保存的凭证失败: $e');
        return null;
      }
    }
    return null;
  }
}
