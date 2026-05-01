# Phase C 第2批实改：File / Log / Container（2026-04-12）

## 目标

- 按 P0 优先级先处理 `file + log + container` 三个模块的缺失端点。
- 同步补齐 alignment 单测，纳入 `test_runner.dart unit --module=<name>` 自动发现。

## 实改清单

### FileV2Api

新增端点：

1. `POST /containers/files/search`
2. `POST /containers/files/content`
3. `POST /containers/files/size`
4. `POST /containers/files/del`
5. `POST /containers/files/download`
6. `GET /containers/daemonjson/file`
7. `POST /backups/search/files`
8. `GET /logs/system/files`
9. `POST /files/wget/stop`
10. `POST /containers/files/upload`

### LogsV2Api

新增端点：

1. `GET /containers/search/log`
2. `POST /containers/clean/log`
3. `POST /containers/compose/clean/log`
4. `POST /containers/logoption/update`
5. `POST /cronjobs/records/log`

### ContainerV2Api

新增端点：

1. `POST /containers/compose/search`
2. `POST /containers/compose/operate`
3. `POST /containers/compose/env`
4. `POST /containers/compose/update`
5. `POST /containers/compose/test`
6. `POST /containers/compose/clean/log`
7. `GET /runtimes/php/container/{id}`
8. `POST /runtimes/php/container/update`

## 对齐测试补充

新增/扩展：

1. `test/api_client/file_v2_alignment_test.dart`（新增 9 条）
2. `test/api_client/logs_v2_alignment_test.dart`（新增文件，5 条）
3. `test/api_client/container_v2_alignment_test.dart`（新增文件，8 条）

## 验证结果

### 定向 alignment 测试

- 运行：3 个 alignment 文件
- 结果：`passed=24 failed=0`

### 模块化 unit 门禁

- 运行：
  - `dart run test/scripts/test_runner.dart unit --module=file`
  - `dart run test/scripts/test_runner.dart unit --module=log`
  - `dart run test/scripts/test_runner.dart unit --module=container`
- 结果：通过（日志尾部 `All tests passed!`）

### 覆盖差异复核（第2批后）

1. `file`: `missing=0`, `extra=1`（`POST /files/download`）
2. `log`: `missing=0`, `extra=2`（`GET /logs/tasks/executing/count`, `POST /logs/tasks/search`）
3. `container`: `missing=0`, `extra=1`（`POST /containers/command`）

## 口径修正

- `analyze_module_api.py` 补充 `file/log/container` 精确 matcher，避免关键词误匹配导致的伪缺失。

## 结论

- 本批目标已完成：`file + log + container` 三模块缺失端点清零（`missing=0`）。
- 当前残留均为“客户端额外端点”，下一批进入契约偏差治理（保留/迁移/下线）。
