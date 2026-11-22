# 测试用例 4：SDK 未声明悬停 API 的降级方案

## 场景描述
开发者的目标 SDK 中搜不到 `onWindowPostureModeChange` / `isInWindowPostureMode`，需要不升级 SDK 的替代方案。

## 前置条件
- 应用基于 Stage 模型 + ArkTS
- 目标 SDK 的 `@ohos.window.d.ts` 未声明 `WindowPostureMode` 系列（已按技能要求核验，而非直接断言不存在）

## 执行步骤
1. AI 代理确认降级路径（场景 HVS-02）：以 `display.getFoldStatus() === FoldStatus.FOLD_STATUS_HALF_FOLDED` 为状态判据
2. AI 代理补充全屏自查：`windowSizeChange` 回调里复核窗口仍全屏，非全屏时强制清除悬停状态，减少误判
3. AI 代理说明启动初始状态用 `getFoldStatus()` 查询
4. AI 代理说明降级路径与标准路径的行为差异（状态判据、非全屏误判、LS 态抑制感知不到）

## 预期结果
- 明确告知降级方案的风险边界（可能误判进入），不隐瞒误差
- 不虚构 SDK 中不存在的接口调用
- 布局仍按折痕坐标锚定，与标准路径共用同一套 UI 适配代码

## 验证方法
- 检查输出是否包含 `FOLD_STATUS_HALF_FOLDED`、`getFoldStatus`、全屏复核逻辑
- 检查是否有"标准/降级行为差异"对照说明
- 检查是否建议 SDK 升级后切回标准 API 路径

## 备注
OpenHarmony 社区 SDK master 与商用 SDK 对该组 API 的声明进度不同，核验动作必须落在目标工程实际 SDK 上。
