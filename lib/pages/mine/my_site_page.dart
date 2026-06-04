import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../model/station_model.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/custom_input_dialog.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../routes/app_routes.dart';
import 'address_edit_page.dart';

class SitePage extends StatelessWidget {
  const SitePage({super.key});
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
        title: Text(
          'site'.tr,
          style: const TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: textColor),
            onPressed: () => Get.toNamed(AppRoutes.addSite),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isStationsLoading.value && controller.stations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.stations.isEmpty) {
          return Center(
            child: Text(
              'no_site_data'.tr,
              style: const TextStyle(color: textLightColor, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.stations.length,
          itemBuilder: (context, index) {
            final station = controller.stations[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home, color: primaryColor),
                ),
                title: Text(
                  station.stationName ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  () {
                    final regionNames =
                        station.regionNodes
                            ?.map((e) => e.name ?? '')
                            .where((name) => name.isNotEmpty)
                            .join(', ') ??
                        '';
                    final detail = station.detailAddress ?? '';
                    if (regionNames.isEmpty) return detail;
                    if (detail.isEmpty) return regionNames;
                    return '$regionNames $detail';
                  }(),
                  style: const TextStyle(fontSize: 14, color: textLightColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: textLightColor,
                ),
                onTap: () {
                  Get.to(() => SiteInfoPage(station: station));
                },
              ),
            );
          },
        );
      }),
    );
  }
}

class SiteInfoPage extends StatefulWidget {
  final StationModel station;

  const SiteInfoPage({super.key, required this.station});

  @override
  State<SiteInfoPage> createState() => _SiteInfoPageState();
}

class _SiteInfoPageState extends State<SiteInfoPage> {
  final StationController controller = Get.find<StationController>();

  Future<void> _showEditDialog(
    BuildContext context,
    String title,
    String initialValue,
    Function(String value) onSave,
  ) async {
    final TextEditingController textController = TextEditingController(
      text: initialValue,
    );

    await CustomInputDialog.show(
      context: context,
      title: title,
      fields: [
        InputFieldConfig(
          label: title,
          hintText: 'enter_address'.tr,
          controller: textController,
        ),
      ],
      onSave: () {
        Navigator.pop(context);
        if (textController.text.trim().isNotEmpty) {
          onSave(textController.text.trim());
        }
      },
    );
  }

  Future<void> _updateStation(Map<String, dynamic> updates) async {
    final Map<String, dynamic> data = {'id': widget.station.id, ...updates};
    await controller.saveOrEditStation(data);
  }

  Future<void> _deleteStation() async {
    CustomConfirmDialog.show(
      context: context,
      title: 'delete_station'.tr,
      content: 'confirm_delete_station'.tr,
      confirmText: 'delete'.tr,
      onConfirm: () async {
        Navigator.pop(context); // 关闭第一个对话框

        // 检查是否有绑定设备
        final hasDevices = await controller.hasDevices(widget.station.id ?? '');

        if (hasDevices) {
          // 如果有设备，进行二次确认
          if (mounted) {
            CustomConfirmDialog.show(
              context: context,
              title: 'warning'.tr,
              content: 'station_has_devices_warning'.tr,
              confirmText: 'continue_delete'.tr,
              onConfirm: () async {
                Navigator.pop(context); // 关闭第二个对话框
                await _executeDelete();
              },
            );
          }
        } else {
          // 没有设备，直接删除
          await _executeDelete();
        }
      },
    );
  }

  Future<void> _executeDelete() async {
    final success = await controller.removeStation(widget.station.id ?? '');
    if (success) {
      Get.back(); // 返回上一页
      ToastUtils.success('delete_successfully'.tr);
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
          onPressed: () => Get.back(),
        ),
        title: Text(
          'site_info'.tr,
          style: const TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
      body: Obx(() {
        // 从控制器中查找最新的站点信息，确保数据同步更新
        final currentStation = controller.stations.firstWhereOrNull(
          (s) => s.id == widget.station.id,
        );

        if (currentStation == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          color: backgroundColor,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'site_name'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                        ),
                      ),
                      subtitle: Text(
                        currentStation.stationName ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: textLightColor,
                      ),
                      onTap: () => _showEditDialog(
                        context,
                        'site_name'.tr,
                        currentStation.stationName ?? '',
                        (value) async {
                          await _updateStation({'stationName': value});
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: Text(
                        'address'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                        ),
                      ),
                      subtitle: Text(
                        () {
                          final regionNames =
                              currentStation.regionNodes
                                  ?.map((e) => e.name ?? '')
                                  .where((name) => name.isNotEmpty)
                                  .join(', ') ??
                              '';
                          final detail = currentStation.detailAddress ?? '';
                          if (regionNames.isEmpty) return detail;
                          if (detail.isEmpty) return regionNames;
                          return '$regionNames $detail';
                        }(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: textLightColor,
                      ),
                      onTap: () => Get.to(
                        () => AddressEditPage(
                          initialAddress:
                              currentStation.regionNodes
                                  ?.map((e) => e.name ?? '')
                                  .join(', ') ??
                              '',
                          initialDetailAddress:
                              currentStation.detailAddress ?? '',
                          onSave: (regionId, detail, fullRegionName) async {
                            await _updateStation({
                              'regionId': regionId,
                              'detailAddress': detail,
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _deleteStation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D4F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'delete_station'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}
