import 'package:flutter/material.dart';

const double kDesignWidth = 400.0;
const double kDesignHeight = 350.0;

class AnimatedFlowChart extends StatefulWidget {
  const AnimatedFlowChart({super.key});

  @override
  State<AnimatedFlowChart> createState() => _AnimatedFlowChartState();
}

class _AnimatedFlowChartState extends State<AnimatedFlowChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: FlowChartPainter(
                progress: _animationController.value,
                width: width,
                height: height,
              ),
            );
          },
        );
      },
    );
  }
}

class FlowChartPainter extends CustomPainter {
  final double progress;
  final double width;
  final double height;

  FlowChartPainter({
    required this.progress,
    required this.width,
    required this.height,
  });

  double sx(double x) => x / kDesignWidth * width;
  double sy(double y) => y / kDesignHeight * height;
  Offset so(double x, double y) => Offset(sx(x), sy(y));

  @override
  void paint(Canvas canvas, Size size) {
    _drawAnimatedFlowLine(
      canvas: canvas,
      nodes: [
        so(265, 250),
        so(265, 230),
        so(150, 208),
        so(150, 240),
        so(160, 240),
      ],
      thickness: sy(6),
      baseColor: Colors.blue.withOpacity(0.2),
      flowColor: Colors.lightBlueAccent,
    );

    _drawAnimatedFlowLine(
      canvas: canvas,
      nodes: [so(265, 250), so(265, 230), so(150, 208), so(150, 160)],
      thickness: sy(6),
      baseColor: Colors.blue.withOpacity(0.2),
      flowColor: Colors.lightBlueAccent,
    );

    _drawAnimatedFlowLine(
      canvas: canvas,
      nodes: [so(280, 140), so(280, 250)],
      thickness: sy(6),
      baseColor: Colors.blue.withOpacity(0.3),
      flowColor: Colors.lightBlueAccent,
    );

    _drawAnimatedFlowLine(
      canvas: canvas,
      nodes: [so(350, 150), so(350, 250), so(290, 285)],
      thickness: sy(6),
      baseColor: Colors.blue.withOpacity(0.3),
      flowColor: Colors.lightBlueAccent,
    );
  }

  void _drawNode(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    Color color,
  ) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(6),
      ),
      paint,
    );
  }

  void _drawAnimatedFlowLine({
    required Canvas canvas,
    required List<Offset> nodes,
    required double thickness,
    required Color baseColor,
    required Color flowColor,
  }) {
    if (nodes.length < 2) return;

    final path = Path();
    path.moveTo(nodes[0].dx, nodes[0].dy);

    for (int i = 1; i < nodes.length; i++) {
      path.lineTo(nodes[i].dx, nodes[i].dy);
    }

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, basePaint);

    final flowPaint = Paint()
      ..color = flowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.5
      ..strokeCap = StrokeCap.round;

    final totalLength = _getPathLength(path);
    final start = totalLength * progress;
    final end = start + totalLength * 0.2;

    for (double p = start; p < end; p += 1) {
      final pos = _getPathPosition(path, p / totalLength);
      if (pos != null) {
        canvas.drawCircle(pos, thickness * 0.25, flowPaint);
      }
    }
  }

  double _getPathLength(Path path) {
    final metrics = path.computeMetrics();
    double length = 0;
    for (var metric in metrics) {
      length += metric.length;
    }
    return length;
  }

  Offset? _getPathPosition(Path path, double t) {
    for (var metric in path.computeMetrics()) {
      return metric.getTangentForOffset(metric.length * t)?.position;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant FlowChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
  }
}
