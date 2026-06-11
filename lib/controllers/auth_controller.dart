import 'dart:developer' as developer;
import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunboxcloud/services/social_auth_service.dart';
import 'package:sunboxcloud/utils/network/crypto_util.dart';
import '../utils/network/api_service.dart';
import '../utils/storage.dart';
import '../utils/toast_utils.dart';
import 'station_controller.dart';

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

  // 路由数据
  final routers = <Map<String, dynamic>>[].obs;

  // 用户信息
  final userInfo = Rxn<Map<String, dynamic>>();

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

    // 初始化用户信息
    _loadUserInfo();

    // 从本地存储读取保存的语言设置
    currentLanguageIndex.value = GlobalStorage.getLanguage();

    // 初始化社交登录服务
    _initSocialAuthService();

    // 如果已登录，则初始化站点控制器并获取最新信息
    final token = GlobalStorage.getToken();
    if (token != null && token.isNotEmpty) {
      Get.put(StationController(), permanent: true);
      // 静默获取用户信息和路由，不阻塞 UI
      fetchUserInfoAndRouters();
    }
  }

  void _loadUserInfo() {
    final info = GlobalStorage.getLoginInfo();
    if (info != null) {
      try {
        userInfo.value = convert.jsonDecode(info) as Map<String, dynamic>;
      } catch (e) {
        developer.log('Error decoding user info: $e', name: 'AuthController');
      }
    }
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
      ToastUtils.error(
        'please_enter_email_password'.tr,
        title: 'login_failed'.tr,
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
          // 登录成功后注入 StationController
          if (Get.isRegistered<StationController>()) {
            Get.find<StationController>().fetchStations(); // 如果已存在，手动刷新数据
          } else {
            Get.put(
              StationController(),
              permanent: true,
            ); // 如果不存在，通过 put 触发 onInit
          }
        }

        await fetchUserInfoAndRouters();

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
        ToastUtils.error(
          response['msg'] ?? 'unknown_error'.tr,
          title: 'login_failed'.tr,
        );
      }
    } catch (e) {
      developer.log('Login Exception: $e', name: 'AuthController', error: e);
      ToastUtils.error(e.toString(), title: 'login_failed'.tr);
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
      ToastUtils.error('please_enter_email'.tr, title: 'error'.tr);
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.sendEmailCode({
        'email': email.value.trim(),
        'codeType': codeType,
      });

      if (response['code'] == 200) {
        ToastUtils.success('verification_code_sent'.tr);
      } else {
        ToastUtils.error(response['msg'] ?? 'send_code_failed'.tr);
      }
    } catch (e) {
      developer.log(
        'Send verification code error: $e',
        name: 'AuthController',
        error: e,
      );
      ToastUtils.error('send_code_failed'.tr);
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
    GlobalStorage.saveLanguage(index);
    update();
  }

  // 获取翻译文本
  String translate(String key) {
    return key.tr;
  }

  Future<void> loginWithApple() async {
    if (_socialAuthService == null) {
      ToastUtils.error('social_login_not_available'.tr);
      return;
    }

    isLoading.value = true;
    try {
      final result = await _socialAuthService!.signInWithApple();

      if (result != null) {
        developer.log('Apple login success: $result', name: 'AuthController');

        final identityToken = result['identityToken'];
        if (identityToken == null || identityToken.toString().isEmpty) {
          ToastUtils.error('apple_token_not_found'.tr);
          return;
        }

        final response = await ApiService.loginByAppleToken({
          'idToken': identityToken,
        });

        if (response['code'] == 200) {
          developer.log(
            'Apple backend login success: $response',
            name: 'AuthController',
          );

          if (response['data'] != null) {
            GlobalStorage.saveToken(response['data']);
            // 登录成功后注入 StationController
            if (Get.isRegistered<StationController>()) {
              Get.find<StationController>().fetchStations(); // 如果已存在，手动刷新数据
            } else {
              Get.put(
                StationController(),
                permanent: true,
              ); // 如果不存在，通过 put 触发 onInit
            }
          }

          await fetchUserInfoAndRouters();

          ToastUtils.success('apple_login_success'.tr);
          Get.offNamed('/home');
        } else if (response['code'] == 206) {
          developer.log(
            'Apple user not found, need to register',
            name: 'AuthController',
          );

          final email = result['email'];
          if (email == null || email.toString().isEmpty) {
            ToastUtils.error('apple_email_not_found'.tr);
            return;
          }

          ToastUtils.info('apple_user_need_register'.tr);

          Get.toNamed('/apple-register', arguments: {'email': email});
        } else {
          ToastUtils.error(
            response['msg'] ?? 'apple_login_failed'.tr,
            title: 'login_failed'.tr,
          );
        }
      } else {
        ToastUtils.warning(
          'apple_login_cancelled'.tr,
          title: 'login_failed'.tr,
        );
      }
    } catch (e) {
      developer.log('Apple login error: $e', name: 'AuthController', error: e);
      ToastUtils.error(e.toString(), title: 'login_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // 谷歌登录
  Future<void> loginWithGoogle() async {
    if (_socialAuthService == null) {
      ToastUtils.error('social_login_not_available'.tr);
      return;
    }

    isLoading.value = true;
    try {
      final result = await _socialAuthService!.signInWithGoogle();

      if (result != null) {
        developer.log('Google login success: $result', name: 'AuthController');

        final idToken = result['idToken'];
        if (idToken == null || idToken.toString().isEmpty) {
          ToastUtils.error('google_token_invalid'.tr, title: 'login_failed'.tr);
          return;
        }

        final response = await ApiService.loginByGoogleToken({
          'access_token': idToken,
        });

        if (response['code'] == 200) {
          developer.log(
            'Google backend login success: $response',
            name: 'AuthController',
          );

          if (response['data'] != null) {
            GlobalStorage.saveToken(response['data']);
            // 登录成功后注入 StationController
            if (Get.isRegistered<StationController>()) {
              Get.find<StationController>().fetchStations(); // 如果已存在，手动刷新数据
            } else {
              Get.put(
                StationController(),
                permanent: true,
              ); // 如果不存在，通过 put 触发 onInit
            }
          }

          await fetchUserInfoAndRouters();

          ToastUtils.success('google_login_success'.tr);
          Get.offNamed('/home');
        } else if (response['code'] == 206) {
          developer.log(
            'Google user not found, need to register',
            name: 'AuthController',
          );

          final email = result['email'];
          if (email == null || email.toString().isEmpty) {
            ToastUtils.error('google_email_not_found'.tr);
            return;
          }

          // ToastUtils.info('google_user_need_register'.tr);

          Get.toNamed('/google-register', arguments: {'email': email});
        } else {
          ToastUtils.error(
            response['msg'] ?? 'google_login_failed'.tr,
            title: 'login_failed'.tr,
          );
        }
      } else {
        ToastUtils.warning(
          'google_login_cancelled'.tr,
          title: 'login_failed'.tr,
        );
      }
    } catch (e) {
      developer.log('Google login error: $e', name: 'AuthController', error: e);
      ToastUtils.error(e.toString(), title: 'login_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserInfoAndRouters() async {
    try {
      final userInfo = await ApiService.getSunboxLoginInfo();
      developer.log('User Info: $userInfo', name: 'AuthController');
      if (userInfo['code'] == 200 && userInfo['data'] != null) {
        final userData = userInfo['data'] as Map<String, dynamic>;
        final user = userData['user'] as Map<String, dynamic>?;
        if (user != null) {
          await GlobalStorage.saveLoginInfo(user);
          this.userInfo.value = user;
        }

        List<dynamic> sysApps = userData['sysApps'] ?? [];
        bool foundAppId = false;

        for (var app in sysApps) {
          if (app is Map<String, dynamic> && app['appCode'] == 'sunbox-h-app') {
            String appId = app['appId'] ?? '';
            if (appId.isNotEmpty) {
              await GlobalStorage.saveAppId(appId);
              await fetchRouters();
              developer.log('成功保存appId: $appId', name: 'AuthController');
              foundAppId = true;
              break;
            }
          }
        }

        if (!foundAppId) {
          await fetchRouters();
          developer.log('未找到有效的SunCloud_APP应用配置', name: 'AuthController');
        }
      }
    } catch (e) {
      developer.log('Failed to get user info: $e', name: 'AuthController');
    }
  }

  Future<void> fetchRouters() async {
    try {
      String? appId = GlobalStorage.getAppId();
      if (appId == null) {
        developer.log('appId为空,无法获取路由', name: 'AuthController');
        routers.clear();
        update(); // 触发 UI 刷新
        return;
      }

      var response = await ApiService.getRouters({'appId': appId});

      if (response['code'] == 200 && response.containsKey('data')) {
        developer.log('Routers response: $response', name: 'AuthController');

        List<dynamic> routerList = response['data'] ?? [];
        routers.value = routerList.cast<Map<String, dynamic>>();

        developer.log(
          'Routers loaded: ${routers.length}',
          name: 'AuthController',
        );
      } else {
        developer.log('获取路由失败: ${response['msg']}', name: 'AuthController');
        // 出错时也清理 routers，避免一直 loading
        routers.clear();
      }
    } catch (e) {
      developer.log('获取路由失败: $e', name: 'AuthController', error: e);
      routers.clear();
    } finally {
      update(); // 无论成功失败，都通知 UI 刷新
    }
  }

  // 登出
  Future<void> logout() async {
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'logging_out'.tr,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // 调用社交登录服务的登出逻辑（如 Google / Apple 登出）
      if (_socialAuthService != null) {
        await _socialAuthService!.signOutFromGoogle();
        await _socialAuthService!.signOutFromApple();
      }

      await GlobalStorage.clearUserInfo();
      userInfo.value = null;
      emailController.clear();
      passwordController.clear();

      // 登出时销毁站点控制器，清除所有站点相关状态
      if (Get.isRegistered<StationController>()) {
        Get.delete<StationController>(force: true);
      }

      Get.offAllNamed('/login');
    } finally {
      // Get.offAllNamed 会自动销毁所有路由包括 Dialog，如果登出逻辑发生异常，则手动关闭 Dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
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
        developer.log('解析保存的凭证失败: $e', name: 'AuthController', error: e);
        return null;
      }
    }
    return null;
  }
}
