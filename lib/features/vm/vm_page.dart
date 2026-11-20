import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/tabs/vm_overview_tab.dart';
import 'package:onepanel_client/features/vm/tabs/vm_instance_tab.dart';
import 'package:onepanel_client/features/vm/tabs/vm_iso_tab.dart';
import 'package:onepanel_client/features/vm/tabs/vm_template_tab.dart';
import 'package:onepanel_client/features/vm/tabs/vm_network_tab.dart';
import 'package:onepanel_client/features/vm/tabs/vm_storage_tab.dart';
import 'package:onepanel_client/features/vm/widgets/vm_environment_banner.dart';

/// 虚拟机模块页：单页承载六个分区。
///
/// 分区与上游 `/vm/overview`、`/vm/list`、`/vm/isos`、`/vm/templates`、
/// `/vm/networks`、`/vm/storage-pools` 的顶部按钮条一一对应。
/// 运行环境未就绪时不遮罩页面，只在顶部给出逐项状态与启用入口。
class VmPage extends StatefulWidget {
  const VmPage({super.key, this.provider, this.service});

  final VmProvider? provider;
  final dynamic service;

  @override
  State<VmPage> createState() => _VmPageState();
}

class _VmPageState extends State<VmPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnce());
  }

  void _loadOnce() {
    if (_initialized || !mounted) return;
    _initialized = true;
    final provider = context.read<VmProvider>();
    provider.loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<VmProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.vmPageTitle,
          onServerChanged: provider.onServerChanged,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: l10n.commonRefresh,
              onPressed: provider.isMutating ? null : provider.loadAll,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: <Widget>[
              Tab(text: l10n.vmTabOverview),
              Tab(text: l10n.vmTabInstances),
              Tab(text: l10n.vmTabIso),
              Tab(text: l10n.vmTabTemplates),
              Tab(text: l10n.vmTabNetworks),
              Tab(text: l10n.vmTabStorages),
            ],
          ),
          body: Column(
            children: <Widget>[
              if (provider.isMutating)
                const LinearProgressIndicator(minHeight: 2),
              const VmEnvironmentBanner(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const <Widget>[
                    VmOverviewTab(),
                    VmInstanceTab(),
                    VmIsoTab(),
                    VmTemplateTab(),
                    VmNetworkTab(),
                    VmStorageTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
