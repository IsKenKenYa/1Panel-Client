# Phase C API / Models 深查问题清单（2026-04-12）

## 说明

- 本清单基于：
  - 修正后的 `check_module_client_coverage.py`（Top3 复核）
  - `phaseB_layered_scan_2026-04-12.*`（分层与模型风险）
- 目标：给出可执行的“问题 -> 风险 -> 处置”条目，覆盖 API 与 models。

## API 问题（16项）

| # | 模块 | 端点/问题 | 风险 | 处理建议 | 状态 |
|---:|---|---|---|---|---|
| 1 | host | `POST /core/hosts` | 与 swagger `host` 模块不一致，疑似旧契约路径 | 走真实 API 回归，确认是否迁移/保留 | 待处理 |
| 2 | host | `POST /core/hosts/del` | 同上 | 同上 | 待处理 |
| 3 | host | `POST /core/hosts/info` | 同上 | 同上 | 待处理 |
| 4 | host | `POST /core/hosts/search` | 同上 | 同上 | 待处理 |
| 5 | host | `POST /core/hosts/test/byid/{var}` | 同上 | 同上 | 待处理 |
| 6 | host | `POST /core/hosts/test/byinfo` | 同上 | 同上 | 待处理 |
| 7 | host | `POST /core/hosts/tree` | 同上 | 同上 | 待处理 |
| 8 | host | `POST /core/hosts/update` | 同上 | 同上 | 待处理 |
| 9 | host | `POST /core/hosts/update/group` | 同上 | 同上 | 待处理 |
| 10 | website | `GET /core/settings/ssl/info` | 归属跨模块（system_ssl），website 统计口径被污染 | 迁移模块核算口径或拆分客户端 | 处理中 |
| 11 | website | `POST /core/settings/ssl/download` | 同上 | 同上 | 处理中 |
| 12 | website | `POST /core/settings/ssl/update` | 同上 | 同上 | 处理中 |
| 13 | website | `GET /websites/ssl/options` | 端点在客户端存在但 Swagger 未体现（或路径变化） | 进行契约偏差回归并记录兼容策略 | 待处理 |
| 14 | website | `GET /websites/ssl/application/{var}/status` | 同上 | 同上 | 待处理 |
| 15 | website | `POST /websites/ssl/auto-renew` | 同上 | 同上 | 待处理 |
| 16 | website | `POST /websites/ssl/validate` | 同上 | 同上 | 待处理 |

## 数据模型问题（8项）

| # | 文件 | 现象 | 风险 | 处理建议 | 状态 |
|---:|---|---|---|---|---|
| 1 | `lib/data/models/container_models.dart` | `Map<String, dynamic>`/`dynamic` 使用密度最高（审计评分 397） | 字段漂移难发现，运行时类型错误概率高 | 拆分强类型子模型，收窄 dynamic 边界 | 待处理 |
| 2 | `lib/data/models/setting_models.dart` | 动态字段密度高（评分 303） | 设置项解析受后端大小写/类型影响明显 | 增加 typed adapter + 默认值策略 | 待处理 |
| 3 | `lib/data/models/toolbox_models.dart` | list/map dynamic 混用（评分 251） | 集合内元素类型不稳定，UI 层容错成本高 | 为列表项建立显式 DTO | 待处理 |
| 4 | `lib/data/models/website_models.dart` | 动态字段较多（评分 247） | 网站配置项演进时容易 silently fail | 核心结构改为强类型 + unknown bucket | 待处理 |
| 5 | `lib/data/models/common_models.dart` | 通用模型 dynamic 渗透（评分 194） | 问题会扩散到多个模块 | 把 common 模型按场景拆分 | 待处理 |
| 6 | `lib/data/models/ssl_models.dart` | SSL 字段动态性偏高（评分 181） | 证书链/状态字段变体难追踪 | 增加 enum 化和解析兜底 | 待处理 |
| 7 | `lib/data/models/database_models.dart` | 数据库模型仍有多处 dynamic（评分 130） | 连接配置/状态模型的可维护性下降 | 对关键对象做强类型替换 | 待处理 |
| 8 | `lib/data/models/monitoring_models.dart` | 监控模型 dynamic 分布中等（评分 96） | 指标字段扩展时易触发兼容分支膨胀 | 继续收敛到 typed metrics 结构 | 处理中 |

## 本轮已落地修复

- 监控页分层违规修复：`monitoring_page` 不再直接依赖 `api/v2/monitor_v2.dart`。
- 新增统一响应解析器：`lib/api/v2/api_response_parser.dart`。
- 解析策略已迁移（首批）：
  - `website_v2.dart`
  - `host_v2.dart`
  - `database_v2.dart`
  - `ai_v2.dart`
  - `auth_v2.dart`
  - `container_v2.dart`
  - `openresty_v2.dart`
  - `dashboard_v2.dart`
- Top3 覆盖脚本口径修复：缺失端点已归零，进入“额外端点契约治理”阶段。
