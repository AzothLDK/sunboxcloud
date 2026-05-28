import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../utils/constants.dart';
import '../../utils/network/api_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../controllers/station_controller.dart';
import '../../routes/app_routes.dart';

class DeviceDetailPage extends StatelessWidget {
  const DeviceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final device = Get.arguments as Map<String, dynamic>?;
    if (device == null) {
      return Scaffold(
        appBar: AppBar(title: Text('device_detail'.tr)),
        body: Center(child: Text('no_data'.tr)),
      );
    }

    final model = device['model'] as Map<String, dynamic>?;
    final deviceName = device['deviceType'] ?? '';
    final deviceCode = device['deviceCode'] ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: backgroundColor,
            icon: const Icon(Icons.settings, color: textColor),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, deviceName, device['id'] ?? '');
              } else if (value == 'change') {
                Get.toNamed(
                  AppRoutes.scan,
                  arguments: {'deviceId': device['id']},
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'change',
                height: 45,
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: textColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'change_collector'.tr,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'delete',
                height: 45,
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'delete_device'.tr,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              color: Colors.white,
              child: Column(
                children: [
                  Image.asset(
                    'assets/sndevicelite.png',
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Container(
                      width: 120,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.battery_charging_full,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'SN:$deviceCode',
                    style: TextStyle(fontSize: 14, color: textLightColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(Icons.electrical_services, 'Inverter', [
                    _buildSpecRow(
                      'Rated AC Voltage',
                      '${model?['ratedVoltage'] ?? '-'}V',
                    ),
                    _buildSpecRow(
                      'Rated Grid Frequency',
                      '${model?['frequencySpec'] ?? '-'}Hz',
                    ),
                    _buildSpecRow(
                      'Max PV Input Voltage',
                      '${model?['maxInputVoltage'] ?? '-'}V',
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSectionCard(Icons.battery_charging_full, 'Battery', [
                    _buildSpecRow(
                      'Battery Type',
                      model?['batteryCellType'] ?? '-',
                    ),
                    _buildSpecRow(
                      'Capacity',
                      '${model?['batteryCapacity'] ?? '-'}kWh',
                    ),
                    _buildSpecRow('Charging Cycles', '- cycles'),
                  ]),
                  const SizedBox(height: 12),
                  _buildSectionCard(Icons.list_alt, 'General Specifications', [
                    _buildSpecRow('Brand', model?['brand'] ?? '-'),
                    _buildSpecRow('Device Type', model?['deviceType'] ?? '-'),
                    _buildSpecRow(
                      'Installation Date',
                      device['installationDate'] ?? '-',
                    ),
                    _buildSpecRow(
                      'Warranty Years',
                      '${model?['warrantyYears'] ?? '-'} years',
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(IconData icon, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: textLightColor)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String deviceName,
    String deviceId,
  ) {
    CustomConfirmDialog.show(
      context: context,
      title: 'delete_device'.tr,
      content: '${'confirm_delete_device'.tr} "$deviceName"?',
      confirmText: 'delete'.tr,
      onConfirm: () async {
        Navigator.pop(context);
        final StationController controller = Get.find<StationController>();
        final success = await controller.removeDevice(deviceId);
        if (success) {
          Get.back(result: true);
          ToastUtils.success('device_deleted_successfully'.tr);
        }
      },
    );
  }
}
