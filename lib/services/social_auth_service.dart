import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sunboxcloud/utils/network/api_service.dart';
import 'package:sunboxcloud/utils/storage.dart';
import 'package:sunboxcloud/controllers/auth_controller.dart';

class SocialAuthService extends GetxService {
  static SocialAuthService get to => Get.find();

  final isLoading = false.obs;
  GoogleSignInAccount? _currentUser;
  final isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      const String serverClientId =
          '945881485770-pricm03pjrng1pr094hfk463gl38sql9.apps.googleusercontent.com';
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);

      GoogleSignIn.instance.authenticationEvents.listen((event) {
        developer.log(
          'Google Sign-In event: $event',
          name: 'SocialAuthService',
        );
        _currentUser = switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          _ => null,
        };
      });

      final result = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      if (result != null) {
        // Get idToken
        final auth = result.authentication;
        final idToken = auth.idToken;

        if (idToken != null) {
          final response = await ApiService.loginByGoogleToken({
            'access_token': idToken,
          });
          if (response['code'] == 200) {
            if (response['data'] != null) {
              GlobalStorage.saveToken(response['data']);
            }

            AuthController authController;
            try {
              authController = Get.find<AuthController>();
            } catch (e) {
              authController = Get.put(AuthController());
            }

            await authController.fetchUserInfoAndRouters();

            Get.offAllNamed('/home');
          }
        }
        developer.log(
          'Lightweight auth result: $result',
          name: 'SocialAuthService',
        );
        isInitialized.value = true;
      }
    } catch (e) {
      developer.log(
        'Google Sign-In initialization error (likely configuration missing): $e',
        name: 'SocialAuthService',
        error: e,
      );
      isInitialized.value = true;
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      isLoading.value = true;

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();
      if (googleUser == null) {
        developer.log('Google sign in cancelled', name: 'SocialAuthService');
        return null;
      }

      _currentUser = googleUser;

      final googleAuth = await googleUser.authentication;

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
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        developer.log(
          'Google sign in cancelled by user',
          name: 'SocialAuthService',
        );
      } else {
        developer.log(
          'Google sign in error: ${e.code} - ${e.description}',
          name: 'SocialAuthService',
          error: e,
        );
      }
      return null;
    } catch (e) {
      developer.log(
        'Google sign in error: $e',
        name: 'SocialAuthService',
        error: e,
      );
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

  Future<void> signOutFromApple() async {
    try {
      // Apple does not have a formal programmatic "sign out" method that invalidates sessions
      // from the client side like Google does. We just clear any local states if we had any.
      developer.log('Apple sign out success', name: 'SocialAuthService');
    } catch (e) {
      developer.log(
        'Apple sign out error: $e',
        name: 'SocialAuthService',
        error: e,
      );
    }
  }

  GoogleSignInAccount? get currentUser => _currentUser;
}
