import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_tab.dart';
import '../home/devices_tab.dart';
import '../home/assistant_tab.dart';
import '../home/me_tab.dart';
import '../../utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const DevicesTab(),
    const AssistantTab(),
    const MeTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
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
