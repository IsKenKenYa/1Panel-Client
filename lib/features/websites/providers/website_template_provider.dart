import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/website_template_models.dart';

import '../services/website_template_service.dart';

class WebsiteTemplateProvider extends ChangeNotifier with SafeChangeNotifier {
  WebsiteTemplateProvider({WebsiteTemplateService? service})
      : _service = service;

  WebsiteTemplateService? _service;

  bool isLoading = false;
  bool isSaving = false;
  String? error;
  String? operationError;

  PageResult<WebsiteTemplateDto> templates =
      PageResult<WebsiteTemplateDto>(items: const [], total: 0);
  PageResult<WebsiteTemplateOutputDto> outputs =
      PageResult<WebsiteTemplateOutputDto>(items: const [], total: 0);
  WebsiteTemplateDto? editingTemplate;
  String previewHtml = '';

  Future<void> _ensureService() async {
    _service ??= WebsiteTemplateService();
  }

  Future<void> loadTemplates({String? name, String? type}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      templates = await _service!.searchTemplates(name: name, type: type);
    } catch (e) {
      error = ErrorMessageUtils.userFacingMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOutputs({int? templateID}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      outputs = await _service!.searchOutputs(templateID: templateID);
    } catch (e) {
      error = ErrorMessageUtils.userFacingMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<WebsiteTemplateDto?> loadTemplate(int id) async {
    await _ensureService();
    editingTemplate = await _service!.getTemplate(id);
    notifyListeners();
    return editingTemplate;
  }

  void clearEditing() {
    editingTemplate = null;
    previewHtml = '';
  }

  Future<bool> saveTemplate({
    required String name,
    required String type,
    String? content,
    String? remark,
    String? variables,
    String? filePath,
  }) async {
    isSaving = true;
    operationError = null;
    notifyListeners();
    try {
      await _ensureService();
      final existing = editingTemplate;
      if (existing == null) {
        await _service!.createTemplate(
          WebsiteTemplateCreate(
            name: name,
            type: type,
            content: content,
            remark: remark,
            variables: variables,
            filePath: filePath,
          ),
        );
      } else {
        await _service!.updateTemplate(
          WebsiteTemplateUpdate(
            id: existing.id,
            name: name,
            type: type,
            content: content,
            remark: remark,
            variables: variables,
            filePath: filePath,
          ),
        );
      }
      await loadTemplates();
      return true;
    } catch (e) {
      operationError = ErrorMessageUtils.userFacingMessage(e);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTemplate(int id) async {
    try {
      await _ensureService();
      await _service!.deleteTemplate(id);
      await loadTemplates();
      return true;
    } catch (e) {
      operationError = ErrorMessageUtils.userFacingMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOutput(int id, {int? templateID}) async {
    try {
      await _ensureService();
      await _service!.deleteOutput(id);
      await loadOutputs(templateID: templateID);
      return true;
    } catch (e) {
      operationError = ErrorMessageUtils.userFacingMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<String> preview({
    required int templateID,
    Map<String, String>? variableValues,
  }) async {
    await _ensureService();
    previewHtml = await _service!.previewTemplate(
      WebsitePreviewReq(
        templateID: templateID,
        variableValues: variableValues,
      ),
    );
    notifyListeners();
    return previewHtml;
  }

  Future<bool> createOutput({
    required String name,
    required int templateID,
    Map<String, String>? variableValues,
  }) async {
    isSaving = true;
    operationError = null;
    notifyListeners();
    try {
      await _ensureService();
      await _service!.createOutput(
        WebsiteTemplateOutputCreate(
          name: name,
          templateID: templateID,
          variableValues: variableValues,
        ),
      );
      await loadOutputs(templateID: templateID);
      return true;
    } catch (e) {
      operationError = ErrorMessageUtils.userFacingMessage(e);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
