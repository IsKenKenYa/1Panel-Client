import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';

class ServerAwarePageScaffold extends StatelessWidget {
  const ServerAwarePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.requireServer = true,
    this.actions = const [],
    this.floatingActionButton,
    this.bottom,
    this.bottomNavigationBar,
    this.onServerChanged,
  });

  final String title;
  final Widget body;
  final bool requireServer;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;
  final Future<void> Function()? onServerChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentServerController>(
      builder: (context, currentServer, _) {
        final scheme = Theme.of(context).colorScheme;
        final showMissingServer = requireServer && !currentServer.hasServer;
        final canPop = Navigator.of(context).canPop();
        return Scaffold(
          backgroundColor: scheme.surface,
          // 内容从标题栏下滚动穿透；标题栏使用不透明 surfaceContainer。
          // 玻璃标题栏曾在 GLES 上复现 BackdropFilter 采样错位（顶部残影），
          // 导航浮层的玻璃效果由底栏与桌面侧栏承担。
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              AppBar().preferredSize.height + (bottom?.preferredSize.height ?? 0),
            ),
            child: AppBar(
              backgroundColor: UIRenderPolicy.liquidGlassEnabled
                  ? scheme.surfaceContainer
                  : null,
              leading: canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                    )
                  : buildShellDrawerLeading(
                      context,
                      key: const Key('shell-drawer-menu-button'),
                    ),
              title: Text(title),
              actions: [
                if (!showMissingServer) ...actions,
                if (requireServer)
                  ServerSwitcherAction(onChanged: onServerChanged),
              ],
              bottom: bottom,
            ),
          ),
          body: showMissingServer
              ? ColoredBox(
                  color: scheme.surface,
                  child: NoServerSelectedState(moduleName: title),
                )
              : MediaQuery.removePadding(
                  // 让位由下方 Padding 统一负责：Scaffold 在
                  // extendBodyBehindAppBar 下保留状态栏 padding，页面内的
                  // ListView 仍会按 MediaQuery 再让位一次（顶部空白翻倍）。
                  context: context,
                  removeTop: true,
                  child: Padding(
                    // 首屏让位 AppBar（两种模式下 Scaffold 均不再自动避让：
                    // extendBodyBehindAppBar 常开 + md3 也走了 PreferredSize appBar）。
                    // Padding 不裁剪：滚动内容滚出 padding 区后自然穿过标题栏
                    // 后方（标题栏不透明，滚动内容被其覆盖）。
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top +
                          AppBar().preferredSize.height +
                          (bottom?.preferredSize.height ?? 0),
                    ),
                    child: body,
                  ),
                ),
          floatingActionButton: showMissingServer ? null : floatingActionButton,
          bottomNavigationBar: showMissingServer ? null : bottomNavigationBar,
        );
      },
    );
  }
}
