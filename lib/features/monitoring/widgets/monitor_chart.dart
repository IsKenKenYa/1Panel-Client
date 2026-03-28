import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/repositories/monitor_repository.dart';

/// 监控折线图组件
///
/// 符合 MDUI3 规范，支持多维交互与参考系
class MonitorChart extends StatefulWidget {
  final List<MonitorDataPoint> data;
  final List<MonitorDataPoint>? previousData; // 上一周期同比数据
  final String unit;
  final Color? color;
  final double? minY;
  final double? maxY;
  final bool showReferenceLines;
  final String label;
  final bool useLogScale; // 是否使用对数刻度
  final VoidCallback? onLongPressStart; // 长按开始（冻结轮询）
  final VoidCallback? onLongPressEnd; // 长按结束（恢复轮询）

  const MonitorChart({
    super.key,
    required this.data,
    required this.label,
    this.previousData,
    this.unit = '',
    this.color,
    this.minY,
    this.maxY,
    this.showReferenceLines = true,
    this.useLogScale = false,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<MonitorChart> createState() => _MonitorChartState();
}

class _MonitorChartState extends State<MonitorChart>
    with SingleTickerProviderStateMixin {
  MonitorDataPoint? _selectedPoint;
  MonitorDataPoint? _selectedPrevPoint;
  Offset? _tapPosition;
  late AnimationController _tooltipController;

  // 缩放相关
  double _scale = 1.0;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _tooltipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _tooltipController.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) {
    _updateSelection(details.localPosition);
  }

  void _updateSelection(Offset localPosition) {
    if (widget.data.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final chartWidth = size.width - 50; // paddingLeft=40, paddingRight=10
    final x = localPosition.dx - 40;

    if (x < 0 || x > chartWidth) return;

    // 考虑缩放后的索引计算
    // 简单的线性映射：x / chartWidth 对应当前可视窗口的时间范围
    // 暂未实现复杂的视口滚动逻辑，仅做基础点选

    final index = (x / chartWidth * (widget.data.length - 1)).round();

    if (index >= 0 && index < widget.data.length) {
      setState(() {
        _selectedPoint = widget.data[index];
        if (widget.previousData != null &&
            index < widget.previousData!.length) {
          _selectedPrevPoint = widget.previousData![index];
        } else {
          _selectedPrevPoint = null;
        }
        _tapPosition = localPosition;
      });
      _tooltipController.forward();
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    _tapPosition = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // 处理缩放
    if (details.scale != 1.0) {
      setState(() {
        _scale = (_baseScale * details.scale).clamp(1.0, 5.0);
      });
    }
    // 处理拖动选择
    _updateSelection(details.localFocalPoint);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = widget.color ?? colorScheme.primary;

    // 计算均值
    double? meanValue;
    if (widget.data.isNotEmpty) {
      meanValue = widget.data.map((e) => e.value).reduce((a, b) => a + b) /
          widget.data.length;
    }

    return GestureDetector(
      onTapUp: _handleTapUp,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onLongPress: () {
        widget.onLongPressStart?.call();
        // 长按也触发选择
        if (_tapPosition != null) {
          _updateSelection(_tapPosition!);
        }
      },
      onLongPressEnd: (_) {
        widget.onLongPressEnd?.call();
      },
      onDoubleTap: () {
        setState(() {
          _scale = 1.0;
          _selectedPoint = null;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _MonitorChartPainter(
              data: widget.data,
              previousData: widget.previousData,
              unit: widget.unit,
              primaryColor: primaryColor,
              gridColor: colorScheme.outlineVariant,
              textColor: colorScheme.onSurfaceVariant,
              paddingLeft: 40,
              paddingRight: 10,
              paddingTop: 20,
              paddingBottom: 30,
              selectedPoint: _selectedPoint,
              meanValue: widget.showReferenceLines ? meanValue : null,
              scale: _scale,
              useLogScale: widget.useLogScale,
              referenceColor1: Colors.indigo.withValues(alpha: 0.4), // 同比
              referenceColor2: Colors.teal.withValues(alpha: 0.4), // 环比均值
            ),
          ),
          // Tooltip
          if (_selectedPoint != null && _tapPosition != null)
            Positioned(
              left: (_tapPosition!.dx - 70)
                  .clamp(0.0, MediaQuery.of(context).size.width - 150),
              top: _tapPosition!.dy - 80, // 上方显示
              child: FadeTransition(
                opacity: _tooltipController,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(12), // MDUI3 Card Radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4), // Elevation 2
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MM-dd HH:mm').format(_selectedPoint!.time),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: primaryColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(
                            '${_selectedPoint!.value.toStringAsFixed(1)}${widget.unit}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      if (_selectedPrevPoint != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: Colors.indigo.withValues(alpha: 0.4),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(
                              '同比: ${_selectedPrevPoint!.value.toStringAsFixed(1)}${widget.unit}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonitorChartPainter extends CustomPainter {
  final List<MonitorDataPoint> data;
  final List<MonitorDataPoint>? previousData;
  final String unit;
  final Color primaryColor;
  final Color gridColor;
  final Color textColor;
  final double paddingLeft;
  final double paddingRight;
  final double paddingTop;
  final double paddingBottom;
  final MonitorDataPoint? selectedPoint;
  final double? meanValue;
  final double scale;
  final bool useLogScale;
  final Color referenceColor1;
  final Color referenceColor2;

  _MonitorChartPainter({
    required this.data,
    this.previousData,
    required this.unit,
    required this.primaryColor,
    required this.gridColor,
    required this.textColor,
    required this.paddingLeft,
    required this.paddingRight,
    required this.paddingTop,
    required this.paddingBottom,
    this.selectedPoint,
    this.meanValue,
    this.scale = 1.0,
    this.useLogScale = false,
    required this.referenceColor1,
    required this.referenceColor2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // 1. Calculate min/max
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    // Include previous data in range calculation
    final allPoints = [...data, ...(previousData ?? [])];
    for (var p in allPoints) {
      if (p.value < minVal) minVal = p.value;
      if (p.value > maxVal) maxVal = p.value;
    }

    if (minVal == double.infinity) minVal = 0;
    if (maxVal == double.negativeInfinity) maxVal = 100;

    // Ensure zero baseline is visible
    if (minVal > 0) minVal = 0;
    if (minVal == maxVal) maxVal += 10;

    // Nice Numbers Scale
    final range = _calculateNiceRange(minVal, maxVal);
    minVal = range.min;
    maxVal = range.max;
    final interval = range.interval;

    // 2. Draw Grid & Axes
    _drawGridAndAxes(
        canvas, size, chartWidth, chartHeight, minVal, maxVal, interval);

    // 3. Draw Reference Lines (Layer 0)
    if (previousData != null && previousData!.isNotEmpty) {
      _drawLine(canvas, previousData!, chartWidth, chartHeight, minVal, maxVal,
          referenceColor1,
          isDashed: true);
    }

    if (meanValue != null) {
      final y =
          _normalizeY(meanValue!, minVal, maxVal, chartHeight) + paddingTop;
      final paint = Paint()
        ..color = referenceColor2
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      _drawDashedLine(canvas, Offset(paddingLeft, y),
          Offset(paddingLeft + chartWidth, y), paint, [4, 4]);
    }

    // 4. Draw Main Data Line (Layer 1)
    _drawDataLine(canvas, chartWidth, chartHeight, minVal, maxVal);

    // 5. Draw Selection (Layer 2)
    if (selectedPoint != null) {
      _drawSelection(canvas, chartWidth, chartHeight, minVal, maxVal);
    }
  }

  double _normalizeY(double value, double min, double max, double height) {
    if (useLogScale) {
      // Simple log scale implementation (log10)
      // Ensure values > 0
      final logMin = min <= 0 ? 0.0 : math.log(min);
      final logMax = math.log(max);
      final logVal = value <= 0 ? 0.0 : math.log(value);
      final range = logMax - logMin;
      if (range == 0) return height;
      return height - ((logVal - logMin) / range * height);
    } else {
      final range = max - min;
      if (range == 0) return height;
      return height - ((value - min) / range * height);
    }
  }

  void _drawGridAndAxes(Canvas canvas, Size size, double width, double height,
      double min, double max, double interval) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    // Y-axis
    for (double yVal = min; yVal <= max; yVal += interval) {
      final y = _normalizeY(yVal, min, max, height) + paddingTop;

      canvas.drawLine(Offset(paddingLeft, y),
          Offset(size.width - paddingRight, y), gridPaint);

      final label = '${yVal.toStringAsFixed(yVal % 1 == 0 ? 0 : 1)}$unit';
      textPainter.text = TextSpan(
          text: label, style: TextStyle(color: textColor, fontSize: 10));
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              paddingLeft - textPainter.width - 4, y - textPainter.height / 2));
    }

    // X-axis (Time)
    // Apply zoom: show subset of labels based on scale
    if (data.isNotEmpty) {
      // Visible range logic could be here, but for now we just skip points
      final step = (data.length / (5 * scale)).ceil().clamp(1, data.length);

      for (var i = 0; i < data.length; i += step) {
        final x = paddingLeft + (i / (data.length - 1)) * width;
        // Don't draw if out of bounds (though current scaling doesn't move x out of bounds, just sparsifies it)

        final time = data[i].time.toLocal();
        String timeLabel = DateFormat('HH:mm').format(time);
        if (i == 0 || data[i].time.day != data[i - 1].time.day) {
          timeLabel = DateFormat('MM-dd HH:mm').format(time);
        }

        textPainter.text = TextSpan(
            text: timeLabel, style: TextStyle(color: textColor, fontSize: 10));
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, paddingTop + height + 6));
      }
    }
  }

  void _drawLine(Canvas canvas, List<MonitorDataPoint> points, double width,
      double height, double min, double max, Color color,
      {bool isDashed = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    bool first = true;

    for (var i = 0; i < points.length; i++) {
      final x = paddingLeft + (i / (points.length - 1)) * width;
      final y = _normalizeY(points[i].value, min, max, height) + paddingTop;

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    if (isDashed) {
      _drawDashedPath(canvas, path, paint, [4, 2]);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawDataLine(
      Canvas canvas, double width, double height, double min, double max) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, paddingTop),
        Offset(0, paddingTop + height),
        [
          primaryColor.withValues(alpha: 0.3),
          primaryColor.withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    bool first = true;

    for (var i = 0; i < data.length; i++) {
      final x = paddingLeft + (i / (data.length - 1)) * width;
      final y = _normalizeY(data[i].value, min, max, height) + paddingTop;

      if (first) {
        path.moveTo(x, y);
        fillPath.moveTo(x, paddingTop + height);
        fillPath.lineTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(paddingLeft + width, paddingTop + height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  void _drawSelection(
      Canvas canvas, double width, double height, double min, double max) {
    if (selectedPoint == null) return;
    final index = data.indexOf(selectedPoint!);
    if (index == -1) return;

    final x = paddingLeft + (index / (data.length - 1)) * width;
    final y = _normalizeY(selectedPoint!.value, min, max, height) + paddingTop;

    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, Offset(x, paddingTop),
        Offset(x, paddingTop + height), linePaint, [4, 2]);
    _drawDashedLine(canvas, Offset(paddingLeft, y),
        Offset(paddingLeft + width, y), linePaint, [4, 2]);

    canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint,
      List<double> dashArray) {
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy);
    _drawDashedPath(canvas, path, paint, dashArray);
  }

  void _drawDashedPath(
      Canvas canvas, Path path, Paint paint, List<double> dashArray) {
    final Path dashedPath = Path();
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      int dashIndex = 0;
      while (distance < metric.length) {
        final double dashLength = dashArray[dashIndex % dashArray.length];
        if (dashIndex % 2 == 0) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + dashLength),
            Offset.zero,
          );
        }
        distance += dashLength;
        dashIndex++;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  _NiceRange _calculateNiceRange(double min, double max) {
    final range = max - min;
    if (range == 0) return _NiceRange(min, min + 10, 2);

    final targetInterval = range / 4;
    final magnitude =
        math.pow(10, (math.log(targetInterval) / math.ln10).floor()).toDouble();
    var interval = magnitude;

    final rel = targetInterval / magnitude;
    if (rel > 5) {
      interval = 10 * magnitude;
    } else if (rel > 2) {
      interval = 5 * magnitude;
    } else if (rel > 1) {
      interval = 2 * magnitude;
    }

    final newMin = (min / interval).floor() * interval;
    final newMax = (max / interval).ceil() * interval;

    return _NiceRange(newMin, newMax, interval);
  }

  @override
  bool shouldRepaint(covariant _MonitorChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.scale != scale ||
        oldDelegate.selectedPoint != selectedPoint;
  }
}

class _NiceRange {
  final double min;
  final double max;
  final double interval;
  _NiceRange(this.min, this.max, this.interval);
}
