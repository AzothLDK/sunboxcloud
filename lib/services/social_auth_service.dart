import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService extends GetxService {
  static SocialAuthService get to => Get.find();

  final isLoading = false.obs;
  GoogleSignInAccount? _currentUser;

  @override
  void onInit() {
    super.onInit();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      const String serverClientId =
          '945881485770-pricm03pjrng1pr094hfk463gl38sql9.apps.googleusercontent.com';
      // 在 Android 上，如果没有 google-services.json，初始化可能会报错
      // 这里可以尝试捕获它，并在以后按需初始化
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        _currentUser = switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          _ => null,
        };
      });
      await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (e) {
      developer.log(
        'Google Sign-In initialization error (likely configuration missing): $e',
        name: 'SocialAuthService',
        error: e,
      );
      // 不要重新抛出，允许应用继续运行
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      isLoading.value = true;

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();
      developer.log(
        'Google sign in result: $googleUser',
        name: 'SocialAuthService',
      );
      if (googleUser == null) {
        developer.log('Google sign in cancelled', name: 'SocialAuthService');
        return null;
      }

      _currentUser = googleUser;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final result = {
        'id': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'idToken': googleAuth.idToken,
      };

      developer.log(
        'Google sign in success: $result',
        name: 'SocialAuthService',
      );
      return result;
    } catch (e) {
      developer.log(
        'Google sign in error: $e',
        name: 'SocialAuthService',
        error: e,
      );
      // 捕获配置错误，防止应用崩溃
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      isLoading.value = true;

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final result = {
        'userIdentifier': credential.userIdentifier,
        'email': credential.email,
        'givenName': credential.givenName,
        'familyName': credential.familyName,
        'identityToken': credential.identityToken,
        'authorizationCode': credential.authorizationCode,
      };

      developer.log(
        'Apple sign in success: $result',
        name: 'SocialAuthService',
      );
      return result;
    } catch (e) {
      developer.log(
        'Apple sign in error: $e',
        name: 'SocialAuthService',
        error: e,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOutFromGoogle() async {
    try {
      await GoogleSignIn.instance.signOut();
      _currentUser = null;
      developer.log('Google sign out success', name: 'SocialAuthService');
    } catch (e) {
      developer.log(
        'Google sign out error: $e',
        name: 'SocialAuthService',
        error: e,
      );
    }
  }

  GoogleSignInAccount? get currentUser => _currentUser;
}
