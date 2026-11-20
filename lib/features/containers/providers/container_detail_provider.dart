import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/data/models/container_models.dart'
    hide Container;
import 'package:onepanel_client/features/containers/container_service.dart';

import 'package:onepanel_client/core/network/network_exceptions.dart';

class ContainerDetailProvider extends ChangeNotifier with SafeChangeNotifier {
  ContainerDetailProvider({
    required this.container,
    ContainerService? service,
  }) : _service = service ?? ContainerService();

  final ContainerInfo container;
  final ContainerService _service;

  bool _inspectLoading = false;
  bool _logsLoading = false;
  bool _statsLoading = false;

  String? _inspectError;
  String? _logsError;
  String? _statsError;

  String? _inspectData;
  String _logs = '';
  ContainerStats? _stats;

  bool _followLogs = true;
  StreamSubscription<String>? _logsSubscription;

  bool get inspectLoading => _inspectLoading;
  bool get logsLoading => _logsLoading;
  bool get statsLoading => _statsLoading;

  String? get inspectError => _inspectError;
  String? get logsError => _logsError;
  String? get statsError => _statsError;

  String? get inspectData => _inspectData;
  String get logs => _logs;
  ContainerStats? get stats => _stats;

  /// 当前是否处于日志跟随状态。
  bool get followLogs => _followLogs;

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadAll() async {
    if (isDisposed) return;
    await Future.wait([
      loadInspect(),
      loadLogs(),
      loadStats(),
    ]);
  }

  Future<void> loadInspect() async {
    // Guard against notifyListeners() after widget tree disposal; the provider
    // outlives the page if the user navigates away during a network call.
    if (isDisposed) return;

    _inspectLoading = true;
    _inspectError = null;
    notifyListeners();

    try {
      _inspectData = await _service.inspectContainer(container.id);
      if (isDisposed) return;
    } catch (e) {
      if (!isDisposed) {
        _inspectError = ErrorMessageUtils.userFacingMessage(e);
      }
    } finally {
      if (!isDisposed) {
        _inspectLoading = false;
        notifyListeners();
      }
    }
  }

  /// 订阅容器日志流。
  ///
  /// [follow] 为 true 时服务端持续推送新日志并保持连接；为 false 时
  /// 回放 [tail] 行后结束。重复调用会先终止上一订阅，避免同一日志
  /// 被两条流同时写入。
  Future<void> loadLogs({String tail = '1000', bool? follow}) async {
    if (isDisposed) return;

    final nextFollow = follow ?? _followLogs;
    _followLogs = nextFollow;

    await _logsSubscription?.cancel();
    _logsSubscription = null;

    _logsLoading = true;
    _logsError = null;
    _logs = '';
    notifyListeners();

    final buffer = StringBuffer();
    _logsSubscription = _service
        .streamContainerLogs(
          container.name,
          tail: tail,
          follow: nextFollow,
        )
        .listen(
      (chunk) {
        if (isDisposed) return;
        buffer.write(chunk);
        _logs = buffer.toString();
        // 首帧到达即视为加载完成，后续帧持续追加。
        if (_logsLoading) {
          _logsLoading = false;
        }
        notifyListeners();
      },
      onError: (Object error) {
        if (isDisposed) return;
        _logsError = ErrorMessageUtils.userFacingMessage(error);
        _logsLoading = false;
        notifyListeners();
      },
      onDone: () {
        if (isDisposed) return;
        _logsLoading = false;
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  /// 停止跟随，改为一次性回放最近 [tail] 行。
  Future<void> stopFollowing({String tail = '1000'}) async {
    await loadLogs(tail: tail, follow: false);
  }

  Future<void> loadStats() async {
    if (isDisposed) return;

    _statsLoading = true;
    _statsError = null;
    notifyListeners();

    try {
      _stats = await _service.getContainerStats(container.id);
      if (isDisposed) return;
    } catch (e) {
      if (!isDisposed) {
        if (e is NetworkException) {
          _statsError = e.message;
        } else {
          _statsError = ErrorMessageUtils.userFacingMessage(e);
        }
      }
    } finally {
      if (!isDisposed) {
        _statsLoading = false;
        notifyListeners();
      }
    }
  }
}
