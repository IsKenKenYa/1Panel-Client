import 'package:flutter/foundation.dart';

enum AppReleaseChannel {
  preview,
  alpha,
  beta,
  preRelease,
  release,
}

class AppReleaseChannelConfig {
  AppReleaseChannelConfig._();

  static const String _channelFromEnv =
      String.fromEnvironment('APP_CHANNEL', defaultValue: '');
  static const String _branchFromEnv =
      String.fromEnvironment('APP_GIT_BRANCH', defaultValue: '');

  static final AppReleaseChannel current = _resolveChannel();

  static bool get isPreviewFamily => current != AppReleaseChannel.release;

  static bool get shouldShowColdStartWarning => isPreviewFamily;

  static bool get shouldRequireConsent => isPreviewFamily;

  static bool get shouldShowWatermark => isPreviewFamily;

  static bool get forceDebugLogLevel =>
      current == AppReleaseChannel.preview ||
      current == AppReleaseChannel.alpha;

  static bool get allowLogLevelSelection => !forceDebugLogLevel;

  static String get channelStorageValue => switch (current) {
        AppReleaseChannel.preview => 'preview',
        AppReleaseChannel.alpha => 'alpha',
        AppReleaseChannel.beta => 'beta',
        AppReleaseChannel.preRelease => 'pre-release',
        AppReleaseChannel.release => 'release',
      };

  static String get branchName => _branchFromEnv;

  static AppReleaseChannel _resolveChannel() {
    final fromChannel = _parseChannel(_channelFromEnv);
    if (fromChannel != null) {
      return fromChannel;
    }

    final fromBranch = _parseChannelFromBranch(_branchFromEnv);
    if (fromBranch != null) {
      return fromBranch;
    }

    return kReleaseMode ? AppReleaseChannel.release : AppReleaseChannel.alpha;
  }

  static AppReleaseChannel? _parseChannel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    switch (normalized) {
      case 'preview':
      case 'early':
      case 'canary':
        return AppReleaseChannel.preview;
      case 'alpha':
      case 'dev':
        return AppReleaseChannel.alpha;
      case 'beta':
        return AppReleaseChannel.beta;
      case 'pre-release':
      case 'prerelease':
      case 'pre_release':
      case 'pre':
      case 'rc':
        return AppReleaseChannel.preRelease;
      case 'release':
      case 'stable':
      case 'prod':
      case 'production':
        return AppReleaseChannel.release;
      default:
        return null;
    }
  }

  static AppReleaseChannel? _parseChannelFromBranch(String branch) {
    var normalized = branch.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.startsWith('refs/heads/')) {
      normalized = normalized.substring('refs/heads/'.length);
    }

    if (normalized == 'main' || normalized == 'master') {
      return AppReleaseChannel.release;
    }

    if (normalized.startsWith('release/')) {
      return AppReleaseChannel.release;
    }

    if (normalized.startsWith('prerelease/') ||
        normalized.startsWith('pre-release/') ||
        normalized.startsWith('pre/')) {
      return AppReleaseChannel.preRelease;
    }

    if (normalized.startsWith('beta/')) {
      return AppReleaseChannel.beta;
    }

    if (normalized.startsWith('alpha/') || normalized.startsWith('dev/')) {
      return AppReleaseChannel.alpha;
    }

    if (normalized.startsWith('preview/')) {
      return AppReleaseChannel.preview;
    }

    return null;
  }
}
