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
      _validateSelection();
    });
  }

  void _validateSelection() {
    if (_selectedIndicators.isEmpty ||
        _selectedIndicators.length == 1 ||
        _selectedIndicators.length == 3) {
      _errorMessage = 'error_select_indicators'.tr;
    } else {
      _errorMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMaxReached = _selectedIndicators.length >= 4;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'customize_indicators'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: textLightColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _indicatorItems.map((item) {
                    bool isSelected = _selectedIndicators.contains(item.id);
                    bool isDisabled = !isSelected && isMaxReached;

                    return GestureDetector(
                      onTap: () => _toggleIndicator(item.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isDisabled
                                      ? Colors.grey[400]
                                      : (isSelected ? primaryColor : textColor),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: primaryColor,
                                size: 20,
                              )
                            else if (isDisabled)
                              Icon(
                                Icons.close,
                                color: Colors.red[300],
                                size: 20,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: Colors.grey[300],
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _errorMessage != null
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _validateSelection();
                  if (_errorMessage == null) {
                    widget.onConfirm(_selectedIndicators);
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'confirm'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
