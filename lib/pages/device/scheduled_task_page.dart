import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';

class ScheduledTaskPage extends StatefulWidget {
  final String? deviceId;

  const ScheduledTaskPage({super.key, this.deviceId});

  @override
  State<ScheduledTaskPage> createState() => _ScheduledTaskPageState();
}

class _ScheduledTaskPageState extends State<ScheduledTaskPage> {
  bool _isTimedEnabled = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _stopTime = const TimeOfDay(hour: 7, minute: 0);
  String _stopMode = 'timed_stop'; // 'limited_energy' or 'timed_stop'
  double _maxEnergy = 50.0;

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
              'scheduled_task'.tr,
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    Container(
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
                      child: Column(
                        children: [
                          _buildSettingRow(
                            label: 'timed_start_stop'.tr,
                            trailing: _buildSwitchToggle(
                              value: _isTimedEnabled,
                              onChanged: (val) =>
                                  setState(() => _isTimedEnabled = val),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingRow(
                            label: 'start_time'.tr,
                            trailing: _buildTimePicker(
                              time: _startTime,
                              onTap: () => _selectTime(context, true),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingRow(
                            label: 'stop_mode'.tr,
                            trailing: _buildModeToggle(),
                          ),
                          _buildDivider(),
                          if (_stopMode == 'timed_stop')
                            _buildSettingRow(
                              label: 'stop_time'.tr,
                              trailing: _buildTimePicker(
                                time: _stopTime,
                                isNextDay: true,
                                onTap: () => _selectTime(context, false),
                              ),
                            )
                          else
                            _buildSettingRow(
                              label: 'limited_energy'.tr,
                              trailing: _buildEnergyInput(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String label, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: textColor)),
          trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: borderColor,
    );
  }

  Widget _buildSwitchToggle({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            label: 'off'.tr,
            isSelected: !value,
            onTap: () => onChanged(false),
          ),
          _buildToggleItem(
            label: 'on'.tr,
            isSelected: value,
            onTap: () => onChanged(true),
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            label: 'limited_energy'.tr,
            isSelected: _stopMode == 'limited_energy',
            onTap: () => setState(() => _stopMode = 'limited_energy'),
            activeColor: primaryColor,
          ),
          _buildToggleItem(
            label: 'timed_stop'.tr,
            isSelected: _stopMode == 'timed_stop',
            onTap: () => setState(() => _stopMode = 'timed_stop'),
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black38,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay time,
    bool isNextDay = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          if (isNextDay)
            Text(
              '${'next_day'.tr} ',
              style: const TextStyle(color: Colors.black38, fontSize: 14),
            ),
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
        ],
      ),
    );
  }

  Widget _buildEnergyInput() {
    return Row(
      children: [
        Text(
          '$_maxEnergy kWh',
          style: const TextStyle(
            color: primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            // Save logic
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: Text(
            'save'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _stopTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _stopTime = picked;
        }
      });
    }
  }
}
