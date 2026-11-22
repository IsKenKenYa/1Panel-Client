# connect-api-cli 命令参考

形如 `$CONNECT_API_CLI <分组> <子命令> [参数]`。`$CONNECT_API_CLI` 定义见 [SKILL.md §2](../SKILL.md)（本 skill 内嵌 `scripts/connect-api-cli.js`，**不要** `npm install -g` / `npx`）。下文示例里的 `connect-api-cli` 均等同于 `$CONNECT_API_CLI`；**PowerShell 块一律写 `node $CONNECT_API_JS`**。
细节以 `$CONNECT_API_CLI <分组> <子命令> --help` 为准。

**通用约定**

- JSON 结果 → stdout；进度与错误 → stderr；**v1.1.4 起业务失败返回非零退出码**。
- 参数错误、请求异常和 API 业务错误均返回非零退出码；旧版（≤1.1.3）需额外检查响应错误码。
- 下列参数传的是**文件路径**，内容为合法 JSON（UTF-8 **无 BOM**）：`--devices` / `--domains` / `--domain` / `--body` / `acl-apply` 的 `--acls`。Windows 写文件时勿用会带 BOM 的编码。
- 下列参数是**英文逗号分隔**字符串：`--cert-ids` / `--device-ids` / `--fps` / `--pkg-ids` / `--tag-ids` / `--tester-ids` / `profile-create` 的 `--acls`（权限名，非文件）。
- 短选项：`-a` App ID · `-p` 包名 · `-f` 文件路径 · `-c` 类别（domain）或中国大陆标记（upload）· `-v` versionId · `-g` groupId。
- 表中「产出」列即下游命令要用的值，用 jq 从 stdout 提取。
- 多数 `publish` / `test` 写操作通过 `--body <JSON文件>` 传入请求体，字段以 `--help` 与 AGC 文档为准。
- **时间字段**：`cert-list` / `profile-list` 等返回的 `expireTime`、`updateTime`，以及反馈查询 body 的 `startTime`/`endTime`，均为 **Unix 毫秒**（约 13 位）。转成自然语言日期时**必须用北京时间**（IANA：`Asia/Shanghai`），禁止 `toISOString()`（那是 UTC，钟点差 8 小时，跨日还会差一天），**禁止当秒或手工加减天数**。详见 [SKILL.md §1.1](../SKILL.md)。

---

## auth

| 子命令 | 说明 | stdout 形态 |
|--------|------|-------------|
| `login` | 按当前模式取 token 并缓存 | 纯文本 |
| `status` | 输出认证模式、Client ID / Key ID、缓存状态、剩余有效期、Auto-refresh | 纯文本 |
| `logout` | 清除本地 token 缓存 | 纯文本 |

这三条**不返回 JSON**，用 grep 判断，例如 `$CONNECT_API_CLI auth status | grep -q "Token cached: yes"`。

`auth status` 在当前目录读不到凭证时 stderr 输出 `Auth status unavailable: ...` 且**退出码为 1**（其余命令凭证问题多在运行时抛错）。

Token 缓存于 `~/.connect-api-cli-token.json`，过期前 5 分钟自动续期，请求遇 401 也会自动刷新重试一次——因此多数命令可直接执行，不必每次先 login。

认证模式由用户在 `.env` 里配置，你不需要改：
- 默认 `client_credentials`（`AGC_CLIENT_ID` + `AGC_CLIENT_SECRET`，无人值守可用）
- `service_account`（推荐）：`AGC_SA_CREDENTIALS` 指向控制台下载的 `*_private.json`，本地签 PS256 JWT，无人值守可用
- `oauth`：`login` 需人工浏览器授权，非交互环境下不可用，其余端点参数均有内置默认值

---

## publish

### 查询

| 子命令 | 必填 | 可选 | 产出 |
|--------|------|------|------|
| `app-id` | `-p` 包名 | `--package-types` | `.appids[0].value` = appId |
| `app-create` | `--app-name`、`--parent-type`、`--installation-free`；应用时还要 `-p` | `--project-id`（省略则交互选择）、`-p`（元服务可省略） | `.appId` |
| `app-info` | `-a` appId | `-l` 语言如 `zh-CN`、`-r` 发布类型、`-v` versionId | `.appInfo` |
| `members` | `--from-page`、`--page-size`、`--lang` | — | 团队成员与角色 |
| `version-list` | `-a` | `-p` 包名、`--state` 状态过滤（逗号分隔） | 各版本简要信息 |
| `package-info` | `-a`、`--package-id` | — | 包详情 |
| `compile-status` | `-a`、`--pkg-ids` | — | 包编译/解析状态 |
| `version-voc` | `-a` | `--body` 可选过滤 JSON | 未解决版本 VOC 工单 |
| `qual-dependent` | — | — | 所需资质文件定义 |
| `qual-query` | `-a`、`--tag-ids` | — | 资质审核任务详情 |
| `agreement-list` | `-a` | `--body`、`--type`（`1` 隐私 / `2` 用户协议） | 协议列表 |

`-p`（app-id）支持逗号分隔，最多 50 个包名。`-r`：`1` 全量 · `6` HarmonyOS 测试；`-r 6` 时 `app-info` 通常需 `-v` versionId。

`app-create`：`--project-id` 可省略——TTY 下会拉取项目列表并提示选择编号或粘贴 ID；非交互环境必须显式传 `--project-id`（先用 `project list`）。`--parent-type` 为 `2` 游戏 / `13` 应用；`--installation-free` 为 `0` 应用（须 `-p` 包名）/ `1` 元服务（不传 `packageName`）。成功时 `.ret.code == 0` 且 `.appId` 非空。Connect API 需**开发者级** Service Account（`project_id` 为空）或团队级 API 客户端（Project=N/A）。

```bash
# 先列出项目，把 projectId 给用户选
$CONNECT_API_CLI project list 2>/dev/null | jq -r '.projectList[] | "\(.projectId)\t\(.name)"'

APP_ID=$($CONNECT_API_CLI publish app-id -p com.example.app 2>/dev/null | jq -r '.appids[0].value')
# 若为空，创建应用（须 -p）：
# APP_ID=$($CONNECT_API_CLI publish app-create --project-id <项目ID> --app-name "Demo" -p com.example.app --parent-type 13 --installation-free 0 2>/dev/null | jq -r '.appId')
# 创建元服务（不传 -p）：
# APP_ID=$($CONNECT_API_CLI publish app-create --project-id <项目ID> --app-name "Meta" --parent-type 13 --installation-free 1 2>/dev/null | jq -r '.appId')
```

`appids` 为空数组 → 应用尚未创建，或包名写错；可用 `app-create` 创建后再查。

`members` 的 `--lang`：`zh_cn` / `en_us` / `ru_ru`。

---

## project

| 子命令 | 必填 | 可选 | 产出 |
|--------|------|------|------|
| `list` | — | — | `.projectList[].projectId`；stderr 另回显可选列表 |

`list`：`GET /api/project-service/v1/projects`。stdout 为完整 JSON；stderr 回显 `projectId` 与名称，供用户选择后传给 `publish app-create --project-id`。

```bash
$CONNECT_API_CLI project list 2>/dev/null | jq -r '.projectList[] | "\(.projectId)\t\(.name)"'
```

### 信息更新

| 子命令 | 必填 | 可选 |
|--------|------|------|
| `app-info-update` | `-a`、`--body` | `-r`、`--release-phase` |
| `language-update` | `-a`、`--body`（须含 `lang`） | `-r`、`--release-phase` |
| `language-delete` | `-a`、`-l` | `-r` |
| `file-info-update` | `-a`、`--body` | `-r`、`--release-phase` |
| `phased-release` | `-a`、`--body` | — |
| `age-rating` | `-a`、`--body` | `-r`、`--release-phase` |

### 包绑定与上架

| 子命令 | 必填 | 可选 | 备注 |
|--------|------|------|------|
| `package-update` | `-a`、`--file-name`、`--object-id` | `-r`、`--release-phase` | 把 OBS 上的包上报到 AGC；`objectId` 来自 `upload file`。上传 `.app` 且非 `-r 6` 时 `upload file` 会自动调用本接口 |
| `release-time` | `-a`、`--change-type` | `--release-time`、`-r` | `--change-type`：`2` 立即上架 · `3` 改定时 |
| `submit` | `-a` | `--body`、`-r`、`--release-phase`、`--remark`、`--release-time` | **提交发布审核** |
| `cancel-review` | `-a`、`-v` versionId | — | 取消审核中版本 |
| `shelf-off` | `-a`、`--reason` | `-r` | 下架 |

### 资质与协议

| 子命令 | 必填 | 可选 |
|--------|------|------|
| `qual-submit` | `-a`、`--body`（含 `tagQualInfos`） | — |
| `qual-update` | `-a`、`--body` | — |
| `qual-cancel` | `-a`、`--task-id` | — |
| `qual-delete` | `-a`、`--tag-ids` | — |
| `agreement-create` | `-a`、`--body` | — |
| `agreement-update` | `-a`、`--body` | — |
| `privacy-submit` | `-a`、`--id` agreementId | `--require-confirm`（`0`/`1`） |

---

## upload

| 子命令 | 必填 | 可选 |
|--------|------|------|
| `file` | `-a` appId、`-f` 文件路径 | `-r` 发布类型、`-c` 中国大陆标记、`--no-bind` |

- `-r`：`1` 全量发布（影响线上）· `6` HarmonyOS 测试。
- `-c`：`0` / `1`。
- HarmonyOS 软件包必须是 **`.app`**（[获取文件上传地址](https://developer.huawei.com/consumer/cn/doc/app/agc-help-upload-api-upload-url-0000002236201294)）。**不要上传 `.hap`**；HAP 只用于本地 `hdc install`。
- < 5MB 单文件上传，≥ 5MB 自动分片并合并。
- OBS 上传本身**不会**在 AGC 控制台产生软件包记录。上传 `.app` 且未使用 `-r 6` / `--no-bind` 时，会接着调用 [更新应用软件包信息](https://developer.huawei.com/consumer/cn/doc/doccenter-submission/agc-help-publish-api-app-package-info-update-0000002236201250) 上报。
- **成功时 stdout 为 JSON**（`.ret.code`、`.fileName`、`.objectId`；上报成功还有 `.packageId`、`.bound`）。失败时 stderr 出现 `Upload failed:` 或 `Package report failed:`。中断后重跑整条命令即可，不需清理分片。
- `-r 6` 只传到 OBS（`.bound == false`），用返回的 `.objectId` 再跑 `test pkg-add`。

---

## provision

### 证书与本地密钥

| 子命令 | 必填 | 可选 | 产出 / 备注 |
|--------|------|------|-------------|
| `csr-generate` | `--alias`、`--pwd`（弹框收集用户输入后传入） | `--out-dir`（默认 `./.certs`）、`--filename`（默认 CSPRNG hex，用作子目录名；文件另加 `key_` / `cert_` / `profile_` 前缀）、`--sdk-path`、`--java-path` | `.filename` `.storePath` `.csrPath` `.p12Path` `.pwd`；**无 `.ret`** |
| `encrypt-pwd` | `--pwd` | `--config-dir`（**Windows 必填**；macOS/Linux 建议也填 `"$HOME/.ohos/config"`） | `.keyPassword` `.storePassword`；**无 `.ret`** |
| `cert-create` | `--csr`、`--cert-name`、`--cert-type` | — | `.certInfo.id`、`.certInfo.certDownloadUrl` |
| `cert-list` | — | `-t` 类型、`--cert-ids` | `.certList[]`（`.id` `.certName` `.certType` `.expireTime` **毫秒**） |
| `cert-delete` | `--cert-ids` | — | **不可撤销**；每次执行前弹框确认具体名称 + id（「随便删一个」不算） |

`--cert-type` / `--type`：`1` 调试 · `2` 发布 · `3` 企业内部 · `4` 二进制。

`encrypt-pwd` 说明：
- **禁止**只跑 `connect-api-cli provision encrypt-pwd --pwd ...`。帮助里的默认 `~/.ohos/config` 在 Windows 上不可靠：CLI 用 `process.env.HOME` 拼路径，`HOME` 常未设置，会去 **当前工作目录** `.ohos\config` 找 `material/`，stdout 为空、stderr 报 `未找到加密密钥目录`。
- 每次调用都显式传绝对路径 `--config-dir`。Windows 用用户主目录，**不是** `~`、**不是** CWD：
  ```powershell
  $cfg = Join-Path $env:USERPROFILE ".ohos\config"
  Test-Path (Join-Path $cfg "material")   # 须为 True
  $P12_PWD = ($CSR_JSON | ConvertFrom-Json).pwd   # 来自 csr-generate JSON，不要 echo
  node $CONNECT_API_JS provision encrypt-pwd --pwd $P12_PWD --config-dir $cfg
  ```
  ```bash
  # macOS / Linux（不要 echo "$P12_PWD"）
  P12_PWD=$(jq -r '.pwd' <<<"$CSR_JSON")
  connect-api-cli provision encrypt-pwd --pwd "$P12_PWD" --config-dir "$HOME/.ohos/config"
  ```
- 先确认 `<config-dir>/material` 存在再调用。不存在 → **用户操作**：需已安装 DevEco Studio 并至少生成过一次签名配置。
- 成功：stdout JSON 含 `keyPassword` 与 `storePassword`（hex）。失败信息只在 stderr。

`csr-generate` 说明：
- 每套材料在 **`.certs/<随机数>/`** 下：`key_<随机数>.p12`、`key_<随机数>.csr`、`cert_<随机数>.cer`、`profile_<随机数>.p7b`。`<随机数>` 默认是 CSPRNG 32 hex；`--filename` 只改这串 id（目录名与各文件共用），类型前缀固定。`--out-dir` 只改根目录。
- 不传 `--sdk-path` 时读 `.env` 的 `DEVECO_HOME`（仅用其下 `sdk/` 或 `Contents/sdk/`）。没有 → **用户操作**：按 [SKILL.md §3.1](../SKILL.md) 问安装目录并写入 `DEVECO_HOME`，**禁止搜盘、禁止套用文档示例路径**。
- 需要本机有 `java`，否则用 `--java-path` 指定。
- `--pwd` 必填：先 **弹框让用户输入**证书签名密码，再把用户输入传入。P12 与 key 用同一密码。只出现在 JSON `.pwd`，**不写文件**。**禁止自动生成、禁止 CLI 自己弹对话框、禁止把 `.pwd` 明文回显给用户**；后续 `encrypt-pwd` 用 `jq -r '.pwd'` 传入。
- 若本机已有 DevEco `material/`，会自动放到 `.storePath/material`（JSON `.materialPath`），hvigor 才能在 `.p12` 同级解密密码。**不要**把 `.p12` / `.cer` / `.p7b` 拷到工程根目录。
- 重跑会新建子目录，失败重试前先看 `.certs/` 是否已有产物。
- 返回里的 `cerPath` / `p7bPath` 是**约定的目标路径，文件此时还不存在**，要靠后续 `curl` 下载到这两个路径。

### 设备

| 子命令 | 必填 | 可选 | 产出 |
|--------|------|------|------|
| `device-add` | `--devices <JSON文件>` | — | `.successedCount` / `.failedCount` / `.failedAddDeviceDetail` |
| `device-list` | — | `--device-name`、`--from`、`--max`、`--order` | `.deviceList[]`（`.id` `.deviceName` `.udid`）、`.totalCount` |
| `device-delete` | `--device-ids` | — | **不可撤销**；每次执行前弹框确认具体名称 + id |

`--order`：`1` 创建时间降序 · `2` 名称升序。

`devices.json`：

```json
[{ "deviceName": "MyPhone", "udid": "<UDID>", "deviceType": 4 }]
```

`deviceType`：`1` 运动手表 · `2` 智能手表 · `4` 手机 · `5` 平板 · `8` 智慧屏 · `19` PC/2in1。

UDID 取自 `"$HDC" shell bm get --udid`（`HDC` 来自 [SKILL.md §3.1](../SKILL.md)）。`device-add` 即使 `.ret.code == 0` 也要检查 `.failedCount`，重复添加会计入失败。

### Profile

| 子命令 | 必填 | 可选 | 产出 |
|--------|------|------|------|
| `profile-create` | `--name`、`--type`、`--cert` certId、`-a` appId | `--device-ids`、`--acls` | `.provisionInfo.id`、`.provisionInfo.provisionDownloadUrl` |
| `profile-list` | `-a` | `--profile-id`、`--from`、`--max` | `.provisionList[]`（`.expireTime` / `.updateTime` 为 **毫秒**，见 SKILL §1.1） |
| `profile-update` | `--id`、`--device-ids` | — | `.provisionInfo`；device 列表为**整体覆盖**，不是追加 |
| `profile-delete` | `--id` | — | **不可撤销**；每次执行前弹框确认具体名称 + id |

`--type`：`1` 调试 · `2` 发布 · `3` 企业内部 · `6` 指定设备。调试类型必须带 `--device-ids`。

`profile-create` 的 `--acls` 是**逗号分隔的已授予权限名**（如 `ohos.permission.XXX,ohos.permission.YYY`），不是 JSON 文件。

### 证书指纹

| 子命令 | 必填 | 产出 |
|--------|------|------|
| `fp-add` | `-a`、`--fps` | `.ret` |
| `fp-list` | `-a` | `.ret` + 指纹列表 |
| `fp-delete` | `-a`、`--fps` | `.ret` |

### ACL 受限权限

| 子命令 | 必填 | 可选 | 产出 |
|--------|------|------|------|
| `acl-eligible` | `-a` | `-l` 语言（`zh`/`en`/`ru`）、`--start`、`--page-size` | 可申请权限列表 |
| `acl-apply` | `-a`、`--acls <JSON文件>` | `--attachment` | `.ret` |
| `acl-status` | `-a` | — | `.aclPermissionList[]`（`.name` `.status`）；**无 `.ret`** |
| `acl-query` | `-a` | — | `.userPermission` |

`acl-status` 的 `status`：`0` 申请中 · `1` 审核通过。审批以天计，**不要轮询**。

`acls.json`（用于 `acl-apply`）：

```json
[{ "name": "ohos.permission.XXX", "reason": "说明使用场景与必要性" }]
```

已授予的权限可在 `profile-create` 时用 `--acls`（逗号分隔权限名）带入 Profile。

---

## domain

| 子命令 | 必填 | 产出 / 备注 |
|--------|------|-------------|
| `config` | `-a` | `.configs[0].modifyCounts` = 剩余修改配额 |
| `query` | `-a`、`-c <server\|business>` | 当前域名配置 |
| `pre-check` | `-a`、`--domain <JSON文件>` | 业务域名预检结果 |
| `update` | `-a`、`-c`、`--domains <JSON文件>` | **消耗配额且不恢复**，执行前先 `config` |
| `verify-file` | `-a`、`-o` 输出路径 | 落盘文件；成功打印 `Download successful.`，**不是 JSON** |

`domains.json`（数组）：

```json
[{ "type": "httpRequest", "value": "https://api.example.com" }]
```

`domain.json`（单对象）：

```json
{ "type": "webView", "value": "https://www.example.com" }
```

返回的 `DomainInfo` 带 `errorCode` / `errorMsg`：即使 `.ret.code == 0`，**单条域名仍可能失败**，要逐条检查。

---

## test

邀请测试 / 公开测试版本、分组、邀请码、公开链接与测试反馈。多数写操作通过 `--body <JSON文件>` 传参。

### 测试版本

| 子命令 | 必填 | 可选 | 产出 / 备注 |
|--------|------|------|-------------|
| `version-create` | `-a`、`--test-type`、`--test-desc` | `-r`（默认 `6`）、`--onshelf-self-detect` | `.versionId` |
| `version-detect` | `-a`、`-v` | — | 上架自检报告 |
| `pkg-add` | `-a`、`--file-name`、`--object-id` | `--distribute-mode` | 绑定已上传包 |
| `version-update` | `-a`、`--body`（须含 `versionId`） | — | 绑定 pkg/分组/语言等 |
| `version-release` | `-a`、`--body`（须含 `versionId`） | — | 生效/发布设置 |
| `version-opentest` | `-a`、`--body`（须含 `versionId`） | — | 公开测试时间窗/配额/分组 |
| `version-submit` | `-a`、`-v` | — | 提交测试版审核 |
| `version-stop` | `-a`、`-v` | — | 停止测试版 |
| `version-delete` | `-a`、`-v` | — | 删除测试版 |

`--test-type`：`3` 邀请测试 · `4` 公开测试。`--test-desc` 最多 50 字。`--onshelf-self-detect`：`0` / `1`。`--distribute-mode`：`1` 测试专区 · `2` AppGallery。

典型链路：`version-create` → `upload file -r 6` → `pkg-add` → `version-update`（补语言/分组等）→ `version-submit`。

### 测试分组

| 子命令 | 必填 | 可选 |
|--------|------|------|
| `group-add` | `-a`、`--name` | `--type`（`0` 外部默认 · `1` 内部） |
| `group-list` | `-a` | `--type`、`--current`、`--page-size` |
| `group-edit` | `-a`、`-g`、`--name` | — |
| `group-delete` | `-a`、`-g` | — |
| `group-user-list` | `-a`、`-g` | `--current`、`--page-size` |
| `group-user-add` | `-a`、`--body`（含 `groupId` 等） | — |
| `group-user-delete` | `-a`、`-g`、`--tester-ids` | — |
| `group-notify` | `-a`、`-g`、`--tester-ids` | 向成员发邀请测试通知。成功看 `.ret.code == 0`（publish 风格，不是 `rtnCode`） |

### 邀请码

| 子命令 | 必填 | 备注 |
|--------|------|------|
| `invite-code-create` | `-a`、`-g`、`--valid-days`、`--invite-limit` | 有效天数 ≤ 30，上限 ≤ 10000 |
| `invite-code-list` | `-a`、`-g` | — |
| `invite-code-stop` | `-a`、`--code-id` | — |
| `invite-code-delete` | `-a`、`--code-id` | — |

### 公开链接

| 子命令 | 必填 | 可选 |
|--------|------|------|
| `public-link-create` | `-a`、`-g`、`--limit` | — |
| `public-link-edit` | `-a`、`-g` | `--limit`、`--status` |
| `public-link-query` | `-a`、`-g` | — |

### 测试反馈

`--body` 传的是**JSON 文件路径**（不是内联字符串）。`appId` 走 `-a`，**不要**写进 body。

这三条返回的是 **`rtnCode` 风格**（不是 `.ret.code`）：`rtnCode == 0` 才算成功。列表为空且 `rtnCode == 0` 表示该时段无反馈，属于成功。

| 子命令 | 必填 | 产出 / 备注 |
|--------|------|-------------|
| `feedback-dimension` | `-a`、`--body` | `.dimensionData`；按维度聚合 |
| `feedback-query` | `-a`、`--body` | `.feedbackInfos[]`、`.pageInfo` |
| `feedback-delete` | `-a`、`--body` | 不可撤销；body 须含 `delFeedBackInfos` |

#### `feedback-dimension` / `feedback-query` 共用过滤字段

| 字段 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `startTime` | 建议 | number | 起始时间，**Unix 毫秒**（约 13 位） |
| `endTime` | 建议 | number | 结束时间，**Unix 毫秒**；须 ≥ `startTime` |
| `appVersions` | 否 | string[] | 应用版本过滤 |
| `models` | 否 | string[] | 设备型号过滤 |
| `deviceVersions` | 否 | string[] | 系统版本过滤 |
| `machineTypes` | 否 | string[] | 设备类型过滤 |

`feedback-query` **额外**分页字段：

| 字段 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `currentPage` | 建议 | number | 当前页，从 **1** 起 |
| `pageSize` | 建议 | number | 每页条数 |

`feedback-dimension` body 示例（近 30 天维度统计）：

```json
{
  "startTime": 1754006400000,
  "endTime": 1756684800000
}
```

`feedback-query` body 示例（近 30 天第 1 页）：

```json
{
  "startTime": 1754006400000,
  "endTime": 1756684800000,
  "currentPage": 1,
  "pageSize": 10
}
```

带可选过滤时把数组字段一并写入同一文件，例如 `"appVersions": ["1.0.0"]`。

```bash
# 生成近 30 天 body（Unix / Git Bash；毫秒）
node -e 'const e=Date.now(),s=e-30*864e5; require("fs").writeFileSync("feedback-query.json", JSON.stringify({startTime:s,endTime:e,currentPage:1,pageSize:10}))'
connect-api-cli test feedback-query -a "$APP_ID" --body ./feedback-query.json 2>/dev/null | jq '{rtnCode, total: .pageInfo.totalRecord, n: (.feedbackInfos|length)}'

node -e 'const e=Date.now(),s=e-30*864e5; require("fs").writeFileSync("feedback-dim.json", JSON.stringify({startTime:s,endTime:e}))'
connect-api-cli test feedback-dimension -a "$APP_ID" --body ./feedback-dim.json 2>/dev/null | jq '{rtnCode, rtnDesc, n: (.dimensionData|length)}'
```

Windows PowerShell 写 body 时**禁止** `Set-Content -Encoding utf8`（会带 BOM，`JSON.parse` 失败）。用无 BOM UTF-8，或上面的 `node -e`：

```powershell
$end = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$start = [DateTimeOffset]::UtcNow.AddDays(-30).ToUnixTimeMilliseconds()
$body = "{`"startTime`":$start,`"endTime`":$end,`"currentPage`":1,`"pageSize`":10}"
[System.IO.File]::WriteAllText("$pwd\feedback-query.json", $body, (New-Object System.Text.UTF8Encoding $false))
node $CONNECT_API_JS test feedback-query -a $APP_ID --body .\feedback-query.json
```

成功时 `feedback-query` 典型形态：

```json
{
  "rtnCode": 0,
  "rtnDesc": "success",
  "feedbackInfos": [],
  "pageInfo": { "current": 1, "pageSize": 10, "totalRecord": 0, "totalPage": 0 }
}
```

`feedback-dimension` 成功看 `rtnCode == 0` 与 `.dimensionData`；若 `rtnCode: -1` 且描述含「应用不存在」，而同 appId 的 `feedback-query` / `publish app-info` 正常，多半是该应用未开通维度能力或接口侧限制，**不是** body 字段名写错——不要靠改时间单位（秒/毫秒）反复试。

#### `feedback-delete` body

| 字段 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `delFeedBackInfos` | 是 | array | `[{ "problemId": "<id>", "testerId": "<id>" }]`，值来自 `feedback-query` 的 `.feedbackInfos[]` |
| `deleteMode` | 建议 | number | 删除模式（以 AGC 文档为准；常见传 `1`） |

```json
{
  "deleteMode": 1,
  "delFeedBackInfos": [{ "problemId": "<problemId>", "testerId": "<testerId>" }]
}
```

执行前先问用户；`problemId` / `testerId` **禁止编造**。

---

## 作为 Node 库使用

```typescript
import { AuthService, PublishService, UploadService, ProvisionService } from 'connect-api-cli';
```

`SignService`、`DomainService`、`TestingService` 未从包入口导出，只能走 CLI（本 skill 场景一律用内嵌 `$CONNECT_API_CLI` / `node $CONNECT_API_JS`）。
