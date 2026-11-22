---
name: arkuix-migration-orchestrator
description: 编排 ArkUI-X 迁移全流程：按 扫描(F2)→骨架(F1)→桥接(F3)→报告 顺序调度三 Skill，在关键决策点（骨架模式/配置迁移/new 选项/覆盖确认）与⑥业务决策项（@ohos.* 独有→删除/重新设计；@hms.*/闭源 kit→降级 OH 替代/降级平台原生桥接/自行实现/裁剪）引导开发者确认，管理 MigrationState（断点续跑/回滚，checkpoint 快照），汇总迁移报告（含源码改写工单/适用版本与环境要求+安全声明）。需端到端完成 OH 应用迁移 ArkUI-X 而非手工串联 Skill 时使用；三 Skill 各自仍可独立运行，编排器为可选增强，全程离线。
license: MIT
metadata:
  author: ArkUI-X 团队
  version: "1.0.0"
  created: "2026-10-09"
  updated: "2026-10-13"
  keywords: ["arkui-x", "orchestrator", "migration", "migration-state", "checkpoint", "pipeline", "cross-platform"]
compatibility: Requires Node.js >= 18. Fully offline; zero third-party dependencies.
---

# ArkUI-X 迁移编排器 Skill（F4）

按 扫描（F2）→ 骨架（F1）→ 桥接（F3）→ 报告 顺序调度同族三 Skill，提供全流程闭环。

## 使用

```bash
node scripts/orchestrate.js <工程根> [--stages scan,skeleton,bridge,report] [--out <输出目录>] \
  [--skill-dir <同族 Skill 根>] [--answer <决策ID>=<所选>] [--rollback <阶段>]
```

- 阶段选择：默认全流程；可传非空子集（执行序固定）；未选阶段 MigrationState/报告标"未执行"。
- 决策预设：`--answer <决策ID>=<所选>`，flag/内联两形态等价，可多次；非 TTY 缺预设=码 4 不代答。**Windows PowerShell**：含 `@` 的决策 ID 须单引号包裹；推荐 cmd.exe（PowerShell `2>&1` 包装 stderr 注入噪音）。
- **多模块 modify entry**：优先级=显式 `--modify-entry` > `--answer modify_entry=` > 自动推导（优先 entry 命名模块）；落账 MigrationState（source=explicit/preset/derived）并打印 `[modify-entry]` 行。
- **强制确认门（一律经开发者确认，不自作主张）**：
  - **SDK 判定源**：编排器不再从环境变量自动选定 SDK；未预设时 scan 由 F2 码 4 停止输出"查找方法+参考候选+重跑通道"——agent 须呈报确认后带 `--answer sdk=<目录>` 重跑（断点续跑续 scan）。scan 恒管道调度（pty 应答免疫），确认唯一通道=`--answer sdk=`。详见 AGENT 约束 1~4。
  - **F1 分类确认**：非 TTY 不自动注入 `--yes`——agent 须先呈报 F2 分类结果（逐桶块），确认后带 `ARKUIX_SCAN_YES=1` 重跑；未授权子 Skill 码 6→转码 4。
  - **⑥+unknown 裁决（skeleton/bridge 前强制门）**：scan 后、skeleton/bridge 前，逐项引导（TTY/非 TTY `--answer bd:`/`uk:`；缺预设=码 4 列全不代答）。⑥选项：降级为OH替代/降级为平台原生桥接/自行实现/裁剪——选"降级为平台原生桥接"移入④桶触达 F3 六件套；unknown 裁决选③/④同理移桶。**分类确认只确认"归类"，本门确认"怎么处理"——两独立步骤**。
  - `[scan] tty=…, sdk-preset=…` 调试行输出至 stderr。
- **skeleton 环境变量（F1 侧，与 SDK 源无关）**：`ARKUIX_X_SDK_DIR`/`ARKUIX_SDK_DIR`（形态路由防误用）仅用于 buildArkTS 占位符与 local.properties 推导。**TTY 交互模式**：子 Skill 确认关口直达终端由用户应答；非 TTY 以参数注入替代（`--sdk-dir`/`--yes`）。
- `--scaffold-from [目录]`：恒透传 skeleton（无值→内置归档物化；有值→指定归档）。`--strict-crossplatform`：透传 F1 关降警告开关（默认注入 `buildOption.ignoreCrossPlatform`，11706007 降警告；运行时仍需守卫/桥接）。
- **new 模式双门**：`--answer migrate_configs=yes|no`（yes=F1 白名单合并+双向校验；no=维持模板）与 `--answer compile_sdk=<版本>`（版本键 24/26.0.0…或全形态；清单=F1 ON 表 10~24/26.0.0；推荐最高 26.0.0）。任一缺预设→F1 码 6→转码 4+专属指引。compile_sdk 选定后 F1 物化做六元组替换（runtimeOS 恒 OpenHarmony），落账 `platform_baseline.openharmony`。
- **bridge_codegen 决策**：bridge 产出六件套后询问 `skip`/`proceed`；非 TTY 默认 skip（不阻断）；`--answer bridge_codegen=proceed`→编排器输出代填指引（F3 adaptation-guide §二B，含适用版本基线与"先升级环境"提示）。
- **适用版本与环境要求（报告第七段）**：工程基线取 F1 `platform_baseline`；逐接口以 F3 `bridge-artifact` 的 `min_android/min_ios` 优先；恒附"使用有问题先确认设备与环境不低于上述版本并升级 ArkUI-X SDK/Android SDK/Xcode"提示。
- **F3 产物自检透传**：`audit.deficient` 非空（硬残缺）时 F4 报告"生成降级"段逐项透出（含 action）；**agent 标准动作：读对应文件与源工程 locations 补全后重跑 bridge（幂等），再编译验证**。
- 断点续跑/回滚：中断后先校验已产出完整性（契约 Schema）从断点续跑（已通过不重跑）；`--rollback <阶段>` 恢复至该阶段 checkpoint 快照，续跑从目标阶段开始。
- 退出码：`0` 成功/`1` 内部/`2` 输入无效/`3` 阶段前置缺失/`4` 用户中止/`5` 子 Skill 失败。
- **编译验证警示（ace 外部缺陷）**：`ace build apk` 编译失败时仍可能码 0——须双重判定：①确认 APK 产物实际产出；②用 `node scripts/parse-build-log.js <build.log> [--json]` 解析错误清单（剥 ANSI+跨行还原+按文件聚类）。

## 决策树

- 输入：工程根 `[--stages 子集] [--answer 预设...] [--rollback 阶段]`
  - StateManager 加载/新建→回滚校验（无 checkpoint→码 4）→阶段计划/前置校验（缺上游→码 3）
  - scan（恒管道，pty 应答免疫）：`--answer sdk=<目录>`→注入 `--sdk-dir`+交叉核对；无预设→F2 码 4→转码 4 待确认
  - skeleton/bridge 前置强制门（ensureSixDecided/ensureUnknownDecided）：⑥+unknown 逐项（TTY/非 TTY `--answer bd:`/`uk:`；缺预设→码 4 列全不代答）；⑥选"降级为平台原生桥接"→移桶④触达 F3；裁决回写 ScanReport（原地原子改写，全链事实一致）
    - （注记：uk 裁决选⑤的 @ohos.* 项随后再入⑥降出门——同符号两次独立确认，属设计行为非重复询问）
  - skeleton_mode（modify 默认/new）：new→migrate_configs 门→compile_sdk 门（推荐最高 26.0.0/源工程版本）：任一缺预设→F1 码 6→转码 4+专属指引
  - skeleton 执行（非 TTY 需 `ARKUIX_SCAN_YES=1`；`--scaffold-from` 恒透传）→完成后源码改写（rewriter：import 注释+stub+kit 拆分+TODO）+落账
  - bridge 执行→wireBridgeToProject 自动落位（commons HAR 化/注册/接线）+audit 透传
  - bridge_codegen（可选不阻断）：非 TTY 缺省 skip；proceed→代填指引
  - report 合成（五段+工单+适用版本与环境要求）→未消费 `--answer` key 告警→done
- 子退出码转译：scan 码 4/任一阶段码 6→编排器码 4+待确认指引；其余非零→码 5（stderr 记失败阶段与子退出码）。

## AGENT 行为约束（强制——违反则迁移结果不可信）

1. **第一次跑 scan 禁止带 `--answer sdk=`**——先裸跑（F2 输出查找方法+参考候选），码 4 后按指引呈报。
2. **F2 码 4 后必须将"查找方法+参考候选"完整转述开发者**（含 DevEco SDK 页入口、常见默认位置、有效目录特征；候选列全路径/API 版本/有无 kits，含 ★ 推荐项），确认后才能带 `--answer sdk=<目录>` 重跑。
3. **即使开发者口头告知 SDK 路径，仍先裸跑一次交叉验证**（显式预设时 F2 也全量探测打印 `[SDK 候选清单]`——本机可能有含 kits 的更新版本）。
4. **SDK 无 `ets/kits` 时必须将后果（@kit.* 全部误归⑥）告知开发者后再继续**——F2 质量硬门码 4 阻断，`--force-no-kits` 只能在开发者显式确认后果后使用。
5. **⑥业务决策与 unknown 裁决是骨架生成前的独立强制步骤，不得跳过、不得代答**。完成 SDK 与 F1 分类确认后**不得直接进入骨架模式询问**——须先逐项过 `adaptation.business_decision`（⑥）与 `adaptation.unknown` 处理方式（`ensureSixDecided`/`ensureUnknownDecided` 把门，非 TTY 缺预设=码 4 列全）。
6. **⑥项呈报逐条含**：模块::符号、occurrences、locations 摘要、处理方式（降级为OH替代/降级为平台原生桥接/自行实现/裁剪）及语义差异（OH替代=跨平台层找等价 API 无桥接；平台原生桥接=移④桶由 F3 生成六件套经 Bridge 调原生）——开发者选，agent 只转述。
7. **unknown 项呈报逐条含**：模块::符号、位置、裁决（equivalent_bridge/degraded_bridge/platform_trim/keep_unknown）与移桶后果（选③/④=移桶触发 F3 六件套；keep_unknown=搁置入未解决段）。
8. **非 TTY 缺预设 exit 4 后，必须将待答 `--answer` 清单逐条转述开发者**，按选择带 `--answer bd:...=<所选>`/`uk:...=<所选>` 重跑——**禁止 agent 自行替开发者选预设**（与 SDK 同款不代答；预设=预先确认，TTY 下带了也不再问）。
9. **new 模式 scaffold 落点须告知开发者**：骨架开始前打印 `scaffold 落点：<路径>`（默认 `<工程根>/arkuix-orchestrate/`），agent 须呈报确认——如需更改以 `--out <目录>` 指定重跑。modify 产物藏 `.arkui-x/migration/` 无此需求。
10. **已知将用 new 模式时，第一次裸跑 scan 可带 `--answer skeleton_mode=new`**（仅预设骨架模式对齐 defaultOut——不影响 SDK 询问先行门，sdk 仍裸跑；避免 modify/new outDir 不一致致 scan 重跑）。

## 检查清单（验收自检）

```bash
npm test                      # 全部单测（mock-skill 替身）
npm run benchmark             # 端到端验收（fixture + mock 三 Skill + 3 次一致性）
npm run guard                 # = 上述两项无条件全跑并汇总
```

- [ ] 单测全绿；benchmark 全 PASS（mock 三次 `migration-report.md` 逐字节一致）
- [ ] 决策不代答：非 TTY 缺 ⑥/unknown/sdk/migrate_configs 预设→码 4 且待答项一次列全
- [ ] 转译规则：scan 码 4→"待确认 SDK"；skeleton 码 6→"待确认（分类/计划）"+（new 缺 migrate_configs 时）专属指引
- [ ] 断点续跑：done 不重跑、决策保留免重询；损坏产物自动重跑该阶段；子集轮 skipped 可解锁
- [ ] 裁决回写：uk→③④⑤、⑥→降级平台原生桥接移④，reason 含溯源且幂等
- [ ] 源码改写：import 注释+stub+kit 拆分+调用点 TODO；stub 成员级合并（重跑不缺成员）
- [ ] bridge 落位：commons HAR（Index.ets 恒生成）+build-profile/oh-package 注册+BridgeRegistry/ViewController 接线
- [ ] 报告段齐备：五段+源码改写工单+适用版本与环境要求（基线+逐接口标注+更新环境提示）
- [ ] 改 MigrationState/产物结构时：`rules/migration-state.schema.json` 与 `rules/schemas/` 三副本同步（VERSIONS.json）

## 约束

- 全程离线零网络；子进程白名单=三 Skill CLI+文件操作。
- 编排器只调度不实现：能力由 F2/F1/F3 交付；⑥与关键决策须开发者确认（不代答）。
- 多实例同输出目录不支持（MigrationState 单写者）；产物契约只读消费。
