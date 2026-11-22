# arkuix-migration-orchestrator 测试提示词

> 运行前提：Node.js ≥ 18；自动场景用 `benchmark/fixture-project` + `benchmark/mock-skill`（三 Skill 秒级替身），**无需本机 SDK/真实工程**。
> Windows PowerShell 注意：含 `@` 的决策 ID 须单引号包裹（splatting 语义）。

## 使用说明（AI 检测/自动化）

- **工作目录 = 本 skill 根目录**（`arkuix-migration-orchestrator/`）。
- **「自动可测场景」**：命令自包含、确定性断言，可无人值守复跑；每场景独立 `/tmp/f4-*` 输出目录（跑前清理）。
- **「人工场景」**：需真实工程、TTY 交互或真实三 Skill，不进自动检测。
- 全链预设基线（下称"全套预设"）：`--answer skeleton_mode=modify --answer uk:@ohos.nonsense::mysteryApi=equivalent_bridge --answer uk:@ohos.mockFeature::legacyApi=keep_unknown --answer bd:@hms.map::map.MapComponent=降级为OH替代 --answer bd:@hms.push::pushService.getToken=裁剪 --answer bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList=重新设计实现 --answer bd:@kit.MockKit::mockKit.doThing=降级为OH替代`
- **Windows/PowerShell**：bash 命令复跑需适配；`HOME` 隔离场景须同时设 `$env:USERPROFILE`。

---

## 自动可测场景

### A1：单命令三阶段全链 + 裁决回写 + 报告段齐备
**命令**：
```bash
rm -rf /tmp/f4-a1 && node scripts/orchestrate.js benchmark/fixture-project --out /tmp/f4-a1 --skill-dir benchmark/mock-skill \
  --answer skeleton_mode=modify \
  --answer uk:@ohos.nonsense::mysteryApi=equivalent_bridge \
  --answer uk:@ohos.mockFeature::legacyApi=keep_unknown \
  --answer bd:@hms.map::map.MapComponent=降级为OH替代 \
  --answer bd:@hms.push::pushService.getToken=裁剪 \
  --answer bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList=重新设计实现 \
  --answer bd:@kit.MockKit::mockKit.doThing=降级为OH替代
```
**预期**：
- 退出码 0；`migration-state.json` 四阶段 done；scan-report/skeleton-result/bridge/bridge-artifact 产物齐备
- unknown 裁决原地回写：scan-report 中 `@ohos.nonsense` 移入 equivalent_bridge 桶且 reason 含 `F4 编排人工裁决`；`@ohos.mockFeature` 保持 unknown 且 reason 含 `显式搁置`
- `migration-report.md` 含：五段主体 + `源码改写工单` + `适用版本与环境要求`（含"升级 ArkUI-X SDK / Android SDK / Xcode"提示）

### A4：new 模式 migrate_configs + compile_sdk 强确认门（new 双门）
**命令**：
```bash
rm -rf /tmp/f4-a4 && node scripts/orchestrate.js benchmark/fixture-project --out /tmp/f4-a4 --skill-dir benchmark/mock-skill \
  --answer skeleton_mode=new --answer migrate_configs=no --answer compile_sdk=26.0.0 \
  --answer uk:@ohos.nonsense::mysteryApi=equivalent_bridge --answer uk:@ohos.mockFeature::legacyApi=keep_unknown \
  --answer bd:@hms.map::map.MapComponent=降级为OH替代 --answer bd:@hms.push::pushService.getToken=裁剪 \
  --answer bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList=重新设计实现 \
  --answer bd:@kit.MockKit::mockKit.doThing=降级为OH替代
# 对照 1：去掉 --answer migrate_configs=no（换新输出目录）→ 退出码 4，stderr 含 --answer migrate_configs=yes|no
# 对照 2：仅去掉 --answer compile_sdk=26.0.0（换新输出目录）→ 退出码 4，stderr 含 --answer compile_sdk=<版本> 与支持清单
```
**预期**：
- 全预设：退出码 0；MigrationState.decisions 含 `migrate_configs`（chosen=no）与 `compile_sdk`（chosen=26.0.0）；stdout 含 `scaffold 落点：/tmp/f4-a4`（new 模式骨架阶段开始前打印落点）
- 对照 1：退出码 4；stderr 含 `--answer migrate_configs=yes|no` 专属指引
- 对照 2：退出码 4；stderr 含 `--answer compile_sdk=<版本>` 专属指引与支持清单（10~24/26.0.0，推荐最高 26.0.0）

---

## 人工场景（不进自动检测）

- **SDK 待确认转译**：`ARKUIX_MOCK_SCAN=confirm-sdk` 跑 `--stages scan`——退出码 4，stderr 含查找方法（DevEco）+参考候选（★），零产出
- **非 TTY 缺决策预设**：仅 `--answer skeleton_mode=modify`——退出码 4，待答决策一次列全
- **子集轮与阶段解锁**：先 `--stages scan` 再带全套预设全跑——skipped 阶段解锁续跑，scan 已 done 不重跑
- **阶段前置缺失**：`--stages bridge` 无上游——退出码 3
- **回滚无 checkpoint**：`--rollback scan` 无快照——退出码 4
- **三次运行一致性**：`npm run benchmark`——mock 三次运行 migration-report 逐字节一致
- **真实工程全链**：SDK 路径询问呈报、⑥/unknown 逐项决策、分类确认授权（ARKUIX_SCAN_YES=1）、源码改写与桥接落位
- **TTY 决策交互与 bridge_codegen**：交互决策问答流；`--answer bridge_codegen=proceed` 触发代填指引
