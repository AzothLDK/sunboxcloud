import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_echarts/flutter_echarts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/station_controller.dart';
import '../../utils/constants.dart';
import '../../utils/storage.dart';
import '../../widgets/custom_date_picker.dart';

class SiteDetailTab extends StatefulWidget {
  const SiteDetailTab({super.key});

  @override
  State<SiteDetailTab> createState() => _SiteDetailTabState();
}

class _SiteDetailTabState extends State<SiteDetailTab> {
  String _selectedMainTab = 'Daily Analysis';
  String _monthlySubTab = 'Overview';
  String _dailySubTab = 'Energy';
  int? _activeLegendIndex;

  DateTime _selectedDate = DateTime.now();

  String get _monthlyDate =>
      DateFormat('MMM yyyy', Get.locale?.toString()).format(_selectedDate);
  String get _dailyDate =>
      DateFormat('MMM d, yyyy', Get.locale?.toString()).format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _fetchData();

    // 监听站点切换
    final stationController = Get.find<StationController>();
    ever(stationController.selectedStationId, (_) {
      if (mounted) {
        setState(() {});
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    if (_selectedMainTab == 'Monthly Overview') {
      await _fetchEnergyData();
      await _fetchEnergyChartData();
    } else {
      await _fetchDailyData();
    }
  }

  Future<void> _fetchDailyData() async {
    final stationController = Get.find<StationController>();
    final selectedStationId = stationController.selectedStationId.value;
    if (selectedStationId.isEmpty) return;

    final updateTime = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (_dailySubTab == 'Energy') {
      await stationController.fetchEnergyDayData(
        stationId: selectedStationId,
        updateTime: updateTime,
      );
    } else {
      await stationController.fetchPowerDayData(
        stationId: selectedStationId,
        updateTime: updateTime,
      );
    }
  }

  Future<void> _fetchEnergyChartData() async {
    final stationController = Get.find<StationController>();
    final selectedStationId = stationController.selectedStationId.value;
    if (selectedStationId.isEmpty) return;

    final updateTime = _selectedMainTab == 'Monthly Overview'
        ? DateFormat('yyyy-MM').format(_selectedDate)
        : DateFormat('yyyy-MM-dd').format(_selectedDate);

    await stationController.fetchEnergyChartData(
      stationId: selectedStationId,
      updateTime: updateTime,
      type: 1,
    );
  }

  Future<void> _fetchEnergyData() async {
    final stationController = Get.find<StationController>();
    final selectedStationId = stationController.selectedStationId.value;
    if (selectedStationId.isEmpty) return;

    final updateTime = _selectedMainTab == 'Monthly Overview'
        ? DateFormat('yyyy-MM').format(_selectedDate)
        : DateFormat('yyyy-MM-dd').format(_selectedDate);

    await stationController.fetchEnergySourcesData(
      stationId: selectedStationId,
      updateTime: updateTime,
    );
  }

  Future<void> _selectDate() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomDatePicker(
        initialDate: _selectedDate,
        maxDate: DateTime.now(),
        mode: _selectedMainTab == 'Monthly Overview'
            ? CustomDatePickerMode.month
            : CustomDatePickerMode.day,
        onConfirm: (date) {
          setState(() {
            _selectedDate = date;
          });
          _fetchData();
        },
      ),
    );
  }

  void _previousDate() {
    setState(() {
      if (_selectedMainTab == 'Monthly Overview') {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month - 1,
          1,
        );
      } else {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      }
    });
    _fetchData();
  }

  bool get _hasNextDate {
    final now = DateTime.now();
    if (_selectedMainTab == 'Monthly Overview') {
      final nextMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        1,
      );
      return nextMonth.isBefore(DateTime(now.year, now.month + 1, 1));
    } else {
      final nextDay = _selectedDate.add(const Duration(days: 1));
      return nextDay.isBefore(DateTime(now.year, now.month, now.day + 1));
    }
  }

  void _nextDate() {
    if (!_hasNextDate) return;
    setState(() {
      if (_selectedMainTab == 'Monthly Overview') {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          1,
        );
      } else {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      }
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final stationController = Get.find<StationController>();

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bgimage.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            title: Obx(() {
              final stationName =
                  stationController.selectedStation?.stationName ??
                  'site_detail'.tr;
              return Text(
                stationName,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
            centerTitle: true,
          ),
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildMainTabs(),
                const SizedBox(height: 16),
                _buildDateSelector(),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedMainTab == 'Monthly Overview'
                      ? _buildMonthlyOverview()
                      : _buildDailyAnalysis(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMainTab = 'Daily Analysis';
                });
                _fetchData();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedMainTab == 'Daily Analysis'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _selectedMainTab == 'Daily Analysis'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'daily_analysis'.tr,
                  style: TextStyle(
                    color: _selectedMainTab == 'Daily Analysis'
                        ? primaryColor
                        : textLightColor,
                    fontWeight: _selectedMainTab == 'Daily Analysis'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMainTab = 'Monthly Overview';
                });
                _fetchData();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedMainTab == 'Monthly Overview'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _selectedMainTab == 'Monthly Overview'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'monthly_overview'.tr,
                  style: TextStyle(
                    color: _selectedMainTab == 'Monthly Overview'
                        ? primaryColor
                        : textLightColor,
                    fontWeight: _selectedMainTab == 'Monthly Overview'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    String dateText = _selectedMainTab == 'Monthly Overview'
        ? _monthlyDate
        : _dailyDate;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _previousDate,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_left,
              color: textLightColor,
              size: 20,
            ),
          ),
        ),
        GestureDetector(
          onTap: _selectDate,
          child: Text(
            dateText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
        GestureDetector(
          onTap: _hasNextDate ? _nextDate : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right,
              color: _hasNextDate ? textLightColor : Colors.grey[300],
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyOverview() {
    final stationController = Get.find<StationController>();

    return Obx(() {
      final chartData = stationController.energyChartData.value;
      final isLoading = stationController.isEnergyChartLoading.value;

      final supply = chartData?['supply'] ?? 0;
      final consume = chartData?['consume'] ?? 0;

      final energyData = stationController.energySourcesData.value;
      final saveEnergy = energyData?['saveEnergy'] ?? 0;
      final gridDependency = energyData?['gridDependency'] ?? 0;
      final gridConsumption = energyData?['gridConsumption'] ?? 0;
      final batteryConsumption = energyData?['batteryConsumption'] ?? 0;
      final solarConsumption = energyData?['solarConsumption'] ?? 0;

      final totalConsumption = gridConsumption + solarConsumption;
      final gridRatio = totalConsumption > 0
          ? gridConsumption / totalConsumption
          : 0.0;
      final solarRatio = totalConsumption > 0
          ? solarConsumption / totalConsumption
          : 0.0;

      final gridPercent = (gridRatio * 100).toStringAsFixed(1);
      final solarPercent = (solarRatio * 100).toStringAsFixed(1);

      return ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sunny, color: solarColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'solar_generation'.tr,
                            style: TextStyle(
                              color: textLightColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: saveEnergy.toStringAsFixed(2),
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' kWh',
                              style: TextStyle(
                                color: textLightColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'grid_dependency'.tr,
                            style: TextStyle(
                              color: textLightColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: gridDependency.toStringAsFixed(1),
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' %',
                              style: TextStyle(
                                color: textLightColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'energy_source'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 电网段 (Grid)
                          _buildAnimatedChartSegment(
                            ratio: gridRatio,
                            startAngle: 0,
                            color: Colors.blue,
                            isActive: _activeLegendIndex == 0,
                            isDimmed:
                                _activeLegendIndex != null &&
                                _activeLegendIndex != 0,
                          ),
                          // 光伏段 (Solar)
                          _buildAnimatedChartSegment(
                            ratio: solarRatio,
                            startAngle: 2 * math.pi * gridRatio,
                            color: primaryColor,
                            isActive: _activeLegendIndex == 1,
                            isDimmed:
                                _activeLegendIndex != null &&
                                _activeLegendIndex != 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendItem(
                            primaryColor,
                            '$solarPercent%',
                            '${solarConsumption.toStringAsFixed(2)}kWh',
                            'from_solar'.tr,
                            isActive: _activeLegendIndex == 1,
                            onTap: () {
                              setState(() {
                                _activeLegendIndex = _activeLegendIndex == 1
                                    ? null
                                    : 1;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            Colors.blue,
                            '$gridPercent%',
                            '${gridConsumption.toStringAsFixed(2)}kWh',
                            'from_grid'.tr,
                            isActive: _activeLegendIndex == 0,
                            onTap: () {
                              setState(() {
                                _activeLegendIndex = _activeLegendIndex == 0
                                    ? null
                                    : 0;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overview / Solar Tabs & Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sub tabs
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _monthlySubTab = 'Overview';
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _monthlySubTab == 'Overview'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: _monthlySubTab == 'Overview'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'overview'.tr,
                              style: TextStyle(
                                color: _monthlySubTab == 'Overview'
                                    ? primaryColor
                                    : textLightColor,
                                fontWeight: _monthlySubTab == 'Overview'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _monthlySubTab = 'Solar';
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _monthlySubTab == 'Solar'
                                  ? primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'solar'.tr,
                              style: TextStyle(
                                color: _monthlySubTab == 'Solar'
                                    ? Colors.white
                                    : textLightColor,
                                fontWeight: _monthlySubTab == 'Solar'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_monthlySubTab == 'Overview') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.outbox,
                                    color: Colors.purple[200],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'supply'.tr,
                                    style: TextStyle(
                                      color: textLightColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: supply.toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' kWh',
                                      style: TextStyle(
                                        color: textLightColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    color: primaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'consumption'.tr,
                                    style: TextStyle(
                                      color: textLightColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: consume.toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' kWh',
                                      style: TextStyle(
                                        color: textLightColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOverviewChart(chartData, isLoading),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'solar_production'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '(kWh)',
                        style: TextStyle(fontSize: 12, color: textLightColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSolarChart(chartData, isLoading),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildLegendItem(
    Color color,
    String percent,
    String value,
    String label, {
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: color.withValues(alpha: 0.3))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        percent,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: textLightColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建带动画的圆环段落
  Widget _buildAnimatedChartSegment({
    required double ratio,
    required double startAngle,
    required Color color,
    required bool isActive,
    required bool isDimmed,
  }) {
    if (ratio <= 0) return const SizedBox.shrink();

    return Transform.rotate(
      angle: startAngle - (math.pi / 2), // 减去 90 度，因为 Flutter 默认从 12 点方向开始
      child: AnimatedScale(
        scale: isActive ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: ratio,
            strokeWidth: isActive ? 20 : 15, // 激活时变粗
            color: isDimmed ? color.withValues(alpha: 0.3) : color,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewChart(Map<String, dynamic>? chartData, bool isLoading) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final xdata = chartData?['xdata'] as List<dynamic>? ?? [];
    final ydataGf = chartData?['ydataGf'] as List<dynamic>? ?? [];
    final ydataDw = chartData?['ydataDw'] as List<dynamic>? ?? [];
    final ydataCnC = chartData?['ydataCnC'] as List<dynamic>? ?? [];
    final ydataCnF = chartData?['ydataCnF'] as List<dynamic>? ?? [];
    final ydataFh = chartData?['ydataFh'] as List<dynamic>? ?? [];

    // // 将负载和储能充转为负数，以显示在 Y 轴下方
    // final negativeYdataFh = ydataFh.map((e) => -(e ?? 0)).toList();
    // final negativeYdataCnC = ydataCnC.map((e) => -(e ?? 0)).toList();

    return SizedBox(
      height: 200,
      child: Echarts(
        option: jsonEncode({
          "grid": {"left": '12%', "right": '5%', "top": '20%', "bottom": '15%'},
          "legend": {
            "width": 240,
            "data": [
              'solar'.tr,
              'grid'.tr,
              'battery_charging'.tr,
              'battery_discharging'.tr,
              'load'.tr,
            ],
            "icon": 'circle',
            "itemWidth": 8,
            "itemHeight": 8,
            "textStyle": {"fontSize": 10, "color": '#999'},
            "top": 0,
            "left": 'center',
          },
          "tooltip": {"trigger": "axis", 'confine': true},
          "xAxis": {
            "type": 'category',
            "data": xdata,
            "axisLine": {"show": false},
            "axisTick": {"show": false},
            "axisLabel": {"color": '#999', "fontSize": 10},
          },
          "yAxis": {
            "type": 'value',
            "nameTextStyle": {"color": '#999', "fontSize": 10},
            "splitLine": {
              "lineStyle": {"type": 'dashed', "color": '#eee'},
            },
            "axisLabel": {"color": '#999', "fontSize": 10},
          },
          "series": [
            {
              "name": 'solar'.tr,
              "type": 'bar',
              "stack": 'total',
              "data": ydataGf,
              "itemStyle": {"color": '#FFC107'},
              "barWidth": 6,
            },
            {
              "name": 'grid'.tr,
              "type": 'bar',
              "stack": 'total',
              "data": ydataDw,
              "itemStyle": {"color": '#3B82F6'},
              "barWidth": 6,
            },
            {
              "name": 'battery_charging'.tr,
              "type": 'bar',
              "stack": 'total',
              "data": ydataCnC,
              "itemStyle": {"color": '#10B981'},
              "barWidth": 6,
            },
            {
              "name": 'battery_discharging'.tr,
              "type": 'bar',
              "stack": 'total',
              "data": ydataCnF,
              "itemStyle": {"color": '#FF4D4F'},
              "barWidth": 6,
            },

            {
              "name": 'load'.tr,
              "type": 'bar',
              "stack": 'total',
              "data": ydataFh,
              "itemStyle": {"color": '#A855F7'},
              "barWidth": 6,
            },
          ],
        }),
      ),
    );
  }

  Widget _buildSolarChart(Map<String, dynamic>? chartData, bool isLoading) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final xdata = chartData?['xdata'] as List<dynamic>? ?? [];
    final ydataGf = chartData?['ydataGf'] as List<dynamic>? ?? [];

    return SizedBox(
      height: 200,
      child: Echarts(
        option: jsonEncode({
          "grid": {"left": '12%', "right": '5%', "top": '10%', "bottom": '15%'},
          "xAxis": {
            "type": 'category',
            "data": xdata,
            "axisLine": {"show": false},
            "axisTick": {"show": false},
            "axisLabel": {"color": '#999', "fontSize": 10},
          },
          "tooltip": {"trigger": "axis", 'confine': true},
          "yAxis": {
            "type": 'value',
            "splitLine": {
              "lineStyle": {"type": 'dashed', "color": '#eee'},
            },
            "axisLabel": {"color": '#999', "fontSize": 10},
          },
          "series": [
            {
              "type": 'bar',
              "data": ydataGf,
              "itemStyle": {
                "color": '#FFC107',
                "borderRadius": [2, 2, 0, 0],
              },
              "barWidth": 6,
            },
          ],
        }),
      ),
    );
  }

  Widget _buildDailyAnalysis() {
    final stationController = Get.find<StationController>();

    return Obx(() {
      final energyDayData = stationController.energyDayData.value;
      final powerDayData = stationController.powerDayData.value;
      final isEnergyLoading = stationController.isEnergyDayLoading.value;
      final isPowerLoading = stationController.isPowerDayLoading.value;

      double gridValue = 0;
      double batteryValue = 0;
      double solarValue = 0;
      double totalConsumption = 0;
      double costSavings = 0;

      String gridPercent = '0.0';
      String batteryPercent = '0.0';
      String solarPercent = '0.0';

      if (_dailySubTab == 'Energy' && energyDayData != null) {
        gridValue = (energyDayData['grid'] ?? 0).toDouble();
        solarValue = (energyDayData['pv'] ?? 0).toDouble();
        totalConsumption = (energyDayData['total'] ?? 0).toDouble();
        costSavings = (energyDayData['cost'] ?? 0).toDouble();
        // 假设负载量
        batteryValue =
            (energyDayData['load'] ?? 0).toDouble() - gridValue - solarValue;
        if (batteryValue < 0) batteryValue = 0;

        if (totalConsumption > 0) {
          gridPercent = (gridValue / totalConsumption * 100).toStringAsFixed(1);
          solarPercent = (solarValue / totalConsumption * 100).toStringAsFixed(
            1,
          );
          batteryPercent =
              (100 -
                      (gridValue / totalConsumption * 100) -
                      (solarValue / totalConsumption * 100))
                  .toStringAsFixed(1);
        }
      }

      return ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _dailySubTab = 'Energy';
                            });
                            _fetchData();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _dailySubTab == 'Energy'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: _dailySubTab == 'Energy'
                                  ? Border.all(color: primaryColor)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'energy'.tr,
                              style: TextStyle(
                                color: _dailySubTab == 'Energy'
                                    ? primaryColor
                                    : textLightColor,
                                fontWeight: _dailySubTab == 'Energy'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _dailySubTab = 'Power';
                            });
                            _fetchData();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _dailySubTab == 'Power'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: _dailySubTab == 'Power'
                                  ? Border.all(color: primaryColor)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'power'.tr,
                              style: TextStyle(
                                color: _dailySubTab == 'Power'
                                    ? primaryColor
                                    : textLightColor,
                                fontWeight: _dailySubTab == 'Power'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_dailySubTab == 'Energy') ...[
                  Text(
                    'energy_flow'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isEnergyLoading)
                    const SizedBox(
                      height: 210,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _buildEnergyFlowTree(
                      gridPercent: gridPercent,
                      batteryPercent: batteryPercent,
                      solarPercent: solarPercent,
                      gridValue: gridValue,
                      batteryValue: batteryValue,
                      solarValue: solarValue,
                    ),
                  const SizedBox(height: 15),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: Container(
                  //         padding: const EdgeInsets.all(12),
                  //         decoration: BoxDecoration(
                  //           color: Colors.grey[50],
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //         child: Row(
                  //           crossAxisAlignment: CrossAxisAlignment.center,
                  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //           children: [
                  //             Row(
                  //               children: [
                  //                 Icon(
                  //                   Icons.home,
                  //                   color: Colors.blue[300],
                  //                   size: 16,
                  //                 ),
                  //                 const SizedBox(width: 4),
                  //                 Text(
                  //                   'consumption'.tr,
                  //                   style: TextStyle(
                  //                     color: textLightColor,
                  //                     fontSize: 12,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //             // const SizedBox(width: 15),
                  //             RichText(
                  //               text: TextSpan(
                  //                 children: [
                  //                   TextSpan(
                  //                     text: totalConsumption.toStringAsFixed(2),
                  //                     style: const TextStyle(
                  //                       color: textColor,
                  //                       fontSize: 18,
                  //                       fontWeight: FontWeight.bold,
                  //                     ),
                  //                   ),
                  //                   const TextSpan(
                  //                     text: ' kWh',
                  //                     style: TextStyle(
                  //                       color: textLightColor,
                  //                       fontSize: 12,
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //     // const SizedBox(width: 12),

                  //     // Expanded(
                  //     //   child: Container(
                  //     //     padding: const EdgeInsets.all(12),
                  //     //     decoration: BoxDecoration(
                  //     //       color: Colors.grey[50],
                  //     //       borderRadius: BorderRadius.circular(8),
                  //     //     ),
                  //     //     child: Column(
                  //     //       crossAxisAlignment: CrossAxisAlignment.start,
                  //     //       children: [
                  //     //         Row(
                  //     //           children: [
                  //     //             Icon(
                  //     //               Icons.monetization_on,
                  //     //               color: Colors.amber,
                  //     //               size: 16,
                  //     //             ),
                  //     //             const SizedBox(width: 4),
                  //     //             Text(
                  //     //               'cost_savings'.tr,
                  //     //               style: TextStyle(
                  //     //                 color: textLightColor,
                  //     //                 fontSize: 12,
                  //     //               ),
                  //     //             ),
                  //     //           ],
                  //     //         ),
                  //     //         const SizedBox(height: 4),
                  //     //         Text(
                  //     //           '\$${costSavings.toStringAsFixed(2)}',
                  //     //           style: const TextStyle(
                  //     //             color: textColor,
                  //     //             fontSize: 18,
                  //     //             fontWeight: FontWeight.bold,
                  //     //           ),
                  //     //         ),
                  //     //       ],
                  //     //     ),
                  //     //   ),
                  //     // ),
                  //   ],
                  // ),
                  // const SizedBox(height: 20),
                  _buildDailyEnergyCharts(energyDayData, isEnergyLoading),
                ] else ...[
                  _buildDailyPowerCharts(powerDayData, isPowerLoading),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildDailyEnergyCharts(Map<String, dynamic>? data, bool isLoading) {
    if (isLoading)
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );

    final xdata = data?['xdata'] as List<dynamic>? ?? [];
    final ydataGf = data?['ydataGf'] as List<dynamic>? ?? [];
    final ydataDw = data?['ydataDw'] as List<dynamic>? ?? [];
    final ydataFh = data?['ydataFh'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'time_of_consumption'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Spacer(),
            Text(
              '(kWh)',
              style: TextStyle(fontSize: 12, color: textLightColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Echarts(
            option: jsonEncode({
              "grid": {
                "left": '12%',
                "right": '5%',
                "top": '20%',
                "bottom": '15%',
              },
              "tooltip": {"trigger": "axis", 'confine': true},
              "legend": {
                "data": ['solar'.tr, 'grid'.tr, 'load'.tr],
                "icon": 'circle',
                "itemWidth": 8,
                "itemHeight": 8,
                "textStyle": {"fontSize": 10, "color": '#999'},
                "top": 0,
                "left": 'center',
              },
              "xAxis": {
                "type": 'category',
                "data": xdata,
                "axisLine": {"show": false},
                "axisTick": {"show": false},
                "axisLabel": {"color": '#999', "fontSize": 10},
              },
              "yAxis": {
                "type": 'value',
                "splitLine": {
                  "lineStyle": {"type": 'dashed', "color": '#eee'},
                },
                "axisLabel": {"color": '#999', "fontSize": 10},
              },
              "series": [
                {
                  "name": 'solar'.tr,
                  "type": 'bar',
                  "stack": 'total',
                  "data": ydataGf,
                  "itemStyle": {"color": '#FFC107'},
                  "barWidth": 7,
                },
                {
                  "name": 'grid'.tr,
                  "type": 'bar',
                  "stack": 'total',
                  "data": ydataDw,
                  "itemStyle": {"color": '#3B82F6'},
                  "barWidth": 7,
                },
                {
                  "name": 'load'.tr,
                  "type": 'bar',
                  "stack": 'total',
                  "data": ydataFh,
                  "itemStyle": {"color": '#A855F7'},
                  "barWidth": 7,
                },
              ],
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPowerCharts(Map<String, dynamic>? data, bool isLoading) {
    if (isLoading)
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );

    final xdata = data?['xdata'] as List<dynamic>? ?? [];
    final ydataGf = data?['ydataGf'] as List<dynamic>? ?? [];
    final ydataDw = data?['ydataDw'] as List<dynamic>? ?? [];
    final ydataFh = data?['ydataFh'] as List<dynamic>? ?? [];
    final dwDependency = data?['dwDependency'] as List<dynamic>? ?? [];

    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'power_flow'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(kW)',
                  style: TextStyle(fontSize: 12, color: textLightColor),
                ),
              ],
            ),
            // const SizedBox(height: 4),
            // Text(
            //   'power_flow_desc'.tr,
            //   style: TextStyle(fontSize: 12, color: textLightColor),
            // ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Echarts(
            option: jsonEncode({
              "grid": {
                "left": '12%',
                "right": '5%',
                "top": '20%',
                "bottom": '15%',
              },
              "legend": {
                "data": ['solar'.tr, 'grid'.tr, 'load'.tr],
                "icon": 'circle',
                "itemWidth": 8,
                "itemHeight": 8,
                "textStyle": {"fontSize": 10, "color": '#999'},
                "top": 0,
                "left": 'center',
              },
              "tooltip": {"trigger": "axis", 'confine': true},
              "xAxis": {
                "type": 'category',
                "data": xdata,
                "axisLine": {"show": false},
                "axisTick": {"show": false},
                "axisLabel": {"color": '#999', "fontSize": 10},
              },
              "yAxis": {
                "type": 'value',
                "splitLine": {
                  "lineStyle": {"type": 'dashed', "color": '#eee'},
                },
                "axisLabel": {"color": '#999', "fontSize": 10},
              },
              "series": [
                {
                  "name": 'solar'.tr,
                  "type": 'line',
                  "smooth": true,
                  "data": ydataGf,
                  "itemStyle": {"color": '#FFC107'},
                  "showSymbol": false,
                },
                {
                  "name": 'grid'.tr,
                  "type": 'line',
                  "smooth": true,
                  "data": ydataDw,
                  "itemStyle": {"color": '#3B82F6'},
                  "showSymbol": false,
                },
                {
                  "name": 'load'.tr,
                  "type": 'line',
                  "smooth": true,
                  "data": ydataFh,
                  "itemStyle": {"color": '#A855F7'},
                  "showSymbol": false,
                },
              ],
            }),
          ),
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'grid_dependency'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(%)',
                  style: TextStyle(fontSize: 12, color: textLightColor),
                ),
              ],
            ),
            // const SizedBox(height: 4),
            // Text(
            //   'grid_dependency_desc'.tr,
            //   style: TextStyle(fontSize: 12, color: textLightColor),
            // ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Echarts(
            option: jsonEncode({
              "grid": {
                "left": '12%',
                "right": '5%',
                "top": '10%',
                "bottom": '15%',
              },
              "tooltip": {"trigger": "axis", 'confine': true},
              "xAxis": {
                "type": 'category',
                "data": xdata,
                "axisLine": {"show": false},
                "axisTick": {"show": false},
                "axisLabel": {"color": '#999', "fontSize": 10},
              },
              "yAxis": {
                "type": 'value',
                "max": 100,
                "splitLine": {
                  "lineStyle": {"type": 'dashed', "color": '#eee'},
                },
                "axisLabel": {"color": '#999', "fontSize": 10},
              },
              "series": [
                {
                  "type": 'line',
                  "smooth": true,
                  "data": dwDependency,
                  "itemStyle": {"color": '#24C18F'},
                  "showSymbol": false,
                },
              ],
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyFlowTree({
    required String gridPercent,
    required String batteryPercent,
    required String solarPercent,
    required double gridValue,
    required double batteryValue,
    required double solarValue,
  }) {
    return Container(
      height: 240,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          // 底层绘制连线
          Positioned.fill(child: CustomPaint(painter: _EnergyFlowPainter())),

          // 上层放置组件
          Row(
            children: [
              const SizedBox(width: 20),
              // Left: Site
              SizedBox(
                width: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/siteicon.png', width: 80),
                    const SizedBox(height: 8),
                    Text(
                      'site'.tr,
                      style: const TextStyle(
                        color: textLightColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer for the horizontal line
              const SizedBox(width: 60),

              // Right: Grid, SunBox, Solar
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnergyNode(
                      'solar'.tr,
                      '$solarPercent%',
                      '${solarValue.toStringAsFixed(2)}kWh',
                      'assets/solaricon.png',
                    ),

                    _buildEnergyNode(
                      'sunbox'.tr,
                      '',
                      '',
                      'assets/sunboxicon.png',
                      showData: false,
                    ),
                    _buildEnergyNode(
                      'grid'.tr,
                      '$gridPercent%',
                      '${gridValue.toStringAsFixed(2)}kWh',
                      'assets/gridicon.png',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyNode(
    String title,
    String percent,
    String value,
    String iconPath, {
    bool showData = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(iconPath, width: 48, height: 48),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(color: textLightColor, fontSize: 14),
            ),
            if (showData) ...[
              const SizedBox(height: 2),
              Text(
                percent,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _EnergyFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // 假设右侧图标宽度为 48
    double iconWidth = 48;

    // Y 轴关键点 (对应右侧三个节点的高度中心)
    // 整个区域高度 220 (240 - 2*10 padding)，分为三等份，节点中心大约在 24, 110, 196
    double nodeY1 = 24; // 现在上方是 Solar
    double nodeY2 = 110; // 中间是 SunBox (and Site)
    double nodeY3 = 196; // 现在下方是 Grid

    // X 轴关键点
    double siteRightEdge = 100 + 20; // Site 容器宽度
    double spacerWidth = 60; // 中间间距
    double rightColumnLeftEdge = siteRightEdge + spacerWidth;

    // 垂直对齐线：穿过右侧三个图标的中心
    double iconCenterX = rightColumnLeftEdge + (iconWidth / 2);

    // 主横线：从 Site 出来
    double startX = siteRightEdge - 10; // 稍微深入 Site 图标一点

    // 向下分支的位置：在横线中段偏右 (原本连上方Grid的分支，现在改为连下方Grid)
    double branchX = siteRightEdge + (spacerWidth * 0.6);

    // 圆角半径
    double radius = 6.0;

    // --- 1. 从 Site 到 SunBox 的水平横线 ---
    // 横线直接连接到 SunBox 的左边缘
    path.moveTo(startX, nodeY2);
    path.lineTo(rightColumnLeftEdge, nodeY2);

    // --- 2. 向下分支连 Grid 的左侧 (Grid 现在在底部) ---
    path.moveTo(branchX, nodeY2);
    path.lineTo(branchX, nodeY3 - radius);
    // 向右转折圆角，连接到 Grid 左侧
    path.quadraticBezierTo(branchX, nodeY3, branchX + radius, nodeY3);
    path.lineTo(rightColumnLeftEdge, nodeY3);

    // --- 3. 连接 Solar -> SunBox -> Grid 的垂直中轴线 ---
    // 从 Solar(上) 底部，穿过 SunBox(中)，到达 Grid(下) 顶部
    // 假设图标高度 48，中心 +/- 24 即为上下边缘
    double iconHalfHeight = 24;

    // Solar 到 SunBox
    path.moveTo(iconCenterX, nodeY1 + iconHalfHeight);
    path.lineTo(iconCenterX, nodeY2 - iconHalfHeight);

    // SunBox 到 Grid
    path.moveTo(iconCenterX, nodeY2 + iconHalfHeight);
    path.lineTo(iconCenterX, nodeY3 - iconHalfHeight);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
