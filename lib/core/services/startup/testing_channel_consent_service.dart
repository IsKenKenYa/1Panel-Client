import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestingChannelConsentState {
  const TestingChannelConsentState({
    required this.channel,
    required this.versionKey,
    required this.storageKey,
    required this.accepted,
  });

  final String channel;
  final String versionKey;
  final String storageKey;
  final bool accepted;

  bool get requiresConsent => !accepted;
}

class TestingChannelConsentService {
  static const String _consentKeyPrefix = 'startup.testing_consent';

  Future<TestingChannelConsentState> readState(String channel) async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final versionKey = '${packageInfo.version}+${packageInfo.buildNumber}';
    final storageKey = '$_consentKeyPrefix.$channel.$versionKey';
    final accepted = prefs.getBool(storageKey) ?? false;

    return TestingChannelConsentState(
      channel: channel,
      versionKey: versionKey,
      storageKey: storageKey,
      accepted: accepted,
    );
  }

  Future<void> markAccepted(TestingChannelConsentState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(state.storageKey, true);
  }
}
