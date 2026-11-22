# distributeddatamgr_preferences 模块概览

## 模块职责

distributeddatamgr_preferences（Preferences）是分布式数据管理子系统下的轻量级 Key-Value 存储部件。数据以键值对形式存储在内存中，持久化到本地 XML 文件（或通过 GSKV 后端存储），适用于少量偏好数据的快速读写场景。Key 为非空字符串且不超过 1024 字符（@system.storage 限制为 32），String Value 不超过 16MB（@system.storage 限制为 128）。支持数据变更监听（本地 change、多进程 multiProcessChange、按 key 的 dataChange）。该模块提供了 5 个 API 面：主 `@ohos.data.preferences`（since 9/13）、`@ohos.data.sendablePreferences`（Sendable 跨线程）、`@ohos.data.storage`（legacy since 6）、`@system.storage`（旧 system API）、Native API `oh_preferences.h`（since 13）。

## 目录结构（简化树）

```
distributeddatamgr_preferences/
├── bundle.json
├── preferences.gni
├── interfaces/
│   ├── inner_api/include/          # C++ 内部 API 头文件
│   │   ├── preferences.h           # Preferences 抽象类（Put/Get/Delete/Clear/Flush/HasKey/RegisterObserver）
│   │   ├── preferences_helper.h     # PreferencesHelper（GetPreferences/DeletePreferences/RemovePreferencesFromCache）
│   │   ├── preferences_errno.h     # 内部错误码定义（E_BASE 偏移 0x1A60000）
│   │   ├── preferences_observer.h  # 观察者接口
│   │   ├── preferences_value.h     # PreferencesValue 值类型
│   │   └── preferences_visibility.h
│   └── xxx/include/               # Native API C 接口头文件
│       ├── oh_preferences.h       # OH_Preferences_Open/Close/SetValue/GetValue/GetAll 等
│       ├── oh_preferences_value.h # OH_PreferencesValue 值操作
│       ├── oh_preferences_option.h # OH_PreferencesOption 选项
│       └── oh_preferences_err_code.h # Native API 错误码枚举
├── frameworks/
│   ├── common/                     # JS/NAPI 公共错误处理
│   │   ├── include/preferences_error.h  # JS 错误码映射（15500000 系列）+ JSError 类
│   │   └── src/preferences_error.cpp    # JS_ERROR_MAPS 映射表
│   ├── js/napi/                    # NAPI JS 绑定（5 个子模块）
│   │   ├── common/                 # 公共工具：js_ability, js_common_utils, js_observer, napi_async_call 等
│   │   ├── preferences/            # @ohos.data.preferences NAPI
│   │   ├── sendable_preferences/   # @ohos.data.sendablePreferences NAPI
│   │   ├── storage/               # @ohos.data.storage NAPI（legacy）
│   │   └── system_storage/        # @system.storage NAPI（旧 system API）
│   ├── ets/taihe/preferences/      # ANI/ArkTS 静态化层
│   ├── cj/                         # Cangjie 语言 FFI
│   ├── native/                     # C++ 核心实现
│   │   ├── src/
│   │   │   ├── preferences_impl.cpp      # PreferencesImpl（主实现类）
│   │   │   ├── preferences_helper.cpp    # PreferencesHelper（实例管理 + 缓存）
│   │   │   ├── preferences_xml_utils.cpp # XML 读写
│   │   │   └── preferences_utils.cpp     # CheckKey/CheckValue 工具函数
│   │   └── include/
│   │       └── preferences_utils.h
│   └── xxx/                        # Native API C 接口实现
│       └── src/
│           ├── oh_preferences.cpp  # OH_Preferences_* 函数实现
│           └── oh_convertor.cpp    # 内部错误码到 Native API 错误码映射
└── test/                           # 测试
```

## 核心文件清单

### 内部 API 头文件（interfaces/inner_api/include/）

| 文件                       | 用途                                                                                                                                                                                        |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `preferences.h`          | Preferences 抽象基类，定义 Put/Get/Delete/Clear/Flush/FlushSync/HasKey/RegisterObserver/UnRegisterObserver/RegisterDataObserver 等纯虚函数。常量 MAX_KEY_LENGTH=1024, MAX_VALUE_LENGTH=16MB |
| `preferences_helper.h`   | PreferencesHelper 静态类，管理 Preferences 实例缓存（prefsCache_ map），提供 GetPreferences/DeletePreferences/RemovePreferencesFromCache/IsStorageTypeSupported                             |
| `preferences_errno.h`    | 内部 C++ 错误码定义。基址 offset = (13<<21)\|(6<<16) = 27656192。E_OK~E_OBJECT_NOT_ACTIVE(E_BASE+27) 等 28 个错误码                                                                         |
| `preferences_observer.h` | PreferencesObserver 观察者接口，定义 RegisterMode 枚举（LOCAL_CHANGE/MULTI_PRECESS_CHANGE/DATA_CHANGE）                                                                                     |
| `preferences_value.h`    | PreferencesValue 值类型，支持 int/string/bool/float/double/long/Uint8Array/object/bigint                                                                                                    |

### JS/NAPI 层（frameworks/js/napi/）

| 文件                                            | 用途                                                                                                                                                                                              |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `common/include/preferences_error.h`          | JS 公开错误码常量（401/801/15500000/15500010/15500019/15501001/15501002）+ ParamTypeError/ParamNumError/InnerError 类 + PRE_NAPI_ASSERT 宏                                                        |
| `common/src/preferences_error.cpp`            | JS_ERROR_MAPS 映射表，将内部 nativeCode 映射到 JS jsCode + message                                                                                                                                |
| `preferences/src/napi_preferences.cpp`        | PreferencesProxy 类，注册 put/putSync/get/getSync/getAll/getAllSync/delete/deleteSync/clear/clearSync/has/hasSync/flush/flushSync/on/off                                                          |
| `preferences/src/napi_preferences_helper.cpp` | 模块函数注册（InitPreferencesHelper）：getPreferences/getPreferencesSync/deletePreferences/deletePreferencesSync/removePreferencesFromCache/removePreferencesFromCacheSync/isStorageTypeSupported |
| `storage/src/napi_storage.cpp`                | StorageProxy 类（legacy @ohos.data.storage），注册 put/putSync/get/getSync/delete/deleteSync/clear/clearSync/has/hasSync/flush/flushSync/on/off                                                   |
| `storage/src/napi_storage_helper.cpp`         | GetStorage/GetStorageSync（legacy）                                                                                                                                                               |
| `system_storage/src/napi_system_storage.cpp`  | @system.storage 的 get/set/delete/clear/has（success/fail/complete 回调模式，key<=32, value<=128）                                                                                                |

### Native API 层（frameworks/xxx/）

| 文件                       | 用途                                                                                                                                                                                                                   |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/oh_preferences.cpp` | OH_Preferences_Open/Close/SetValue/GetValue/GetAll/DeletePreferences/HasAll/Check/Persist/Delete 实现，通过 OH_PreferencesImpl 包装 inner Preferences                                                                  |
| `src/oh_convertor.cpp`   | NativeErrToNativeAPI 错误码映射表：内部 E_OK/E_INVALID_ARGS/E_KEY_EMPTY/E_KEY_EXCEED_MAX_LENGTH/E_VALUE_EXCEED_MAX_LENGTH -> Native API 401；E_DELETE_FILE_FAIL -> 15500010；E_NO_DATA -> 15500013；未匹配 -> 15500011 |

### C++ 核心实现（frameworks/native/）

| 文件                              | 用途                                                                                                                                                                                                                  |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/preferences_impl.cpp`      | PreferencesImpl 主实现类。Put（CheckKey+CheckValue+更新 valuesCache_）、Delete、Clear（isCleared_标志）、Flush/FlushSync（WriteToDiskFile 写 XML）、Get/GetValue、GetAllDatas、HasKey、IsClose 检查（isActive_ 标志） |
| `src/preferences_helper.cpp`    | PreferencesHelper 实现。管理 prefsCache_（map<string, pair<shared_ptr<Preferences></preferences>, bool>>），GetPreferencesInner 决定使用 PreferencesImpl 还是 EnhanceImpl                                             |
| `src/preferences_utils.cpp`     | PreferencesUtils::CheckKey（空检查+长度1024检查）、CheckValue（string 长度16MB检查+object JSON 长度检查+bigint 非空检查）                                                                                             |
| `src/preferences_xml_utils.cpp` | XML 文件读写（WriteSettingXml/ReadSettingXml）                                                                                                                                                                        |

## API 面与 SysCap

| API 面                         | 声明文件                                     | since                     | SysCap                                                   |
| ------------------------------ | -------------------------------------------- | ------------------------- | -------------------------------------------------------- |
| @ohos.data.preferences         | `api/@ohos.data.preferences.d.ts`          | 9 (dynamic) / 23 (static) | SystemCapability.DistributedDataManager.Preferences.Core |
| @ohos.data.sendablePreferences | `api/@ohos.data.sendablePreferences.d.ets` | 12                        | SystemCapability.DistributedDataManager.Preferences.Core |
| @ohos.data.storage             | `api/@ohos.data.storage.d.ts`              | 6 (deprecated)            | SystemCapability.DistributedDataManager.Preferences.Core |
| @system.storage                | `api/@system.storage.d.ts`                 | 6 (deprecated)            | SystemCapability.DistributedDataManager.Preferences.Core |
| Native API oh_preferences      | `interfaces/xxx/include/oh_preferences.h`  | 13                        | SystemCapability.DistributedDataManager.Preferences.Core |

## 关键约束

- **Key**：非空 String，主 API 上限 1024 字符（`Preferences::MAX_KEY_LENGTH`）；@system.storage 上限 32 字符
- **Value**：String 类型上限 16MB（`Preferences::MAX_VALUE_LENGTH`）；@system.storage 上限 128 字符
- **不支持多进程**：Preferences 非线程安全，多进程使用可能导致文件损坏和数据丢失
- **数据量建议**：不超过 1 万条键值对
- **持久化**：put/delete/clear 操作仅修改内存，需调用 flush/flushSync 才落盘
