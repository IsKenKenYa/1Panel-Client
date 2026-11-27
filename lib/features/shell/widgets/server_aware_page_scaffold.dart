import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
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
    return Selector<CurrentServerController, bool>(
      selector: (_, controller) => requireServer && !controller.hasServer,
      builder: (context, showMissingServer, _) {
        final scheme = Theme.of(context).colorScheme;
        final canPop = Navigator.of(context).canPop();
        // 订阅渲染模式：切换后标题栏底色立即在玻璃与实色之间切换。
        // 控制器尚未载入时退回策略值。
        final settings = context.watch<AppSettingsController?>();
        final glass = settings == null || !settings.loaded
            ? UIRenderPolicy.liquidGlassEnabled
            : UIRenderPolicy.glassEnabledFor(settings.uiRenderMode);
        return Scaffold(
          backgroundColor: scheme.surface,
          // 内容从标题栏下滚动穿透；标题栏在液态玻璃模式使用不透明
          // surfaceContainer。顶栏玻璃化在 GLES 上两条管线均不成立：
          // GlassContainer 走轻量静态快照（几何不变不再重捕获，滚动
          // 内容冻结残影），AdaptiveLiquidGlassLayer 触发 GPU 每帧
          // 数秒的渲染停滞；glass 包 BackdropFilter 路径有采样错位。
          // chrome 玻璃由底栏（GlassTabBar 管线）承担。
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              AppBar().preferredSize.height + (bottom?.preferredSize.height ?? 0),
            ),
            child: AppBar(
              backgroundColor: glass ? scheme.surfaceContainer : null,
              leading: canPop
                  ? const BackButton()
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
