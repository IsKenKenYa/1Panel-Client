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
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.onErrorContainer.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  _channelLabel(context),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: colorScheme.onErrorContainer,
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
