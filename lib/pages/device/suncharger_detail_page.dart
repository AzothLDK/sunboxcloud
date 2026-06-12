import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../utils/network/api_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/custom_date_picker.dart';
import 'charging_records_page.dart';
import 'scheduled_task_page.dart';

class SunChargerDetailPage extends StatefulWidget {
  final String? deviceName;
  final String? deviceId;
  final String? deviceCode;

  const SunChargerDetailPage({super.key, this.deviceName, this.deviceId, this.deviceCode});

  @override
  State<SunChargerDetailPage> createState() => _SunChargerDetailPageState();
}

class _SunChargerDetailPageState extends State<SunChargerDetailPage> {
  final StationController controller = Get.find<StationController>();
  final ScrollController _scrollController = ScrollController();
  String _energyTimeRange = 'Week';
  DateTime _selectedDate = DateTime.now();

  // 实时充电状态数据
  bool _isLoadingStatus = false;
  int? _status;            // 0-可用, 1-充电中
  String? _chargeStatus;   // cpStatus 字符串
  int? _buttonType;        // 0-开始充电, 1-停止充电
  String? _chargeOrder;
  String? _transactionId;
  String? _chargeStartTime;
  double? _chargePower;
  double? _chargeCurrent;
  double? _chargeSoc;

  // 最新充电记录
  bool _isLoadingRecords = false;
  List<Map<String, dynamic>> _latestRecords = [];

  // 充电统计数据
  bool _isLoadingStats = false;
  double? _statTotalCharged;
  int? _statChargeCount;
  List<String> _statXAxis = [];
  List<double> _statYAxis = [];

  @override
  void initState() {
    super.initState();
    _energyTimeRange = 'week';
    if (widget.deviceId != null) {
      _fetchData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await _fetchChargeRealtime();
    await _fetchLatestRecords();
    await _fetchChargeStatistics();
  }

  Future<void> _fetchChargeRealtime() async {
    if (widget.deviceId == null) return;
    setState(() => _isLoadingStatus = true);
    try {
      final res = await ApiService.getChargeRealtime(widget.deviceId!);
      if (res['code'] == 200 && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        setState(() {
          _status = (data['status'] as num?)?.toInt();
          _chargeStatus = data['cpStatus'] as String?;
          _buttonType = data['buttonType'] as int?;
          _chargeOrder = data['chargeOrder'] as String?;
          _transactionId = data['transactionId']?.toString();
          _chargeStartTime = data['startTime'] as String?;
          _chargePower = (data['power'] as num?)?.toDouble();
          _chargeCurrent = (data['current'] as num?)?.toDouble();
          _chargeSoc = (data['soc'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      // 静默失败
    } finally {
      setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _fetchLatestRecords() async {
    if (widget.deviceId == null) return;
    setState(() => _isLoadingRecords = true);
    try {
      final res = await ApiService.getLatestChargeRecords(widget.deviceId!);
      if (res['code'] == 200 && res['data'] != null) {
        final list = res['data'] as List<dynamic>;
        setState(() {
          _latestRecords = list.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      // 静默失败
    } finally {
      setState(() => _isLoadingRecords = false);
    }
  }

  String _formatRecordTime(String? start, String? end, bool isCharging) {
    if (start == null || start.isEmpty) return '--';
    if (isCharging || end == null || end.isEmpty) {
      return '$start – now';
    }
    return '$start – $end';
  }

  Future<void> _fetchChargeStatistics() async {
    if (widget.deviceId == null) return;

    DateTime start;
    DateTime end;
    if (_energyTimeRange == 'week') {
      start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else if (_energyTimeRange == 'month') {
      start = DateTime(_selectedDate.year, _selectedDate.month, 1);
      end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    } else {
      start = DateTime(_selectedDate.year, 1, 1);
      end = DateTime(_selectedDate.year, 12, 31);
    }

    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);

    setState(() => _isLoadingStats = true);
    try {
      final res = await ApiService.getChargeStatistics(
        chargeConnectorId: widget.deviceId,
        startDate: startStr,
        endDate: endStr,
        type: _energyTimeRange,
      );
      if (res['code'] == 200 && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        setState(() {
          _statTotalCharged = (data['totalCharged'] as num?)?.toDouble();
          _statChargeCount = (data['chargeCount'] as num?)?.toInt();
          final xList = data['xaxis'] as List<dynamic>? ?? [];
          final yList = data['yaxis'] as List<dynamic>? ?? [];
          _statXAxis = xList.map((e) => e.toString()).toList();
          _statYAxis = yList.map((e) => (e as num).toDouble()).toList();
        });
      }
    } catch (e) {
      // 静默失败
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  void _onPrevDate() {
    setState(() {
      if (_energyTimeRange == 'week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else if (_energyTimeRange == 'month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
    _fetchData();
  }

  bool get _hasNextDate {
    final now = DateTime.now();
    if (_energyTimeRange == 'week') {
      final nextWeek = _selectedDate.add(const Duration(days: 7));
      final firstDayOfNextWeek = nextWeek.subtract(
        Duration(days: nextWeek.weekday - 1),
      );
      final firstDayOfCurrentWeek = now.subtract(
        Duration(days: now.weekday - 1),
      );
      return !firstDayOfNextWeek.isAfter(firstDayOfCurrentWeek);
    } else if (_energyTimeRange == 'month') {
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
      if (_energyTimeRange == 'week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else if (_energyTimeRange == 'month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
    _fetchData();
  }

  String get _dateDisplayText {
    if (_energyTimeRange == 'week') {
      final firstDayOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(firstDayOfWeek)} – ${DateFormat('d, yyyy').format(lastDayOfWeek)}';
    } else if (_energyTimeRange == 'month') {
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
    if (_energyTimeRange == 'week') {
      mode = CustomDatePickerMode.day;
    } else if (_energyTimeRange == 'month') {
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
    final bool isCharging = _status == 1;
    final bool showStop = _buttonType == 1;
    final String statusText = _chargeStatus ?? '--';
        
    final String startTimeText = _chargeStartTime ?? '--:--';
    final String powerText = _chargePower != null ? _chargePower!.toStringAsFixed(1) : '--';
    final String currentText = _chargeCurrent != null ? _chargeCurrent!.toStringAsFixed(0) : '--';
    final double socValue = (_chargeSoc ?? 0) / 100.0;
    final String socText = _chargeSoc != null ? '${_chargeSoc!.toStringAsFixed(0)}%' : '--%';

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
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'started'.tr} $startTimeText',
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
                  onPressed: _isLoadingStatus
                      ? null
                      : () async {
                          if (widget.deviceId == null) return;
                          try {
                            if (showStop) {
                              if (_chargeOrder == null) return;
                              final res = await ApiService.stopCharge(
                                chargeOrder: _chargeOrder!,
                                transactionId: _transactionId,
                              );
                              if (res['code'] == 200) {
                                ToastUtils.success('stop_charge_success'.tr);
                              } else {
                                ToastUtils.error(res['msg'] ?? 'stop_charge_failed'.tr);
                              }
                            } else {
                              String? idTag;
                              try {
                                final idTagRes =
                                    await ApiService.getDefaultIdTag(
                                  widget.deviceId!,
                                );
                                if (idTagRes['code'] == 200 &&
                                    idTagRes['data'] != null) {
                                  idTag = idTagRes['data']['idTag'] as String?;
                                }
                              } catch (_) {
                                // 静默失败
                              }
                              if (idTag != null) {
                                final res = await ApiService.startCharge(
                                  chargeConnectorId: widget.deviceId!,
                                  idTag: idTag,
                                );
                                if (res['code'] == 200) {
                                  ToastUtils.success('start_charge_success'.tr);
                                } else {
                                  ToastUtils.error(res['msg'] ?? 'start_charge_failed'.tr);
                                }
                              }
                            }
                            _fetchChargeRealtime();
                          } catch (e) {
                            ToastUtils.error('network_error'.tr);
                          }
                        },
                  icon: Icon(
                    showStop ? Icons.stop : Icons.play_arrow,
                    color: showStop ? Colors.orange : const Color(0xFF24C18F),
                    size: 20,
                  ),
                  label: Text(
                    showStop ? 'stop'.tr : 'start'.tr,
                    style: TextStyle(
                      color: showStop ? Colors.orange : const Color(0xFF24C18F),
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
                  _buildMetricItem(powerText, 'kW'),
                  const SizedBox(width: 16),
                  _buildMetricItem(currentText, 'A'),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: socValue,
                      strokeWidth: 5,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    socText,
                    style: const TextStyle(
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
                  Get.to(() => ChargingRecordsPage(deviceId: widget.deviceId, deviceCode: widget.deviceCode)),
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
        if (_isLoadingRecords)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_latestRecords.isEmpty)
          const SizedBox.shrink()
        else
          ..._latestRecords.asMap().entries.expand((entry) {
            final record = entry.value;
            final isCharging = (record['status'] as int?) == 1;
            final energy =
                (record['chargePower'] as num?)?.toStringAsFixed(1) ?? '--';
            final duration = record['chargeDuration'] as String? ?? '--';
            final time = _formatRecordTime(
              record['startTime'] as String?,
              record['endTime'] as String?,
              isCharging,
            );
            final status = isCharging ? 'charging'.tr : 'completed'.tr;
            final widgets = <Widget>[
              _buildRecordCard(
                energy: energy,
                duration: duration,
                time: time,
                status: status,
                isCharging: isCharging,
              ),
            ];
            if (entry.key != _latestRecords.length - 1) {
              widgets.add(const SizedBox(height: 12));
            }
            return widgets;
          }).toList(),
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
                    _buildTimeTab('week'),
                    _buildTimeTab('month'),
                    _buildTimeTab('year'),
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
                  value: (_statTotalCharged ?? 0).toStringAsFixed(2),
                  unit: 'kWh',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.history,
                  label: 'charge_count'.tr,
                  value: (_statChargeCount ?? 0).toString(),
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
                  "data": ${jsonEncode(_statXAxis.isEmpty ? [] : _statXAxis)},
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
                    "data": ${jsonEncode(_statYAxis.isEmpty ? [] : _statYAxis)},
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
          label.tr,
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
              Get.to(() => ScheduledTaskPage(deviceId: widget.deviceId, deviceCode: widget.deviceCode));
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

