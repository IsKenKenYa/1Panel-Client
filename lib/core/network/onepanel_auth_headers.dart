import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../config/api_constants.dart';

class OnePanelAuthHeaders {
  const OnePanelAuthHeaders._();

  static Map<String, String> build(String apiKey, {DateTime? now}) {
    final timestamp =
        ((now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000).toString();
    final authToken = sign(apiKey, timestamp);
    return <String, String>{
      ApiConstants.authHeaderToken: authToken,
      ApiConstants.authHeaderTimestamp: timestamp,
    };
  }

  static String sign(String apiKey, String timestamp) {
    if (apiKey.isEmpty) throw ArgumentError('API Key 不能为空');
    final message = '${ApiConstants.authPrefix}:$timestamp';
    return Hmac(sha256, utf8.encode(apiKey))
        .convert(utf8.encode(message)).toString();
  }
}
