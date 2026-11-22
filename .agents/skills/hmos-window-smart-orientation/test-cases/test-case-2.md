# 测试用例 2：两种方式设置旋转策略

## 场景描述
开发者需要为应用设置旋转策略，分别验证 module.json5 静态配置（启动即生效）与运行时 setPreferredOrientation API（动态切换）两种接入方式，以及两者的覆盖关系。

## 前置条件
- 存在可构建的 HarmonyOS 工程，module.json5 位于 entry/src/main/module.json5
- EntryAbility.ets 中已实现 onWindowStageCreate 回调

## 执行步骤
1. AI 代理识别需求，路由至场景 ROT-03，读取 rotation-api.md 的"两种方式总览"
2. 方式一：在 module.json5 的 abilities 标签配置 "orientation": "auto_rotation_restricted"
3. 方式二：在 onWindowStageCreate 中调用 windowStage.getMainWindowSync().setPreferredOrientation(window.Orientation.AUTO_ROTATION_RESTRICTED)，并用 try-catch 捕获 BusinessError
4. AI 代理说明两种方式的覆盖关系：运行时调用覆盖静态配置（对当前窗口会话生效），未运行时设置时按静态配置生效，两者都未设置时默认 UNSPECIFIED
5. AI 代理说明选型建议：静态配置适合启动即固定/初始方向，运行时 API 适合动态切换

## 预期结果
- 静态配置示例包含 abilities 标签与 "orientation" 字段，取值为合法小写蛇形命名（如 "auto_rotation_restricted"）
- 运行时示例先获取主窗口再调用，并说明仅主窗口支持
- 说明 18 个取值与 window.Orientation 枚举一一对应
- 说明临时方向类型（user_rotation_*）一般用于运行时动态切换，不建议静态配置

## 验证方法
- 检查 module.json5 示例的 JSON 结构正确（name/srcEntry/orientation 等字段）
- 检查运行时代码包含错误处理（BusinessError 捕获）
- 检查是否说明两种方式均受行为限制约束（仅主窗口、分屏/悬浮窗等场景被忽略）
- 检查是否给出按需求选型的建议表或等价内容

## 备注
若开发者追问具体取值含义（如 auto_rotation_restricted 与 auto_rotation_unspecified 的差异），应进一步引用 orientation-strategies.md（ROT-02）。
