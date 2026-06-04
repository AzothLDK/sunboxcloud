import 'dart:math';
import 'package:flutter/material.dart';

class SankeyNode {
  final String name;
  final Color color;
  final int depth;
  double value;

  double x = 0;
  double y = 0;
  double height = 0;

  SankeyNode({
    required this.name,
    required this.color,
    required this.depth,
    this.value = 0,
  });
}

class SankeyLink {
  final String sourceName;
  final String targetName;
  double value;

  SankeyLink({
    required this.sourceName,
    required this.targetName,
    this.value = 0,
  });
}

class _LinkGeometry {
  final Path path;
  final SankeyLink link;
  final Color sourceColor;
  final Color targetColor;

  _LinkGeometry({
    required this.path,
    required this.link,
    required this.sourceColor,
    required this.targetColor,
  });
}

class _NodeGeometry {
  final Rect rect;
  final SankeyNode node;

  _NodeGeometry({required this.rect, required this.node});
}

class CustomSankeyChart extends StatefulWidget {
  final List<SankeyNode> nodes;
  final List<SankeyLink> links;
  final double nodeWidth;
  final double nodeGap;
  final double minHeight;
  final double borderRadius;

  const CustomSankeyChart({
    Key? key,
    required this.nodes,
    required this.links,
    this.nodeWidth = 45,
    this.nodeGap = 10,
    this.minHeight = 30,
    this.borderRadius = 6,
  }) : super(key: key);

  @override
  State<CustomSankeyChart> createState() => CustomSankeyChartState();
}

class CustomSankeyChartState extends State<CustomSankeyChart> {
  List<_LinkGeometry> _linkGeometries = [];
  List<_NodeGeometry> _nodeGeometries = [];

  SankeyNode? _selectedNode;
  Offset? _tooltipPosition;
  List<SankeyLink>? _selectedLinks;
  double? _totalValue;

  void _onTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    for (var nodeGeo in _nodeGeometries) {
      if (nodeGeo.rect.contains(localPosition)) {
        if (_selectedNode?.name == nodeGeo.node.name) {
          setState(() {
            _selectedNode = null;
            _selectedLinks = null;
            _totalValue = null;
            _tooltipPosition = null;
          });
        } else {
          setState(() {
            _selectedNode = nodeGeo.node;
            _selectedLinks = _getRelatedLinks(nodeGeo.node);
            _totalValue = _getNodeTotalValue(nodeGeo.node);
            _tooltipPosition = localPosition;
          });
        }
        return;
      }
    }

    for (var geo in _linkGeometries) {
      if (geo.path.contains(localPosition)) {
        setState(() {
          _selectedNode = null;
          _selectedLinks = [geo.link];
          _totalValue = geo.link.value;
          _tooltipPosition = localPosition;
        });
        return;
      }
    }

    setState(() {
      _selectedNode = null;
      _selectedLinks = null;
      _totalValue = null;
      _tooltipPosition = null;
    });
  }

  List<SankeyLink> _getRelatedLinks(SankeyNode node) {
    if (node.depth == 0) {
      return widget.links.where((l) => l.sourceName == node.name).toList();
    } else {
      return widget.links.where((l) => l.targetName == node.name).toList();
    }
  }

  double _getNodeTotalValue(SankeyNode node) {
    double total = 0;
    for (var link in widget.links) {
      if (node.depth == 0 && link.sourceName == node.name) {
        total += link.value;
      } else if (node.depth != 0 && link.targetName == node.name) {
        total += link.value;
      }
    }
    return total;
  }

  void _dismissTooltip() {
    setState(() {
      _selectedNode = null;
      _selectedLinks = null;
      _totalValue = null;
      _tooltipPosition = null;
    });
  }

  void resetSelection() {
    setState(() {
      _selectedNode = null;
      _selectedLinks = null;
      _totalValue = null;
      _tooltipPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> linkPercentages = {};
    if (_selectedNode != null &&
        _selectedLinks != null &&
        _totalValue != null) {
      for (var link in _selectedLinks!) {
        String key = '${link.sourceName}|${link.targetName}';
        double percent =
            _totalValue! > 0 ? (link.value / _totalValue! * 100) : 0;
        linkPercentages[key] = percent;
      }
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) {},
      onPanStart: (_) => _dismissTooltip(),
      child: Stack(
        children: [
          CustomPaint(
            painter: _SankeyPainter(
              nodes: widget.nodes,
              links: widget.links,
              nodeWidth: widget.nodeWidth,
              nodeGap: widget.nodeGap,
              minHeight: widget.minHeight,
              borderRadius: widget.borderRadius,
              selectedNode: _selectedNode,
              selectedLinks: _selectedLinks
                  ?.map((l) => '${l.sourceName}|${l.targetName}')
                  .toSet(),
              linkPercentages: linkPercentages,
              onGeometriesComputed: (links, nodes) {
                _linkGeometries = links;
                _nodeGeometries = nodes;
              },
            ),
            size: Size.infinite,
          ),
          if (_selectedLinks != null &&
              _selectedLinks!.length == 1 &&
              _tooltipPosition != null &&
              _selectedNode == null)
            _buildLinkTooltip(context),
        ],
      ),
    );
  }

  Widget _buildLinkTooltip(BuildContext context) {
    final link = _selectedLinks!.first;
    final pos = _tooltipPosition!;

    String sourceLabel = link.sourceName.replaceAll('\n', ' ');
    String targetLabel = link.targetName.replaceAll('\n', ' ');

    const double tooltipWidth = 180;
    const double tooltipHeight = 90;
    const double tooltipMargin = 8;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final double containerWidth = box.size.width;
    final double containerHeight = box.size.height;

    double tooltipLeft = pos.dx - tooltipWidth / 2;
    double tooltipTop = pos.dy - tooltipHeight - tooltipMargin;

    if (tooltipLeft < tooltipMargin) {
      tooltipLeft = tooltipMargin;
    }
    if (tooltipLeft + tooltipWidth > containerWidth - tooltipMargin) {
      tooltipLeft = containerWidth - tooltipWidth - tooltipMargin;
    }
    if (tooltipTop < tooltipMargin) {
      tooltipTop = pos.dy + tooltipMargin;
    }
    if (tooltipTop + tooltipHeight > containerHeight - tooltipMargin) {
      tooltipTop = containerHeight - tooltipHeight - tooltipMargin;
    }

    Color sourceColor = _getSourceColor(link.sourceName);
    Color targetColor = _getTargetColor(link.targetName);

    Widget tooltipContent = Container(
      constraints: BoxConstraints(maxWidth: tooltipWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A202C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: sourceColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  sourceLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_downward,
                        size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      link.value.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: targetColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  targetLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Positioned(
      left: tooltipLeft,
      top: tooltipTop,
      child: Material(
        color: Colors.transparent,
        child: tooltipContent,
      ),
    );
  }

  Color _getSourceColor(String name) {
    for (var n in widget.nodes) {
      if (n.name == name) return n.color;
    }
    return Colors.grey;
  }

  Color _getTargetColor(String name) {
    for (var n in widget.nodes) {
      if (n.name == name) return n.color;
    }
    return Colors.grey;
  }
}

class _SankeyPainter extends CustomPainter {
  final List<SankeyNode> nodes;
  final List<SankeyLink> links;
  final double nodeWidth;
  final double nodeGap;
  final double minHeight;
  final double borderRadius;
  final SankeyNode? selectedNode;
  final Set<String>? selectedLinks;
  final Map<String, double> linkPercentages;
  final void Function(List<_LinkGeometry>, List<_NodeGeometry>)
      onGeometriesComputed;

  _SankeyPainter({
    required this.nodes,
    required this.links,
    required this.nodeWidth,
    required this.nodeGap,
    required this.minHeight,
    required this.borderRadius,
    this.selectedNode,
    this.selectedLinks,
    this.linkPercentages = const {},
    required this.onGeometriesComputed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final double chartWidth = size.width;
    final double chartHeight = size.height;

    final leftNodes = nodes.where((n) => n.depth == 0).toList();
    final rightNodes = nodes.where((n) => n.depth == 1).toList();

    _layoutNodes(leftNodes, rightNodes, chartWidth, chartHeight);

    final nodeGeos = _buildNodeGeometries();
    final geometries = _buildLinkGeometries(chartWidth);
    onGeometriesComputed(geometries, nodeGeos);

    for (var geo in geometries) {
      _drawLinkPath(canvas, geo);
    }

    _drawNodes(canvas, nodeGeos);
  }

  List<_NodeGeometry> _buildNodeGeometries() {
    return nodes
        .map((node) => _NodeGeometry(
              rect: Rect.fromLTWH(node.x, node.y, nodeWidth, node.height),
              node: node,
            ))
        .toList();
  }

  void _layoutNodes(
    List<SankeyNode> leftNodes,
    List<SankeyNode> rightNodes,
    double chartWidth,
    double chartHeight,
  ) {
    double leftTotalValue = 0;
    for (var node in leftNodes) {
      double outValue = _getOutValue(node.name);
      node.value = max(outValue, 0);
      leftTotalValue += node.value;
    }

    double rightTotalValue = 0;
    for (var node in rightNodes) {
      double inValue = _getInValue(node.name);
      node.value = max(inValue, 0);
      rightTotalValue += node.value;
    }

    _positionNodes(leftNodes, 0, chartHeight, leftTotalValue);
    _positionNodes(
        rightNodes, chartWidth - nodeWidth, chartHeight, rightTotalValue);
  }

  void _positionNodes(
    List<SankeyNode> nodeList,
    double xPos,
    double chartHeight,
    double totalValue,
  ) {
    if (nodeList.isEmpty) return;

    double totalMinHeight =
        minHeight * nodeList.length + nodeGap * (nodeList.length - 1);
    double availableForValue = chartHeight - totalMinHeight;
    if (availableForValue < 0) availableForValue = 0;

    double valueScale = totalValue > 0 ? availableForValue / totalValue : 0;

    double currentY = 0;
    for (int i = 0; i < nodeList.length; i++) {
      final node = nodeList[i];
      double nodeHeight = minHeight + node.value * valueScale;

      node.x = xPos;
      node.y = currentY;
      node.height = nodeHeight;

      currentY += nodeHeight;
      if (i < nodeList.length - 1) {
        currentY += nodeGap;
      }
    }

    double usedHeight = currentY;
    double offsetY = (chartHeight - usedHeight) / 2;
    if (offsetY > 0) {
      for (var node in nodeList) {
        node.y += offsetY;
      }
    }
  }

  double _getOutValue(String nodeName) {
    double total = 0;
    for (var link in links) {
      if (link.sourceName == nodeName) {
        total += link.value;
      }
    }
    return total;
  }

  double _getInValue(String nodeName) {
    double total = 0;
    for (var link in links) {
      if (link.targetName == nodeName) {
        total += link.value;
      }
    }
    return total;
  }

  void _drawNodes(Canvas canvas, List<_NodeGeometry> nodeGeometries) {
    double leftTotal = 0;
    double rightTotal = 0;

    for (var node in nodes) {
      if (node.depth == 0) {
        leftTotal += _getOutValue(node.name);
      } else {
        rightTotal += _getInValue(node.name);
      }
    }

    for (var nodeGeo in nodeGeometries) {
      final node = nodeGeo.node;
      bool isSelected = selectedNode?.name == node.name;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(node.x, node.y, nodeWidth, node.height),
        Radius.circular(borderRadius),
      );

      if (isSelected) {
        final glowPaint = Paint()
          ..color = node.color.withOpacity(0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawRRect(rect, glowPaint);
      }

      final paint = Paint()
        ..color = isSelected
            ? node.color
            : node.color.withOpacity(isSelected ? 1 : 0.85)
        ..style = PaintingStyle.fill;

      if (isSelected) {
        paint.strokeWidth = 2.5;
        paint.style = PaintingStyle.stroke;
        canvas.drawRRect(rect, paint);
        paint.style = PaintingStyle.fill;
      }

      canvas.drawRRect(rect, paint);

      double nodeValue =
          node.depth == 0 ? _getOutValue(node.name) : _getInValue(node.name);

      double sideTotal = node.depth == 0 ? leftTotal : rightTotal;
      double percentage = sideTotal > 0 ? (nodeValue / sideTotal * 100) : 0;

      final nameSpan = TextSpan(
        text: node.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.bold,
        ),
      );

      final namePainter = TextPainter(
        text: nameSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      namePainter.layout(maxWidth: nodeWidth - 10);

      double availableHeight = node.height;
      bool showPercentage = percentage >= 2.0;

      if (showPercentage) {
        final percentText = '${percentage.toStringAsFixed(1)}%';

        final percentSpan = TextSpan(
          text: percentText,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        );

        final percentPainter = TextPainter(
          text: percentSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        percentPainter.layout();

        double totalTextHeight = namePainter.height + percentPainter.height + 4;
        double nameY;

        if (availableHeight > totalTextHeight + 6) {
          nameY = node.y + (availableHeight - totalTextHeight) / 2;
        } else {
          nameY = node.y + 3;
        }

        namePainter.paint(canvas, Offset(node.x + 5, nameY));
        percentPainter.paint(
            canvas,
            Offset(node.x + (nodeWidth - percentPainter.width) / 2,
                node.y + node.height - percentPainter.height - 3));
      } else {
        double textY = node.y + 5;
        if (node.height > namePainter.height + 10) {
          textY = node.y + (node.height - namePainter.height) / 2;
        }
        namePainter.paint(canvas, Offset(node.x + 5, textY));
      }
    }
  }

  List<_LinkGeometry> _buildLinkGeometries(double chartWidth) {
    final nodeMap = <String, SankeyNode>{};
    for (var node in nodes) {
      nodeMap[node.name] = node;
    }

    final sourceOffsets = <String, double>{};
    final targetOffsets = <String, double>{};
    final geometries = <_LinkGeometry>[];

    for (var link in links) {
      final sourceNode = nodeMap[link.sourceName];
      final targetNode = nodeMap[link.targetName];
      if (sourceNode == null || targetNode == null) continue;
      if (link.value <= 0) continue;

      double sourceTotalValue = _getOutValue(sourceNode.name);
      double targetTotalValue = _getInValue(targetNode.name);

      double sourceLinkHeight;
      if (sourceTotalValue > 0) {
        sourceLinkHeight = (link.value / sourceTotalValue) * sourceNode.height;
      } else {
        int outCount = links
            .where((l) => l.sourceName == sourceNode.name && l.value > 0)
            .length;
        sourceLinkHeight =
            outCount > 0 ? sourceNode.height / outCount : minHeight;
      }

      double targetLinkHeight;
      if (targetTotalValue > 0) {
        targetLinkHeight = (link.value / targetTotalValue) * targetNode.height;
      } else {
        int inCount = links
            .where((l) => l.targetName == targetNode.name && l.value > 0)
            .length;
        targetLinkHeight =
            inCount > 0 ? targetNode.height / inCount : minHeight;
      }

      double sourceOffset = sourceOffsets[link.sourceName] ?? 0;
      double targetOffset = targetOffsets[link.targetName] ?? 0;

      double sourceY = sourceNode.y + sourceOffset;
      double targetY = targetNode.y + targetOffset;

      double sourceX = sourceNode.x + nodeWidth;
      double targetX = targetNode.x;

      final path = _buildCurvedPath(
        sourceX,
        sourceY,
        targetX,
        targetY,
        sourceLinkHeight,
        targetLinkHeight,
      );

      geometries.add(_LinkGeometry(
        path: path,
        link: link,
        sourceColor: sourceNode.color,
        targetColor: targetNode.color,
      ));

      sourceOffsets[link.sourceName] = sourceOffset + sourceLinkHeight;
      targetOffsets[link.targetName] = targetOffset + targetLinkHeight;
    }

    return geometries;
  }

  Path _buildCurvedPath(
    double x1,
    double y1,
    double x2,
    double y2,
    double sourceLinkHeight,
    double targetLinkHeight,
  ) {
    final path = Path();
    path.moveTo(x1, y1);
    path.cubicTo(
      x1 + (x2 - x1) / 2,
      y1,
      x2 - (x2 - x1) / 2,
      y2,
      x2,
      y2,
    );
    path.lineTo(x2, y2 + targetLinkHeight);
    path.cubicTo(
      x2 - (x2 - x1) / 2,
      y2 + targetLinkHeight,
      x1 + (x2 - x1) / 2,
      y1 + sourceLinkHeight,
      x1,
      y1 + sourceLinkHeight,
    );
    path.close();
    return path;
  }

  void _drawLinkPath(Canvas canvas, _LinkGeometry geo) {
    String linkKey = '${geo.link.sourceName}|${geo.link.targetName}';
    bool isSelected = selectedLinks?.contains(linkKey) ?? false;
    bool hasSelection = selectedLinks != null && selectedLinks!.isNotEmpty;
    bool showPercentage = linkPercentages.containsKey(linkKey);

    final pathBounds = geo.path.getBounds();

    if (!hasSelection || isSelected) {
      double opacity = (isSelected || showPercentage) ? 0.7 : 0.35;

      final shader = LinearGradient(
        colors: [
          geo.sourceColor.withOpacity(opacity),
          geo.targetColor.withOpacity(opacity),
        ],
      ).createShader(pathBounds);

      final paint = Paint()
        ..shader = shader
        ..style = PaintingStyle.fill
        ..maskFilter = (isSelected || showPercentage)
            ? const MaskFilter.blur(BlurStyle.normal, 2)
            : null;

      canvas.drawPath(geo.path, paint);

      if (isSelected || showPercentage) {
        final strokePaint = Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawPath(geo.path, strokePaint);
      }

      if (showPercentage && linkPercentages[linkKey] != null) {
        _drawPercentageOnLink(canvas, pathBounds, linkPercentages[linkKey]!);
      }
    } else {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.08)
        ..style = PaintingStyle.fill;
      canvas.drawPath(geo.path, paint);
    }
  }

  void _drawPercentageOnLink(Canvas canvas, Rect bounds, double percentage) {
    double centerX = bounds.left + bounds.width / 2;
    double centerY = bounds.top + bounds.height / 2;

    String text = '${percentage.toStringAsFixed(1)}%';

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 4,
            color: Colors.black54,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    double textX = centerX - textPainter.width / 2;
    double textY = centerY - textPainter.height / 2;

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      ),
      Radius.circular(8),
    );

    canvas.drawRRect(bgRect, bgPaint);
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant _SankeyPainter oldDelegate) {
    return true;
  }
}
