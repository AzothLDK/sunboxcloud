import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunboxcloud/pages/device/deviceslist_tab.dart';
import 'package:sunboxcloud/pages/device/site_detail_tab.dart';
import '../home/home_tab.dart';
import '../device/devices_tab.dart';
import '../home/assistant_tab.dart';
import '../home/me_tab.dart';
import '../../utils/constants.dart';
import '../../controllers/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final Map<String, Widget> _pageMap = {
    'home_page': const HomeTab(),
    'device_page': const DevicesListTab(),
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
          return _buildDefaultPage();
        }

        List<Widget> dynamicPages = [];
        List<BottomNavigationBarItem> dynamicItems = [];

        for (var router in routers) {
          String name = router['name'] ?? '';
          String title = '';
          if (router['meta'] is Map<String, dynamic>) {
            title = router['meta']['title'] ?? '';
          }

          dynamicPages.add(_getPageByRouterName(name));
          dynamicItems.add(
            BottomNavigationBarItem(
              icon: Icon(_getIconByRouterName(name)),
              // label: title.isNotEmpty ? title : _getLabelByRouterName(name).tr,
              label: _getLabelByRouterName(name).tr,
            ),
          );
        }

        if (dynamicPages.isEmpty) {
          return _buildDefaultPage();
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

  Widget _buildDefaultPage() {
    final List<Widget> defaultTabs = [
      const HomeTab(),
      const DevicesTab(),
      const AssistantTab(),
      const MeTab(),
    ];

    return Scaffold(
      body: defaultTabs[_currentIndex],
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'home'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sensor_door),
            label: 'devices'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assistant),
            label: 'assistant'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'me'.tr,
          ),
        ],
      ),
    );
  }
}
