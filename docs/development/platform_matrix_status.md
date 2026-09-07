# 平台矩阵状态

本文件记录各平台当前的功能覆盖与构建状态。

---

## 功能矩阵

| 平台 | UI 模式 | 导航 | 数据渲染 | 交互 | 构建状态 |
|------|---------|------|----------|------|----------|
| Android | MDUI3 | 已完成 | 已完成 | 已完成 | 已完成 |
| iOS | Native/MDUI3 | 已完成 | 已完成（只读） | 部分完成 | 待 xcodebuild 验证 |
| macOS | Native/MDUI3 | 已完成 | 已完成 | 部分完成 | 待 xcodebuild 验证 |
| Windows | Native/MDUI3 双模式 | 已完成（单例页面直赋，导航 21 项） | 已完成（21 页（+ScriptLibraryPage）） | 已完成（CRUD） | 已完成（dotnet build 0 错误 + xUnit 26/26） |
| Linux | MDUI3 | 已完成 | 已完成 | 已完成 | 已完成 |
| HarmonyOS | 占位 | 占位 | 占位 | 占位 | 未启动 |

## 状态说明

- **已完成**：功能已实现并通过测试门禁。
- **部分完成**：核心功能已实现，部分高级交互待补充。
- **已完成（只读）**：数据展示已实现，写入操作待后续迭代。
- **已完成（首批）**：首批模块已实现，后续模块持续接入中。
- **待验证**：代码已就绪，需在对应平台环境执行构建门禁。
- **占位**：路由/通道/Provider 占位已建立，原生实施按里程碑推进。
- **未启动**：尚未进入开发阶段。

## Windows 原生轨道补充说明（2026-09-07）

- 宿主：`OnePanelNativeHost`（WindowsAppSDK 2.4.0 stable、WindowsAppSDKSelfContained、win-x64、unpackaged），进程内经胶水 DLL `flutter_headless_host` 运行无 view headless Flutter 引擎。
- 通道：`com.onepanel.client/method`（与 iOS/macOS 同源），方法集对齐 Dart `NativeChannelManager`；`StandardMethodCodec` golden 向量双向锁定。
- 导航：单例页面 + `Frame.Content` 直赋（本环境 `Frame.Navigate` 存在 native AV 缺陷，详见 `windows_native_architecture.md`「环境约束与规避」）。
- 导航覆盖 10 项：Dashboard / Monitoring 已接入（Phase 3 第一组）；时间序列图表属后续批次。
- 底衬：官方 SystemBackdrop API（Mica Base / MicaAlt / DesktopAcrylic / None）+ LocalSettings 持久化。
- 端到端冒烟：启动 `OnePanelNativeHost.exe` → ServersPage 渲染真实服务器列表。
- 数据库模块（B11）已接入：列表（跨 mysql/postgresql/mongodb/redis/remote scope 合并）、新建（本地/远程两形态）、删除、描述与密码改写；导航 11 项。
- 定时任务模块（B12）已接入：任务列表（含上次/下次执行预览）、新建/编辑（shell 类型最小集）、启停、删除、立即执行；导航 12 项。
- 备份模块（B13）已接入：备份记录列表（含恢复上下文字段）、恢复（危险确认）、删除（危险确认）；下载到本地属桌面交互后续批次；导航 13 项。
- AI 模块扩展（B14）已接入：模型创建（拉取）/重建/删除生命周期；AI 域名绑定需 appInstallID 发现流属后续批次；导航项数不变（AI 已在第 10 项）。
- 主机与工具箱模块（B15）已接入：SSH 状态/服务操作/配置编辑、设备快照卡、DNS 校验；Terminal（websocket 双向）登记范围外；导航 15 项。
- 日志与 OpenResty 模块（B16）已接入：操作/登录/系统日志只读三页签、OpenResty 快照与配置源保存；Processes/Terminal 走 websocket 登记范围外；导航 17 项。
- 命令库与 AI 发现流（B17）已接入：命令库 CRUD、分组下拉、getOllamaContext 发现流消费与域名绑定表单；导航 18 项。
- 编排与安全网关模块（B18）已接入：Compose 列表与六动作操作、面板 SSL/网站证书/OpenResty 状态只读聚合；Compose 创建/编辑与网关写操作属后续批次；导航 20 项。
- Compose 建/改与网关开关（B19）已接入：编排新建（path/raw 两形态）与配置全量替换编辑、OpenResty 默认 HTTPS 跳转开关；导航项数不变。
- 脚本库模块（B20）已接入：脚本只读列表与批量删除（系统脚本保护）；脚本运行/同步走脚本执行通道属范围外；onboarding（引导覆盖层）/operations_center（聚合页无独立数据源）评估为范围外；导航 21 项。

## 构建门禁命令

| 平台 | 命令 |
|------|------|
| Flutter 通用 | `flutter analyze && flutter test` |
| Windows 原生 | `dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug` |
| Windows 原生测试 | `dotnet test windows/runner/native_host/OnePanelNativeHost.Tests/OnePanelNativeHost.Tests.csproj -c Debug` |
| iOS 原生 | `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build` |
| macOS 原生 | `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug build` |

> 最后更新：2026-09-07
