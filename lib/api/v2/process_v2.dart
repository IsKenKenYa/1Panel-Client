import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';

class ProcessV2Api {
  ProcessV2Api(this._client);

  final DioClient _client;

  Future<Response<void>> stopProcess(ProcessRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/process/stop'),
      data: request.toJson(),
    );
  }

  Future<Response<Map<String, dynamic>>> getProcessByPid(int pid) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/process/$pid'),
    );
    return Response<Map<String, dynamic>>(
      data: response.data?['data'] as Map<String, dynamic>? ?? const {},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<Map<String, dynamic>>>> getListeningProcesses() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/process/listening'),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<Map<String, dynamic>>>(
      data: rawItems.whereType<Map<String, dynamic>>().toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}

class ProcessRequest {
  const ProcessRequest({
    required this.pid,
  });

  final int pid;

  Map<String, dynamic> toJson() => <String, dynamic>{'PID': pid};
}
