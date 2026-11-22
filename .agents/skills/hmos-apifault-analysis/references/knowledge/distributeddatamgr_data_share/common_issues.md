# data_share 常见问题排查指南

> 排查时优先参考文档: `docs/.../reference/apis-arkdata/errorcode-datashare.md`

---

## 1. 权限问题

### 1.1 非系统应用调用系统API (错误码 202)

- **现象**: `Permission verification failed. A non-system application calls a system API.`
- **关联错误码**: 202
- **可能原因**: data_share 在 API 20 之前为 systemapi, 非 system 应用调用受限。
- **排查步骤**:
  1. 确认调用方应用是否为系统应用。
  2. 如果不是系统应用, 确认目标 API 是否在对应版本已转为 publicapi (API 20+ 部分接口已转公开)。

### 1.2 无权限访问URI指定数据 (错误码 15700015)

- **现象**: `No permission to access the data specified by the URI.`
- **关联错误码**: 15700015
- **可能原因**: 未申请数据提供方要求的 readPermission / writePermission。
- **排查步骤** (来自 errorcode-datashare.md):
  1. 咨询数据提供方获取所需权限。
  2. 找到数据提供者包名 (URI 的 path 中, 如 `datashareproxy://com.acts.ohos.data.datasharetest/test`)。
  3. 通过 `bm dump --bundle-name <包名>` 查看配置, 找到 DataShareExtension 配置, 确认 readPermission / writePermission。
  4. 在调用方 module.json5 中声明对应权限。

---

## 2. 参数问题

### 2.1 参数类型/数量错误 (错误码 401)

- **现象**: `Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameters types.`
- **关联错误码**: 401
- **排查步骤**:
  1. 对照 `.d.ts` 接口签名, 检查必选参数是否全部传入。
  2. 检查参数类型是否匹配 (如 `uri` 必须为 string, `predicates` 必须为 DataSharePredicates 实例)。
  3. 注意 callback 版本和 Promise 版本的参数差异。

### 2.2 URI/数组长度/格式超限 (错误码 15700014)

- **现象**: `The parameter format is incorrect or the value range is invalid.`
- **关联错误码**: 15700014
- **可能原因** (来自 errorcode-datashare.md):
  1. URI 长度超过 256 字节。
  2. ProxyData 的 value 长度超过 4096 字节 (API 26+ 可通过 DataProxyConfig.maxValueLength 扩展到 102400)。
  3. URI 数组长度超过 32。
  4. ProxyData 数组长度超过 32。
  5. URI 格式校验失败。
- **排查步骤**:
  1. 检查 URI 是否满足固定格式: `datashareproxy://{bundleName}/{path}`。
  2. 检查各字段长度限制。
  3. 检查数组元素数量。

---

## 3. URI 问题

### 3.1 URI 不存在 (错误码 15700011)

- **现象**: `The URI does not exist.`
- **关联错误码**: 15700011 (内部码 E_URI_NOT_EXIST = 1048)
- **可能场景**: addTemplate / delTemplate / enableSilentProxy / disableSilentProxy / DataProxyHandle.putValue / removeValue / getValues。
- **排查步骤** (来自 errorcode-datashare.md):
  1. 咨询 DataShare 服务端提供者, 获取正确的 URI 路径。
  2. 检查 URI 格式: `datashare:///{bundleName}/{moduleName}/{storeName}/{tableName}` (enable/disableSilentProxy) 或 `datashareproxy://{bundleName}/{path}` (DataProxyHandle)。

### 3.2 创建 DataShareHelper 时 URI 不正确 (错误码 15700010)

- **现象**: `The DataShareHelper fails to be initialized.`
- **关联错误码**: 15700010
- **可能原因** (来自 errorcode-datashare.md):
  1. createDataShareHelper 入参 uri 不正确。
  2. createDataShareHelper 入参 context 不正确 (非 Stage 模型)。
  3. 客户端从后台拉起 DataShareExtension 未配置后台拉起权限。
- **排查步骤**:
  1. 咨询服务端获取正确 URI。
  2. 确认 context 为 Stage 模型的 UIAbilityContext / ExtensionContext。
  3. 检查 module.json5 中是否配置了后台拉起权限。
  4. 如果 URI 以 `datashareproxy` 开头, 确认 options.isProxy = true。

---

## 4. 连接状态 / 实例生命周期问题

### 4.1 DataShareHelper 实例已关闭 (错误码 15700013)

- **现象**: `The DataShareHelper instance is already closed.`
- **关联错误码**: 15700013 (内部码 E_HELPER_DIED = 1064)
- **可能原因**: 调用 `close()` 后继续使用该实例, 或服务端进程异常退出。
- **排查步骤** (来自 errorcode-datashare.md):
  1. 重新创建 DataShareHelper 实例。
  2. 检查代码流程, 确认未在 close 之后调用 insert/delete/query/update 等方法。

### 4.2 数据区/bundleName 不存在 (错误码 15700012)

- **现象**: `The data area does not exist.`
- **关联错误码**: 15700012 (内部码 E_BUNDLE_NAME_NOT_EXIST = 1049)
- **可能场景**: publish / getPublishedData。
- **排查步骤** (来自 errorcode-datashare.md):
  1. 咨询 DataShare 服务端提供者, 获取正确的 bundleName。

### 4.3 内部错误 (错误码 15700000)

- **现象**: `Inner error.`
- **关联错误码**: 15700000
- **可能原因** (来自 errorcode-datashare.md):
  1. 内部状态异常。
  2. 错误地使用接口。
  3. 权限配置错误。
  4. 系统错误: 空指针 / 内存不足 / 数据服务异常重启 / I/O 错误 / IPC 异常 / JS 引擎异常。
- **排查步骤**:
  1. 查看完整错误日志 (hilog, tag: dataShare)。
  2. 排查是否存在对象关闭后再使用。
  3. 排查是否按接口文档正确使用。
  4. 排查权限配置。
  5. 尝试重试; 如仍无法解决, 提示用户重启应用/升级设备。

---

## 5. 数据大小限制

- **非静默场景**: insert/update/delete 的 uri+参数总大小 <= 900 KB; batchInsert values <= 128 MB; query predicates <= 128 MB。
- **静默场景**: uri+参数总大小 <= 200 KB。
- **模板订阅**: uri+subscriberId+template 总大小 <= 200 KB。
- **已发布数据**: data+bundleName 总大小 <= 200 KB。
- **DataProxyHandle**: URI <= 256 字节, value <= 4096 字节 (可配置 102400), 数组 <= 32 个。
- 超出限制时操作失败或抛出异常, 不一定返回特定错误码, 可能表现为 15700000 或直接异常。
