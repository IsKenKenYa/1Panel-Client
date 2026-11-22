# arkuix-flowlog-diagnose-skill 验证工程集（test-case）

> SDD 需求 `feat-arkuix-flowlog-diagnose-skill` 的实机验证用例集，一场景一工程。
> 每个工程对应 skill 的一个 test-case 样例（B-S1~S10），含场景说明、复现步骤、实测关键日志。
> 最终归档到 codespace `docs/skill/arkuix-flowlog-diagnose-skill/test-case/` 作为验证参考。

## 工程清单（全部 10 场景）

| 目录 | 场景 | skill 预期 | 状态 | 备注 |
|------|------|-----------|------|------|
| `bs1-startup-stall-s4` | 启动卡顿（top-level 阻塞 10s） | 维度①链断（RunPage 后）+维度④大间隔+维度③F1 延迟 | ✅ 验证 | 应用层近似 S4 卡点（精确 S4 需 native 层） |
| `bs2-first-frame-block` | 首帧未上屏（onAppear 阻塞 8s） | 维度③：vsync 请求有→flush 延迟 8s="请求了未上屏" | ✅ 验证 | v1 踩坑：aboutToAppear 阻塞会变成 B-S6 模式 |
| `bs3-native-lib-missing` | 删 so→UnsatisfiedLinkError 闪退 | A-1：`UnsatisfiedLinkError: No implementation found for...`+`dlopen failed` | ✅ 验证 | README+脚本（改 APK 型） |
| `bs4-modules-abc-missing` | 删 modules.abc→白屏 | A-8 扩展：`RunScriptBuffer failed`+`Failed to get Ability object` | ✅ 验证 | README+脚本（改 APK 型） |
| `bs5-js-exception` | aboutToAppear throw new Error | A-5b：框架 panda::TryCatch catch 不白屏；errorManager 可协助拿 JS 栈 | ✅ 验证 | 完整工程+errorManager 注册 |
| `bs6-stall` | 同步构建 3.2 万节点→stall | 维度④：RunPage→vsync gap 3530ms | ✅ 验证 | List 懒加载无效，必须 Scroll+ForEach |
| `bs7-loop` | onTouch 高频→ProcessPointerEvent 277 次重复 | 维度④：重复行循环嫌疑 | ✅ 验证 | 同 ms 30+ 物理不可达，建议判定弹性化 |
| `bs8-destroy-uaf` | 销毁路径压力（慢 onDisappear+快速进出） | 维度①：销毁链锚点完整可查 | ✅ 验证 | UAF 未触发（需框架缺陷配合） |
| `bs9-normal-coldstart` | 正常冷启动基线 | 全链 22 锚点齐+S2/Q-24 补点可见+首帧已上屏 | ✅ 验证 | SDD AC-1.1/AC-1.2 实证 |
| `bs10-normal-warm` | 正常 warm 前后台 | fgbg 四态齐+Q-24 warm 场景可见 | ✅ 验证 | 用任一正常工程+HOME/am start 循环 |

## 使用约定

- 每个工程用最新 codespace SDK 构建：`ace build apk [--debug]`
- 抓日志前先执行 SKILL.md"日志限流预防与重置（Android）"章节的命令
- debug 包含 sourceMaps.map（JS 栈行级定位需要）；release 默认不含
- 验证记录（实测日志片段）写入各工程 README 的"实测关键日志"节
- 改 APK 型场景（bs3/bs4）：用 Python zipfile 删条目（resources.arsc 必须 ZIP_STORED）+ zipalign + apksigner 签名
