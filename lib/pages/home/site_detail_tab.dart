import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import '../../utils/constants.dart';

class SiteDetailTab extends StatefulWidget {
  const SiteDetailTab({super.key});

  @override
  State<SiteDetailTab> createState() => _SiteDetailTabState();
}

class _SiteDetailTabState extends State<SiteDetailTab> {
  // 'Monthly Overview' or 'Daily Analysis'
  String _selectedMainTab = 'Monthly Overview';

  // Monthly Sub Tab: 'Overview' or 'Solar'
  String _monthlySubTab = 'Overview';

  // Daily Sub Tab: 'Energy' or 'Power'
  String _dailySubTab = 'Energy';

  final String _monthlyDate = 'Mar 2026';
  final String _dailyDate = 'Mar 5, 2026';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Main Tabs (Monthly Overview / Daily Analysis)
          _buildMainTabs(),
          const SizedBox(height: 16),
          // Date Selector
          _buildDateSelector(),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _selectedMainTab == 'Monthly Overview'
                ? _buildMonthlyOverview()
                : _buildDailyAnalysis(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMainTab = 'Monthly Overview';
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedMainTab == 'Monthly Overview'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _selectedMainTab == 'Monthly Overview'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Monthly Overview',
                  style: TextStyle(
                    color: _selectedMainTab == 'Monthly Overview'
                        ? primaryColor
                        : textLightColor,
                    fontWeight: _selectedMainTab == 'Monthly Overview'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMainTab = 'Daily Analysis';
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedMainTab == 'Daily Analysis'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _selectedMainTab == 'Daily Analysis'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Daily Analysis',
                  style: TextStyle(
                    color: _selectedMainTab == 'Daily Analysis'
                        ? primaryColor
                        : textLightColor,
                    fontWeight: _selectedMainTab == 'Daily Analysis'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    String dateText = _selectedMainTab == 'Monthly Overview'
        ? _monthlyDate
        : _dailyDate;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
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
        Text(
          dateText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_right,
            color: textLightColor,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyOverview() {
    return ListView(
      children: [
        // Saved Energy & Grid Dependency Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt, color: primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Saved Energy',
                          style: TextStyle(color: textLightColor, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '150.52',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' kWh',
                            style: TextStyle(
                              color: textLightColor,
                              fontSize: 12,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.power, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Grid Dependency',
                          style: TextStyle(color: textLightColor, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '70.0',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' %',
                            style: TextStyle(
                              color: textLightColor,
                              fontSize: 12,
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
        const SizedBox(height: 16),

        // Energy Sources
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Energy Sources',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Donut chart placeholder
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: 0.75, // Grid + Battery
                            strokeWidth: 15,
                            color: Colors.blue,
                            backgroundColor: const Color(0xFFFFC107), // Solar
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: 0.25, // Battery
                            strokeWidth: 15,
                            color: primaryColor,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Legend
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendItem(
                          Colors.blue,
                          '25%',
                          '550.72kWh',
                          'From Grid',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          primaryColor,
                          '25%',
                          '550.72kWh',
                          'From Battery',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          const Color(0xFFFFC107),
                          '50%',
                          '1100.72kWh',
                          'From Solar',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Overview / Solar Tabs & Chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sub tabs
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _monthlySubTab = 'Overview';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _monthlySubTab == 'Overview'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _monthlySubTab == 'Overview'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Overview',
                            style: TextStyle(
                              color: _monthlySubTab == 'Overview'
                                  ? primaryColor
                                  : textLightColor,
                              fontWeight: _monthlySubTab == 'Overview'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _monthlySubTab = 'Solar';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _monthlySubTab == 'Solar'
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Solar',
                            style: TextStyle(
                              color: _monthlySubTab == 'Solar'
                                  ? Colors.white
                                  : textLightColor,
                              fontWeight: _monthlySubTab == 'Solar'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_monthlySubTab == 'Overview') ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.outbox,
                                  color: Colors.purple[200],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Supply',
                                  style: TextStyle(
                                    color: textLightColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '0.52',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' kWh',
                                    style: TextStyle(
                                      color: textLightColor,
                                      fontSize: 12,
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inbox,
                                  color: primaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Consumption',
                                  style: TextStyle(
                                    color: textLightColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '1.00',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' kWh',
                                    style: TextStyle(
                                      color: textLightColor,
                                      fontSize: 12,
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
                const SizedBox(height: 16),
                _buildOverviewChart(),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Solar Production',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '(kWh)',
                      style: TextStyle(fontSize: 12, color: textLightColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSolarChart(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLegendItem(
    Color color,
    String percent,
    String value,
    String label,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    percent,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: textLightColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewChart() {
    return SizedBox(
      height: 200,
      child: Echarts(
        option: '''
        {
          grid: { left: '10%', right: '5%', top: '20%', bottom: '15%' },
          legend: {
            data: ['Solar', 'Grid', 'Battery', 'Load'],
            icon: 'circle',
            itemWidth: 8,
            itemHeight: 8,
            textStyle: { fontSize: 10, color: '#999' },
            top: 0,
            left: 0
          },
          xAxis: {
            type: 'category',
            data: ['1', '4', '7', '10', '13', '16', '19', '22', '25', '28', '31'],
            axisLine: { show: false },
            axisTick: { show: false },
            axisLabel: { color: '#999', fontSize: 10 }
          },
          yAxis: {
            type: 'value',
            splitLine: { lineStyle: { type: 'dashed', color: '#eee' } },
            axisLabel: { color: '#999', fontSize: 10 }
          },
          series: [
            {
              name: 'Battery',
              type: 'bar',
              stack: 'total',
              data: [5, 6, 5, 4, 0, 0, 0, 0, 0, 0, 0],
              itemStyle: { color: '#24C18F' },
              barWidth: 6
            },
            {
              name: 'Grid',
              type: 'bar',
              stack: 'total',
              data: [-5, -6, -5, -4, 0, 0, 0, 0, 0, 0, 0],
              itemStyle: { color: '#3B82F6' },
              barWidth: 6
            },
            {
              name: 'Load',
              type: 'bar',
              stack: 'total2',
              data: [0, 0, 0, 1.5, 2.5, 1.5, 0.5, 0, 0, 0, 0],
              itemStyle: { color: '#A855F7' },
              barWidth: 6
            },
            {
              name: 'Solar',
              type: 'bar',
              stack: 'total2',
              data: [0, 0, 0, 0, 0, 0, 0, -4.5, -6, -5, -4],
              itemStyle: { color: '#FFC107' },
              barWidth: 6
            }
          ]
        }
        ''',
      ),
    );
  }

  Widget _buildSolarChart() {
    return SizedBox(
      height: 200,
      child: Echarts(
        option: '''
        {
          grid: { left: '10%', right: '5%', top: '5%', bottom: '15%' },
          xAxis: {
            type: 'category',
            data: ['1', '4', '7', '10', '13', '16', '19', '22', '25', '28', '31'],
            axisLine: { show: false },
            axisTick: { show: false },
            axisLabel: { color: '#999', fontSize: 10 }
          },
          yAxis: {
            type: 'value',
            splitLine: { lineStyle: { type: 'dashed', color: '#eee' } },
            axisLabel: { color: '#999', fontSize: 10 }
          },
          series: [
            {
              type: 'bar',
              data: [4.5, 6, 5, 4, 0, 0, 0, 0, 0, 0, 0],
              itemStyle: { color: '#FFC107', borderRadius: [2, 2, 0, 0] },
              barWidth: 6
            }
          ]
        }
        ''',
      ),
    );
  }

  Widget _buildDailyAnalysis() {
    return ListView(
      children: [
        // Sub tabs for Daily Analysis
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _dailySubTab = 'Energy';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _dailySubTab == 'Energy'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            border: _dailySubTab == 'Energy'
                                ? Border.all(color: primaryColor)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Energy',
                            style: TextStyle(
                              color: _dailySubTab == 'Energy'
                                  ? primaryColor
                                  : textLightColor,
                              fontWeight: _dailySubTab == 'Energy'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _dailySubTab = 'Power';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _dailySubTab == 'Power'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            border: _dailySubTab == 'Power'
                                ? Border.all(color: primaryColor)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Power',
                            style: TextStyle(
                              color: _dailySubTab == 'Power'
                                  ? primaryColor
                                  : textLightColor,
                              fontWeight: _dailySubTab == 'Power'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_dailySubTab == 'Energy') ...[
                // Energy Flow Tree
                const Text(
                  'Energy Flow',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEnergyFlowTree(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.home,
                                  color: Colors.blue[300],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Consumption',
                                  style: TextStyle(
                                    color: textLightColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '150.52',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' kWh',
                                    style: TextStyle(
                                      color: textLightColor,
                                      fontSize: 12,
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cost Savings',
                                  style: TextStyle(
                                    color: textLightColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '\$70.02',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Power Flow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Power Flow',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(kW)',
                              style: TextStyle(
                                fontSize: 12,
                                color: textLightColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solar+SunSaver+Grid power your site.',
                          style: TextStyle(fontSize: 12, color: textLightColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Echarts(
                    option: '''
                    {
                      grid: { left: '10%', right: '5%', top: '20%', bottom: '15%' },
                      legend: {
                        data: ['Solar', 'Grid', 'SunBox'],
                        icon: 'circle',
                        itemWidth: 8,
                        itemHeight: 8,
                        textStyle: { fontSize: 10, color: '#999' },
                        top: 0,
                        left: 0
                      },
                      xAxis: {
                        type: 'category',
                        data: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'],
                        axisLine: { show: false },
                        axisTick: { show: false },
                        axisLabel: { color: '#999', fontSize: 10 }
                      },
                      yAxis: {
                        type: 'value',
                        splitLine: { lineStyle: { type: 'dashed', color: '#eee' } },
                        axisLabel: { color: '#999', fontSize: 10 }
                      },
                      series: [
                        {
                          name: 'Solar',
                          type: 'line',
                          smooth: true,
                          data: [1.3, 1.2, 1.5, 1.6, 1.5, 1.8, 2.2],
                          itemStyle: { color: '#FFC107' },
                          showSymbol: false
                        },
                        {
                          name: 'Grid',
                          type: 'line',
                          smooth: true,
                          data: [1.6, 1.5, 1.8, 1.9, 1.8, 2.1, 2.5],
                          itemStyle: { color: '#3B82F6' },
                          showSymbol: false
                        },
                        {
                          name: 'SunBox',
                          type: 'line',
                          smooth: true,
                          data: [1.4, 1.3, 1.7, 1.8, 1.7, 2.0, 2.4],
                          itemStyle: { color: '#A855F7' },
                          showSymbol: false
                        }
                      ]
                    }
                    ''',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Second chart for Daily Analysis
        if (_dailySubTab == 'Energy') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Time Of Consumption',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(kWh)',
                      style: TextStyle(fontSize: 12, color: textLightColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Echarts(
                    option: '''
                    {
                      grid: { left: '10%', right: '5%', top: '20%', bottom: '15%' },
                      legend: {
                        data: ['Solar', 'Grid', 'SunBox'],
                        icon: 'circle',
                        itemWidth: 8,
                        itemHeight: 8,
                        textStyle: { fontSize: 10, color: '#999' },
                        top: 0,
                        left: 0
                      },
                      xAxis: {
                        type: 'category',
                        data: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'],
                        axisLine: { show: false },
                        axisTick: { show: false },
                        axisLabel: { color: '#999', fontSize: 10 }
                      },
                      yAxis: {
                        type: 'value',
                        splitLine: { lineStyle: { type: 'dashed', color: '#eee' } },
                        axisLabel: { color: '#999', fontSize: 10 }
                      },
                      series: [
                        {
                          name: 'Grid',
                          type: 'bar',
                          stack: 'total',
                          data: [4.5, 5.5, 4.8, 4.0, 0, 0, 0],
                          itemStyle: { color: '#3B82F6' },
                          barWidth: 8
                        },
                        {
                          name: 'SunBox',
                          type: 'bar',
                          stack: 'total',
                          data: [0, 0, 0, 1.0, 2.5, 2.0, 1.0],
                          itemStyle: { color: '#A855F7' },
                          barWidth: 8
                        },
                        {
                          name: 'Solar',
                          type: 'bar',
                          stack: 'total',
                          data: [0, 0, 0, 0, 3.0, 3.5, 3.0],
                          itemStyle: { color: '#FFC107' },
                          barWidth: 8
                        }
                      ]
                    }
                    ''',
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Grid Dependency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(%)',
                      style: TextStyle(fontSize: 12, color: textLightColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Lower Grid Dependency = Lower Electricity Costs.',
                  style: TextStyle(fontSize: 12, color: textLightColor),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Echarts(
                    option: '''
                    {
                      grid: { left: '10%', right: '5%', top: '10%', bottom: '15%' },
                      xAxis: {
                        type: 'category',
                        data: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'],
                        axisLine: { show: false },
                        axisTick: { show: false },
                        axisLabel: { color: '#999', fontSize: 10 }
                      },
                      yAxis: {
                        type: 'value',
                        max: 100,
                        splitLine: { lineStyle: { type: 'dashed', color: '#eee' } },
                        axisLabel: { color: '#999', fontSize: 10 }
                      },
                      series: [
                        {
                          type: 'line',
                          smooth: true,
                          data: [40, 38, 42, 41, 42, 41, 48, 49],
                          itemStyle: { color: '#24C18F' },
                          showSymbol: false
                        }
                      ]
                    }
                    ''',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEnergyFlowTree() {
    return Container(
      height: 210,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left: Site
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/siteicon.png', width: 80),
              const SizedBox(height: 8),
              const Text(
                'Site',
                style: TextStyle(color: textLightColor, fontSize: 14),
              ),
            ],
          ),

          // Middle: Connecting lines
          SizedBox(
            width: 66,
            height: 200,
            child: CustomPaint(painter: _EnergyFlowPainter()),
          ),

          // Right: Grid, SunBox, Solar
          SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnergyNode(
                  'Grid',
                  '0.0%',
                  '0.00kWh',
                  'assets/gridicon.png',
                ),
                const SizedBox(height: 10),
                _buildEnergyNode(
                  'SunBox',
                  '67.9%',
                  '13.64kWh',
                  'assets/sunboxicon.png',
                ),
                const SizedBox(height: 10),
                _buildEnergyNode(
                  'Solar',
                  '32.1%',
                  '6.46kWh',
                  'assets/solaricon.png',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyNode(
    String title,
    String percent,
    String value,
    String iconPath,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(iconPath, width: 48, height: 48),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: textLightColor, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              percent,
              style: const TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EnergyFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    double startX = 0;
    double startY = size.height / 2;
    double midX = size.width / 2;

    // The right column has 3 items, height 180.
    // So the centers are at roughly y=24, y=90, y=156
    double topY = 24;
    double bottomY = size.height - 24;

    // Line from Site to Middle
    path.moveTo(startX, startY);
    path.lineTo(midX, startY);

    // Vertical line
    path.moveTo(midX, topY);
    path.lineTo(midX, bottomY);

    // Horizontal lines to right nodes
    // Top
    path.moveTo(midX, topY);
    path.lineTo(size.width, topY);
    // Middle
    path.moveTo(midX, startY);
    path.lineTo(size.width, startY);
    // Bottom
    path.moveTo(midX, bottomY);
    path.lineTo(size.width, bottomY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
