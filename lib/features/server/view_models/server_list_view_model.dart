import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_form_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';

class ServerListViewModel extends ChangeNotifier {
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
      });
    });
    // For coach steps, we need context, so we attach listener that captures the current context.
    // However, it's better to just check once or provide a function.
    _serverProvider.addListener(() => _onProviderUpdated(context));
  }

  @override
  void dispose() {
    // We can't easily remove the closure listener, but since this ViewModel is disposed with the page, it's fine.
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

  Future<void> _onProviderUpdated(BuildContext context) async {
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
      final steps = <CoachMarkStep>[];
      if (showAdd) {
        steps.add(
          CoachMarkStep(
            targetKey: addKey,
            title: l10n.coachServerAddTitle,
            description: l10n.coachServerAddDesc,
          ),
        );
      }
      if (showCard && _serverProvider.servers.isNotEmpty) {
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

  Future<void> openAddServer(BuildContext context) async {
    final currentServer = context.read<CurrentServerController>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ServerFormPage()),
    );

    if (result == true) {
      await _serverProvider.load();
      if (context.mounted) {
        await currentServer.refresh();
      }
    }
  }

  Future<void> openDetail(
      BuildContext context, ServerCardViewModel item) async {
    if (!item.isCurrent) {
      await context
          .read<CurrentServerController>()
          .selectServer(item.config.id);
      if (context.mounted) {
        await _serverProvider.load();
      }
    }
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServerDetailPage(server: item),
      ),
    );
  }

  Future<void> deleteServer(
      BuildContext context, ServerCardViewModel item) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.serverDeleteConfirmTitle),
            content: Text(l10n.serverDeleteConfirmMessage(item.config.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    final currentServerController = context.read<CurrentServerController>();
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = l10n.serverDeleteSuccess(item.config.name);

    try {
      await _serverProvider.delete(item.config.id);
      await currentServerController.refresh();
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.serverDeleteFailed(error.toString()))),
      );
    }
  }
}
