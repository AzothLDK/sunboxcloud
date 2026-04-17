import 'dart:async';
import 'dart:convert' as convert;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/network/api_service.dart';
import '../../utils/network/crypto_util.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());

  int _currentStep = 0;
  bool _isLoading = false;
  int _countdown = 0;
  Timer? _timer;
  String _currentEmail = '';
  String _newEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final response = await ApiService.getLoginInfo();
      if (response['code'] == 200 && response['user'] != null) {
        setState(() {
          _currentEmail = response['user']['email'] ?? '';
        });
      }
    } catch (e) {
      developer.log('Failed to load user info: $e', name: 'ChangeEmailPage');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      Get.snackbar(
        'error'.tr,
        'please_enter_valid_email'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    if (email == _currentEmail) {
      Get.snackbar(
        'error'.tr,
        'new_email_same_as_old'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.sendEmailCode({
        'email': email,
        'codeType': 'editEmail',
      });

      if (response['code'] == 200) {
        setState(() {
          _newEmail = email;
          _currentStep = 1;
        });
        _startCountdown();
        Get.snackbar(
          'success'.tr,
          'verification_code_sent'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          colorText: primaryColor,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          response['msg'] ?? 'send_code_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'send_code_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _codeFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
    }
    if (index == 5 && value.isNotEmpty) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length != 6) {
      Get.snackbar(
        'error'.tr,
        'please_enter_6_digit_code'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> verifyData = {
        'email': _newEmail,
        'code': code,
        'codeType': 'editEmail',
      };

      String jsonData = convert.jsonEncode(verifyData);
      String encryptedData = CryptoUtil.encryptRequest(jsonData);

      final response = await ApiService.verifyCode(encryptedData);

      if (response['code'] == 200) {
        await _editEmail();
      } else {
        Get.snackbar(
          'error'.tr,
          response['msg'] ?? 'verification_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'verification_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editEmail() async {
    try {
      final response = await ApiService.editEmail({
        'email': _currentEmail,
        'newEmail': _newEmail,
      });

      if (response['code'] == 200) {
        Get.dialog(
          AlertDialog(
            title: Text('success'.tr),
            content: Text('email_changed_successfully'.tr),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  final authController = Get.find<AuthController>();
                  authController.logout();
                },
                child: Text(
                  'confirm'.tr,
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          response['msg'] ?? 'email_change_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'email_change_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

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
          'change_email'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _currentStep == 0 ? _buildEmailStep() : _buildCodeStep(),
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'enter_new_email'.tr,
            style: TextStyle(fontSize: 16, color: textLightColor),
          ),
          const SizedBox(height: 16),
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
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'enter_email_hint'.tr,
                hintStyle: TextStyle(color: textLightColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: const Icon(Icons.email, color: textLightColor),
              ),
            ),
          ),
          if (_currentEmail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${'current_email'.tr}: $_currentEmail',
              style: TextStyle(fontSize: 12, color: textLightColor),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'send_verification_code'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              text: 'verification_code_sent_to'.tr,
              style: TextStyle(fontSize: 16, color: textLightColor),
              children: [
                TextSpan(
                  text: ' $_newEmail',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 50,
                height: 70,
                child: TextField(
                  controller: _codeControllers[index],
                  focusNode: _codeFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => _onCodeChanged(index, value),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'didnt_receive_code'.tr,
                style: TextStyle(fontSize: 14, color: textLightColor),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: (_countdown > 0 || _isLoading)
                    ? null
                    : _sendVerificationCode,
                child: Text(
                  _countdown > 0
                      ? '$_countdown ${'resend_in'.tr}'
                      : 'resend_code'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: _countdown > 0 ? textLightColor : primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'confirm'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
