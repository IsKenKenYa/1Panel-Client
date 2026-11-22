# distributeddatamgr_kv_store 常见问题模式

## 1. 权限问题

### 1.1 分布式同步权限不足 (Status::PERMISSION_DENIED / JS 202)
- **C++ Status**: `PERMISSION_DENIED`
- **JS 错误码**: 202（非系统应用使用系统 API）
- **场景**: 非系统应用调用了仅系统应用可用的 API（如 DataShare 相关查询 `getResultSet` / `delete` with predicates）。
- **代码位置**: `js_single_kv_store.cpp` 中 `ASSERT_PERMISSION_ERR` 宏检查 `IsSystemApp()`。
- **解决**: 确认应用是否为系统应用，或避免调用标记为 `@systemapi` 的方法。

### 1.2 分布式数据同步权限
- **权限**: `ohos.permission.DISTRIBUTED_DATASYNC`
- **场景**: 跨设备同步数据 (`sync`)、订阅远端数据变更 (`on('dataChange', SUBSCRIBE_TYPE_REMOTE)`) 需要此权限。
- **解决**: 在 `module.json5` 中声明该权限，并在运行时向用户申请授权。

## 2. 参数校验问题 (Status::INVALID_ARGUMENT / JS 401 / 15100000)

- **C++ Status**: `INVALID_ARGUMENT`
- **JS 错误码**: 401（旧 API）/ 15100000（新 API）
- **常见原因**（基于 `js_kv_manager.cpp`、`js_single_kv_store.cpp` 参数校验逻辑）:
  - **必填参数缺失**: `argc < N`，如 `createKVManager` 未传 `bundleName`、`getKVStore` 未传 `storeId`/`options`。
  - **key 为空或类型错误**: `put`/`get`/`delete` 中 key 必须为非空 string。
  - **storeId 非法**: 必须仅含字母、数字、下划线，限 128 字符。
  - **appId 为空或超长**: `getAllKVStoreId` 中 appId 不能为空且不超 256 字符。
  - **securityLevel 非法**: `options.securityLevel` 不能为 `INVALID_LABEL`（即 S1/S2/S3/S4 之一）。
  - **kvStoreType 不支持**: 仅支持 `SINGLE_VERSION` 或 `DEVICE_COLLABORATION`。
  - **value 类型错误**: `put` 的 value 不在 `string|number|boolean|Uint8Array` 之内。
  - **backup 文件名非法**: 文件名不能为空且不能为保留名 `autoBackup`。
  - **sync mode 超范围**: `mode` 必须 <= `SyncMode::PUSH_PULL` (2)。
- **代码位置**: 各 NAPI 函数的 `ASSERT_BUSINESS_ERR` 宏调用点。

## 3. 存储状态问题

### 3.1 KVStore 未打开 (Status::STORE_NOT_OPEN)
- **场景**: 未先调用 `getKVStore` 就操作 KVStore，或服务未就绪。
- **JS 表现**: 对应 JS 错误码为 0（不直接抛错，内部处理），通常表现为操作静默失败或空指针。

### 3.2 KVStore 或结果集已关闭 (Status::ALREADY_CLOSED / JS 15100005)
- **场景**: 调用 `closeKVStore` 后仍操作 KVStore 对象，或 `closeResultSet` 后仍访问结果集。
- **代码位置**: `js_single_kv_store.cpp` 中 `kvStore == nullptr` 检查，以及底层 `SingleKvStore` 代理失效。
- **解决**: 确保在 close 之前完成所有操作，或在 close 后重新 `getKVStore`。

## 4. 数据库/存储故障

### 4.1 数据库损坏 (Status::DATA_CORRUPTED / Status::CRYPT_ERROR / JS 15100003)
- **场景**: sqlite 数据库文件损坏、磁盘异常、加密密钥不匹配。
- **自动恢复**: `GetKVStore` 检测到 `DATA_CORRUPTED` 时会设置 `options.rebuild = true` 尝试重建数据库（见 `js_kv_manager.cpp:153-157`）。
- **解决**: 如果自动恢复失败，需删除数据库文件后重新创建。

### 4.2 WAL 文件超限 (Status::WAL_OVER_LIMITS / JS 14800047)
- **场景**: sqlite WAL (Write-Ahead Log) 文件大小超过默认限制。
- **解决**: 减少并发写入量，或通过 `EXEC_CHECKPOINT` Pragma 命令触发 checkpoint 合并 WAL。

### 4.3 数据库无法打开 (Status::DB_CANT_OPEN)
- **场景**: 文件权限问题、路径不存在、数据库文件被锁。
- **解决**: 检查文件权限、路径有效性，确保无其它进程持有锁。

## 5. 同步问题

### 5.1 网络错误 (Status::NETWORK_ERROR)
- **场景**: 分布式同步时网络不可达。
- **解决**: 检查设备网络连接和分布式通信链路。

### 5.2 同步正在进行 (Status::SYNC_ACTIVATED)
- **场景**: 上一次同步尚未完成就再次调用 `sync`。
- **解决**: 等待 `syncComplete` 回调后再发起新的同步。

### 5.3 设备未在线 (Status::DEVICE_NOT_ONLINE)
- **场景**: `sync` 的目标设备 ID 不在线或未组网。
- **解决**: 确认设备已通过 `deviceManager` 完成可信组网且在线。

## 6. Schema 问题

### 6.1 Schema 不匹配 (Status::SCHEMA_MISMATCH)
- **场景**: 打开已存在 Schema 数据库时 Schema 定义变更，或写入数据字段与 Schema 不一致。
- **解决**: 保持 Schema 定义一致，或删除数据库后使用新 Schema 重建。

### 6.2 Schema 无效 (Status::INVALID_SCHEMA)
- **场景**: Schema 格式不合法（JSON 格式错误、字段类型不支持等）。
- **解决**: 参照 `Schema` 类文档正确构造 Schema JSON。

### 6.3 字段类型/值无效 (Status::INVALID_VALUE_FIELDS / INVALID_FIELD_TYPE / INVALID_FORMAT)
- **场景**: Schema 模式下 `put` 写入的数据值/类型与 Schema 定义不匹配。
- **代码位置**: `store_errno.h:120-138`，底层 sqlite 约束检查。

## 7. 加密问题

### 7.1 加密错误 (Status::CRYPT_ERROR / JS 15100003)
- **场景**: `rekey` 操作失败、加密级别冲突。
- **解决**: 确认加密口令正确，`rekey` 操作需在 KVStore 处于空闲状态时进行。

### 7.2 安全级别错误 (Status::SECURITY_LEVEL_ERROR)
- **场景**: 本地与远端设备的 SecurityOption 不一致，阻止同步。
- **解决**: 确保同步两端设备的 `securityLevel` 设置一致。

## 8. 订阅问题

### 8.1 重复订阅 (Status::STORE_ALREADY_SUBSCRIBE)
- **场景**: 使用相同的 `SubscribeType` 和回调函数多次调用 `on('dataChange')`。
- **代码位置**: `js_single_kv_store.cpp:823-828`，检查 `JSUtil::Equals` 回调是否已存在。
- **解决**: 先 `off` 再 `on`，或使用不同的回调函数。

### 8.2 未订阅 (Status::STORE_NOT_SUBSCRIBE)
- **场景**: `off('dataChange')` 时未找到已注册的观察者。
- **代码位置**: `js_single_kv_store.cpp:883`，`ASSERT_BUSINESS_ERR(ctxt, found...)`。

### 8.3 超出观察者上限 (Status::OVER_MAX_LIMITS / JS 15100001)
- **场景**: 注册的数据变更观察者数量超过系统最大限制。
- **解决**: 取消不再需要的观察者订阅，释放名额。

## 9. 访问限流

### 9.1 超过最大访问频率 (Status::EXCEED_MAX_ACCESS_RATE)
- **场景**: 短时间内频繁调用 KVStore API（如循环 `put` 大量数据）超过系统限流阈值。
- **解决**: 降低调用频率，使用 `putBatch` 批量写入，或加入适当延迟。

### 9.2 会话限流 (Status::RATE_LIMIT)
- **场景**: 会话正在打开中，并发请求触发限流。

## 10. 云存储

### 10.1 云存储禁用 (Status::CLOUD_DISABLED)
- **场景**: 设备未登录华为帐号或未开启云同步开关。
- **解决**: 引导用户登录帐号并在设置中开启云同步。

### 10.2 不支持广播 (Status::NOT_SUPPORT_BROADCAST)
- **场景**: 当前设备/数据库不支持云广播能力。

## 11. 单例约束

- **规则**: 对于指定路径仅支持创建数据库单例，不支持同一路径创建多数据库实例对象（README 约束）。
- **场景**: 同一 `bundleName` + `baseDir` 路径下使用不同 `storeId` 可以创建多个 KVStore，但同一 `storeId` 重复 `getKVStore` 会返回已有实例。尝试用不同 `Options`（如不同 `securityLevel`）重新打开已有 store 会返回 `STORE_META_CHANGED`（JS 15100002）。
- **解决**: 确保同一 storeId 的 Options 在整个应用生命周期内一致。
