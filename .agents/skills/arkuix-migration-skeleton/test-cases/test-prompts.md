# arkuix-migration-skeleton 测试提示词

> 运行前提：Node.js ≥ 18；自动场景使用 `benchmark/mock-ace/ace.js` 替身与仓内 fixture，**无需本机 ace/ArkUI-X SDK**。
> 消费前置：ScanReport 用仓内 `benchmark/scan-reports/stage.json`（等价 F2 产物）。
> 注意：modify 就地改造目标工程——**自动场景一律先复制 fixture 到 /tmp** 再跑，禁止直接改写 `benchmark/` 原件。

## 使用说明（AI 检测/自动化）

- **工作目录 = 本 skill 根目录**（`arkuix-migration-skeleton/`）。
- **「自动可测场景」**：命令自包含、确定性断言，可无人值守复跑。
- **「人工场景」**：需 TTY 交互、真实工程或真实 ace，不进自动检测。
- **Windows/PowerShell**：bash 命令复跑需适配；`HOME` 隔离场景须同时设 `$env:USERPROFILE`。

---

## 自动可测场景

### A1：modify 模式就地改造（默认归档路径，零 ace 依赖）
**命令**：
```bash
rm -rf /tmp/f1-proj /tmp/f1-a1 && cp -R benchmark/fixture-stage-project /tmp/f1-proj
node scripts/skeleton.js /tmp/f1-proj --scan-report benchmark/scan-reports/stage.json --mode modify --out /tmp/f1-a1 --yes --ace-bin /no/such/ace
```
**预期**：
- 退出码 0；stdout 含 `已从归档注入跨平台壳` 与 `实际改动文件清单`
- `/tmp/f1-proj/.arkui-x/android` 与 `.arkui-x/ios` 在场；`.arkui-x/arkui-x-config.json5` 含 `ignoreCrossPlatform`
- `/tmp/f1-a1/skeleton-result.json`：mode=modify、`platform_baseline.android.min_sdk=26`、`platform_baseline.ios.deployment_target="10.0"`；报告含 `平台版本基线（适用版本下限）` 段

### A9：Compile SDK 版本选择（强确认门 + 六元组替换）
**命令**：
```bash
# 强门：缺 --compile-sdk（其余齐）→ 码 6 + 指引（含最高/源工程版本推荐）
rm -rf /tmp/f1-a9 && node scripts/skeleton.js benchmark/fixture-stage-project --scan-report benchmark/scan-reports/stage.json \
  --mode new --migrate-configs no --out /tmp/f1-a9 --yes --ace-bin /no/such/ace
# 选 24 物化：版本六元组替换 + 基线落账
rm -rf /tmp/f1-a9b && node scripts/skeleton.js benchmark/fixture-stage-project --scan-report benchmark/scan-reports/stage.json \
  --mode new --scaffold-from --migrate-configs no --compile-sdk 24 --out /tmp/f1-a9b --yes --ace-bin /no/such/ace
# 未收录版本 / modify 误用 → 码 2
node scripts/skeleton.js benchmark/fixture-stage-project --scan-report benchmark/scan-reports/stage.json \
  --mode new --migrate-configs no --compile-sdk 25 --out /tmp/f1-a9c --yes --ace-bin /no/such/ace
```
**预期**：
- 第一条：退出码 6 零产出；stderr 含 `--compile-sdk <版本>`、`源工程版本 17`（fixture compatibleSdkVersion 5.0.5(17) 反查）、`compile_sdk=` 编排器通道
- 第二条：退出码 0；stdout 含 `Compile SDK 24`；产物 build-profile 的 compile/compatibleSdkVersion=**数字 24**（OpenHarmony 形态）、runtimeOS 恒 `OpenHarmony`；hvigor-config modelVersion `6.1.1` + 插件 `4.24.2`；根 oh-package modelVersion `6.1.1`；`platform_baseline.openharmony.compile_sdk_version="24"`
- 第三条：退出码 2；stderr 含 `支持版本`（16 键清单）

---

## 人工场景（不进自动检测）

- **new 多模块迁入**：`--mode new --migrate-configs no --compile-sdk 26.0.0`——entry/feature 源码迁入，`migrated_modules` 数组落账
- **new 配置迁移 yes**：`--migrate-configs yes`——白名单合并+双向校验，版本键不变量防回退，`config_migration.verification.ok=true`
- **配置迁移强确认门**：new 模式缺 `--migrate-configs`→退出码 6
- **幂等重跑**：已 modify 工程重跑→退出码 0 不二次注入
- **模型门**：ScanReport 缺失/FA→退出码 3 零写
- **零迁入显式失败**：空工程 new 模式→退出码 2
- **TTY 交互全流程**：模式/平台/配置迁移/版本/覆盖确认询问与中止零写
- **真实 ace 路径**：本机装 ArkUI-X SDK（API 22+）后跑 `--ace-modify`，TTY 透传多模块二级交互
