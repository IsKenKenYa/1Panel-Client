# 排错

按 stderr 第一行错误对号入座。**同一条命令不要重试**——这里几乎没有靠重试能好的错误。
标「用户操作」的，你做不了，报告给用户并停止。

---

## 命令层

| 症状 | 原因 | 动作 |
|------|------|------|
| `The term 'connect-api-cli' is not recognized` | 本 skill **不**装全局命令，不能裸跑 `connect-api-cli` | `node $CONNECT_API_JS provision cert-list`。见 [SKILL.md §2](../SKILL.md) |
| `The term 'node D:\...\connect-api-cli.js' is not recognized` / `#< CLIXML` | PowerShell 把 `"node 路径.js"` 整串当命令名：`$x = "node ...js"; & $x` | 变量只存 `.js` 路径：`$CONNECT_API_JS = "...\scripts\connect-api-cli.js"`，然后 `node $CONNECT_API_JS auth status`。**不要** `& $CONNECT_API_CLI`。见 [SKILL.md §2](../SKILL.md) |
| `jq` 不是内部或外部命令 / `jq: command not found` | Windows 默认无 jq | 不要管道 jq。读 CLI stdout JSON，用 `node -e` 抽字段 |
| `Could not find a part of the path` / 重定向到 `dev/null` 或 `/tmp` | PowerShell 里复制了 bash 的 `2>/dev/null`、`2>/tmp/agc.err` | 不要重定向。直接 `node $CONNECT_API_JS ...`，错误在 stderr |
| `error: required option '-a'`（`profile-list`） | Profile 按应用查，必须 `-a <数字 appId>` | 先 `publish app-id -p <包名>`。删证书不必先跑 profile-list |
| `error: required option '--cert-ids'` | 写成了 `--cert-id`，或把证书名当成了 id | 用 `cert-list` 的 `.certList[].id`：`provision cert-delete --cert-ids <id>` |
| `node: command not found` / 无法运行 scripts | 无 Node.js，或脚本路径指错 | 装 Node.js LTS；确认指向本 skill 的 `scripts/connect-api-cli.js`（见 [SKILL.md §2](../SKILL.md)） |
| `Cannot find module` / 脚本不存在 | skill 未带 `scripts/` 或路径错误 | 确认 `scripts/connect-api-cli.js` 存在；`$CONNECT_API_JS` / `$CONNECT_API_CLI` 指向该文件 |
| `\| jq` 报 `parse error` | 版本 < 1.1.1，stdout 混有 dotenv 横幅或签名工具日志 | 换用本 skill 自带脚本（≥1.1.1）；仍失败则 `... 2>/dev/null \| sed -n '/^{/,$p' \| jq`（从第一个 `{` 起截取） |
| 命令"看起来成功"但结果不对 | 旧版（≤1.1.3）失败时退出码可能为 0 | 改判 `.ret.code` 或 stderr 是否含 `Request failed:` |
| `error: required option ... not specified` | 缺必填参数 | `$CONNECT_API_CLI <分组> <子命令> --help` 核对，别猜 |

---

## 认证层

| 症状 | 原因 | 动作 |
|------|------|------|
| `Missing AGC credentials...` | 当前工作目录无 `.env`，或未导出环境变量 | `.env` **按 CWD 读取**，换过目录就读不到；确认在正确目录执行。仍缺失 → **用户操作**：控制台「用户与访问 → API 客户端」建客户端并写入 `.env`，或改用 Service Account |
| `Missing Service Account credentials` / 凭据文件找不到 | 未设 `AGC_SA_CREDENTIALS` 或路径错误 | 指向控制台下载的 `*_private.json`（含 `key_id` / `private_key` / `sub_account`） |
| `Login failed:` / 401 | Client ID/Secret 错、有空格或引号、客户端被停用；或 SA 凭据/私钥无效 | 先 `auth logout && auth login`；仍失败 → **用户操作**：核对凭证 |
| 换过 Client ID / Key ID / 域名后一直 401 | 缓存 token 与当前凭证不匹配 | `$CONNECT_API_CLI auth logout && $CONNECT_API_CLI auth login` |
| 403 `Request failed with status code 403` | token 有效，但该 API 客户端对此应用/团队无权限 | **用户操作**：控制台调整 API 客户端权限，之后重新 login。重试无意义 |
| oauth 模式 login 卡住不动 | 需人工浏览器授权 | 非交互环境用不了，告知用户去浏览器完成，或改用 `client_credentials` / `service_account` |
| `OAuth token refresh failed, need to re-login` | refreshToken 失效 | 重新 `auth login`（仍需人工授权） |

---

## 业务层

| 症状 | 原因 | 动作 |
|------|------|------|
| `app-id` 返回空 `appids` | ①应用未创建 ②包名写错 ③客户端看不到该应用 | 核对包名与工程 `bundleName`；确认无误 → `publish app-create` 创建，或去控制台建 |
| `upload file` 失败 | `-a` 传成了包名、文件路径不存在、传了 `.hap`、网络中断 | HarmonyOS 须传 **`.app`**；确认 `-a` 是 appId、文件可读；重跑整条，不需清理分片 |
| `upload file` 成功但 AGC 软件包管理/版本页没有记录 | 只传到了 OBS，没有调用「更新应用软件包信息」上报 | 上传 `.app`（非 `-r 6`）会自动上报，看 stdout `.bound == true` 和 `.packageId`。旧流程或 `--no-bind` 后须再跑 `publish package-update`。`-r 6` 须再 `test pkg-add`。解析完成前控制台可能仍显示处理中，可用 `publish compile-status` |
| `device-add` 返回 `failedCount > 0` | 设备已注册，或 UDID 格式错 | 查 `failedAddDeviceDetail`；已注册就直接从 `device-list` 取 `id` |
| `encrypt-pwd` 报 `未找到加密密钥目录`（路径落在 **CWD** `.ohos\config`） | Windows 上 `HOME` 常为空，未传 `--config-dir` 时默认目录相对当前工作目录 | 加 `--config-dir` 指向用户主目录：PowerShell `$env:USERPROFILE\.ohos\config`。**不要**用不带该参数的同一条命令重试。该路径下仍无 `material/` → **用户操作**：先装 DevEco 并生成过签名配置 |
| `csr-generate` 留下空的 `.certs/<随机数>/` | 旧版本在校验 SDK / 调 hap-sign-tool **之前**就 mkdir，失败重试会再生成一套随机目录 | 空目录可手动删。当前版本先校验，失败会清掉这次建的目录 |
| `hap-sign-tool.jar not found at ...` / `sdkPath is required` | `.env` 无 `DEVECO_HOME`，或它不是 DevEco 安装目录 | **用户操作**：问安装目录，写入 `DEVECO_HOME`（见 [SKILL.md §3.1](../SKILL.md)）。**禁止**全盘/`where`/`Get-Command` 搜索，禁止拿文档示例路径当本机默认去探测 |
| `csr-generate` 报 java 相关错误 | 本机 PATH 无可用 `java` | 用 `--java-path` 指向 **已由用户提供的** DevEco JBR（§3.1 表），不要搜盘找 `java.exe` |
| 下载 `.cer` / `.p7b` 得到空文件或 403 | 下载地址已过期 | 用 `cert-list` / `profile-list` 重取地址，取到立即下载 |
| `domain update` 报次数超限 | 修改配额耗尽，且不恢复 | 先 `domain config` 查余量；耗尽 → **用户操作** |
| `domain` 返回 `.ret.code == 0` 但域名没生效 | 单条域名带 `errorCode` / `errorMsg` | 逐条检查每个 `DomainInfo` |
| 上架/测试分发要传 HAP | 官方上传接口软件包格式是 APP | 走流程 C：发布证书 + `hvigorw assembleApp` 出 `.app` |
| `feedback-query` / `feedback-dimension`：`Unexpected token` / JSON parse | `--body` 文件带 UTF-8 BOM，或内容不是合法 JSON | 用无 BOM UTF-8 重写（`node -e` 或 PowerShell `UTF8Encoding($false)`）；body 是**文件路径**，不要把 JSON 直接当参数 |
| `feedback-*` 用 `.ret.code` 判断失败 | 这三条是 **`rtnCode`** 风格 | 改判 `.rtnCode == 0` |
| `feedback-query` 成功但 `feedbackInfos: []` | 时间窗内无反馈 | 正常；可放宽 `startTime`/`endTime`（毫秒）再查，不要当接口失败 |
| `feedback-dimension`：`rtnCode: -1`「应用不存在」，同 appId 的 `feedback-query`/`app-info` 却正常 | 维度接口对该应用/能力未开通或后端限制 | 不是 body 字段写错；不要改成秒级时间戳瞎试。报告用户后停 |

---

## 构建与安装层

| 症状 | 排查顺序 |
|------|----------|
| `hdc install`：`signature verification failed due to not trusted app source` | 装的是**发布证书**签的 HAP（Profile 无设备绑定）。常见原因：`products[].signingConfig` 指向 `release`，`-p buildMode=debug` **救不了**；或直接装了上次的 release HAP。**不要重试 install**。解包 hap 看 `.p7b` 的 `"type"`。是 `release` → 流程 D4.5：切到调试 signingConfig 后重构建，装完改回。 |
| hvigor `00303217 Invalid value of 'DEVECO_SDK_HOME'` | 当前 shell 未设 `DEVECO_SDK_HOME`。§3.1 只把 SDK 路径推出来，hvigor 不会从 `DEVECO_HOME` 自己填。构建前导出：Windows `$env:DEVECO_SDK_HOME="$env:DEVECO_HOME\sdk"`；macOS `.app` 用 `$DEVECO_HOME/Contents/sdk`。**不要**搜盘，**不要**把该变量写进 `.env` |
| `hdc install` 失败 / 装完闪退 | ①`AppScope/app.json5` 的 `bundleName` 与 AGC 包名、`.p7b` 是否完全一致 ②设备 UDID 是否已注册且在该 Profile 的设备列表里 ③Profile 是否 `--type 1`、证书是否 `--cert-type 1` ④`hdc list targets` 是否看得到设备 |
| hvigor 构建报密码错误 / `ENOENT .../material` | ①`build-profile.json5` 是否填了 `encrypt-pwd` 输出的 hex（不能是明文）②`material/` 必须在 `.p12` **同级**（`.certs/<随机数>/material`）。`csr-generate` 成功时 JSON 应有 `.materialPath`。**不要**把签名文件拷到工程根目录 |
| 构建产物找不到 | 上架找 `build/outputs/**/*.app`；本地调试找 `*/build/*/outputs/*/*-signed.hap`。模块名/product 名以工程为准 |
| 命令写了 release，装机/解包仍是 debug 包 | ①参数写成了 `-p buildmode=release`（全小写）→ hvigor **静默忽略**，`assembleHap` 回落 debug。必须 `-p buildMode=release` ②跑了 `assembleHap` 而不是 `assembleApp`（HAP 默认 debug；APP 默认 release）③没用 `DEVECO_HOME` 下的 `hvigorw` 绝对路径、换了别的封装或 PATH 里另一套工具，缺省经常是 HAP+debug ④`build-profile.json5` 仍是调试证书 / `.p7b` `"type":"debug"`。**判定**：解包 `module.json` 看 `app.buildMode` 与 `app.debug`；hvigor 日志看 `Picking option ... with build mode '...'`。`apiReleaseType: Release` 和文件名 `entry-default-signed.hap` 都**不是**依据 |
| 「release 模式 + debug 证书」仍不能上架 | 编译模式和签名类型独立。上架/测试分发必须 **发布证书（type 2）+ `assembleApp` + `.app`**。调试证书签出的包系统仍会当调试包 |
| AGC 已有发布证书，本地 `.certs/` 只有调试套 / 没有 `.p12` | 云侧证书不含私钥；本 skill 不做云侧签名 | **不要**搜云侧签名，**不要**满盘/其他工程找旧 `.p12`。在本工程重新走流程 B-发布：`csr-generate` → `cert-create`（type 2）→ `profile-create`（type 2）→ `encrypt-pwd` → 写入 `build-profile.json5` |
| 用户说「运行到手机」却去搜 `hdc` / DevEco / 调 Harmony MCP | 没过 §3.1，或没用本 skill | **先读 `.env` 的 `DEVECO_HOME`**。没有 → 问用户写入 `.env`。用该目录下的 `hvigorw`/`hdc` 绝对路径走流程 D。**禁止**搜盘、禁止裸跑 `hdc`、禁止 `harmony_launch_app` |

---

## 安全红线

- 不打印 `.env` 内容、完整 access token、`~/.connect-api-cli-token.json`、P12 密码。展示配置只给键名：`sed 's/=.*/=***/' .env`。
- `.env`、`.certs/`、`*.p12`、token 缓存不入库。
- 版本 < 1.1.1 的 `csr-generate` 会把 `-keyPwd <明文>` 打进日志：若在旧版日志里见到，提醒用户清理并更换该 P12 密码。
