# 常见问题

## 通用错误码

### 201 — Permission denied

- **原因**: 应用缺少执行该操作所需的权限 (ohos.permission.*)。
- **修复**: 在 `module.json5` 中声明所需权限并确保用户已授权。

### 401 — Parameter error

- **原因**: 参数类型不匹配、必填参数为空 (如 `table` 为空字符串)、参数值不合法 (如负数 limit)。
- **修复**: 检查参数类型和取值，特别是字符串参数不为空。Cangjie 层通常在调用 FFI 前进行参数校验，例如 `field.isEmpty()` 检查后直接抛出 401。

### 801 — Capability not supported

- **原因**: 当前设备不支持该能力 (如某些 SQL 语句 attach/begin/commit/rollback 在特定场景下不支持)，或存储类型不支持。
- **修复**: 检查设备能力，使用 `canIUse` 判断，或更换实现方式。

## 关系型数据库 (relational_store)

### 14800000 — Inner error

- **原因**: Cangjie 封装层内部错误，包括内存分配失败 (MEMORY_ERROR = -1 映射到 14800000)、枚举值解析异常、未知错误码兜底。
- **修复**: 检查日志中的 `"Inner code is ${code % 14800000}"` 定位底层具体错误。

### 14800010 — Invalid database path

- **原因**: `StoreConfig` 中的数据库路径无效。
- **修复**: 检查 `name`、`customDir`、`rootDir` 参数是否合法。

### 14800011 — Database corrupted

- **原因**: SQLite 数据库文件损坏 (E_BASE+56)，可能因异常关机、文件被外部修改导致。
- **修复**: 使用 `backup()`/`restore()` 恢复备份，或 `deleteRdbStore()` 后重新创建。

### 14800014 — Already closed

- **原因**: RdbStore 或 ResultSet 实例已关闭，再次调用其方法 (E_BASE+30)。
- **修复**: 检查 `isClosed` 属性，确保不在 `close()` 之后访问对象。注意 GC 析构 `~init()` 会调用 `releaseFFIData`。

### 14800015 — The database does not respond

- **原因**: 数据库繁忙，长时间无响应 (E_BASE+34)。
- **修复**: 检查是否有长事务未提交，减少并发写入。

### 14800017 — Config changed

- **原因**: 使用与上次打开不同的 `StoreConfig` 打开同一数据库 (E_BASE+70)。
- **修复**: 确保每次打开同一数据库时 `StoreConfig` 一致，或先删除再重新创建。

### 14800019 — The SQL must be a query statement

- **原因**: 对 ResultSet 使用了非查询 SQL (E_BASE+7)。
- **修复**: 确保 `querySql()` 中传入的是 SELECT 语句。

### 14800021 — SQLite: Generic error

- **原因**: SQLite 通用错误 (E_BASE+55)，常见于 insert 失败或更新的数据不存在。
- **修复**: 检查 SQL 语句、表名、列名是否正确，确认数据约束。

### 14800026 — SQLite: Out of memory

- **原因**: SQLite 内存分配失败 (E_BASE+62)。Cangjie 层也可能在 C 代码 malloc 失败时直接抛出此码 (如 `getBlob`/`getAssets` 中 `size == -1`)。
- **修复**: 检查数据量是否过大，减少单次操作的数据规模。

### 14800047 — WAL file size over limit

- **原因**: WAL 文件大小超过默认限制 (E_BASE+47)，常见于大量写入未 checkpoint。
- **修复**: 定期调用 `commit()` 触发 checkpoint，或减少大批量写入。

## 分布式键值数据库 (distributed_kv_store)

### 15100002 — Open existed database with changed options

- **原因**: 使用不同的 `KVOptions` (如 securityLevel、encrypt) 重新打开已存在的数据库。
- **修复**: 确保每次 `getKVStore` 使用相同的 options，或先 `deleteKVStore` 再用新 options 创建。

### 15100003 — Database corrupted

- **原因**: KV 数据库损坏。内部返回码 -1 会被 `getErrorCode()` 映射为 15100003。
- **修复**: 使用 `backup()`/`restore()` 恢复备份，或删除数据库重建。

### 15100004 — Not found

- **原因**: 指定的 key 不存在，或 storeId 未找到。
- **修复**: 先用 `get()` 前检查 key 是否存在，或捕获异常使用默认值。

### 15100005 — Database or result set already closed

- **原因**: 在已关闭的 KVStore 或 KVStoreResultSet 上执行操作。
- **修复**: 确保 `closeKVStore()` 后不再访问该实例，检查 `KVStoreResultSet` 是否已被关闭。

## preferences

### 15500000 — Inner error

- **原因**: preferences 内部错误。包括 `ERR_INVALID_INSTANCE_CODE` (-1) 映射为 15500000。
- **修复**: 检查 Preferences 实例是否有效，查看日志中的 nativeErrorCode 获取底层信息。

### 15500010 — Failed to delete preferences file

- **原因**: 删除 preferences 持久化文件失败 (ERROR_BASE+10)。可能文件被占用或权限不足。
- **修复**: 确保文件未被其它进程锁定，检查文件权限。

### 15500019 — Failed to obtain subscription service

- **原因**: 获取 DataObsMgrClient 服务失败 (ERROR_BASE+19)。注册 `on()` 观察者时可能触发。
- **修复**: 检查系统服务是否正常运行。

### 15501001 — Not stage mode

- **原因**: 当前不在 stage 模式下，操作仅支持 stage 模式。
- **修复**: 确保应用使用 stage 模型 (UIAbilityContext)，而非 FA 模型。

### 15501002 — Invalid dataGroupId

- **原因**: `PreferencesOptions.dataGroupId` 无效或不存在。Cangjie 层 `checkCodeAndThrow` 对未知错误码也会默认抛出此码。
- **修复**: 检查 `dataGroupId` 是否正确，确保对应的 data share group 已创建。

## 数据共享谓词 (data_share_predicates)

### 16000050 — Internal error

- **原因**: FFI 返回 -1 或谓词对象创建失败 (id < 0)。
- **修复**: 检查参数合法性，确保在正确的上下文中使用。

## Cangjie 封装特有问题

### Beta 特性

本 Cangjie 封装为 Beta 版本，API 可能存在变化。README 中已声明 Beta 状态。

### 错误码映射机制

- **relational_store**: 底层返回 `E_BASE + N` (E_BASE = 27394048) 的内部码，通过 `ERROR_CODE_MAP` 映射为公开错误码 (如 E_BASE+56 -> 14800011)。MEMORY_ERROR (-1) 映射为 14800000。
- **distributed_kv_store**: 底层返回 -1 映射为 15100003 (corrupted)。
- **preferences**: 底层返回 `ERROR_BASE + N` (ERROR_BASE = 27656192)，通过 `NATIVE_ERR_TO_CJ_ERR_MAP` 映射为公开码 (如 ERROR_BASE+10 -> 15500010)。-1 映射为 15500000。

### 内存管理风险

- FFI 桥接层使用 `@C struct` 进行数据编组，需要手动管理 C 内存 (`LibC.free`)。
- 每个需要释放的路径都有 `free()` 方法。如果异常发生在 malloc 和 free 之间，可能导致内存泄漏。
- 特别是 `RetValueType`、`CValuesBucket`、`RetAsset` 等 @C 结构体，在异常分支中需要先释放已分配的内存再抛出异常 (`throwIfOOM` 的 handler 模式)。
- 使用 `.asResource()` (CTypeResource) 模式可以确保 RAII 自动释放，推荐使用。

### 通用错误码获取

- `getUniversalErrorMsg()` 优先检查 `UNIVERSAL_ERROR_MAP` (201/401/801)。
- 如果不在通用码中，再查模块特定的 `ERROR_CODE_MAP`。
- 兜底返回 `"Inner error"` 或 `"Unknown error code"`。
