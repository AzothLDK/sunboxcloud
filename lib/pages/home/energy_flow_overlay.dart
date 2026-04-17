import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class EnergyFlowOverlay extends StatelessWidget {
  const EnergyFlowOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: EnergyFlowPainter(),
        child: Stack(
          children: [
            // 温度和天气
            Positioned(
              top: 0,
              left: 20,
              child: Text(
                '23°C Cloudy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            // Solar
            Positioned(
              top: 20,
              left: 140,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Solar\n0.5 kW',
                  style: TextStyle(fontSize: 14, color: textColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            // Grid
            Positioned(
              top: 0,
              right: 60,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Grid\n0.5 kW',
                  style: TextStyle(fontSize: 14, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // House Load
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'House Load\n0.7 kW',
                  style: TextStyle(fontSize: 14, color: textColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            // EV Charger
            Positioned(
              bottom: 0,
              left: 160,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'EV Charger\n7 kW',
                  style: TextStyle(fontSize: 14, color: textColor),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            // SunBox
            Positioned(
              bottom: 0,
              right: 80,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'SunBox\n0.5 kW',
                  style: TextStyle(fontSize: 14, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnergyFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制虚线
    const dashWidth = 5.0;
    const dashSpace = 3.0;

    // Solar 到 房子顶部
    _drawDashedLine(
      canvas,
      paint,
      size,
      Offset(200, 30),
      Offset(200, 100),
      dashWidth,
      dashSpace,
    );

    // Grid 到 房子右侧
    _drawDashedLine(
      canvas,
      paint,
      size,
      Offset(340, 10),
      Offset(340, 60),
      dashWidth,
      dashSpace,
    );

    //House Load 房子左侧
    _drawDashedLine(
      canvas,
      paint,
      size,
      Offset(120, 240),
      Offset(120, 330),
      dashWidth,
      dashSpace,
    );

    //EV Charger 房子左侧
    _drawDashedLine(
      canvas,
      paint,
      size,
      Offset(170, 240),
      Offset(170, 320),
      dashWidth,
      dashSpace,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Size size,
    Offset start,
    Offset end,
    double dashWidth,
    double dashSpace,
  ) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

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

    // 绘制最后一段
    if (remainingDistance > 0) {
      final progress = currentDistance / distance;
      final x = start.dx + (end.dx - start.dx) * progress;
      final y = start.dy + (end.dy - start.dy) * progress;
      canvas.drawLine(Offset(x, y), end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
