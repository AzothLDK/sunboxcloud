import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'full_screen_chart_page.dart';
import 'backup_reserve_page.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../widgets/custom_date_picker.dart';

class SunBoxDetailPage extends StatefulWidget {
  final String? deviceName;
  final String? deviceId;

  const SunBoxDetailPage({super.key, this.deviceName, this.deviceId});

  @override
  State<SunBoxDetailPage> createState() => _SunBoxDetailPageState();
}

class _SunBoxDetailPageState extends State<SunBoxDetailPage> {
  final StationController controller = Get.find<StationController>();
  final ScrollController _scrollController = ScrollController();
  String _energyTimeRange = 'Week'; // 'Week', 'Month', 'Year'
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 确保第一次加载时语言正确
    _energyTimeRange = 'week'.tr;
    if (widget.deviceId != null) {
      controller.fetchMeterData(widget.deviceId!);
      _fetchFhData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchFhData() {
    if (widget.deviceId == null) return;

    String updateTime;
    if (_energyTimeRange == 'week'.tr || _energyTimeRange == 'Week') {
      // 周：传该周的第一天 (周一)
      final firstDayOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      updateTime = DateFormat('yyyy-MM-dd').format(firstDayOfWeek);
    } else if (_energyTimeRange == 'month'.tr || _energyTimeRange == 'Month') {
      // 月：传年月
      updateTime = DateFormat('yyyy-MM').format(_selectedDate);
    } else {
      // 年：传年
      updateTime = DateFormat('yyyy').format(_selectedDate);
    }

    controller.fetchFhChartData(widget.deviceId!, updateTime);
  }

  String get _dateDisplayText {
    if (_energyTimeRange == 'week'.tr || _energyTimeRange == 'Week') {
      final firstDayOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(firstDayOfWeek)} – ${DateFormat('d, yyyy').format(lastDayOfWeek)}';
    } else if (_energyTimeRange == 'month'.tr || _energyTimeRange == 'Month') {
      return DateFormat(
        'MMMM yyyy',
        Get.locale?.toString(),
      ).format(_selectedDate);
    } else {
      return DateFormat('yyyy').format(_selectedDate);
    }
  }

  void _onPrevDate() {
    setState(() {
      if (_energyTimeRange == 'week'.tr || _energyTimeRange == 'Week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else if (_energyTimeRange == 'month'.tr ||
          _energyTimeRange == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
    _fetchFhData();
  }

  bool get _hasNextDate {
    final now = DateTime.now();
    if (_energyTimeRange == 'week'.tr || _energyTimeRange == 'Week') {
      final nextWeek = _selectedDate.add(const Duration(days: 7));
      final firstDayOfNextWeek = nextWeek.subtract(
        Duration(days: nextWeek.weekday - 1),
      );
      final firstDayOfCurrentWeek = now.subtract(
        Duration(days: now.weekday - 1),
      );
      return !firstDayOfNextWeek.isAfter(firstDayOfCurrentWeek);
    } else if (_energyTimeRange == 'month'.tr || _energyTimeRange == 'Month') {
      final nextMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        1,
      );
      return nextMonth.isBefore(DateTime(now.year, now.month + 1, 1));
    } else {
      return _selectedDate.year < now.year;
    }
  }

  void _onNextDate() {
    if (!_hasNextDate) return;
    setState(() {
      if (_energyTimeRange == 'week'.tr || _energyTimeRange == 'Week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else if (_energyTimeRange == 'month'.tr ||
          _energyTimeRange == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
    _fetchFhData();
  }

  Future<void> _selectDate() async {
    CustomDatePickerMode mode;
    if (_energyTimeRange == 'week'.tr || _energyTimeRange == 'Week') {
      mode = CustomDatePickerMode.day;
    } else if (_energyTimeRange == 'month'.tr || _energyTimeRange == 'Month') {
      mode = CustomDatePickerMode.month;
    } else {
      mode = CustomDatePickerMode.year;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomDatePicker(
        initialDate: _selectedDate,
        maxDate: DateTime.now(),
        mode: mode,
        onConfirm: (date) {
          setState(() {
            _selectedDate = date;
          });
          _fetchFhData();
        },
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Get.back(),
            ),
            title: Text(
              widget.deviceName ?? 'SunBox',
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: textColor),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: _buildSettingsTab(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (widget.deviceId != null) {
                      await Future.wait([
                        controller.fetchMeterData(widget.deviceId!),
                        Future.microtask(() => _fetchFhData()),
                      ]);
                    }
                  },
                  child: _buildChartsTab(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 图表标签页
  Widget _buildChartsTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: [
          // const SizedBox(height: 8),
          // // 顶部状态与设备卡片
          // _buildTopDeviceStatusCard(),
          // const SizedBox(height: 16),
          // 功率和充电水平图表卡片
          _buildPowerAndChargeCard(),
          const SizedBox(height: 16),
          // 能量统计卡片
          _buildEnergyStatisticsCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTopDeviceStatusCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Standby Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'standby'.tr,
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 圆环进度条
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: 0.5,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF24C18F),
                                ),
                              ),
                            ),
                          ),
                          const Center(
                            child: Text(
                              '50%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF24C18F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 充放电数据
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '200 ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: 'kWh',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'charged'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '200 ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: 'kWh',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'discharged'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 电池设备图片占位
          Container(
            // width: 120,
            // height: 140,
            // decoration: BoxDecoration(
            //   color: Colors.grey[100],
            //   borderRadius: BorderRadius.circular(8),
            // ),
            child: Image.asset(
              'assets/sndevice.png',
              // width: 40,
              // height: 40,
              // color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerAndChargeCard() {
    return Obx(() {
      final data = controller.meterData.value;
      if (controller.isMeterDataLoading.value) {
        return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (data == null) {
        return const SizedBox.shrink();
      }

      final powerList = data['powerList'] ?? {};
      final socList = data['socList'] ?? {};

      final powerXAxis = powerList['xaxis'] ?? [];
      final chargeList = powerList['chargeList'] ?? [];
      final disChargeList = powerList['disChargeList'] ?? [];

      final socXAxis = socList['xaxis'] ?? [];
      final socYAxis = socList['yaxis'] ?? [];

      return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Power Chart Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${'power'.tr} ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const TextSpan(
                        text: '(kW)',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                Text(
                  'today'.tr,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),

            // const SizedBox(height: 8),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Container(
            //       width: 8,
            //       height: 8,
            //       decoration: const BoxDecoration(
            //         color: Color(0xFF24C18F),
            //         shape: BoxShape.circle,
            //       ),
            //     ),
            //     const SizedBox(width: 4),
            //     Text(
            //       'charge_power'.tr,
            //       style: const TextStyle(fontSize: 12, color: Colors.black87),
            //     ),
            //     const SizedBox(width: 12),
            //     Container(
            //       width: 8,
            //       height: 8,
            //       decoration: BoxDecoration(
            //         color: Colors.deepPurple[400],
            //         shape: BoxShape.circle,
            //       ),
            //     ),
            //     const SizedBox(width: 4),
            //     Text(
            //       'discharge_power'.tr,
            //       style: const TextStyle(fontSize: 12, color: Colors.black87),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 8),

            // Power Line Chart
            SizedBox(
              height: 150,
              child: Echarts(
                option: jsonEncode({
                  "grid": {
                    "left": "3%",
                    "right": "3%",
                    "bottom": "0%",
                    "top": "5%",
                    "containLabel": true,
                  },
                  "tooltip": {"trigger": "axis", 'confine': true},
                  "xAxis": {
                    "type": "category",
                    "boundaryGap": false,
                    "data": powerXAxis.map((e) {
                      if (e == null) return "";
                      try {
                        return e.toString().substring(11, 16);
                      } catch (_) {
                        return e.toString();
                      }
                    }).toList(),
                    "axisLine": {"show": false},
                    "axisTick": {"show": false},
                    "axisLabel": {"color": "#999999"},
                  },
                  "yAxis": {
                    "type": "value",
                    "splitLine": {
                      "lineStyle": {"type": "dashed", "color": "#EEEEEE"},
                    },
                    "axisLabel": {"color": "#999999"},
                  },
                  "series": [
                    {
                      "name": 'power'.tr,
                      "type": "line",
                      "smooth": true,
                      "showSymbol": false,
                      "data": chargeList.map((e) => e).toList(),
                      "itemStyle": {"color": "#64B5F6"},
                      "lineStyle": {"width": 2},
                    },
                    // {
                    //   "name": 'discharge_power'.tr,
                    //   "type": "line",
                    //   "smooth": true,
                    //   "showSymbol": false,
                    //   "data": disChargeList.map((e) => e).toList(),
                    //   "itemStyle": {"color": "#81C784"},
                    //   "lineStyle": {"width": 2},
                    // },
                  ],
                }),
              ),
            ),
            const SizedBox(height: 24),
            // Charge Level Header
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${'charge_level'.tr} ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const TextSpan(
                    text: '(%)',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Charge Level Area Chart
            SizedBox(
              height: 120,
              child: Echarts(
                option: jsonEncode({
                  "grid": {
                    "left": "3%",
                    "right": "3%",
                    "bottom": "0%",
                    "top": "5%",
                    "containLabel": true,
                  },
                  "tooltip": {"trigger": "axis", 'confine': true},
                  "xAxis": {
                    "type": "category",
                    "boundaryGap": false,
                    "data": socXAxis.map((e) {
                      if (e == null) return "";
                      try {
                        return e.toString().substring(11, 16);
                      } catch (_) {
                        return e.toString();
                      }
                    }).toList(),
                    "axisLine": {"show": false},
                    "axisTick": {"show": false},
                    "axisLabel": {"color": "#999999"},
                  },
                  "yAxis": {
                    "type": "value",
                    "splitLine": {
                      "lineStyle": {"type": "dashed", "color": "#EEEEEE"},
                    },
                    "axisLabel": {"color": "#999999"},
                    "min": 0,
                    "max": 100,
                  },
                  "series": [
                    {
                      "type": "line",
                      "smooth": true,
                      "showSymbol": false,
                      "data": socYAxis.map((e) => e).toList(),
                      "itemStyle": {"color": "#24C18F"},
                      "areaStyle": {
                        "color": {
                          "type": "linear",
                          "x": 0,
                          "y": 0,
                          "x2": 0,
                          "y2": 1,
                          "colorStops": [
                            {"offset": 0, "color": "rgba(36, 193, 143, 0.3)"},
                            {"offset": 1, "color": "rgba(36, 193, 143, 0.0)"},
                          ],
                        },
                      },
                      "lineStyle": {"width": 2},
                    },
                  ],
                }),
              ),
            ),
          ],
        ),
      );
    });
  }

  // 能量统计卡片
  Widget _buildEnergyStatisticsCard() {
    return Obx(() {
      final data = controller.fhChartData.value;

      // 保持高度稳定，防止加载时页面跳动
      Widget content;
      if (controller.isFhChartLoading.value && data == null) {
        content = const SizedBox(
          height: 400,
          child: Center(child: CircularProgressIndicator()),
        );
      } else {
        final powerList = data?['powerList'] ?? {};
        final xAxis = powerList['xaxis'] ?? [];
        final chargeList = powerList['chargeList'] ?? [];
        final disChargeList = powerList['disChargeList'] ?? [];

        final totalCharge = data?['charge'] ?? 0;
        final totalDischarge = data?['discharge'] ?? 0;

        content = Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),

                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${'energy'.tr} ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const TextSpan(
                                  text: '(kWh)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTimeTab('week'.tr),
                                _buildTimeTab('month'.tr),
                                _buildTimeTab('year'.tr),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Date Selector (Site Detail Style)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _onPrevDate,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _selectDate,
                            child: Text(
                              _dateDisplayText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _hasNextDate ? _onNextDate : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: _hasNextDate
                                    ? Colors.grey
                                    : Colors.grey[300],
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.battery_saver,
                                        size: 16,
                                        color: Color(0xFF24C18F),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'charged'.tr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$totalCharge ',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'kWh',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.battery_charging_full,
                                        size: 16,
                                        color: Colors.deepPurple[400],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'discharged'.tr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$totalDischarge ',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'kWh',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
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
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 16),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF24C18F),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'charged'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'discharged'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              final chartOption = {
                                "grid": {
                                  "left": "5%",
                                  "right": "3%",
                                  "bottom": "3%",
                                  "top": "10%",
                                  "containLabel": true,
                                },
                                "tooltip": {
                                  "trigger": "axis",
                                  "confine": false,
                                },
                                "xAxis": {
                                  "type": "category",
                                  "data": xAxis,
                                  "axisLine": {"show": false},
                                  "axisTick": {"show": false},
                                  "axisLabel": {"color": "#999999"},
                                },
                                "yAxis": {
                                  "name": 'kWh',
                                  "type": "value",
                                  "splitLine": {
                                    "lineStyle": {
                                      "type": "dashed",
                                      "color": "#EEEEEE",
                                    },
                                  },
                                  "axisLabel": {"color": "#999999"},
                                },
                                "series": [
                                  {
                                    "name": 'charged'.tr,
                                    "type": "bar",
                                    "barWidth":
                                        (_energyTimeRange == 'month'.tr ||
                                            _energyTimeRange == 'Month')
                                        ? 5
                                        : 10,
                                    "data": chargeList
                                        .map((e) => e ?? 0)
                                        .toList(),
                                    "itemStyle": {"color": "#24C18F"},
                                  },
                                  {
                                    "name": 'discharged'.tr,
                                    "type": "bar",
                                    "barWidth":
                                        (_energyTimeRange == 'month'.tr ||
                                            _energyTimeRange == 'Month')
                                        ? 5
                                        : 10,
                                    "data": disChargeList
                                        .map((e) => e ?? 0)
                                        .toList(),
                                    "itemStyle": {"color": "#7E57C2"},
                                  },
                                ],
                              };
                              Get.to(
                                () => FullScreenChartPage(
                                  chartOption: chartOption,
                                  title: 'energy'.tr,
                                ),
                                fullscreenDialog: false,
                                transition: Transition.fadeIn,
                              );
                            },
                            icon: const Icon(
                              Icons.open_in_full,
                              size: 16,
                              color: Colors.grey,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bar Chart
                SizedBox(
                  height: 200,
                  child: Echarts(
                    option: jsonEncode({
                      "grid": {
                        "left": "5%",
                        "right": "5%",
                        "bottom": "0%",
                        "top": "15%",
                        "containLabel": true,
                      },
                      "tooltip": {"trigger": "axis", 'confine': true},
                      "xAxis": {
                        "type": "category",
                        "data": xAxis,
                        "axisLine": {"show": false},
                        "axisTick": {"show": false},
                        "axisLabel": {"color": "#999999"},
                      },
                      "yAxis": {
                        "name": 'kWh',
                        "type": "value",
                        "splitLine": {
                          "lineStyle": {"type": "dashed", "color": "#EEEEEE"},
                        },
                        "axisLabel": {"color": "#999999"},
                      },
                      "series": [
                        {
                          "name": 'charged'.tr,
                          "type": "bar",
                          "barWidth":
                              (_energyTimeRange == 'month'.tr ||
                                  _energyTimeRange == 'Month')
                              ? 3
                              : 6,
                          "data": chargeList.map((e) => e ?? 0).toList(),
                          "itemStyle": {"color": "#24C18F"},
                        },
                        {
                          "name": 'discharged'.tr,
                          "type": "bar",
                          "barWidth":
                              (_energyTimeRange == 'month'.tr ||
                                  _energyTimeRange == 'Month')
                              ? 3
                              : 6,
                          "data": disChargeList.map((e) => e ?? 0).toList(),
                          "itemStyle": {"color": "#7E57C2"},
                        },
                      ],
                    }),
                  ),
                ),
              ],
            ),
            if (controller.isFhChartLoading.value)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        child: content,
      );
    });
  }

  Widget _buildTimeTab(String range) {
    final isSelected = _energyTimeRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _energyTimeRange = range;
        });
        _fetchFhData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF24C18F) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          range,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Obx(() {
      final meterData = controller.meterData.value;
      final batterySpare = meterData?['batterySpare'] ?? 20.0;
      final batterySparePercent = (batterySpare as num).toInt();

      return Container(
        height: 120,
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Get.to(
                  BackupReservePage(
                    batterySpare: batterySparePercent,
                    deviceCode: widget.deviceId ?? '',
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.battery_std,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text('BSU Protection'.tr),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '$batterySparePercent%',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_right,
                          color: primaryColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
