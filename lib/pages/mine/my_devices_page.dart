import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../model/device_model.dart';
import '../../model/station_model.dart';

class MyDevicesPage extends StatelessWidget {
  const MyDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StationController controller = Get.find<StationController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => Text(
            controller.selectedStation?.stationName ?? 'devices'.tr,
            style: const TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: textColor),
            onPressed: () => _showStationSelectionDialog(context, controller),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                if (controller.stations.length > 1) {
                  return PopupMenuButton<StationModel>(
                    onSelected: (station) =>
                        controller.selectStation(station.id ?? ''),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    color: Colors.white,
                    itemBuilder: (context) => controller.stations.map((
                      station,
                    ) {
                      final isSelected =
                          controller.selectedStationId.value == station.id;
                      return PopupMenuItem<StationModel>(
                        value: station,
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Text(
                                station.stationName ?? '',
                                style: TextStyle(
                                  color: isSelected ? primaryColor : textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.selectedStation?.stationName ??
                                'select_site'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: textColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 20),
              Expanded(
                child: Obx(() {
                  if (controller.isDevicesLoading.value &&
                      controller.devices.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.devices.isEmpty) {
                    return _buildEmptyState(context, controller);
                  }

                  return ListView.builder(
                    itemCount: controller.devices.length,
                    itemBuilder: (context, index) {
                      final device = controller.devices[index];
                      return _buildDeviceItem(device, controller);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStationSelectionDialog(
    BuildContext context,
    StationController controller,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'select_station'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.stations.length,
                itemBuilder: (context, index) {
                  final station = controller.stations[index];
                  return ListTile(
                    title: Text(station.stationName ?? ''),
                    onTap: () async {
                      Get.back();
                      final result = await Get.toNamed(
                        '/distribution-network',
                        arguments: {'stationId': station.id},
                      );
                      if (result == true) {
                        controller.refreshCurrentStation();
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: primaryColor,
              ),
              title: Text(
                'add_new_station'.tr,
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Get.back();
                _showNewStationNameDialog(controller);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showNewStationNameDialog(StationController controller) {
    final TextEditingController nameController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('new_station'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'enter_station_name'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Get.back();
                final result = await Get.toNamed(
                  '/distribution-network',
                  arguments: {'stationName': name},
                );
                if (result == true) {
                  // 新增站点后，需要刷新整个站点列表以获取最新数据
                  await controller.fetchStations();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, StationController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
            color: textLightColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'no_device_linked'.tr,
            style: const TextStyle(fontSize: 16, color: textLightColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showStationSelectionDialog(context, controller),
            icon: const Icon(Icons.add),
            label: Text('add_device'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(DeviceModel device, StationController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.battery_charging_full,
              color: primaryColor,
              size: 24,
            ),
          ),
        ),
        title: Text(
          device.deviceType ?? '',
          style: const TextStyle(fontWeight: FontWeight.w500, color: textColor),
        ),
        subtitle: Text(
          'SN:${device.sn ?? ''}',
          style: const TextStyle(fontSize: 12, color: textLightColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (device.status == 'online' ? Colors.green : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: device.status == 'online'
                          ? Colors.green
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    device.status?.capitalizeFirst ?? 'Offline',
                    style: TextStyle(
                      fontSize: 11,
                      color: device.status == 'online'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _confirmDelete(device, controller),
            ),
          ],
        ),
        onTap: () => Get.toNamed('/device-detail', arguments: device.toJson()),
      ),
    );
  }

  void _confirmDelete(DeviceModel device, StationController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_device'.tr),
        content: Text('${'confirm_delete_device'.tr} ${device.deviceName}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await controller.removeDevice(device.id ?? '');
              if (success) {
                Get.snackbar('success'.tr, 'device_deleted_successfully'.tr);
              }
            },
            child: Text(
              'confirm'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
