import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../utils/network/api_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/custom_date_picker.dart';

class ChargingRecordsPage extends StatefulWidget {
  final String? deviceId;
  final String? deviceCode;

  const ChargingRecordsPage({super.key, this.deviceId, this.deviceCode});

  @override
  State<ChargingRecordsPage> createState() => _ChargingRecordsPageState();
}

class _ChargingRecordsPageState extends State<ChargingRecordsPage> {
  DateTime _selectedMonth = DateTime.now();

  bool _isLoading = false;
  List<Map<String, dynamic>> _records = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    final deviceId = widget.deviceId ?? widget.deviceCode;
    if (deviceId == null || deviceId.isEmpty) {
      ToastUtils.error('device_not_found'.tr);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final queryDate = DateFormat('yyyy-MM').format(_selectedMonth);
      final res = await ApiService.getChargeRecordsByDate(
        chargeConnectorId: deviceId,
        queryDate: queryDate,
      );
      if (res['code'] == 200 && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        final list = data['records'] as List<dynamic>? ?? [];
        setState(() {
          _records = list.map((e) => e as Map<String, dynamic>).toList();
          _total = (data['total'] as num?)?.toInt() ?? 0;
        });
      } else {
        ToastUtils.error(res['msg'] ?? 'load_failed'.tr);
      }
    } catch (e) {
      ToastUtils.error('network_error'.tr);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatRecordTime(String? start, String? end, bool isCharging) {
    if (start == null || start.isEmpty) return '--';
    if (isCharging || end == null || end.isEmpty) {
      return '$start – now';
    }
    return '$start – $end';
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'charging_records'.tr,
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildMonthSelector(),
              Expanded(child: _buildRecordsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
              _fetchRecords();
            },
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
            onTap: _selectMonth,
            child: Text(
              DateFormat(
                'MMMM yyyy',
                Get.locale?.toString(),
              ).format(_selectedMonth),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: _hasNextMonth
                ? () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                    });
                    _fetchRecords();
                  }
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                color: _hasNextMonth ? textLightColor : Colors.grey[300],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasNextMonth {
    final now = DateTime.now();
    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  Future<void> _selectMonth() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomDatePicker(
        initialDate: _selectedMonth,
        maxDate: DateTime.now(),
        mode: CustomDatePickerMode.month,
        onConfirm: (date) {
          setState(() {
            _selectedMonth = date;
          });
          _fetchRecords();
        },
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_records.isEmpty) {
      return Center(
        child: Text(
          'no_data'.tr,
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
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
        return _buildRecordCard(
          energy: energy,
          duration: duration,
          time: time,
          status: status,
          isCharging: isCharging,
        );
      },
    );
  }

  Widget _buildRecordCard({
    required String energy,
    required String duration,
    required String time,
    required String status,
    required bool isCharging,
  }) {
    final Color statusColor = isCharging ? Colors.orange : const Color(0xFF24C18F);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: statusColor,
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
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
}
