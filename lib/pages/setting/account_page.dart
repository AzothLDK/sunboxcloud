import 'dart:convert' as convert;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../utils/storage.dart';
import '../../routes/app_routes.dart';
import 'edit_field_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String _username = '';
  String _address = '';
  String _phone = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final userInfoJson = GlobalStorage.getLoginInfo();
    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      try {
        final userInfo =
            convert.jsonDecode(userInfoJson) as Map<String, dynamic>;
        setState(() {
          _username = userInfo['nickName'] ?? userInfo['userName'] ?? '';
          _address = userInfo['remark'] ?? '';
          _phone = userInfo['phonenumber'] ?? userInfo['phone'] ?? '';
          _email = userInfo['email'] ?? '';
        });
      } catch (e) {
        developer.log('Failed to parse user info: $e', name: 'AccountPage');
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
          'account'.tr,
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
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'username'.tr,
                        style: TextStyle(fontSize: 14, color: textLightColor),
                      ),
                      subtitle: Text(
                        _username.isNotEmpty ? _username : 'not_set'.tr,
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: textLightColor,
                      ),
                      onTap: () async {
                        final result = await Get.to(
                          () => EditFieldPage(
                            fieldType: EditFieldType.username,
                            currentValue: _username,
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _username = result;
                          });
                        }
                      },
                    ),
                    // const Divider(height: 1, indent: 16),
                    // ListTile(
                    //   title: Text(
                    //     'address'.tr,
                    //     style: TextStyle(fontSize: 14, color: textLightColor),
                    //   ),
                    //   subtitle: Text(
                    //     _address.isNotEmpty ? _address : 'not_set'.tr,
                    //     style: TextStyle(fontSize: 16, color: textColor),
                    //   ),
                    //   trailing: const Icon(
                    //     Icons.chevron_right,
                    //     color: textLightColor,
                    //   ),
                    //   onTap: () async {
                    //     final result = await Get.to(
                    //       () => EditFieldPage(
                    //         fieldType: EditFieldType.address,
                    //         currentValue: _address,
                    //       ),
                    //     );
                    //     if (result != null) {
                    //       setState(() {
                    //         _address = result;
                    //       });
                    //     }
                    //   },
                    // ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      title: Text(
                        'phone_number'.tr,
                        style: TextStyle(fontSize: 14, color: textLightColor),
                      ),
                      subtitle: Text(
                        _phone.isNotEmpty ? _phone : 'not_set'.tr,
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: textLightColor,
                      ),
                      onTap: () async {
                        final result = await Get.to(
                          () => EditFieldPage(
                            fieldType: EditFieldType.phone,
                            currentValue: _phone,
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _phone = result;
                          });
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      title: Text(
                        'email'.tr,
                        style: TextStyle(fontSize: 14, color: textLightColor),
                      ),
                      subtitle: Text(
                        _email.isNotEmpty ? _email : 'not_set'.tr,
                        style: TextStyle(fontSize: 16, color: textColor),
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
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // OutlinedButton(
              //   onPressed: () {
              //     // 处理删除账号
              //   },
              //   style: OutlinedButton.styleFrom(
              //     side: const BorderSide(color: Colors.red),
              //     padding: const EdgeInsets.symmetric(vertical: 16),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              //   child: Text(
              //     'delete_account'.tr,
              //     style: TextStyle(
              //       color: Colors.red,
              //       fontSize: 16,
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
