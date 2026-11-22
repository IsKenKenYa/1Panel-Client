# 测试提示词

覆盖五大场景：登录/退出、创建应用与元服务、ACL、证书打包真机、上传软件包。

## 1. 登录、退出登录

### 测试场景 1.1：登录
**提示词**：
```
用 connect-api-cli 登录 AGC，并告诉我当前登录状态
```

**预期输出**：
- 定位内嵌脚本（PowerShell：`node $CONNECT_API_JS`）
- 先 `auth status`：缺凭证 → 提示补 `.env`（`AGC_CLIENT_ID`/`AGC_CLIENT_SECRET` 或 Service Account），不泄露密钥
- `Token cached: no` → `auth login`；`yes` → 跳过 login 并报告剩余时间
- OAuth 模式告知需浏览器授权，不盲目重试

### 测试场景 1.2：退出登录
**提示词**：
```
退出 connect-api-cli 的 AGC 登录
```

**预期输出**：
- 执行 `auth logout` 清除本地 token 缓存
- 再 `auth status` 确认已登出 / Token cached: no
- 不删除用户 `.env` 凭证文件

## 2. 创建应用和元服务

### 测试场景 2.1：创建应用
**提示词**：
```
在 AGC 给我创建一个 HarmonyOS 应用，名字叫 DemoApp，包名 com.example.demoapp
```

**预期输出**：
- 先 `project list`，把 projectId 列表回显给用户选定（非交互必须显式 `--project-id`）
- `publish app-create --project-id <id> --app-name "DemoApp" -p com.example.demoapp --parent-type 13 --installation-free 0`
- 成功：`.ret.code == 0` 且从 `.appId` 提取（或再 `publish app-id -p` 校验）
- 应用必须带 `-p` 包名

### 测试场景 2.2：创建元服务
**提示词**：
```
帮我创建一个元服务，名字叫 DemoAtomic
```

**预期输出**：
- 同样先选定 `projectId`
- `publish app-create ... --app-name "DemoAtomic" --parent-type 13 --installation-free 1`（**不传** `-p`）
- 成功提取 `.appId`

## 3. 申请 ACL 权限

### 测试场景 3.1：申请 ACL
**提示词**：
```
给我的应用申请 ACL 受限权限 ohos.permission.READ_CONTACTS
```

**预期输出**：
- 先解析 `appId`（`publish app-id -p` 或用户已给）
- 可选 `acl-eligible` 核对可申请列表
- 写无 BOM 的 `acls.json`，执行 `provision acl-apply -a <appId> --acls acls.json`
- 可用 `acl-status` **查一次**状态；审批中告知用户等待，**不轮询**
- 走流程 F（[workflows.md](../references/workflows.md)）

## 4. 申请下载证书、打包、运行到真机

### 测试场景 4.1：调试证书 + 打包 + 真机安装
**提示词**：
```
申请调试证书，打包后运行到手机上
```

**预期输出**：
- 识别为流程 **D**：先过 §3.1 `DEVECO_HOME`（无则弹框问用户，禁止搜盘 / Harmony MCP）
- 流程 B 调试（type 1）：`csr-generate` → `cert-create` → 注册设备 UDID → `profile-create` → 下载到 `.cerPath`/`.p7bPath`
- `encrypt-pwd` 必须带 `--config-dir`
- `assembleHap` + `buildMode=debug` + 调试签名；`hdc install` 用 §3.1 推出的 hdc 绝对路径
- 禁止上传 `.hap` 到商店；装完若临时改了 `signingConfig` 须改回

## 5. 上传软件包

### 测试场景 5.1：上传 .app 上架
**提示词**：
```
把刚打好的 release APP 包上传到 AGC 全量发布
```

**预期输出**：
- 流程 **C**：须 `.app`（发布证书 + `assembleApp` + `buildMode=release`）
- `upload file -a <appId> -f <xxx.app> -r 1`（全量）；测试分发应用 `-r 6`
- 拒绝用户若误传 `.hap`
- 校验 `.ret.code` / 退出码（≥1.1.4）与 objectId 等字段

### 测试场景 5.2：误传 HAP
**提示词**：
```
把 entry-default-signed.hap 上传到应用市场
```

**预期输出**：
- 拒绝上传；说明商店须 `.app`，`.hap` 仅流程 D 本地安装
