# 用例：targetSdk 不满足时中止

## 目标

`targetSdkVersion` 低于 `6.0.0(20)` 时，不自动改码。  
`compatibleSdkVersion` 低于 20 但 `targetSdkVersion` 已满足时，**不**作为中止条件。

## 前置

- 工程 `targetSdkVersion` 低于 `6.0.0(20)`，或在对话中明确该约束

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 3 触发
2. 观察 Skill 是否按 **targetSdk** 执行前置检测并停止

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S2

## 通过标准

- [ ] 明确提示需 `targetSdkVersion` **6.0.0(20)+**（gesturesShare 起始版本）
- [ ] **未**注入管理类 / 未改业务页
- [ ] 可给出升级 `targetSdkVersion` 后再接入的建议
- [ ] 不错误引用「HarmonyOS 5.0 即可用 gesturesShare」作为放行依据
- [ ] 不以「仅 `compatibleSdkVersion` 偏低」作为唯一中止理由（若 target 已满足应可继续，并说明运行时降级）
