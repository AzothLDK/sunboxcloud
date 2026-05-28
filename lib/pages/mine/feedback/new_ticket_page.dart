import 'dart:io';
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/constants.dart';
import '../../../utils/network/api_service.dart';
import '../../../utils/toast_utils.dart';
import '../../../utils/storage.dart';
import '../../../controllers/station_controller.dart';
import '../../../model/device_model.dart';

class NewTicketPage extends StatefulWidget {
  const NewTicketPage({super.key});

  @override
  State<NewTicketPage> createState() => _NewTicketPageState();
}

class _NewTicketPageState extends State<NewTicketPage> {
  // 工单类型：0 = Inquiry, 1 = Device Issue
  int _ticketType = 0;
  // 联系方式：0 = Email, 1 = Phone
  int _contactType = 0;
  // 设备选择
  bool _showDeviceSelector = false;

  String _userEmail = '';
  String _userPhone = '';

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  DeviceModel? _selectedDevice;
  final StationController _stationController = Get.find<StationController>();

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
        _userEmail = userInfo['email']?.toString() ?? '';
        _userPhone =
            userInfo['phonenumber']?.toString() ??
            userInfo['phone']?.toString() ??
            '';

        // 默认填充邮箱
        if (_userEmail.isNotEmpty) {
          _contactController.text = _userEmail;
        }
      } catch (e) {
        // Ignore parsing error
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ToastUtils.error('pick_image_failed'.tr);
    }
  }

  void _showImageSourceSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('take_photo'.tr),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('choose_from_gallery'.tr),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    final contactInfo = _contactController.text.trim();

    if (description.isEmpty) {
      ToastUtils.warning('please_enter_description'.tr);
      return;
    }

    if (contactInfo.isEmpty) {
      ToastUtils.warning('please_enter_contact'.tr);
      return;
    }

    if (_ticketType == 1 && _selectedDevice == null) {
      ToastUtils.warning('please_select_device'.tr);
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // 1. 上传图片
      List<String> imageUrls = [];
      for (var imageFile in _selectedImages) {
        Map<String, dynamic> uploadData = {'source': 'application'};
        final uploadResult = await ApiService.uploadImage(
          imageFile.path,
          data: uploadData,
        );
        if (uploadResult['code'] == 200) {
          // 假设返回的数据中有 url 字段
          final url = uploadResult['data']?['fileUrl'];
          if (url != null) {
            imageUrls.add(url);
          }
        }
      }

      // 2. 提交工单
      final Map<String, dynamic> data = {
        'ticketType': (_ticketType + 1).toString(), // 1咨询 2设备问题
        'remark': description,
        'contactType': _contactType + 1, // 1邮箱 2电话
        'contact': contactInfo,
        'picture': imageUrls.join(','),
        if (_ticketType == 2 && _selectedDevice != null) ...{
          'deviceId': _selectedDevice!.id,
          // 'stationId': int.tryParse(_selectedDevice!.stationId ?? '') ?? 0,
        },
      };

      final result = await ApiService.addWorkOrder(data);
      Get.back(); // 关闭进度弹窗

      if (result['code'] == 200) {
        Get.back(result: true); // 返回上一页并通知刷新
        ToastUtils.success('submit_success'.tr);
      } else {
        ToastUtils.error(result['msg'] ?? 'submit_failed'.tr);
      }
    } catch (e) {
      Get.back();
      ToastUtils.error('submit_failed'.tr);
    }
  }

  void _showDeviceList() {
    if (_stationController.devices.isEmpty) {
      ToastUtils.info('no_devices'.tr);
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'select_device'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _stationController.devices.length,
                itemBuilder: (context, index) {
                  final device = _stationController.devices[index];
                  return ListTile(
                    leading: const Icon(Icons.devices, color: primaryColor),
                    title: Text(device.deviceType ?? 'unknown'.tr),
                    subtitle: Text('SN: ${device.deviceCode ?? ''}'),
                    onTap: () {
                      setState(() {
                        _selectedDevice = device;
                      });
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
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
          'new_ticket'.tr,
          style: const TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 工单类型
                Text(
                  'ticket_type'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _ticketType = 0;
                            _showDeviceSelector = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _ticketType == 0
                                  ? primaryColor
                                  : borderColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _ticketType == 0
                                ? primaryColor.withOpacity(0.1)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Radio(
                                value: 0,
                                groupValue: _ticketType,
                                onChanged: (value) {
                                  setState(() {
                                    _ticketType = 0;
                                    _showDeviceSelector = false;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              Text('inquiry'.tr),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _ticketType = 1;
                            _showDeviceSelector = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _ticketType == 1
                                  ? primaryColor
                                  : borderColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _ticketType == 1
                                ? primaryColor.withOpacity(0.1)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Radio(
                                value: 1,
                                groupValue: _ticketType,
                                onChanged: (value) {
                                  setState(() {
                                    _ticketType = 1;
                                    _showDeviceSelector = true;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              Text('device_issue'.tr),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 设备选择（当选择 Device Issue 时显示）
                if (_showDeviceSelector)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'device'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showDeviceList,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.devices,
                                    color: primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDevice?.deviceType ??
                                          'select_device'.tr,
                                    ),
                                    if (_selectedDevice != null)
                                      Text(
                                        'SN: ${_selectedDevice!.deviceCode ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: textLightColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: textLightColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // 详细描述
                Text(
                  'detailed_description'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'please_describe_problem'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),

                const SizedBox(height: 24),

                // 上传图片
                Text(
                  'upload_images'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...List.generate(_selectedImages.length, (index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (_selectedImages.length < 5)
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  color: textLightColor,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '+',
                                  style: TextStyle(color: textLightColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // 联系方式
                Text(
                  'contact'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _contactType = 0;
                            _contactController.text = _userEmail;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _contactType == 0
                                  ? primaryColor
                                  : borderColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _contactType == 0
                                ? primaryColor.withOpacity(0.1)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Radio(
                                value: 0,
                                groupValue: _contactType,
                                onChanged: (value) {
                                  setState(() {
                                    _contactType = 0;
                                    _contactController.text = _userEmail;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              Text('email'.tr),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _contactType = 1;
                            _contactController.text = _userPhone;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _contactType == 1
                                  ? primaryColor
                                  : borderColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _contactType == 1
                                ? primaryColor.withOpacity(0.1)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Radio(
                                value: 1,
                                groupValue: _contactType,
                                onChanged: (value) {
                                  setState(() {
                                    _contactType = 1;
                                    _contactController.text = _userPhone;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              Text('phone'.tr),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 联系方式输入
                TextField(
                  controller: _contactController,
                  keyboardType: _contactType == 0
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: _contactType == 0
                        ? 'enter_email'.tr
                        : 'enter_phone'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),

                const SizedBox(height: 40),

                // 提交按钮
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'submit'.tr,
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
      ),
    );
  }
}
