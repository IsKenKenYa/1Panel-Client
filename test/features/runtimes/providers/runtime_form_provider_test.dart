import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_args.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_draft.dart';
import 'package:onepanel_client/features/runtimes/providers/runtime_form_provider.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';

class _MockRuntimeService extends Mock implements RuntimeService {}

void main() {
  late _MockRuntimeService service;
  late RuntimeFormProvider provider;

  const detail = RuntimeInfo(
    id: 3,
    name: 'java-main',
    type: 'java',
    resource: 'appstore',
    status: 'Running',
    image: 'eclipse-temurin:17-jre',
    codeDir: '/apps/java',
    port: '8080',
    params: <String, dynamic>{
      'HOST_IP': '0.0.0.0',
      'CONTAINER_NAME': 'java-main',
      'EXEC_SCRIPT': 'java -jar app.jar',
    },
    remark: 'prod',
  );

  setUpAll(() {
    registerFallbackValue(const RuntimeInfo());
    registerFallbackValue(const RuntimeFormDraft());
  });

  setUp(() {
    service = _MockRuntimeService();
    when(() => service.createDraft(any())).thenAnswer(
      (invocation) => RuntimeService().createDraft(
        invocation.positionalArguments.first as String,
      ),
    );
    when(() => service.getRuntimeDetail(any())).thenAnswer((_) async => detail);
    when(() => service.draftFromRuntime(any())).thenAnswer(
      (_) => RuntimeService().draftFromRuntime(detail),
    );
    when(() => service.createRuntime(any())).thenAnswer((_) async => null);
    when(() => service.updateRuntime(any())).thenAnswer((_) async {});
    provider = RuntimeFormProvider(service: service);
  });

  test('initialize create uses requested initial type', () async {
    await provider.initialize(const RuntimeFormArgs(initialType: 'node'));

    expect(provider.draft.type, 'node');
  });

  test('initialize edit maps detail into draft', () async {
    await provider.initialize(const RuntimeFormArgs(runtimeId: 3));

    expect(provider.draft.id, 3);
    expect(provider.draft.name, 'java-main');
    expect(provider.draft.type, 'java');
  });

  test('save create calls service after basic fields are filled', () async {
    await provider.initialize(const RuntimeFormArgs(initialType: 'node'));
    provider.updateBasic(name: 'node-main');
    provider.updateRuntimeConfig(
      image: 'node:20-alpine',
      codeDir: '/apps/node',
      port: 3000,
      source: 'https://registry.npmjs.org/',
      hostIp: '0.0.0.0',
      containerName: 'node-main',
      execScript: 'npm start',
      packageManager: 'npm',
    );

    final result = await provider.save();

    expect(result, isTrue);
    verify(() => service.createRuntime(any())).called(1);
  });

  test('save edit calls update service', () async {
    await provider.initialize(const RuntimeFormArgs(runtimeId: 3));

    final result = await provider.save();

    expect(result, isTrue);
    verify(() => service.updateRuntime(any())).called(1);
  });
}
