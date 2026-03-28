import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/mcp_models.dart';
import 'package:onepanel_client/features/ai/mcp_server_service.dart';

class McpServerProvider extends ChangeNotifier {
  McpServerProvider({McpServerService? service})
      : _service = service ?? McpServerService();

  final McpServerService _service;

  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;
  String _searchQuery = '';
  List<McpServerDTO> _servers = const <McpServerDTO>[];
  McpBindDomainRes _binding = const McpBindDomainRes();

  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<McpServerDTO> get servers => _servers;
  McpBindDomainRes get binding => _binding;

  Future<void> load({String? keyword}) async {
    _isLoading = true;
    _error = null;
    if (keyword != null) {
      _searchQuery = keyword;
    }
    notifyListeners();

    try {
      final snapshot = await _service.loadSnapshot(
        keyword: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
      _servers = snapshot.servers;
      _binding = snapshot.binding;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.mcp_server_provider',
        'load mcp servers failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<bool> saveServer({
    int? id,
    required String name,
    required String command,
    required String type,
    required String outputTransport,
    required int port,
    String? baseUrl,
    String? hostIP,
    String? containerName,
    String? ssePath,
    String? streamableHttpPath,
  }) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      if (id == null) {
        await _service.createServer(
          McpServerCreate(
            name: name,
            command: command,
            type: type,
            outputTransport: outputTransport,
            port: port,
            baseUrl: _normalizeOptional(baseUrl),
            hostIP: _normalizeOptional(hostIP),
            containerName: _normalizeOptional(containerName),
            ssePath: _normalizeOptional(ssePath),
            streamableHttpPath: _normalizeOptional(streamableHttpPath),
          ),
        );
      } else {
        await _service.updateServer(
          McpServerUpdate(
            id: id,
            name: name,
            command: command,
            type: type,
            outputTransport: outputTransport,
            port: port,
            baseUrl: _normalizeOptional(baseUrl),
            hostIP: _normalizeOptional(hostIP),
            containerName: _normalizeOptional(containerName),
            ssePath: _normalizeOptional(ssePath),
            streamableHttpPath: _normalizeOptional(streamableHttpPath),
          ),
        );
      }
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.mcp_server_provider',
        'save mcp server failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteServer(int id) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteServer(id);
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.mcp_server_provider',
        'delete mcp server failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> operateServer({
    required int id,
    required String operate,
  }) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await _service.operateServer(id: id, operate: operate);
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.mcp_server_provider',
        'operate mcp server failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> saveDomainBinding({
    required String domain,
    String? ipList,
    int? sslId,
    int? websiteId,
  }) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      final hasExistingBinding = (_binding.domain ?? '').trim().isNotEmpty &&
          (_binding.websiteID ?? 0) > 0;
      if (hasExistingBinding && websiteId != null && websiteId > 0) {
        await _service.updateDomain(
          McpBindDomainUpdate(
            ipList: _normalizeOptional(ipList),
            sslID: sslId,
            websiteID: websiteId,
          ),
        );
      } else {
        await _service.bindDomain(
          McpBindDomain(
            domain: domain,
            ipList: _normalizeOptional(ipList),
            sslID: sslId,
          ),
        );
      }
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.mcp_server_provider',
        'save mcp domain binding failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  String buildExternalUrl(McpServerDTO server) {
    final baseUrl = (server.baseUrl ?? '').trim();
    if (baseUrl.isEmpty) {
      return '';
    }
    if ((server.outputTransport ?? '').toLowerCase() == 'sse') {
      return '$baseUrl${server.ssePath ?? ''}';
    }
    return '$baseUrl${server.streamableHttpPath ?? ''}';
  }

  Map<String, dynamic> buildConfigPreview(McpServerDTO server) {
    return <String, dynamic>{
      'mcpServers': <String, dynamic>{
        server.name ?? 'server': <String, dynamic>{
          'url': buildExternalUrl(server),
        },
      },
    };
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
