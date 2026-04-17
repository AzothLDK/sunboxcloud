import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunboxcloud/pages/home/animated_flow_chart.dart';
import 'energy_flow_overlay.dart';
import 'customize_indicators_dialog.dart';
import '../../utils/constants.dart';
import '../../utils/network/api_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 站点列表
  List<Map<String, dynamic>> _stationList = [];
  // 当前选中的站点
  Map<String, dynamic>? _selectedStation;
  // 是否正在加载
  bool _isLoadingStations = true;

  // 电池SOC百分比
  double batterySoc = 100;

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
    switch (indicatorId) {
      case 'solar_generation':
        return {
          'name': 'solar_generation'.tr,
          'value': '200 kWh',
          'icon': 'assets/solar.png',
        };
      case 'site_load':
        return {
          'name': 'site_load'.tr,
          'value': '300 kWh',
          'icon': 'assets/site.png',
        };
      case 'battery_charging':
        return {
          'name': 'battery_charging'.tr,
          'value': '200 kWh',
          'icon': 'assets/charging.png',
        };
      case 'battery_discharging':
        return {
          'name': 'battery_discharging'.tr,
          'value': '300 kWh',
          'icon': 'assets/discharging.png',
        };
      case 'buy_from_grid':
        return {
          'name': 'buy_from_grid'.tr,
          'value': '100 kWh',
          'icon': 'assets/bfg.png',
        };
      case 'sell_to_grid':
        return {
          'name': 'sell_to_grid'.tr,
          'value': '50 kWh',
          'icon': 'assets/stg.png',
        };
      default:
        return {'name': '', 'value': '', 'icon': ''};
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStationList();
  }

  Future<void> _loadStationList() async {
    try {
      final result = await ApiService.getStationList();
      if (result['code'] == 200 && result['data'] != null) {
        List<dynamic> data = result['data'];
        setState(() {
          _stationList = data
              .map((e) => {'id': e['id'], 'stationName': e['stationName']})
              .toList();
          if (_stationList.isNotEmpty) {
            _selectedStation = _stationList[0];
          }
          _isLoadingStations = false;
        });
      } else {
        setState(() {
          _isLoadingStations = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStations = false;
      });
    }
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
        child: _isLoadingStations
            ? const Center(child: CircularProgressIndicator())
            : _stationList.isEmpty
            ? _buildEmptyState()
            : _buildNormalContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        // 顶部按钮栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Get.toNamed('/notifications');
                },
                child: const Icon(
                  Icons.notifications,
                  color: textColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Stack(
          children: [
            Image.asset('assets/centerhouse.png'),
            const AnimatedFlowChart(),
            const EnergyFlowOverlay(),
          ],
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.toNamed('/distribution-network');
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
    );
  }

  Widget _buildNormalContent() {
    return ListView(
      children: [
        // 顶部按钮栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 选择站点按钮
              PopupMenuButton<Map<String, dynamic>>(
                onSelected: (station) {
                  setState(() {
                    _selectedStation = station;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                color: Colors.white,
                itemBuilder: (context) {
                  return _stationList.map((station) {
                    final isSelected = _selectedStation?['id'] == station['id'];
                    return PopupMenuItem<Map<String, dynamic>>(
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
                              station['stationName'],
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
                                decoration: BoxDecoration(
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
                  }).toList();
                },
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
                        _selectedStation?['stationName'] ?? '',
                        style: TextStyle(
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
              ),
              // 消息按钮
              GestureDetector(
                onTap: () {
                  Get.toNamed('/notifications');
                },
                child: const Icon(
                  Icons.notifications,
                  color: textColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Stack(
          children: [
            Image.asset('assets/centerhouse.png'),
            const AnimatedFlowChart(),
            const EnergyFlowOverlay(),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(20),
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
                padding: EdgeInsets.all(15),
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
                              Container(
                                width: 35,
                                height: 35,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.circle_outlined,
                                    color: primaryColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '66%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.info_outline,
                                color: textLightColor,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'energy_self_sufficiency_rate'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
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
                                    getBatteryIcon(batterySoc),
                                    color: primaryColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${batterySoc}%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.info_outline,
                                color: textLightColor,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'battery_soc'.tr,
                            style: TextStyle(
                              fontSize: 12,
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
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2,
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info['value'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    info['name'],
                                    style: TextStyle(
                                      fontSize: 12,
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
