import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_ble_link/smart_ble_link.dart';
import '../../utils/constants.dart';

/// Represents the state of the BLE linking process
class _LinkingState {
  final bool isLinking;
  final String message;

  const _LinkingState({this.isLinking = false, this.message = '请开始配网'});

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

  final ValueNotifier<_LinkingState> _stateNotifier = ValueNotifier(
    const _LinkingState(),
  );

  StreamSubscription<LinkingEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _checkSimulator();
    _initBleLink();
    _listenToEvents();
  }

  void _checkSimulator() {
    if (kReleaseMode) return;

    bool isSimulator = false;
    String message = '';

    if (Platform.isIOS) {
      isSimulator = !Platform.environment.containsKey('DYLD_INSERT_LIBRARIES');
      message = 'iOS 模拟器不支持蓝牙功能，请使用真机测试配网功能。';
    } else if (Platform.isAndroid) {
      isSimulator = _isAndroidEmulator();
      message = 'Android 模拟器不支持蓝牙功能，请使用真机测试配网功能。';
    }

    if (isSimulator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.dialog(
          AlertDialog(
            title: const Text('提示'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                child: Text('确定', style: TextStyle(color: primaryColor)),
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
          _updateState(message: '配网中：${event.message}');
        } else if (event is LinkingSuccess) {
          _updateState(
            message: '配网成功！\nMAC: ${event.mac}\nIP: ${event.ip}',
            isLinking: false,
          );
        } else if (event is LinkingError) {
          _updateState(message: '配网失败：${event.message}', isLinking: false);
        } else if (event is LinkingTimeout) {
          _updateState(message: '配网超时', isLinking: false);
        }
      },
      onError: (error) {
        developer.log(
          'Linking event error: $error',
          name: 'DistributionNetworkPage',
          error: error,
        );
        _updateState(message: '发生错误：$error', isLinking: false);
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
    _updateState(isLinking: true, message: '正在检查权限...');

    if (Platform.isAndroid) {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      final bool hasDenied = statuses.values.any((status) => !status.isGranted);
      if (hasDenied) {
        _updateState(isLinking: false, message: '需要位置和蓝牙权限才能进行配网！');
        return;
      }
    } else if (Platform.isIOS) {
      // iOS only requires bluetooth permission here.
      final PermissionStatus status = await Permission.bluetooth.request();
      if (!status.isGranted) {
        _updateState(isLinking: false, message: '需要蓝牙权限才能进行配网！');
        return;
      }
    }

    _updateState(message: '开始配网...');

    try {
      await SmartBleLink.startLinking(
        ssid: _ssidController.text.trim(),
        password: _passwordController.text.trim(),
        bleName: _bleNameController.text.trim(),
        userData: _userDataController.text.trim(),
        deviceFindingType: 3, // UDP+BLE mode
      );
    } catch (e) {
      developer.log(
        'Failed to start linking: $e',
        name: 'DistributionNetworkPage',
        error: e,
      );
      _updateState(isLinking: false, message: '启动配网失败');
    }
  }

  /// Stop the ongoing linking process.
  Future<void> _stopLinking() async {
    try {
      await SmartBleLink.stopLinking();
      _updateState(isLinking: false, message: '配网已停止');
    } catch (e) {
      developer.log(
        'Failed to stop linking: $e',
        name: 'DistributionNetworkPage',
        error: e,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备配网'),
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
                      _buildTextField(
                        controller: _ssidController,
                        label: 'Wi-Fi 名称 (SSID)',
                        icon: Icons.wifi,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Wi-Fi 密码',
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
                        label: '蓝牙设备名称',
                        icon: Icons.bluetooth,
                        hint: '默认为AZ',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _userDataController,
                        label: '自定义数据 (可选)',
                        icon: Icons.data_usage,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
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
    return Row(
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
            child: const Text(
              '开始配网',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton.tonal(
            onPressed: state.isLinking ? _stopLinking : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '停止配网',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
