import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';

class BackupReservePage extends StatefulWidget {
  const BackupReservePage({super.key});

  @override
  State<BackupReservePage> createState() => _BackupReservePageState();
}

class _BackupReservePageState extends State<BackupReservePage> {
  double _progress = 0.2; // 初始值 20%

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Get.back();
          },
        ),
        title: Text(
          'Backup Reserve',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 卡片容器
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和描述
                      Row(
                        children: [
                          const Icon(
                            Icons.battery_charging_full,
                            color: primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Backup Reserve',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Reserve Energy for Grid Outages.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textLightColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // 直线进度条
                      Center(
                        child: Container(
                          width: 300,
                          child: Column(
                            children: [
                              // 进度条容器
                              Stack(
                                children: [
                                  // 背景线
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  // 进度线
                                  Container(
                                    height: 8,
                                    width: 300 * _progress,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  // 推荐线 (20%)
                                  Positioned(
                                    left: 300 * 0.2 - 1,
                                    top: -4,
                                    bottom: -4,
                                    child: Container(
                                      width: 2,
                                      color: primaryColor,
                                    ),
                                  ),
                                  // 拖动指示器
                                  Positioned(
                                    left: 300 * _progress - 8,
                                    top: -8,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        double newProgress =
                                            (details.localPosition.dx + 8) /
                                            300;
                                        newProgress = newProgress.clamp(
                                          0.0,
                                          1.0,
                                        );
                                        setState(() {
                                          _progress = newProgress;
                                        });
                                      },
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(
                                                0.3,
                                              ),
                                              spreadRadius: 2,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // 刻度线和标签
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int i = 0; i <= 5; i++)
                                    Column(
                                      children: [
                                        Container(
                                          width: 1,
                                          height: 8,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${i * 20}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textLightColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 推荐标签
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 60 - 25),
                                  child: Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              // 中心百分比
                              Text(
                                '${(_progress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
