# distributeddatamgr_distributeddatamgr_cangjie_wrapper

## 模块职责

Cangjie (仓颉) 语言封装层，为 OpenHarmony 分布式数据管理子系统提供原生的 Cangjie API。该模块覆盖 5 个底层数据组件：data_share_predicates (数据共享谓词)、distributed_kv_store (分布式键值数据库)、preferences、relational_store (关系型数据库) 和 values_bucket (值桶类型)。通过 FFI (C ABI) 桥接，使 Cangjie 语言应用开发者能够使用数据存储、查询、同步等能力。本模块为 Beta 特性，版本 6.1。ROM 约 900KB / RAM 约 864KB。

## 目录结构

```
distributeddatamgr_distributeddatamgr_cangjie_wrapper/
├── ohos/
│   └── data/
│       ├── data.cj                          # 根包声明
│       ├── data_share_predicates/           # 数据共享谓词模块
│       ├── distributed_kv_store/            # 分布式键值数据库模块
│       ├── preferences/                  
│       ├── relational_store/                # 关系型数据库模块
│       └── values_bucket/                   # 值桶类型模块
├── kit/
│   └── ArkData/
│       └── index.cj                         # Kit 统一导出
├── mock/                                    # Mock 实现 (编译占位)
├── test/                                    # 单元测试
│   ├── data_share_predicates/
│   ├── distributed_kv_store/
│   ├── hide_distributed/
│   ├── preferences/
│   └── relational_store/
├── bundle.json                              # 部件构建配置
└── BUILD.gn                                 # GN 构建入口
```

## 核心文件

### FFI 桥接层 (`*_ffi.cj`)

- `ohos/data/relational_store/relational_store_ffi.cj` — 声明 `FfiOHOSRelationalStore*` 系列 foreign 函数 (约 80+ 个 FFI 入口)，包含 `@C struct` 类型 (RetStoreConfig, RetValueType, CValuesBucket, RetAsset 等) 用于跨 C ABI 数据编组。
- `ohos/data/distributed_kv_store/distributed_kv_store_ffi.cj` — 声明 `FfiOHOSDistributedKVStore*` 系列 foreign 函数，含 CKVValueType、CEntry、CArrEntry、COptions 等 @C 结构体。
- `ohos/data/preferences/preferences_ffi.cj` — 声明 `FfiOHOSPreferences*` 系列 foreign 函数，含 CPreferencesValueType、CPreferencesValueTypes 等 @C 结构体。
- `ohos/data/data_share_predicates/data_share_predicates_ffi.cj` — 声明 `FfiOHOSDataSharePredicates*` 系列 foreign 函数。

### 公共 API 层 (`*.cj`)

- `ohos/data/relational_store/relational_store.cj` — 公共函数 `getRdbStore`、`deleteRdbStore`。
- `ohos/data/relational_store/rdb_store.cj` — `RdbStore` 类：query、insert、update、delete、batchInsert、querySql、executeSql、beginTransaction、commit、rollBack、backup、restore、on、off、emit 等。
- `ohos/data/relational_store/rdb_predicates.cj` — `RdbPredicates` 类：equalTo、contains、like、between、orderByAsc、limitAs、groupBy 等条件构建方法。
- `ohos/data/relational_store/result_set.cj` — `ResultSet` 类：goToRow、goToFirstRow、goToNextRow、getLong、getString、getDouble、getBlob、getColumnName、getColumnIndex、close 等。
- `ohos/data/distributed_kv_store/distributed_kv_store.cj` — `DistributedKVStore` 类 (createKVManager) 和 `KVManager` 类 (getKVStore、closeKVStore、deleteKVStore、getAllKVStoreId)。
- `ohos/data/distributed_kv_store/single_kvstore.cj` — `SingleKVStore` 类：put、putBatch、delete、deleteBatch、get、backup、restore、startTransaction、commit、rollback、enableSync、setSyncParam 等。
- `ohos/data/distributed_kv_store/device_kvstore.cj` — `DeviceKVStore` 类：get (by device)、getEntries 等。
- `ohos/data/distributed_kv_store/kvstore_result_set.cj` — `KVStoreResultSet` 类：getCount、getPosition、moveToFirst 等。
- `ohos/data/distributed_kv_store/query.cj` — `Query` 类：构造函数 (调用 FfiOHOSDistributedKVStoreQueryConstructor)。
- `ohos/data/preferences/preferences.cj` — `Preferences` 类：getPreferences、deletePreferences、removePreferencesFromCache、put、get、getAll、delete、has、flush、clear、on、off 等。
- `ohos/data/data_share_predicates/data_share_predicates.cj` — `DataSharePredicates` 类：equalTo、and、orderByAsc、orderByDesc、limit、inValues、or、beginWrap、endWrap。
- `ohos/data/values_bucket/value_type.cj` — `VBValueType` 枚举和 `CValueType` @C 结构体。

### 错误码与常量 (`*_common.cj` / `*_options.cj`)

- `ohos/data/relational_store/relational_store_common.cj` — ERROR_CODE_MAP (30+ 条目)、E_BASE 常量定义、StoreConfig、CryptoParam 等公共类型、throwIfNotSuccess/getErrorCode/getErrorMsg 辅助函数。
- `ohos/data/distributed_kv_store/distributed_kv_store_common.cj` — ERROR_CODE_MAP (6 条目)、Constants、KVOptions、Schema、Entry 等类型、getErrorCode/getErrorMsg 辅助函数。
- `ohos/data/data_share_predicates/data_share_predicates_common.cj` — throwIfNotSuccess/getErrorMsg 辅助函数。
- `ohos/data/preferences/preferences_options.cj` — NATIVE_ERROR_MSG、CJ_ERROR_MSG、NATIVE_ERR_TO_CJ_ERR_MAP 映射表、PreferencesOptions、PreferencesValueType 等类型。

### Kit 导出

- `kit/ArkData/index.cj` — 通过 `public import` 统一导出全部 5 个子模块的公共 API。

### 构建配置

- `bundle.json` — 部件元信息 (名称、版本、ROM/RAM 资源估算)。
- `BUILD.gn` — GN 构建入口。
