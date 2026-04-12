# Phase C API / Models 全量深扫清单（2026-04-12）

## 扫描基线

- 覆盖差异脚本：`docs/development/modules/check_module_client_coverage.py --all --json`
- 模块提取脚本：`docs/development/modules/analyze_module_api.py`
- 额外静态扫描：API 解析风险模式（`response.data as Map<String, dynamic>`、`response.data?['data']`）与 models 动态字段密度。

> 更新（第2批实改）：`file/log/container` 三模块已完成补点与对齐测试，详见 `phaseC_batch2_file_log_container_remediation_2026-04-12.md`。

## 全量状态（修正脚本口径后）

- aligned: 9
- extra_in_client: 5
- missing_in_client: 13

## API 问题池（20 项）

| # | 模块 | 端点 | 类型 | 风险 | 处置建议 | 优先级 |
|---:|---|---|---|---|---|---|
| 1 | file | `POST /containers/files/content` | missing | 容器文件读取能力缺失，影响容器文件面板 | 在 `file_v2.dart` 补齐容器文件 CRUD/search 能力 | P0 |
| 2 | file | `POST /containers/files/search` | missing | 容器目录检索不可用 | 同上 | P0 |
| 3 | file | `POST /containers/files/download` | missing | 容器文件下载缺失，易触发功能退化 | 同上 | P0 |
| 4 | file | `GET /containers/daemonjson/file` | missing | daemon.json 编辑链路不完整 | 增加读取与保存接口封装 | P0 |
| 5 | log | `POST /core/auth/login` | missing | 日志/审计回放链路不全 | 在日志模块补齐登录相关审计查询映射 | P0 |
| 6 | log | `POST /core/auth/logout` | missing | 同上 | 同上 | P0 |
| 7 | log | `GET /containers/search/log` | missing | 容器日志查询能力缺失 | 在 `logs_v2.dart` 增加容器日志查询端点 | P0 |
| 8 | container | `POST /containers/compose/search` | missing | Compose 管理查询能力缺失 | 补齐 compose search/env/operate/update/test | P0 |
| 9 | container | `POST /containers/compose/operate` | missing | Compose 生命周期操作缺失 | 同上 | P0 |
| 10 | container | `POST /containers/compose/update` | missing | Compose 配置更新缺失 | 同上 | P0 |
| 11 | process | `POST /runtimes/supervisor/process` | missing | 进程托管操作不完整 | `process_v2.dart` 增加 runtimes/hosts supervisor 端点 | P1 |
| 12 | process | `GET /runtimes/supervisor/process/{var}` | missing | 进程详情读取缺失 | 同上 | P1 |
| 13 | ssh | `POST /settings/ssh` | missing | SSH 设置无法下发，影响远程连接稳定性 | 在 `ssh_v2.dart` 补齐 settings/ssh 全链路 | P1 |
| 14 | ssh | `GET /settings/ssh/conn` | missing | 默认连接策略无法读取 | 同上 | P1 |
| 15 | app | `GET /dashboard/app/launcher` | missing | 应用启动器数据缺失 | 在 `app_v2.dart` 增加 launcher 相关接口 | P1 |
| 16 | host | `POST /hosts/test/byid` | extra | Swagger 未声明，存在契约漂移 | 保留（Web 语义已使用），等待契约补齐 | P1 |
| 17 | host | `POST /core/hosts/test/byid/{var}` | extra | legacy 路径仍在，长期保留会加重维护成本 | 保留 fallback，设置下线窗口 | P1 |
| 18 | auth | `GET /core/auth/demo` | extra | 端点归属与 `websites/auths` 混杂，模块语义不清 | 将登录安全类与网站认证类拆分治理 | P2 |
| 19 | website_ssl | `POST /websites/ssl/validate` | extra | Swagger 未显式收录，可能引发误判 | 标注为契约偏差并保留兼容 | P2 |
| 20 | database | `POST /databases/{var}/password/reset` | extra | 端点与 Swagger 偏差，可能导致回归漏测 | 增加 live API 对齐用例并记录偏差策略 | P2 |

## API 实现风险（解析策略）

| 文件 | 现象 | 风险 | 建议 |
|---|---|---|---|
| `lib/api/v2/app_v2.dart` | `response.data as Map<String, dynamic>` 出现 16 次 | 解包口径不一致，运行时类型错误概率高 | 迁移到 `ApiResponseParser` |
| `lib/api/v2/file_v2.dart` | 直接强转 14 次 + `toString` 兜底 | 非结构化返回难以稳定兼容 | 统一使用解析器 + 强类型 DTO |
| `lib/api/v2/runtime_v2.dart` | `response.data?['data']` 13 次 | 多分支解包导致行为漂移 | 抽离统一解包函数 |
| `lib/api/v2/backup_account_v2.dart` | `['data']` 访问 11 次 | 相同问题在备份模块重复出现 | 统一迁移解析器 |

## Models 风险池（8 项）

| # | 文件 | 现象 | 风险 | 建议 | 优先级 |
|---:|---|---|---|---|---|
| 1 | `lib/data/models/container_models.dart` | dynamic=100，`Map<String, dynamic>`=99 | 容器复杂对象类型漂移难追踪 | 拆分强类型子模型，收敛 dynamic | P0 |
| 2 | `lib/data/models/setting_models.dart` | dynamic=78，mapDynamic=75 | 设置项兼容成本高 | 增加 typed adapter 与默认值策略 | P0 |
| 3 | `lib/data/models/website_models.dart` | dynamic=62，mapDynamic=61 | 网站配置演进风险高 | 对核心结构强类型化 | P1 |
| 4 | `lib/data/models/toolbox_models.dart` | dynamic=64，mapDynamic=59 | 工具箱数据结构不稳定 | 拆分 DTO，避免深层 dynamic map | P1 |
| 5 | `lib/data/models/app_models.dart` | dynamic=54，mapDynamic=52 | 应用市场模型易出现静默解析失败 | 引入显式字段与 unknown bucket | P1 |
| 6 | `lib/data/models/common_models.dart` | dynamic=51，mapDynamic=45 | 通用模型问题会扩散全局 | 场景化拆分 common 模型 | P1 |
| 7 | `lib/data/models/ssl_models.dart` | dynamic=46，mapDynamic=45 | 证书状态/链路字段演进风险 | enum 化关键状态字段 | P2 |
| 8 | `lib/data/models/database_models.dart` | dynamic=34，mapDynamic=32 | 数据库连接对象容错复杂 | 关键对象强类型替换 | P2 |

## 现有自动化脚本能力盘点

| 阶段 | 现有能力 | 脚本/命令 | 结论 |
|---|---|---|---|
| 需求拆解 | 部分（人工文档） | `docs/development/modules/audit/*.md` | 无“自动检查”门禁 |
| 测试用例设计 | 部分（人工维护） | 现有测试文件 | 无“覆盖度自动校验”门禁 |
| 自动化测试基线准备 | 有 | `test/scripts/test_runner.dart` | 可执行但依赖已有测试资产 |
| 功能开发实现 | 有 | 代码与 analyze | 可执行 |
| 单元测试执行 | 有 | `dart run test/scripts/test_runner.dart unit` | 可执行 |
| 集成测试执行 | 有（条件） | `dart run test/scripts/test_runner.dart integration` | 需 `RUN_LIVE_API_TESTS=true` |
| 文档回写 | 部分（人工） | audit 文档 | 无自动强制门禁 |

## 闭环缺口（本轮确认）

1. `host` 模块当前无可发现的单测资产（`--module=host` 返回空集合）。
2. 集成测试在默认环境会被跳过，真实 API 回归依赖环境变量，不是强制门禁。
3. “需求拆解/用例设计/文档回写”尚无自动化强制校验脚本。

## 下一步建议（可直接执行）

1. 新增 `host` 的 API 对齐测试文件（覆盖 search/info/tree/test/update/del）。
2. 为 `file/container/log` 三个 P0 模块补齐缺失端点并增加 integration case。
3. 增加一个统一 gate 脚本，将覆盖扫描 + unit + integration + 文档检查串联为单命令。
