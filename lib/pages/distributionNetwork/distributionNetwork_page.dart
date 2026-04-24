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
  final TextEditingController _ssidController = TextEditingController(
    text: '晟能科技',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'wxSN2015',
  );
  final TextEditingController _bleNameController = TextEditingController(
    text: 'AZ',
  );
  final TextEditingController _userDataController = TextEditingController();

  final TextEditingController _qrCodeController = TextEditingController();

  String? _stationId;
  String? _stationName;

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

      final results = await WiFiScan.instance.getScannedResults();
      Get.back();

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
                      subtitle: Text(
                        '${'signal_strength'.tr}: ${network.level} dBm',
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
          AlertDialog(
            title: Text('info'.tr),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                child: Text(
                  'confirm'.tr,
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
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

  /// Start the linking process after checking permissions.
  Future<void> _startLinking() async {
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
        userData: _qrCodeController.text.trim().isNotEmpty
            ? _qrCodeController.text.trim()
            : _userDataController.text.trim(),
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

  /// Navigate to scan page and get result
  Future<void> _scanQRCode() async {
    final result = await Get.toNamed(AppRoutes.scan);
    if (result != null && result is String) {
      setState(() {
        _qrCodeController.text = result;
      });
      ToastUtils.success('device_info_obtained'.tr);
    }
  }

  Future<void> _addDevice() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      // SVProgressHUD.show();
      final now = DateTime.now();
      final sn =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}'
          '${now.millisecond.toString().padLeft(3, '0')}';

      final Map<String, dynamic> data = {
        'cpSn': sn,
        if (_stationId != null) 'stationId': _stationId,
        if (_stationName != null) 'stationName': _stationName,
      };

      final result = await ApiService.addDevice(data);
      Get.back();
      if (result['code'] == 200) {
        Get.back(result: true);
        ToastUtils.success('device_added_success'.tr);
      } else {
        ToastUtils.error(result['msg'] ?? 'device_added_failed'.tr);
      }
    } catch (e) {
      Get.back();
      developer.log(
        'Failed to add device: $e',
        name: 'DistributionNetworkPage',
        error: e,
      );
      ToastUtils.error('device_added_failed'.tr);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'device_network_config'.tr,
          style: const TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.4),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _qrCodeController,
                              label: 'device_qr_info'.tr,
                              icon: Icons.qr_code_scanner,
                              hint: 'scan_device_qr_hint'.tr,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            onPressed: _scanQRCode,
                            icon: const Icon(Icons.center_focus_weak),
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
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
                          IconButton.filledTonal(
                            onPressed: _scanWifiNetworks,
                            icon: const Icon(Icons.list),
                            style: IconButton.styleFrom(
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
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _bleNameController,
                        enabled: false,
                        label: 'ble_device_name'.tr,
                        icon: Icons.bluetooth,
                        hint: 'ble_name_default'.tr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                ValueListenableBuilder<_LinkingState>(
                  valueListenable: _stateNotifier,
                  builder: (context, state, child) {
                    return Column(
                      children: [
                        _buildStatusDisplay(state, colorScheme),
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
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildStatusDisplay(_LinkingState state, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: state.isLinking
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.isLinking ? colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          if (state.isLinking) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
          ] else ...[
            Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              state.message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: state.isLinking
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
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
              child: FilledButton(
                onPressed: state.isLinking ? null : _startLinking,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'start_config'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonal(
                onPressed: state.isLinking ? _stopLinking : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'stop_config'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: state.isLinking ? null : _addDevice,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'simulate_add_device'.tr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
