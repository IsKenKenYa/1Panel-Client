# distributeddatamgr_preferences 常见问题

## 1. 参数错误 (401)

**现象**：`BusinessError: Code 401. Parameter error.`

**原因**：

- key 参数不是 string 类型（如传了 number 或 object）
- key 为空字符串
- key 长度超过 1024 字符（主 API）或 32 字符（@system.storage）
- value 不是合法的 ValueType（number/string/boolean/Array/Uint8Array/object/bigint）
- String value 长度超过 16MB
- 参数个数不对（如 put 传了少于 2 个参数）
- callback 参数不是 function 类型
- getPreferences 的 name 参数不是 string，或 dataGroupId 不是 string

**排查思路**：

1. 检查传入参数的类型和数量是否与 API 签名匹配
2. NAPI 层通过 `ParseKey` 校验 key 必须是 string 且长度 <= 1024
3. NAPI 层通过 `ParseDefValue` 校验 value 必须是合法 ValueType 且 string 长度 <= 16MB
4. 检查 ==Native API== 调用时所有指针参数非空
5. 底层 `PreferencesUtils::CheckKey` 和 `CheckValue` 会返回 E_KEY_EMPTY / E_KEY_EXCEED_MAX_LENGTH / E_VALUE_EXCEED_MAX_LENGTH，在 NAPI/==Native API== 层统一映射为 401

**关键源码**：

- `frameworks/common/include/preferences_error.h` — ParamTypeError/ParamNumError 类
- `frameworks/native/src/preferences_utils.cpp` — CheckKey/CheckValue

---

## 2. 能力不支持 (801)

**现象**：`BusinessError: Code 801. Capability not supported.`

**原因**：

- 当前设备不支持 `SystemCapability.DistributedDataManager.Preferences.Core`
- 内部错误码 E_NOT_SUPPORTED (E_BASE+801) 映射到 801

**排查思路**：

1. 确认目标设备的 SysCap 支持情况
2. 在调用前用 `canIUse('SystemCapability.DistributedDataManager.Preferences.Core')` 检查

---

## 3. 通用内部错误 (15500000)

**现象**：`BusinessError: Code 15500000. Inner error.`

**原因**：

- 底层返回的错误码在 `JS_ERROR_MAPS`（preferences_error.cpp）中找不到对应映射时，统一回退到 15500000
- 常见于文件 IO 异常、内存分配失败、XML 解析失败等未分类错误
- Preferences 实例为 nullptr 时也会触发

**排查思路**：

1. 查看 HiLog 中 Preferences 模块的详细日志（tag: PreferencesJsKit / Preferences）
2. 确认 preferencesDir 目录存在且可读写
3. 检查是否并发操作同一 Preferences 实例导致竞态

**关键源码**：

- `frameworks/common/src/preferences_error.cpp` — `JS_ERROR_MAPS` 数组 + `GetJsErrorCode()` 函数
- `frameworks/common/include/preferences_error.h` — `InnerError` 类构造逻辑

---

## 4. 删除文件失败 (15500010)

**现象**：`BusinessError: Code 15500010. Failed to delete the user preferences persistence file.`

**原因**：

- deletePreferences / deletePreferencesSync 调用时文件删除失败
- 文件不存在、权限不足、文件被其它进程锁定
- 内部错误码 E_DELETE_FILE_FAIL (E_BASE+10)

**排查思路**：

1. 确认 Preferences 文件路径正确（在 preferencesDir 下）
2. 确认应用对该目录有写权限
3. 确认没有其它线程/进程正在使用该 Preferences 实例
4. ==Native API== 中同样返回 15500010（PREFERENCES_ERROR_DELETE_FILE）

**关键源码**：

- `frameworks/native/src/preferences_helper.cpp` — DeletePreferences 实现
- `frameworks/common/src/preferences_error.cpp` — 映射 E_DELETE_FILE_FAIL -> 15500010

---

## 5. 存储错误 (15500011, ==Native API== 专用)

**现象**：==Native API== 返回 `PREFERENCES_ERROR_STORAGE (15500011)`

**原因**：

- OHConvertor::NativeErrTo==Native API== 中未匹配到的内部错误码统一映射为 15500011
- 常见于 XML 文件读写失败、Preferences 实例获取失败等
- ==Native API== OH_Preferences_SetValue 在 Put 失败时直接返回 15500011

**排查思路**：

1. 查看 HiLog 中 OH_Preferences 相关错误日志
2. 确认 Preferences 实例已通过 OH_Preferences_Open 成功打开
3. 确认文件系统状态正常

---

## 6. 获取订阅服务失败 (15500019)

**现象**：`BusinessError: Code 15500019. Failed to obtain the subscription service.`

**原因**：

- 注册 on('dataChange') / on('multiProcessChange') 观察者时，获取 DataObsMgrClient 失败
- 内部错误码 E_GET_DATAOBSMGRCLIENT_FAIL (E_BASE+19)

**排查思路**：

1. 确认系统数据观察者服务正常运行
2. 重试注册操作
3. 检查是否注册了过多观察者导致服务拒绝

**关键源码**：

- `frameworks/native/src/preferences_impl.cpp` — RegisterDataObserver/RegisterObserver

---

## 7. 仅 Stage 模式支持 (15501001)

**现象**：`BusinessError: Code 15501001. The operations is supported in stage mode only.`

**原因**：

- 在 FA 模型下调用 getPreferences 等 API
- 仅 stage 模型支持 Preferences 功能

**排查思路**：

1. 将应用迁移到 stage 模型
2. 或使用 legacy `@ohos.data.storage` API（支持 FA 模型）

---

## 8. 无效的 dataGroupId (15501002)

**现象**：`BusinessError: Code 15501002. Invalid dataGroupId.`

**原因**：

- getPreferences 传入的 options.dataGroupId 不合法
- dataGroupId 对应的沙箱目录不存在或不可访问

**排查思路**：

1. 检查 dataGroupId 是否为有效的跨应用数据组标识
2. 确认应用有权限访问该 dataGroupId 对应的目录

---

## 9. Key 不存在 (15500013, ==Native API== 专用)

**现象**：==Native API== 返回 `PREFERENCES_ERROR_KEY_NOT_FOUND (15500013)`

**原因**：

- OH_Preferences_GetAll 返回的数据为空时，映射为 15500013
- 内部 E_NO_DATA (E_BASE+22) 映射到此码
- 注意：OH_Preferences_GetValue 不会返回此码，找不到时返回默认值

**排查思路**：

1. 确认 Preferences 中确实有数据（先 OH_Preferences_SetValue 写入）
2. 确认使用了正确的 Preferences 文件名

---

## 10. 对象已关闭/不可用 (内部 E_OBJECT_NOT_ACTIVE / E_ALREADY_CLOSED)

**现象**：

- 底层 IsClose() 检查失败，上报 DFX 故障
- 日志中出现 "closed:Put" / "closed:Get" 等操作名
- JS 层表现为 15500000 Inner error

**原因**：

- 调用 removePreferencesFromCache / deletePreferences 后仍继续使用原 Preferences 实例
- Preferences 实例的 isActive_ 标志为 false
- 内部错误码 E_OBJECT_NOT_ACTIVE (E_BASE+27)

**排查思路**：

1. removePreferencesFromCache 后不要继续操作该实例
2. 如需再次使用，重新调用 getPreferences 获取新实例
3. 检查代码中 Preferences 实例的生命周期管理

**关键源码**：

- `frameworks/native/src/preferences_impl.cpp` — `IsClose()` 函数

---

## 11. @system.storage 专用错误码

**现象**：fail 回调收到负数错误码

| 错误码 | 含义                  | 原因                                                          |
| ------ | --------------------- | ------------------------------------------------------------- |
| -1006  | key 为空              | key 未传或为空字符串                                          |
| -1016  | key 超过 32 字符      | @system.storage 的 key 限制为 32 字符（不同于主 API 的 1024） |
| -1017  | value 超过 128 字符   | @system.storage 的 value 限制为 128 字符                      |
| -1018  | default 超过 128 字符 | get 操作的 default 值限制为 128 字符                          |

**排查思路**：

1. @system.storage 有更严格的长度限制（key<=32, value/default<=128）
2. 如需存储更大数据，迁移到 `@ohos.data.preferences`（key<=1024, value<=16MB）

**关键源码**：

- `frameworks/js/napi/system_storage/src/napi_system_storage.cpp` — `ConversionToSysStorageErrorCode()` 和 `GetMessageInfo()`

---

## 12. ==Native API== 内存分配失败 (15500012)

**现象**：==Native API== 返回 `PREFERENCES_ERROR_MALLOC (15500012)`

**原因**：

- OH_Preferences_Open 中 new OH_PreferencesImpl 失败
- OH_Preferences_GetAll 中 malloc OH_PreferencesPair 数组失败

**排查思路**：

1. 检查系统内存状态
2. 减少同时打开的 Preferences 实例数量

---

## 错误码映射关系总结

### 内部 C++ 错误码 -> JS 公开错误码

| 内部错误码                              | JS 公开错误码 | message                               |
| --------------------------------------- | ------------- | ------------------------------------- |
| E_INVALID_ARGS (E_BASE+2)               | 401           | Parameter error                       |
| E_KEY_EMPTY (E_BASE+5)                  | 401           | Parameter error                       |
| E_KEY_EXCEED_MAX_LENGTH (E_BASE+6)      | 401           | Parameter error                       |
| E_VALUE_EXCEED_MAX_LENGTH (E_BASE+14)   | 401           | Parameter error                       |
| E_NOT_SUPPORTED (E_BASE+801)            | 801           | Capability not supported              |
| E_DELETE_FILE_FAIL (E_BASE+10)          | 15500010      | Failed to delete file                 |
| E_GET_DATAOBSMGRCLIENT_FAIL (E_BASE+19) | 15500019      | Failed to obtain subscription service |
| 其它未映射                              | 15500000      | Inner error                           |

### 内部 C++ 错误码 -> ==Native API== 错误码

| 内部错误码                  | Native api 错误码 | 说明                         |
| --------------------------- | ------------------ | ---------------------------- |
| E_OK                        | 0 (PREFERENCES_OK) | 成功                         |
| E_INVALID_ARGS              | 401                | 参数错误                     |
| E_KEY_EMPTY                 | 401                | key 为空                     |
| E_KEY_EXCEED_MAX_LENGTH     | 401                | key 超长                     |
| E_VALUE_EXCEED_MAX_LENGTH   | 401                | value 超长                   |
| E_NOT_SUPPORTED             | 801                | 不支持                       |
| E_DELETE_FILE_FAIL          | 15500010           | 删除失败                     |
| E_GET_DATAOBSMGRCLIENT_FAIL | 15500019           | 订阅服务失败                 |
| E_NO_DATA                   | 15500013           | key 不存在                   |
| E_OBSERVER_RESERVE          | 0                  | 观察者保留（映射为成功）     |
| 其它                        | 15500011           | 存储错误（==fallback==） |
