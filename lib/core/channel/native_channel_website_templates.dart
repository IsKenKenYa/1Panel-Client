import '../../data/models/website_template_models.dart';
import '../../features/websites/services/website_template_service.dart';

class NativeChannelWebsiteTemplateHandlers {
  static Map<String, dynamic> _template(WebsiteTemplateDto item) => {
        'id': item.id,
        'name': item.name,
        'type': item.type,
        'content': item.content,
        'filePath': item.filePath,
        'remark': item.remark,
        'variables': item.variables,
        'createdAt': item.createdAt,
        'updatedAt': item.updatedAt,
      };

  static Map<String, dynamic> _output(WebsiteTemplateOutputDto item) => {
        'id': item.id,
        'name': item.name,
        'templateID': item.templateID,
        'templateName': item.templateName,
        'templateType': item.templateType,
        'outputPath': item.outputPath,
        'variableValues': item.variableValues,
        'createdAt': item.createdAt,
        'updatedAt': item.updatedAt,
      };

  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    final service = WebsiteTemplateService();
    switch (method) {
      case 'getNativeWebsiteTemplates':
        final result = await service.searchTemplates(
          page: args['page'] as int,
          pageSize: args['pageSize'] as int,
          name: args['name'] as String?,
          type: args['type'] as String?,
        );
        return {'items': result.items.map(_template).toList(), 'total': result.total};
      case 'getNativeWebsiteTemplate':
        final item = await service.getTemplate(args['id'] as int);
        return item == null ? null : _template(item);
      case 'saveNativeWebsiteTemplate':
        final id = args['id'] as int?;
        if (id == null) {
          await service.createTemplate(WebsiteTemplateCreate(
            name: args['name'] as String,
            type: args['type'] as String,
            content: args['content'] as String?,
            filePath: args['filePath'] as String?,
            remark: args['remark'] as String?,
            variables: args['variables'] as String?,
          ));
        } else {
          await service.updateTemplate(WebsiteTemplateUpdate(
            id: id,
            name: args['name'] as String,
            type: args['type'] as String,
            content: args['content'] as String?,
            filePath: args['filePath'] as String?,
            remark: args['remark'] as String?,
            variables: args['variables'] as String?,
          ));
        }
        return null;
      case 'deleteNativeWebsiteTemplate':
        await service.deleteTemplate(args['id'] as int);
        return null;
      case 'getNativeWebsiteTemplateOutputs':
        final result = await service.searchOutputs(
          templateID: args['templateID'] as int?,
          page: args['page'] as int,
          pageSize: args['pageSize'] as int,
        );
        return {'items': result.items.map(_output).toList(), 'total': result.total};
      case 'getNativeWebsiteTemplateOutput':
        final item = await service.getOutput(args['id'] as int);
        return item == null ? null : _output(item);
      case 'previewNativeWebsiteTemplate':
        return service.previewTemplate(WebsitePreviewReq(
          templateID: args['templateID'] as int,
          variableValues: Map<String, String>.from(args['variableValues'] as Map),
        ));
      case 'createNativeWebsiteTemplateOutput':
        await service.createOutput(WebsiteTemplateOutputCreate(
          name: args['name'] as String,
          templateID: args['templateID'] as int,
          variableValues: Map<String, String>.from(args['variableValues'] as Map),
        ));
        return null;
      case 'deleteNativeWebsiteTemplateOutput':
        await service.deleteOutput(args['id'] as int);
        return null;
      default:
        throw ArgumentError.value(method, 'method');
    }
  }
}
