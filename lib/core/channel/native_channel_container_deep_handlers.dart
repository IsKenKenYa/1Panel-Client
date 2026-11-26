import '../../api/v2/api_response_parser.dart';
import '../config/api_constants.dart';
import '../network/api_client_manager.dart';
import '../../data/models/common_models.dart';
import '../../data/models/container_models.dart';
import '../../features/containers/container_service.dart';
import '../../features/orchestration/services/orchestration_service.dart';

class NativeChannelContainerDeepHandlers {
  static Future<Map<String, dynamic>> getContainerForm(dynamic arguments) async {
    final client = await ApiClientManager.instance.getCurrentClient();
    final result = await client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/info'),
      data: {'name': arguments['name'] as String},
    );
    return ApiResponseParser.asMap(result.data);
  }

  static Future<Map<String, dynamic>> createContainerFromForm(dynamic arguments) async {
    final request = Map<String, dynamic>.from(arguments as Map);
    request['taskID'] = DateTime.now().millisecondsSinceEpoch.toString();
    final client = await ApiClientManager.instance.getCurrentClient();
    await client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers'), data: request,
    );
    return {'success': true};
  }
  static Future<Map<String, dynamic>> getContainerStats(dynamic arguments) async {
    final stats = await ContainerService().getContainerStats(arguments['id'] as String);
    return stats.toJson();
  }

  static Future<Map<String, dynamic>> renameContainer(dynamic arguments) async {
    await ContainerService().renameContainer(ContainerRename.fromJson(
      Map<String, dynamic>.from(arguments as Map),
    ));
    return {'success': true};
  }

  static Future<Map<String, dynamic>> upgradeContainer(dynamic arguments) async {
    final request = Map<String, dynamic>.from(arguments as Map);
    request['taskID'] = DateTime.now().millisecondsSinceEpoch.toString();
    await ContainerService().upgradeContainer(ContainerUpgrade.fromJson(request));
    return {'success': true};
  }

  static Future<Map<String, dynamic>> commitContainer(dynamic arguments) async {
    await ContainerService().commitContainer(ContainerCommit.fromJson(
      Map<String, dynamic>.from(arguments as Map),
    ));
    return {'success': true};
  }

  static Future<Map<String, dynamic>> updateContainer(dynamic arguments) async {
    final request = Map<String, dynamic>.from(arguments as Map);
    request['taskID'] = DateTime.now().millisecondsSinceEpoch.toString();
    final client = await ApiClientManager.instance.getCurrentClient();
    await client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/update'), data: request,
    );
    return {'success': true};
  }

  static Future<Map<String, dynamic>> cleanContainerLog(dynamic arguments) async {
    await ContainerService().cleanContainerLog(arguments['name'] as String);
    return {'success': true};
  }

  static Future<Map<String, dynamic>> pruneContainers(dynamic arguments) async {
    final report = await ContainerService().pruneContainers(ContainerPrune.fromJson(
      Map<String, dynamic>.from(arguments as Map),
    ));
    return {'success': true, 'data': report.toJson()};
  }

  static Future<Map<String, dynamic>> getDockerConfiguration(dynamic arguments) async {
    final service = ContainerService();
    final status = await service.getDockerStatus();
    final content = await service.getDaemonJson();
    return {'status': status.toJson(), 'content': content};
  }

  static Future<Map<String, dynamic>> saveDockerConfiguration(dynamic arguments) async {
    await ContainerService().updateDaemonJson(arguments['content'] as String);
    return {'success': true};
  }

  static Future<Map<String, dynamic>> operateDocker(dynamic arguments) async {
    await ContainerService().operateDocker(DockerOperation.fromJson(
      Map<String, dynamic>.from(arguments as Map),
    ));
    return {'success': true};
  }

  static Future<Map<String, dynamic>> tagContainerImage(dynamic arguments) async {
    final api = await ApiClientManager.instance.getContainerApi();
    await api.tagImage(ImageTag.fromJson(Map<String, dynamic>.from(arguments as Map)));
    return {'success': true};
  }

  static Future<Map<String, dynamic>> saveContainerImage(dynamic arguments) async {
    final api = await ApiClientManager.instance.getContainerApi();
    await api.saveImage(ImageSave.fromJson(Map<String, dynamic>.from(arguments as Map)));
    return {'success': true};
  }

  static Future<Map<String, dynamic>> loadContainerImage(dynamic arguments) async {
    final api = await ApiClientManager.instance.getContainerApi();
    await api.loadImage(ImageLoad.fromJson(Map<String, dynamic>.from(arguments as Map)));
    return {'success': true};
  }

  static Future<Map<String, dynamic>> updateContainerTemplate(dynamic arguments) async {
    await OrchestrationService().updateTemplate(ContainerTemplateOperate(
      id: arguments['id'] as int,
      name: arguments['name'] as String,
      description: arguments['description'] as String,
      content: arguments['content'] as String,
    ));
    return {'success': true};
  }
}
