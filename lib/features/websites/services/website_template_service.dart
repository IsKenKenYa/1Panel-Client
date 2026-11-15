import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/common_models.dart';
import '../../../data/models/website_template_models.dart';

class WebsiteTemplateService {
  WebsiteTemplateService({WebsiteV2Api? api}) : _api = api;

  WebsiteV2Api? _api;

  Future<WebsiteV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getWebsiteApi();
    return _api!;
  }

  Future<PageResult<WebsiteTemplateDto>> searchTemplates({
    String? name,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final api = await _ensureApi();
    return api.searchWebsiteTemplates(
      WebsiteTemplateSearch(
        page: page,
        pageSize: pageSize,
        name: name,
        type: type,
      ),
    );
  }

  Future<WebsiteTemplateDto?> getTemplate(int id) async {
    final api = await _ensureApi();
    return (await api.getWebsiteTemplate(WebsiteTemplateIdReq(id: id))).data;
  }

  Future<void> createTemplate(WebsiteTemplateCreate request) async {
    final api = await _ensureApi();
    await api.createWebsiteTemplate(request);
  }

  Future<void> updateTemplate(WebsiteTemplateUpdate request) async {
    final api = await _ensureApi();
    await api.updateWebsiteTemplate(request);
  }

  Future<void> deleteTemplate(int id) async {
    final api = await _ensureApi();
    await api.deleteWebsiteTemplate(WebsiteTemplateIdReq(id: id));
  }

  Future<String> previewTemplate(WebsitePreviewReq request) async {
    final api = await _ensureApi();
    return (await api.previewWebsiteTemplate(request)).data?.html ?? '';
  }

  Future<PageResult<WebsiteTemplateOutputDto>> searchOutputs({
    int? templateID,
    int page = 1,
    int pageSize = 20,
  }) async {
    final api = await _ensureApi();
    return api.searchWebsiteTemplateOutputs(
      WebsiteTemplateOutputSearch(
        page: page,
        pageSize: pageSize,
        templateID: templateID,
      ),
    );
  }

  Future<WebsiteTemplateOutputDto?> getOutput(int id) async {
    final api = await _ensureApi();
    return (await api.getWebsiteTemplateOutput(WebsiteTemplateIdReq(id: id)))
        .data;
  }

  Future<void> createOutput(WebsiteTemplateOutputCreate request) async {
    final api = await _ensureApi();
    await api.createWebsiteTemplateOutput(request);
  }

  Future<void> deleteOutput(int id) async {
    final api = await _ensureApi();
    await api.deleteWebsiteTemplateOutput(WebsiteTemplateIdReq(id: id));
  }
}
