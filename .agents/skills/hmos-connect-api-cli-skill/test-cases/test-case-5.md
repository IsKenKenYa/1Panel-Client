# 测试用例 5：上传软件包

## 场景描述
将 HarmonyOS 商店包（`.app`）上传到 AGC（流程 C）；并验证误传 `.hap` 时被拒绝。

## 前置条件
- 已登录；`appId` 已知
- 本地已有发布证书签名的 `.app`（发布 type=2 + `assembleApp` + `buildMode=release`）
- 若尚无 `.app`：先过 §3.1 与流程 B-发布 + C 构建，再上传

## 执行步骤

### 5.1 正确上传 .app
1. 确认文件扩展名为 `.app`，且发布签名（`.p7b` type=release；`module.json` 中 `app.buildMode=="release"` 且 `app.debug==false`）
2. 正式全量：`upload file -a <appId> -f <path.app> -r 1`  
   测试分发：`-r 6`（再接流程 G 的 `test pkg-add` 等）
3. 校验退出码（≥1.1.4）与 `.ret.code == 0`；记录 `objectId` / fileName 供 `package-update`（若未自动上报）
4. 需要上架审核时继续 `publish package-update` → `submit`（按 [workflows.md](../references/workflows.md) C）

### 5.2 误传 .hap
1. 用户提供 `*.hap` 作为「上传应用市场」目标
2. **拒绝**调用 `upload file -f *.hap`
3. 说明：商店/邀请/公开测试须 `.app`；`.hap` 仅流程 D 本地 `hdc install`

## 预期结果
- `.app` 上传成功；`.hap` 不上传到 AGC
- 全量 `-r 1` 前若用户未确认，应提示影响线上
- 未编造 `appId` / `objectId`

## 验证方法
- 检查 upload 命令的 `-f` 扩展名与 `-r` 取值
- 检查对话中不存在对商店场景的 `.hap` 上传命令
