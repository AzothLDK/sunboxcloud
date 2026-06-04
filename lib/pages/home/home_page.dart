import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunboxcloud/pages/device/device_list_page.dart';
import 'package:sunboxcloud/pages/device/site_detail_tab.dart';
import 'home_tab.dart';
import 'assistant_tab.dart';
import 'me_tab.dart';
import '../../utils/constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/station_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  Timer? _refreshTimer;
  final StationController _stationController = Get.find<StationController>();

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_stationController.selectedStationId.value.isNotEmpty) {
        _stationController.fetchHomeData(
          _stationController.selectedStationId.value,
          showLoading: false,
        );
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  final Map<String, Widget> _pageMap = {
    'home_page': const HomeTab(),
    'device_page': const DeviceListPage(),
    'site_page': const SiteDetailTab(),
    'assistance_page': const AssistantTab(),
    'me_page': const MeTab(),
  };

  final Map<String, IconData> _iconMap = {
    'home_page': Icons.home,
    'device_page': Icons.sensor_door,
    'site_page': Icons.home_work,
    'assistance_page': Icons.assistant,
    'me_page': Icons.person,
  };

  final Map<String, String> _labelMap = {
    'home_page': 'home',
    'device_page': 'devices',
    'assistance_page': 'assistant',
    'me_page': 'me',
    'site_page': 'site',
  };

  Widget _getPageByRouterName(String name) {
    return _pageMap[name] ?? const HomeTab();
  }

  IconData _getIconByRouterName(String name) {
    return _iconMap[name] ?? Icons.home;
  }

  String _getLabelByRouterName(String name) {
    return _labelMap[name] ?? 'home';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final routers = authController.routers;

        if (routers.isEmpty) {
          // 如果 routers 为空，说明还在加载中或者加载失败
          // 我们这里可以给个默认的占位页面或者等待
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: const CircularProgressIndicator()),
          );
        }
        List<Widget> dynamicPages = [];
        List<BottomNavigationBarItem> dynamicItems = [];

        for (var router in routers) {
          String name = router['name'] ?? '';
          dynamicPages.add(_getPageByRouterName(name));
          dynamicItems.add(
            BottomNavigationBarItem(
              icon: Icon(_getIconByRouterName(name)),
              label: _getLabelByRouterName(name).tr,
            ),
          );
        }

        if (dynamicPages.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_currentIndex >= dynamicPages.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: dynamicPages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: primaryColor,
            unselectedItemColor: textLightColor,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: dynamicItems,
          ),
        );
      },
    );
  }
}
