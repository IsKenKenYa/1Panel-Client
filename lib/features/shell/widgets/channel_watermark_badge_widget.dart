import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/release_channel_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class ChannelWatermarkBadgeWidget extends StatelessWidget {
  const ChannelWatermarkBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppReleaseChannelConfig.shouldShowWatermark) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    // 左下角：避免遮挡 AppBar 右侧 actions 与右下角 FAB。
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 84),
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  // error 色随明暗主题切换：浅色下是警示红，深色下是亮粉，
                  // 低透明度叠加后两边都能保持可读对比。
                  color: colorScheme.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _channelLabel(context),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: colorScheme.error.withValues(alpha: 0.65),
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _channelLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (AppReleaseChannelConfig.current) {
      case AppReleaseChannel.preview:
        return l10n.releaseChannelPreview;
      case AppReleaseChannel.alpha:
        return l10n.releaseChannelAlpha;
      case AppReleaseChannel.beta:
        return l10n.releaseChannelBeta;
      case AppReleaseChannel.preRelease:
        return l10n.releaseChannelPreRelease;
      case AppReleaseChannel.release:
        return l10n.releaseChannelRelease;
    }
  }
}
