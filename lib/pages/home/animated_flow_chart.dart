import 'package:flutter/material.dart';

// 带动画的能流图
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
    // 动画控制器：控制流动速度（值越大越快）
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: FlowChartPainter(
            progress: _animationController.value, // 流动进度
          ),
        );
      },
    );
  }
}

// 能流图画布（核心绘制 + 动画）
class FlowChartPainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0 动画进度

  FlowChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 画节点
    // _drawNode(canvas, 50, 100, 80, 50, Colors.blueAccent);
    // _drawNode(canvas, 50, 250, 80, 50, Colors.green);
    // _drawNode(canvas, 280, 80, 80, 40, Colors.orange);
    // _drawNode(canvas, 280, 160, 80, 40, Colors.purple);
    // _drawNode(canvas, 280, 260, 80, 40, Colors.red);

    //画带流动动画的能流线（方向、粗细、颜色可自定义）
    _drawAnimatedFlowLine(
      canvas: canvas,
      nodes: [
        Offset(265, 250),
        Offset(265, 230),
        Offset(150, 208),
        Offset(150, 240),
        Offset(160, 240),
      ],
      thickness: 6,
      baseColor: Colors.blue.withOpacity(0.2),
      flowColor: Colors.lightBlueAccent,
    );

    _drawAnimatedFlowLine(
      canvas: canvas,
      nodes: [
        Offset(265, 250),
        Offset(265, 230),
        Offset(150, 208),
        Offset(150, 160),
      ],
      thickness: 6,
      baseColor: Colors.blue.withOpacity(0.2),
      flowColor: Colors.lightBlueAccent,
    );

    _drawAnimatedFlowLine(
      canvas: canvas,
      nodes: [Offset(280, 140), Offset(280, 250)],
      thickness: 6,
      baseColor: Colors.blue.withOpacity(0.3),
      flowColor: Colors.lightBlueAccent,
    );

    _drawAnimatedFlowLine(
      canvas: canvas,
      nodes: [Offset(350, 150), Offset(350, 250), Offset(290, 285)],
      thickness: 6,
      baseColor: Colors.blue.withOpacity(0.3),
      flowColor: Colors.lightBlueAccent,
    );

    // 示例：多节点路径
    // _drawAnimatedFlowLine(
    //   canvas: canvas,
    //   nodes: [
    //     Offset(100, 100),
    //     Offset(200, 150),
    //     Offset(300, 100),
    //     Offset(250, 200),
    //   ],
    //   thickness: 8,
    //   baseColor: Colors.green.withOpacity(0.3),
    //   flowColor: Colors.lightGreenAccent,
    // );
  }

  // 绘制节点
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

  // 绘制：带动画流动效果的能流线
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

    // 连接所有节点
    for (int i = 1; i < nodes.length; i++) {
      path.lineTo(nodes[i].dx, nodes[i].dy);
    }

    // 底层底色
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, basePaint);

    // 流动光效（动画核心）
    final flowPaint = Paint()
      ..color = flowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.5
      ..strokeCap = StrokeCap.round;

    // 计算流动段路径
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

  // 工具：获取路径长度
  double _getPathLength(Path path) {
    final metrics = path.computeMetrics();
    double length = 0;
    for (var metric in metrics) {
      length += metric.length;
    }
    return length;
  }

  // 工具：获取路径上的点
  Offset? _getPathPosition(Path path, double t) {
    for (var metric in path.computeMetrics()) {
      return metric.getTangentForOffset(metric.length * t)?.position;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant FlowChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
