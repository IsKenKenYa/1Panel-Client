# arkuix-interface-scan 测试提示词

> 运行前提：Node.js ≥ 18（零第三方依赖）；仓内自带 `benchmark/mini-sdk` 与三套 fixture，**自动场景无需本机 SDK**。
> 环境变量基线：`OH_SDK_DIR`、`OHOS_SDK_HOME`、`DEVECO_SDK_HOME` 置空以复现确定性路径。

## 使用说明（AI 检测/自动化）

- **工作目录 = 本 skill 根目录**（`arkuix-interface-scan/`）。
- **「自动可测场景」**：命令自包含（仓内 fixture 相对路径 + `/tmp` 输出，跑前清理），预期为确定性断言，可无人值守复跑。
- **「人工场景」**：需真实工程、TTY 交互或真实 SDK，不进自动检测（跳过不算失败）。
- **Windows/PowerShell**：命令为 bash 形态，复跑需适配（`/tmp`→`$env:TEMP`、`rm -rf`→`Remove-Item -Recurse -Force`）；`HOME` 隔离场景须同时设 `$env:USERPROFILE`（win32 `os.homedir()` 读 USERPROFILE）。

---

## 自动可测场景

### A1：Stage 工程全量扫描（双源判定）
**命令**：
```bash
rm -rf /tmp/f2-a1 && node scripts/scan.js benchmark/fixture-stage-project --sdk-dir benchmark/mini-sdk --out /tmp/f2-a1
```
**预期**：
- 退出码 0；stdout 含 `SDK 判定源（显式指定）`
- `/tmp/f2-a1/scan-report.json`：`schema_version=1`、`project_model=stage`、`adaptation` 七桶键齐（full_direct/…/unknown）；至少一条 reason 含 `双源一致`
- `/tmp/f2-a1/migration-advice.md` 在场，含分桶表与 `单平台支持接口占比` 统计行

### A5：SDK 询问先行拦截（非 TTY 无预设）
**命令**：
```bash
rm -rf /tmp/f2-a5 && OH_SDK_DIR= OHOS_SDK_HOME= DEVECO_SDK_HOME= HOME=$(mktemp -d) \
  node scripts/scan.js benchmark/fixture-stage-project --out /tmp/f2-a5
```
（Windows 须同时设 `$env:USERPROFILE` 与 `$env:HOME` 同指假临时目录，否则本机真实 SDK 会泄漏进候选）
**预期**：
- 退出码 4，**零产出**（`/tmp/f2-a5/scan-report.json` 不存在）
- stderr 含 SDK 路径**查找方法**（`DevEco`）、`--sdk-dir` 重跑通道、`未经确认，不产出判定`

---

## 人工场景（不进自动检测）

- **C-API 扫描**：`node scripts/scan.js benchmark/fixture-capi-project --sdk-dir benchmark/mini-sdk`——inventory 含 `source:"ndk"` 条目，未覆盖头/符号落 unknown
- **单源降级**：`--no-sdk` 显式确认——scan-report 无 `sdk` 字段，advice 含 `SDK 未检出，单源判定`
- **--yes 自动采纳**：`OH_SDK_DIR=benchmark/mini-sdk` + `HOME` 隔离——退出码 0，`sdk.origin` 以 `auto:` 开头
- **FA 拒绝**：`fixture-fa-project`——退出码 3，stdout 含 `FA 模型不支持`，产物照常写出
- **TTY 交互全流程**：终端直跑真实工程，SDK 询问先行、无效路径当场纠正×3=中止
- **真实工程+本机 SDK**：`[SDK 候选清单]` 交叉核对、@hms 归⑥带替代、动态加载提示
