import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunboxcloud/pages/home/animated_flow_chart.dart';
import 'energy_flow_overlay.dart';
import 'customize_indicators_dialog.dart';
import '../../utils/constants.dart';
import '../../utils/network/api_service.dart';
import '../../controllers/station_controller.dart';
import '../../model/station_model.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final StationController controller = Get.find<StationController>();

  // 电池SOC百分比
  double batterySoc = 100;

  // 未读消息个数
  int _unreadCount = 0;

  // 选中的指标
  List<String> selectedIndicators = [
    'solar_generation',
    'site_load',
    'battery_charging',
    'battery_discharging',
  ];

  // 根据SOC百分比返回电池图标
  IconData getBatteryIcon(double soc) {
    if (soc == 100) {
      return Icons.battery_full;
    } else if (soc >= 80) {
      return Icons.battery_6_bar;
    } else if (soc >= 60) {
      return Icons.battery_5_bar;
    } else if (soc >= 40) {
      return Icons.battery_4_bar;
    } else if (soc >= 20) {
      return Icons.battery_2_bar;
    } else if (soc > 0) {
      return Icons.battery_1_bar;
    } else {
      return Icons.battery_0_bar;
    }
  }

  // 显示自定义指标对话框
  void showCustomizeDialog() {
    Get.dialog(
      CustomizeIndicatorsDialog(
        selectedIndicators: selectedIndicators,
        onConfirm: (newSelected) {
          // 直接更新选择，错误验证已经在对话框中处理
          setState(() {
            selectedIndicators = newSelected;
          });
        },
      ),
    );
  }

  // 根据指标ID获取指标信息
  Map<String, dynamic> getIndicatorInfo(String indicatorId) {
    final data = controller.homeData.value;
    switch (indicatorId) {
      case 'solar_generation':
        return {
          'name': 'solar_generation'.tr,
          'value': '${data?.pvPower ?? '--'}',
          'unit': 'kWh',
          'icon': 'assets/solar.png',
        };
      case 'site_load':
        return {
          'name': 'site_load'.tr,
          'value': '${data?.loadPower ?? '--'}',
          'unit': 'kWh',
          'icon': 'assets/site.png',
        };
      case 'battery_charging':
        return {
          'name': 'battery_charging'.tr,
          'value': '${data?.chargePower ?? '--'}',
          'unit': 'kWh',
          'icon': 'assets/charging.png',
        };
      case 'battery_discharging':
        return {
          'name': 'battery_discharging'.tr,
          'value': '${data?.dischargePower ?? '--'}',
          'unit': 'kWh',
          'icon': 'assets/discharging.png',
        };
      case 'buy_from_grid':
        return {
          'name': 'buy_from_grid'.tr,
          'value': '${data?.gridPower ?? '--'}',
          'unit': 'kWh',
          'icon': 'assets/bfg.png',
        };
      case 'sell_to_grid':
        return {
          'name': 'sell_to_grid'.tr,
          'value': '${data?.gridSellPower ?? '--'}',
          'unit': 'kWh',
          'icon': 'assets/stg.png',
        };
      default:
        return {'name': '', 'value': '', 'unit': '', 'icon': ''};
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // 数据已由 StationController 管理，此处无需手动加载
  }

  // 加载未读告警个数
  Future<void> _loadUnreadCount() async {
    try {
      final result = await ApiService.getCountNumber();
      if (result['code'] == 200 || result['code'] == 0) {
        final data = result['data'];
        if (data is Map) {
          setState(() {
            _unreadCount = data['total'] ?? 0 as int;
          });
        }
      }
    } catch (e) {
      // 静默处理
    }
  }

  // 构建带角标的消息图标
  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () async {
        await Get.toNamed('/notifications');
        _loadUnreadCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications,
            color: textColor,
            size: 24,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showInfoTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'self_sufficiency_rate_info'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'self_sufficiency_rate_desc'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: textLightColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'got_it'.tr,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        child: Obx(() {
          // 1. 如果正在加载站点列表且列表为空，或者正在加载当前站点的设备/首页数据
          if ((controller.isStationsLoading.value &&
                  controller.stations.isEmpty) ||
              controller.isDevicesLoading.value ||
              controller.isHomeDataLoading.value) {
            return Container(
              color: Colors.transparent,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          // 2. 如果没有站点，或者当前站点加载完成但没有设备，显示空状态
          if (controller.stations.isEmpty || controller.devices.isEmpty) {
            return _buildEmptyState();
          }

          // 3. 正常显示内容
          return RefreshIndicator(
            onRefresh: () => controller.fetchStations(),
            child: _buildNormalContent(),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => controller.fetchStations(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                // 顶部按钮栏
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 如果有站点但没设备，显示站点切换按钮
                      if (controller.stations.isNotEmpty)
                        _buildStationSelector()
                      else
                        const SizedBox.shrink(),
                      _buildNotificationIcon(),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                AspectRatio(
                  aspectRatio: 400 / 350,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/centerhouse.png', fit: BoxFit.fill),
                      const AnimatedFlowChart(),
                      const EnergyFlowOverlay(),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final result = await Get.toNamed(
                              '/scan',
                              arguments: {
                                'stationId': controller.selectedStation?.id,
                                'stationName':
                                    controller.selectedStation?.stationName,
                              },
                            );
                            if (result == true) {
                              controller.fetchStations();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'add_device'.tr,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'no_device_linked'.tr,
                          style: TextStyle(color: textLightColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationSelector() {
    return PopupMenuButton<StationModel>(
      onSelected: (station) {
        controller.selectStation(station.id ?? '');
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => controller.stations
          .map(
            (station) => PopupMenuItem<StationModel>(
              value: station,
              child: Text(station.stationName ?? ''),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.selectedStation?.stationName ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: textColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalContent() {
    final data = controller.homeData.value;
    final ssRateValue = (data?.ssRate ?? 0) / 100;
    final bsocValue = data?.bsoc ?? 0;

    return ListView(
      children: [
        // 顶部按钮栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 选择站点按钮
              _buildStationSelector(),
              // 消息按钮
              _buildNotificationIcon(),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Obx(() {
          final data = controller.homeData.value;
          return AspectRatio(
            aspectRatio: 400 / 350,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/centerhouse.png', fit: BoxFit.fill),
                AnimatedFlowChart(
                  solarValue: data?.solar ?? 0,
                  gridValue: data?.grid ?? 0,
                  siteValue: data?.site ?? 0,
                  evValue: data?.ev ?? 0, // 目前 homeData 中似乎没有 ev 字段，先传 0
                ),
                const EnergyFlowOverlay(),
              ],
            ),
          );
        }),
        Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              //today
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 20,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'today'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: showCustomizeDialog,
                    child: const Icon(
                      Icons.filter_list,
                      color: textLightColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              // 顶部两个主要指标
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 能量自给率
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 25,
                                height: 25,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: ssRateValue,
                                      strokeWidth: 6,
                                      backgroundColor: primaryColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      color: primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(ssRateValue * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              // const SizedBox(width: 8),
                              // Text(
                              //   '%',
                              //   style: TextStyle(
                              //     fontSize: 18,
                              //     fontWeight: FontWeight.bold,
                              //     color: textColor,
                              //   ),
                              // ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  _showInfoTooltip(context);
                                },
                                child: const Icon(
                                  Icons.info_outline,
                                  color: textLightColor,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'energy_self_sufficiency_rate'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    // 电池SOC
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 35,
                                height: 35,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E8),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    getBatteryIcon(bsocValue),
                                    color: primaryColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${bsocValue.toInt()}%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'battery_soc'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 能量数据展示
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 四个数据卡片
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: selectedIndicators.map((indicatorId) {
                      final info = getIndicatorInfo(indicatorId);
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Image.asset(info['icon']),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: info['value'],
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const TextSpan(text: ' '),
                                        TextSpan(
                                          text: info['unit'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.normal,
                                            color: textLightColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    info['name'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textLightColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
