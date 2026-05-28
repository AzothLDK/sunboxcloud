import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_date_picker.dart';

class ChargingRecordsPage extends StatefulWidget {
  final String? deviceId;

  const ChargingRecordsPage({super.key, this.deviceId});

  @override
  State<ChargingRecordsPage> createState() => _ChargingRecordsPageState();
}

class _ChargingRecordsPageState extends State<ChargingRecordsPage> {
  DateTime _selectedMonth = DateTime.now();

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
        },
      ),
    );
  }

  Widget _buildRecordsList() {
    // 模拟数据
    final List<Map<String, dynamic>> mockRecords = [
      {
        'energy': '18.6',
        'duration': '3h 24m',
        'time': 'May 18 09:16 – 12:40',
        'status': 'completed'.tr,
      },
      {
        'energy': '24.8',
        'duration': '8h 15m',
        'time': 'May 11 22:00 – May 12 06:15',
        'status': 'completed'.tr,
      },
      {
        'energy': '12.3',
        'duration': '3h 15m',
        'time': 'May 10 14:30 – 17:45',
        'status': 'completed'.tr,
      },
      {
        'energy': '18.6',
        'duration': '3h 24m',
        'time': 'May 18 09:16 – 12:40',
        'status': 'completed'.tr,
      },
      {
        'energy': '24.8',
        'duration': '8h 15m',
        'time': 'May 11 22:00 – May 12 06:15',
        'status': 'completed'.tr,
      },
      {
        'energy': '12.3',
        'duration': '3h 15m',
        'time': 'May 10 14:30 – 17:45',
        'status': 'completed'.tr,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: mockRecords.length,
      itemBuilder: (context, index) {
        final record = mockRecords[index];
        return _buildRecordCard(
          energy: record['energy'],
          duration: record['duration'],
          time: record['time'],
          status: record['status'],
        );
      },
    );
  }

  Widget _buildRecordCard({
    required String energy,
    required String duration,
    required String time,
    required String status,
  }) {
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
              color: const Color(0xFF24C18F),
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
                        color: const Color(0xFF24C18F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFF24C18F),
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
