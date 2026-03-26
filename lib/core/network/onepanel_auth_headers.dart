import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../config/api_constants.dart';

class OnePanelAuthHeaders {
  const OnePanelAuthHeaders._();

  static Map<String, String> build(String apiKey) {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
    final authToken = _generateToken(apiKey, timestamp);
    return <String, String>{
      ApiConstants.authHeaderToken: authToken,
      ApiConstants.authHeaderTimestamp: timestamp,
    };
  }

  static String _generateToken(String apiKey, String timestamp) {
    final authString = '${ApiConstants.authPrefix}$apiKey$timestamp';
    return md5.convert(utf8.encode(authString)).toString();
  }
}
