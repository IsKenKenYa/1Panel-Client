# 测试用例 4：申请下载证书、打包并运行到真机

## 场景描述
端到端流程 D：调试证书 + Profile → encrypt-pwd → assembleHap → hdc 安装到真机。

## 前置条件
- 已登录；目标 `appId` 已知
- 真机 USB 已连接
- 用户可提供 DevEco Studio 安装目录（写入工程 `.env` 的 `DEVECO_HOME`）

## 执行步骤
1. **§3.1 门禁**：读 `.env` 的 `DEVECO_HOME`；缺失则弹框询问，校验 `hvigorw` 与 `hap-sign-tool.jar`  
   - **禁止**搜盘、`where hdc`、Harmony MCP 代替本门禁
2. 导出会话 `DEVECO_SDK_HOME`（由 `DEVECO_HOME` 推出，不写进 `.env`）
3. **流程 B（调试 type=1）**：
   - 仅当本工程 `.certs/` 已有完整一套（`.p12`+`.cer`+`.p7b`）才可复用；否则 `csr-generate` → `cert-create` → 下载 cer
   - `$HDC shell bm get --udid` → `device-add` / `device-list` 取 `deviceId`
   - `profile-create`（带 `--device-ids`）→ 下载 p7b 到返回的 `.p7bPath`
4. `encrypt-pwd`：**必须** `--config-dir` 指向用户主目录 `.ohos/config`；禁止回显 `.pwd`
5. 配置 `build-profile.json5` 指向调试 material；必要时临时改 `products[].signingConfig`（装完必须改回）
6. 用 `DEVECO_HOME` 下绝对路径 `hvigorw`：`assembleHap`，`-p productName=default` 且 **`buildMode=debug`（驼峰）**
7. 验产物后 `$HDC install <signed.hap>`

## 预期结果
- 真机安装成功；调试 Profile 明文 `"type":"debug"`
- 签名文件留在 `.certs/<随机>/`，未拷到工程根、未入库
- 未把 `.hap` 当作商店上传包

## 验证方法
- 对照 [workflows.md](../references/workflows.md) 流程 D
- 检查未使用 PATH 裸跑 `hdc`/`hvigorw`
- 检查装机前后 `signingConfig` 是否按规则恢复
