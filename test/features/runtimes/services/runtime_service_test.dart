import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_draft.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';

void main() {
  test('更新运行环境时需要已有的运行环境 ID', () {
    final service = RuntimeService();

    expect(
      () => service.buildUpdateRequest(const RuntimeFormDraft()),
      throwsArgumentError,
    );
    expect(
      service.buildUpdateRequest(const RuntimeFormDraft(id: 17)).toJson()['id'],
      17,
    );
  });
}
