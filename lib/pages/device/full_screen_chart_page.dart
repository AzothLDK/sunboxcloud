import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'dart:convert';
import 'package:get/get.dart';

class FullScreenChartPage extends StatefulWidget {
  final Map<String, dynamic> chartOption;
  final String title;

  const FullScreenChartPage({
    super.key,
    required this.chartOption,
    this.title = '',
  });

  @override
  State<FullScreenChartPage> createState() => _FullScreenChartPageState();
}

class _FullScreenChartPageState extends State<FullScreenChartPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RotatedBox(
          quarterTurns: 1, // 顺时针旋转 90 度
          child: Column(
            children: [
              // 自定义头部（旋转后的 AppBar）
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // 占位以平衡返回按钮
                  ],
                ),
              ),
              // 图表内容
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF24C18F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'charged'.tr,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'discharged'.tr,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Echarts(option: jsonEncode(widget.chartOption)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
