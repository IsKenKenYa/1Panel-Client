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
        color: Colors.black54,
        child: Stack(
          children: [
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
    final top = rect == null
        ? size.height * 0.4
        : (rect.bottom + 12).clamp(24, size.height - 220);

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
