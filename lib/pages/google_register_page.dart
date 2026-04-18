import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunboxcloud/utils/network/api_service.dart';
import 'package:sunboxcloud/utils/network/crypto_util.dart';
import '../utils/constants.dart';

class GoogleRegisterPage extends StatefulWidget {
  final String email;

  const GoogleRegisterPage({super.key, required this.email});

  @override
  State<GoogleRegisterPage> createState() => _GoogleRegisterPageState();
}

class _GoogleRegisterPageState extends State<GoogleRegisterPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'please_enter_password'.tr;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'password_too_short'.tr;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'passwords_do_not_match'.tr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> registerData = {
        'email': widget.email,
        'password': password,
        'confirmPassword': confirmPassword,
        'roleKey': 'SunBox-H_APP_Customer',
      };

      String jsonData = convert.jsonEncode(registerData);
      String encryptedData = CryptoUtil.encryptRequest(jsonData);

      final response = await ApiService.register(encryptedData);

      if (response['code'] == 200) {
        Get.snackbar(
          'success'.tr,
          'register_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAllNamed('/login');
        // Get.offNamed('/complete-profile', arguments: {'email': widget.email});
      } else {
        setState(() {
          _errorMessage = response['msg'] ?? 'register_failed'.tr;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'set_password'.tr,
          style: const TextStyle(color: textColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'google_register_title'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'google_register_subtitle'.tr,
                style: const TextStyle(fontSize: 14, color: textLightColor),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
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
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: textLightColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'confirm_password'.tr,
                  hintText: 'confirm_password_hint'.tr,
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
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: textLightColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'password_requirements'.tr,
                style: const TextStyle(fontSize: 12, color: textLightColor),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'register'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
