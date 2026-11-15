import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/website_template_models.dart';
import 'package:onepanel_client/features/websites/providers/website_template_provider.dart';
import 'package:onepanel_client/features/websites/services/website_template_service.dart';

class _FakeWebsiteTemplateService extends WebsiteTemplateService {
  _FakeWebsiteTemplateService() : super(api: null);

  PageResult<WebsiteTemplateDto> templatePage = PageResult<WebsiteTemplateDto>(
    items: <WebsiteTemplateDto>[
      const WebsiteTemplateDto(
        id: 3,
        name: 'nginx-basic',
        type: 'single',
        content: 'server {}',
        filePath: '/templates/nginx.zip',
        remark: 'demo',
        variables: '[]',
        createdAt: '2026-11-12 10:00:00',
        updatedAt: '2026-11-12 11:00:00',
      ),
    ],
    total: 1,
  );
  PageResult<WebsiteTemplateOutputDto> outputPage =
      PageResult<WebsiteTemplateOutputDto>(
    items: <WebsiteTemplateOutputDto>[
      const WebsiteTemplateOutputDto(
        id: 8,
        name: 'prod-conf',
        templateID: 3,
        templateName: 'nginx-basic',
        templateType: 'single',
        outputPath: '/etc/nginx/prod.conf',
        variableValues: '{}',
        createdAt: '2026-11-12 10:00:00',
        updatedAt: '2026-11-12 11:00:00',
      ),
    ],
    total: 1,
  );

  bool failLoad = false;
  bool failMutation = false;
  int createCount = 0;
  int updateCount = 0;
  int deleteTemplateCount = 0;
  int deleteOutputCount = 0;
  int createOutputCount = 0;
  WebsiteTemplateCreate? lastCreate;
  WebsiteTemplateUpdate? lastUpdate;
  WebsiteTemplateOutputCreate? lastOutputCreate;
  int? lastPreviewTemplateId;
  Map<String, String>? lastPreviewValues;

  void _maybeThrowLoad() {
    if (failLoad) throw Exception('load failed');
  }

  void _maybeThrowMutation() {
    if (failMutation) throw Exception('mutation failed');
  }

  @override
  Future<PageResult<WebsiteTemplateDto>> searchTemplates({
    String? name,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    _maybeThrowLoad();
    return templatePage;
  }

  @override
  Future<PageResult<WebsiteTemplateOutputDto>> searchOutputs({
    int? templateID,
    int page = 1,
    int pageSize = 20,
  }) async {
    _maybeThrowLoad();
    return outputPage;
  }

  @override
  Future<WebsiteTemplateDto?> getTemplate(int id) async {
    return templatePage.items.first;
  }

  @override
  Future<void> createTemplate(WebsiteTemplateCreate request) async {
    _maybeThrowMutation();
    createCount++;
    lastCreate = request;
  }

  @override
  Future<void> updateTemplate(WebsiteTemplateUpdate request) async {
    _maybeThrowMutation();
    updateCount++;
    lastUpdate = request;
  }

  @override
  Future<void> deleteTemplate(int id) async {
    _maybeThrowMutation();
    deleteTemplateCount++;
  }

  @override
  Future<String> previewTemplate(WebsitePreviewReq request) async {
    lastPreviewTemplateId = request.templateID;
    lastPreviewValues = request.variableValues;
    return '<h1>preview</h1>';
  }

  @override
  Future<void> createOutput(WebsiteTemplateOutputCreate request) async {
    _maybeThrowMutation();
    createOutputCount++;
    lastOutputCreate = request;
  }

  @override
  Future<void> deleteOutput(int id) async {
    _maybeThrowMutation();
    deleteOutputCount++;
  }
}

void main() {
  group('WebsiteTemplateProvider', () {
    late _FakeWebsiteTemplateService service;
    late WebsiteTemplateProvider provider;

    setUp(() {
      service = _FakeWebsiteTemplateService();
      provider = WebsiteTemplateProvider(service: service);
    });

    test('loadTemplates_populatesListAndClearsError', () async {
      await provider.loadTemplates();

      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.templates.items.single.name, 'nginx-basic');
    });

    test('loadTemplates_onFailure_setsUserFacingError', () async {
      service.failLoad = true;

      await provider.loadTemplates();

      expect(provider.isLoading, isFalse);
      expect(provider.error, isNotNull);
    });

    test('saveTemplate_withoutEditing_callsCreate', () async {
      final ok = await provider.saveTemplate(
        name: 'new-template',
        type: 'single',
        content: 'server {}',
      );

      expect(ok, isTrue);
      expect(service.createCount, 1);
      expect(service.updateCount, 0);
      expect(service.lastCreate?.name, 'new-template');
      expect(service.lastCreate?.type, 'single');
      expect(provider.isSaving, isFalse);
    });

    test('saveTemplate_withEditing_callsUpdateWithId', () async {
      await provider.loadTemplate(3);

      final ok = await provider.saveTemplate(
        name: 'nginx-basic',
        type: 'multi',
      );

      expect(ok, isTrue);
      expect(service.updateCount, 1);
      expect(service.lastUpdate?.id, 3);
      expect(service.lastUpdate?.type, 'multi');
    });

    test('saveTemplate_onFailure_returnsFalseAndSetsOperationError', () async {
      service.failMutation = true;

      final ok = await provider.saveTemplate(
        name: 'new-template',
        type: 'single',
      );

      expect(ok, isFalse);
      expect(provider.operationError, isNotNull);
      expect(provider.isSaving, isFalse);
    });

    test('deleteTemplate_removesAndReloads', () async {
      final ok = await provider.deleteTemplate(3);

      expect(ok, isTrue);
      expect(service.deleteTemplateCount, 1);
      expect(provider.templates.items.length, 1);
    });

    test('preview_returnsHtmlAndStoresState', () async {
      final html = await provider.preview(
        templateID: 3,
        variableValues: <String, String>{'port': '8080'},
      );

      expect(html, '<h1>preview</h1>');
      expect(provider.previewHtml, '<h1>preview</h1>');
      expect(service.lastPreviewTemplateId, 3);
      expect(service.lastPreviewValues, <String, String>{'port': '8080'});
    });

    test('createOutput_andDeleteOutput_callsService', () async {
      final created = await provider.createOutput(
        name: 'prod-conf',
        templateID: 3,
        variableValues: <String, String>{'port': '8080'},
      );

      expect(created, isTrue);
      expect(service.createOutputCount, 1);
      expect(service.lastOutputCreate?.templateID, 3);

      final deleted = await provider.deleteOutput(8);
      expect(deleted, isTrue);
      expect(service.deleteOutputCount, 1);
    });
  });
}
