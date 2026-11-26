import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/build_metadata_config.dart';
import '../config/release_channel_config.dart';
import '../services/app_preferences_service.dart';

class NativeChannelHarmonyLegal {
  static const _officialDomainName = 'onepanel.iskenkenya.com';
  static const _officialDomainUrl = 'https://$_officialDomainName';
  static const _repoSsh = 'git@github.com:IsKenKenYa/1Panel-Client.git';
  static const _repoHttps = 'https://github.com/IsKenKenYa/1Panel-Client.git';
  static const _issuesUrl =
      'https://github.com/IsKenKenYa/1Panel-Client/issues';
  static const _releasesUrl =
      'https://github.com/IsKenKenYa/1Panel-Client/releases';
  static const _legalRoot =
      'https://github.com/IsKenKenYa/1Panel-Client/blob/main';

  static Future<List<LicenseEntry>>? _licenses;

  static Future<Map<String, String>> getHarmonyAboutInfo(
    dynamic arguments,
  ) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final channelKey = switch (AppReleaseChannelConfig.current) {
      AppReleaseChannel.preview => 'releaseChannelPreview',
      AppReleaseChannel.alpha => 'releaseChannelAlpha',
      AppReleaseChannel.beta => 'releaseChannelBeta',
      AppReleaseChannel.preRelease => 'releaseChannelPreRelease',
      AppReleaseChannel.release => 'releaseChannelRelease',
    };
    return {
      'appName': packageInfo.appName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'packageName': packageInfo.packageName,
      'channelKey': channelKey,
      'branch': AppReleaseChannelConfig.branchName,
      'commit': BuildMetadataConfig.gitCommit,
      'shortCommit': BuildMetadataConfig.shortCommit,
      'buildDate': BuildMetadataConfig.buildDate,
      'officialDomainName': _officialDomainName,
      'officialDomainUrl': _officialDomainUrl,
      'repoSsh': _repoSsh,
      'repoHttps': _repoHttps,
      'issuesUrl': _issuesUrl,
      'releasesUrl': _releasesUrl,
    };
  }

  static Future<List<Map<String, String>>> getHarmonyLegalDocuments(
    dynamic arguments,
  ) async {
    final locale = await AppPreferencesService().loadLocale();
    final isChinese = locale == null
        ? Platform.localeName.startsWith('zh')
        : locale.languageCode == 'zh';
    return [
      {
        'id': 'privacy',
        'titleKey': 'settingsLegalPrivacyPolicy',
        'url': isChinese
            ? '$_legalRoot/docs/PRIVACY_POLICY.zh-CN.md'
            : '$_legalRoot/docs/PRIVACY_POLICY.md',
      },
      {
        'id': 'terms',
        'titleKey': 'settingsLegalTermsOfService',
        'url': '$_legalRoot/docs/TERMS_OF_SERVICE.md',
      },
      {
        'id': 'notices',
        'titleKey': 'settingsLegalThirdPartyNotices',
        'url': '$_legalRoot/THIRD_PARTY_LICENSES.md',
      },
      {
        'id': 'license',
        'titleKey': 'settingsLegalOpenSourceLicense',
        'url': '$_legalRoot/LICENSE',
      },
    ];
  }

  static Future<List<String>> getHarmonyLicensePackages(
    dynamic arguments,
  ) async {
    final licenses = await _readLicenses(arguments);
    final packages = <String>{
      for (final license in licenses)
        ...license.packages.where((package) => package.trim().isNotEmpty),
    }..remove('onepanel_client');
    return packages.toList()..sort(
      (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
    );
  }

  static Future<List<String>> getHarmonyPackageLicenses(
    dynamic arguments,
  ) async {
    final package = (arguments as Map)['package'] as String;
    final licenses = await _readLicenses(arguments);
    return {
      for (final license in licenses)
        if (license.packages.contains(package))
          license.paragraphs.map((paragraph) => paragraph.text).join('\n\n'),
    }.toList();
  }

  static Future<void> openHarmonyAboutLink(dynamic arguments) async {
    final id = (arguments as Map)['id'] as String;
    final url = switch (id) {
      'official' => _officialDomainUrl,
      'issues' => _issuesUrl,
      'releases' => _releasesUrl,
      'repository' => _repoHttps,
      _ => throw ArgumentError.value(id, 'id'),
    };
    await _openExternal(url);
  }

  static Future<void> openHarmonyLegalDocument(dynamic arguments) async {
    final id = (arguments as Map)['id'] as String;
    final documents = await getHarmonyLegalDocuments(arguments);
    final document = documents.firstWhere((document) => document['id'] == id);
    await _openExternal(document['url']!);
  }

  static Future<void> copyHarmonyAboutField(dynamic arguments) async {
    final field = (arguments as Map)['field'] as String;
    final text = switch (field) {
      'branch' => AppReleaseChannelConfig.branchName,
      'commit' => BuildMetadataConfig.gitCommit,
      'buildDate' => BuildMetadataConfig.buildDate,
      'domain' => _officialDomainName,
      'repoSsh' => _repoSsh,
      _ => throw ArgumentError.value(field, 'field'),
    };
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<List<LicenseEntry>> _readLicenses(dynamic arguments) {
    if (arguments is Map && arguments['refresh'] == true) {
      _licenses = LicenseRegistry.licenses.toList();
    }
    return _licenses ??= LicenseRegistry.licenses.toList();
  }

  static Future<void> _openExternal(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw StateError('无法打开链接：$url');
    }
  }
}
