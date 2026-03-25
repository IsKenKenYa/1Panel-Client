import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';

void main() {
  test('complete and reset onboarding toggles visibility', () async {
    SharedPreferences.setMockInitialValues({});
    final service = OnboardingService();

    expect(await service.shouldShowOnboarding(), isTrue);

    await service.completeOnboarding();
    expect(await service.shouldShowOnboarding(), isFalse);

    await service.resetAll();
    expect(await service.shouldShowOnboarding(), isTrue);
  });
}
