import 'dart:async';

import 'package:flutter/services.dart';

class HarmonyEntryPresentation {
  HarmonyEntryPresentation(this._channel);

  final MethodChannel _channel;
  bool enabled = false;
  Object? _owner;
  String? _page;
  FutureOr<void> Function(String)? _onAction;

  Future<bool> show(
    Object owner,
    String page, {
    String title = '',
    String message = '',
    bool requireConsent = false,
    FutureOr<void> Function(String)? onAction,
  }) async {
    if (!enabled) return false;
    _owner = owner;
    _page = page;
    _onAction = onAction;
    return await _channel.invokeMethod<bool>('setEntryPresentation', {
          'page': page,
          'title': title,
          'message': message,
          'requireConsent': requireConsent,
        }) ??
        false;
  }

  Future<void> dismiss(Object owner) async {
    if (!identical(owner, _owner)) return;
    _owner = null;
    _page = null;
    _onAction = null;
    await _channel.invokeMethod<bool>('setEntryPresentation', {'page': ''});
  }

  Future<void> handleAction(String page, String action) async {
    if (enabled && page == _page) await _onAction?.call(action);
  }
}
