import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../utils/network/api_service.dart';
import '../../utils/toast_utils.dart';
import 'dart:developer' as developer;

class BackupReservePage extends StatefulWidget {
  final int batterySpare;
  final String deviceCode;

  const BackupReservePage({
    super.key,
    this.batterySpare = 20,
    this.deviceCode = '',
  });

  @override
  State<BackupReservePage> createState() => _BackupReservePageState();
}

class _BackupReservePageState extends State<BackupReservePage> {
  late bool _isEnabled;
  late double _progress;

  final double _minSoc = 5.0;
  final double _maxSoc = 50.0;

  @override
  void initState() {
    super.initState();
    _isEnabled = true;
    _progress = widget.batterySpare.toDouble().clamp(_minSoc, _maxSoc);
  }

  Future<void> _submitSettings() async {
    if (widget.deviceCode.isEmpty) {
      ToastUtils.error('device_code_empty'.tr);
      return;
    }
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final rpcType = _isEnabled ? 1 : 2;
      final value = _progress.round();

      final response = await ApiService.rpcControl({
        'deviceCode': widget.deviceCode,
        'rpcType': rpcType,
        'value': value,
      });

      Get.back();

      if (response['code'] == 200) {
        ToastUtils.success('settings_saved_success'.tr);
        Get.back(result: true);
      } else {
        ToastUtils.error(response['msg'] ?? 'settings_saved_failed'.tr);
      }
    } catch (e) {
      Get.back();
      developer.log(
        'Submit settings failed: $e',
        name: 'BackupReservePage',
        error: e,
      );
      ToastUtils.error('network_error'.tr);
    }
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
          'BSU Protection'.tr,
          style: const TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 卡片容器
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 顶部开关行
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Expanded(
                          //       child: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.start,
                          //         children: [
                          //           Text(
                          //             'enable_low_battery_protection'.tr,
                          //             style: const TextStyle(
                          //               fontSize: 18,
                          //               fontWeight: FontWeight.bold,
                          //               color: textColor,
                          //             ),
                          //           ),
                          //           const SizedBox(height: 4),
                          //           Text(
                          //             'low_battery_protection_desc'.tr,
                          //             style: const TextStyle(
                          //               fontSize: 13,
                          //               color: textLightColor,
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //     Switch(
                          //       value: _isEnabled,
                          //       activeColor: primaryColor,
                          //       onChanged: (val) {
                          //         setState(() {
                          //           _isEnabled = val;
                          //         });
                          //       },
                          //     ),
                          //   ],
                          // ),

                          // 当开关打开时显示下方内容
                          if (_isEnabled) ...[
                            // const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'lock_soc_threshold'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: textLightColor,
                                  ),
                                ),
                                Text(
                                  '${_progress.round()}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSlider(),
                            const SizedBox(height: 24),
                            _buildHintBox(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'confirm'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        // 计算视觉上的进度比例 (0.0 到 1.0)
        final double visualProgress =
            ((_progress - _minSoc) / (_maxSoc - _minSoc)).clamp(0.0, 1.0);

        return Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  // 将拖动位置转换为 SOC 值
                  final double ratio = (details.localPosition.dx / trackWidth)
                      .clamp(0.0, 1.0);
                  _progress = _minSoc + ratio * (_maxSoc - _minSoc);
                });
              },
              onTapDown: (details) {
                setState(() {
                  final double ratio = (details.localPosition.dx / trackWidth)
                      .clamp(0.0, 1.0);
                  _progress = _minSoc + ratio * (_maxSoc - _minSoc);
                });
              },
              child: Container(
                height: 32,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 背景轨道
                    Container(
                      height: 6,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // 浅色填充（可选，这里保持原有逻辑或微调）
                    Container(
                      height: 6,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // 实际进度条
                    Positioned(
                      left: 0,
                      child: Container(
                        height: 6,
                        width: trackWidth * visualProgress,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // 滑块按钮
                    Positioned(
                      left: trackWidth * visualProgress - 12,
                      top: -9,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var val in ['5%', '15%', '25%', '35%', '50%'])
                  Text(
                    val,
                    style: const TextStyle(fontSize: 12, color: Colors.black26),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHintBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE58F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: Color(0xFFFAAD14), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'low_battery_protection_hint'.tr,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF856404),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
