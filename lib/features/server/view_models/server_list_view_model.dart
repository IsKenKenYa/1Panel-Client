import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';

class ServerListViewModel extends ChangeNotifier with SafeChangeNotifier {
  ServerListViewModel({
    this.enableCoach = true,
    required ServerProvider serverProvider,
  }) : _serverProvider = serverProvider {
    _searchController.addListener(_onSearchChanged);
  }

  final bool enableCoach;
  final ServerProvider _serverProvider;
  final TextEditingController _searchController = TextEditingController();
  final OnboardingService _onboardingService = OnboardingService();
  String _query = '';
  bool _visible = false;
  bool _checkingCoach = false;
  bool _checkedCoach = false;
  bool _openingDetail = false;

  final GlobalKey addKey = GlobalKey();
  final GlobalKey firstCardKey = GlobalKey();

  List<CoachMarkStep> coachSteps = const [];

  TextEditingController get searchController => _searchController;
  String get query => _query;

  void setVisible(BuildContext context, bool visible) {
    _visible = visible;
    _serverProvider.setPageVisible(this, visible);
    if (visible && enableCoach && !_checkedCoach && !_checkingCoach) {
      unawaited(_checkCoach(context));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (_query == query) return;
    _query = query;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      if (!_serverProvider.hasDirectory ||
          _serverProvider.directoryError != null) {
        await _serverProvider.load();
      } else {
        await _serverProvider.loadMetrics();
      }
    } catch (_) {
      // 目录读取错误由列表的错误状态和重试按钮展示。
      if (_serverProvider.directoryError == null) rethrow;
    }
  }

  Future<void> _checkCoach(BuildContext context) async {
    _checkingCoach = true;
    try {
      if (!_serverProvider.hasDirectory) await refresh();
      if (!_visible || !context.mounted || !_serverProvider.hasDirectory) {
        return;
      }
      final hasServers = _serverProvider.configs.isNotEmpty;
      final show = await _onboardingService.shouldShowCoach(hasServers
          ? OnboardingService.coachServerCardKey
          : OnboardingService.coachServerAddKey);
      if (!_visible || !context.mounted) return;
      _checkedCoach = true;
      if (!show) return;
      final l10n = context.l10n;
      coachSteps = [
        CoachMarkStep(
          targetKey: hasServers ? firstCardKey : addKey,
          title:
              hasServers ? l10n.coachServerCardTitle : l10n.coachServerAddTitle,
          description:
              hasServers ? l10n.coachServerCardDesc : l10n.coachServerAddDesc,
        ),
      ];
      notifyListeners();
    } finally {
      _checkingCoach = false;
    }
  }

  Future<void> completeCoach() async {
    await _onboardingService.completeCoach(OnboardingService.coachServerAddKey);
    await _onboardingService
        .completeCoach(OnboardingService.coachServerCardKey);
    coachSteps = const [];
    notifyListeners();
  }

  Future<void> openDetail(BuildContext context, ApiConfig config) async {
    if (_openingDetail) return;
    _openingDetail = true;
    try {
      final controller = context.read<CurrentServerController>();
      if (controller.currentServerId != config.id) {
        try {
          await controller.selectServer(config.id);
        } catch (error) {
          if (context.mounted && _visible) {
            SnackBarUtils.showError(
                context, ErrorMessageUtils.userFacingMessage(error));
          }
          return;
        }
      }
      if (!context.mounted ||
          !_visible ||
          controller.currentServerId != config.id) {
        return;
      }
      await openRouteRespectingShell<void>(
        context,
        AppRoutes.serverDetail,
        arguments: config,
      );
    } finally {
      _openingDetail = false;
    }
  }
}
