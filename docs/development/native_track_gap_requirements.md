# iOS 与 macOS 原生轨道缺口修复需求

> 本文交给独立线程执行。撰写前已采集仓库真实状态，数字来自实际文件统计。
> 文中标注「待确认」的部分不要凭常识补全。

## 1. 现状基线

### 1.1 通道层（两端共用）

- `ios/Runner/UI/Core/ChannelManager.swift` 88 行，`macos/Runner/UI/Core/ChannelManager.swift` 107 行，均为通用代理，按方法名转发到 Dart。
- Dart 侧 `lib/core/channel/native_channel_manager.dart` 有 209 个读方法，`native_channel_write_handlers.dart` 有 114 个写方法。
- **VM、告警中心、模型下载器在两端都没有通道方法**。`grep VM|Alert|ModelDownloader` 在读写两个 handler 文件里零命中。

### 1.2 iOS 模块覆盖

`ios/Runner/UI/Modules/` 下 14 个目录，合计约 14,000 行。

| 模块 | 文件数 | 行数 | 深度 |
| --- | --- | --- | --- |
| Containers | 11 | 3208 | 详情、文件、Compose 列表、仓库、创建表单、镜像操作、终端 |
| Websites | 7 | 2898 | 列表与配置页 |
| Apps | 5 | 1352 | 商店详情、安装详情、安装表单 |
| AI | 3 | 1392 | 模型列表、创建表单 |
| Files | 3 | 878 | 列表、内容查看 |
| Servers | 5 | 696 | 列表、服务器首页、添加 |
| Databases | 2 | 658 | 列表、详情 |
| Logs | 1 | 642 | 列表 |
| Cronjobs | 1 | 526 | 列表 |
| Security | 2 | 475 | 列表 |
| Settings | 4 | 395 | 设置 |
| Firewall | 2 | 348 | 列表、新增表单 |
| Monitoring | 2 | 269 | 列表 |
| Backups | 1 | 236 | 列表 |

`ModuleRoute` 枚举 10 个 case：containers、websites、apps、monitoring、databases、cronjobs、firewall、backups、ai、logs。

**缺失模块**：虚拟机、告警中心、模型下载器。

**列表型模块缺详情**：Backups、Cronjobs、Logs、Monitoring、Security、Firewall（只有新增表单，无规则编辑与转发分区）。

### 1.3 macOS 模块覆盖

`macos/Runner/UI/Modules/` 下 14 个目录，合计约 4,100 行。

| 模块 | 行数 | 深度 |
| --- | --- | --- |
| Settings | 618 | 设置项 |
| Files | 363 | 列表 |
| Servers | 317 | 列表 |
| Firewall | 308 | 列表 |
| Containers | 276 | 列表 + 日志弹窗 |
| Databases | 201 | 列表 |
| CronJobs | 197 | 列表 |
| Apps | 195 | 列表 |
| Monitoring | 193 | 列表 |
| Dashboard | 186 | 概览 |
| Backups | 178 | 列表 |
| Websites | 178 | 列表 |
| AI | 145 | 列表 |

**全部 14 个模块零详情视图**。`grep -i detail` 在 14 个目录里全部为 0。

侧栏 `SidebarView.swift` 有 13 项：dashboard、monitoring、servers、websites、databases、containers、apps、files、firewall、cronjobs、backups、ai、settings。**日志与安全没有侧栏入口**。

**缺失模块**：虚拟机、告警中心、模型下载器。

**深度缺口**：容器缺详情、文件浏览、Compose 列表、网络与卷分区、终端；网站缺配置中心；数据库缺详情与管理动作；应用缺安装流程。

## 2. 缺口分层

### 第一层：阻断性缺口（功能完全不可达）

1. 虚拟机模块在两端都不可用。Dart 侧 `VMService` 40 端点、单页 6 Tab 已交付，原生无对应视图与通道。
2. 告警中心在两端都不可用。Dart 侧 `AlertService` 15 端点、3 Tab 已交付，原生无通道。
3. 模型下载器在两端都不可用。Dart 侧 `ModelDownloaderService` 15 端点、四分区已交付，原生无通道。

### 第二层：结构缺口（有入口但功能不完整）

4. macOS 全部模块缺详情视图，只能看列表，无法进入单项。
5. macOS 缺日志与安全模块入口。
6. iOS 六个列表型模块缺详情或编辑能力。
7. 两端缺写操作入口，多数模块只能只读浏览。

### 第三层：一致性缺口

8. iOS `ModuleRoute` 10 个 case 与 Dart 侧可直达模块不等，缺 runtime、toolbox、processes、ssh、disk、openresty、group、host assets 等（这些在 Dart 侧经服务器详情「更多」与运维中心进入）。
9. 两端文案走 `TranslationsManager.get(key, fallback:)`，fallback 是英文硬编码。Dart 侧新增的 vm/alert/modelDownloader 文案键需要同步进双语 arb 键表。

## 3. 执行要求

### 3.1 通道扩展顺序

每个新模块按以下顺序实现，每步可独立验证：

1. Dart 读 handler（`native_channel_read_handlers.dart`）：列表、详情、统计
2. Dart 写 handler（`native_channel_write_handlers.dart`）：创建、删除、状态切换
3. 原生 ViewModel：调用通道，持有列表与错误状态
4. 原生 View：列表 + 详情 + 操作确认
5. 入口登记：iOS `ModuleRoute` case、macOS `SidebarView` item
6. 语义一致性 6 项检查

### 3.2 架构约束（强制）

- 原生层只承载 Presentation 与平台能力接入。业务规则、数据加工、错误映射必须在 Dart 侧完成。
- 原生 View 不得直接解析 API 响应结构，只消费 handler 已归一化的数据。
- 禁止在 Swift 里重新实现 Dart 已有的判断逻辑（状态机、权限判定、字段兼容）。
- 新增 handler 必须复用既有 Service/Repository，不得新开数据通路。
- 文件行数上限 1000 行，超出按职责分文件。
- 日志统一走 Dart 侧 `appLogger`，Swift 侧不新建日志体系。

### 3.3 语言与文案

- 新增文案键必须双写 `lib/l10n/app_zh.arb` 与 `app_en.arb`，再执行 `flutter gen-l10n`。
- Swift 侧使用 `translations.get("arbKey", fallback: "English")`，键名与 Dart 一致。
- 中文用词遵守 `AGENTS.md` 的语言条款：使用完整的两字及以上词语，避免互联网行业内部的简写与比喻。

### 3.4 验收门禁

每个模块交付后必须给出以下结果：

| 门禁 | 命令 |
| --- | --- |
| 静态分析 | `flutter analyze`（0 error） |
| 单元测试 | `dart run test/scripts/test_runner.dart unit` |
| 界面测试 | `dart run test/scripts/test_runner.dart ui` |
| iOS 构建 | `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build` |
| macOS 构建 | `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug build` |

iOS 构建的 destination 不写具体模拟器型号。机型名随 Xcode 版本变化，写死会在找不到设备时直接退出。

### 3.5 语义一致性检查（每个模块必检）

- 入口语义一致：模块入口位置与导航层级与 Dart 轨道一致
- 主流程一致：创建、编辑、删除、批量操作行为一致
- 错误反馈一致：失败提示文案与重试路径一致
- 权限与危险操作一致：二次确认与权限提示一致
- 国际化一致：中英文文案来源一致
- 无跨层调用：原生 View 不得直连 API
- 无障碍三类检查：语义标签、触控目标 ≥ 48x48、对比度与焦点指示

## 4. 建议批次划分

### 批次一：虚拟机（iOS）

- 通道：环境探测、实例列表、详情、电源操作、ISO、模板、网络、存储池、快照、监控采样
- 视图：单页分区（对应 Dart 六 Tab 的顺序）+ 实例详情 + 电源操作确认 + 监控折线
- 验收：在真实 1Panel v2.5.1 面板上完成启动、停止、重启、快照各一次

### 批次二：虚拟机（macOS）

- 复用批次一的通道与 ViewModel 结构，视图按 macOS HIG 用 `NavigationSplitView` 三段式
- 验收：同上，另加窗口缩放到最窄宽度不溢出

### 批次三：告警中心（两端）

- 通道：任务列表与创建、日志列表与清空、六类渠道读写与测试
- 视图：三 Tab（任务/日志/渠道）+ 渠道表单（含自定义 Webhook 的 Body 与 Header 编辑器）
- 验收：创建一条磁盘告警并触发一次，确认日志出现

### 批次四：模型下载器（两端）

- 通道：推荐模型、搜索、任务、本地模型、设置
- 视图：四分区 + 设置抽屉
- 验收：发起一次小模型下载并完成

### 批次五：macOS 详情补齐（按使用频率排序）

- 顺序：Containers（详情、文件、Compose、网络、卷、终端）→ Websites（配置中心）→ Databases（详情与管理）→ Apps（安装流程）→ Files（内容查看与编辑）
- 验收：每个模块至少一条完整主流程走通

### 批次六：iOS 列表型模块补详情

- 顺序：Firewall（规则编辑、转发分区、Docker 分区、设置）→ Monitoring（图表与设置）→ Cronjobs（创建与执行记录）→ Backups → Logs（筛选与跟随）→ Security
- 验收：同批次五

### 批次七：入口与文案一致性

- iOS `ModuleRoute` 补 runtime、toolbox、processes、ssh、disk、openresty、group、host assets
- macOS 侧栏补日志与安全
- 两端文案键与 Dart arb 保持一致，fallback 与中文文案相同

## 5. MDUI3 轨道的 M3 Expressive 剩余工作

原生轨道之外，Dart 侧还有以下 M3E 待办，可与原生批次并行：

| 范围 | 现状 | 待办 |
| --- | --- | --- |
| `lib/features/monitoring/monitoring_page.dart` | `SectionCard` 0 处 | 迁移到分区卡片 + `ExpressiveRow` |
| `lib/features/databases/databases_detail_page.dart` | `SectionCard` 0 处 | 同上 |
| `lib/features/databases/databases_page.dart` | `SectionCard` 0 处 | 同上 |
| 全仓硬编码内边距 | `EdgeInsets.all(16)` 202 处 | 替换为 `AppDesignTokens.cardPadding`（值同为 16） |
| 动效 | `motionEmphasized` 3 处调用 | 按需补充页面切换与列表项出现动效，不做无意义堆砌 |

替换内边距时逐处确认语义。部分位置的 16 是图片内边距或控件内边距，与卡片内边距不同名不同义，直接替换会改变视觉。

## 6. 不要做的事

- 不要为原生轨道复制 Dart 业务逻辑。原生只做展示与交互。
- 不要新增第二套状态管理。原生 ViewModel 只持有展示状态。
- 不要改 `docs/OpenSource/1Panel/**`。
- 不要在原生层直接拼 API 路径或签名。
- 不要用固定宽度 `SizedBox(width >= 300)`，用 `AdaptiveLayoutSpec.dialogConstraints`。
- 不要写死模拟器机型名。
- 不要提交密钥、API Key、测试主机的地址与凭据。

## 7. 参考实现

- iOS 深度参照：`ios/Runner/UI/Modules/Containers/`（11 文件，含详情、文件、Compose、终端）
- macOS 结构参照：`macos/Runner/UI/Modules/Shell/MainShellView.swift` 与 `SidebarView.swift`
- Dart 业务参照：`lib/features/vm/vm_page.dart`（六 Tab）、`lib/features/alert/alert_page.dart`（三 Tab）、`lib/features/ai/widgets/model_downloader_sections.dart`
- Dart 通道参照：`native_channel_read_handlers.dart` 的 `getContainers`、`native_channel_write_handlers.dart` 的容器操作