import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'animated_flow_chart.dart';

class EnergyFlowOverlay extends StatelessWidget {
  const EnergyFlowOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double sx(double x) => x / kDesignWidth * width;
        double sy(double y) => y / kDesignHeight * height;

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
                  child: Text(
                    '23°C Cloudy',
                    style: TextStyle(
                      fontSize: sy(16),
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Positioned(
                  top: sy(20),
                  left: sx(140),
                  child: Container(
                    padding: EdgeInsets.all(sy(8)),
                    child: Text(
                      'Solar\n0.5 kW',
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
                      'Grid\n0.5 kW',
                      style: TextStyle(fontSize: sy(14), color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Positioned(
                  bottom: sy(20),
                  left: sx(20),
                  child: Container(
                    padding: EdgeInsets.all(sy(8)),
                    child: Text(
                      'House Load\n0.7 kW',
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
                      'EV Charger\n7 kW',
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
                      'SunBox\n0.5 kW',
                      style: TextStyle(fontSize: sy(14), color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
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
      so(170, 240),
      so(170, 320),
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
