---
name: hmos-connect-api-cli-skill
description: 用本 skill 内嵌的 connect-api-cli 脚本（scripts/，无需 npm 安装）操作华为 AppGallery Connect / AGC：登录登出、创建应用/元服务、查询 App ID、上传 APP（非 HAP）/APK、发布审核、邀请/公开测试、证书与 Profile、ACL、域名，以及 CSR/P12、assembleApp/assembleHap、encrypt-pwd、真机 hdc 安装。Use when 用户提到 AGC、AppGallery Connect、华为应用市场、hmos-connect-api-cli-skill、connect-api-cli、登录、退出登录、创建应用、创建元服务、上架、上传 APP、构建 app/release/debug 包、assembleApp、assembleHap、运行到手机、真机运行、hdc、发布/调试证书、Profile、p7b、csr、encrypt-pwd、ACL、邀请测试或公开测试。
license: Apache-2.0
metadata:
  author: harmonyos-dev-skills
  version: "1.1.4"
  created: "2026-09-03"
  updated: "2026-09-15"
  keywords: ["agc", "appgallery-connect", "connect-api-cli", "hmos-connect-api-cli-skill", "publish", "certificate", "profile", "upload", "acl", "atomic-service"]
compatibility: Requires Node.js LTS (≥ CLI 1.1.4). Optional jq on bash. Signing/build/hdc needs DEVECO_HOME in project .env.
---

# hmos-connect-api-cli-skill：操作华为 AppGallery Connect

本 skill **自带 CLI**：[`scripts/connect-api-cli.js`](scripts/connect-api-cli.js)。用 Node 直接跑即可，**不要**引导用户 `npm install -g` / `npx`。
前置只要求本机有 **Node.js**（`node -v`，建议 LTS）。

## Workflow（总流程）

### Input
- 用户意图（登录/登出、创建应用或元服务、ACL、证书打包真机、上传软件包等）
- 工程包名、项目 ID、构建产物路径、可选 `.env`（AGC 凭证 + `DEVECO_HOME`）

### Process
1. 定位 CLI（§2）→ `--version`（≥ 1.1.4 推荐）
2. `auth status` 门禁；缺凭证停并交用户补 `.env`（§3）
3. 签名/构建/hdc 前过 `DEVECO_HOME` 门禁（§3.1），禁止搜盘与 Harmony MCP
4. 按意图选流程 A–G（§8），打开 [workflows.md](references/workflows.md)
5. 每步按输出契约判定（§1）；失败对照 [troubleshooting.md](references/troubleshooting.md)

### Output
- 成功：关键 ID / 落盘路径 / 下一步
- 失败：stderr 首行 + 是否「用户操作」；不泄露凭证与密码

## 1. 输出契约（决定你怎么判断成败，先读）

| 事实 | 你必须怎么做 |
|------|--------------|
| **v1.1.4 起失败返回非零退出码**，业务 JSON 仍写 stdout | 可用退出码判断失败，并检查返回字段是否满足任务目标 |
| 旧版（≤1.1.3）业务失败可能返回 0 | 旧版必须额外检查 `.ret.code` / `.rtnCode` |
| 业务结果（JSON）→ stdout；进度与错误 → stderr | bash：`$CONNECT_API_CLI ... 2>/dev/null \| jq`。**PowerShell 禁止** `2>/dev/null`、`2>/tmp/...`、管道 `jq`（本机通常没有 jq，重定向会报找不到路径）。用 `node $CONNECT_API_JS ...` 直接读 stdout，抽字段用 `node -e` |
| API 类命令返回 `.ret.code` | `.ret.code == 0` 才算成功 |
| **`test feedback-*` 返回 `.rtnCode`** | 反馈维度/列表/删除是 `rtnCode` 风格，**不是** `.ret.code`。用 `jq -e '.rtnCode == 0'`；空 `feedbackInfos` 且 `rtnCode == 0` = 该时段无数据，算成功 |
| 本地类命令（`csr-generate`、`encrypt-pwd`）无 `.ret` | 以目标字段存在为准，如 `jq -e 'has("csrPath")'` / `has("keyPassword")`。`csr-generate` 前须 **弹框让用户输入**密码并作为 `--pwd` 传入；成功时还有 `.filename` `.pwd` `.storePath`；**禁止**把 `.pwd` 回显。下载 `.cer` / `.p7b` 必须写到 `.cerPath` / `.p7bPath`。**禁止**把签名文件拷到工程根目录 |
| **`encrypt-pwd` 禁止裸跑** | Windows 上 CLI 读 `HOME`（常为空），默认 `~/.ohos/config` 会落到 **CWD** `.ohos\config`，第一次必报「未找到加密密钥目录」。必须显式 `--config-dir` 指向用户主目录下的 `.ohos\config`（PowerShell：`$env:USERPROFILE\.ohos\config`） |
| `.ret.code == 0` 但列表为空 ≠ 成功 | 空 `appids` / `certList` 说明资源不存在，要停下来查原因，不是继续 |
| `--body` JSON 文件 | 合法 UTF-8 JSON、**无 BOM**。Windows 勿用 `Set-Content -Encoding utf8` 写 body（会带 BOM 导致 parse 失败）；用 `node -e` 写文件或 `UTF8Encoding($false)`。字段示例见 [commands.md 测试反馈](references/commands.md) |

判定模板（每步执行后都这样收口）：

```bash
OUT=$($CONNECT_API_CLI <命令> 2>/tmp/agc.err); jq -e '.ret.code == 0' <<<"$OUT" >/dev/null \
  || { echo "FAILED: $(head -1 /tmp/agc.err)"; }
```

```powershell
# 不要复制上面的 bash。看 stdout 的 .ret.code 与 $LASTEXITCODE
node $CONNECT_API_JS provision cert-list
```

## 1.1 时间戳 → 自然语言（禁止臆算）

向用户展示「过期时间 / 更新时间」等日期时，**必须按毫秒 Unix 时间戳换算为北京时间**（IANA：`Asia/Shanghai`），不要心算、不要减几天、不要当秒处理。

| 字段来源 | 单位 | 典型位数 | 换算 |
|----------|------|----------|------|
| `provision` / `cert-list` / `profile-list` 的 `expireTime`、`updateTime` | **毫秒** | 13 位（约 `1.7e12`～`1.9e12`） | `new Date(ms)` 再格式化为北京时间 |
| `test feedback-*` 请求体 `startTime` / `endTime` | **毫秒** | 同上 | 同上 |
| 本地 token 缓存 / OAuth 的 `expireTime`（auth） | **秒** | 较小（如 `3600`） | `Date.now() + sec * 1000`；**与上面不是同一套** |

展示规则：

1. 用解释器换算，禁止手算日期。**必须指定 `timeZone: 'Asia/Shanghai'`**（北京时间；IANA 无 `Asia/Beijing`）。展示格式：日期时间 `2029-08-18 14:30:33`；只写日期时写 `2029-08-18`。
2. **禁止用 `toISOString()` / `.slice(0,10)` 给用户看**：那是 UTC（末尾 `Z`），钟点差 8 小时；UTC 16:00 之后北京时间日历日还会差一天。判断是否过期用 `expireTime > Date.now()`，不要拿 ISO 字符串比日期。
3. **禁止**：把毫秒当秒（会得到远未来日期）；对结果再「微调」几天；用 `expireTime/1000` 再当毫秒二次转换搞乱。
4. 对照样例（`profile-list` 真实值，北京时间）：`1881729033000` → **2029-08-18 14:30:33**；`1818559382000` → **2027-08-18 11:23:02**；`1818241320000` → **2027-08-14 19:02:00**。若你算出 2029-08-15 / 2027-08-16 / 2027-08-10 或 UTC 的 `…T06:30:33.000Z`，说明换算错了，重算。

```bash
# 正确：毫秒 → 北京时间（sv-SE 得到 YYYY-MM-DD HH:mm:ss）
node -e "const d=new Date(1881729033000); console.log(d.toLocaleString('sv-SE',{timeZone:'Asia/Shanghai'}))"
# → 2029-08-18 14:30:33

# 只要日期
node -e "console.log(new Date(1881729033000).toLocaleDateString('en-CA',{timeZone:'Asia/Shanghai'}))"
# → 2029-08-18
```

## 2. 定位并调用内嵌脚本

先确认 Node，再定位 CLI：

```bash
node -v || echo NEED_NODE
```

`NEED_NODE` → **用户操作**：安装 Node.js LTS 后再来。

约定（**不要用全局 `connect-api-cli` / `npx`**）：

```bash
# bash / zsh：整串可以当命令（shell 会拆成 node + 脚本路径）
CONNECT_API_CLI="node <SKILL_ROOT>/scripts/connect-api-cli.js"
# 当前目录已是 skill 根：CONNECT_API_CLI="node scripts/connect-api-cli.js"
$CONNECT_API_CLI --version
$CONNECT_API_CLI auth status
```

```powershell
# PowerShell：变量只能存 .js 路径，必须用 node 去跑。
# 禁止 $CONNECT_API_CLI = "node D:\...\connect-api-cli.js"; & $CONNECT_API_CLI ...
# `&` 会把整串当成命令名，报 The term 'node D:\...js' is not recognized。
$CONNECT_API_JS = "<SKILL_ROOT>\scripts\connect-api-cli.js"
node $CONNECT_API_JS --version
node $CONNECT_API_JS auth status
```

`<SKILL_ROOT>` = 本 skill 根目录（含 `SKILL.md` 与 `scripts/`）。

下文与 [references/](references/) 里凡写 `connect-api-cli` / `$CONNECT_API_CLI`：bash 用 `$CONNECT_API_CLI`，**PowerShell 一律写成 `node $CONNECT_API_JS`**。

版本应 ≥ `1.1.1`（推荐 ≥ `1.1.4`；低版本 stdout 会混 dotenv/签名工具日志，`jq` 解析失败）。

非 skill 场景（CI 独立装包）仍可使用 npm 包 `connect-api-cli`；**在本 skill 上下文中优先用内嵌脚本**。

## 3. 凭证与登录门禁

脚本可用后先跑这一条，它同时回答"凭证在不在、要不要登录、是不是需要人工"三件事：

```bash
$CONNECT_API_CLI auth status
```

| 输出 | 含义 | 动作 |
|------|------|------|
| `Auth status unavailable: Missing AGC credentials...`（旧版本是一段 Node 堆栈，含同样字样） | 当前目录读不到凭证 | 见下方「凭证缺失」 |
| `Token cached: yes` + 剩余时间 | 可直接干活 | 跳过 login，token 会自动续期 |
| `Token cached: no` | 需登录 | `$CONNECT_API_CLI auth login` |
| `Auth mode: oauth` | 登录要人工在浏览器点授权 | **非交互环境无法完成**，告知用户后等待，不要自己反复重试。相关端点已内置默认值，不需要你配置 |

**凭证缺失**：凭证从**当前工作目录**的 `.env` 读取（也认已导出的环境变量），换个目录执行就读不到——先确认是不是站错了目录。确实没有则是**用户操作**：任选一种模式写入该目录的 `.env`：

```env
# 模式 A：API 客户端（默认）
AGC_CLIENT_ID=<客户端ID>
AGC_CLIENT_SECRET=<客户端密钥>

# 模式 B：Service Account（推荐，控制台下载 *_private.json）
# AGC_AUTH_MODE=service_account
# AGC_SA_CREDENTIALS=./xxx_private.json
```

切换过 Client ID 或域名后缓存失效：`$CONNECT_API_CLI auth logout && $CONNECT_API_CLI auth login`。

## 3.1 DevEco 路径门禁（签名 / 构建 / hdc 前必做）

凡要用 HarmonyOS SDK、`hvigorw`、`ohpm`、`hdc`、`hap-sign-tool.jar` 或 DevEco JBR 的步骤（流程 B / C / D），**先读当前工作目录 `.env` 的 `DEVECO_HOME`**（也认已导出的同名环境变量）。**只这一项**；SDK / `hvigorw` / `ohpm` / `hdc` 都从它推，不要再写 `HARMONYOS_SDK_PATH`。

用户说「运行到手机 / 运行应用到手机 / 装到真机 / hdc 安装」= **流程 D**，同样必须先过本门禁。没有 `DEVECO_HOME` 就问人并写入 `.env`，**不要**为了找 `hdc`/`hvigorw` 去搜 DevEco。

| 状态 | 你必须怎么做 |
|------|--------------|
| `.env` 里已有 `DEVECO_HOME`，且按下表校验通过 | 用它；不要再问、不要改猜 |
| **没有、为空、或校验失败** | **弹框让用户输入**本机 **DevEco Studio 安装目录**，写入 `.env` 的 `DEVECO_HOME` 后继续 |
| 不知道路径 | **禁止搜索** |

**禁止**（违反就会在别人机器上扫盘、套错路径）：

- 全盘 / 用户主目录 / `Program Files` / `Applications` / `Downloads` / 其他工程里搜 `DevEco`、`hvigorw`、`hdc`、`hap-sign-tool.jar`
- `where` / `where.exe` / `Get-Command` / `mdfind` / `find` 去**发现**安装位置
- 把文档里的示例路径（如 `/Applications/DevEco-Studio.app`、`C:\Program Files\Huawei\DevEco Studio`）当成**本机默认**去探测；那只是形态说明
- PATH 里碰巧有 `hvigorw` / `hdc` 也不能代替 `DEVECO_HOME`（版本可能不是这套工程用的）；**禁止裸跑** `hdc` / `hvigorw`
- **禁止用 Harmony MCP**（`harmony_build` / `harmony_launch_app` / `harmony_list_devices` 等）来代替本门禁——那些工具会自己找 DevEco

用户给出目录 `P` 后，**只检查 `P` 本身及其下一层 `Contents/`**（macOS `.app`），不要再往别处找：

| 用途 | Windows（`P` 下直接有 `sdk` + `tools`） | macOS（`P` 为 `DevEco-Studio.app`） |
|------|------------------------------------------|-------------------------------------|
| 写入 `.env` 的 `DEVECO_HOME` | 用户给的 `P` | 用户给的 `P` |
| SDK（推出来，不写进 `.env`） | `P\sdk` | `P\Contents\sdk` |
| 会话变量 `DEVECO_SDK_HOME` | 同上 SDK 路径 | 同上 SDK 路径 |
| `hvigorw` | `P\tools\hvigor\bin\hvigorw.bat` | `P\Contents\tools\hvigor\bin\hvigorw` |
| `ohpm` | `P\tools\ohpm\bin\ohpm.bat` | `P\Contents\tools\ohpm\bin\ohpm` |
| `hdc` | `<SDK>\default\openharmony\toolchains\hdc.exe` | `<SDK>/default/openharmony/toolchains/hdc` |
| `csr-generate --java-path`（可选） | `P\jbr\bin\java.exe` | `P\Contents\jbr\Contents\Home\bin\java` |

校验：对应 `hvigorw` 存在，且 `<SDK>/default/openharmony/toolchains/lib/hap-sign-tool.jar` 存在。失败 → 再问用户，**不要**换目录重试。

写入当前工程 **CWD** `.env`（CLI 只读这里；无 BOM、不覆盖已有 AGC 键、不打印 `.env` 内容）。先把校验通过的路径放进当前会话的 `DEVECO_HOME`，再跑：

```powershell
# 无 BOM 只更新 DEVECO_HOME；值来自当前环境，勿 echo .env
node -e @'
const fs=require("fs"); const file=".env";
const home=process.env.DEVECO_HOME;
if(!home) process.exit(1);
let t=fs.existsSync(file)?fs.readFileSync(file,"utf8"):"";
if(t.charCodeAt(0)===0xFEFF) t=t.slice(1);
const line="DEVECO_HOME="+JSON.stringify(home);
const re=/^DEVECO_HOME=.*$/m;
t=re.test(t)?t.replace(re,line):t.replace(/\s*$/,"")+(t.trim()?"\n":"")+line+"\n";
fs.writeFileSync(file, t);
'@
```

bash 用同一段 JS，把 `@' ... '@` 换成 `node -e '... '`（外层单引号）。

之后 `csr-generate` 可不传 `--sdk-path`（读 `DEVECO_HOME`）。构建必须用上面算出的 **`hvigorw` 绝对路径**，不要依赖 PATH 里的同名命令。

跑 `hvigorw` 前还要把 **`DEVECO_SDK_HOME` 导出到当前会话**（值 = 上表 SDK 路径）。**只导出、不写进 `.env`**。hvigor 不会从 `DEVECO_HOME` 自己填这个变量；工具文件都在、shell 没设，仍会报 `00303217 Invalid value of 'DEVECO_SDK_HOME'`。

```powershell
$env:DEVECO_SDK_HOME = Join-Path $env:DEVECO_HOME "sdk"
```

```bash
# macOS .app：DEVECO_SDK_HOME="$DEVECO_HOME/Contents/sdk"
export DEVECO_SDK_HOME="$DEVECO_HOME/sdk"
```

## 4. 停下来问人，别自己硬试

这些不是报错重试能解决的：

- **DevEco 路径未知**：`.env` 没有可用的 `DEVECO_HOME`。问用户安装目录并写入 `.env`，**禁止搜索**（见 §3.1）。
- **应用不存在**：`publish app-id` 返回空 `appids` 时，先 `project list` **把 projectId 列表回显给用户选定**，再用 `publish app-create --project-id <选定值>` 创建（或 TTY 下省略 `--project-id` 交互选）。也可去控制台建。
- **403**：token 有效但该 API 客户端无此应用/团队权限，只能由用户去控制台改权限。重试无意义。
- **OAuth 浏览器授权**、**ACL 审批**：都需要人工，且 ACL 审批以天计，不要轮询 `acl-status`。
- **需要真机**：`hdc` 相关步骤要设备已 USB 连接。

## 5. 动手前先确认的操作

删除类命令（尤其 `cert-delete` / `profile-delete` / `device-delete`）**每一次执行前都必须弹框二次确认具体对象**（名称 + id）。用户明确点头后才能调用；未确认禁止执行。

**「随便删一个 / 删一个 / 都可以 / 按你说的删」不算确认。** 这类话只表示同意删除，没有指定对象。必须再弹框列出候选（至少名称、类型、id），等用户选定或确认「就删这一张」之后才能 `cert-delete`。上一轮的确认不能带到这一次。

用户说「删除证书」时（Windows 用 `node $CONNECT_API_JS`，不要裸跑 `connect-api-cli`，不要 `jq` / `2>/dev/null`）：

1. `node $CONNECT_API_JS provision cert-list`，从 `.certList[]` 取 `.id` / `.certName` / `.certType`（`1` 调试 · `2` 发布）。
2. **弹框**让用户选要删的那张（选项用名称，提交后用对应 **id**）。即使用户说「随便一个」，也要先弹出你准备删的那一张（名称 + id），等确认。
3. `node $CONNECT_API_JS provision cert-delete --cert-ids <id>`（必须是 `--cert-ids`，不要 `--cert-id`，不要传证书名）。
4. 再 `cert-list` 确认已消失。

不要为了「看关联 Profile」先跑 `profile-list`：它**必须** `-a <appId>`，缺了会直接 `required option '-a'`。需要对照时先 `publish app-id -p <bundleName>` 再 `profile-list -a <appId>`，用 `.provisionList[].certName` 对齐。

| 操作 | 原因 |
|------|------|
| `cert-delete` / `device-delete` / `profile-delete` | **不可撤销**。正在使用的证书/Profile 删掉会导致已发布应用无法更新。**每次**弹框须展示将删的名称 + id；「随便删一个」也要先确认具体对象 |
| `domain update` | **消耗修改配额**，配额有限且不恢复。执行前先 `domain config` 看余量 |
| `upload file -r 1` | 全量发布类型，影响线上。测试用 `-r 6` |
| `cert-create` | 证书数量有上限。仅当**本工程 `.certs/` 已有配套 `.p12`** 时才复用 `cert-list` 里未过期的同类型证书 |

`csr-generate` 默认写到 **`.certs/<随机数>/`**，文件带类型前缀：`key_<随机数>.p12` / `.csr`，`cert_<随机数>.cer`，`profile_<随机数>.p7b`。调试与发布各一套。跑命令前 **弹框让用户输入**证书签名密码，把用户输入作为 `--pwd` 传入（P12 与 key 相同）。**禁止**自动生成、**禁止**CLI 自己弹对话框、**禁止**把 `.pwd` 回显。JSON 含 `.filename` `.storePath` `.csrPath` `.cerPath` `.p7bPath` `.pwd`，成功时还会把 DevEco `material/` 放到 `.storePath/material`（`.materialPath`）。**禁止**手写路径、**禁止**把签名文件拷到工程根目录。重跑会新建子目录——失败重试前先看 `.certs/` 里是不是已经有了。

**签名只认工程本地，禁止搜云侧。** 完整一套 = 同目录 `.p12` + `.cer` + `.p7b`（用途对应 type 1 调试 / type 2 发布）。只在当前工程 `.certs/` 和 `build-profile.json5` 的 `signingConfigs` 里找。本地没有、只有调试套、或缺 `.p12` → **立刻走流程 B 重新生成**（`csr-generate` → `cert-create` → `profile-create` → `encrypt-pwd`）。AGC `cert-list` 有证书也不能当本地材料：云侧不下发私钥。**禁止**搜 AGC/云侧签名、**禁止**在整盘/其他工程/Downloads 里找旧 `.p12` 去「配对」云上证书。

## 6. ID 来源链（禁止编造，一律从上游提取）

| 需要的值 | 来自哪条命令 | jq 提取路径 |
|----------|--------------|-------------|
| `appId` | `publish app-id -p <包名>` 或 `publish app-create` | `.appids[0].value` / `.appId` |
| `projectId` | `project list`（或 `publish app-info` 的 `.appInfo.projectId`） | `.projectList[].projectId` |
| `certId` | `cert-create` / `cert-list` | `.certInfo.id` / `.certList[0].id` |
| 证书下载地址 | 同上 | `.certInfo.certDownloadUrl` |
| `deviceId` | `device-list` | `.deviceList[] \| select(.udid=="<UDID>") \| .id` |
| 设备 UDID | `$HDC shell bm get --udid`（`HDC` 来自 §3.1） | — |
| `provisionId` | `profile-create` / `profile-list` | `.provisionInfo.id` / `.provisionList[0].id` |
| Profile 下载地址 | 同上 | `.provisionInfo.provisionDownloadUrl` |
| 域名配额余量 | `domain config` | `.configs[0].modifyCounts` |

下载地址**有有效期**，取到后立即 `curl -o` 落盘，不要先做别的。

## 7. 能力地图

| 分组 | 能做什么 |
|------|----------|
| `auth` | 登录、查 token 状态、登出 |
| `publish` | 创建应用/元服务、包名 → App ID、应用/版本信息、包绑定、提交审核、资质与协议等 |
| `project` | 查询项目列表（`projectId`） |
| `upload` | 上传 **APP**（HarmonyOS 上架/测试分发）/APK/图片（≥5MB 自动分片）。**不要上传 HAP** |
| `provision` | 证书、设备、Profile、指纹、ACL；本地生成 CSR/P12；加密 DevEco 签名密码 |
| `domain` | 域名查询/更新、配额查询、校验文件下载、业务域名预检 |
| `test` | 邀请/公开测试版本、分组与成员、邀请码、公开链接、测试反馈 |

参数、枚举取值、JSON 入参格式 → [references/commands.md](references/commands.md)。拿不准就 `$CONNECT_API_CLI <分组> <子命令> --help`，不要凭印象拼参数。

## Decision Tree

先 `auth status`（§3），再按下表选流程。逐步命令见 [workflows.md](references/workflows.md)。

```
缺凭证 / .env 读不到？          → 停，按 §3 让用户写入 .env
OAuth 要浏览器授权？            → 停，等用户点授权（非交互环境不要重试）
没有 DEVECO_HOME 且要签名/构建/真机？ → 停，按 §3.1 问安装目录；禁止搜盘
用户要上传 .hap 上架/测试？     → 拒绝：商店与测试分发只接受 .app
运行到手机 / 真机 / hdc？       → 流程 D（先 §3.1）
上架 / 提交审核 / release APP？ → 流程 C（发布证书 + assembleApp + .app）
邀请测试 / 公开测试？           → 流程 G（.app + -r 6）
申请证书 / Profile / 签名材料？ → 流程 B（调试 type 1 需设备；发布 type 2 不要）
配域名白名单？                  → 流程 E
申请受限权限 ACL？              → 流程 F
验证凭证 / 查 App ID？          → 流程 A
```

## 8. 业务流程

选定后打开 [references/workflows.md](references/workflows.md)，里面每步都带提取命令与校验点。

HarmonyOS：**商店/邀请测试/公开测试上传 `.app`**（发布证书 + `assembleApp`），**不要上传 `.hap`**。`.hap` 只用于流程 D 本地 `hdc install`。

用户说「构建 app 包 / release 包」时，**先按用途对照，不要默认 `assembleHap`**：

| 用户想做 | 任务 | `-p`（必须驼峰） | 证书 / Profile | 产物 | 流程 |
|----------|------|------------------|----------------|------|------|
| 运行到手机 / 真机调试 / hdc 安装 | `assembleHap` | `buildMode=debug` | type **1** 调试 | `.hap` | **D**（先过 §3.1） |
| 上架 / 邀请测试 / 公开测试 / release APP | `assembleApp` | `buildMode=release` | type **2** 发布 | `.app` | **C** / **G** |

**硬规则（违反就会打出 debug 包还声称成功）**：

- `-p` 必须写成 **`buildMode`**（驼峰）。`-p buildmode=release` 会被 **静默忽略**；`assembleHap` 默认 debug，命令成功也不等于 release。
- 构建只用本 skill 写明的 `hvigorw` 命令（流程 C2 / D5），可执行文件路径来自 §3.1 的 `DEVECO_HOME`，不要换别的封装、不要搜 PATH。
- 编译模式和签名类型是两套：`buildMode=release` + **调试**证书仍是调试签名包，不能上架。上架必须 **发布证书 + `assembleApp` + `.app`**。
- **`buildMode=debug` 切不了证书。** hdc 能否安装只看 `products[].signingConfig` 指向哪一套 material。product 若仍是 `release`（发布 Profile 无设备绑定），即使 debug 编译，`hdc install` 也会 `not trusted app source`。装机前解包 `.p7b` 须 `"type":"debug"`；若临时改了 `products[].signingConfig`，装完必须改回。**禁止**先装失败再回头改配置。
- **构建后必须验产物，未验不准说成功**：解包 `module.json`，release 须 `app.buildMode=="release"` 且 `app.debug==false`。`app.apiReleaseType=="Release"` 只是 SDK API 渠道；文件名里的 `default` 是 **product 名**。`.p7b` 明文 `"type"` 为 `debug` 还是 `release`。
- 跑 `hvigorw` 前必须导出 `DEVECO_SDK_HOME`（§3.1 推出的 SDK 目录）。只校验 `hvigorw`/`hdc` 文件存在不够。
- **上架签名只认本工程 `.certs/`**。没有发布套（或缺 `.p12`）就重新跑流程 **B-发布**，不要搜云侧签名、不要满盘找旧私钥。AGC 上已有 `MyReleaseCert` 之类但本地没有配套 `.p12` = 不能复用。
- **DevEco 路径只认 `.env` / 用户提供**（§3.1）。不知道就问人并写入 `DEVECO_HOME`，禁止搜盘、禁止套用文档示例路径。

| 用户想做 | 流程 |
|----------|------|
| 验证凭证能用 / 首次接入 | **A** login → app-id → app-info |
| 上传构建产物 | **C** appId → `upload file`（HarmonyOS 须 `.app`；默认会上报到 AGC。测试分发用 `-r 6` 再 `test pkg-add`） |
| 邀请/公开测试分发 | **G** `test version-create` → upload `.app` → `test pkg-add` → `test version-submit` |
| 申请证书 + Profile | **B** csr-generate → cert-create → device-add → profile-create（调试 type 1 需设备；发布 type 2 不要设备） |
| 运行到手机 / 从零签名装进真机 | **D** = 先 §3.1（`DEVECO_HOME`）→ B + `encrypt-pwd` + `hvigorw` 构建 + `hdc` 安装。**禁止**搜 DevEco、禁止 Harmony MCP、禁止裸跑 `hdc` |
| 配域名白名单 | **E** config → pre-check → update → verify-file |
| 申请受限权限 | **F** acl-apply → acl-status |

## 9. Checklist

### Critical
- [ ] 使用内嵌 `scripts/connect-api-cli.js`（bash：`$CONNECT_API_CLI`；PowerShell：`node $CONNECT_API_JS`），未引导全局安装
- [ ] v1.1.4+ 结合退出码与业务字段判定；未用 bash `2>/dev/null` / `jq` 管道硬套到 PowerShell
- [ ] `appId` / `projectId` / `certId` / `provisionId` 均从上游提取，未编造
- [ ] 上架/测试分发上传 `.app`（非 `.hap`）；真机安装用调试签名 `.hap`（流程 D）
- [ ] 签名/构建/hdc 前已过 `DEVECO_HOME` 门禁；未搜盘、未用 Harmony MCP 代替
- [ ] 未打印 `.env`、token、`.pwd`、P12 明文密码

### Warning
- [ ] 删除类操作已弹框确认名称 + id
- [ ] `encrypt-pwd` 已带 `--config-dir`
- [ ] 证书/Profile 下载 URL 已立即落到 `.cerPath` / `.p7bPath`
- [ ] 时间戳按毫秒换算为北京时间（`Asia/Shanghai`），未用 `toISOString()` 直接展示
- [ ] ACL 审批中未轮询 `acl-status`

### Info
- [ ] CLI 版本 ≥ 1.1.4
- [ ] 失败已对照 troubleshooting，未盲目重试 401/403/空结果

## 10. 出错时

先读 stderr 第一行，对照 [references/troubleshooting.md](references/troubleshooting.md) 找因果。401/403/空结果不要原样重试。`encrypt-pwd` 报「未找到加密密钥目录」时，加 `--config-dir` 指向用户主目录（Windows：`%USERPROFILE%\.ohos\config`）再跑，**不要**用不带该参数的同一条命令重试。

## 11. 不要外泄

不打印 `.env` 内容、完整 access token、`~/.connect-api-cli-token.json`、P12 密码。
需要展示配置时只给键名：`sed 's/=.*/=***/' .env`。确认登录状态用 `auth status`。
`.env`、`.certs/`、`*.p12`、token 缓存都不入库。
