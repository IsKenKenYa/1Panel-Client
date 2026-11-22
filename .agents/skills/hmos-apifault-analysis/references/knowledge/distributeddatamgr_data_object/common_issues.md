# distributeddatamgr_data_object 常见问题排查指南

## 1. 错误码 201：权限校验失败

**现象**：调用 `setSessionId`、`createObjectSync` 等需要分布式同步的 API 时，抛出 `code: 201, message: "Permission verification failed."`

**原因**：
- 应用未在 `module.json5` 中声明 `ohos.permission.DISTRIBUTED_DATASYNC` 权限
- 用户未在系统设置中授予分布式数据同步权限
- 内部错误码 ERR_NO_PERMISSION (1673) 从 `DistributedObjectStore::CreateObject` 返回

**排查步骤**：
1. 检查 `module.json5` 的 `requestPermissions` 中是否包含 `ohos.permission.DISTRIBUTED_DATASYNC`
2. 检查应用是否为 stage 模型，确保 `requestPermissions` 配置正确
3. 检查用户是否已通过 `requestPermissionsFromUser` 授权
4. 查看日志中是否有 `ERR_NO_PERMISSION` 内部错误

**代码位置**：
- NAPI 层映射：`frameworks/jskitsimpl/src/adaptor/js_distributedobjectstore.cpp` 第 197 行（`result != ERR_NO_PERMISSION -> PermissionError`）
- ANI 层映射：`frameworks/ets/taihe/.../ohos.data.distributedDataObject.DataObject.cpp` 第 572 行（`ERR_NO_PERMISSION -> PermissionError`）
- 错误定义：`frameworks/jskitsimpl/src/common/object_error.cpp` 第 45-65 行

---

## 2. 错误码 401：参数错误

**现象**：调用各种 API 时抛出 `code: 401, message: "Parameter error..."`

**原因及对应场景**：
- **参数数量不足**：`createObjectSync` 需要 3~4 个参数（version, sessionId, objectId[, context]），`on/off` 需要 4 个参数
- **参数类型错误**：sessionId 应为 string，callback 应为 function，object 应为 DistributedObject 实例
- **sessionId 格式不合法**：仅允许字母、数字、下划线（_），最大 128 字符（正则 `^[a-zA-Z0-9_]+$`）
- **save 的 deviceId 为空**（ANI 层校验）

**排查步骤**：
1. 检查 API 参数数量和类型是否匹配 .d.ts 声明
2. 对 setSessionId，检查 sessionId 是否满足正则 `SESSION_ID_REGEX`（字母+数字+下划线，<=128字符）
3. 查看日志中的 `ParametersType` / `ParametersNum` 错误信息

**代码位置**：
- 错误定义：`frameworks/jskitsimpl/src/common/object_error.cpp`（ParametersType, ParametersNum）
- sessionId 格式校验（JS 层）：`interfaces/jskits/distributed_data_object.js` 第 441 行
- sessionId 格式校验（ANI 层）：`frameworks/ets/taihe/.../ohos.data.distributedDataObject.DataObject.cpp` 第 619-624 行
- NAPI 参数校验宏：`frameworks/jskitsimpl/include/common/js_util.h` 第 127-135 行（`NAPI_ASSERT_ERRCODE_V9`）

---

## 3. 错误码 801：设备能力不支持

**现象**：调用 `save`、`revokeSave`、`bindAssetStore` 时抛出 `code: 801, message: "Capability not supported."`

**原因**：
- 内部错误码 ERR_PROCESSING (1669) 从 `DistributedObject::Save/RevokeSave/BindAssetStore` 返回
- 通常因为设备不支持分布式数据持久化能力，或 datamgr_service 不可用

**排查步骤**：
1. 检查设备的 SystemCapability 是否包含 `SystemCapability.DistributedDataManager.DataObject.DistributedObject`
2. 检查分布式数据服务（datamgr_service）是否正常运行
3. 查看日志中 `ERR_PROCESSING` 内部错误的具体上下文

**代码位置**：
- 错误定义：`frameworks/jskitsimpl/src/common/object_error.cpp` 第 77-85 行（DeviceNotSupportedError）
- 映射宏：`frameworks/jskitsimpl/include/adaptor/js_common.h` 第 52-60 行（`INVALID_API_THROW_ERROR`，当 ERR_PROCESSING 时设置 DeviceNotSupportedError）
- ANI 层映射：`frameworks/ets/taihe/.../ani_dataobject_session.cpp` 第 113-116 行

---

## 4. 错误码 15400001：创建内存数据库失败

**现象**：调用 `setSessionId` 或 `create` 时抛出 `code: 15400001, message: "Failed to create the in-memory database."`

**原因**：
- 内部错误码 ERR_EXIST (1652) 表示同一 sessionId 已被另一个分布式数据对象占用
- 同一应用中多个对象使用了相同的 sessionId
- 前一个使用相同 sessionId 的对象未被正确销毁

**排查步骤**：
1. 检查是否有多个分布式数据对象使用了相同的 sessionId
2. 确保前一个对象在创建新对象前调用了 `destroyObjectSync` 或 `setSessionId("")` 退出会话
3. 检查对象生命周期管理，避免对象泄漏
4. 使用 `genSessionId()` 生成唯一 sessionId 以避免冲突

**代码位置**：
- 错误定义：`frameworks/jskitsimpl/src/common/object_error.cpp` 第 51-59 行（DatabaseError）
- NAPI 层映射：`frameworks/jskitsimpl/src/adaptor/js_distributedobjectstore.cpp` 第 196 行（`result != ERR_EXIST -> DatabaseError`）
- ANI 层映射：`frameworks/ets/taihe/.../ohos.data.distributedDataObject.DataObject.cpp` 第 568-571 行

---

## 5. 错误码 15400002：setAsset/setAssets 参数错误

**现象**：调用 `setAsset` 或 `setAssets` 时抛出 `code: 15400002`

**原因及对应场景**：
- `assetKey` 或 `assetsKey` 为空字符串
- `uri` 为空字符串或 null
- `uris` 不是数组，或数组长度为 0，或长度超过 50
- `uris` 数组中存在空字符串元素

**排查步骤**：
1. 检查 assetKey/assetsKey 是否为非空字符串
2. 检查 uri/uris 是否有效（非空、对应实际存在的资产）
3. 对于 setAssets，检查 uris 数组长度在 1~50 范围内
4. 确认 uri 指向的文件存在于 distributedFilesDir 目录下

**代码位置**：
- JS 层校验：`interfaces/jskits/distributed_data_object.js` 第 382-387, 502-549 行
- ANI 层校验：`frameworks/ets/taihe/.../ohos.data.distributedDataObject.DataObject.cpp` 第 726-800 行
- ANI 错误码定义：`frameworks/ets/taihe/.../include/ani_error_utils.h` 第 26 行（`AniError_ParameterError = 15400002`）

---

## 6. 错误码 15400003：sessionId 已设置

**现象**：调用 `setAsset` 或 `setAssets` 时抛出 `code: 15400003, message: "The sessionId of the distributed object has been set."`

**原因**：
- `setAsset/setAssets` 必须在 `setSessionId` 之前调用
- 当对象已经加入分布式会话（sessionId 非空）时，不允许修改资产属性

**排查步骤**：
1. 检查调用顺序：确保 `setAsset/setAssets` 在 `setSessionId` 之前调用
2. 检查是否在同一对象上重复设置资产
3. 如果需要重新设置资产，先退出会话（`setSessionId("")`），再设置资产，最后重新加入会话

**代码位置**：
- JS 层校验：`interfaces/jskits/distributed_data_object.js` 第 503-508, 525-531 行
- ANI 层校验：`frameworks/ets/taihe/.../ohos.data.distributedDataObject.DataObject.cpp` 第 730-735, 766-771 行
- ANI 错误码定义：`frameworks/ets/taihe/.../include/ani_error_utils.h` 第 27 行（`AniError_SessionJoined = 15400003`）

---

## 7. Sandbox 限制问题

**现象**：在 DLP（数据防泄漏）沙箱应用中调用 `createObjectSync` 或 `setSessionId` 时静默失败或返回 null

**原因**：
- `JSDistributedObjectStore::IsSandBox()` 检测到应用运行在 DLP 沙箱环境中
- 沙箱应用不允许创建分布式数据对象

**排查步骤**：
1. 检查应用是否被 DLP 策略标记（`AccessTokenKit::GetHapDlpFlag` 返回值非 0）
2. 查看日志中 `IsSandBox` 相关信息

**代码位置**：
- NAPI 层：`frameworks/jskitsimpl/src/adaptor/js_distributedobjectstore.cpp` 第 177, 529-544 行
- ANI 层：`frameworks/ets/taihe/.../ohos.data.distributedDataObject.DataObject.cpp` 第 554-558 行

---

## 8. 协作编辑模块错误（15410000~15410003）

**现象**：使用 collaboration_edit API 时抛出 `code: 15410xxx`

**错误码对照**：
- `15410000`：内部错误（INTERNAL_ERROR）
- `15410001`：不支持的操作（UNSUPPORTED_OPERATION）
- `15410002`：索引越界（INDEX_OUT_OF_RANGE）
- `15410003`：数据库错误（DB_ERROR）
- `202`：非系统应用（NOT_SYSTEM_APP）
- `401`：参数错误（INVALID_ARGUMENT）

**代码位置**：
- 错误码定义：`frameworks/jskitsimpl/collaboration_edit/include/napi_errno.h`
- 错误抛出：`frameworks/jskitsimpl/collaboration_edit/src/napi_error_utils.cpp`

---

## 9. 内部错误码（不直接暴露给应用）

以下内部错误码（`objectstore_errors.h`，BASE_ERR_OFFSET=1650）在 NAPI/ANI 层被映射为公开错误码或被吞掉：

| 内部码 | 名称 | 可能的公开映射 |
|--------|------|---------------|
| 1651 | ERR_DB_SET_PROCESS | 无（内部处理） |
| 1652 | ERR_EXIST | 15400001 |
| 1654 | ERR_NOMEM | 无（返回 null） |
| 1661 | ERR_NULL_OBJECT | 无（返回失败） |
| 1663 | ERR_NULL_OBJECTSTORE | 无（返回失败） |
| 1669 | ERR_PROCESSING | 801 |
| 1671 | ERR_INVALID_ARGS | 无（内部处理） |
| 1673 | ERR_NO_PERMISSION | 201 |

排查底层问题时，需要在日志中搜索这些内部错误码值。
