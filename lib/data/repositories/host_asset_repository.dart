import 'dart:convert';

import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_asset_models.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/data/models/host_tree_models.dart';

class HostAssetRepository {
  HostAssetRepository({
    ApiClientManager? clientManager,
    HostV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  HostV2Api? _api;

  Future<HostV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getHostApi();
  }

  Future<PageResult<HostInfo>> searchHosts(HostSearchRequest request) async {
    appLogger.dWithPackage(
      'data.repositories.host_asset',
      'searchHosts: ${request.toJson()}',
    );
    final api = await _ensureApi();
    final response = await api.searchHostAssets(request);
    return response.data ??
        const PageResult<HostInfo>(
          items: <HostInfo>[],
          total: 0,
        );
  }

  Future<HostInfo> getHostById(int id) async {
    final api = await _ensureApi();
    final response = await api.getHostById(id);
    if (response.data == null) {
      throw Exception('Host not found');
    }
    return response.data!;
  }

  Future<List<HostTreeNode>> loadHostTree({String? info}) async {
    final api = await _ensureApi();
    final response = await api.getHostAssetTree(info: info);
    return response.data ?? const <HostTreeNode>[];
  }

  Future<bool> testHostById(int id) async {
    final api = await _ensureApi();
    final response = await api.testHostById(id);
    return response.data ?? false;
  }

  Future<bool> testHostByInfo(HostConnTest request) async {
    final api = await _ensureApi();
    final response = await api.testHostAssetByInfo(_encodeConnection(request));
    return response.data ?? false;
  }

  Future<void> createHost(HostOperate request) async {
    final api = await _ensureApi();
    await api.createHostAsset(_encodeOperate(request));
  }

  Future<HostInfo> updateHost(HostOperate request) async {
    final api = await _ensureApi();
    final response = await api.updateHostAsset(_encodeOperate(request));
    if (response.data == null) {
      throw Exception('Update host failed');
    }
    return response.data!;
  }

  Future<void> deleteHosts(List<int> ids) async {
    final api = await _ensureApi();
    await api.deleteHost(OperateByIDs(ids: ids));
  }

  Future<void> updateHostGroup(HostGroupChange request) async {
    final api = await _ensureApi();
    await api.updateHostAssetGroup(request);
  }

  HostOperate _encodeOperate(HostOperate request) {
    final encodedPassword = request.password?.isNotEmpty == true
        ? _encode(request.password!)
        : null;
    final encodedPrivateKey = request.privateKey?.isNotEmpty == true
        ? _encode(request.privateKey!)
        : null;
    return request.copyWith(
      password: encodedPassword,
      privateKey: encodedPrivateKey,
    );
  }

  HostConnTest _encodeConnection(HostConnTest request) {
    return request.copyWith(
      password: request.password?.isNotEmpty == true
          ? _encode(request.password!)
          : null,
      privateKey: request.privateKey?.isNotEmpty == true
          ? _encode(request.privateKey!)
          : null,
    );
  }

  String _encode(String input) => base64.encode(utf8.encode(input));
}
