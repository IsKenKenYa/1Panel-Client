import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class CoachMarkStep {
  const CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
}

class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
  });

  final List<CoachMarkStep> steps;
  final VoidCallback onFinished;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_index];
    final rect = _getTargetRect(step.targetKey);
    final l10n = context.l10n;
    final isLast = _index == widget.steps.length - 1;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 蒙版在目标区域挖孔：用户视线直接落在目标控件上，
            // 而非隔着半透明灰色猜测要看什么。
            Positioned.fill(
              child: CustomPaint(
                painter: _CoachMarkMaskPainter(holeRect: rect),
              ),
            ),
            if (rect != null)
              Positioned(
                left: rect.left - 6,
                top: rect.top - 6,
                width: rect.width + 12,
                height: rect.height + 12,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const Key('coachmark-highlight'),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusMd),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            _buildBubble(context, rect, step, isLast, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    Rect? rect,
    CoachMarkStep step,
    bool isLast,
    dynamic l10n,
  ) {
    final size = MediaQuery.sizeOf(context);
    const estimatedBubbleHeight = 200.0;
    double top;
    if (rect == null) {
      top = size.height * 0.4;
    } else if (rect.bottom + 12 + estimatedBubbleHeight <= size.height - 24) {
      // 目标下方放得下：紧贴目标下方，视觉关联最强。
      top = rect.bottom + 12;
    } else if (rect.top - 12 - estimatedBubbleHeight >= 24) {
      // 下方放不下则放到目标上方。
      top = rect.top - 12 - estimatedBubbleHeight;
    } else {
      top = (size.height - estimatedBubbleHeight).clamp(24.0, size.height);
    }

    return Positioned(
      left: AppDesignTokens.spacingLg,
      right: AppDesignTokens.spacingLg,
      top: top.toDouble(),
      child: Card(
        child: Padding(
          padding: AppDesignTokens.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              Text(step.description),
              const SizedBox(height: AppDesignTokens.spacingLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onFinished,
                    child: Text(l10n.onboardingSkip),
                  ),
                  const SizedBox(width: AppDesignTokens.spacingSm),
                  FilledButton(
                    onPressed: () {
                      if (isLast) {
                        widget.onFinished();
                        return;
                      }

                      setState(() {
                        _index += 1;
                      });
                    },
                    child: Text(isLast ? l10n.coachDone : l10n.onboardingNext),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Rect? _getTargetRect(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return null;
    }

    final overlayRender = context.findAncestorRenderObjectOfType<RenderBox>();
    final targetRender = targetContext.findRenderObject();
    if (overlayRender is! RenderBox ||
        targetRender is! RenderBox ||
        !overlayRender.hasSize ||
        !targetRender.hasSize) {
      return null;
    }

    final globalOffset = targetRender.localToGlobal(Offset.zero);
    final offset = overlayRender.globalToLocal(
      globalOffset,
    );
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      targetRender.size.width,
      targetRender.size.height,
    );
  }
}

/// 全屏半透明蒙版，目标区域按 even-odd 规则挖孔透出真实控件。
class _CoachMarkMaskPainter extends CustomPainter {
  _CoachMarkMaskPainter({required this.holeRect});

  final Rect? holeRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    if (holeRect == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    final hole = RRect.fromRectAndRadius(
      holeRect!.inflate(6),
      const Radius.circular(AppDesignTokens.radiusMd),
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CoachMarkMaskPainter oldDelegate) =>
      oldDelegate.holeRect != holeRect;
}
