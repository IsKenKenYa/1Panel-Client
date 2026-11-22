# 测试用例 2：创建应用与元服务

## 场景描述
在 AppGallery Connect 上通过 `publish app-create` 创建普通应用（installation-free=0）与元服务（installation-free=1）。

## 前置条件
- 已登录（见 test-case-1）
- 账号具备创建应用权限（开发者级 Service Account 或团队级 API 客户端）
- 已知或可列出 `projectId`

## 执行步骤

### 2.1 创建应用
1. `project list`，将 `projectId` 与名称回显给用户选定（非 TTY 必须显式传 `--project-id`）
2. 执行：
   ```text
   publish app-create --project-id <项目ID> --app-name "<名称>" -p <包名> --parent-type 13 --installation-free 0
   ```
3. 校验 `.ret.code == 0` 且 `.appId` 非空；可用 `publish app-id -p <包名>` 复核

### 2.2 创建元服务
1. 同样先选定 `projectId`
2. 执行：
   ```text
   publish app-create --project-id <项目ID> --app-name "<名称>" --parent-type 13 --installation-free 1
   ```
   （**不要**传 `-p` / packageName）
3. 校验 `.ret.code == 0` 且 `.appId` 非空

## 预期结果
- 应用创建必须带包名；元服务不带包名
- `appId` 来自返回 JSON，未手编
- 若 403 / 权限不足 → 停止并提示用户改控制台权限，不重试

## 验证方法
- 对照 [references/commands.md](../references/commands.md) `app-create` 参数表
- 检查两条命令的 `--installation-free` 与 `-p` 使用差异
