# Phase C Host Core 漂移端点治理决策（2026-04-12）

## 结论摘要

- 已完成第一批实改：`lib/api/v2/host_v2.dart` 9 组 host 资产端点由 `/core/hosts*` 主路径迁移到 `/hosts*`。
- 兼容策略：对 `404/405` 自动回退 legacy `/core/hosts*`，避免线上节点尚未完成升级时功能中断。
- 本轮不直接下线 legacy 路径，进入“观察 + 集成回归”阶段后再下线。

## 契约证据

### 上游 Web 语义（优先）

- `docs/OpenSource/1Panel/frontend/src/api/modules/terminal.ts` 明确使用：
  - `POST /hosts/search`
  - `POST /hosts/info`
  - `POST /hosts/tree`
  - `POST /hosts/test/byinfo`
  - `POST /hosts/test/byid`（body 传 `id`）
  - `POST /hosts/update`
  - `POST /hosts/update/group`
  - `POST /hosts/del`

### Swagger 口径

- `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json` 当前仅显式包含：
  - `GET /hosts/components/{name}`
- 对上述 8 个 `/hosts/*` 核心操作缺失显式定义。

### 历史日志口径

- `docs/OpenSource/1Panel/core/cmd/server/docs/x-log.json` 存在 legacy：
  - `/core/hosts`
  - `/core/hosts/del`
  - `/core/hosts/update`
  - `/core/hosts/update/group`

## 9 项逐条决策矩阵

| # | 能力 | 旧路径（legacy） | 新主路径 | 当前实现 | 决策 | 下线策略 |
|---:|---|---|---|---|---|---|
| 1 | 创建主机 | `POST /core/hosts` | `POST /hosts` | 已迁移，404/405 回退 | 迁移 + 保留兼容 | 进入双环境集成回归后评估下线 |
| 2 | 删除主机 | `POST /core/hosts/del` | `POST /hosts/del` | 已迁移，404/405 回退 | 迁移 + 保留兼容 | 同上 |
| 3 | 更新主机 | `POST /core/hosts/update` | `POST /hosts/update` | 已迁移，404/405 回退 | 迁移 + 保留兼容 | 同上 |
| 4 | 主机搜索 | `POST /core/hosts/search` | `POST /hosts/search` | 已迁移，404/405 回退 | 迁移 + 保留兼容 | 同上 |
| 5 | 主机详情 | `POST /core/hosts/info` | `POST /hosts/info` | 已迁移，404/405 回退 | 迁移 + 保留兼容 | 同上 |
| 6 | 主机树 | `POST /core/hosts/tree` | `POST /hosts/tree` | 已迁移，404/405 回退 | 迁移 + 保留兼容 | 同上 |
| 7 | 按信息测试 | `POST /core/hosts/test/byinfo` | `POST /hosts/test/byinfo` | 已迁移，404/405 回退 | 迁移 + 保留兼容 | 同上 |
| 8 | 更新分组 | `POST /core/hosts/update/group` | `POST /hosts/update/group` | 已迁移，404/405 回退 | 迁移 + 保留兼容 | 同上 |
| 9 | 按 ID 测试 | `POST /core/hosts/test/byid/{id}` | `POST /hosts/test/byid`（body: `{id}`） | 已迁移，404/405 回退 legacy 路径 | 迁移 + 保留兼容 | 待 Swagger/真实 API 契约补齐后下线 |

## 回归与门禁执行记录

- 静态检查：`flutter analyze lib/api/v2/host_v2.dart`（通过）。
- 单测门禁：`dart run test/scripts/test_runner.dart unit --module=host`
  - 结果：当前无匹配的 host 单测（空集合）。
- 集成门禁：`dart run test/scripts/test_runner.dart integration --module=host`
  - 结果：未开启 `RUN_LIVE_API_TESTS`，已按脚本策略跳过。

## 风险与后续动作

1. 风险：Swagger 与 Web 语义存在偏差，容易造成“脚本判断缺失/额外”与真实行为不一致。
2. 动作：补充 host 模块 API 对齐测试（至少覆盖 search/info/tree/test/update/del）。
3. 动作：在 DEV 与 MAIN 各进行一轮真实节点集成回归，记录 fallback 触发率。
4. 动作：当 fallback 连续两个迭代触发率接近 0 时，提交 legacy 路径下线变更。
