# accesscontrol_sandbox_manager 模块概览

> 组件名 `@ohos/sandbox_manager`，subsystem=accesscontrol，SystemAbility ID=**3508**，进程名 `sandbox_manager_service`。
> 纯 C++ 系统服务，**无 JS/NAPI API**；应用层经 filemanagement/ability 间接调用。

## 模块职责

应用沙箱间文件共享规则的持久化存储、管理与激活。持久化规则落 RDB 数据库，临时规则经 MAC 适配层下推内核 ioctl 生效。提供策略字典树（policy_trie）加速路径匹配，支持跨用户、按 tokenId/bundleName 的细粒度权限控制，以及共享目录（SharedDirectory）授权/撤销。

## 目录结构（简化）

```
accesscontrol_sandbox_manager/
├── interfaces/inner_api/sandbox_manager/include/   # 公开 inner API 头文件
│   ├── sandbox_manager_kit.h          # SandboxManagerKit（公开入口，全静态方法）
│   ├── policy_info.h                  # PolicyInfo/PolicyType/SandboxRetType/OperateMode/SetInfo/SharedDirectoryInfo
│   └── sandbox_manager_err_code.h     # SandboxManagerErrCode 枚举（15 项）
├── frameworks/
│   ├── inner_api/sandbox_manager/     # SDK 实现（IPC 客户端）
│   │   ├── include/sandbox_manager_client.h     # SandboxManagerClient 单例（持 ISandboxManager proxy）
│   │   └── src/                                  # kit.cpp / client.cpp（GetProxy/LoadSystemAbility/CallProxyWithRetry）
│   └── sandbox_manager/               # Parcel 序列化（policy_info_parcel, set_info_parcel, *_vec_raw_data）
├── services/
│   ├── common/                        # database(generic_values, variant_value), utils(sandbox_memory_manager)
│   └── sandbox_manager/main/cpp/
│       ├── include/service/           # service.h / policy_info_manager.h / policy_trie.h / sandbox_manager_const.h
│       ├── include/database/          # sandbox_manager_rdb.h（RDB 持久化）
│       ├── include/mac/mac_adapter.h  # MAC 内核适配（ioctl）
│       ├── include/media/             # media_path_support.h（媒体库路径）
│       ├── include/share/share_files.h# 文件共享业务
│       └── src/service/               # sandbox_manager_service.cpp（权限校验 + IPC stub）
├── modules/claw_sandbox/              # 独立原生二进制（sandbox_exec/mount/loader/aids）
└── bundle.json / BUILD.gn / sandbox_manager.gni / hisysevent.yaml
```

## 分层调用链

```
调用方(C++)
  → SandboxManagerKit::Xxx(...)            [interfaces/inner_api/.../sandbox_manager_kit.h]
  → SandboxManagerClient::Xxx(...)         [frameworks/inner_api/.../src/sandbox_manager_client.cpp]  CallProxyWithRetry 重试
  → ISandboxManager proxy                  [IPC proxy；跨进程 Binder，SA 3508]
  → SandboxManagerService::Xxx(...)        [services/.../src/service/sandbox_manager_service.cpp]  权限校验
  → PolicyInfoManager::Xxx(...)            [services/.../src/service/policy_info_manager.cpp]      业务逻辑
  → SandboxManagerRdb::Insert/...          [services/.../src/database/sandbox_manager_rdb.cpp]    持久化
  → MacAdapter::SetSandboxPolicy/...       [services/.../src/mac/mac_adapter.cpp]                 内核 ioctl（临时规则）
```

## 核心文件清单

| 路径（相对模块根） | 用途 |
|---|---|
| `interfaces/inner_api/sandbox_manager/include/sandbox_manager_kit.h` | 公开 inner API 入口，全部静态方法 |
| `interfaces/inner_api/sandbox_manager/include/policy_info.h` | 核心数据结构：PolicyInfo/OperateMode/SandboxRetType/SetInfo/SharedDirectoryInfo |
| `interfaces/inner_api/sandbox_manager/include/sandbox_manager_err_code.h` | 错误码枚举 SandboxManagerErrCode（15 项） |
| `frameworks/inner_api/sandbox_manager/include/sandbox_manager_client.h` | SDK 单例，持 ISandboxManager proxy，含重试逻辑 |
| `frameworks/inner_api/sandbox_manager/src/sandbox_manager_client.cpp` | GetProxy/CheckSystemAbility/LoadSystemAbility(SA 3508)/CallProxyWithRetry |
| `frameworks/inner_api/sandbox_manager/src/sandbox_manager_kit.cpp` | Kit 静态方法 → 入参校验 → 转发 Client |
| `frameworks/sandbox_manager/include/policy_info_parcel.h` 等 | Parcel 序列化（policy/set_info/vec_raw_data） |
| `services/sandbox_manager/main/cpp/include/service/sandbox_manager_service.h` | SandboxManagerService（SystemAbility+SandboxManagerStub），SA=3508 |
| `services/sandbox_manager/main/cpp/src/service/sandbox_manager_service.cpp` | 权限校验 + IPC stub 实现（各接口行号见 api_chain.json） |
| `services/sandbox_manager/main/cpp/include/service/policy_info_manager.h` | PolicyInfoManager 单例（核心业务逻辑） |
| `services/sandbox_manager/main/cpp/include/service/policy_trie.h` | 策略字典树，路径匹配加速 |
| `services/sandbox_manager/main/cpp/include/service/sandbox_manager_const.h` | 权限名常量 / 批量上限 / SA 生命周期常量 |
| `services/sandbox_manager/main/cpp/include/database/sandbox_manager_rdb.h` | RDB 持久化接口 |
| `services/sandbox_manager/main/cpp/include/mac/mac_adapter.h` | MAC 内核适配（ioctl 下推临时规则） |
| `services/sandbox_manager/main/cpp/include/share/share_files.h` | 文件共享业务（SharedDirectory） |
| `services/sandbox_manager/main/cpp/include/media/media_path_support.h` | 媒体库路径支持 |
| `modules/claw_sandbox/` | 独立原生二进制：sandbox_exec/mount/loader/aids |

## 关键约束

- 单条路径最大长度 `POLICY_PATH_LIMIT = 4095`
- `std::vector<PolicyInfo>` 批量上限 500 条
- `MAX_BATCH_COUNT = 32`；`NON_PERSIST_POLICY_BATCH_SIZE = 200`；`PERSIST_POLICY_BATCH_SIZE = 200000`
- `SA_LIFE_TIME = 3` 分钟（延迟卸载 DelayUnloadService）
- SA 按需启动：BOOT_COMPLETED / PACKAGE_REMOVED / PACKAGE_FULLY_REMOVED / PACKAGE_DATA_CLEARED / PACKAGE_ADDED / PACKAGE_CHANGED；low.memory.prepare 时停止
- UID 限定：FOUNDATION_UID=5523、SPACE_MGR_SERVICE_UID=7013 部分接口限调用方 UID
- 非 system app → SANDBOX_MANAGER_NOT_SYS_APP
