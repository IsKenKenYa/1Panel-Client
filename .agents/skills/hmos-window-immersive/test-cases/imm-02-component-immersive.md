# 测试用例 2：组件级沉浸实现（安全区域拓展）

## 场景描述
开发者需要实现页面背景延伸到状态栏和导航条，页面顶部和底部颜色不同，需分别延伸。验证组件级 `.expandSafeArea()` 方案的代码生成。

## 前置条件
- 存在可构建的 HarmonyOS 工程
- 页面文件为 .ets 格式，使用 ArkUI 声明式开发范式

## 执行步骤
1. AI 代理识别"背景延伸""上下不同色"需求，路由至场景 IMM-02，读取 imm-02-component-immersive.md
2. AI 代理建议使用 `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])` 和 `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])`
3. AI 代理生成完整的 ArkTS 代码示例，顶部组件设 TOP 边缘延伸，底部组件设 BOTTOM 边缘延伸
4. AI 代理提示约束：expandSafeArea 要求组件与安全区边界重合、不能设固定宽高（百分比除外）

## 预期结果
- 上下不同色场景使用 `.expandSafeArea()` 并正确传入 SafeAreaType.SYSTEM 和 SafeAreaEdge.TOP/BOTTOM
- 代码示例中顶部组件和底部组件分别设置不同的 expandSafeArea 参数
- 提示了 expandSafeArea 的边界重合要求和尺寸限制

## 验证方法
- 检查 expandSafeArea 参数是否使用 SafeAreaType.SYSTEM 和 SafeAreaEdge 枚举
- 检查顶部组件是否设 SafeAreaEdge.TOP，底部组件是否设 SafeAreaEdge.BOTTOM
- 检查是否提示边界重合要求和尺寸限制约束

## 备注
若开发者追问滚动容器场景的 expandSafeArea 无效问题，应进一步引导至 IMM-05 的滚动容器沉浸方案（父容器设 expandSafeArea 或 clipContent）。
