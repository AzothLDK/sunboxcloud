import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_echarts/flutter_echarts.dart';
import '../../utils/constants.dart';
import 'package:get/get.dart';
import '../../pages/backup_reserve_page.dart';
import 'site_detail_tab.dart';

class DevicesTab extends StatefulWidget {
  const DevicesTab({super.key});

  @override
  State<DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<DevicesTab> {
  // 选中的顶部标签
  String _selectedTopTab = 'SunBox';
  // 能量统计时间范围
  String _energyTimeRange = 'Week';
  // 能量统计日期
  final String _energyDate = 'Mar 2 - 8';

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
          body: Column(
            children: [
              // 顶部标签栏
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTopTab = 'SunBox';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            child: Text(
                              'SunBox',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _selectedTopTab == 'SunBox'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedTopTab == 'SunBox'
                                    ? primaryColor
                                    : textColor,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTopTab = 'Site Detail';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            child: Text(
                              'Site Detail',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _selectedTopTab == 'Site Detail'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedTopTab == 'Site Detail'
                                    ? primaryColor
                                    : textColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 设置按钮
                    IconButton(
                      icon: const Icon(Icons.settings, color: textColor),
                      onPressed: () {
                        // 显示设置页面或弹窗
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              height: 300,
                              child: _buildSettingsTab(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              // 内容区域
              Expanded(
                child: _selectedTopTab == 'SunBox'
                    ? _buildChartsTab()
                    : const SiteDetailTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 图表标签页
  Widget _buildChartsTab() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          // 顶部状态与设备卡片
          _buildTopDeviceStatusCard(),
          const SizedBox(height: 16),
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
                      const Text(
                        'Standby',
                        style: TextStyle(
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
                        const Text(
                          'Charged',
                          style: TextStyle(fontSize: 12, color: Colors.black45),
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
                        const Text(
                          'Discharged',
                          style: TextStyle(fontSize: 12, color: Colors.black45),
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
            width: 120,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 40, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerAndChargeCard() {
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
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Power ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: '(kW)',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              const Text(
                'Today',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Power Line Chart
          SizedBox(
            height: 150,
            child: Echarts(
              option: jsonEncode({
                "grid": {
                  "left": "0%",
                  "right": "0%",
                  "bottom": "0%",
                  "top": "5%",
                  "containLabel": true,
                },
                "tooltip": {"trigger": "axis", 'confine': true},
                "xAxis": {
                  "type": "category",
                  "boundaryGap": false,
                  "data": [
                    "00",
                    "02",
                    "04",
                    "06",
                    "08",
                    "10",
                    "12",
                    "14",
                    "16",
                    "18",
                    "20",
                    "22",
                    "24",
                  ],
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
                  "min": 0.0,
                  "max": 0.4,
                  "interval": 0.1,
                },
                "series": [
                  {
                    "type": "line",
                    "smooth": true,
                    "showSymbol": false,
                    "data": [
                      0.15,
                      0.13,
                      0.17,
                      0.17,
                      0.18,
                      0.17,
                      0.22,
                      0.25,
                      0.25,
                    ],
                    "itemStyle": {"color": "#64B5F6"},
                    "lineStyle": {"width": 2},
                  },
                  {
                    "type": "line",
                    "smooth": true,
                    "showSymbol": false,
                    "data": [
                      0.13,
                      0.11,
                      0.15,
                      0.15,
                      0.16,
                      0.15,
                      0.20,
                      0.24,
                      0.24,
                    ],
                    "itemStyle": {"color": "#81C784"},
                    "lineStyle": {"width": 2},
                  },
                  {
                    "type": "line",
                    "smooth": true,
                    "showSymbol": false,
                    "data": [
                      0.11,
                      0.09,
                      0.13,
                      0.13,
                      0.14,
                      0.13,
                      0.18,
                      0.21,
                      0.21,
                    ],
                    "itemStyle": {"color": "#FFB74D"},
                    "lineStyle": {"width": 2},
                  },
                ],
              }),
            ),
          ),
          const SizedBox(height: 24),
          // Charge Level Header
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Charge Level ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
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
                  "left": "0%",
                  "right": "0%",
                  "bottom": "0%",
                  "top": "5%",
                  "containLabel": true,
                },
                "tooltip": {"trigger": "axis", 'confine': true},
                "xAxis": {
                  "type": "category",
                  "boundaryGap": false,
                  "data": [
                    "00",
                    "02",
                    "04",
                    "06",
                    "08",
                    "10",
                    "12",
                    "14",
                    "16",
                    "18",
                    "20",
                    "22",
                    "24",
                  ],
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
                  "interval": 20,
                },
                "series": [
                  {
                    "type": "line",
                    "smooth": true,
                    "showSymbol": false,
                    "data": [58, 55, 62, 60, 61, 59, 70, 76, 76],
                    "itemStyle": {"color": "#4CAF50"},
                    "lineStyle": {"width": 2},
                    "areaStyle": {
                      "color": {
                        "type": "linear",
                        "x": 0,
                        "y": 0,
                        "x2": 0,
                        "y2": 1,
                        "colorStops": [
                          {"offset": 0, "color": "rgba(76, 175, 80, 0.3)"},
                          {"offset": 1, "color": "rgba(76, 175, 80, 0.0)"},
                        ],
                      },
                    },
                  },
                ],
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyStatisticsCard() {
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
          // Header & Segment Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Energy ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: '(kWh)',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
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
                    _buildTimeTab('Week'),
                    _buildTimeTab('Month'),
                    _buildTimeTab('Year'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                _energyTimeRange == 'Week' ? 'Mar 2–8' : _energyDate,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                          Icon(
                            Icons.battery_charging_full,
                            size: 16,
                            color: Colors.deepPurple[400],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Discharged',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '0.52 ',
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
                          const Icon(
                            Icons.battery_saver,
                            size: 16,
                            color: Color(0xFF24C18F),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Charged',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '1.00 ',
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
          const SizedBox(height: 24),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Discharged',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF24C18F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Charged',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              const Icon(Icons.open_in_full, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          // Bar Chart
          SizedBox(
            height: 180,
            child: Echarts(
              option: jsonEncode({
                "grid": {
                  "left": "0%",
                  "right": "0%",
                  "bottom": "0%",
                  "top": "5%",
                  "containLabel": true,
                },
                "tooltip": {"trigger": "axis", "confine": false},
                "xAxis": {
                  "type": "category",
                  "data": ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
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
                  "max": 2.0,
                  "interval": 0.5,
                },
                "series": [
                  {
                    "name": "Discharged",
                    "type": "bar",
                    "barWidth": 10,
                    "data": [0.15, 0.22, 0.22, 0.45, 0.22, 0.22, 0.85],
                    "itemStyle": {"color": "#7E57C2"},
                  },
                  {
                    "name": "Charged",
                    "type": "bar",
                    "barWidth": 10,
                    "data": [0.10, 0.30, 0.50, 0.30, 0.50, 0.50, 0.65],
                    "itemStyle": {"color": "#24C18F"},
                  },
                ],
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab(String text) {
    bool isSelected = _energyTimeRange == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _energyTimeRange = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF24C18F) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 设置标签页
  Widget _buildSettingsTab() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: ListView(
        children: [
          // 网络状态
          Container(
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
                    const Icon(Icons.wifi, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    const Text('Network'),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Connected',
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
          const SizedBox(height: 10),
          // 运行模式
          Container(
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
                    const Icon(Icons.settings, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    const Text('Operational Mode'),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Self-Consumption',
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
          const SizedBox(height: 10),
          // 备份储备
          GestureDetector(
            onTap: () {
              Get.to(const BackupReservePage());
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
                      const Text('Backup Reserve'),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '20%',
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
  }
}
