import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';

class MyDevicesPage extends StatelessWidget {
  const MyDevicesPage({super.key});

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
          'Device',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: textColor),
            onPressed: () {
              // 处理添加设备逻辑
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 位置下拉菜单
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SunBox',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: textLightColor),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 设备列表
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 设备项
                    ListTile(
                      leading: Container(
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
                      title: const Text(
                        'SunBox',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      subtitle: const Text(
                        'SN:00212001249240444',
                        style: TextStyle(fontSize: 12, color: textLightColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 在线状态
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Row(
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
                          ),
                          // 箭头
                          const Text(
                            '→ 点击具体',
                            style: TextStyle(fontSize: 12, color: primaryColor),
                          ),
                        ],
                      ),
                      onTap: () {
                        // 处理设备点击逻辑
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
