# 原生 UI 批量适配工作流

> **适用范围**：iOS / macOS / Windows / HarmonyOS 原生 UI 轨道的新模块接入、操作补齐与走查验证。
> **配套文档**：`AGENTS.md`（硬性规则）、`docs/development/cross_platform_ui_governance.md`（跨平台治理总纲）、`docs/development/modules/阶段总计划.md`（批次台账）。
>
> **核心命题**：所有平台的原生 UI 只是"共享 Dart 业务核心"之上的不同展示层——通道契约、模块清单、状态规范、验证流程完全一致，平台差异只在控件与交互 idiom。因此适配一个新平台 = 复用同一份通道契约与模块清单，替换展示层实现，跑同一套验证闭环。

---

## 一、架构分层（所有平台一致）

```
Presentation（原生 UI：SwiftUI / WinUI3 / ArkUI）
    │  只做展示 + 交互，经 Native Channel 取数/写操作
    ▼
Native Channel（Dart：native_channel_manager → read/write_handlers）
    │  读：getXxx；写：addXxx / deleteXxx / toggleXxx …；返回 {success, error?}
    ▼
Service / Repository（Dart 业务规则）
    ▼
API v2（1Panel RestAPI）
```

约束：

- 原生层禁止直连 API，禁止复制业务逻辑。
- 新增能力先补通道（Dart），再写原生展示。
- 通道返回统一 `{success: bool}` / `{success: false, error: String}`；列表接口返回 `List<Map<String, dynamic>>`。

---

## 二、模块接入清单（每个平台按此表逐项打勾）

### 2.1 壳层（Shell）

| 项 | 要求 |
|----|------|
| Tab / 导航结构 | 与 MDUI3 iPhone 壳语义一致（服务器/文件/安全/设置 4 tab 或平台等价结构） |
| 每 tab 导航容器 | iOS `NavigationStack`；macOS `NavigationSplitView`；Windows `NavigationView`；HarmonyOS `Navigation` |
| 系统材质 | Apple 平台依赖系统 Liquid Glass（OS 26+ 自动），禁止叠加自定义视觉材质 |
| 模块入口 | 业务模块从服务器首页进入（容器/网站/应用/监控），与 MDUI3 层级一致 |

### 2.2 数据模块（按通道能力）

| 模块 | 读通道 | 写通道 | 行级操作 |
|------|--------|--------|----------|
| 服务器 | getServers | addServer / updateServer / deleteServer / connectServer | 新增/编辑/删除/切换 |
| 文件 | getFiles{path} | createFolder / renameFile / deleteFile | 新建文件夹/重命名/删除/目录钻取/搜索 |
| 容器 | getContainers | toggleContainerState / restartContainer / deleteContainer | 启停/重启/删除 |
| 应用 | getApps（含 installId） / getAppStore / getAppVersions / getAppInstallForm | installApp / startApp / stopApp / updateApp / uninstallApp | 启停/更新/卸载/商店搜索/安装 |
| 网站 | getWebsites / getWebsiteDetail / getWebsiteCreateOptions（分组、PHP 运行环境、父站点） | createWebsite / toggleWebsiteStatus / deleteWebsite | 启停/删除/创建（四种类型表单）/详情（站点信息与域名）；建站请求必须携带 `appType`（服务端校验 new 或 installed） |
| 监控 | getMonitoring / getDashboard | — | 只读 |
| 数据库 | getDatabases（多 scope 合并） | — | 只读列表（名称/类型/版本/状态） |
| 计划任务 | getCronJobs | toggleCronJobStatus / deleteCronJob | 启停/删除 |
| 防火墙 | getFirewallRules | deleteFirewallRule（新增规则通道已存在，页面待接） | 删除 |
| 备份 | getBackups | deleteBackup | 删除 |
| AI | getAIModels | deleteAIModel | 删除 |
| 容器详情 | getContainers / getContainerInspect{name} | toggleContainerState / restartContainer / deleteContainer | 信息（inspect JSON）/ 日志 两个分栏；日志响应 envelope 由 `ContainerService` 统一解包（`data:null` 表示无 stdout 日志） |

### 2.3 交互与反馈规范

| 层 | 规范 |
|----|------|
| L1 瞬态反馈 | 操作成功/失败 → Toast（macOS/iOS 用临时浮层胶囊；Windows InfoBar；鸿蒙 promptAction） |
| L2 首屏阻塞 | 空数据+加载失败 → 整页错误态 + 重试按钮 |
| L3 有缓存失败 | 保留已有数据 + 顶部/Toast 提示 |
| 危险操作 | 二次确认（iOS confirmationDialog；macOS alert；Windows ContentDialog；鸿蒙 AlertDialog） |
| 桌面右键等价 | 列表项提供 contextMenu（桌面）与滑动手势（移动）双通道 |
| 触控目标 | 移动端 ≥44/48pt；桌面端密度可 compact |

### 2.4 本地化

- 所有文案键必须存在于 `lib/l10n/app_zh.arb` + `app_en.arb`（驼峰命名），经 `getTranslations` 通道下发。
- 禁止在原生代码里造不存在的 key；缺失先补 ARB 再 gen-l10n。
- 含占位符的文案（如 `{name}`）在原生侧做字符串替换。

---

## 三、验证闭环（每批次必跑）

### 3.1 构建门禁

| 平台 | 命令 |
|------|------|
| iOS | `flutter build ios --simulator --debug`（或 Xcode：打开 `Runner.xcworkspace`，scheme Runner） |
| macOS | `flutter build macos --debug` |
| Windows | `dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug` |
| HarmonyOS | `hflutter build hap --release` |
| 共享 Dart | `flutter analyze`（0 error）+ `dart run test/scripts/test_runner.dart unit` |

### 3.2 运行时走查（模拟器/设备）

统一用**启动参数测试钩子**驱动页面，不依赖点击自动化：

| 钩子 | 平台 | 作用 |
|------|------|------|
| `ONEPANEL_INITIAL_TAB`（iOS 环境变量） | iOS simctl | 选初始 tab：servers/files/security/settings |
| `ONEPANEL_OPEN_SERVER_HOME` | iOS simctl | 打开当前服务器首页（列表 → 首页层级） |
| `ONEPANEL_OPEN_MODULE` | iOS simctl | 按真实层级入栈：列表 → 服务器首页 → 模块页（containers/websites/apps/monitoring）；`files` 切到文件 tab |
| `ONEPANEL_OPEN_SETTINGS_PAGE` | iOS simctl | 设置 tab 内直接进入子页：about / legal |
| `ONEPANEL_SEED_SERVER_URL` / `ONEPANEL_SEED_API_KEY` | iOS simctl（原生转发）；Android/桌面可用 `--dart-define` | 调试构建写入服务器与 API Key（原生壳经 `seedDebugConfig` 通道转发，仅调试生效） |
| `ONEPANEL_FORCE_SEMANTICS=true`（dart-define） | Android 调试构建 | 强制开启 Flutter 语义树，便于自动化工具读取界面 |
| `ONEPANEL_OPEN_ADD_SERVER` | iOS simctl | 自动打开添加服务器表单 |
| `ONEPANEL_OPEN_CONTAINER_LOGS=<容器名>` | iOS simctl | 直接打开容器详情页（`ONEPANEL_CONTAINER_TAB=logs|info` 选择初始分栏） |

iOS 走查命令模板：

```bash
export DEVELOPER_DIR=/Volumes/FanXiangMac/Applications/Xcode.app/Contents/Developer
UDID=<device-udid>
xcrun simctl install $UDID build/ios/iphonesimulator/Runner.app
SIMCTL_CHILD_ONEPANEL_OPEN_MODULE=containers xcrun simctl launch $UDID com.iskenkenya.onepanel
sleep 8~20   # 远距离面板给足网络时间
xcrun simctl io $UDID screenshot .dart_tool/native_ui_batch/shots/<name>.png
```

其他平台的等价机制：Android intent extra、Windows launch args、鸿蒙 want 参数——命名保持 `ONEPANEL_*` 前缀一致。

### 3.3 走查检查表（每页）

- [ ] 标题 / 导航层级正确，返回语义正确
- [ ] 空态（图标+标题+描述）与 L2 错误态均可渲染
- [ ] 真实数据渲染（徽章语义色、指标、列表）
- [ ] 行级操作入口存在（滑动/右键/菜单）
- [ ] 危险操作有二次确认
- [ ] 中英文文案来自 ARB
- [ ] 深色模式无对比问题

### 3.4 证据与台账

- 截图落盘 `.dart_tool/native_ui_batch/shots/`（gitignored），命名 `<platform>-<序号>-<页面>.png`。
- 每批次在 `阶段总计划.md` 追加条目：状态、能力边界、实际交付、执行证据（命令+结果+截图名）、验证范围（未覆盖项）。
- 覆盖矩阵以下表为准，逐平台勾选：

| 能力 | iOS | macOS | Windows | HarmonyOS |
|------|-----|-------|---------|-----------|
| 服务器 CRUD+切换 | ✅ | ✅（新增/编辑/删除/切换） | 待适配 | 待适配 |
| 文件操作 | ✅（新建/重命名/删除/搜索/钻取） | ✅（新建/重命名/删除/钻取，搜索待补） | 待适配 | 待适配 |
| 容器 3 操作 | ✅ | ✅（右键菜单启停/重启/删除） | 待适配 | 待适配 |
| 容器详情 | ✅（点击行进入，信息 inspect JSON / 日志分栏） | ✅（右键菜单 sheet，等宽文本/空态/刷新） | 待适配 | 待适配 |
| 应用 3 操作 | ✅（启停/更新/卸载/商店安装） | ✅（右键菜单启停/卸载） | 待适配 | 待适配 |
| 网站 3 操作 | ✅（启停/删除/创建，四种类型表单/详情页） | ✅（右键菜单启停/删除） | 待适配 | 待适配 |
| 监控指标 | ✅（真实数据） | ✅ | 待适配 | 待适配 |
| 数据库 / 计划任务 / 防火墙 / 备份 / AI 列表 | ✅（五个模块，含启停或删除） | 待适配 | 待适配 | 待适配 |
| 应用锁 | ✅（LAContext） | Toggle（无门禁） | 待适配 | 待适配 |

> 本表随批次更新；`待适配` 由后续批次按第二节清单补齐。

---

## 四、单批次执行流程（标准 8 步）

1. **盘点**：对照第二节清单，列出目标平台缺的通道/操作/页面。
2. **补通道**（如有缺口）：`native_channel_write_handlers.dart` + `native_channel_manager.dart` 分发，纯增量、返回 `{success}`。
3. **写 ViewModel**：通道调用 + 状态（isLoading/error）+ 完成回调。
4. **写 View**：行级操作（滑动/右键/菜单）+ 确认框 + Toast + 列表刷新。
5. **构建门禁**：平台构建命令 + `flutter analyze`。
6. **运行时走查**：测试钩子逐页截图，对照 3.3 检查表。
7. **修复**：走查发现的问题当轮修复、重构建重走查。
8. **台账回写**：`阶段总计划.md` 条目 + 覆盖矩阵更新。

### 常见陷阱

- **Flutter 插件 pod 布局**：`Pods/` 下没有插件源码目录属正常（开发模式 pod 走 `.symlinks` 引用 pub 缓存）。
- **Xcode 打开方式**：必须 `.xcworkspace`，直接开 `.xcodeproj` 必报 `Module not found`。
- **模拟器一次只开一台**（16GB 内存约束）；CoreSimulator 报 `Cannot allocate memory` 且杀 XPC 无效时重启系统。
- **远距离面板**（如美国主机）：列表加载给 20s 级等待再截图，避免误判为卡死。
- **列表合并卡片**：iOS insetGrouped 相邻行合并为单卡是系统规范，与 MDUI3 独立卡片不同属正常平台差异。

---

## 五、平台差异速查

| 维度 | iOS | macOS | Windows | HarmonyOS |
|------|-----|-------|---------|-----------|
| 导航 | TabView + NavigationStack | NavigationSplitView + Sidebar | NavigationView + Frame | Navigation + Tabs |
| 危险确认 | confirmationDialog | alert / confirmationDialog | ContentDialog | AlertDialog |
| 轻提示 | 临时胶囊浮层 | 临时胶囊浮层 | InfoBar | promptAction |
| 左滑/右键 | swipeActions | contextMenu | contextMenu + Flyout | swipeAction + bindContextMenu |
| 密度 | standard | compact（鼠标） | compact | standard |
| 图标体系 | SF Symbols | SF Symbols | Segoe Fluent Icons | HarmonyOS Symbol |
| 系统材质 | Liquid Glass（OS 26+） | Liquid Glass（OS 26+） | Mica / Acrylic | 系统模糊 |

---

**文档版本**: 1.0  
**最后更新**: 2026-11-17  
**维护者**: Open1PanelApp 协作代理
