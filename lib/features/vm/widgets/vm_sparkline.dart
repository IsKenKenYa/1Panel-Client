import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 轻量折线图：仅绘制当前采样窗口内的走势，不引入图表依赖。
///
/// 采样值按窗口内最大值归一化；没有采样时绘制中线占位。
class VmSparkline extends StatelessWidget {
  const VmSparkline({
    super.key,
    required this.samples,
    this.semanticLabel,
  });

  final List<double> samples;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      child: CustomPaint(
        painter: _SparklinePainter(
          samples: samples,
          color: scheme.primary,
          gridColor: scheme.outlineVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.samples,
    required this.color,
    required this.gridColor,
  });

  final List<double> samples;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    // 三条水平参考线：0%、50%、100%。
    for (var i = 0; i < 3; i++) {
      final dy = size.height * i / 2;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    if (samples.length < 2) {
      final midY = size.height / 2;
      canvas.drawLine(
        Offset(0, midY),
        Offset(size.width, midY),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
      return;
    }

    final maxValue = samples.reduce(math.max);
    final scaleMax = maxValue <= 0 ? 1.0 : maxValue;
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final dx = size.width * i / (samples.length - 1);
      final normalized = (samples[i] / scaleMax).clamp(0, 1).toDouble();
      final dy = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor;
  }
}
