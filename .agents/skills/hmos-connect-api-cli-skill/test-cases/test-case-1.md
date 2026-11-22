# 测试用例 1：登录与退出登录

## 场景描述
验证 connect-api-cli 的 AGC 凭证门禁、登录与退出登录（清除本地 token）。

## 前置条件
- Node.js LTS 可用
- `scripts/connect-api-cli.js` 存在（版本 ≥ 1.1.4）
- 工作目录可放置 `.env`（含 `AGC_CLIENT_ID`/`AGC_CLIENT_SECRET` 或 Service Account）

## 执行步骤

### 1.1 登录
1. 定位 `$CONNECT_API_JS` / `$CONNECT_API_CLI` 指向本 skill `scripts/connect-api-cli.js`
2. `auth status`
3. 分支：
   - Missing credentials → 停止，指导用户写 `.env`（不打印密钥）
   - Token cached: no → `auth login`
   - Token cached: yes → 跳过 login，报告剩余时间
   - Auth mode: oauth → 提示浏览器授权，不循环重试
4. 再次 `auth status` 确认可用

### 1.2 退出登录
1. `auth logout`
2. `auth status` 确认 token 已清除（Token cached: no 或等价）
3. 确认 `.env` 仍在，未被删除

## 预期结果
- 登录成功后可执行后续业务命令
- 退出后本地 `~/.connect-api-cli-token.json`（或等价缓存）已失效
- PowerShell 未错误使用 `& "node path.js"` 整串调用

## 验证方法
- 检查命令序列是否为 status → login（按需）→ status；logout → status
- 检查未外泄 `.env` 与 access token
