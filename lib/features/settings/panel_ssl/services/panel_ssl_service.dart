import 'dart:convert';
import 'dart:typed_data';

import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:onepanel_client/data/repositories/setting_repository.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

class PanelSslService {
  PanelSslService() : _repository = SettingRepository();

  PanelSslService.forServer(ApiConfig server)
      : _repository = SettingRepository.forServer(server);

  final SettingRepository _repository;

  Future<Map<String, dynamic>> getSslInfo() async {
    final api = await _repository.ensureApi();
    return (await api.getSSLInfo()).data!;
  }

  Future<void> updateSsl({required String cert, required String key}) async {
    if (!isPublicCertificatePem(cert) || !isPrivateKeyPem(key)) {
      throw const FormatException('需要 PEM 证书和私钥');
    }
    final api = await _repository.ensureApi();
    final settings = await api.getSystemSettings();
    await api.updateSSL(SSLUpdate.importPem(
      currentMode: settings.data?.ssl,
      cert: cert,
      key: key,
    ));
  }

  Future<({SaveOutcome file, int size})> downloadSsl() async {
    final api = await _repository.ensureApi();
    final bytes = (await api.downloadSSL()).data!;
    if (!isPublicCertificatePem(ascii.decode(bytes, allowInvalid: true))) {
      throw const FormatException('服务器未返回公开的 PEM 证书');
    }
    final file = await PlatformFileService().saveBytesStructured(
      fileName: 'server.crt',
      bytes: Uint8List.fromList(bytes),
      mimeType: 'application/x-pem-file',
      category: 'certificates',
    );
    return (file: file, size: bytes.length);
  }

}
