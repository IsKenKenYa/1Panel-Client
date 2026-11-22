# accesscontrol_sandbox_manager 常见问题模式

> 错误码定义见 `error_codes.json`。`errcode` 指 `SandboxManagerErrCode`（int32_t，整体返回），`rettype` 指 `SandboxRetType`（uint32_t，单条 PolicyInfo 结果）。

## 1. 权限问题（统一返回 errcode PERMISSION_DENIED=1）

所有权限校验失败均返回 `1`，并通过 `SandboxManagerDfxHelper::ReportPolicyViolate` 上报。排查方向：先确认调用方 TokenId/UID，再对照下表核对所需权限。

| 接口                                                         | 所需权限 / UID 限定                                          |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| SetPolicy / SetPolicyAsync                                   | `ohos.permission.SET_SANDBOX_POLICY`                         |
| SetPolicy（带结果向量重载）                                  | `SET_SANDBOX_POLICY` + UID=SPACE_MGR_SERVICE_UID(7013)       |
| SetPolicyByBundleName                                        | `SET_SANDBOX_POLICY` + UID=FOUNDATION_UID(5523)              |
| CheckPolicy                                                  | `ohos.permission.CHECK_SANDBOX_POLICY`                       |
| CheckPersistPolicy                                           | `ohos.permission.CHECK_SANDBOX_POLICY`                       |
| PersistPolicy                                                | `ohos.permission.FILE_ACCESS_PERSIST`                        |
| UnPersistPolicy                                              | `ohos.permission.FILE_ACCESS_PERSIST`                        |
| StartAccessingPolicy / StopAccessingPolicy                   | `ohos.permission.FILE_ACCESS_PERSIST`（部分限 FOUNDATION_UID） |
| CleanPersistPolicyByPath                                     | `ohos.permission.FILE_ACCESS_MANAGER`                        |
| GetPersistPolicy                                             | `ohos.permission.GET_FILE_ACCESS_PERSIST`                    |
| UnsetShareFileInfo（重载）                                   | `ohos.permission.REVOKE_FILE_ACCESS_PERSIST`                 |
| SetShareFileInfo / UpdateShareFileInfo / UnsetShareFileInfo  | UID=FOUNDATION_UID(5523)                                     |
| GetSharedDirectoryInfo / Grant / RevokeSharedDirectoryPermission | `ohos.permission.ACCESS_SHARED_FILE`                         |
| CleanPolicyByUserId                                          | UID=FOUNDATION_UID                                           |

排查方向：

- 用 `hidumper -s 3508` 或 `bm dump` 确认调用方 TokenId 与声明权限是否匹配。
- 若日志含 `ReportPolicyViolate ... SG_REPORT_PERMISSION_DENIED`，说明走了 `CheckPermission` 失败分支（sandbox_manager_service.cpp ）。
- `IsFileManagerCalling`校验 native token 必须为 `file_manager_service`，否则 `FILE_ACCESS_PERMISSION_NAME` 校验失败。

## 2. 参数问题（errcode INVALID_PARAMTER=2）

| 场景                                             | 触发码                                      | 排查方向                                                                                               |
| ------------------------------------------------ | ------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| policy 列表为空                                  | errcode 2                                   | Kit 层（sandbox_manager_kit.cpp）优先校验，未到 service                                                |
| 路径超长（>4095）                                | errcode 2 / rettype INVALID_PATH=3          | 校验`POLICY_PATH_LIMIT`；截断或拆分路径                                                              |
| 批量超限（vector 上限 500 / MAX_BATCH_COUNT=32） | errcode 2                                   | 分批调用；持久化批量可用 PERSIST_POLICY_BATCH_SIZE=200000                                              |
| mode 位组合非法                                  | rettype INVALID_MODE=2                      | OperateMode 位掩码：READ=1/WRITE=2/CREATE=4/DELETE=8/RENAME=16/DENY_READ=32/DENY_WRITE=64/MAX_MODE=128 |
| path 格式不合法 / 非沙箱路径                     | rettype INVALID_PATH=3                      | 确认路径前缀在允许的沙箱根目录内（含媒体路径 media_path_support）                                      |
| policyFlag 导致不可持久化                        | rettype FORBIDDEN_TO_BE_PERSISTED_BY_FLAG=6 | 区分：标志位禁止 vs 路径本身属性禁止（rettype 1）                                                      |

注：`INVALID_PARAMTER` 为源码原文拼写（sandbox_manager_err_code.h L25），非笔误，排查时按此名检索。

## 3. 服务问题

| 场景                                             | 触发码                                       | 排查方向                                                                                                                                                  |
| ------------------------------------------------ | -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SA 3508 未启动 / proxy 获取失败                  | errcode SANDBOX_MANAGER_SERVICE_NOT_EXIST=3  | `hidumper -s 3508` 查 samgr 注册；触发按需加载（BOOT_COMPLETED/PACKAGE_* 事件）。SA_LIFE_TIME=3 分钟后延迟卸载，冷启动第一==次==调用易触发          |
| IPC Parcel 序列化失败                            | errcode SANDBOX_MANAGER_SERVICE_PARCEL_ERR=4 | 数据量超限（vector 过大）；检查 policy_info_parcel / set_info_parcel / *_vec_raw_data marshalling                                                         |
| 远端 IPC 异常（CallProxyWithRetry 重试后仍失败） | errcode SANDBOX_MANAGER_SERVICE_REMOTE_ERR=5 | 服务进程崩溃或 Binder 死亡；查`sandbox_manager_service` 进程存活                                                                                        |
| 非 system app 调用受限接口                       | errcode SANDBOX_MANAGER_NOT_SYS_APP=14       | GetPersistPolicy / GetSharedDirectoryInfo / GrantSharedDirectoryPermission / RevokeSharedDirectoryPermission 强制`TokenIdKit::IsSystemAppByFullTokenID` |

## 4. 数据库问题（RDB 持久化）

| 场景                                | 触发码                                        | 排查方向                                                     |
| ----------------------------------- | --------------------------------------------- | ------------------------------------------------------------ |
| RDB 操作失败（Insert/Query/Delete） | errcode SANDBOX_MANAGER_DB_ERR=6              | 查数据库文件权限/磁盘空间/表结构（sandbox_manager_rdb.cpp）  |
| 查询命中但无记录                    | errcode SANDBOX_MANAGER_DB_RETURN_EMPTY=7     | 区分于 RECORD_NOT_EXIST：表存在但条件无匹配                  |
| 指定记录不存在（UnPersist/Clean）   | errcode SANDBOX_MANAGER_DB_RECORD_NOT_EXIST=8 | 单条返回 rettype POLICY_HAS_NOT_BEEN_PERSISTED=4；整体返回 8 |

## 5. MAC 内核层问题（临时规则）

临时规则（SetPolicy/UnSetPolicy/SetDenyPolicy/StartAccessingPolicy）下推内核 ioctl，失败码集中在此。

| 场景               | 触发码                                   | 排查方向                                                          |
| ------------------ | ---------------------------------------- | ----------------------------------------------------------------- |
| MAC 适配层未初始化 | errcode SANDBOX_MANAGER_MAC_NOT_INIT=9   | /dev/sandbox 或内核沙箱节点未就绪；查 mac_adapter.cpp 初始化      |
| 内核 ioctl 失败    | errcode SANDBOX_MANAGER_MAC_IOCTL_ERR=10 | MacAdapter::SetSandboxPolicy 返回非 0；查内核沙箱驱动、参数合法性 |
| 单条策略 MAC 失败  | rettype POLICY_MAC_FAIL=5                | 批量 SetPolicy 的 result 向量中该条失败；结合 9/10 排查           |
| deny 规则冲突      | errcode SANDBOX_MANAGER_DENY_ERR=11      | 已存在 DENY_READ/DENY_WRITE 规则导致设置/访问被拒                 |

## 6. 调用方 UID 限定（非权限，而是进程身份）

部分接口限定调用方必须是特定系统进程，否则 `PERMISSION_DENIED=1`：

| UID 常量              | 值   | 含义                       | 受限接口                                                                                                                                                                                           |
| --------------------- | ---- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| FOUNDATION_UID        | 5523 | foundation 进程            | UnPersistPolicy(byToken) L373、CleanPolicyByUserId、SetPolicyByBundleName L691、StartAccessingByTokenId、SetShareFileInfo、UpdateShareFileInfo、UnsetShareFileInfo、StartAccessingPolicy 分支 L617 |
| SPACE_MGR_SERVICE_UID | 7013 | file_manager/space_manager | SetPolicy（带结果向量重载）L505/L553                                                                                                                                                               |

排查方向：

- 通过 `IPCSkeleton::GetCallingUid()` 日志确认实际调用方 UID。
- 跨进程调用若 UID 链被中间代理改变（如经 foundation 转发），需确认最终到达 service 的 UID。
- 非 system app 场景见 errcode 14（第 3 节）。

## 7. 其它

| 场景           | 触发码                                      | 排查方向                                                            |
| -------------- | ------------------------------------------- | ------------------------------------------------------------------- |
| 媒体库调用失败 | errcode SANDBOX_MANAGER_MEDIA_CALL_ERR=12   | media_path_support / MediaPermissionHelper 调用失败；查媒体服务状态 |
| 进程终止失败   | errcode SANDBOX_MANAGER_KILL_PROCESS_ERR=13 | 策略变更需 kill 受影响进程（AbilityManagerClient），但终止失败      |
