import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String onboardingCompletedKey = 'onboarding_completed_v2';
  static const String coachServerAddKey = 'coachmark_server_add_v2';
  static const String coachServerCardKey = 'coachmark_server_card_v2';

  static const List<String> _legacyKeys = [
    'onboarding_completed_v1',
    'coachmark_server_add_v1',
    'coachmark_server_card_v1',
  ];

  Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(onboardingCompletedKey) ?? false);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedKey, true);
  }

  Future<bool> shouldShowCoach(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(key) ?? false);
  }

  Future<void> completeCoach(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(onboardingCompletedKey);
    await prefs.remove(coachServerAddKey);
    await prefs.remove(coachServerCardKey);
    for (final legacyKey in _legacyKeys) {
      await prefs.remove(legacyKey);
    }
  }
}
