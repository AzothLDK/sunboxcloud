import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../model/device_model.dart';
import 'sunbox_detail_page.dart';
import 'suncharger_detail_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final StationController controller = Get.find<StationController>();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final PageController _pageController = PageController();
  Worker? _stationWorker;

  @override
  void initState() {
    super.initState();
    _startBannerAutoPlay();
    // 仅在进入此页面时调用 App 设备列表接口
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedStationId.value.isNotEmpty) {
        controller.fetchAppDevices(controller.selectedStationId.value);
      }
    });

    // 监听站点变化，仅在此页面激活时更新数据
    _stationWorker = ever(controller.selectedStationId, (String stationId) {
      if (stationId.isNotEmpty) {
        controller.fetchAppDevices(stationId);
      }
    });
  }

  @override
  void dispose() {
    _stationWorker?.dispose();
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % 3;
        _pageController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _launchURL() async {
    // final Uri url = Uri.parse('http://www.smartwuxi.com/#/en-US');
    // try {
    //   if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    //     ToastUtils.error('Could not launch $url');
    //   }
    // } catch (e) {
    //   ToastUtils.error('Error: $e');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bgimage.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildBanner(),
            Expanded(
              child: Obx(() {
                if (controller.isDevicesLoading.value &&
                    controller.appDevices.isEmpty) {
                  return _buildLoading();
                }
                return RefreshIndicator(
                  onRefresh: () => controller.fetchAppDevices(
                    controller.selectedStationId.value,
                  ),
                  child: _buildDeviceList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemCount: 3,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: _launchURL,
                child: Container(
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/banner001.png',
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.fill,
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == index
                        ? primaryColor
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildDeviceList() {
    final List<DeviceModel> displayDevices = List.from(controller.appDevices);

    // 必定模拟一个 SunCharger 设备
    final simulatedCharger = DeviceModel(
      id: 'simulated_charger',
      deviceName: 'SunCharger',
      deviceType: 'SunCharger',
      status: 'online',
      soc: 89.0,
      chargedEnergy: 12.5,
      power: 7.2,
    );

    // 检查是否已经存在 SunCharger，如果不存在则添加
    bool hasCharger = displayDevices.any((d) => d.deviceType == 'SunCharger');
    if (!hasCharger) {
      displayDevices.insert(0, simulatedCharger);
    }

    if (displayDevices.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'no_device_found'.tr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: displayDevices.length,
      itemBuilder: (context, index) => _buildDeviceCard(displayDevices[index]),
    );
  }

  Widget _buildBatteryIndicator(double soc) {
    return SizedBox(
      width: 70,
      // height: 70,
      child: Column(
        children: [
          Text(
            '${(soc * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF24C18F),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 45,
            height: 70,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  height: 66 * soc.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24C18F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIndicator(double soc) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: soc.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF24C18F),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '${(soc * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF24C18F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricValue(String value, String unit) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$value ',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text: unit,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DeviceModel device) {
    final deviceName = device.deviceName ?? 'SunBox';
    final isOnline = device.status == 'online';
    final statusText = isOnline ? 'online'.tr : 'offline'.tr;
    final statusColor = isOnline ? const Color(0xFF4CAF50) : Colors.red;
    final statusBgColor = isOnline ? const Color(0xFFE8F5E9) : Colors.red[50];
    final soc = (device.soc ?? 50) / 100;
    final charged = device.chargedEnergy ?? 200;
    final discharged = device.dischargedEnergy ?? 200;
    final isSunCharger = device.deviceType == 'SunCharger';
    final power = device.power ?? 0.0;

    return GestureDetector(
      onTap: () {
        if (isSunCharger) {
          Get.to(
            () => SunChargerDetailPage(
              deviceName: deviceName,
              deviceId: device.id,
            ),
          );
        } else {
          Get.to(
            () => SunBoxDetailPage(deviceName: deviceName, deviceId: device.id),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        deviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isSunCharger)
                        // _buildBatteryIndicator(soc)
                        const SizedBox.shrink()
                      else
                        _buildCircularIndicator(soc),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetricValue(charged.toString(), 'kWh'),
                          Text(
                            'charged'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isSunCharger) ...[
                            _buildMetricValue(
                              isOnline ? power.toString() : '',
                              isOnline ? 'kW' : '',
                            ),
                            Text(
                              'power'.tr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ] else ...[
                            _buildMetricValue(discharged.toString(), 'kWh'),
                            Text(
                              'discharged'.tr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSunCharger) ...[
              Image.asset('assets/snchargerlite.png'),
            ] else ...[
              Image.asset('assets/sndevicelite.png'),
            ],
          ],
        ),
      ),
    );
  }
}
