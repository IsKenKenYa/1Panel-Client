# KenPanel 多面板基础设施与 Flutter 组件交接

接手对象为负责 Flutter 回归、原生构建及真实面板联调的开发人员。批次编号为 `PANEL-20261121`。升级后需要重新添加服务器。当前可供联调的内置适配器为 1Panel，宝塔的登录、Cookie 和接口行为仍需真实面板确认。[阶段总计划](modules/阶段总计划.md)

本批基于 `dev-v2` 的 `9ae43594` 开发。SDK 环境可使用 `bea7fd5e` 或包含该提交的后续版本，验证面板适配器、共享组件、设置、监控和服务器页面。

## 代码入口

| 工作内容 | 阅读入口 | 接手时需要知道的行为 |
| --- | --- | --- |
| 连接生命周期 | [PanelAdapter](../../lib/data/panels/panel_adapter.dart)、[PanelRegistry](../../lib/data/panels/panel_registry.dart)、[OnePanelAdapter](../../lib/data/panels/one_panel_adapter.dart) | 每个服务器 ID 有独立会话。连接参数变化会替换会话，表单测试另开临时会话。适配器负责鉴权、响应解析、指标及资源释放。 |
| 注册面板界面 | [PanelPresentations](../../lib/features/server/panels/panel_presentation.dart)、[服务器详情](../../lib/features/server/server_detail_page.dart) | 启动时调用 `PanelPresentations.register(adapter, presentation)`。注册信息提供唯一类型、凭据字段和内容构建方法。`loadCapabilities()` 返回当前账户可用的能力名称和 `PanelAccess.read` 或 `PanelAccess.write`。已有 1Panel 模块继续复用各自的 Provider 和仓库。 |
| 保存和编辑服务器 | [ApiConfigManager](../../lib/core/config/api_config.dart)、[ServerRepository](../../lib/features/server/server_repository.dart)、[服务器表单](../../lib/features/server/server_form_page.dart) | 服务器目录与当前 ID 一起保存。普通设置只含元数据，API Key 和附加字段按服务器 ID、类型和地址保存到安全存储。新增首台服务器时自动选中，继续添加时保留当前选择。批量保存按输入顺序返回每项结果。 |
| 原生配置交换 | [原生通道字段](../../lib/core/channel/native_server_config.dart) | SwiftUI 和 WinUI3 通过 Dart 通道读取展示字段和配置版本。SwiftUI 编辑表单提交打开时的 `revision`。提交新地址时需要提供该地址的凭据。 |
| 导航、刷新与后台任务 | [服务器状态](../../lib/features/server/server_provider.dart)、[当前服务器](../../lib/features/shell/controllers/current_server_controller.dart)、[下载任务归属](../../lib/core/services/transfer/one_panel_download_source.dart) | 最多同时刷新四台服务器。列表和详情共用同一配置正在进行的采集，配置修改或删除后会忽略旧响应。下载重试根据任务所属服务器核对目标地址后签名。 |
| Flutter 界面复用 | [共享组件入口](../../lib/shared/widgets/app_widgets.dart)、[自适应服务器列表](../../lib/features/server/widgets/server_list_view.dart) | 通用表单、保存按钮、详情字段、空状态、错误提示与文本预览从共享模块引用。服务器指标、日志来源选择等含业务含义的组件放在对应功能目录。界面只传展示数据和回调。 |
| 工具箱服务器归属 | [按服务器建立 Provider](../../lib/features/toolbox/widgets/toolbox_server_scope.dart)、[读取状态](../../lib/features/toolbox/providers/toolbox_snapshot_provider.dart) | 磁盘、Clam、Fail2ban 和 Supervisor 的 Provider 随服务器切换重新建立，仓库按指定 ID 请求。即使两个服务器上的记录编号相同，操作仍发给打开该工具时选择的服务器。 |

从服务器卡片的更多菜单编辑 B 时，可以继续将 A 作为当前服务器。旧密钥始终隐藏，同地址编辑时可保留；地址改变后需重新填写凭据。保存时使用打开表单时的配置检查并发修改。其他入口已经编辑或删除该服务器时，旧表单会收到错误。

每次保存连接使用新的 `credentialId`。新凭据写入成功后才提交目录，随后移除旧凭据。如果在清理前强制终止应用，安全存储里可能留有目录未引用的条目。接手验证时应重新打开应用，检查目录引用的那组凭据仍可用于该服务器。发生存储异常时，错误会标明目录已提交、保留原配置或需要重新读取。

共享组件可从 `package:onepanel_client/shared/widgets/app_widgets.dart` 导入。搜索框接收输入回调，保存按钮接收 `isSaving` 和提交回调。文件复制和移动、容器创建、证书上传、防火墙规则菜单、虚拟机存储展示分别使用各自模块中的组件。这些模块负责自己的校验、权限及确认步骤。[文件操作](../../lib/features/files/widgets/dialogs/file_operation_dialog.dart) · [容器表单](../../lib/features/containers/dialogs/container_form_fields.dart) · [证书上传](../../lib/features/websites/widgets/website_ssl_upload_dialog.dart)

## Flutter 回归

### MDUI3 Expressive 与窗口尺寸

Flutter 共用一套服务器页面和业务状态。页面从 `AdaptiveLayoutSpec` 读取内容区尺寸，导航壳和分栏通过 `AdaptiveLayoutViewport` 提供本栏宽度。宽度小于 600 dp 时使用手机布局。桌面和浏览器从 1024 dp 起使用桌面布局，宽屏移动设备保留平板交互。服务器卡片按可用宽度与用户字号计算每行数量，内容决定高度。[自适应布局](../../lib/core/layout/adaptive_layout.dart) · [设备与窗口判定](../../lib/ui/routing/ui_target_resolver.dart) · [卡片排列](../../lib/features/server/widgets/server_card_sliver.dart)

明暗主题共用 Material 3 的语义颜色、卡片表面、选中态与操作按钮形状。手机和平板使用标准控件密度，主要按钮最小高度为 48 dp。在业务界面入参相同的情况下，窄栏表单使用可滚动的底部弹层，中等与宽栏使用居中对话框。[应用主题](../../lib/core/theme/app_theme.dart) · [自适应表单](../../lib/shared/widgets/forms/app_form_panel.dart)

| Flutter 验证场景 | 验收操作 |
| --- | --- |
| 手机竖屏与 844 × 390 dp 横屏 | 打开搜索、卡片操作和服务器详情。在较短的窗口打开表单和键盘，滚动到保存或取消按钮。 |
| 600 dp 平板与 280–320 dp 分栏 | 在同一窗口改变业务栏宽度。检查卡片和字段行重新排列，两栏里的表单各自采用适合该栏的展示方式。 |
| 桌面窗口连续调整大小 | 保留已输入的搜索文字及当前模块。窄窗口仍能进入模块，宽窗口可通过侧栏与快捷键切换。 |
| 2 倍字号及浅色、深色主题 | 检查长服务器名、指标、操作菜单、筛选选项、横向滚动和表单按钮。选中标签、进度和错误提示在两种主题下都能辨认。打开长服务器目录和容器编排详情，滚动到最后一项并返回。 |

定向用例包括 [布局尺寸](../../test/core/layout/adaptive_layout_test.dart)、[服务器卡片](../../test/features/server/server_card_sliver_test.dart)、[共用组件](../../test/widget_test/panel_shared_components_test.dart)、[分栏弹层](../../test/bugfix/shared_confirmation_dialog_test.dart) 和 [服务器切换](../../test/widget_test/server_switcher_action_test.dart)。SwiftUI 和 WinUI3 的交互与设备验证列在下表。

核对导航时，在桌面打开一台服务器的数据库详情，通过侧栏进入服务器列表，编辑该服务器并保存，再返回数据库模块。旧连接的业务详情应关闭，服务器列表、全局设置和搜索内容应保留。仅改变窗口大小时，当前业务详情应继续显示。也要检查从服务器详情主动切换到另一台服务器后，详情仍可继续使用。[连接版本与导航用例](../../test/features/shell/server_connection_navigation_test.dart)

### 依赖与命令

在仓库根目录执行。依赖版本见 [pubspec.lock](../../pubspec.lock) 与 [pubspec_overrides.yaml](../../pubspec_overrides.yaml)。锁文件记录的最低版本为 Flutter 3.41.0、Dart 3.9.2。接手环境应能按该文件还原依赖。本次工作机为 Flutter 3.50.1，其 `flutter_test` 固定的 `test_api` 版本与仓库锁文件不同。`dotnet --list-sdks` 返回空列表，默认安装目录未检测到 Visual Studio C++ 桌面工具和 Windows SDK。

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze
dart run test/scripts/test_runner.dart all
```

`all` 依次执行 `unit`、`ui` 和 `integration`。未开启真实 API 时，集成步骤会报告跳过。记录各步骤的通过、失败和跳过数量。可定向执行 `flutter test test/features/server`、`flutter test test/data/panels`、`flutter test test/widget_test/panel_shared_components_test.dart` 定位失败。测试运行器从 PATH 查找 Flutter，也接受 `FLUTTER_BIN` 指定的可执行文件。[测试运行器](../../test/scripts/test_runner.dart)

## 设备与平台验证

| 环境 | 执行命令 | 核对结果 |
| --- | --- | --- |
| Windows Flutter，Visual Studio C++ 桌面开发工具、CMake 和 Windows SDK | `flutter build windows --debug`，`flutter test integration_test/server_connection_storage_test.dart -d windows` | 验证 Windows Flutter 构建、凭据重新打开与删除、加密数据库密钥失效时保留数据、切换和编辑服务器后的文件 API。 |
| Windows 原生宿主，支持 .NET 8 的 SDK | `dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug`，`dotnet test windows/runner/native_host/OnePanelNativeHost.Tests/OnePanelNativeHost.Tests.csproj` | 在 WinUI3 新增和选择服务器，在 Flutter 编辑名称，再重新打开宿主核对列表与当前服务器。 |
| Android、Linux | 在相应主机执行 `flutter build apk --debug`、`flutter build linux --debug` | 在手机和平板尺寸检查同一份服务器列表。Linux 桌面检查侧栏、返回与模块切换。 |
| iOS、iPadOS、macOS | 在 macOS 执行 `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build` 和 `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug build` | 按仓库现有流程准备 CocoaPods。检查 SwiftUI 配置读写、地址变化时的凭据输入、打开旧表单后保存时的版本冲突，以及 Flutter 详情打开对应服务器。 |
| Web | `flutter test --platform chrome test/web/`，`pnpm install --frozen-lockfile`，`pnpm build:web`，`pnpm check:web` | Chrome 的 BrowserVault 用例通过，静态资源可构建，部署命令的 dry-run 成功。真实 CORS 测试需要下一节的编译参数。 |
| HarmonyOS | `hflutter build hap --release`，在设备上保存、重新打开、更新并删除一组测试凭据 | 记录 HAP 路径和设备验证结果。检查 HUKS 失败会向界面报告错误，加密文件保持可用。[HarmonyOS 构建说明](harmonyos_build_and_sideload.md) |

## 使用真实 1Panel

准备两台可区分的授权测试服务器 A、B。浏览器来源需要面板授权 CORS。上传与下载用例会在测试服务器的 `/root` 下新建专用目录，结束时清理该目录。

1. 指标测试从进程环境或仓库测试用的本地 `.env` 读取 `RUN_LIVE_API_TESTS=true`、`PANEL_BASE_URL`、`PANEL_API_KEY`。执行 `flutter test test/bugfix/server_disk_display_bug_test.dart`。检查健康请求成功，延时非负，磁盘使用率在 0% 至 100% 之间。
2. 签名和浏览器文件测试通过 `String.fromEnvironment` 读取编译参数。将 `PANEL_BASE_URL` 与 `PANEL_API_KEY` 放在测试主机的私有 JSON 文件中。下面使用仓库外的相对路径作为示例，执行时填写真实路径。

```sh
flutter test --dart-define-from-file="../private/panel-test.json" test/integration/onepanel_security_live_test.dart
flutter test --platform chrome --dart-define-from-file="../private/panel-test.json" test/web/browser_api_integration_test.dart
```

3. 在同一界面添加 A、B。保存 B 后应继续选中 A。切换过程中刷新卡片，核对显示的 CPU、内存、磁盘和延迟分别属于对应服务器。编辑 B 只变更 B；在表单打开期间从另一入口修改或删除 B，旧表单保存应报告冲突。
4. 在 A 创建下载任务，切换到 B 后重试。重试应使用 A 的凭据；更改 A 的地址后，原任务应提示目标地址已变化。删除选中的 B 后，剩余服务器可以正常使用。
5. 在手机、平板、桌面尺寸各检查一次添加、编辑、搜索、刷新和删除。检查只读能力、未注册面板提示以及保留服务器信息的行为。后两项可结合注册表和详情页用例执行。桌面检查快捷键和内嵌路由，窄屏和放大文字检查保存、复制、取消选择等操作均可触达。
6. 使用两个返回明显不同数据的服务器，在工具箱请求期间切换服务器。新页面只显示所选服务器的数据。首屏读取失败应提供重试，已有内容刷新失败应保留内容。真实验证可使用只读的磁盘概览和服务状态。

## 回写结果

本机已通过改动文件的只读 Dart 语法检查、测试运行器的独立 Dart 静态分析、翻译资源和差异检查。交接文档中的 36 个相对链接均能解析到工作区文件。应用级 `flutter analyze`、Widget 测试、平台构建和真实连接由接手环境执行。

将提交号或所用工作区版本、SDK 版本、平台和设备、实际命令、退出码及首个失败用例写入阶段总计划的 `PANEL-20261121` 条目。各平台通过后附构建产物位置；跳过的真实连接用例单独记录。日志和截图应排除 API Key、附加凭据及签名。[阶段总计划](modules/阶段总计划.md)
