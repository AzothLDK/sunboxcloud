import 'dart:convert' as convert;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide FormData;
import '../../utils/constants.dart';
import '../../utils/storage.dart';
import '../../utils/network/api_service.dart';
import 'package:dio/dio.dart';

enum EditFieldType { username, address, phone }

class EditFieldPage extends StatefulWidget {
  final EditFieldType fieldType;
  final String currentValue;

  const EditFieldPage({
    super.key,
    required this.fieldType,
    required this.currentValue,
  });

  @override
  State<EditFieldPage> createState() => _EditFieldPageState();
}

class _EditFieldPageState extends State<EditFieldPage> {
  late TextEditingController _controller;
  bool _isLoading = false;
  String _userId = '';

  String get _title {
    switch (widget.fieldType) {
      case EditFieldType.username:
        return 'edit_username'.tr;
      case EditFieldType.address:
        return 'edit_address'.tr;
      case EditFieldType.phone:
        return 'edit_phone'.tr;
    }
  }

  String get _hintText {
    switch (widget.fieldType) {
      case EditFieldType.username:
        return 'enter_username_hint'.tr;
      case EditFieldType.address:
        return 'enter_address_hint'.tr;
      case EditFieldType.phone:
        return 'enter_phone_hint'.tr;
    }
  }

  TextInputType get _keyboardType {
    switch (widget.fieldType) {
      case EditFieldType.phone:
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? get _inputFormatters {
    switch (widget.fieldType) {
      case EditFieldType.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return null;
    }
  }

  IconData get _icon {
    switch (widget.fieldType) {
      case EditFieldType.username:
        return Icons.person;
      case EditFieldType.address:
        return Icons.location_on;
      case EditFieldType.phone:
        return Icons.phone;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
    _loadUserId();
  }

  void _loadUserId() {
    final userInfoJson = GlobalStorage.getLoginInfo();
    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      try {
        final userInfo =
            convert.jsonDecode(userInfoJson) as Map<String, dynamic>;
        _userId = userInfo['userId'] ?? '';
      } catch (e) {
        developer.log('Failed to parse user info: $e', name: 'EditFieldPage');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'field_cannot_be_empty'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    if (_userId.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'user_id_not_found'.tr,
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
      Map<String, dynamic> data = {'userId': _userId};

      switch (widget.fieldType) {
        case EditFieldType.username:
          data['nickName'] = _controller.text.trim();
          break;
        case EditFieldType.address:
          data['address'] = _controller.text.trim();
          break;
        case EditFieldType.phone:
          data['phone'] = _controller.text.trim();
          data['phoneAreaCode'] = '+86';
          break;
      }

      FormData formData = FormData.fromMap(data);

      final response = await ApiService.editUser(formData);

      if (response['code'] == 200) {
        _updateLocalUserInfo();
        Get.back(result: _controller.text.trim());
        Get.snackbar(
          'success'.tr,
          'saved_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          colorText: primaryColor,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          response['msg'] ?? 'save_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      developer.log('Save failed: $e', name: 'EditFieldPage');
      Get.snackbar(
        'error'.tr,
        'save_failed'.tr,
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

  void _updateLocalUserInfo() {
    final userInfoJson = GlobalStorage.getLoginInfo();
    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      try {
        final userInfo =
            convert.jsonDecode(userInfoJson) as Map<String, dynamic>;
        switch (widget.fieldType) {
          case EditFieldType.username:
            userInfo['nickName'] = _controller.text.trim();
            break;
          case EditFieldType.address:
            userInfo['remark'] = _controller.text.trim();
            break;
          case EditFieldType.phone:
            userInfo['phonenumber'] = _controller.text.trim();
            userInfo['phone'] = _controller.text.trim();
            break;
        }
        GlobalStorage.saveLoginInfo(userInfo);
      } catch (e) {
        developer.log(
          'Failed to update local user info: $e',
          name: 'EditFieldPage',
        );
      }
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
          _title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
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
                child: TextField(
                  controller: _controller,
                  keyboardType: _keyboardType,
                  inputFormatters: _inputFormatters,
                  decoration: InputDecoration(
                    hintText: _hintText,
                    hintStyle: TextStyle(color: textLightColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(_icon, color: textLightColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
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
                          'save'.tr,
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
        ),
      ),
    );
  }
}
