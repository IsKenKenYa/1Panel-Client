# 测试用例 3：申请 ACL 权限

## 场景描述
为指定应用申请 ACL 受限权限（流程 F），并正确处理审批周期。

## 前置条件
- 已登录
- 已知目标应用的 `appId`（或可由包名 `publish app-id -p` 解析）
- 权限名合法（可先 `acl-eligible` 查询）

## 执行步骤
1. 解析 `appId`，禁止编造
2. （推荐）`provision acl-eligible -a <appId>` 确认目标权限可申请
3. 用 `node -e` 或无 BOM 方式写入 `acls.json`（字段格式见 [commands.md](../references/commands.md)）
4. `provision acl-apply -a <appId> --acls acls.json`
5. 校验 `.ret.code == 0`（或 v1.1.4+ 退出码 + 业务字段）
6. 可选执行一次 `provision acl-status -a <appId>`：
   - `status=0` 申请中 → 告知用户审批以天计，**禁止轮询**
   - `status=1` 审核通过 → 后续 `profile-create` 可用 `--acls` 带入已授予权限名

## 预期结果
- ACL 申请请求成功提交
- 不因「审核中」反复调用 `acl-status`
- Windows 下 `acls.json` 无 UTF-8 BOM

## 验证方法
- 检查是否走流程 F（[workflows.md](../references/workflows.md)）
- 检查未在短时间内循环 `acl-status`
