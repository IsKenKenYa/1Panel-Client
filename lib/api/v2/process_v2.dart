import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/process_detail_models.dart';
import '../../data/models/process_models.dart';

class ProcessV2Api {
  ProcessV2Api(this._client);

  final DioClient _client;

  Future<Response<void>> stopProcess(ProcessStopRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/process/stop'),
      data: request.toJson(),
    );
  }

  Future<Response<ProcessDetail>> getProcessByPid(int pid) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/process/$pid'),
    );
    return Response<ProcessDetail>(
      data: ProcessDetail.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<ListeningProcess>>> getListeningProcesses() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/process/listening'),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<ListeningProcess>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ListeningProcess.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}
