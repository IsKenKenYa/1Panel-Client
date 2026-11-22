# relational_store 部件概览

## 模块职责

relational_store 是 OpenHarmony/ 分布式数据管理子系统(distributeddatamgr)下的关系型数据库部件,基于 SQLite 提供本地关系型数据库的完整管理能力,包括增删改查、事务、SQL 直接执行、分布式表同步与端云同步。通过 NAPI 向 JS/ArkTS 层暴露 `relationalStore`(RdbStore / RdbPredicates / ResultSet / Transaction / ValuesBucket / StoreConfig 等)和 `cloudData`(云同步配置与共享)两大模块,同时提供 Native API(C) 接口和 inner_api(C++) 接口。

## 简化目录树

```
distributeddatamgr_relational_store/
  bundle.json
  frameworks/
    js/napi/
      relationalstore/src/entry_point.cpp          -- NAPI 模块入口 data.relationalStore
      rdb/src/
        napi_rdb_store_helper.cpp                  -- getRdbStore / deleteRdbStore 实现
        napi_rdb_store.cpp                         -- RdbStore 类 NAPI 绑定
        napi_rdb_predicates.cpp                    -- RdbPredicates 类 NAPI 绑定
        napi_result_set.cpp                        -- ResultSet 类 NAPI 绑定
        napi_values_bucket.cpp                     -- ValuesBucket 工具
        napi_rdb_store_observer.cpp                -- 数据变更观察者
      cloud_data/src/entry_point.cpp               -- NAPI 模块入口 data.cloudData
      cloud_data/src/js_config.cpp                 -- cloudData.configure
      sendablerelationalstore/src/                 -- 跨线程可共享版本
      dataability/src/                             -- DataAbility 适配
    native/rdb/include/
      rdb_store_impl.h                             -- RdbStore 实现
      rdb_manager_impl.h / rdb_store_manager.h     -- 数据库管理器
      connection_pool.h / connection.h             -- 连接池
      sqlite_errno.h                               -- SQLite 错误码映射
    native/dfx/include/
      rdb_dfx_errno.h                              -- DFX 诊断错误码
  interfaces/
    inner_api/rdb/include/
      rdb_store.h, rdb_helper.h, rdb_store_config.h
      rdb_predicates.h, abs_rdb_predicates.h
      result_set.h, abs_result_set.h
      values_bucket.h, value_object.h
      rdb_errno.h                                  -- 内部错误码定义
      transaction.h
    inner_api/cloud_data/include/
      cloud_manager.h, cloud_service.h, cloud_types.h
    xxx/include/
      relational_store.h, relational_store_error_code.h,
      oh_predicates.h, oh_value_object.h, oh_values_bucket.h
```

## 核心文件清单

| path                                                        | 用途                                                                                                                                                                                           |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `frameworks/js/napi/relationalstore/src/entry_point.cpp`  | NAPI 模块`data.relationalStore` 注册入口,Init 调用 InitRdbHelper / RdbStoreProxy::Init / RdbPredicatesProxy::Init / ResultSetProxy::Init / LiteResultSetProxy::Init / TransactionProxy::Init |
| `frameworks/js/napi/rdb/src/napi_rdb_store_helper.cpp`    | 模块级函数 getRdbStore / deleteRdbStore / getRdbStoreV9 / deleteRdbStoreV9 的 NAPI 实现                                                                                                        |
| `frameworks/js/napi/rdb/src/napi_rdb_store.cpp`           | RdbStore 类方法 NAPI 绑定(insert/delete/update/query/querySql/batchInsert/executeSql/beginTransaction/commit/rollBack/attach/setDistributedTables/sync/on/off 等)                              |
| `frameworks/js/napi/rdb/src/napi_rdb_predicates.cpp`      | RdbPredicates 类方法 NAPI 绑定(equalTo/like/orderByAsc/groupBy/limit/in/or/and/join 等)                                                                                                        |
| `frameworks/js/napi/rdb/src/napi_result_set.cpp`          | ResultSet 类方法 NAPI 绑定(goToFirstRow/getString/getLong/getBlob/getColumnIndex/close 等)                                                                                                     |
| `frameworks/js/napi/rdb/src/napi_values_bucket.cpp`       | ValuesBucket 类型转换工具                                                                                                                                                                      |
| `frameworks/js/napi/cloud_data/src/entry_point.cpp`       | NAPI 模块`data.cloudData` 注册入口                                                                                                                                                           |
| `frameworks/js/napi/cloud_data/src/js_config.cpp`         | cloudData.configure / CloudDB 实现                                                                                                                                                             |
| `frameworks/native/rdb/include/rdb_store_impl.h`          | RdbStore C++ 实现(增删改查/事务/分布式/云同步)                                                                                                                                                 |
| `frameworks/native/rdb/include/sqlite_errno.h`            | SQLite 错误码到 RDB 内部错误码的映射表                                                                                                                                                         |
| `frameworks/native/dfx/include/rdb_dfx_errno.h`           | DFX 诊断专用错误码                                                                                                                                                                             |
| `interfaces/inner_api/rdb/include/rdb_store.h`            | RdbStore 抽象接口(inner_api)                                                                                                                                                                   |
| `interfaces/inner_api/rdb/include/rdb_helper.h`           | RdbHelper 接口(getRdbStore 工厂)                                                                                                                                                               |
| `interfaces/inner_api/rdb/include/rdb_store_config.h`     | StoreConfig 配置定义                                                                                                                                                                           |
| `interfaces/inner_api/rdb/include/rdb_errno.h`            | 内部错误码常量定义(E_OK ~ E_SYNC_PERMISSION_DENIED)                                                                                                                                            |
| `interfaces/inner_api/rdb/include/result_set.h`           | ResultSet 抽象接口                                                                                                                                                                             |
| `interfaces/inner_api/rdb/include/values_bucket.h`        | ValuesBucket 接口                                                                                                                                                                              |
| `interfaces/inner_api/rdb/include/transaction.h`          | Transaction 接口                                                                                                                                                                               |
| `interfaces/inner_api/cloud_data/include/cloud_manager.h` | 云数据管理接口                                                                                                                                                                                 |
| `interfaces/xxx/include/relational_store.h`               | Native API C 接口(OH_Rdb_GetOrCreate / OH_Rdb_Execute 等)                                                                                                                                             |
| `interfaces/xxx/include/relational_store_error_code.h`    | Native API 错误码枚举(OH_Rdb_ErrCode)                                                                                                                                                                 |
| `interfaces/xxx/include/oh_predicates.h`                  | Native API 谓词接口                                                                                                                                                                                   |
| SDK 声明:`@ohos.data.relationalStore.d.ts`                | TS/ArkTS API 声明                                                                                                                                                                              |
| SDK 声明:`@ohos.data.cloudData.d.ts`                      | 云数据 API 声明                                                                                                                                                                                |
| SDK 声明:`@ohos.data.sendableRelationalStore.d.ets`       | 跨线程可共享版本 API 声明                                                                                                                                                                      |
| 文档:`errorcode-data-rdb.md`                              | 公开错误码说明                                                                                                                                                                                 |
| 文档:`js-apis-data-relationalStore.md`                    | relationalStore API 用法文档                                                                                                                                                                   |
