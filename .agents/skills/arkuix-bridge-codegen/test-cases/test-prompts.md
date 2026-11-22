# arkuix-bridge-codegen 测试提示词

> 运行前提：Node.js ≥ 18（零第三方依赖，全程离线）；自动场景用仓内 `benchmark/fixture-source-project` + `benchmark/fixture-scan-report/report.json`（含 ③×2 + ④×1：deviceInfo::udid / batteryInfo::batterySOC / vibrator::startVibration 及一条未收录 nonsense::mysteryApi）。

## 使用说明（AI 检测/自动化）

- **工作目录 = 本 skill 根目录**（`arkuix-bridge-codegen/`）。
- **「自动可测场景」**：命令自包含、确定性断言，可无人值守复跑。
- **「人工场景」**：需真实工程与 F2 产物、或围栏内手写实现，不进自动检测。
- **Windows/PowerShell**：bash 命令复跑需适配；`HOME` 隔离场景须同时设 `$env:USERPROFILE`。

---

## 自动可测场景

### A1：③④ 混合生成六件套（含映射建议与降级说明）
**命令**：
```bash
rm -rf /tmp/f3-a1 && node scripts/bridge.js benchmark/fixture-source-project --scan-report benchmark/fixture-scan-report/report.json --out /tmp/f3-a1
```
**预期**：
- 退出码 0；`/tmp/f3-a1/bridge-artifact.json`（schema_version=1）与 `bridge-report.md` 在场
- ③映射命中：`BridgeBatteryInfoBatterySOC.java` 围栏内含 `等价原生 API：android.os.BatteryManager.getIntProperty`
- ④降级：`BridgeVibratorStartVibration.java` 围栏内含 `降级说明` 与三要素 TODO（interface/platform/category）
- 未收录项如实呈报：`unmapped_native_apis` 含 `@ohos.deviceInfo::udid` 与 `@ohos.nonsense::mysteryApi`（不猜测）
- ①契约/②Local/③ArkUIX/⑥Impl 落位 `commons/<module>/{interface,utils,impl}/`；工程级 `commons/utils/PlatformInfo.ets` 在场

---

## 人工场景（不进自动检测）

- **增量再生成围栏保护**：A1 后改 ④⑤ 围栏内手改标记再跑——围栏内逐字节保留，②Local 已存在不覆盖
- **unknown 裁决后直连桥接**：F4 裁决 unknown→③ 的 scan-report 跑生成六件套
- **ndk C-API 接口**：source=ndk 无 .ets 迁移源——②Local `local_status:"failed"`，④⑤照常生成；`*include*` 头跳过
- **ScanReport 缺失/契约缺字段**：路径不存在→退出码 2；契约缺 adaptation→退出码 3 落空契约 `artifacts:[]`
- **③④ 均空良性完成**：空 equivalent/degraded→退出码 0，`artifacts:[]`
- **真实工程+F2 产物全链**：②Local 语句迁移完整性、audit.deficient 补全后重跑幂等、编译验证
