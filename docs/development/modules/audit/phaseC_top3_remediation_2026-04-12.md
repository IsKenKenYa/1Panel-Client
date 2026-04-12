# Phase C Top3 模块整改清单（2026-04-12）

## 审计口径修正（已完成）

- 覆盖脚本已支持：
  - `_client.get<T>(...)` 等泛型调用提取
  - `_client\n  .post(...)` 跨行调用提取
  - `'${ApiConstants.buildApiPath(...)}/$id'` 插值路径提取
  - `_withNode('/path', ...)` 路径提取
- 覆盖脚本已支持路径归一化：`{id}` / `:id` / `$id` 统一为 `{var}`。
- 模块映射已补齐：
  - `website` 增加 `ssl_v2.dart`
  - `host` 增加 `monitor_v2.dart`、`ssh_v2.dart`、`firewall_v2.dart`、`host_tool_v2.dart`、`disk_management_v2.dart`
- 模块提取匹配已改为前缀匹配，避免 `database` 误匹配 `/websites/databases`。

## Top3 复核结果

| 模块 | Swagger | Client | Missing | Extra | 状态 |
|---|---:|---:|---:|---:|---|
| website | 93 | 100 | 0 | 7 | extra_in_client |
| host | 44 | 53 | 0 | 9 | extra_in_client |
| database | 42 | 49 | 0 | 7 | extra_in_client |

> 结论：Top3 模块在“缺失端点”维度已收敛为 0；当前主要风险转为“客户端额外端点（契约漂移或兼容端点）”。

## website 模块整改项

- 缺失端点：无。
- 额外端点（7）：
  - `GET /core/settings/ssl/info`
  - `POST /core/settings/ssl/download`
  - `POST /core/settings/ssl/update`
  - `GET /websites/ssl/options`
  - `GET /websites/ssl/application/{var}/status`
  - `POST /websites/ssl/auto-renew`
  - `POST /websites/ssl/validate`
- 已开始补齐：
  - 覆盖映射已补齐 `ssl_v2.dart`，消除历史假缺失。
  - 统一响应解析器已接入 `website_v2.dart`。
- 后续动作：
  - 将系统 SSL 相关 3 个端点迁移到 `system_ssl` 模块核算口径。
  - 对 `websites/ssl/*` 4 个端点做契约回归（Swagger/真实返回/Web 行为）。

## host 模块整改项

- 缺失端点：无。
- 额外端点（9）：
  - `POST /core/hosts`
  - `POST /core/hosts/del`
  - `POST /core/hosts/info`
  - `POST /core/hosts/search`
  - `POST /core/hosts/test/byid/{var}`
  - `POST /core/hosts/test/byinfo`
  - `POST /core/hosts/tree`
  - `POST /core/hosts/update`
  - `POST /core/hosts/update/group`
- 已开始补齐：
  - host 关联 API 客户端映射已补齐（monitor/ssh/firewall/tool/disk）。
  - 统一响应解析器已接入 `host_v2.dart`。
- 后续动作：
  - 逐项核对 `/core/hosts/*` 是否仍为后端真实兼容路径。
  - 若已废弃，迁移到 swagger 标准端点并补回归测试。

## database 模块整改项

- 缺失端点：无。
- 额外端点（7）：
  - `GET /databases/redis/check`
  - `GET /databases/{var}/connection/test`
  - `GET /databases/{var}/privileges`
  - `POST /databases/update`
  - `POST /databases/{var}/backups`
  - `POST /databases/{var}/password/reset`
  - `POST /databases/{var}/privileges`
- 已开始补齐：
  - `database` 提取口径已修正为 `/databases` 前缀，去除历史误报。
  - 统一响应解析器已接入 `database_v2.dart`。
- 后续动作：
  - 对 7 个额外端点做契约确认并落地分类（兼容保留 / 替换 / 下线）。
  - 为保留端点补充 API 回归测试与文档注记。
