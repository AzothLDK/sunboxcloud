import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/constants.dart';
import '../../utils/network/api_service.dart';
import '../../utils/toast_utils.dart';
import '../../controllers/station_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_status_dialog.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late MobileScannerController cameraController;
  bool _hasPermission = false;
  bool _isScanning = true;
  late AnimationController _animationController;
  final TextEditingController _manualSnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        cameraController.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        cameraController.stop();
        break;
      default:
        break;
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
    } else {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  void _showPermissionDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 权限图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              // 标题
              Text(
                'camera_permission_required'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // 内容
              Text(
                'camera_permission_denied_msg'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  color: textLightColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(
                          color: textLightColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        openAppSettings();
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
                        'go_to_settings'.tr,
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
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _handleScanResult(String code) async {
    // 1. 显示加载中
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 2. 验证 SN
      final response = await ApiService.checkSN(code);
      Get.back(); // 关闭加载框

      if (response['code'] == 200) {
        final args = Get.arguments as Map<String, dynamic>?;
        final stationId = args?['stationId'];
        final stationName = args?['stationName'];
        final deviceId = args?['deviceId'];

        // 验证成功，进入 AddDevicePage (AppRoutes.bleConfig)
        Get.offNamed(
          AppRoutes.bleConfig,
          arguments: {
            'cpSn': code,
            if (stationId != null) 'stationId': stationId,
            if (stationName != null) 'stationName': stationName,
            if (deviceId != null) 'deviceId': deviceId,
          },
        );
      } else {
        // 验证失败
        _showErrorDialog(response['msg'] ?? 'error_occurred'.tr);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back(); // 确保加载框关闭
      _showErrorDialog('network_error'.tr);
    }
  }

  Future<void> _handleMacResult(String mac) async {
    // 1. 显示加载中
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 2. 验证 MAC 并获取 SN
      final response = await ApiService.checkMac(mac);
      Get.back(); // 关闭加载框

      if (response['code'] == 200) {
        final sn = response['data']?.toString() ?? '';
        if (sn.isEmpty) {
          _showErrorDialog('invalid_sn'.tr);
          return;
        }

        final args = Get.arguments as Map<String, dynamic>?;
        final stationId = args?['stationId'];
        final stationName = args?['stationName'];
        final deviceId = args?['deviceId'];

        // 验证成功，进入 AddDevicePage (AppRoutes.bleConfig)
        Get.offNamed(
          AppRoutes.bleConfig,
          arguments: {
            'cpSn': sn,
            if (stationId != null) 'stationId': stationId,
            if (stationName != null) 'stationName': stationName,
            if (deviceId != null) 'deviceId': deviceId,
          },
        );
      } else {
        // 验证失败
        _showErrorDialog(response['msg'] ?? 'error_occurred'.tr);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back(); // 确保加载框关闭
      _showErrorDialog('network_error'.tr);
    }
  }

  void _showErrorDialog(String message) {
    CustomStatusDialog.show(
      type: CustomDialogType.error,
      message: message,
      onConfirm: () {
        // 延迟1秒后恢复扫描，防止重复触发
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isScanning = true;
            });
          }
        });
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    cameraController.dispose();
    _manualSnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'scan_qr_code'.tr,
          style: const TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: _hasPermission
            ? [
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: cameraController,
                    builder: (context, state, child) {
                      switch (state.torchState) {
                        case TorchState.off:
                          return const Icon(Icons.flash_off, color: textColor);
                        case TorchState.on:
                          return const Icon(
                            Icons.flash_on,
                            color: primaryColor,
                          );
                        default:
                          return const Icon(Icons.flash_off, color: textColor);
                      }
                    },
                  ),
                  onPressed: () => cameraController.toggleTorch(),
                ),
              ]
            : [],
      ),
      body: Column(
        children: [
          // 上部：扫描区域
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            if (_hasPermission)
                              MobileScanner(
                                controller: cameraController,
                                onDetect: (capture) {
                                  if (!_isScanning) return;
                                  final List<Barcode> barcodes =
                                      capture.barcodes;
                                  for (final barcode in barcodes) {
                                    if (barcode.rawValue != null) {
                                      _isScanning = false;
                                      _handleScanResult(barcode.rawValue!);
                                      break;
                                    }
                                  }
                                },
                              )
                            else
                              Container(
                                color: Colors.black87,
                                child: const Center(
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 48,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                            // 扫描动画线
                            if (_hasPermission)
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Positioned(
                                    top: _animationController.value * 240 + 5,
                                    left: 10,
                                    right: 10,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 4,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryColor.withValues(alpha: 0.1),
                                            primaryColor,
                                            primaryColor.withValues(alpha: 0.1),
                                          ],
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
                    const SizedBox(height: 16),
                    Text(
                      _hasPermission
                          ? 'put_qr_in_frame'.tr
                          : 'camera_permission_hint'.tr,
                      style: const TextStyle(
                        color: textLightColor,
                        fontSize: 14,
                      ),
                    ),
                    if (!_hasPermission) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _checkPermission,
                        child: Text(
                          'grant_permission'.tr,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // 下部：手动输入区域
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'manual_add_title'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textLightColor,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _manualSnController,
                    decoration: InputDecoration(
                      hintText: 'enter_sn_hint_text'.tr,
                      prefixIcon: const Icon(
                        Icons.edit_note,
                        color: textLightColor,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final sn = _manualSnController.text.trim();
                      if (sn.isEmpty) {
                        ToastUtils.warning('please_enter_sn_msg'.tr);
                        return;
                      }
                      _handleMacResult(sn);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'confirm'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
