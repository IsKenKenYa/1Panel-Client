# distributeddatamgr_kv_store 模块概览

## 模块职责

distributeddatamgr_kv_store（KV 数据库 / KV Store）是分布式数据管理子系统的核心部件，依托公共基础库提供的 KV 存储能力开发，为设备应用提供键值对数据管理能力。支持单版本/多设备 KV 存储、分布式数据同步、Schema 描述数据格式、数据备份恢复、加密存储及云存储；底层存储引擎基于 DistributedDB（sqlite）。在有进程的平台上，KV 存储以基础库形式加载在应用进程，保障不被其它进程访问。

- 子系统: distributeddatamgr
- SysCap: SystemCapability.DistributedDataManager.KVStore.Core / SystemCapability.DistributedDataManager.DistributedKVStore
- features: kv_store_cloud / kv_store_device

## 目录结构（3 层）

```
distributeddatamgr_kv_store/
├── frameworks/
│   ├── common/          # 公共工具类
│   ├── innerkitsimpl/   # 部件间接口实现（service 层）
│   ├── jskitsimpl/      # JS/NAPI API 实现
│   ├── libs/            # DistributedDB 存储引擎（基于 sqlite）
│   └── native/          # 内部接口实现
├── interfaces/
│   ├── inner_api/       # 内部接口声明
│   ├── innerkits/       # 部件间接口声明（C++）
│   └── jskits/          # JS API 声明
├── databaseutils/       # 数据库工具
├── kvstoremock/         # mock 实现
└── test/                # 测试用例
```

## 核心文件清单

| 文件路径 | 用途 |
|---------|------|
| frameworks/jskitsimpl/distributedkvstore/src/entry_point.cpp | NAPI 模块注册入口（新版），nm_modname="data.distributedKVStore"，Init 注册 createKVManager + FieldNode/Schema/Query 构造器 + 常量 |
| frameworks/jskitsimpl/distributeddata/src/entry_point.cpp | NAPI 模块注册入口（旧版），nm_modname="data.distributedData" |
| frameworks/jskitsimpl/distributedkvstore/src/js_kv_manager.cpp | KVManager NAPI 桥接：createKVManager / getKVStore / closeKVStore / deleteKVStore / getAllKVStoreId / on / off |
| frameworks/jskitsimpl/distributedkvstore/src/js_single_kv_store.cpp | SingleKVStore NAPI 桥接：put / delete / get / putBatch / deleteBatch / getEntries / getResultSet / closeResultSet / sync / startTransaction / commit / rollback / backup / restore / rekey / on / off 等 ~27 方法 |
| frameworks/jskitsimpl/distributedkvstore/src/js_device_kv_store.cpp | DeviceKVStore NAPI 桥接：继承 SingleKVStore，重写 get / getEntries / getResultSet / getResultSize（支持 deviceId 参数） |
| frameworks/jskitsimpl/distributedkvstore/src/js_kv_store_resultset.cpp | KvStoreResultSet NAPI 桥接：结果集 moveToFirst/moveToNext/getEntry/rowCount 等 |
| frameworks/jskitsimpl/distributedkvstore/src/js_observer.cpp | 数据变更观察者 NAPI 桥接 |
| frameworks/jskitsimpl/distributedkvstore/src/js_query.cpp | Query NAPI 桥接：equalTo/notEqualTo/greaterThan/like/and/or 等 24 方法 |
| frameworks/jskitsimpl/distributedkvstore/src/js_schema.cpp | Schema NAPI 桥接 |
| frameworks/jskitsimpl/distributedkvstore/src/js_field_node.cpp | FieldNode NAPI 桥接 |
| frameworks/jskitsimpl/distributedkvstore/src/js_const_properties.cpp | NAPI 常量注册（KVStoreType / SecurityLevel / SyncMode / SubscribeType 等） |
| frameworks/jskitsimpl/distributedkvstore/src/js_error_utils.cpp | JS 错误码转换工具：Status → JS BusinessError 映射 |
| frameworks/jskitsimpl/distributedkvstore/src/napi_queue.cpp | NAPI 异步任务队列 |
| frameworks/jskitsimpl/distributedkvstore/src/uv_queue.cpp | UV 事件队列（回调分发） |
| frameworks/jskitsimpl/distributedkvstore/src/js_util.cpp | NAPI 类型转换工具（key/value/Options 序列化等） |
| interfaces/innerkits/distributeddata/include/single_kvstore.h | SingleKvStore C++ 接口声明（innerkits） |
| interfaces/innerkits/distributeddata/include/kvstore.h | KvStore 抽象基类声明 |
| interfaces/innerkits/distributeddata/include/distributed_kv_data_manager.h | DistributedKvDataManager 管理器接口声明 |
| interfaces/innerkits/distributeddata/include/kvstore_observer.h | 数据变更观察者接口声明 |
| interfaces/innerkits/distributeddata/include/kvstore_result_set.h | 结果集接口声明 |
| interfaces/innerkits/distributeddata/include/data_query.h | DataQuery 查询构造器接口声明 |
| interfaces/innerkits/distributeddata/include/store_errno.h | C++ Status 枚举错误码定义（约 40 个码） |
| interfaces/innerkits/distributeddata/include/types.h | 类型定义（Key / Value / Entry / Options 等） |
| frameworks/innerkitsimpl/distributeddatasvc/include/ikvstore_data_service.h | KVStore 数据服务 IPC 接口 |
| frameworks/innerkitsimpl/kvdb/include/kvdb_service.h | KVDB 服务实现 |
| frameworks/libs/distributeddb/interfaces/include/store_types.h | DistributedDB 底层 DBStatus 枚举（约 80 个码） |
| frameworks/libs/distributeddb/interfaces/include/kv_store_errno.h | DistributedDB errno 转换声明 |
| frameworks/libs/distributeddb/include/kv_store_delegate.h | KV Store Delegate 声明 |
| frameworks/libs/distributeddb/include/kv_store_nb_delegate.h | Non-blocking KV Store Delegate 声明 |
| frameworks/libs/distributeddb/include/relational_store_delegate.h | 关系型存储 Delegate 声明 |

## 约束

- KV 大小及可存储条目数在平台可承受内可修改配置，通过修改编译宏修改。
- 依赖平台具有正常的文件创建、读写删除修改、锁等能力。
- 由于平台能力差异数据库能力需要做相应裁剪。
- 对于指定路径仅支持创建数据库单例，不支持同一路径创建多数据库实例对象。
