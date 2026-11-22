# data_share (数据共享) 部件概述

## 模块职责

data_share 部件 (bundle `@ohos/data_share`, subsystem `distributeddatamgr`) 为系统提供跨应用数据共享能力。数据提供方通过 `DataShareExtensionAbility` 暴露数据,数据访问方通过 `DataShareHelper` 进行增删改查,并支持静默访问 (Silent Proxy)、模板订阅 (Template)、已发布数据管理 (PublishedData)、共享配置 (DataProxyHandle) 等高级特性。配套提供 `DataSharePredicates` 谓词构造器和 `DataShareResultSet` 结果集遍历器。

SysCap:
- `SystemCapability.DistributedDataManager.DataShare.Core`
- `SystemCapability.DistributedDataManager.DataShare.Consumer`
- `SystemCapability.DistributedDataManager.DataShare.Provider`

## 简化目录树

```
distributeddatamgr_data_share/
├── bundle.json                          # 部件定义: @ohos/data_share
├── frameworks/
│   ├── js/napi/
│   │   ├── dataShare/src/               # NAPI 模块 data.dataShare (createDataShareHelper 等)
│   │   │   ├── native_datashare_module.cpp      # 模块入口, 导出 4 个函数
│   │   │   ├── napi_datashare_helper.cpp        # DataShareHelper 实例方法绑定
│   │   │   └── napi_dataproxy_handle.cpp        # DataProxyHandle 实例方法绑定
│   │   ├── common/
│   │   │   ├── src/datashare_predicates_proxy.cpp  # DataSharePredicates NAPI 绑定
│   │   │   └── include/datashare_error.h           # JS 公共错误码 (401/202/15700000-15700015)
│   │   ├── datashare_ext_ability/        # DataShareExtensionAbility JS 模块
│   │   └── datashare_ext_ability_context/
│   └── native/                           # C++ 原生框架 (common/consumer/provider/proxy)
├── interfaces/inner_api/
│   ├── common/include/
│   │   ├── datashare_errno.h            # 内部错误码 (E_BASE=1000 .. E_SYSTEM_ABILITY_OPERATE_FAILED=1089)
│   │   ├── datashare_predicates.h       # 谓词内部接口
│   │   └── datashare_template.h         # 模板内部接口
│   ├── consumer/include/
│   │   ├── datashare_helper.h           # DataShareHelper inner_api
│   │   ├── dataproxy_handle.h           # DataProxyHandle inner_api
│   │   └── datashare_result_set.h       # DataShareResultSet inner_api
│   └── provider/include/
│       └── result_set_bridge.h          # 数据提供方结果集桥接
└── test/                                # 测试用例
```

## 核心文件清单

| 文件路径 | 用途 |
|---|---|
| `frameworks/js/napi/dataShare/src/native_datashare_module.cpp` | NAPI 模块 `data.dataShare` 入口, 导出 createDataShareHelper / enableSilentProxy / disableSilentProxy / createDataProxyHandle |
| `frameworks/js/napi/dataShare/src/napi_datashare_helper.cpp` | DataShareHelper 实例方法 NAPI 绑定 (insert/delete/query/update/batchInsert/notifyChange/normalizeUri/denormalizeUri/on/off/addTemplate/delTemplate/publish/getPublishedData/close) |
| `frameworks/js/napi/dataShare/src/napi_dataproxy_handle.cpp` | DataProxyHandle 实例方法 NAPI 绑定 (publish/delete/deleteMyPublishedData/get/on/off/putValue/removeValue/getValues) |
| `frameworks/js/napi/common/src/datashare_predicates_proxy.cpp` | DataSharePredicates 全部谓词方法 NAPI 绑定 (equalTo/notEqualTo/contains/like/glob/between/greaterThan/limit/in/inKeys 等) |
| `frameworks/js/napi/common/include/datashare_error.h` | JS 层公开错误码常量 (401/202/15700000/15700010-15700015) |
| `interfaces/inner_api/common/include/datashare_errno.h` | 内部错误码头文件 (E_OK=0, E_BASE=1000, E_ERROR=1001 .. E_SYSTEM_ABILITY_OPERATE_FAILED=1089) |
| `interfaces/inner_api/consumer/include/datashare_helper.h` | DataShareHelper inner_api 头文件 (C++ 客户端实现) |
| `interfaces/inner_api/consumer/include/dataproxy_handle.h` | DataProxyHandle inner_api 头文件 |
| `interfaces/inner_api/consumer/include/datashare_result_set.h` | DataShareResultSet inner_api 头文件 |
| `frameworks/js/napi/dataShare/src/native_datashare_predicates_module.cpp` | NAPI 模块 `data.dataSharePredicates` 入口, 调用 DataSharePredicatesProxy::Init |
| `frameworks/js/napi/datashare_ext_ability/datashare_ext_ability_module.cpp` | NAPI 模块 `application.DataShareExtensionAbility` 注册 |
