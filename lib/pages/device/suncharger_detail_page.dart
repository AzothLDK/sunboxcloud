import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../widgets/custom_date_picker.dart';
import 'charging_records_page.dart';
import 'scheduled_task_page.dart';

class SunChargerDetailPage extends StatefulWidget {
  final String? deviceName;
  final String? deviceId;

  const SunChargerDetailPage({super.key, this.deviceName, this.deviceId});

  @override
  State<SunChargerDetailPage> createState() => _SunChargerDetailPageState();
}

class _SunChargerDetailPageState extends State<SunChargerDetailPage> {
  final StationController controller = Get.find<StationController>();
  final ScrollController _scrollController = ScrollController();
  String _energyTimeRange = 'Week';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _energyTimeRange = 'week'.tr;
    if (widget.deviceId != null) {
      // 模拟加载数据
      _fetchData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchData() {
    // 这里可以调用接口获取充电记录和统计数据
    // 目前先模拟数据
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
    _fetchData();
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
    _fetchData();
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
          _fetchData();
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Get.back(),
            ),
            title: Text(
              widget.deviceName ?? 'SunCharger',
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
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildChargingRecords(),
                const SizedBox(height: 16),
                _buildEnergyStatistics(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24C18F), Color(0xFF1E9E74)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24C18F).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'charging'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'started'.tr} 09:16',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.stop, color: Colors.orange, size: 20),
                  label: Text(
                    'stop'.tr,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildMetricItem('7.2', 'kW'),
                  const SizedBox(width: 16),
                  _buildMetricItem('32', 'A'),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: 0.0,
                      strokeWidth: 5,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    '0%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingRecords() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'charging_records'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            TextButton(
              onPressed: () =>
                  Get.to(() => ChargingRecordsPage(deviceId: widget.deviceId)),
              child: Row(
                children: [
                  Text(
                    'view_all'.tr,
                    style: const TextStyle(color: primaryColor, fontSize: 14),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: primaryColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildRecordCard(
          energy: '18.6',
          duration: '3h 24m',
          time: '09:16 – now',
          status: 'charging'.tr,
          isCharging: true,
        ),
        const SizedBox(height: 12),
        _buildRecordCard(
          energy: '24.8',
          duration: '8h 15m',
          time: 'May 11 22:00 – May 12 06:15',
          status: 'completed'.tr,
          isCharging: false,
        ),
        const SizedBox(height: 12),
        _buildRecordCard(
          energy: '12.3',
          duration: '3h 15m',
          time: 'May 10 14:30 – 17:45',
          status: 'completed'.tr,
          isCharging: false,
        ),
      ],
    );
  }

  Widget _buildRecordCard({
    required String energy,
    required String duration,
    required String time,
    required String status,
    required bool isCharging,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isCharging ? Colors.orange : const Color(0xFF24C18F),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$energy ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const TextSpan(
                            text: 'kWh',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCharging
                            ? Colors.orange.withOpacity(0.1)
                            : const Color(0xFF24C18F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isCharging
                              ? Colors.orange
                              : const Color(0xFF24C18F),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const TextSpan(
                      text: '(kWh)',
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _onPrevDate,
              ),
              GestureDetector(
                onTap: _selectDate,
                child: Text(
                  _dateDisplayText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _hasNextDate ? _onNextDate : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.flash_on,
                  label: 'charged'.tr,
                  value: '3.64',
                  unit: 'kWh',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.history,
                  label: 'charge_count'.tr,
                  value: '10',
                  unit: '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Echarts(
              option: '''
              {
                "grid": {
                  "left": "5%",
                  "right": "3%",
                  "bottom": "3%",
                  "top": "10%",
                  "containLabel": true
                },
                "xAxis": {
                  "type": "category",
                  "data": ["05-11", "05-12", "05-13", "05-14", "05-15", "05-16", "05-17"],
                  "axisLine": {"show": false},
                  "axisTick": {"show": false},
                  "axisLabel": {"color": "#999999"}
                },
                "yAxis": {
                  "type": "value",
                  "axisLine": {"show": false},
                  "axisTick": {"show": false},
                  "splitLine": {"lineStyle": {"type": "dashed", "color": "#EEEEEE"}}
                },
                "series": [
                  {
                    "data": [0, 0.6, 3.0, 0, 0, 0, 0],
                    "type": "bar",
                    "barWidth": "10",
                    "itemStyle": {
                      "color": "#24C18F",
                      "borderRadius": [5, 5, 0, 0]
                    }
                  }
                ]
              }
              ''',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab(String label) {
    bool isSelected = _energyTimeRange == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _energyTimeRange = label;
        });
        _fetchData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: unit,
                    style: const TextStyle(fontSize: 12, color: textColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 设置标签页
  Widget _buildSettingsTab() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(10),
      child: ListView(
        children: [
          GestureDetector(
            onTap: () {
              Get.back(); // 先关闭 BottomSheet
              Get.to(() => ScheduledTaskPage(deviceId: widget.deviceId));
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
                        Icons.timer_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text('scheduled_task'.tr),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(
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
  }
}
