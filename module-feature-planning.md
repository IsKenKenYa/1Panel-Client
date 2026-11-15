# 模块适配功能规划报告

> **基线**：基于 `docs/OpenSource/1Panel` 前端代码 + swagger.json 调研 87 个 missing_in_client 端点
> **方法论**：接口 ≠ 功能 ≠ UI 页面。本报告按「功能」而非「接口」组织，区分假阳性 / 路径修复 / 真缺失
> **生成时间**：2026-07-10
> **依据**：`AGENTS.md`「模块能力设计必须参考 1Panel Web 前端行为与交互语义，在客户端完成高保真功能还原」
> **当前快照**：`v2.5.1`（2026-11-15 更新，810 paths）；本轮新增功能与验证证据见 `docs/development/modules/阶段总计划.md` B9，本文保留历史规划背景。

---

## 一、调研结论总览

### 1.1 87 个 missing 端点的真实分类

经对照 1Panel 前端 `frontend/src/views/` + `frontend/src/api/modules/` 逐端点调研，87 个 missing 端点重新分类如下：

| 分类 | 数量 | 占比 | 说明 |
|---|---|---|---|
| **假阳性**（客户端已实现，coverage 误报） | **17** | 19.5% | 路径归一化差异 / Repository 层直接调用 / 跨模块实现 |
| **路径 Bug**（客户端路径或方法错误，改一行即可） | **9** | 10.3% | 客户端路径与 Swagger/前端不一致，导致 404/405 |
| **契约路径迁移**（客户端已实现，路径需迁移） | **10** | 11.5% | ai accounts 系列从 /ai/agents/accounts/* → /ai/accounts/* |
| **localhost-only 内部端点**（不适用客户端） | **1** | 1.1% | /core/settings/ssl/reload 仅 localhost 可调 |
| **已用替代方案覆盖** | **1** | 1.1% | command upload 已用本地 CSV 解析替代 |
| **真缺失需新功能开发** | **49** | 56.3% | 需按功能组规划，非按接口逐一开发 |

### 1.2 重新校准的覆盖率

| 维度 | 原报告 | 校准后 |
|---|---|---|
| 缺失端点数 | 87（去重 70） | 真缺失 49（去重后约 40 个功能点） |
| 客户端覆盖率 | 90.3% | **93.2%**（扣除 17 假阳性 + 1 内部 + 1 替代） |
| P0 阻断项 | ai 39 + host 18 | **ai 删除检查 1 + setting ssh/default 路径 1** |

**关键发现**：原报告将 ai 39 + host 18 列为 P0 阻断项过度悲观。实际上：
- host 18 个中 **10 个是假阳性**（/core/hosts/* 已实现，coverage 工具路径归一化未识别）
- ai 39 个中 **10 个是契约路径迁移**（客户端已实现，仅需改路径字符串）
- 真正的 P0 阻断项只有 2 个：`ai/agents/delete/check`（删除前资源检查）+ `settings/ssh/default`（路径 Bug）

---

## 二、假阳性清单（17 个，无需开发）

这些端点客户端已实现，coverage 工具因路径归一化或检查范围限制误报。

| 模块 | 端点 | 客户端实现位置 | 误报原因 |
|---|---|---|---|
| host | POST /hosts, /hosts/del, /hosts/info, /hosts/search, /hosts/tree, /hosts/update, /hosts/update/group, /hosts/test/byinfo（8 个） | `lib/api/v2/host_v2.dart`（primaryPath=/core/hosts/*, legacyPath=/hosts/*） | coverage 仅匹配 /hosts/* 未识别 /core/hosts/* 主路径 |
| host | GET /hosts/monitor/iooptions, /hosts/monitor/netoptions（2 个） | `lib/data/repositories/monitor_repository.dart`（直接 client.get） | coverage 仅扫描 *_v2.dart API 类，未扫描 Repository 层直接调用 |
| process | GET /files/wget/process, /files/wget/process/keys（2 个） | `lib/api/v2/file_v2.dart:1233,1248` | 端点在 /files 下但归入 process 模块检查 |
| process | GET /process/ws（1 个） | `lib/core/network/process_ws_client.dart` + `lib/data/repositories/process_repository.dart:53` | WebSocket 端点，coverage 仅检查 Retrofit 文件 |
| group | POST /hosts/update/group, /websites/group/change（2 个） | `lib/api/v2/host_v2.dart:249` + `lib/api/v2/website_v2.dart:814` | group 模块仅检查 system_group_v2.dart，未跨模块识别 |
| setting | POST /core/settings/ssl/reload（1 个） | 不适用（localhost-only） | 服务端内部端点，IsLoopback 校验拒绝远程调用 |
| command | POST /core/commands/upload（1 个） | `lib/features/commands/services/command_service.dart:55`（本地 CSV 解析替代） | 已用 parseImportPreviewCsv 等价覆盖 |

**建议**：在 `check_module_client_coverage.py` 中增加跨模块路径识别 + Repository 层扫描，减少假阳性。

---

## 三、路径 Bug 清单（9 个，改一行即可修复）

这些是客户端路径或 HTTP 方法与 Swagger/前端不一致，导致功能失效。修复成本极小（改路径字符串或方法）。

### 3.1 P0 路径 Bug（功能完全失效）

| 端点 | 客户端错误路径 | 正确路径 | 影响功能 | 修复文件 |
|---|---|---|---|---|
| POST /settings/ssh/default | `/settings/ssh/conn/default` | `/settings/ssh/default` | 终端设置「默认连接信息显示」开关完全失效 | `lib/api/v2/setting_v2.dart:886` |

### 3.2 P1 路径 Bug（关键流程阻断）

| 端点 | 客户端错误 | 正确 | 影响功能 | 修复文件 |
|---|---|---|---|---|
| POST /backups/conn/check | `/backups/check` | `/backups/conn/check` | 备份账户新建时连接测试失败 | `lib/api/v2/backup_account_v2.dart:91` |
| POST /hosts/tool/status | `/hosts/tool` | `/hosts/tool/status` | Supervisor 状态查询失败 | `lib/api/v2/host_tool_v2.dart` |
| POST /hosts/tool/config/get | `/hosts/tool/config` | `/hosts/tool/config/get` | Supervisor 配置读取失败 | `lib/api/v2/host_tool_v2.dart` |
| POST /hosts/firewall/filter/rule/search | `/hosts/firewall/filter/search` | `/hosts/firewall/filter/rule/search` | Iptables Filter 规则查询失败 | `lib/api/v2/firewall_v2.dart` |

### 3.3 P2 路径 Bug（功能异常但非阻断）

| 端点 | 客户端错误 | 正确 | 影响功能 | 修复文件 |
|---|---|---|---|---|
| GET /websites/{id}/lbs | `/websites/lbs` + query{id} | `/websites/{id}/lbs` path param | 网站负载均衡配置查询失败 | `lib/api/v2/website_v2.dart:565` |
| POST /websites/log/operate | `/websites/log` | `/websites/log/operate` | 网站日志清空/切割失败 | `lib/api/v2/website_v2.dart:640` |
| POST /containers/download/log | GET 方法 | POST 方法 | 容器日志下载 405 | `lib/api/v2/container_v2.dart:951` |
| POST /files/read/{type} | `/files/read`（缺 type 段） | `/files/read/{type}` | 大文件按行预览异常 | `lib/api/v2/file_v2.dart:446` |

---

## 四、契约路径迁移清单（10 个，ai accounts 系列）

客户端已在 `/ai/agents/accounts/*` 与 `/ai/agents/providers` 实现完整账号 CRUD/模型池/验证，但 Swagger 契约路径已迁移到 `/ai/accounts/*`。

**前提**：需先通过 API 测试确认服务端真实路径（可能新旧都支持，也可能仅新路径可用）。

| Swagger 新路径 | 客户端旧路径 | 功能 |
|---|---|---|
| GET /ai/accounts/providers | /ai/agents/providers | 获取供应商列表 |
| POST /ai/accounts | /ai/agents/accounts | 创建账号 |
| POST /ai/accounts/update | /ai/agents/accounts/update | 更新账号 |
| POST /ai/accounts/delete | /ai/agents/accounts/delete | 删除账号 |
| POST /ai/accounts/search | /ai/agents/accounts/search | 分页查询账号 |
| POST /ai/accounts/models | /ai/agents/accounts/models | 账号模型列表 |
| POST /ai/accounts/models/create | /ai/agents/accounts/models/create | 新增模型 |
| POST /ai/accounts/models/update | /ai/agents/accounts/models/update | 更新模型 |
| POST /ai/accounts/models/delete | /ai/agents/accounts/models/delete | 删除模型 |
| POST /ai/accounts/verify | /ai/agents/accounts/verify | 验证账号（客户端增强） |

**执行方式**：API 测试确认后，批量替换 `lib/api/v2/ai_v2.dart` 中的路径字符串。模型/Repository/Provider/UI 基本可复用。

---

## 五、真缺失功能规划（49 个端点 → 18 个功能组）

按功能（而非接口）聚合。一个功能组可能对应多个端点，一个端点也可能跨功能组。

### 5.1 P0 功能（核心阻断，2 个）

#### F-P0-1: AI Agent 删除前资源检查
- **端点**：`POST /ai/agents/delete/check`（1 个）
- **前端行为**：`views/ai/agents/agent/index.vue:573` — Agent 列表点击删除时，先调 check 接口获取关联应用安装资源，有则弹资源确认框，无则直接进删除流程
- **客户端落点**：
  - API：`lib/api/v2/ai_v2.dart` 新增 `deleteAgentCheck(AgentIdReq)`
  - Model：`lib/data/models/ai/agent_models.dart` 新增 `AppInstallResource`
  - Repository：`lib/features/ai/agents/agents_repository.dart` 新增 `deleteCheck`
  - Provider：`lib/features/ai/agents/providers/agents_provider_agent_actions.dart` 删除前 check
  - UI：`lib/features/ai/agents/widgets/ai_agents_list_widget.dart` 删除前资源确认弹窗
- **工作量**：M
- **价值**：删除前安全检查，避免误删关联应用

#### F-P0-2: SSH 默认连接路径修复
- **端点**：`POST /settings/ssh/default`（路径 Bug，见 3.1）
- **工作量**：XS（改一行）
- **价值**：恢复终端设置开关功能

### 5.2 P1 功能（重要，9 个功能组）

#### F-P1-1: AI 账号供应商计数
- **端点**：`POST /ai/accounts/counts`（1 个）
- **前端行为**：`views/ai/agents/agent/add/index.vue:353` — 创建 Agent 时按供应商统计账号数，禁用无账号的供应商
- **客户端落点**：API + Model + Repository + Provider（创建表单供应商禁用逻辑）
- **工作量**：S

#### F-P1-2: MCP 服务器增强（详情/状态同步/连接测试）
- **端点**：`POST /ai/mcp/server/detail`、`/status/sync`、`/connection/test`（3 个）
- **前端行为**：
  - detail：`views/ai/mcp/server/index.vue:246` — 编辑前加载完整配置
  - status/sync：`index.vue:225` — 列表加载后批量同步真实运行状态
  - connection/test：`index.vue:312` — 测试连接
- **客户端落点**：API + Repository + Service + Provider + UI（复用 `ai_mcp_tab_widget.dart`）
- **工作量**：M
- **价值**：MCP 编辑闭环 + 状态准确性 + 运维辅助

#### F-P1-3: TensorRT-LLM 模型服务管理
- **端点**：`/ai/tensorrt/{search,create,update,delete,operate}`（5 个）
- **前端行为**：`views/ai/model/tensorrt/` — 完整 CRUD + 生命周期管理（启停/重启），与 Ollama 并列
- **客户端落点**：
  - API：`lib/api/v2/ai_v2.dart`（注意当前 969 LOC，新增 5 端点会超 1000，需同步拆分）
  - Model：新增 `TensorRTLLM` 系列
  - UI：新建 `lib/features/ai/widgets/ai_tensorrt_tab_widget.dart`
- **工作量**：L
- **价值**：模型服务后端扩展，移动端管理有价值

#### F-P1-4: GPU 历史监控
- **端点**：`GET /ai/gpu/options`、`POST /ai/gpu/search`（2 个）
- **前端行为**：`views/ai/gpu/history/index.vue` — 6 类折线图（内存/GPU利用率/进程/功耗/温度/转速）+ 时间范围 + GPU 选择
- **客户端落点**：API + Model + Repository + Provider + UI（复用 `ai_gpu_tab_widget.dart` 新增历史子页）
- **工作量**：L
- **价值**：GPU 监控是 AI 模块核心运维能力

#### F-P1-5: Agent 通道删除与微信通道配置
- **端点**：`POST /ai/agents/channel/delete`、`/ai/agents/channel/weixin/get`（2 个）
- **前端行为**：
  - channel/delete：7 类通道配置页（飞书/Telegram/Discord/企微/QQ/钉钉/微信）删除按钮
  - weixin/get：微信通道配置读取，配合已有 loginAgentWeixinChannel
- **客户端落点**：API + Repository + Provider + UI（通道配置组件新增删除按钮 + 微信组件）
- **工作量**：M

#### F-P1-6: Agent 技能卸载与网站解绑
- **端点**：`POST /ai/agents/skills/uninstall`、`/ai/agents/website/unbind`（2 个）
- **前端行为**：
  - skills/uninstall：`views/ai/agents/agent/config/tabs/skills/hermes.vue:352` — 已安装技能卸载
  - website/unbind：`views/ai/agents/agent/index.vue:635` — Agent 列表解绑网站
- **客户端落点**：API + Repository + Provider + UI（复用现有列表组件新增操作）
- **工作量**：S
- **价值**：补齐 install/update/uninstall + bind/unbind 闭环

#### F-P1-7: Ollama 域名绑定更新
- **端点**：`POST /ai/domain/update`（1 个）
- **前端行为**：`views/ai/model/ollama/domain/index.vue:195` — 已绑定域名时 operate=update
- **客户端落点**：API + Repository + UI（复用 `ai_domain_tab_widget.dart` 编辑模式）
- **工作量**：S
- **价值**：补齐 bind/get/update 闭环

#### F-P1-8: 本地 SSH 连接测试
- **端点**：`POST /settings/ssh/check`（无参，测试已保存连接）
- **前端行为**：`views/terminal/terminal/index.vue:447` — 打开本地终端前测试连通性
- **客户端落点**：API + Service + Provider + UI（终端页本地连接入口前置测试）
- **注意**：与客户端已有的 `/settings/ssh/check/info`（带参测试任意连接）语义不同
- **工作量**：S
- **注意**：setting_v2.dart 已 1299 LOC，新增前需先拆分

#### F-P1-9: 终端 AI 助手配置 + 文件 AI 搜索配置
- **端点**：`/settings/terminal/ai/{search,update}` + `/settings/files/ai/{search,update}`（4 个）
- **前端行为**：
  - terminal/ai：`views/terminal/setting/ai/index.vue` — 终端 AI 助手启用/账号/前缀/风险命令
  - files/ai：`views/host/file-management/ai-search/file-ai-search-drawer.vue` — 文件 AI 搜索账号配置
- **客户端落点**：
  - 新建 `lib/features/settings/terminal_ai_settings_page.dart`
  - 文件管理 AI 搜索入口增加账号配置卡片
  - 复用 `ai_v2.dart:416` 的 `pageAgentAccounts` 获取账号下拉
- **工作量**：M
- **价值**：AI 是项目重点模块；文件 AI 搜索补齐后形成完整链路（客户端已有 /files/ai-search 搜索端点）

### 5.3 P2 功能（改进，7 个功能组）

#### F-P2-1: Hermes 聊天会话管理
- **端点**：`/ai/agents/hermes/chat/sessions`、`/sessions/delete`、`/sessions/rename`（3 个）
- **前端行为**：`views/ai/agents/agent/components/hermes-chat.vue` — 会话列表 + 重命名 + 删除
- **客户端落点**：API + Repository + UI（新建 Hermes 聊天会话组件）
- **工作量**：M
- **价值**：Hermes 专属辅助，移动端依赖终端能力，价值有限

#### F-P2-2: Agent 批量操作
- **端点**：`/ai/agents/batch/{install,operate,skill/install,upgrade}`（4 个）
- **前端行为**：1Panel 前端尚未接入，Swagger 已暴露
- **客户端落点**：API + Model + Repository + Provider + UI（列表多选批量操作）
- **工作量**：L
- **价值**：契合多机统一管理增强方向，客户端可作前瞻实现

#### F-P2-3: 文件历史功能配置
- **端点**：`/settings/file-history/{search,update}`（2 个）
- **前端行为**：`views/host/file-management/code-editor/history/index.vue` — 文件历史启用/每路径最大数/磁盘配额
- **客户端落点**：API + Model + Service + Provider + UI
- **依赖**：客户端尚无代码编辑器与文件历史主功能，建议随主功能一同建设
- **工作量**：S（配置部分），L（含主功能）

#### F-P2-4: 基础设置精简读取 + 网站根目录
- **端点**：`/core/settings/search/base`、`GET /settings/website/dir`（2 个）
- **前端行为**：
  - search/base：侧边栏/过期页/首页等轻量场景的性能优化端点（脱敏）
  - website/dir：创建网站时填充默认静态路径
- **客户端落点**：API + Service（可选 Model）
- **工作量**：XS
- **价值**：性能优化 + 便利性默认值

#### F-P2-5: SSH 远程主机终端路径修复
- **端点**：`GET /hosts/terminal/ssh`（WebSocket，1 个）
- **前端行为**：`views/terminal/terminal/index.vue:503` — `/hosts/terminal/ssh?id={hostId}`
- **客户端问题**：savedHost 错误使用 `/hosts/terminal`（本地 shell）+ `operateNode=local`，无法真正 SSH
- **客户端落点**：
  - `lib/features/terminal/models/terminal_runtime_models.dart:149-189`
  - endpointPath() 为 savedHost 返回 `/hosts/terminal/ssh`
  - queryParameters 为 savedHost 改为 `id={hostId}`
- **工作量**：S
- **价值**：多机 SSH 是客户端核心价值，终端基础设施已存在

#### F-P2-6: 网站负载均衡与日志操作路径修复
- **端点**：见 3.3（2 个路径 Bug）
- **工作量**：XS

#### F-P2-7: 容器日志下载 + 文件按行读取路径修复
- **端点**：见 3.3（2 个路径 Bug）
- **工作量**：XS

### 5.4 P3 功能（暂缓，2 个功能组）

#### F-P3-1: 告警 CronJob 列表
- **端点**：`POST /alert/cronjob/list`（1 个）
- **前端行为**：`views/setting/alert/dash/task/index.vue` — 告警任务配置时按 cronjob 子类型加载列表
- **依赖**：属 xpack alert 能力，客户端无 alert 模块
- **建议**：随 alert 模块整体适配时落地

#### F-P3-2: 命令文件上传（已替代覆盖）
- **端点**：`POST /core/commands/upload`（1 个）
- **现状**：客户端已用本地 CSV 解析（`command_service.dart:55`）等价替代
- **建议**：维持现状，如需对齐可后续补 multipart 上传

---

## 六、架构前置项（AGENTS.md 强制）

以下架构违规需在功能开发前处理，否则会持续累积技术债：

### 6.1 拆分超 1000 LOC 的 API 文件（硬上限）

| 文件 | 当前 LOC | 拆分建议 | 阻塞的功能 |
|---|---|---|---|
| `lib/api/v2/setting_v2.dart` | 1299 | 按域拆分：setting_v2.dart（core）、setting_agent_v2.dart（agent AI 配置）、setting_snapshot_v2.dart、setting_license_v2.dart | F-P1-8, F-P1-9, F-P2-3, F-P2-4 |
| `lib/api/v2/file_v2.dart` | 1261 | 按操作类型拆分：file_v2.dart（browse）、file_transfer_v2.dart、file_recycle_v2.dart、file_share_v2.dart、file_search_v2.dart | F-P2-7 |
| `lib/api/v2/ai_v2.dart` | 969 | 接近上限，新增 TensorRT 5 端点 + GPU 2 端点 + 通道 2 端点后会超限，需同步拆分 | F-P1-3, F-P1-4, F-P1-5 |

### 6.2 AI Repository 位置越界 + 职责重叠

| 文件 | 问题 | 修复 |
|---|---|---|
| `lib/features/ai/ai_repository.dart` | 位置越界（应在 lib/data/repositories/） | 迁移到 `lib/data/repositories/ai_repository.dart` |
| `lib/features/ai/ai_service.dart` | 与 AIRepository 职责重叠（都直接持有 AIV2Api） | AIService 改为协调 Repository，不直接持有 API |
| `lib/features/ai/agents/agents_repository.dart` | 同上 | 迁移到 `lib/data/repositories/ai_agents_repository.dart` |

### 6.3 客户端 UI 文件超推荐阈值

| 文件 | 当前 LOC | 阈值 | 拆分建议 |
|---|---|---|---|
| `lib/features/settings/system_settings_page.dart` | 1147 | 800 | 按设置域拆分子页 |
| `lib/features/settings/settings_provider.dart` | 1035 | 500 | 按域拆分 Provider |
| `lib/features/settings/terminal_settings_page.dart` | 955 | 800 | 终端 AI 配置作为独立子页 |

---

## 七、执行顺序建议

### 第一阶段：快速修复（路径 Bug + 契约迁移，1-2 天）

**目标**：用最小成本消除 19 个端点的 missing 状态

1. **P0 路径修复**（F-P0-2）：`setting_v2.dart:886` 改一行路径
2. **P1 路径修复**（4 个）：backup/tool/tool-config/firewall 各改一行
3. **P2 路径修复**（4 个）：website lbs/log、container download/log、file read 各改一行
4. **契约路径迁移**（10 个）：API 测试确认后批量替换 ai accounts 路径
5. **假阳性标记**：在 coverage 工具或文档中标记 17 个假阳性

**验证**：每个路径修复后跑 `flutter analyze` + 对应模块单测

### 第二阶段：架构前置（拆分 + 归位，2-3 天）

**目标**：消除硬性违规，为新功能腾出空间

1. 拆分 `setting_v2.dart` 1299 → 按域 3-4 个文件
2. 拆分 `file_v2.dart` 1261 → 按操作类型 4-5 个文件
3. AI Repository 迁移到 `lib/data/repositories/`
4. AIService 职责澄清（协调 Repository，不直接持有 API）

**验证**：`flutter analyze` + `dart run test/scripts/test_runner.dart unit`

### 第三阶段：P0 + P1 功能开发（1-2 周）

按功能组优先级顺序：

1. **F-P0-1** AI Agent 删除前资源检查（M）
2. **F-P1-6** Agent 技能卸载 + 网站解绑（S）— 闭环补齐
3. **F-P1-7** Ollama 域名绑定更新（S）— 闭环补齐
4. **F-P1-1** AI 账号供应商计数（S）
5. **F-P1-8** 本地 SSH 连接测试（S）
6. **F-P1-9** 终端 AI + 文件 AI 配置（M）
7. **F-P1-2** MCP 服务器增强（M）
8. **F-P1-5** Agent 通道删除 + 微信配置（M）
9. **F-P1-4** GPU 历史监控（L）
10. **F-P1-3** TensorRT-LLM 管理（L）

### 第四阶段：P2 功能 + 持续优化

- F-P2-5 SSH 远程终端路径（S）— 多机 SSH 核心价值
- F-P2-3 文件历史配置（随主功能）
- F-P2-1 Hermes 会话（M）
- F-P2-2 Agent 批量操作（L）— 多机增强
- F-P2-4 基础设置精简 + 网站目录（XS）

### 第五阶段：P3 暂缓项

- F-P3-1 告警 CronJob（随 alert 模块）
- F-P3-2 命令上传（维持本地替代）

---

## 八、功能与接口对照矩阵

下表展示「功能 → 接口 → 前端页面 → 客户端落点」的完整映射，避免按接口逐一开发的误区：

| 功能组 | 接口数 | 前端页面（views/） | 客户端落点 | 优先级 | 工作量 |
|---|---|---|---|---|---|
| SSH 默认连接路径修复 | 1 | terminal/setting | setting_v2.dart 改路径 | P0 | XS |
| AI Agent 删除前检查 | 1 | ai/agents/agent/index | ai_v2 + agents_repository + list_widget | P0 | M |
| 备份账户连接校验路径 | 1 | setting/backup-account/operate | backup_account_v2 改路径 | P1 | XS |
| Supervisor 工具路径修复 | 2 | toolbox/supervisor | host_tool_v2 改路径 | P1 | XS |
| Iptables Filter 规则路径 | 1 | host/firewall/advance | firewall_v2 改路径 | P1 | XS |
| AI 账号契约迁移 | 10 | ai/agents/agent/config | ai_v2 批量改路径 | P1 | S |
| AI 账号供应商计数 | 1 | ai/agents/agent/add | ai_v2 + agents_repository + create_form | P1 | S |
| MCP 服务器增强 | 3 | ai/mcp/server | ai_v2 + mcp_repository + mcp_tab_widget | P1 | M |
| TensorRT-LLM 管理 | 5 | ai/model/tensorrt | ai_v2（拆分）+ 新建 tensorrt_tab | P1 | L |
| GPU 历史监控 | 2 | ai/gpu/history | ai_v2 + ai_repository + gpu_tab 历史 | P1 | L |
| Agent 通道删除+微信 | 2 | ai/agents/agent/config/channels | ai_v2 + 通道组件 | P1 | M |
| Agent 技能卸载+网站解绑 | 2 | ai/agents/agent/config/skills + index | ai_v2 + agents_repository + list | P1 | S |
| Ollama 域名更新 | 1 | ai/model/ollama/domain | ai_v2 + ai_repository + domain_tab | P1 | S |
| 本地 SSH 连接测试 | 1 | terminal/terminal | setting_v2（拆分）+ terminal_page | P1 | S |
| 终端 AI + 文件 AI 配置 | 4 | terminal/setting/ai + file-management/ai-search | setting_v2（拆分）+ 新建 ai_settings_page | P1 | M |
| SSH 远程终端路径 | 1 | terminal/terminal | terminal_runtime_models 改路径 | P2 | S |
| 网站 lbs/log 路径 | 2 | website/config/basic + log | website_v2 改路径 | P2 | XS |
| 容器日志下载方法 | 1 | components/log/container | container_v2 改方法 | P2 | XS |
| 文件按行读取路径 | 1 | host/file-management | file_v2 改路径 | P2 | XS |
| Hermes 聊天会话 | 3 | ai/agents/agent/components/hermes-chat | ai_v2 + 新建 hermes_chat 组件 | P2 | M |
| Agent 批量操作 | 4 | （前端未接入） | ai_v2 + agents_repository + list 多选 | P2 | L |
| 文件历史配置 | 2 | file-management/code-editor/history | setting_v2（拆分）+ 文件历史主功能 | P2 | S（配置）/ L（含主功能） |
| 基础设置精简+网站目录 | 2 | layout/Sidebar + website/create | setting_v2 + website_create | P2 | XS |
| 告警 CronJob 列表 | 1 | setting/alert/dash/task | 待建 alert 模块 | P3 | M（含模块） |
| 命令文件上传 | 1 | terminal/command/import | 已用本地 CSV 替代 | P3 | XS（如需对齐） |

---

## 九、结论

### 9.1 关键认知修正

1. **接口数 ≠ 功能数**：87 个 missing 端点实际对应约 25 个功能组，其中 17 个假阳性 + 9 个路径 Bug + 10 个契约迁移仅需 1-2 天修复
2. **P0 阻断项大幅缩减**：从原报告的 ai 39 + host 18 缩减为 **2 个**（AI 删除检查 + SSH 路径 Bug）
3. **host 模块基本无缺口**：18 个 missing 中 10 个假阳性 + 8 个路径归一化，客户端 host_assets 模块已完整实现多机管理
4. **ai 模块真缺口集中在新增能力**：TensorRT、GPU 历史、MCP 增强、通道闭环，而非账号管理（账号仅需路径迁移）

### 9.2 推荐策略

**先修路径，再拆架构，后建功能**：
1. 第一阶段用 1-2 天消除 19 个端点（路径修复 + 契约迁移），覆盖率从 90.3% → 93.2%
2. 第二阶段用 2-3 天拆分超限文件 + AI Repository 归位，消除架构违规
3. 第三阶段按功能组优先级开发 P0 + P1 功能（约 10 个功能组）
4. 第四阶段 P2 功能 + 第五阶段 P3 暂缓

### 9.3 多机统一管理增强机会

AGENTS.md 强调「客户端增强方向至少包含：多机统一管理」。以下功能组契合此方向：
- **F-P2-2 Agent 批量操作**（4 端点）：前端未接入，客户端可前瞻实现多 Agent 批量安装/操作/升级
- **F-P2-5 SSH 远程终端**：多机 SSH 是客户端核心价值，仅需修正 WS 路径
- **F-P1-3 TensorRT-LLM**：多模型服务后端管理

这些是客户端相对 1Panel 前端的差异化价值点。
