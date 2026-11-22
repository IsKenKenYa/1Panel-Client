# distributeddatamgr_data_object 模块概述

## 模块职责

distributeddatamgr_data_object（分布式数据对象）是  分布式数据管理子系统下的部件，为应用程序提供跨设备的内存级数据对象同步能力。开发者可以创建分布式数据对象、设置 sessionId 实现多设备间数据自动同步、监听数据变更/设备状态/资产传输进度、持久化保存/撤销保存数据、绑定 RDB 资产、以及设置单个/多个资产。模块同时提供协作编辑（collaboration_edit）能力，支持文本协同编辑、撤销管理、节点操作等高级功能。

**基本信息：**
- **子系统**：distributeddatamgr
- **SysCap**：SystemCapability.DistributedDataManager.DataObject.DistributedObject
- **API 命名空间**：`@ohos.data.distributedDataObject`（dynamic since 8，static since 23）
- **权限**：`ohos.permission.DISTRIBUTED_DATASYNC`
- **Kit**：ArkData

## 目录结构（简化）

```
distributeddatamgr_data_object/
├── bundle.json
├── data_object.gni
├── interfaces/
│   ├── innerkits/                          # C++ 内部 API 头文件
│   │   ├── distributed_object.h            # DistributedObject 抽象类（Put*/Get*/Save/RevokeSave/BindAssetStore）
│   │   ├── distributed_objectstore.h       # DistributedObjectStore 抽象类（CreateObject/DeleteObject/Watch/UnWatch）
│   │   ├── object_types.h                  # AssetBindInfo/Asset/ValuesBucket 类型定义
│   │   └── objectstore_errors.h            # 内部错误码定义（BASE_ERR_OFFSET=1650）
│   └── jskits/
│       └── distributed_data_object.js      # JS 层实现（Proxy 拦截、setSessionId/save/setAsset 等业务逻辑）
├── frameworks/
│   ├── jskitsimpl/
│   │   ├── src/adaptor/                    # NAPI 桥接层
│   │   │   ├── js_module_init.cpp          # 模块注册入口（nm_modname="data.distributedDataObject"）
│   │   │   ├── js_distributedobjectstore.cpp # 核心桥接（createObjectSync/destroy/on/off/recordCallback）
│   │   │   ├── js_distributedobject.cpp    # 对象桥接（put/get/save/revokeSave/bindAssetStore）
│   │   │   ├── js_object_wrapper.cpp       # 对象包装器（管理 watcher 生命周期）
│   │   │   ├── js_watcher.cpp              # JS 回调监听器
│   │   │   ├── notifier_impl.cpp           # 状态变更通知实现
│   │   │   └── progress_notifier_impl.cpp  # 进度变更通知实现
│   │   ├── src/common/
│   │   │   └── object_error.cpp            # 公开错误码映射（201/401/801/15400001）
│   │   ├── src/lite/                       # Lite 变体
│   │   ├── include/adaptor/js_common.h     # 宏定义（INVALID_API_THROW_ERROR -> 801 等）
│   │   ├── include/common/
│   │   │   ├── object_error.h              # Error 类层次定义
│   │   │   ├── napi_queue.h                # NAPI 异步队列与参数校验宏
│   │   │   └── js_util.h                   # NAPI_ASSERT_ERRCODE_V9 宏
│   │   └── collaboration_edit/             # 协作编辑能力
│   │       ├── src/
│   │       │   ├── napi_collaboration_edit_object.cpp
│   │       │   ├── napi_edit_unit.cpp
│   │       │   ├── napi_node.cpp
│   │       │   ├── napi_text.cpp
│   │       │   ├── napi_undo_manager.cpp
│   │       │   ├── napi_sync_service.cpp
│   │       │   ├── napi_cloud_db.cpp
│   │       │   ├── napi_parser.cpp
│   │       │   ├── napi_error_utils.cpp    # 协作编辑错误抛出
│   │       │   └── entry_point.cpp
│   │       └── include/
│   │           └── napi_errno.h            # 协作编辑错误码（15410000~15410003）
│   ├── ets/taihe/ohos.data.distributedDataObject/  # ANI/ArkTS 静态化层（since 23）
│   │   ├── src/
│   │   │   ├── ohos.data.distributedDataObject.impl.cpp  # create/genSessionId 导出
│   │   │   ├── ohos.data.distributedDataObject.DataObject.cpp # DataObject 完整实现（setSessionId/save/on/off/setAsset 等）
│   │   │   ├── ani_dataobject_session.cpp  # Session 管理（数据同步、资产同步）
│   │   │   ├── ani_constructor.cpp         # 构造逻辑
│   │   │   ├── ani_watcher.cpp             # ANI 监听器
│   │   │   ├── ani_notifier_impl.cpp       # ANI 状态通知
│   │   │   ├── ani_progress_notifier_impl.cpp # ANI 进度通知
│   │   │   ├── ani_error_utils.cpp         # ANI 错误抛出（taihe::set_business_error）
│   │   │   └── ani_utils.cpp              # ANI 工具函数
│   │   └── include/
│   │       ├── ani_error_utils.h           # AniError 枚举（401/15400002/15400003）
│   │       └── ani_dataobject_session.h
│   └── innerkitsimpl/
│       ├── src/adaptor/                    # 存储引擎/对象实现
│       │   ├── distributed_object_store_impl.cpp  # DistributedObjectStoreImpl（单例，管理对象生命周期）
│       │   ├── distributed_object_impl.cpp        # DistributedObjectImpl（数据读写委托 flatObjectStore）
│       │   ├── flat_object_store.cpp              # 扁平对象存储（DB 操作）
│       │   ├── flat_object_storage_engine.cpp     # 存储引擎
│       │   ├── object_callback_impl.cpp           # IPC 回调实现
│       │   ├── client_adaptor.cpp                 # 客户端适配
│       │   └── asset_change_timer.cpp             # 资产变更定时器
│       └── src/communicator/              # 软总线通信
│           ├── communication_provider.cpp
│           ├── softbus_adapter_standard.cpp
│           ├── process_communicator_impl.cpp
│           ├── app_pipe_handler.cpp
│           ├── app_pipe_mgr.cpp
│           └── dev_manager.cpp
└── samples/
```

## 核心文件清单

| 文件 | 用途 |
|------|------|
| `interfaces/innerkits/distributed_objectstore.h` | 抽象接口：CreateObject / DeleteObject / Watch / UnWatch / SetStatusNotifier / SetProgressNotifier |
| `interfaces/innerkits/distributed_object.h` | 抽象接口：PutDouble/Boolean/String/Complex / GetDouble/Boolean/String/Complex / Save / RevokeSave / BindAssetStore |
| `interfaces/innerkits/objectstore_errors.h` | 内部错误码（SUCCESS=0 ~ ERR_NO_PERMISSION=1673，BASE_ERR_OFFSET=1650） |
| `frameworks/jskitsimpl/src/adaptor/js_module_init.cpp` | NAPI 模块注册入口，注册 7 个同步函数 |
| `frameworks/jskitsimpl/src/adaptor/js_distributedobjectstore.cpp` | JSCreateObjectSync / JSDestroyObjectSync / JSOn / JSOff / JSRecordCallback / JSDeleteCallback / JSEquenceNum |
| `frameworks/jskitsimpl/src/adaptor/js_distributedobject.cpp` | JSPut / JSGet / JSSave / JSRevokeSave / JSBindAssetStore |
| `frameworks/jskitsimpl/src/common/object_error.cpp` | 公开错误码映射（ParametersType=401, PermissionError=201, DatabaseError=15400001, DeviceNotSupportedError=801） |
| `frameworks/jskitsimpl/include/adaptor/js_common.h` | INVALID_API_THROW_ERROR（ERR_PROCESSING->801）、Constants（change/status/progressChanged） |
| `frameworks/innerkitsimpl/src/adaptor/distributed_object_store_impl.cpp` | 单例实现，委托 FlatObjectStore |
| `frameworks/innerkitsimpl/src/adaptor/distributed_object_impl.cpp` | 对象实现，委托 FlatObjectStore 进行 DB 操作 |
| `interfaces/jskits/distributed_data_object.js` | JS 层业务逻辑：DistributedV9 类（Proxy 拦截属性读写、setSessionId/save/revokeSave/setAsset/setAssets） |
| `frameworks/ets/taihe/.../ohos.data.distributedDataObject.DataObject.cpp` | ANI 静态化层核心：DataObjectImpl（JoinSession/LeaveSession/Save/RevokeSave/onChange/onStatus/onProgressChanged/setAsset/setAssets） |
| `frameworks/ets/taihe/.../include/ani_error_utils.h` | ANI 层错误码枚举（AniError_ParameterCheck=401, AniError_ParameterError=15400002, AniError_SessionJoined=15400003） |
| `frameworks/jskitsimpl/collaboration_edit/include/napi_errno.h` | 协作编辑错误码（EDIT_ERROR_OFFSET=15410000） |

## 技术架构要点

1. **三层架构**：JS 层（Proxy 拦截 + 业务逻辑） -> NAPI/ANI 桥接层（参数校验 + 异步调度） -> Innerkits 实现层（DistributedObjectStoreImpl + FlatObjectStore + 软总线通信）
2. **双轨 API**：Dynamic 模式（since 8，NAPI + JS）和 Static 模式（since 23，ANI/Taihe）。ANI 层不经过 JS 层，直接通过 `taihe::make_holder` 创建 C++ 对象。
3. **Session 机制**：对象通过 sessionId 加入分布式网络，底层通过软总线（SoftBus）进行数据同步。
4. **回调管理**：JS 层通过 `recordCallback/deleteCallback` 在全局映射中记录回调引用，对象重建（如页面切换）时自动恢复监听。ANI 层通过 DataObjectImpl 内部的 `changeCallBacks_/statusCallBacks_/progressCallBacks_` 列表管理。
5. **错误码映射**：内部错误码（objectstore_errors.h，1651~1673）在 NAPI/ANI 层映射为公开错误码（201/401/801/15400001/15400002/15400003）。
