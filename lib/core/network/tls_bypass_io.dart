import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// IO (mobile/desktop) implementation - bypasses TLS certificate validation.
void configureTlsBypass(Dio dio) {
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  };
}
