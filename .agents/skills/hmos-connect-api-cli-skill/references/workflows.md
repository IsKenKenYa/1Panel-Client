# 业务流程

每步都给了**提取命令 + 校验点**。校验不过就停，不要带着空值往下走。
下文假设已过 SKILL.md 的前置门禁（`$CONNECT_API_CLI` 已定位、版本 ≥1.1.1、`auth status` 正常）。
下文示例里的 `connect-api-cli` 均等同于 `$CONNECT_API_CLI`（见 [SKILL.md §2](../SKILL.md)）。**PowerShell 块一律写 `node $CONNECT_API_JS`**，不要裸跑 `connect-api-cli`。

---

## A. 验证凭证 / 首次接入

```bash
APP_ID=$(connect-api-cli publish app-id -p <包名> 2>/dev/null | jq -r '.appids[0].value // empty')
[ -n "$APP_ID" ] && echo "appId=$APP_ID" || echo "空结果：可用 app-create 创建，或核对包名"
```

**校验点**：`APP_ID` 非空且为纯数字串。空值 → 用 `publish app-create` 创建应用/元服务，或包名写错了，**到此为止**，别继续跑后面的流程。

```bash
# 先列出项目并把 projectId 回显给用户选择
$CONNECT_API_CLI project list 2>/dev/null | jq -r '.projectList[] | "\(.projectId)\t\(.name)"'
# 用户选定后：
APP_ID=$($CONNECT_API_CLI publish app-create \
  --project-id <用户选定的项目ID> --app-name "<名称>" -p <包名> --parent-type 13 --installation-free 0 \
  2>/dev/null | jq -r '.appId // empty')
# 或在 TTY 下省略 --project-id，由 CLI 交互选择
```

```bash
connect-api-cli publish app-info -a "$APP_ID" 2>/dev/null | jq '{ret, releaseState: .appInfo.releaseState}'
```

---

## B. 证书 + Profile

**前置**：`appId` 已拿到；已过 [SKILL.md §3.1](../SKILL.md)（`.env` 有可用的 `DEVECO_HOME`）。没有就问用户 DevEco 安装目录并写入 `.env`，**禁止搜盘**。本机还需要 `java`（可用 DevEco JBR，见 §3.1）。

**先只看本工程本地**：`.certs/` 是否已有**完整一套**（同目录 `.p12` + `.cer` + `.p7b`，用途对应下表 type）。`build-profile.json5` 的 `signingConfigs` 指向这套且密码是 `encrypt-pwd` hex → 直接进流程 C / D。  
本地没有、只有调试套、或缺 `.p12` → **重新生成**（下面 B-发布 / B-调试），不要停。AGC `cert-list` 里即使已有 `MyReleaseCert` 也不能当材料——云侧不下发私钥，对不上本地密钥。**禁止**搜云侧签名、**禁止**在整盘 / 其他工程 / Downloads 找旧 `.p12`。仅当本工程 `.certs/` 已有配套 `.p12` 时，才用 `cert-list` 复用未过期的同类型证书（只下 `.cer` / `.p7b`，不新建证）。

不传 `--filename` 时 CLI 用同一串 CSPRNG hex 作为子目录名，文件带类型前缀（`.certs/<随机数>/key_<随机数>.p12`、`cert_<随机数>.cer`、`profile_<随机数>.p7b`）。调试与发布各跑一次，不要混用。一律用返回的 `.filename` / `.storePath` / `.csrPath` / `.cerPath` / `.p7bPath` / `.pwd`，**不要手写路径，不要拷到工程根目录，不要回显 `.pwd`**。

| 用途 | `--cert-type` / Profile `--type` | `--device-ids` | 产物用途 |
|------|----------------------------------|----------------|----------|
| 真机调试 | `1` | **必须** | 签 HAP，流程 D |
| 上架 / 邀请测试 / 公开测试 | `2` | **不要带** | 签 APP，流程 C / G |

`--cert-type` 另有：`3` 企业内部 · `4` 二进制（仅证书）。`csr-generate` 无 `.ret`，以 `has("csrPath")` 为准。返回里的 `cerPath` / `p7bPath` 此时文件还不存在。`--pwd` 必填：先 **弹框让用户输入**密码，再传入（无回显，只在 JSON `.pwd`），**禁止回显明文**。下载地址有有效期，**拿到就立刻 `curl -o` 到 `.cerPath` / `.p7bPath`**。

### B-发布（上架用）

```bash
# 先弹框让用户输入密码，得到 $P12_PWD 后再跑（不要在会话里回显明文）
CSR_JSON=$(connect-api-cli provision csr-generate --alias mykey --pwd "$P12_PWD" 2>/dev/null)
CSR_PATH=$(jq -r '.csrPath' <<<"$CSR_JSON")
STORE=$(jq -r '.storePath' <<<"$CSR_JSON")
CER_PATH=$(jq -r '.cerPath' <<<"$CSR_JSON")
P7B_PATH=$(jq -r '.p7bPath' <<<"$CSR_JSON")
P12_PWD=$(jq -r '.pwd' <<<"$CSR_JSON")

# 本地没有配套 .p12 时不要复用云上旧证，直接用刚生成的 CSR 申请新证
connect-api-cli provision cert-list -t 2 2>/dev/null | jq '.certList[]? | {id, certName, expireTime}'

CERT_JSON=$(connect-api-cli provision cert-create --csr "$CSR_PATH" \
  --cert-name "MyReleaseCert" --cert-type 2 2>/dev/null)
CERT_ID=$(jq -r '.certInfo.id' <<<"$CERT_JSON")
curl -sS -o "$CER_PATH" "$(jq -r '.certInfo.certDownloadUrl' <<<"$CERT_JSON")"

PROV_JSON=$(connect-api-cli provision profile-create --name "MyReleaseProfile" --type 2 \
  --cert "$CERT_ID" -a "$APP_ID" 2>/dev/null)
curl -sS -o "$P7B_PATH" "$(jq -r '.provisionInfo.provisionDownloadUrl' <<<"$PROV_JSON")"
```

**校验点**：`$CER_PATH` 与 `$P7B_PATH` 都存在且非空。记下 `STORE` / 各路径供流程 C 填 `build-profile.json5`。

已授予 ACL 写入 Profile：`--acls ohos.permission.XXX,ohos.permission.YYY`（逗号分隔名，不是 JSON 文件）。

### B-调试（真机用）

```bash
# B1 先弹框让用户输入密码得到 $P12_PWD；不传 --filename；用返回路径，不要手写
CSR_JSON=$(connect-api-cli provision csr-generate --alias mykey --pwd "$P12_PWD" 2>/dev/null)
CSR_PATH=$(jq -r '.csrPath' <<<"$CSR_JSON")
P12_PATH=$(jq -r '.p12Path' <<<"$CSR_JSON")
STORE=$(jq -r '.storePath' <<<"$CSR_JSON")
CER_PATH=$(jq -r '.cerPath' <<<"$CSR_JSON")
P7B_PATH=$(jq -r '.p7bPath' <<<"$CSR_JSON")
P12_PWD=$(jq -r '.pwd' <<<"$CSR_JSON")

# B2 申请调试证书
connect-api-cli provision cert-list -t 1 2>/dev/null | jq '.certList[]? | {id, certName, expireTime}'

CERT_JSON=$(connect-api-cli provision cert-create --csr "$CSR_PATH" \
  --cert-name "MyDebugCert" --cert-type 1 2>/dev/null)
CERT_ID=$(jq -r '.certInfo.id' <<<"$CERT_JSON")
curl -sS -o "$CER_PATH" "$(jq -r '.certInfo.certDownloadUrl' <<<"$CERT_JSON")"
```

```bash
# B3 真机调试才需要：注册设备
UDID=$("$HDC" shell bm get --udid | tr -d '\r\n')
DEVICE_ID=$(connect-api-cli provision device-list 2>/dev/null \
  | jq -r --arg u "$UDID" '.deviceList[]? | select(.udid==$u) | .id')

if [ -z "$DEVICE_ID" ]; then
  printf '[{"deviceName":"MyPhone","udid":"%s","deviceType":4}]\n' "$UDID" > devices.json
  connect-api-cli provision device-add --devices devices.json 2>/dev/null | jq '{ret, successedCount, failedCount, failedAddDeviceDetail}'
  DEVICE_ID=$(connect-api-cli provision device-list 2>/dev/null \
    | jq -r --arg u "$UDID" '.deviceList[]? | select(.udid==$u) | .id')
fi
```

**校验点**：`device-add` 即使 `.ret.code == 0`，也要看 `failedCount`——重复添加会计入失败。`deviceId` 要回查 `device-list` 拿。`deviceType`：`1` 运动手表 · `2` 智能手表 · `4` 手机 · `5` 平板 · `8` 智慧屏 · `19` PC/2in1。

```bash
# B4 创建调试 Profile（必须带 --device-ids）
PROV_JSON=$(connect-api-cli provision profile-create --name "MyDebugProfile" --type 1 \
  --cert "$CERT_ID" -a "$APP_ID" --device-ids "$DEVICE_ID" 2>/dev/null)
curl -sS -o "$P7B_PATH" "$(jq -r '.provisionInfo.provisionDownloadUrl' <<<"$PROV_JSON")"
```

**校验点**：`$CER_PATH` 与 `$P7B_PATH` 都存在且非空。记下 `STORE` / 各路径供流程 D。

---

## C. 发布签名、构建 APP、上传上架

HarmonyOS 上架/测试分发必须上传 **`.app`**。[获取文件上传地址](https://developer.huawei.com/consumer/cn/doc/app/agc-help-upload-api-upload-url-0000002236201294) 支持的软件包格式是 APP，**不是 HAP**。须已走 **B-发布**。

| 产物 | 怎么来 | 用途 |
|------|--------|------|
| `.hap` | `assembleHap` + **调试**证书 | 仅流程 D：`hdc install` |
| `.app` | `assembleApp` + **发布**证书 | 上架、邀请测试、公开测试 |

**禁止** `upload file -f *.hap`。

### C1 发布签名配置

`build-profile.json5` 密码必须是 `encrypt-pwd` 输出的 hex，**不能填明文**。用发布 `.cer` / `.p7b` / `.p12`。`signingConfigs.name` 须与 `products[].signingConfig` 一致。流程 D 可能把 product 临时改成了调试套——**构建 APP 前先确认 `products[].signingConfig` 指向发布套**（`.p7b` `"type":"release"`），不要用残留的 `default`。

```powershell
# Windows（禁止省略 --config-dir，禁止用 ~ 或相对路径；用 csr-generate 的 .pwd，不要 echo）
$P12_PWD = ($CSR_JSON | ConvertFrom-Json).pwd
node $CONNECT_API_JS provision encrypt-pwd --pwd $P12_PWD --config-dir "$env:USERPROFILE\.ohos\config"
```

```bash
# macOS / Linux（不要 echo "$P12_PWD"）
P12_PWD=$(jq -r '.pwd' <<<"$CSR_JSON")
connect-api-cli provision encrypt-pwd --pwd "$P12_PWD" --config-dir "$HOME/.ohos/config" 2>/dev/null | jq -r '.keyPassword, .storePassword'
```

```json5
{
  "name": "release",
  "type": "HarmonyOS",
  "material": {
    "certpath": "./.certs/<随机数>/cert_<随机数>.cer",
    "keyAlias": "mykey",
    "keyPassword": "<encrypt-pwd 输出>",
    "profile": "./.certs/<随机数>/profile_<随机数>.p7b",
    "signAlg": "SHA256withECDSA",
    "storeFile": "./.certs/<随机数>/key_<随机数>.p12",
    "storePassword": "<encrypt-pwd 输出>"
  }
}
```

路径用流程 B 返回的 `.cerPath` / `.p7bPath` / `.p12Path` 转成工程相对路径（`./.certs/<随机数>/cert_<随机数>.cer` 等）。`csr-generate` 会把 `material/` 放到 `.storePath` 旁（看 `.materialPath`）。**不要**拷到工程根目录。`bundleName` 必须与 AGC 包名、发布 Profile 一致。

### C2 构建签名 APP

**`-p buildMode` 必须驼峰**。写成 `-p buildmode=release` 会被 hvigor **静默忽略**。`assembleHap` 未指定模式时默认 **debug**（`assembleApp` 默认才是 release）。本步只用 `DEVECO_HOME` 下的 `hvigorw` 绝对路径（§3.1），不要换别的封装、不要 `where hvigorw`。

```bash
cd <项目根目录>
# HVIGORW / OHPM 来自 SKILL.md §3.1（DEVECO_HOME 下的绝对路径），禁止 which/where 去搜
"$OHPM" install
"$HVIGORW" assembleApp --mode project -p product=default -p buildMode=release --no-daemon
```

产物典型路径 `build/outputs/default/*-default-signed.app`。确认扩展名是 **`.app`**。找不到则按 `products[].name` 搜 `build/outputs/**/*.app`。**禁止**把 `entry/**/entry-default-signed.hap` 当成 APP 包（`default` 是 product 名，不是 release）。

**校验点（未过不准声称 release / 构建成功）**：

1. 磁盘上有 `*.signed.app`，不是只有 `.hap`。
2. hvigor 日志含 `Picking option from product 'default' with build mode 'release'`。若仍是 `'debug'`，就是 `buildMode` 没生效（先查大小写）。
3. 解包产物里的 `module.json`：`app.buildMode` 为 `"release"` 且 `app.debug` 为 `false`。**不要**用 `app.apiReleaseType == "Release"` 当依据（那是 SDK API 渠道）。
4. 所用 `.p7b` 明文 `"type":"release"`（调试 Profile 是 `"type":"debug"` 且带 `debug-info.device-ids`）。

### C3 上传并提交

`-r 1` 影响线上，未确认不要用。`-a` 必须是数字 appId。

```bash
connect-api-cli publish app-info -a "$APP_ID" -l zh-CN 2>/dev/null | jq '{ret, releaseState: .appInfo.releaseState}'

UP_JSON=$(connect-api-cli upload file -a "$APP_ID" -f ./build/outputs/default/<name>-default-signed.app -r 1 2>/dev/null)
jq -e '.ret.code == 0 and .bound == true and (.packageId | strings | length > 0)' <<<"$UP_JSON" >/dev/null \
  || { echo "FAILED: upload/report"; }
```

**校验点**：stdout 是 JSON（不是 `Upload successful.`）。`.bound == true` 且有 `.packageId` 才表示已上报到 AGC；只有 OBS 成功、未上报时控制台软件包管理是空的。stderr 含 `Upload failed:` / `Package report failed:` 即失败。大文件别中途打断；失败重跑整条，不需清理分片。

上报成功后可用 `.packageId` 查解析状态，再 `submit`：

```bash
PKG_ID=$(jq -r '.packageId' <<<"$UP_JSON")
connect-api-cli publish compile-status -a "$APP_ID" --pkg-ids "$PKG_ID" 2>/dev/null | jq '.ret'

connect-api-cli publish submit -a "$APP_ID" -r 1 2>/dev/null | jq '.ret'
```

`-r`：`1` 全量 · `6` HarmonyOS 测试（测试分发整体走流程 G，上传仍须 `.app`）。可选 `-c 0|1`。`submit` / `shelf-off` / `cancel-review` 先问用户。

---

## D. 端到端：签名 → 构建 → 装真机

用户说「运行到手机 / 运行应用到手机 / 装到真机」走本节。在 **B-调试** 的产物之上做本地安装。上架不要走本节，走流程 **C**（发布证书 + `assembleApp` + `.app`）。

**没有 `.env` 的 `DEVECO_HOME`**：弹框让用户输入 DevEco 安装目录并写入 `.env`（[SKILL.md §3.1](../SKILL.md)）。**禁止**搜盘、禁止裸跑 `hdc`/`hvigorw`、禁止 Harmony MCP（`harmony_build` / `harmony_launch_app` / `harmony_list_devices`）。

**D1 DevEco 工具路径**（先过 [SKILL.md §3.1](../SKILL.md)）

从 `.env` 的 `DEVECO_HOME` 推出 `HVIGORW` / `OHPM` / `HDC` 绝对路径，并把 `DEVECO_SDK_HOME` 导出到当前会话（[SKILL.md §3.1](../SKILL.md)）。没有 `DEVECO_HOME` → 问用户并写入 `.env`，**禁止**用下面这种示例当本机默认去探测：

```text
# 仅说明目录形态，不是本机路径
macOS .app → Contents/tools/hvigor/bin/hvigorw 、 Contents/sdk
Windows    → tools\hvigor\bin\hvigorw.bat 、 sdk
```

**D2** 跑流程 A 拿 `appId`，跑 **B-调试** 拿 `.cer` / `.p7b` / `.p12`。

**D3 核对 bundleName**——最常见的失败原因，构建前先查

`AppScope/app.json5` 的 `bundleName` 必须与 AGC 注册包名、`.p7b` 内包名**完全一致**，否则安装必失败。

**D4 加密密码**

`build-profile.json5` 里的密码必须是 AES-128-GCM 加密后的 hex，**填明文构建会失败**：

```powershell
# Windows（禁止省略 --config-dir，否则落到 CWD；用 csr-generate 的 .pwd，不要 echo）
$P12_PWD = ($CSR_JSON | ConvertFrom-Json).pwd
node $CONNECT_API_JS provision encrypt-pwd --pwd $P12_PWD --config-dir "$env:USERPROFILE\.ohos\config"
```

```bash
# macOS / Linux（不要 echo "$P12_PWD"）
P12_PWD=$(jq -r '.pwd' <<<"$CSR_JSON")
connect-api-cli provision encrypt-pwd --pwd "$P12_PWD" --config-dir "$HOME/.ohos/config" 2>/dev/null | jq -r '.keyPassword'
```

填入 `signingConfigs.material`：

```json5
{
  "name": "default",
  "type": "HarmonyOS",
  "material": {
    "certpath": "./.certs/<随机数>/cert_<随机数>.cer",
    "keyAlias": "mykey",
    "keyPassword": "<encrypt-pwd 输出>",
    "profile": "./.certs/<随机数>/profile_<随机数>.p7b",
    "signAlg": "SHA256withECDSA",
    "storeFile": "./.certs/<随机数>/key_<随机数>.p12",
    "storePassword": "<encrypt-pwd 输出>"
  }
}
```

加密材料须在 `.p12` **同级目录**。`csr-generate` 已自动放到 `$STORE/material`（JSON `.materialPath`）。若缺失再补：

```bash
ln -s ~/.ohos/config/material "$STORE/material"
```

**不要**把 `.p12` / `.cer` / `.p7b` 拷到工程根目录来“凑”索引。

`encrypt-pwd` **必须**加 `--config-dir`。Windows 上默认 `~/.ohos/config` 会落到当前工作目录（CLI 读 `HOME` 而非 `USERPROFILE`），第一次必失败。用 `%USERPROFILE%\.ohos\config`；报「未找到加密密钥目录」时对照报错路径，不要用不带该参数的命令重试。

**D4.5 选调试签名（构建前，禁止先装再猜）**

`buildMode=debug` **只改编译模式，不改证书**。hdc 用的签名由 `products[].signingConfig` → `signingConfigs[].name` 决定。发布 Profile（`"type":"release"`）无设备绑定，装真机必报 `signature verification failed due to not trusted app source`。hvigor **没有** `-p signingConfig=...` 这种开关。

构建 / 安装前读 `build-profile.json5`：

1. 在 `signingConfigs` 里找**调试套**：对应 `.p7b` 明文 `"type":"debug"`，且 `debug-info.device-ids` 含当前 UDID。名称常见 `default`。
2. 看本次 `product`（默认 `default`）的 `signingConfig` 是否就是这一套。
3. **已是调试套** → 不要改 `build-profile.json5`。
4. **指向 `release` / `"type":"release"`**：
   - 已有调试套 → 记下原值，**临时**把 `products[].signingConfig` 改成调试套的 `name`。D6 结束后（成功或失败）**立刻改回**。禁止改完不改回，否则后续流程 C 会打出调试签名包。
   - 没有调试套 → 走 B-调试 + D4，把调试套**追加**进 `signingConfigs`（不要覆盖发布套），再临时切换。
5. **禁止**对现有 HAP 先 `hdc install`，再根据 `not trusted app source` 回头改配置。

**D5 构建 HAP**（仅本地调试）

上架 / 测试分发不要走本步，走 **C2**（`assembleApp` + 发布证书）。用户说「构建 app 包」若意图是上架，也走 C2，不要默认本步。`HVIGORW` / `OHPM` 必须来自 §3.1，不要搜 PATH。

**`-p buildMode` 必须驼峰**。`-p buildmode=debug` / `buildmode=release` 都会被忽略，打 HAP 时静默回落到 **debug**。

```bash
cd <项目根目录>
# 当前会话必须已有 DEVECO_SDK_HOME（§3.1 推出的 SDK 目录），否则 hvigor 报 00303217
"$OHPM" install
"$HVIGORW" assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

产物典型路径 `entry/build/default/outputs/default/entry-default-signed.hap`（模块名以工程为准）。

**校验点（未过不准 `hdc install`）**：解包 hap 内 `module.json`，本地调试预期 `app.buildMode=="debug"` 且 `app.debug==true`；`.p7b` 为 `"type":"debug"`、bundle-name 与工程一致、`debug-info.device-ids` 含本机 UDID。已有 hap 三项都满足且源码未改，可跳过重建。若 `"type":"release"` → 回到 D4.5，不要装。若用户要的是 release 却得到 debug 这两项，说明跑错了任务或 `buildMode` 没生效，不要把 hap 文件名里的 `default` 解释成 release。

**D6 安装启动**

```bash
"$HDC" install ./entry/build/default/outputs/default/entry-default-signed.hap
"$HDC" shell aa start -a EntryAbility -b <包名>
```

D4.5 若临时改过 `products[].signingConfig`，本步结束后**立刻改回**（成功失败都改回）。

安装失败按 bundleName → 设备是否在 Profile 里 → 证书/Profile 类型是否都是调试 的顺序排查。`not trusted app source` 不要重试 install，回到 D4.5。

---

## E. 域名配置

```bash
# E1 先看配额，update 消耗且不恢复
connect-api-cli domain config -a "$APP_ID" 2>/dev/null | jq '.configs[0] | {modifyCounts, serverDomainCounts, businessDomainCounts}'

# E2 看现状
connect-api-cli domain query -a "$APP_ID" -c server 2>/dev/null | jq '.'

# E3 业务域名先预检
echo '{"type":"webView","value":"https://www.example.com"}' > domain.json
connect-api-cli domain pre-check -a "$APP_ID" --domain domain.json 2>/dev/null | jq '.'

# E4 预检过了再更新
echo '[{"type":"httpRequest","value":"https://api.example.com"}]' > domains.json
connect-api-cli domain update -a "$APP_ID" -c server --domains domains.json 2>/dev/null | jq '.'

# E5 需要归属校验时下载校验文件，交给用户放到域名根目录
connect-api-cli domain verify-file -a "$APP_ID" -o ./huawei-verify.txt
```

**校验点**：`update` 返回即使 `.ret.code == 0`，**单条域名仍可能失败**，逐条查 `errorCode` / `errorMsg`。配额为 0 时不要试着 update。

---

## F. ACL 受限权限

```bash
echo '[{"name":"ohos.permission.XXX","reason":"说明使用场景与必要性"}]' > acls.json
connect-api-cli provision acl-apply -a "$APP_ID" --acls acls.json 2>/dev/null | jq '.ret'

connect-api-cli provision acl-status -a "$APP_ID" 2>/dev/null | jq '.aclPermissionList[]? | {name, status}'
```

`status`：`0` 申请中 · `1` 通过。审批以天计——**提交后就结束本次任务并告知用户**，不要轮询等待。
申请前可先 `connect-api-cli provision acl-eligible -a "$APP_ID"` 查可申请列表。
已授予的权限用 `connect-api-cli provision acl-query -a <appId>` 查，可在 `profile-create` 时通过 `--acls`（逗号分隔权限名）带入。

---

## G. 邀请/公开测试分发

**前置**：`appId` 已拿到；构建产物已准备好上传。

```bash
# G1 创建测试版本（3=邀请测试，4=公开测试）
VER_JSON=$(connect-api-cli test version-create -a "$APP_ID" --test-type 3 --test-desc "内测" -r 6 2>/dev/null)
VERSION_ID=$(jq -r '.versionId // empty' <<<"$VER_JSON")
[ -n "$VERSION_ID" ] && echo "versionId=$VERSION_ID" || echo "创建失败"
```

```bash
# G2 上传包（测试用 -r 6；必须是发布证书签出的 .app，不要传 .hap）
# -r 6 只传到 OBS，不会报到正式版本；用返回的 objectId 再 pkg-add
UP_JSON=$(connect-api-cli upload file -a "$APP_ID" -f ./build/outputs/default/<name>-default-signed.app -r 6 2>/dev/null)
OBJECT_ID=$(jq -r '.objectId // empty' <<<"$UP_JSON")
FILE_NAME=$(jq -r '.fileName // empty' <<<"$UP_JSON")
[ -n "$OBJECT_ID" ] && echo "objectId=$OBJECT_ID" || echo "上传失败：无 objectId"
```

**校验点**：`.ret.code == 0` 且 `.objectId` 非空。`-r 6` 时 `.bound` 为 `false` 是预期。stderr 含 `Upload failed:` 即失败。

```bash
# G3 绑定包到测试版本（file-name / objectId 必须来自上一步，禁止编造）
connect-api-cli test pkg-add -a "$APP_ID" --file-name "$FILE_NAME" --object-id "$OBJECT_ID" 2>/dev/null | jq '.ret'

# G4 按需更新版本信息（语言、分组等，--body 须含 versionId）
# echo "{\"versionId\":\"$VERSION_ID\"}" > test-version.json
# connect-api-cli test version-update -a "$APP_ID" --body test-version.json 2>/dev/null | jq '.ret'

# G5 提交审核
connect-api-cli test version-submit -a "$APP_ID" -v "$VERSION_ID" 2>/dev/null | jq '.ret'
```

邀请测试还需：`test group-add` → `group-user-add` / `invite-code-create`；公开测试用 `test version-opentest` 配置时间窗与配额。详见 [commands.md](commands.md) 的 `test` 分组。

**校验点**：`VERSION_ID` 非空；每步 `.ret.code == 0`。审核状态以控制台为准，不要轮询。
