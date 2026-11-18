import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';

import '../../../data/models/runtime_models.dart';
import '../../../data/models/website_group_models.dart';
import '../../../data/models/website_models.dart';
import '../../../data/repositories/website_repository.dart';
import 'website_detail_store.dart';

enum WebsiteLifecycleMode { create, edit }

class WebsiteLifecycleState {
  const WebsiteLifecycleState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.groups = const <WebsiteGroup>[],
    this.runtimes = const <RuntimeInfo>[],
    this.parentWebsites = const <WebsiteInfo>[],
    this.website,
    this.type = 'runtime',
    this.alias = '',
    this.primaryDomain = '',
    this.remark = '',
    this.groupId,
    this.runtimeId,
    this.siteDir = '',
    this.proxyType = 'tcp',
    this.proxyAddress = '',
    this.port = '',
    this.parentWebsiteId,
    this.ipv6 = false,
    this.favorite = false,
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final List<WebsiteGroup> groups;
  final List<RuntimeInfo> runtimes;
  final List<WebsiteInfo> parentWebsites;
  final WebsiteInfo? website;
  final String type;
  final String alias;
  final String primaryDomain;
  final String remark;
  final int? groupId;
  final int? runtimeId;
  final String siteDir;
  final String proxyType;
  final String proxyAddress;
  final String port;
  final int? parentWebsiteId;
  final bool ipv6;
  final bool favorite;

  WebsiteLifecycleState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    Object? error = _unset,
    List<WebsiteGroup>? groups,
    List<RuntimeInfo>? runtimes,
    List<WebsiteInfo>? parentWebsites,
    Object? website = _unset,
    String? type,
    String? alias,
    String? primaryDomain,
    String? remark,
    Object? groupId = _unset,
    Object? runtimeId = _unset,
    String? siteDir,
    String? proxyType,
    String? proxyAddress,
    String? port,
    Object? parentWebsiteId = _unset,
    bool? ipv6,
    bool? favorite,
  }) {
    return WebsiteLifecycleState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: identical(error, _unset) ? this.error : error as String?,
      groups: groups ?? this.groups,
      runtimes: runtimes ?? this.runtimes,
      parentWebsites: parentWebsites ?? this.parentWebsites,
      website:
          identical(website, _unset) ? this.website : website as WebsiteInfo?,
      type: type ?? this.type,
      alias: alias ?? this.alias,
      primaryDomain: primaryDomain ?? this.primaryDomain,
      remark: remark ?? this.remark,
      groupId: identical(groupId, _unset) ? this.groupId : groupId as int?,
      runtimeId:
          identical(runtimeId, _unset) ? this.runtimeId : runtimeId as int?,
      siteDir: siteDir ?? this.siteDir,
      proxyType: proxyType ?? this.proxyType,
      proxyAddress: proxyAddress ?? this.proxyAddress,
      port: port ?? this.port,
      parentWebsiteId: identical(parentWebsiteId, _unset)
          ? this.parentWebsiteId
          : parentWebsiteId as int?,
      ipv6: ipv6 ?? this.ipv6,
      favorite: favorite ?? this.favorite,
    );
  }

  // Sentinel object to distinguish "not provided" from explicit null in copyWith.
  static const _unset = Object();
}

class WebsiteLifecycleProvider extends ChangeNotifier with SafeChangeNotifier {
  WebsiteLifecycleProvider({
    required this.mode,
    this.websiteId,
    WebsiteRepository? repository,
    WebsiteDetailStore? store,
  })  : _repository = repository ?? WebsiteRepository(),
        _store = store;

  final WebsiteLifecycleMode mode;
  final int? websiteId;
  final WebsiteRepository _repository;
  final WebsiteDetailStore? _store;

  WebsiteLifecycleState _state = const WebsiteLifecycleState();
  WebsiteLifecycleState get state => _state;

  bool get isEditMode => mode == WebsiteLifecycleMode.edit;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final groups = await _repository.listWebsiteGroups();
      final runtimes = await _repository.listPhpRuntimes();
      final parentWebsites = await _repository.listParentWebsites();

      var nextState = _state.copyWith(
        isLoading: false,
        groups: groups,
        runtimes: runtimes,
        parentWebsites: parentWebsites,
        groupId: groups.isNotEmpty ? groups.first.id : null,
        runtimeId: runtimes.isNotEmpty ? runtimes.first.id : null,
      );

      if (isEditMode && websiteId != null) {
        final WebsiteInfo website = _store != null
            ? (await _store!.load()) ??
                (await _repository.getWebsiteDetail(websiteId!))
            : await _repository.getWebsiteDetail(websiteId!);
        nextState = nextState.copyWith(
          website: website,
          type: _resolveType(website.type),
          alias: website.alias ?? '',
          primaryDomain: website.primaryDomain ?? website.displayDomain ?? '',
          remark: website.remark ?? '',
          groupId: website.webSiteGroupId ?? nextState.groupId,
          runtimeId: website.runtimeId ?? nextState.runtimeId,
          siteDir: website.siteDir ?? '',
          proxyType: website.proxyType ?? nextState.proxyType,
          proxyAddress: website.proxy ?? '',
          port: website.domains.isNotEmpty
              ? '${website.domains.first.port ?? ''}'
              : '',
          parentWebsiteId: website.parentWebsiteId,
          ipv6: website.ipv6 ?? false,
          favorite: website.favorite ?? false,
        );
      }

      _state = nextState;
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: ErrorMessageUtils.userFacingMessage(e));
    }
    notifyListeners();
  }

  void setType(String value) {
    _state = _state.copyWith(type: value, error: null);
    notifyListeners();
  }

  void setAlias(String value) {
    _state = _state.copyWith(alias: value);
    notifyListeners();
  }

  void setPrimaryDomain(String value) {
    _state = _state.copyWith(primaryDomain: value);
    notifyListeners();
  }

  void setRemark(String value) {
    _state = _state.copyWith(remark: value);
    notifyListeners();
  }

  void setGroupId(int? value) {
    _state = _state.copyWith(groupId: value);
    notifyListeners();
  }

  void setRuntimeId(int? value) {
    _state = _state.copyWith(runtimeId: value);
    notifyListeners();
  }

  void setSiteDir(String value) {
    _state = _state.copyWith(siteDir: value);
    notifyListeners();
  }

  void setProxyType(String value) {
    _state = _state.copyWith(proxyType: value);
    notifyListeners();
  }

  void setProxyAddress(String value) {
    _state = _state.copyWith(proxyAddress: value);
    notifyListeners();
  }

  void setPort(String value) {
    _state = _state.copyWith(port: value);
    notifyListeners();
  }

  void setParentWebsiteId(int? value) {
    _state = _state.copyWith(parentWebsiteId: value);
    notifyListeners();
  }

  Future<bool> submit() async {
    final validationError = _validate();
    if (validationError != null) {
      _state = _state.copyWith(error: validationError);
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isSubmitting: true, error: null);
    notifyListeners();
    try {
      if (isEditMode) {
        await _repository.updateWebsiteByModel(_buildUpdateRequest());
      } else {
        await _repository.preCheckWebsite({});
        await _repository.createWebsite(_buildCreateRequest());
      }
      return true;
    } catch (e) {
      _state = _state.copyWith(error: ErrorMessageUtils.userFacingMessage(e));
      notifyListeners();
      return false;
    } finally {
      _state = _state.copyWith(isSubmitting: false);
      notifyListeners();
    }
  }

  WebsiteCreate _buildCreateRequest() {
    final port = int.tryParse(_state.port.trim());
    final primaryDomain = _state.primaryDomain.trim();
    return WebsiteCreate(
      alias: _state.alias.trim(),
      name: primaryDomain,
      remark: _state.remark.trim().isEmpty ? null : _state.remark.trim(),
      type: _state.type,
      webSiteGroupId: _state.groupId ?? 0,
      // 服务端校验 appType 必须是 new 或 installed；建站流程默认复用已安装应用。
      appType: 'installed',
      runtimeId: _state.type == 'runtime' ? _state.runtimeId : null,
      siteDir: _state.siteDir.trim().isEmpty ? null : _state.siteDir.trim(),
      proxyType: _state.type == 'proxy' ? _state.proxyType : null,
      proxy: _state.type == 'proxy' ? _state.proxyAddress.trim() : null,
      port: port,
      parentWebsiteId: _state.type == 'subsite' ? _state.parentWebsiteId : null,
      domains: primaryDomain.isEmpty
          ? null
          : [
              WebsiteDomain(
                domain: primaryDomain,
                port: port,
                ssl: false,
              ),
            ],
      // Unique task ID for server-side deduplication of rapid retries.
      taskId: DateTime.now().millisecondsSinceEpoch.toString(),
      ipv6: _state.ipv6,
    );
  }

  WebsiteUpdate _buildUpdateRequest() {
    return WebsiteUpdate(
      id: websiteId ?? 0,
      primaryDomain: _state.primaryDomain.trim(),
      remark: _state.remark.trim(),
      webSiteGroupId: _state.groupId ?? 0,
      ipv6: _state.ipv6,
      favorite: _state.favorite,
    );
  }

  String? _validate() {
    if (_state.groupId == null) {
      return 'group';
    }
    if (_state.primaryDomain.trim().isEmpty) {
      return 'domain';
    }
    if (!isEditMode) {
      if (_state.alias.trim().isEmpty) {
        return 'alias';
      }
      if (_state.type == 'runtime' && _state.runtimeId == null) {
        return 'runtime';
      }
      if (_state.type == 'proxy' && _state.proxyAddress.trim().isEmpty) {
        return 'proxy';
      }
      if (_state.type == 'subsite' && _state.parentWebsiteId == null) {
        return 'parent';
      }
    }
    return null;
  }

  // Default to 'runtime' for unknown types to handle future server-side additions gracefully.
  String _resolveType(String? value) {
    switch (value) {
      case 'proxy':
      case 'subsite':
      case 'static':
      case 'runtime':
        return value!;
      default:
        return 'runtime';
    }
  }
}
