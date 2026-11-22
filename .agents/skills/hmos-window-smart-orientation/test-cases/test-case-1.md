# 测试用例 1：智感旋转机制咨询与零成本接入

## 场景描述
开发者首次接触智感旋转能力，希望了解其机制并让应用获得智感旋转体验，关心是否需要新增接口或权限。

## 前置条件
- 应用基于 Stage 模型 + ArkTS（`@ohos.window`）
- 测试设备为搭载 OpenHarmony 7.0.0 及以上版本且支持智感传感器的机型（验证智感体验时需要）

## 执行步骤
1. AI 代理识别"智感旋转"关键词，触发本技能（场景 ROT-01）
2. AI 代理解释智感旋转机制：系统方向判定 = 旋转策略 + 重力传感器角度 + 旋转锁定开关 + 应用场景 + 智感旋转开关（OH 7.0.0+）
3. AI 代理说明零成本接入要点：无新增 API、无新增权限；自动旋转类策略（AUTO_ROTATION 系列 / USER_ROTATION 系列）、FOLLOW_DESKTOP 或默认 UNSPECIFIED 均参与
4. AI 代理给出设置示例（module.json5 静态配置或 setPreferredOrientation 运行时调用）
5. AI 代理说明回退行为：设备/系统不支持或开关未开启时自动回退纯重力传感器旋转

## 预期结果
- 准确说明"重力传感器和智感传感器共同作用决定最终方向"
- 准确给出用户开关路径：设置 > 系统 > 智感旋转
- 明确固定方向策略（PORTRAIT/LANDSCAPE/PORTRAIT_INVERTED/LANDSCAPE_INVERTED）不参与智感旋转
- 未虚构任何"智感旋转专用 API"或新增权限
- 提供的示例代码使用 window.Orientation 正确枚举值

## 验证方法
- 检查输出是否包含"智感传感器""重力传感器"共同作用的表述
- 检查是否明确"无需新增接口/权限"
- 检查示例代码的枚举值与接口签名是否正确（setPreferredOrientation(window.Orientation.AUTO_ROTATION_RESTRICTED) 等）
- 检查是否说明不支持设备上的回退行为

## 备注
这是本技能最高频的使用场景。若开发者使用固定策略且希望获得智感体验，应进一步引导至 ROT-05 扫描改造流程。
