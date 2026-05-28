import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import 'animated_flow_chart.dart';

class EnergyFlowOverlay extends StatelessWidget {
  const EnergyFlowOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final StationController controller = Get.find<StationController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double sx(double x) => x / kDesignWidth * width;
        double sy(double y) => y / kDesignHeight * height;

        return Obx(() {
          final data = controller.homeData.value;

          return SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: EnergyFlowPainter(width: width, height: height),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: sy(0),
                    left: sx(20),
                    child: Row(
                      children: [
                        Text(
                          '${data?.temperature ?? '--'}°C ',
                          style: TextStyle(
                            fontSize: sy(16),
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/${data?.icon ?? "100"}.svg',
                          width: 24,
                          height: 24,
                          // colorFilter: ColorFilter.mode(
                          //     Colors.yellow,
                          //     BlendMode.srcIn), // 可选：修改颜色
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: sy(20),
                    // left: sx(140),
                    right: sx(200),
                    child: Container(
                      padding: EdgeInsets.all(sy(8)),
                      child: Text(
                        'solar'.tr + '\n${data?.solar ?? '--'} kW',
                        style: TextStyle(fontSize: sy(14), color: textColor),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  Positioned(
                    top: sy(0),
                    right: sx(60),
                    child: Container(
                      padding: EdgeInsets.all(sy(8)),
                      child: Text(
                        'grid'.tr + '\n${data?.grid ?? '--'} kW',
                        style: TextStyle(fontSize: sy(14), color: textColor),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: sy(20),
                    right: sx(280),
                    child: Container(
                      padding: EdgeInsets.all(sy(8)),
                      child: Text(
                        'site_load'.tr + '\n${data?.site ?? '--'} kW',
                        style: TextStyle(fontSize: sy(14), color: textColor),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: sy(0),
                    left: sx(160),
                    child: Container(
                      padding: EdgeInsets.all(sy(8)),
                      child: Text(
                        'ev_charger'.tr + '\n-- kW',
                        style: TextStyle(fontSize: sy(14), color: textColor),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: sy(0),
                    right: sx(80),
                    child: Container(
                      padding: EdgeInsets.all(sy(8)),
                      child: Text(
                        'SunBox\n${data?.storage ?? '--'} kW',
                        style: TextStyle(fontSize: sy(14), color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class EnergyFlowPainter extends CustomPainter {
  final double width;
  final double height;

  EnergyFlowPainter({required this.width, required this.height});

  double sx(double x) => x / kDesignWidth * width;
  double sy(double y) => y / kDesignHeight * height;
  Offset so(double x, double y) => Offset(sx(x), sy(y));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = sy(1)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashWidth = 5.0;
    const dashSpace = 3.0;

    _drawDashedLine(
      canvas,
      paint,
      so(200, 30),
      so(200, 100),
      sx(dashWidth),
      sx(dashSpace),
    );

    _drawDashedLine(
      canvas,
      paint,
      so(340, 10),
      so(340, 60),
      sx(dashWidth),
      sx(dashSpace),
    );

    _drawDashedLine(
      canvas,
      paint,
      so(120, 240),
      so(120, 330),
      sx(dashWidth),
      sx(dashSpace),
    );

    _drawDashedLine(
      canvas,
      paint,
      so(160, 240),
      so(160, 320),
      sx(dashWidth),
      sx(dashSpace),
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end,
    double dashWidth,
    double dashSpace,
  ) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    double remainingDistance = distance;
    double currentDistance = 0;

    for (int i = 0; i < dashCount; i++) {
      final progress = currentDistance / distance;
      final x = start.dx + (end.dx - start.dx) * progress;
      final y = start.dy + (end.dy - start.dy) * progress;

      final nextProgress = (currentDistance + dashWidth) / distance;
      final nextX = start.dx + (end.dx - start.dx) * nextProgress;
      final nextY = start.dy + (end.dy - start.dy) * nextProgress;

      canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paint);

      currentDistance += dashWidth + dashSpace;
      remainingDistance -= dashWidth + dashSpace;
    }

    if (remainingDistance > 0) {
      final progress = currentDistance / distance;
      final x = start.dx + (end.dx - start.dx) * progress;
      final y = start.dy + (end.dy - start.dy) * progress;
      canvas.drawLine(Offset(x, y), end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EnergyFlowPainter oldDelegate) {
    return oldDelegate.width != width || oldDelegate.height != height;
  }
}
