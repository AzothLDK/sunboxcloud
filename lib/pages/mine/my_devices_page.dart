import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../model/device_model.dart';
import '../../model/station_model.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/custom_input_dialog.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'select_station'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: textLightColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Station List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.stations.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final station = controller.stations[index];
                  final isSelected =
                      controller.selectedStationId.value == station.id;
                  return InkWell(
                    onTap: () async {
                      Get.back();
                      final result = await Get.toNamed(
                        '/scan',
                        arguments: {'stationId': station.id},
                      );
                      if (result == true) {
                        controller.refreshCurrentStation();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.05)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.home_work_outlined,
                              size: 20,
                              color: isSelected ? Colors.white : primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.stationName ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                if (station.detailAddress != null &&
                                    station.detailAddress!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    station.detailAddress!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textLightColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Text(
                              'current_site'.tr,
                              style: const TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Add New Station Button
            Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  _showNewStationNameDialog(controller);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  elevation: 0,
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'add_new_station'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  void _showNewStationNameDialog(StationController controller) {
    final TextEditingController nameController = TextEditingController();
    CustomInputDialog.show(
      context: Get.context!,
      title: 'new_station'.tr,
      fields: [
        InputFieldConfig(
          label: 'site_name'.tr,
          hintText: 'enter_site_name'.tr,
          controller: nameController,
        ),
      ],
      onSave: () async {
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          Get.back();
          final result = await Get.toNamed(
            '/scan',
            arguments: {'stationName': name},
          );
          if (result == true) {
            await controller.fetchStations();
          }
        }
      },
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
          'SN:${device.deviceCode ?? ''}',
          style: const TextStyle(fontSize: 12, color: textLightColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //   decoration: BoxDecoration(
            //     color: (device.status == 'online' ? Colors.green : Colors.grey)
            //         .withValues(alpha: 0.1),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Container(
            //         width: 6,
            //         height: 6,
            //         decoration: BoxDecoration(
            //           color: device.status == 'online'
            //               ? Colors.green
            //               : Colors.grey,
            //           shape: BoxShape.circle,
            //         ),
            //       ),
            //       const SizedBox(width: 4),
            //       Text(
            //         device.status?.capitalizeFirst ?? 'Offline',
            //         style: TextStyle(
            //           fontSize: 11,
            //           color: device.status == 'online'
            //               ? Colors.green
            //               : Colors.grey,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
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
    CustomConfirmDialog.show(
      context: Get.context!,
      title: 'delete_device'.tr,
      content: '${'confirm_delete_device'.tr} ${device.deviceName}?',
      confirmText: 'delete'.tr,
      onConfirm: () async {
        Get.back();
        final success = await controller.removeDevice(device.id ?? '');
        if (success) {
          Get.snackbar('success'.tr, 'device_deleted_successfully'.tr);
        }
      },
    );
  }
}
