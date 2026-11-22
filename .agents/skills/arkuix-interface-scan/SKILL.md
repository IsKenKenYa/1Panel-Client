---
name: arkuix-interface-scan
description: 扫描 OpenHarmony Stage 工程的 @ohos.*/@hms.* 接口引用与 Native NDK C-API 引用（#include 头文件 + OH_* 符号），按六分类（完整直用/有损直用/等价桥接/降级桥接/平台裁剪/业务决策，unknown 兜底）产出 scan-report.json 与 migration-advice.md。评估 OH 应用迁移 ArkUI-X 接口适配性时使用；FA 模型不支持。
license: MIT
metadata:
  author: ArkUI-X 团队
  version: "1.2.0"
  created: "2026-09-10"
  updated: "2026-09-19"
  keywords: ["arkui-x", "interface-scan", "cross-platform", "migration", "scan-report", "ndk", "c-api"]
compatibility: Requires Node.js >= 18. Fully offline; zero third-party dependencies.
---

# ArkUI-X 接口适配性扫描 Skill（F2）

## 能力与边界

**做：**
- 扫描 Stage 工程（module.json5 + .ets/.ts + resources + 构建配置）的 @ohos.*/@hms.* 引用
- 扫描 Native 源码（.cpp/.cc/.h/.hpp）的 NDK C-API（#include 头文件 + OH_* 符号）
- 动态加载边界：`import('@ohos.x')` 与 `dlopen("libxxx.z.so")` 字面量计入；变量/拼接形态静态不可解析，提示不计入
- @ohos.* 双源交叉判定：本地 SDK `@crossplatform` 标记 × 规则表；冲突归 unknown
- NDK C-API（source=ndk）：规则表单源判定
- @hms.* 默认归⑥业务决策，规则表已知时附 OH 替代建议
- 未展开的 @kit.*（闭源 kit）同归⑥业务决策（source=unknown 如实透传不虚计归属）
- 报告含单平台支持接口占比统计
- 产出 `scan-report.json`（schema_version=1，source 枚举 ohos/hms/ndk，供 F1/F3/F4 消费）与 `migration-advice.md`

**不做：** 工程结构转换（F1）、桥接生成（F3）、流程编排（F4）；源码改写；FA 模型仅提示不支持；ECMAScript 内置对象不扫。

## 使用流程

1. **SDK 确认（询问先行，必经）**：先向开发者询问本机 OH SDK 路径（附查找方法：DevEco 设置界面 SDK 页；默认 macOS `~/Library/OpenHarmony/Sdk`、Windows `%LOCALAPPDATA%\OpenHarmony\Sdk`；有效特征=版本级目录含 `ets/api/@ohos.*.d.ts`）。本地探测候选仅作参考附后（★含 `ets/kits` 在前）。**未经确认不产出判定（仅一个候选同样确认）**：
   - **TTY**：先问路径（粘贴目录 / 回车=浏览候选逐个 Y/n/r/q / q=中止）。agent pty 直跑会被自动应答——agent 场景请经 F4 编排器或直接 `--sdk-dir` 预设
   - **非 TTY（agent/CI）**：缺 `--sdk-dir` 与 `--yes` → **退出码 4 零产出**，打印查找方法+参考候选+重跑通道——agent 须呈报开发者，确认后以 `--sdk-dir <目录>` 重跑（编排器经 `--answer sdk=<目录>` 透传）；`--yes`=CI 授权，自动采纳推荐序第一（最新含 kits）并 stdout 大声打印所选路径/版本/kits 能力，`sdk.origin=auto:*` 可追溯
   - **`--sdk-dir` 多版本根**：枚举子版本按推荐序呈报确认（`--yes` 取第一）
   - **`--sdk-dir` 格式无效**：详因+查找方法反馈；TTY 当场重输×3=中止，非 TTY 退出码 2
   - **显式预设交叉核对**：给定后仍强制全量探测并打印 `[SDK 候选清单]` 到 stderr（★kits 标+"←本次使用"）；预设不在候选/无 kits 均警示并列更优候选
   - **SDK 质量硬门**：所选 SDK 无 `ets/kits` 且工程含 `@kit.*` 导入 → **退出码 4 阻断**，给含 kits 候选建议与 `--force-no-kits` 显式确认通道（编排器经 `--answer force_no_kits=1` 透传）
   - **未检出 SDK**：非 TTY 退出码 4 呈报查找方法与降级通道（不再自动降级），开发者确认接受单源降级后以 `--no-sdk` 显式降级重跑；TTY 询问路径（回车二次确认=单源降级）
   - scan-report.json `sdk` 段记 path/version/confirmed/origin（explicit/interactive/auto:*），advice 同步呈现确认状态
2. **执行扫描**：
   ```bash
   node scripts/scan.js <工程根> [--out <输出目录>] [--sdk-dir <OH SDK>] [--yes] [--no-sdk] [--rules <规则表>]
   ```
   产物缺省 `<工程根>/arkuix-scan-output`（锚定工程根）；重跑覆盖旧产物 TTY 询问、非 TTY 警示后继续，如需保留请 `--out` 指定新目录
3. **解读产物**：`scan-report.json`=inventory（含 ndk）+ adaptation 七桶（六分类+unknown）；`migration-advice.md` 按六分类组织，③/④标注"将由 F3 生成桥接"，含单平台占比统计节与动态加载提示

## 退出码

| 码 | 语义 |
|----|------|
| 0 | 成功（含 SDK 未检出单源降级的成功产出） |
| 1 | 内部错误（未预期异常） |
| 2 | 输入无效（根目录不存在/不可读、参数非法值） |
| 3 | 模型不支持（project_model=fa/unknown；产物照常写出） |
| 4 | 用户中止（SDK 目录确认环节中止/输入流结束） |

## 决策树

- 输入工程根目录
  - detectModel：AppScope/app.json5 在场（或构建三件套推定）→ stage；config.json 在场 → fa（退出码 3，产物照常写出仅提示不支持）；均无 → unknown（退出码 3）
  - SDK 判定源（只 stage 走）：
    - `--no-sdk` → 单源降级（报告显著标注）
    - `--sdk-dir` 给定：校验通过→交叉核对全量候选后采用；多版本根→展开子版本按推荐序呈报确认；格式无效→详因+查找方法反馈（TTY 重输×3=中止 / 非 TTY 码 2）
    - 无预设+`--yes`（CI 授权）→ 采纳推荐序第一（最新含 kits）
    - 无预设+非 TTY → 退出码 4 零产出（查找方法+参考候选指引，不代答）
    - 无预设+TTY → 先问路径（回车=浏览探测候选；无效路径当场纠正反馈）
  - 质量硬门：SDK 无 ets/kits 且工程含 @kit.* → 退出码 4（`--force-no-kits` 显式确认后放行）
  - 逐接口判定 classify：
    - source=ohos：双源交叉矩阵（见下节；docs-verified 实证条目双向优先）
    - source=hms → ⑥业务决策（规则表已知附替代建议）
    - source=ndk（C-API）→ 规则表单源（未覆盖→unknown，宁缺毋错）
    - @kit.* 未展开 → ⑥业务决策（闭源生态类比 @hms）

## 判定规则（双源交叉）

| SDK @crossplatform | 规则表 | 结论 |
|---|---|---|
| 支持标记 | ①/②（支持向） | 采规则表细分，reason 注双源一致 |
| 支持标记 | ③/④/⑤（不支持向） | 冲突→unknown（列两源结论） |
| 支持标记 | 未覆盖 | ①完整直用（单源：SDK） |
| 无标记 | ③/④/⑤ | 采规则表，双源一致 |
| 无标记 | ①/② | 冲突→unknown |
| 无标记 | 未覆盖 | unknown（判定依据未覆盖） |
| SDK 未检出 | 任意 | 规则表单源采信+报告显著标注 |

NDK C-API（source=ndk）：一律规则表单源判定（覆盖→分类；未覆盖→unknown）。@hms.*（闭源）不走自动分类，一律⑥业务决策，规则表已知时附建议替代项。

## 规则表演进

`rules/adaptation.json` 为版本化策展规则表（来源：OH SDK `@crossplatform` 标记 + arkui-x docs 仓 API 参考 + NDK sysroot 核验，来源版本记于表内 `meta` 字段）。符号级条目可携带 `platform:"android"|"ios"` 标注单平台支持（命中计入报告占比统计）。发现误判请更新规则表并递增 `meta.rules_version`。

**SDK 播种器**：`node scripts/curator-seed.js --sdk-dir <OH SDK>`——将 SDK 中"模块级整标"（整个 d.ts 声明跨平台）的模块自动播种为 full_direct 条目（人工策展条目优先、幂等可随 SDK 版本重跑）；符号级部分标记的模块只统计不播种（打印清单供人工策展）。

## 检查清单（验收自检）

上库/改动后逐条过：

```bash
node --test scripts/          # 全部单测
node benchmark/compare.js     # 端到端验收（fixture + mini-sdk + C-API + 3 次一致性 + demo 采样）
```

- [ ] 单测全绿；benchmark 全 PASS（含 3 次 ScanReport 逐字节一致）
- [ ] 桶互斥：任一接口只出现在一个桶（benchmark 总检项）
- [ ] SDK 确认门：非 TTY 无预设→退出码 4 零产出，stderr 含查找方法（DevEco）+参考候选+`--sdk-dir` 通道
- [ ] 质量硬门：无 kits SDK+@kit 工程→退出码 4；`--force-no-kits` 放行后 @kit 如实归⑥
- [ ] 显式 `--sdk-dir` 仍打印 `[SDK 候选清单]` 交叉核对；无 kits 预设有警示与更优候选建议
- [ ] 退出码契约 0~4 未被改动破坏
- [ ] 离线零网络：交付物无 net/http/fetch 引用（benchmark 静态扫描项）
- [ ] 修改 inventory/adaptation 产物结构时：`rules/schema.json` 与 F4 `rules/schemas/scan-report.schema.json` 同步
