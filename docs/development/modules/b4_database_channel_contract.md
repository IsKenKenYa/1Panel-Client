# B4 数据库深度 · 宿主通道契约 v1（冻结）

> Dart handler 与 C# WindowsBridge 的单一事实源。MDUI3 底层 `lib/api/v2/database_v2.dart` 现成复用。
> 返回惯例同 B1-B3（读透传、写 `{success, error?}`）。

## 读通道

| method | 参数 | 底层（database_v2.dart） | 服务端 |
| --- | --- | --- | --- |
| getDatabaseBaseInfo | `{type, name}` | loadDatabaseBaseInfo | POST /databases/common/info |
| getDatabaseConfFile | `{type, name}`（conf 类型传 `type+'-conf'`） | loadDatabaseConfigFile | POST /databases/common/load/file |
| getMysqlVariables | `{type, name}` | loadMysqlVariables | POST /databases/variables |
| getMysqlStatus | `{type, name}` | loadMysqlStatus | POST /databases/status |
| getRedisConf | `{type, name}` | loadRedisConf | POST /databases/redis/conf |
| getRedisStatus | `{type, name}` | loadRedisStatus | POST /databases/redis/status |
| getRedisPersistence | `{type, name}` | loadRedisPersistenceConf | POST /databases/redis/persistence/conf |
| getDatabaseRemoteAccess | `{type, name}` | loadRemoteAccess | POST /databases/remote |
| getDatabaseUsers | `{database: string}` | searchDatabaseUsers | POST /databases/users/search |
| getDatabaseGrants | `{database: string}` | searchDatabaseGrants | POST /databases/grants/search |
| getDatabaseBackups | `{type, name, detailName}` | searchDatabaseBackups（或 BackupAccountV2Api.searchBackupRecords） | POST /backups/record/search |

## 写通道

| method | 参数（扁平） | 底层 | 服务端 |
| --- | --- | --- | --- |
| updateDatabaseConfFile | `{type: string, database: string, file: string}` | updateDatabaseConfigFile | POST /databases/common/update/conf |
| updateMysqlVariables | `{type: string, database: string, variables: [{param, value}]}` | updateMysqlVariables | POST /databases/variables/update |
| updateRedisConf | `{dbType: string, database: string, timeout: string, maxclients: string, maxmemory: string}` | updateRedisConf | POST /databases/redis/conf/update |
| updateRedisPersistence | `{database: string, type: 'aof'\|'rbd', appendonly?: string, appendfsync?: string, save?: string, dbType: string}` | updateRedisPersistenceConf | POST /databases/redis/persistence/update |
| changeRedisPassword | `{database: string, password: string}`（password 底层 base64 编码） | changeRedisPassword | POST /databases/redis/password |
| updateDatabaseAccess | `{id: int, from: string, type: string, database: string, value: '%'|'localhost'}` | updateMysqlAccess | POST /databases/change/access |
| updateDatabaseUserPassword | `{database: string, username: string, host: string, password: string}`（password 底层 base64） | updateDatabaseUserPassword | POST /databases/users/password |
| createDatabaseUser | `{database: string, username: string, host: string, password: string, description?: string}`（password base64） | createDatabaseUser | POST /databases/users |
| deleteDatabaseUser | `{database: string, username: string, host: string}` | deleteDatabaseUser | POST /databases/users/del |
| updateDatabaseUser | `{database: string, username: string, host: string, newHost: string, description: string}` | updateDatabaseUser | POST /databases/users/update |
| grantDatabaseUser | `{database: string, db: string, username: string, host: string}` | createDatabaseGrant | POST /databases/grants |
| revokeDatabaseGrant | `{database: string, db: string, username: string, host: string}` | deleteDatabaseGrant | POST /databases/grants/del |

## 实现约定

1. 同 B1-B3：Dart handler 透传/`{success, error?}` + 必填缺失快速失败 + dispatch 注册；C# 读 `GetXxxAsync→JsonElement?`、写 `XxxAsync→bool`，数组参数用 `List<object>`。
2. base64 密码：Dart 底层方法已内置编码的（如 updateDatabaseUserPassword）直接传明文；无内置的按上游前端 `encodeBase64` 补。
3. 智能体渠道/PG 超级用户/.mongodb privileges 等深度项归后续批次。

## 实现偏差回写（as-implemented，v1.1 冻结）

双轨实现核验后与 v1 草案的差异，以下为最终事实：

1. **base64 密码**：`database_v2.dart` 底层均收裸 Map 不编码（编码在仓库层），由 **Dart handler 统一补 base64**（`updateDatabaseUserPassword`、`createDatabaseUser` 的 `password`）；C# 桥层纯透传明文。
2. **changeRedisPassword 键名**：上游前端与真实端点要求 `{database, value: base64(password)}`，handler 将契约 `password` 映射为 `value` 并 base64。
3. **getDatabaseBackups**：`searchDatabaseBackups` 需库记录 id（契约参数不含），改走 `BackupAccountV2Api.searchBackupRecords`（即契约服务端端点 POST /backups/record/search），按 `{type, name, detailName}` 筛选拼装分页结构。
4. **getDatabaseConfFile**：底层返回裸 `String`，通道包为 `{content}`；`type+'-conf'` 后缀由调用方传入。
5. **getDatabaseRemoteAccess**：底层返回裸 `bool`，通道包为 `{remoteAccess: bool}`。

实现落点：Dart `lib/core/channel/native_channel_database_deep_handlers.dart` + `native_channel_manager.dart` 注册；C# `WindowsBridgeDatabase.cs`（partial）+ `DatabaseDeepBridgeContractTests.cs`。
