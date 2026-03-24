import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/terminal_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  bool _loading = false;
  String? _error;
  List<TerminalSessionInfo> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = await ApiClientManager.instance.getTerminalApi();
      final response = await api.getTerminalSessions();
      setState(() {
        _items = response.data ?? [];
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serverModuleTerminal),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: l10n.commonRefresh,
          ),
        ],
      ),
      body: Padding(
        padding: AppDesignTokens.pagePadding,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;

    if (_error != null && _items.isEmpty) {
      return _ErrorView(
        title: l10n.commonLoadFailedTitle,
        error: _error!,
        onRetry: _load,
      );
    }

    if (_loading && _items.isEmpty) {
      return const _LoadingView();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: AppDesignTokens.spacingXl),
                _EmptyView(title: l10n.commonEmpty),
              ],
            )
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDesignTokens.spacingSm),
              itemBuilder: (context, index) {
                final item = _items[index];
                return AppCard(
                  title: item.sessionId ?? '',
                  subtitle: _buildSessionSubtitle(item),
                  child: _buildSessionDetail(item),
                );
              },
            ),
    );
  }

  Widget? _buildSessionSubtitle(TerminalSessionInfo item) {
    if (item.status?.isNotEmpty == true) {
      return Text(item.status!);
    }
    return null;
  }

  Widget? _buildSessionDetail(TerminalSessionInfo item) {
    final parts = <String>[];
    if (item.containerId?.isNotEmpty == true) {
      parts.add(item.containerId!);
    }
    if (item.createTime?.isNotEmpty == true) {
      parts.add(item.createTime!);
    }
    if (item.lastActivityTime?.isNotEmpty == true) {
      parts.add(item.lastActivityTime!);
    }
    if (parts.isEmpty) {
      return null;
    }
    return Text(parts.join(' · '));
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(l10n.commonLoading),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(title),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: AppDesignTokens.spacingMd),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
