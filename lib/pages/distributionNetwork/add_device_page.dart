import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sunboxcloud/utils/toast_utils.dart';
import '../../controllers/station_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_status_dialog.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  String? _stationId;
  String? _stationName;
  String? _cpSn;
  String? _replaceDeviceId;

  bool _isEmulator = false;
  bool _isScanning = false;
  bool _isBluetoothOn = false;

  List<ScanResult> _scanResults = [];
  final Set<String> _foundDeviceIds = {};
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    _stationId = arguments?['stationId'];
    _stationName = arguments?['stationName'];
    _cpSn = arguments?['cpSn'];
    _replaceDeviceId = arguments?['deviceId'];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    // 1. 判断是否为模拟器
    _isEmulator = await _checkIfEmulator();
    if (_isEmulator) {
      if (mounted) {
        setState(() {});
        ToastUtils.warning('simulator_no_bluetooth'.tr, title: 'info'.tr);
      }
      return;
    }

    // 2. 检查并请求权限
    bool hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      if (mounted) {
        ToastUtils.warning(
          'bluetooth_location_permission_hint'.tr,
          title: 'info'.tr,
        );
      }
      return;
    }

    // 3. 监听蓝牙开关状态
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() {
          _isBluetoothOn = state == BluetoothAdapterState.on;
        });
        if (_isBluetoothOn) {
          _startScan();
        } else {
          _stopScan();
          ToastUtils.warning(
            'enable_bluetooth_msg'.tr,
            title: 'bluetooth_not_enabled'.tr,
          );
        }
      }
    });

    // 4. 监听扫描结果
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted && _isScanning) {
        // 过滤出名称全称为 "AZ" 的设备
        final azDevices = results.where((r) {
          final name = r.device.platformName;
          return name == 'AZ';
        }).toList();

        // 检查是否有新发现产生的设备
        for (var r in azDevices) {
          if (!_foundDeviceIds.contains(r.device.remoteId.str)) {
            _foundDeviceIds.add(r.device.remoteId.str);
            ToastUtils.success(
              '${'device_found_msg'.tr}: ${r.device.platformName}',
            );
          }
        }

        setState(() {
          // 按信号强度排序
          _scanResults = azDevices..sort((a, b) => b.rssi.compareTo(a.rssi));
        });
      }
    });
  }

  Future<bool> _checkIfEmulator() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    }
    return false;
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};
    if (Platform.isAndroid) {
      statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    } else if (Platform.isIOS) {
      statuses = await [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ].request();
    }

    return statuses.values.every((status) => status.isGranted);
  }

  void _startScan() async {
    if (_isEmulator || !_isBluetoothOn || _isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _foundDeviceIds.clear();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Start scan failed: $e');
    }

    // 扫描结束后更新状态
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  void _stopScan() async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (!_isEmulator) {
      _stopScan();
      _scanResultsSubscription.cancel();
      _adapterStateSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white12,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'add_collector'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Radar UI
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE6EFFF),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFD4E4FF),
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFC0D9FF),
                      ),
                    ),
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animationController.value * 2 * math.pi,
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0x662B5CFF),
                                    Color(0xFF2B5CFF),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.2, 0.25, 0.25],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 状态文本
            if (_isEmulator)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'simulator_no_bluetooth'.tr,
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              )
            else if (!_isBluetoothOn)
              Text(
                'bluetooth_not_enabled'.tr,
                style: const TextStyle(fontSize: 16, color: Colors.redAccent),
              )
            else if (_isScanning)
              Text(
                'scanning_nearby'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              )
            else
              Text(
                'scan_finished'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                text: 'ensure_bluetooth_enabled'.tr,
                style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            // 设备列表展示
            Expanded(
              child: _scanResults.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning
                            ? 'searching_for_devices'.tr
                            : 'no_devices_found'.tr,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _scanResults.length,
                      itemBuilder: (context, index) {
                        final result = _scanResults[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE6EFFF),
                              child: Icon(
                                Icons.bluetooth,
                                color: Color(0xFF2B5CFF),
                              ),
                            ),
                            title: Text(
                              result.device.platformName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text('RSSI: ${result.rssi} dBm'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Get.toNamed(
                                  AppRoutes.distributionNetwork,
                                  arguments: {
                                    'stationId': _stationId,
                                    'stationName': _stationName,
                                    'cpSn': _cpSn,
                                    'replaceDeviceId': _replaceDeviceId,
                                    'deviceName': result.device.platformName,
                                    'deviceId': result.device.remoteId.str,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B5CFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'connect_device'.tr,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),
            Text(
              'device_power_hint'.tr,
              style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Expanded(
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       _showManualAddDialog();
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color(0xFF2B5CFF),
                  //       foregroundColor: Colors.white,
                  //       padding: const EdgeInsets.symmetric(vertical: 14),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(24),
                  //       ),
                  //       elevation: 0,
                  //     ),
                  //     child: Text(
                  //       'manual_add_title'.tr,
                  //       style: const TextStyle(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isScanning
                          ? null
                          : () {
                              if (_isBluetoothOn && !_isEmulator) {
                                _startScan();
                              } else if (!_isBluetoothOn) {
                                ToastUtils.warning(
                                  'bluetooth_not_enabled'.tr,
                                  title: 'info'.tr,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isScanning
                            ? Colors.grey
                            : const Color(0xFF2B5CFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isScanning ? 'scanning_nearby'.tr : 'rescan_btn'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _addDevice(String sn) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final StationController controller = Get.find<StationController>();
      Map<String, dynamic> response;

      if (_replaceDeviceId != null && _replaceDeviceId!.isNotEmpty) {
        // 更换采集棒逻辑
        final Map<String, dynamic> data = {
          'cpSn': sn,
          'deviceId': _replaceDeviceId,
        };
        response = await controller.replaceDevice(data);
      } else {
        // 添加设备逻辑
        final Map<String, dynamic> data = {
          'cpSn': sn,
          if (_stationId != null) 'stationId': _stationId,
          if (_stationName != null) 'stationName': _stationName,
        };
        response = await controller.addDevice(data);
      }

      Get.back(); // 关闭加载框

      if (response['code'] == 200) {
        CustomStatusDialog.show(
          type: CustomDialogType.success,
          message: 'device_added_success'.tr,
          onConfirm: () {
            Get.offAllNamed(AppRoutes.home); // 返回首页
          },
        );
      } else {
        CustomStatusDialog.show(
          type: CustomDialogType.error,
          message: response['msg'] ?? 'device_added_failed'.tr,
        );
      }
    } catch (e) {
      Get.back();
      developer.log(
        'Failed to add/replace device: $e',
        name: 'AddDevicePage',
        error: e,
      );
      CustomStatusDialog.show(
        type: CustomDialogType.error,
        message: 'device_added_failed'.tr,
      );
    }
  }

  void _showManualAddDialog() {
    final TextEditingController snController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('manual_add_title'.tr),
        content: TextField(
          controller: snController,
          decoration: InputDecoration(
            hintText: 'enter_sn_hint_text'.tr,
            labelText: 'sn_label'.tr,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              final sn = snController.text.trim();
              if (sn.isEmpty) {
                ToastUtils.warning('please_enter_sn_msg'.tr);
                return;
              }
              Get.back();
              _addDevice(sn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B5CFF),
              foregroundColor: Colors.white,
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }
}
