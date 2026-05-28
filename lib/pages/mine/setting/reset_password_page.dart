import 'dart:async';
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/constants.dart';
import '../../../utils/network/api_service.dart';
import '../../../utils/network/crypto_util.dart';
import '../../../utils/toast_utils.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  int _currentStep = 0;
  bool _isLoading = false;
  int _countdown = 0;
  Timer? _timer;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _verifiedEmail = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() {
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();
      final email = authController.userInfo.value?['email'] as String? ?? '';
      _emailController.text = email;
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    final hasValidChars = RegExp(
      r'^[A-Za-z0-9!@#$%^&*(),.?":{}|<>]+$',
    ).hasMatch(password);
    return password.length >= minPasswordLength &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password) &&
        hasValidChars;
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
      ToastUtils.error('please_enter_valid_email'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.sendEmailCode({
        'email': email,
        'codeType': 'resetPassword',
      });

      if (response['code'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        final returnedEmail = data?['email'] as String? ?? email;
        for (var controller in _codeControllers) {
          controller.clear();
        }
        setState(() {
          _verifiedEmail = returnedEmail;
          _currentStep = 1;
        });
        _startCountdown();
        ToastUtils.success('verification_code_sent'.tr);
      } else {
        ToastUtils.error(response['msg'] ?? 'send_code_failed'.tr);
      }
    } catch (e) {
      ToastUtils.error('send_code_failed'.tr);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
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
      ToastUtils.error('please_enter_6_digit_code'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> verifyData = {
        'email': _verifiedEmail,
        'code': code,
        'codeType': 'resetPassword',
      };

      String jsonData = convert.jsonEncode(verifyData);
      String encryptedData = CryptoUtil.encryptRequest(jsonData);

      final response = await ApiService.verifyCode(encryptedData);

      if (response['code'] == 200) {
        final userId = response['data'] as String? ?? '';
        setState(() {
          _userId = userId;
          _currentStep = 2;
        });
      } else {
        ToastUtils.error(response['msg'] ?? 'verification_failed'.tr);
      }
    } catch (e) {
      ToastUtils.error('verification_failed'.tr);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!_isPasswordValid(password)) {
      ToastUtils.error('password_requirements_not_met'.tr);
      return;
    }

    if (password != confirmPassword) {
      ToastUtils.error('passwords_do_not_match'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> resetData = {
        'userId': _userId,
        'password': password,
      };

      String jsonData = convert.jsonEncode(resetData);
      String encryptedData = CryptoUtil.encryptRequest(jsonData);

      final response = await ApiService.resetPassword(encryptedData);

      if (response['code'] == 200) {
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'success'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'password_reset_success'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textLightColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        final authController = Get.find<AuthController>();
                        authController.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'confirm'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );
      } else {
        ToastUtils.error(response['msg'] ?? 'password_reset_failed'.tr);
      }
    } catch (e) {
      ToastUtils.error('password_reset_failed'.tr);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            if (_currentStep > 0) {
              setState(() {
                if (_currentStep == 2) {
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                } else if (_currentStep == 1) {
                  for (var controller in _codeControllers) {
                    controller.clear();
                  }
                }
                _currentStep--;
              });
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          'reset_password'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _currentStep == 0
            ? _buildEmailStep()
            : _currentStep == 1
            ? _buildCodeStep()
            : _buildPasswordStep(),
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            'please_enter_email'.tr,
            style: TextStyle(fontSize: 16, color: textColor),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
            style: const TextStyle(color: textLightColor),
            decoration: InputDecoration(
              hintText: 'enter_email'.tr,
              hintStyle: TextStyle(color: textLightColor),
              filled: true,
              fillColor: const Color(0xFFEEEEEE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderColor),
              ),
              prefixIcon: const Icon(Icons.email, color: textLightColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'password_reset_note'.tr,
            style: TextStyle(fontSize: 14, color: textLightColor),
          ),
          const SizedBox(height: 40),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
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
                  text: ' $_verifiedEmail',
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
                      'verify'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'set_new_password'.tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'enter_new_password'.tr,
              hintStyle: TextStyle(color: textLightColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor),
              ),
              prefixIcon: const Icon(Icons.lock, color: textLightColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'confirm_new_password'.tr,
              hintStyle: TextStyle(color: textLightColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor),
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: textLightColor),
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
          const SizedBox(height: 16),
          _buildPasswordRequirements(),
          const SizedBox(height: 40),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
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
                      'reset'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final hasConfirmPassword = confirmPassword.isNotEmpty;
    final passwordsMatch = password == confirmPassword && hasConfirmPassword;
    final hasValidChars =
        RegExp(r'^[A-Za-z0-9!@#$%^&*(),.?":{}|<>]+$').hasMatch(password) ||
        password.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'password_requirements'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirement(
            password.length >= minPasswordLength,
            'password_length'.tr,
          ),
          const SizedBox(height: 8),
          _buildRequirement(
            RegExp(r'[a-z]').hasMatch(password),
            'password_lowercase'.tr,
          ),
          const SizedBox(height: 8),
          _buildRequirement(
            RegExp(r'[A-Z]').hasMatch(password),
            'password_uppercase'.tr,
          ),
          const SizedBox(height: 8),
          _buildRequirement(
            RegExp(r'[0-9]').hasMatch(password),
            'password_numbers'.tr,
          ),
          const SizedBox(height: 8),
          _buildRequirement(
            RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
            'password_special'.tr,
          ),
          const SizedBox(height: 8),
          _buildRequirement(hasValidChars, 'password_valid_chars'.tr),
          if (hasConfirmPassword) ...[
            const SizedBox(height: 8),
            _buildRequirement(passwordsMatch, 'passwords_match'.tr),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirement(bool isMet, String text) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          color: isMet ? successColor : textLightColor,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? successColor : textLightColor,
            ),
          ),
        ),
      ],
    );
  }
}
