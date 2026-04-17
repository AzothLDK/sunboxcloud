import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';

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
        title: const Text(
          'New Ticket',
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 工单类型
                const Text(
                  'Ticket Type',
                  style: TextStyle(
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
                              color: _ticketType == 0 ? primaryColor : borderColor,
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
                              const Text('Inquiry'),
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
                              color: _ticketType == 1 ? primaryColor : borderColor,
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
                              const Text('Device Issue'),
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
                      const Text(
                        'Device',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
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
                                  const Text('SunBox-H'),
                                  const Text(
                                    'SN:00212001249240444',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textLightColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textLightColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                
                // 详细描述
                const Text(
                  'Detailed Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Please describe your problem in detail...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 上传图片
                const Text(
                  'Upload Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: textLightColor),
                        SizedBox(height: 4),
                        Text('+', style: TextStyle(color: textLightColor)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 联系方式
                const Text(
                  'Contact',
                  style: TextStyle(
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
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _contactType == 0 ? primaryColor : borderColor,
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
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              const Text('Email'),
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
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _contactType == 1 ? primaryColor : borderColor,
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
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              const Text('Phone'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 邮箱输入
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                    suffixIcon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  controller: TextEditingController(text: '957123562@qq.com'),
                ),
                
                const SizedBox(height: 40),
                
                // 提交按钮
                ElevatedButton(
                  onPressed: () {
                    // 处理提交逻辑
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
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