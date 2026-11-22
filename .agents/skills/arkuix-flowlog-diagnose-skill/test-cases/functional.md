# 功能测试用例

## 测试前提

每次测试前必须配置日志环境（详见 SKILL.md "日志配置要求"章节）：

```bash
adb shell setprop log.tag.Ace V
adb shell setprop log.tag.ArkCompiler W
adb shell setprop log.tag.NAPI S
adb logcat -c
adb logcat -G 16M
```

## 测试用例清单

| 用例 | 场景 | 预期诊断 | 测试工程 |
|------|------|---------|---------|
| B-S1 | 启动卡顿（top-level阻塞） | 维度①链断+维度④大间隔+维度③F1延迟 | `bs1-startup-stall-s4` |
| B-S2 | 首帧未上屏（onAppear阻塞） | 维度③F1有vsync无→请求未上屏 | `bs2-first-frame-block` |
| B-S3 | 缺so闪退 | FAQ A-1命中 UnsatisfiedLinkError+dlopen | `bs3-native-lib-missing` |
| B-S4 | 缺abc白屏 | FAQ A-8命中 RunScriptBuffer failed | `bs4-modules-abc-missing` |
| B-S5 | JS异常（throw new Error） | FAQ A-5b命中+框架panda::TryCatch捕获 | `bs5-js-exception` |
| B-S6 | 大量节点stall | 维度④大间隔stall | `bs6-stall` |
| B-S7 | 高频触摸循环 | 维度④重复行循环嫌疑 | `bs7-loop` |
| B-S8 | 销毁路径压力 | 维度①销毁链锚点完整可查 | `bs8-destroy-uaf` |
| B-S9 | 正常冷启动基线 | 全链22锚点齐+首帧已上屏 | `bs9-normal-coldstart` |
| B-S10 | 正常warm前后台 | fgbg四态齐+Q-24 warm可见 | `bs10-normal-warm` |

## 验证结果（2026-10 实测）

配置 `Ace V` + `ArkCompiler W` + 清buffer 后，10/10 场景诊断准确。
