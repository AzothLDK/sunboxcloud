import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

enum CustomDatePickerMode { day, month, year }

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final CustomDatePickerMode mode;
  final Function(DateTime) onConfirm;
  final DateTime? maxDate;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.mode,
    required this.onConfirm,
    this.maxDate,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _currentViewDate;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentViewDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
    _selectedDate = widget.initialDate;
  }

  void _onPrev() {
    setState(() {
      if (widget.mode == CustomDatePickerMode.day) {
        _currentViewDate = DateTime(
          _currentViewDate.year,
          _currentViewDate.month - 1,
        );
      } else if (widget.mode == CustomDatePickerMode.month) {
        _currentViewDate = DateTime(
          _currentViewDate.year - 1,
          _currentViewDate.month,
        );
      } else {
        _currentViewDate = DateTime(
          _currentViewDate.year - 10,
          _currentViewDate.month,
        );
      }
    });
  }

  void _onNext() {
    setState(() {
      if (widget.mode == CustomDatePickerMode.day) {
        _currentViewDate = DateTime(
          _currentViewDate.year,
          _currentViewDate.month + 1,
        );
      } else if (widget.mode == CustomDatePickerMode.month) {
        _currentViewDate = DateTime(
          _currentViewDate.year + 1,
          _currentViewDate.month,
        );
      } else {
        _currentViewDate = DateTime(
          _currentViewDate.year + 10,
          _currentViewDate.month,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    if (widget.mode == CustomDatePickerMode.day) title = 'select_date'.tr;
    if (widget.mode == CustomDatePickerMode.month) title = 'select_month'.tr;
    if (widget.mode == CustomDatePickerMode.year) title = 'select_year'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: textLightColor,
                    size: 20,
                  ),
                  onPressed: () => Get.back(),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sub Header with navigation
          _buildSubHeader(),
          const SizedBox(height: 20),
          // Content
          _buildContent(),
          const SizedBox(height: 32),
          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(_selectedDate);
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'confirm_btn'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    String text = '';
    if (widget.mode == CustomDatePickerMode.day) {
      if (Get.locale?.languageCode == 'zh') {
        text = DateFormat('yyyy年M月', 'zh_CN').format(_currentViewDate);
      } else {
        text = DateFormat('MMMM yyyy', 'en_US').format(_currentViewDate);
      }
    } else if (widget.mode == CustomDatePickerMode.month) {
      if (Get.locale?.languageCode == 'zh') {
        text = '${_currentViewDate.year}年';
      } else {
        text = '${_currentViewDate.year}';
      }
    } else {
      int startYear = (_currentViewDate.year ~/ 10) * 10;
      text = '$startYear - ${startYear + 9}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: textLightColor),
          onPressed: _onPrev,
        ),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: textLightColor),
          onPressed: _onNext,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.mode == CustomDatePickerMode.day) return _buildDayGrid();
    if (widget.mode == CustomDatePickerMode.month) return _buildMonthGrid();
    return _buildYearGrid();
  }

  Widget _buildDayGrid() {
    final firstDayOfMonth = DateTime(
      _currentViewDate.year,
      _currentViewDate.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentViewDate.year,
      _currentViewDate.month + 1,
      0,
    );
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday
    final prevMonthLastDay = DateTime(
      _currentViewDate.year,
      _currentViewDate.month,
      0,
    ).day;

    final List<Widget> dayWidgets = [];
    final weekDayKeys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

    // Weekday headers
    for (var key in weekDayKeys) {
      dayWidgets.add(
        Center(
          child: Text(
            key.tr,
            style: const TextStyle(color: textLightColor, fontSize: 14),
          ),
        ),
      );
    }

    // Previous month days
    for (int i = startWeekday - 1; i >= 0; i--) {
      dayWidgets.add(
        _buildDayCell(prevMonthLastDay - i, isCurrentMonth: false),
      );
    }

    // Current month days
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      dayWidgets.add(_buildDayCell(i, isCurrentMonth: true));
    }

    // Next month days
    int remainingCells = 42 - dayWidgets.length + 7; // Total 6 rows + headers
    for (int i = 1; i <= remainingCells % 7; i++) {
      // just fill the current row
    }

    // Ensure we have 6 rows of dates
    int totalCellsNeeded = 42 + 7;
    int currentDayCount = 1;
    while (dayWidgets.length < totalCellsNeeded) {
      dayWidgets.add(_buildDayCell(currentDayCount++, isCurrentMonth: false));
    }

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(int day, {required bool isCurrentMonth}) {
    final bool isSelected =
        isCurrentMonth &&
        _selectedDate.year == _currentViewDate.year &&
        _selectedDate.month == _currentViewDate.month &&
        _selectedDate.day == day;

    final date = DateTime(_currentViewDate.year, _currentViewDate.month, day);
    final bool isFuture =
        widget.maxDate != null &&
        date.isAfter(
          DateTime(
            widget.maxDate!.year,
            widget.maxDate!.month,
            widget.maxDate!.day,
          ),
        );

    return GestureDetector(
      onTap: () {
        if (isCurrentMonth && !isFuture) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : null,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isFuture
                      ? Colors.grey[300]
                      : (isCurrentMonth ? textColor : Colors.grey[300])),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final monthKeys = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected =
            _selectedDate.year == _currentViewDate.year &&
            _selectedDate.month == month;

        final date = DateTime(_currentViewDate.year, month, 1);
        final isFuture =
            widget.maxDate != null &&
            date.isAfter(
              DateTime(widget.maxDate!.year, widget.maxDate!.month, 1),
            );

        return GestureDetector(
          onTap: () {
            if (!isFuture) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey[100]!,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              monthKeys[index].tr,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isFuture ? Colors.grey[300] : textColor),
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearGrid() {
    int startYear = (_currentViewDate.year ~/ 10) * 10;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 12, // 10 years + 2 buffer
      itemBuilder: (context, index) {
        final year = startYear + index;
        final isCurrentDecade = index >= 0 && index < 10;
        final isSelected = _selectedDate.year == year;

        final isFuture = widget.maxDate != null && year > widget.maxDate!.year;

        return GestureDetector(
          onTap: () {
            if (!isFuture) {
              setState(() {
                _selectedDate = DateTime(year, _selectedDate.month, 1);
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey[100]!,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$year',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isFuture
                          ? Colors.grey[300]
                          : (isCurrentDecade ? textColor : Colors.grey[300])),
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}
