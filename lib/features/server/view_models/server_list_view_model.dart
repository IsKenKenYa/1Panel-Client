import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';

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

  final GlobalKey addKey = GlobalKey();
  final GlobalKey firstCardKey = GlobalKey();

  List<CoachMarkStep> coachSteps = const [];

  TextEditingController get searchController => _searchController;
  ServerProvider get serverProvider => _serverProvider;

  void init(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serverProvider.load().then((_) {
        if (_serverProvider.servers.isNotEmpty) {
          _serverProvider.loadMetrics();
        }
        if (!context.mounted) {
          return;
        }
        // Check coach marks after initial load
        checkAndShowCoachMarks(context);
      });
    });
    // Add listener but prevent recursive updates
    _serverProvider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    // Just notify listeners without triggering coach marks
    // Coach marks will be shown only on initial load
    notifyListeners();
  }

  @override
  void dispose() {
    _serverProvider.removeListener(_onProviderChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    notifyListeners();
  }

  List<ServerCardViewModel> get filteredServers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _serverProvider.servers;
    }
    return _serverProvider.servers.where((item) {
      return item.config.name.toLowerCase().contains(query) ||
          item.config.url.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> refresh() async {
    await _serverProvider.load();
    if (_serverProvider.servers.isNotEmpty) {
      await _serverProvider.loadMetrics();
    }
  }

  Future<void> checkAndShowCoachMarks(BuildContext context) async {
    if (!enableCoach) return;
    if (coachSteps.isNotEmpty) return;

    final showAdd = await _onboardingService
        .shouldShowCoach(OnboardingService.coachServerAddKey);
    final showCard = await _onboardingService
        .shouldShowCoach(OnboardingService.coachServerCardKey);

    if (!context.mounted || (!showAdd && !showCard)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final l10n = context.l10n;
      final hasServers = _serverProvider.servers.isNotEmpty;
      final steps = <CoachMarkStep>[];
      // 「先添加第一台服务器」仅在确实没有服务器时展示；
      // 已有服务器时引导卡片操作，文案与场景保持一致。
      if (showAdd && !hasServers) {
        steps.add(
          CoachMarkStep(
            targetKey: addKey,
            title: l10n.coachServerAddTitle,
            description: l10n.coachServerAddDesc,
          ),
        );
      }
      if (showCard && hasServers) {
        steps.add(
          CoachMarkStep(
            targetKey: firstCardKey,
            title: l10n.coachServerCardTitle,
            description: l10n.coachServerCardDesc,
          ),
        );
      }

      coachSteps = steps;
      notifyListeners();
    });
  }

  Future<void> completeCoach() async {
    await _onboardingService.completeCoach(OnboardingService.coachServerAddKey);
    await _onboardingService
        .completeCoach(OnboardingService.coachServerCardKey);
    coachSteps = const [];
    notifyListeners();
  }

  Future<void> openDetail(
      BuildContext context, ServerCardViewModel item) async {
    // 切换服务器会重建带 serverId key 的模块子树，原卡片 context 随之卸载；
    // 先取 NavigatorState，切换完成后仍能压入详情页。
    final navigator = Navigator.of(context);
    if (!item.isCurrent) {
      await context
          .read<CurrentServerController>()
          .selectServer(item.config.id);
      if (context.mounted) {
        await _serverProvider.load();
      }
    }

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => ServerDetailPage(server: item),
      ),
    );
  }

  /// 删除服务器配置（纯数据操作）：确认弹窗与结果反馈由 UI 层负责。
  Future<void> deleteServer(ServerCardViewModel item) async {
    await _serverProvider.delete(item.config.id);
  }

  /// 服务器新增/删除/切换后的统一列表刷新。
  Future<void> refreshAfterServerChange() async {
    await _serverProvider.load();
  }
}
