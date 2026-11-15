# 模块适配深度分析报告

> **基线**：`docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`（只读）
> **客户端**：`lib/api/v2/*.dart` + `lib/data/repositories/`
> **生成时间**：2026-07-10
> **依据**：`AGENTS.md`「V2 接口定义单一来源」「模块适配 7 步闭环」「架构与分层」
> **当前快照**：`v2.5.1`（2026-11-15 更新，810 paths）；当前批次状态见 `docs/development/modules/阶段总计划.md` B9，本文保留历史分析背景。

---

## 一、总体覆盖现状

### 1.1 swagger.json 端点规模

| 维度 | 数值 |
|---|---|
| 总路径数 | **710** |
| 总端点数（GET/POST/PUT/DELETE/PATCH） | **721** |
| 顶层路径前缀（top-level） | 27 个（/ai 97、/websites 97、/containers 72、/core 71、/hosts 59、/files 57、/databases 54、/toolbox 39、/apps 31、/runtimes 31、/settings 26、/backups 21、/cronjobs 16、/alert 15、/dashboard 12、/openresty 10、/groups 4、/logs 4、/process 4、/health 1 等） |

### 1.2 客户端覆盖汇总

| 维度 | 数值 |
|---|---|
| `lib/api/v2/*_v2.dart` 文件数 | **34** |
| 客户端 `buildApiPath()` 端点定义总数 | **~770**（超过 swagger 721，差额为客户端兼容白名单端点） |
| `lib/data/repositories/` Repository 文件数 | **33** |
| check_module_client_coverage.py 划分模块数 | **27** |
| `aligned` 模块数 | **14** |
| `missing_in_client` 模块数 | **13** |
| 总缺失端点数（missing_in_client） | **87** |

### 1.3 27 模块覆盖状态

| 状态 | 模块数 | 模块列表 |
|---|---|---|
| ✅ aligned | 14 | app, auth, dashboard, database, device, domains, log, openresty, runtime, ssl, system_ssl, toolbox, website_ssl, (无缺失的) |
| ⚠️ missing_in_client | 13 | ai, backup, command, container, cronjob, file, firewall, group, host, monitor, process, setting, ssh, website |

---

## 二、阻断项：87 个 missing_in_client 端点（AGENTS.md「进入 API 测试阶段前清零」）

### 2.1 按模块严重度排序

| 模块 | 缺失数 | 严重度 | 核心缺口 |
|---|---|---|---|
| **ai** | 39 | 🔴 P0 | AI accounts 管理(12)、agents batch(4)、hermes chat(3)、tensorrt(5)、mcp server(3)、文件 AI 搜索(3)、GPU options/search(2) |
| **host** | 18 | 🔴 P0 | 主机 CRUD(POST /hosts, /hosts/del, /hosts/info, /hosts/search, /hosts/tree, /hosts/update, /hosts/update/group 共 7)、terminal local/ssh/container(3)、tool config/status(3)、supervisor process file(1)、firewall filter rule search(1)、monitor iooptions/netoptions(2) |
| **setting** | 11 | 🟠 P1 | file-history(2)、AI 文件搜索(2)、terminal AI(2)、SSH check/default(2)、core settings search/ssl reload(2)、website dir(1) |
| **process** | 4 | 🟡 P2 | wget process(2)、process ws(1)、supervisor process file get(1) |
| **ssh** | 3 | 🟡 P2 | terminal/ssh(1)、ssh check/default(2) |
| **monitor** | 2 | 🟡 P2 | iooptions/netoptions(2) |
| **group** | 2 | 🟡 P2 | update/group(1)、websites/group/change(1) |
| **website** | 2 | 🟡 P2 | lbs 详情(1)、log/operate(1) |
| **firewall** | 1 | 🟢 P3 | filter/rule/search(1) |
| **backup** | 1 | 🟢 P3 | conn/check(1) |
| **command** | 1 | 🟢 P3 | upload(1) |
| **container** | 1 | 🟢 P3 | download/log POST(1) |
| **cronjob** | 1 | 🟢 P3 | alert/cronjob/list(1) |
| **file** | 1 | 🟢 P3 | read/{var}(1) |

### 2.2 跨模块路径归一化问题（去重后实际唯一缺失约 70 个）

check_module_client_coverage.py 按关键词分组导致部分端点在多模块重复计数：

| 端点 | 重复计数的模块 | 实际归属 |
|---|---|---|
| `GET /hosts/monitor/iooptions` | host + monitor | monitor |
| `GET /hosts/monitor/netoptions` | host + monitor | monitor |
| `GET /hosts/terminal/ssh` | host + ssh | ssh |
| `POST /hosts/tool/supervisor/process/file/get` | host + process | process |
| `POST /settings/ssh/check` | setting + ssh | ssh |
| `POST /settings/ssh/default` | setting + ssh | ssh |
| `POST /hosts/update/group` | host + group | host（group 是参数） |
| `POST /settings/files/ai/search` | setting + ai | ai |
| `POST /settings/files/ai/update` | setting + ai | ai |
| `POST /settings/terminal/ai/search` | setting + ai | ai |
| `POST /settings/terminal/ai/update` | setting + ai | ai |

去重后**实际唯一缺失端点 ≈ 70 个**。

### 2.3 客户端额外端点（44 个，未在 Swagger 中）

客户端有但 Swagger 没有的端点（多为客户端增强 / 待迁移）：

| 类型 | 数量 | 说明 |
|---|---|---|
| 路径归一化差异 | ~10 | 如 `/websites/lbs` vs `/websites/{var}/lbs`、`/containers/download/log` GET vs POST |
| 客户端增强能力 | ~20 | MFA、passkey、AI 浏览器托管、AI 通道配对审批等 |
| 白名单（带原因） | ~14 | 见各模块报告 |

---

## 三、API 变更追踪（check_module_api_updates.py）

### 3.1 与客户端现有基线对比

| 状态 | 模块数 | 模块 |
|---|---|---|
| unchanged（无变更） | 7 | dashboard, device, domains, log, openresty, runtime, toolbox |
| updated（有变更） | 20 | ai(+39/-10), app(+2), auth(+13), backup(+2/-1), command(+3/-2), container(+1), cronjob(+1), database(+12), file(+18/-1), firewall(+1/-1), group(+2), host(+19/-4), monitor(+2/-1), process(+4), setting(+11/-13), ssh(+19), ssl(+3), system_ssl(+1), website(+5/-3), website_ssl(+2) |

### 3.2 关键变更

- **ssh 模块基线 0 → 19 端点**：基线未建立，本轮新增 19 个端点全部需客户端覆盖（与 missing_in_client 3 个缺失不矛盾，因为客户端已覆盖 16/19）
- **ai 模块 +39/-10**：上游 AI 模块大幅扩展（accounts、agents batch、hermes chat、tensorrt、mcp server），客户端基线 73 → 102 端点
- **database +12**：上游新增 12 个端点，客户端基线 42 → 54，已全部覆盖
- **file +18/-1**：上游新增 18 个端点，客户端基线 49 → 66，已覆盖 65（缺 1：`POST /files/read/{var}`）
- **host +19/-4**：上游新增 19 删除 4，客户端基线 44 → 59，仅覆盖 51（缺 18 个，含主机 CRUD 全套）

---

## 四、架构违规（AGENTS.md 强制）

### 4.1 🔴 硬性违规：2 个 API 文件超 1000 LOC 硬上限

| 文件 | LOC | 超 | 说明 |
|---|---|---|---|
| `lib/api/v2/setting_v2.dart` | **1299** | +299 | 单文件承载 53 个端点，需按设置域拆分 |
| `lib/api/v2/file_v2.dart` | **1261** | +261 | 单文件承载 66 个端点，需按文件操作类型拆分 |

AGENTS.md 第 179 行「所有代码文件（文档与 Swagger 产物除外）硬上限为 1000 LOC，超出必须拆分」。API 文件非 Swagger 产物，必须拆分。

### 4.2 🔴 硬性违规：AI Repository 位置越界

| 文件 | 位置 | 应在位置 |
|---|---|---|
| `lib/features/ai/ai_repository.dart` | `features/ai/` | `lib/data/repositories/ai_repository.dart` |
| `lib/features/ai/agents/agents_repository.dart` | `features/ai/agents/` | `lib/data/repositories/ai_agents_repository.dart` |

AGENTS.md 第 138 行「仓库层：数据单一事实来源（`lib/data/repositories/`）」— AI Repository 放在 features 层违反分层。

### 4.3 🟠 职责重叠：AIService 与 AIRepository 并存

```
lib/features/ai/ai_service.dart      ← final AIV2Api _api; (直接持有 API)
lib/features/ai/ai_repository.dart   ← Future<AIV2Api> _getApi() (也直接持有 API)
```

两者都直接持有 `AIV2Api`，职责重叠：
- `AIService.bindDomain()` 仅加 try/catch 后转发 `_api.bindDomain()`
- `AIRepository.bindDomain()` 仅做参数组装后调 `api.bindDomain()`

AGENTS.md 第 137 行「服务层：业务规则与数据加工，协调不同的 Repository」— AIService 未协调多个 Repository，而是直接调 API，与 Repository 职责冲突。

### 4.4 🟠 Repository 命名/位置不一致（11 个 v2.dart 无对应 repository）

脚本检测 11 个 v2.dart 在 `lib/data/repositories/` 下无对应命名 repository：

| API 文件 | Repository 状态 | 说明 |
|---|---|---|
| `ai_v2.dart` | ❌ 不在 data/repositories/（在 features/ai/） | 位置违规 |
| `auth_v2.dart` | ❌ 无 | 可能在 core/auth/ 下 |
| `backup_account_v2.dart` | ❌ 无 | backup_repository.dart 仅覆盖备份记录，未覆盖账号 |
| `compose_v2.dart` | ❌ 无 | 容器编排无独立 Repository |
| `docker_v2.dart` | ❌ 无 | 由 container_repository.dart 隐式覆盖 |
| `file_v2.dart` | ❌ 命名不匹配 | `files_repository.dart`（复数） |
| `snapshot_v2.dart` | ❌ 无 | 快照 API 无 Repository |
| `system_group_v2.dart` | ❌ 命名不匹配 | `group_repository.dart` |
| `terminal_v2.dart` | ❌ 无 | 终端 API 无 Repository |
| `update_v2.dart` | ❌ 无 | 升级 API 无 Repository |
| `website_group_v2.dart` | ❌ 命名不匹配 | `group_repository.dart` |

---

## 五、客户端兼容白名单（已记录原因，待清理）

14 个 aligned 模块中有 8 个存在客户端兼容白名单端点（Swagger 未声明但客户端保留）：

| 模块 | 白名单端点数 | 主要原因 |
|---|---|---|
| auth | 3 | 登录前 demo/issafety/language 探测 |
| database | 6 | 数据库连接测试、权限管理、密码重置等契约待补齐 |
| log | 2 | 任务日志执行中数量、列表查询 |
| ssl | 4 | 证书申请状态、自动续签、表单校验 |
| toolbox | 14 | 磁盘管理、Supervisor 进程、清理工具等归属待收口 |
| website_ssl | 4 | 证书相关能力 |
| command | 7 | 脚本库 legacy wrapper 待迁移到 script_library_v2 |
| container | 1 | 容器命令执行入口 |

**白名单清理优先级**：command legacy wrapper（7 个，已有 script_library_v2.dart 承接）> toolbox 归属收口（14 个）> database 权限管理（6 个）。

---

## 六、合规强项

| 维度 | 状态 | 证据 |
|---|---|---|
| 分层依赖方向 | ✅ 100% 合规 | UI/State 层 0 直连 lib/api/v2/（前序 zoom-out 验证） |
| API 客户端代码生成 | ✅ 全部手写但格式统一 | 34 个 v2.dart 均使用 `ApiConstants.buildApiPath()` |
| 14 模块契约对齐 | ✅ aligned | app/auth/dashboard/database/device/domains/log/openresty/runtime/ssl/system_ssl/toolbox/website_ssl 等 |
| 客户端白名单带原因 | ✅ 全部标注 | 8 模块 41 个白名单端点均有「保留：原因」注释 |
| Repository 层平均规模 | ✅ ~118 LOC/文件 | 33 个 repository 文件仅 1 个超 300 LOC（database_repository 386） |

---

## 七、优先级行动清单

### P0 阻断项（进入 API 测试前必须清零）

1. **ai 模块 39 个缺失端点** — 上游 AI 大幅扩展，客户端需补齐 accounts/agents batch/hermes chat/tensorrt/mcp server 五大子域
2. **host 模块 18 个缺失端点** — 主机 CRUD 全套缺失（POST /hosts, /hosts/del, /hosts/info, /hosts/search, /hosts/tree, /hosts/update, /hosts/update/group），移动端多机管理核心能力
3. **拆分 setting_v2.dart 1299 LOC** — 按设置域拆分（terminal/monitor/api_key/about/menu/theme/upgrade）
4. **拆分 file_v2.dart 1261 LOC** — 按文件操作类型拆分（browse/transfer/recycle/share/search）
5. **AI Repository 迁移到 lib/data/repositories/** — 修正分层违规
6. **AIService 与 AIRepository 职责澄清** — Service 协调 Repository，不直接持有 API

### P1 重要项

7. **setting 模块 11 个缺失端点** — file-history、AI 文件搜索、terminal AI、SSH check/default
8. **API 变更基线回写** — ssh 模块基线 0 → 19（缺失基线文件 `docs/development/modules/SSH管理/ssh_api_analysis.json` 已存在，需更新端点计数）

### P2 改进项

9. **process/ssh/monitor/group/website 各 2-4 个缺失端点** — 多为路径归一化差异，需客户端契约校验
10. **firewall/backup/command/container/cronjob/file 各 1 个缺失端点** — 多为方法签名差异（GET vs POST、path 参数化）

### P3 清理项

11. **command 模块 7 个 legacy wrapper 白名单** — 迁移到 script_library_v2.dart
12. **toolbox 模块 14 个白名单** — 归属收口到 disk_management/process 独立模块
13. **11 个 v2.dart Repository 命名/位置对齐** — 统一命名规范

---

## 八、建议的 7 步闭环执行顺序（AGENTS.md 第 90-97 行）

按 AGENTS.md「模块适配 7 步闭环」对 P0 阻断项执行：

### AI 模块（39 缺失，最严重）
1. **需求拆解**：AI accounts/agents batch/hermes chat/tensorrt/mcp server 五大子域能力边界
2. **测试用例设计**：每个子域单测 + 契约偏差用例（39 端点 × 正常/异常 = ~80 用例）
3. **基线准备**：更新 `docs/development/modules/AI管理/ai_api_analysis.json` 端点数 73 → 102
4. **功能开发**：扩展 `lib/api/v2/ai_v2.dart`（注意当前 969 LOC，新增 39 端点会超 1000，需同步拆分）
5. **单测执行**：`dart run test/scripts/test_runner.dart unit`
6. **集成测试**：`dart run test/scripts/test_runner.dart integration`（涉及 API 必跑）
7. **文档回写**：更新 `docs/development/modules/AI管理/ai_api_analysis.md`

### Host 模块（18 缺失，含主机 CRUD）
1. **需求拆解**：主机 CRUD + terminal 类型 + tool config + supervisor file
2. **测试用例设计**：主机增删改查 + terminal local/ssh/container 切换
3. **基线准备**：更新 `docs/development/modules/主机管理/host_api_analysis.json` 端点数 44 → 59
4. **功能开发**：扩展 `lib/api/v2/host_v2.dart`（当前 296 LOC，可承载）
5. **单测/集成测试**
6. **文档回写**

---

## 九、结论

当前 1Panel V2 API 客户端覆盖率为 **(721 - 70) / 721 ≈ 90.3%**（去重后实际缺失 70 个端点）。

**阻断项**：87 个 missing_in_client 端点（去重后 70 个），主要集中在 ai（39）和 host（18）两个模块，占缺失总量 65%。

**架构违规**：2 个 API 文件超 1000 LOC 硬上限 + AI Repository 位置越界 + AIService/AIRepository 职责重叠。

**合规强项**：14 模块契约对齐 + 分层依赖 100% 合规 + 8 模块白名单全部带原因。

按 AGENTS.md「进入 API 测试阶段前清零」要求，ai 与 host 两个 P0 模块必须在下一轮 PR 中完成端点补齐，否则阻断后续 API 测试。
