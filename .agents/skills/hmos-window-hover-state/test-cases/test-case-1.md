# 测试用例 1：悬停态机制咨询与接入

## 场景描述
开发者首次接触折叠屏悬停态，希望了解机制并让应用获得"上半屏内容 + 下半屏操作"的分区布局能力，关心需要监听什么接口、是否新增权限。

## 前置条件
- 应用基于 Stage 模型 + ArkTS（`@ohos.window`）
- 测试设备为折叠屏（书本型，Mate X / Z Fold 类）
- 目标 SDK 的 `@ohos.window.d.ts` 已声明 `WindowPostureMode` 系列 API（未声明时本用例退化为降级方案咨询，见测试用例 4）

## 执行步骤
1. AI 代理识别"悬停态/半折叠/悬停模式/笔记本形态"关键词，触发本技能（场景 HVS-01/HVS-02）
2. AI 代理解释悬停态机制：设备半折叠（HALF_FOLD）+ 折痕横向 + 全屏窗口满足系统判定条件时，窗口进入 `WindowPostureMode.DESKTOP_MODE`，无需新增权限
3. AI 代理给出接入三件套：`isInWindowPostureMode` 初始查询 + `onWindowPostureModeChange` 监听 + `@State isInHover` 单状态源驱动布局
4. AI 代理强调 API 形态：window 实例方法（非泛型 on 事件），注册时必须传 `WindowPostureMode.DESKTOP_MODE`
5. AI 代理给出回调内只切状态、布局交给声明式 UI 的代码组织方式

## 预期结果
- 准确说明系统侧判定条件（全屏、折痕横向、无缩放、非 LS 态、折痕区域校验）
- 未虚构任何"悬停态专用权限"或不存在的接口
- 示例代码使用正确的实例方法签名
- 提示先核验目标 SDK 是否声明该组 API

## 验证方法
- 检查输出是否包含 `WindowPostureMode.DESKTOP_MODE`、`onWindowPostureModeChange`、`isInWindowPostureMode`
- 检查是否说明触发条件链（HALF_FOLD + 全屏窗口）
- 检查示例代码是否回调内只切状态、不做重活

## 备注
这是本技能最高频的使用场景。若开发者 SDK 未声明该组 API，应引导至降级方案（测试用例 4）。
