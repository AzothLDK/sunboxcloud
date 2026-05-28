import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_ble_link/smart_ble_link.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../utils/constants.dart';
import '../../routes/app_routes.dart';
import '../../utils/toast_utils.dart';
import '../../utils/network/api_service.dart';
import '../../controllers/station_controller.dart';
import '../../widgets/custom_status_dialog.dart';

/// Represents the state of the BLE linking process
class _LinkingState {
  final bool isLinking;
  final String message;

  const _LinkingState({this.isLinking = false, this.message = ''});

  _LinkingState copyWith({bool? isLinking, String? message}) {
    return _LinkingState(
      isLinking: isLinking ?? this.isLinking,
      message: message ?? this.message,
    );
  }
}

/// Page for configuring the distribution network via Smart BLE Link.
class DistributionNetworkPage extends StatefulWidget {
  const DistributionNetworkPage({super.key});

  @override
  State<DistributionNetworkPage> createState() =>
      _DistributionNetworkPageState();
}

class _DistributionNetworkPageState extends State<DistributionNetworkPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bleNameController = TextEditingController();
  final TextEditingController _userDataController = TextEditingController();

  String _cpSn = '';
  String? _stationId;
  String? _stationName;
  String? _replaceDeviceId;

  final ValueNotifier<_LinkingState> _stateNotifier = ValueNotifier(
    const _LinkingState(),
  );

  StreamSubscription<LinkingEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    _stationId = arguments?['stationId'];
    _stationName = arguments?['stationName'];
    _replaceDeviceId = arguments?['replaceDeviceId'];
    _cpSn = arguments?['cpSn'] ?? '';

    if (arguments?['deviceName'] != null) {
      _bleNameController.text = arguments!['deviceName'];
    }
    _checkSimulator();
    _initBleLink();
    _listenToEvents();
    _getCurrentWifiSSID();
  }

  Future<void> _getCurrentWifiSSID() async {
    try {
      final info = NetworkInfo();
      String? ssid = await info.getWifiName();
      if (ssid != null) {
        // Remove quotes if present (iOS often adds them)
        if (ssid.startsWith('"') && ssid.endsWith('"')) {
          ssid = ssid.substring(1, ssid.length - 1);
        }
        setState(() {
          _ssidController.text = ssid!;
        });
      }
    } catch (e) {
      developer.log('Error getting WiFi SSID: $e');
    }
  }

  Future<void> _scanWifiNetworks() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      ToastUtils.error(
        'location_permission_for_wifi'.tr,
        title: 'permission_required'.tr,
      );
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        Get.back();
        ToastUtils.error(
          '${'cannot_start_wifi_scan'.tr}: $canScan',
          title: 'error_occurred'.tr,
        );
        return;
      }

      await WiFiScan.instance.startScan();
      await Future.delayed(const Duration(seconds: 2));

      //  final results = await WiFiScan.instance.getScannedResults();

      final rawResults = await WiFiScan.instance.getScannedResults();
      Get.back();

      // 过滤与去重逻辑
      final Map<String, WiFiAccessPoint> distinctMap = {};
      for (var ap in rawResults) {
        // 1. 过滤掉没有名称的
        if (ap.ssid.isEmpty) continue;

        // 2. 过滤掉 5G 频段的 (通常 5G 频率 > 5000MHz)
        if (ap.frequency > 5000) continue;

        // 3. 重名的选择信号最强的
        if (!distinctMap.containsKey(ap.ssid) ||
            ap.level > distinctMap[ap.ssid]!.level) {
          distinctMap[ap.ssid] = ap;
        }
      }

      final results = distinctMap.values.toList();

      if (results.isEmpty) {
        ToastUtils.warning('no_wifi_found'.tr);
        return;
      }

      results.sort((a, b) => b.level.compareTo(a.level));

      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'select_wifi_network'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final network = results[index];
                    return ListTile(
                      leading: const Icon(Icons.wifi),
                      title: Text(
                        network.ssid.isEmpty
                            ? 'unknown_network'.tr
                            : network.ssid,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'signal_strength'.tr}: ${network.level} dBm',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'BSSID: ${network.bssid} | ${'frequency'.tr}: ${network.frequency}MHz | ${'channel'.tr}: ${_calculateChannel(network.frequency)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      onTap: () {
                        setState(() {
                          _ssidController.text = network.ssid;
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
    } catch (e) {
      Get.back();
      developer.log('Error scanning WiFi: $e');
      ToastUtils.error('wifi_scan_failed'.tr);
    }
  }

  void _checkSimulator() {
    if (kReleaseMode) return;

    bool isSimulator = false;
    String message = '';

    if (Platform.isIOS) {
      isSimulator = !Platform.environment.containsKey('DYLD_INSERT_LIBRARIES');
      message = 'ios_simulator_no_bluetooth'.tr;
    } else if (Platform.isAndroid) {
      isSimulator = _isAndroidEmulator();
      message = 'android_simulator_no_bluetooth'.tr;
    }

    if (isSimulator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
                      Icons.info_outline,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'info'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
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
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'confirm'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
      });
    }
  }

  bool _isAndroidEmulator() {
    return Platform.environment.containsKey('ANDROID_EMULATOR') ||
        Platform.environment['RO_BUILD_PRODUCT'] == 'sdk' ||
        Platform.environment['RO_BUILD_ID']?.contains('sdk') == true;
  }

  /// Initialize the BLE link plugin.
  Future<void> _initBleLink() async {
    if (!kReleaseMode) {
      bool isSimulator = false;
      if (Platform.isIOS) {
        isSimulator = !Platform.environment.containsKey(
          'DYLD_INSERT_LIBRARIES',
        );
      } else if (Platform.isAndroid) {
        isSimulator = _isAndroidEmulator();
      }
      if (isSimulator) {
        return;
      }
    }
    try {
      await SmartBleLink.init();
      developer.log(
        'SmartBleLink initialized',
        name: 'DistributionNetworkPage',
      );
    } catch (e) {
      developer.log(
        'Failed to initialize SmartBleLink: $e',
        name: 'DistributionNetworkPage',
        error: e,
      );
    }
  }

  /// Listen to the linking events and update the UI.
  void _listenToEvents() {
    _eventSubscription = SmartBleLink.linkingEvents.listen(
      (event) {
        if (event is LinkingProgress) {
          _updateState(message: '${'configuring'.tr}: ${event.message}');
        } else if (event is LinkingSuccess) {
          _updateState(
            message:
                '${'config_success'.tr}\nMAC: ${event.mac}\nIP: ${event.ip}',
            isLinking: false,
          );
          // 配网成功后自动添加设备
          _addDevice(sn: _cpSn, mac: event.mac);
        } else if (event is LinkingError) {
          _updateState(
            message: '${'config_failed'.tr}: ${event.message}',
            isLinking: false,
          );
        } else if (event is LinkingTimeout) {
          _updateState(message: 'config_timeout'.tr, isLinking: false);
        }
      },
      onError: (error) {
        developer.log(
          'Linking event error: $error',
          name: 'DistributionNetworkPage',
          error: error,
        );
        _updateState(
          message: '${'error_occurred'.tr}: $error',
          isLinking: false,
        );
      },
    );
  }

  void _updateState({bool? isLinking, String? message}) {
    _stateNotifier.value = _stateNotifier.value.copyWith(
      isLinking: isLinking,
      message: message,
    );
  }

  int _calculateChannel(int frequency) {
    if (frequency >= 2412 && frequency <= 2484) {
      return (frequency - 2412) ~/ 5 + 1;
    } else if (frequency >= 5170 && frequency <= 5825) {
      return (frequency - 5170) ~/ 5 + 34;
    }
    return 0;
  }

  /// Start the linking process after checking permissions.
  Future<void> _startLinking() async {
    FocusScope.of(context).unfocus(); // 取消输入框聚焦，关闭键盘
    _updateState(isLinking: true, message: 'checking_permissions'.tr);

    if (Platform.isAndroid) {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      final bool hasDenied = statuses.values.any((status) => !status.isGranted);
      if (hasDenied) {
        _updateState(
          isLinking: false,
          message: 'location_bluetooth_permission_required'.tr,
        );
        return;
      }
    } else if (Platform.isIOS) {
      final PermissionStatus status = await Permission.bluetooth.request();
      if (!status.isGranted) {
        _updateState(
          isLinking: false,
          message: 'bluetooth_permission_required'.tr,
        );
        return;
      }
    }

    _updateState(message: 'starting_config'.tr);

    try {
      await SmartBleLink.startLinking(
        ssid: _ssidController.text.trim(),
        password: _passwordController.text.trim(),
        bleName: _bleNameController.text.trim(),
        userData: _cpSn.isNotEmpty ? _cpSn : _userDataController.text.trim(),
        deviceFindingType: 3,
      );
    } catch (e) {
      developer.log(
        'Failed to start linking: $e',
        name: 'DistributionNetworkPage',
        error: e,
      );
      _updateState(isLinking: false, message: 'config_start_failed'.tr);
    }
  }

  /// Stop the ongoing linking process.
  Future<void> _stopLinking() async {
    try {
      await SmartBleLink.stopLinking();
      _updateState(isLinking: false, message: 'config_stopped'.tr);
    } catch (e) {
      developer.log(
        'Failed to stop linking: $e',
        name: 'DistributionNetworkPage',
        error: e,
      );
    }
  }

  Future<void> _addDevice({String? sn, String? mac}) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      String cpSn = sn ?? '';
      if (cpSn.isEmpty) {
        final now = DateTime.now();
        cpSn =
            '${now.year}'
            '${now.month.toString().padLeft(2, '0')}'
            '${now.day.toString().padLeft(2, '0')}'
            '${now.hour.toString().padLeft(2, '0')}'
            '${now.minute.toString().padLeft(2, '0')}'
            '${now.second.toString().padLeft(2, '0')}'
            '${now.millisecond.toString().padLeft(3, '0')}';
      }

      final StationController controller = Get.find<StationController>();
      Map<String, dynamic> response;

      if (_replaceDeviceId != null && _replaceDeviceId!.isNotEmpty) {
        // 更换采集棒逻辑
        final Map<String, dynamic> data = {
          'cpSn': cpSn,
          'deviceId': _replaceDeviceId,
          'deviceMac': mac ?? '',
        };
        response = await controller.replaceDevice(data);
      } else {
        // 添加设备逻辑
        final Map<String, dynamic> data = {
          'cpSn': cpSn,
          'deviceMac': mac ?? '',
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
        name: 'DistributionNetworkPage',
        error: e,
      );
      CustomStatusDialog.show(
        type: CustomDialogType.error,
        message: 'device_added_failed'.tr,
      );
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _stateNotifier.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _bleNameController.dispose();
    _userDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'device_network_config'.tr,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'device_qr_info'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: textLightColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 20,
                          color: textLightColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _cpSn,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _ssidController,
                            label: 'wifi_name'.tr,
                            icon: Icons.wifi,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _scanWifiNetworks,
                          icon: const Icon(Icons.list, color: primaryColor),
                          style: IconButton.styleFrom(
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'wifi_password'.tr,
                      icon: Icons.lock,
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<_LinkingState>(
                valueListenable: _stateNotifier,
                builder: (context, state, child) {
                  return Column(
                    children: [
                      _buildStatusDisplay(state),
                      const SizedBox(height: 32),
                      _buildActionButtons(state),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      style: TextStyle(
        fontSize: 15,
        color: enabled ? textColor : textLightColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: textLightColor),
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: textLightColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildStatusDisplay(_LinkingState state) {
    if (state.message.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: state.isLinking
            ? primaryColor.withValues(alpha: 0.05)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.isLinking ? primaryColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (state.isLinking) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            const Icon(Icons.info_outline, color: textLightColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              state.message,
              style: TextStyle(
                fontSize: 14,
                color: state.isLinking ? primaryColor : textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(_LinkingState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: state.isLinking ? null : _startLinking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'start_config'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: state.isLinking ? _stopLinking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isLinking
                      ? errorColor
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'stop_config'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'ensure_24ghz_wifi'.tr,
          style: const TextStyle(color: textLightColor, fontSize: 12),
        ),
      ],
    );
  }
}
