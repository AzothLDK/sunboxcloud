import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../model/station_model.dart';

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
                  station.detailAddress ?? '',
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
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(hintText: 'enter_new_value'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (textController.text.trim().isNotEmpty) {
                onSave(textController.text.trim());
              }
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStation(Map<String, dynamic> updates) async {
    final Map<String, dynamic> data = {'id': widget.station.id, ...updates};
    await controller.saveOrEditStation(data);
    setState(() {}); // 更新本地显示的 UI
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
                color: secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
      body: Container(
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
                      widget.station.stationName ?? '',
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
                      widget.station.stationName ?? '',
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
                      widget.station.detailAddress ?? '',
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
                      'address'.tr,
                      widget.station.detailAddress ?? '',
                      (value) async {
                        await _updateStation({'detailAddress': value});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
