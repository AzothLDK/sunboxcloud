import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';

class CustomizeIndicatorsDialog extends StatefulWidget {
  final List<String> selectedIndicators;
  final Function(List<String>) onConfirm;

  const CustomizeIndicatorsDialog({
    super.key,
    required this.selectedIndicators,
    required this.onConfirm,
  });

  @override
  State<CustomizeIndicatorsDialog> createState() =>
      _CustomizeIndicatorsDialogState();
}

class _CustomizeIndicatorsDialogState extends State<CustomizeIndicatorsDialog> {
  late List<String> _selectedIndicators;
  String? _errorMessage;
  final List<IndicatorItem> _indicatorItems = [
    IndicatorItem('solar_generation', 'solar_generation'.tr),
    IndicatorItem('site_load', 'site_load'.tr),
    IndicatorItem('battery_charging', 'battery_charging'.tr),
    IndicatorItem('battery_discharging', 'battery_discharging'.tr),
    IndicatorItem('buy_from_grid', 'buy_from_grid'.tr),
    IndicatorItem('sell_to_grid', 'sell_to_grid'.tr),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndicators = List.from(widget.selectedIndicators);
    // 初始验证
    _validateSelection();
  }

  void _toggleIndicator(String indicatorId) {
    setState(() {
      if (_selectedIndicators.contains(indicatorId)) {
        _selectedIndicators.remove(indicatorId);
      } else {
        if (_selectedIndicators.length < 4) {
          _selectedIndicators.add(indicatorId);
        }
      }
      // 检查选择的指标数量是否符合要求
      _validateSelection();
    });
  }

  void _validateSelection() {
    if (_selectedIndicators.isEmpty) {
      _errorMessage = 'error_select_indicators'.tr;
    } else if (_selectedIndicators.length == 1 ||
        _selectedIndicators.length == 3) {
      _errorMessage = 'error_select_indicators'.tr;
    } else {
      _errorMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'customize_indicators'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: _indicatorItems.map((item) {
                return CheckboxListTile(
                  title: Text(item.name),
                  value: _selectedIndicators.contains(item.id),
                  onChanged: (value) {
                    if (value != null) {
                      _toggleIndicator(item.id);
                    }
                  },
                  activeColor: primaryColor,
                );
              }).toList(),
            ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(color: textLightColor),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // 先验证选择
                    _validateSelection();
                    // 只有当没有错误时才确认
                    if (_errorMessage == null) {
                      widget.onConfirm(_selectedIndicators);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'confirm'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IndicatorItem {
  final String id;
  final String name;

  IndicatorItem(this.id, this.name);
}
