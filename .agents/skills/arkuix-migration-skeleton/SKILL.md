---
name: arkuix-migration-skeleton
description: 为 OpenHarmony Stage 工程生成 ArkUI-X 跨平台骨架（Android/iOS 壳+共享 ArkTS）。modify（内置归档自修改，零 ace 依赖）/ new（归档物化或 ace create）双模式；FA 拒绝；检测编译环境。搭建跨平台工程结构时使用。
license: MIT
metadata:
  author: ArkUI-X 团队
  version: "1.2.0"
  created: "2026-09-10"
  updated: "2026-10-13"
  keywords: ["arkui-x", "skeleton", "migration", "cross-platform"]
compatibility: Node.js >= 18, zero deps, offline. modify 归档路径无需 ace；--ace-modify/new 需 ArkUI-X SDK。
---

# ArkUI-X 迁移骨架生成 Skill（F1）

把 OpenHarmony Stage 工程改造/迁移为 ArkUI-X 跨平台工程（Android 壳+iOS 壳+共享 ArkTS）。

## 能力与边界

**做：**
- 消费 F2 ScanReport 的 project_model：fa→提示不支持停止（零写）；缺失/unknown→引导先跑 F2
- **平台选项**：骨架生成前询问——双平台（默认）/仅 Android/仅 iOS；modify 注入对应平台壳（未选不注入）
- **modify 模式（默认=归档自修改）**：校验工程完整性（build-profile/oh-package/hvigorfile.ts 三件套）后，经计划改动清单确认，从内置归档确定性注入：①`.arkui-x/` 平台壳（按 platform 裁剪）②各模块 hvigorfile.ts 改写（根/appTasks→`AppTasksForArkUIX`、hap→`HapTasks`、hsp→`HspTasks`；**har 模块原样保留**——插件无 har 任务名，ace modify 同样不改）③根 hvigor/hvigor-config.json5 注入 arkui-x 插件（modelVersion 形态；旧 hvigorVersion 形态跳过并警示）④buildArkTS 三件占位符注入（project_path 恒替换；SDK 检出才替换）⑤local.properties 生成（nodejs.dir/arkui-x.dir/sdk.dir，在场不覆盖）。**零 ace 依赖、跨平台一致**（Windows 非 TTY 可用）；`--ace-modify` 显式走官方工具路径（此路径才有 SDK API 22+ 门槛，退出码 4）
- **new 模式**：`--scaffold-from`（缺省内置归档）物化跨平台 scaffold（零交互确定性），或经 `ace create -t app` 新建后把源工程各模块源码**原样搬移**（不改写，改写属 F3）到共享 ArkTS 目录；输出目录非空先确认（跳过/覆盖/中止）
- 环境检测（Android SDK/Gradle/JDK、Xcode/CocoaPods、ArkUI-X SDK 检出与版本）：只决定验证辅助与报告标注，**不阻断骨架生成**（例外：`--ace-modify` 且 SDK < API 22→拒绝，退出码 4；归档 modify 不受此门槛）
- **new 模式 Compile SDK 版本门**：`--compile-sdk <版本>`——new 模式必答（TTY 询问，推荐序：★最高 26.0.0 / ◆源工程版本——从源 build-profile 反查；**非 TTY 缺参=退出码 6，不代答**；未收录/modify 误用=退出码 2）。值=版本键（24/26.0.0…）或全形态（6.1.1(24)）。支持清单=固化版本表 `rules/sdk-versions.json`（ON 表策展：API 10~24 + 26.0.0 共 16 键，无 25）。选定后物化做**版本六元组替换**（三元组保留源值+越界钳制：compileSdkVersion=所选；compatible/targetSdkVersion 保留源值，仅破坏 compatible<=target<=compile 关系时钳制；源缺 target=compile；不可解析保守取 compile）：build-profile compile/target/compatibleSdkVersion（OH 形态：apiLevel<26 写数字如 24，仅 26.0.0 写字符串）、hvigor-config modelVersion+插件版本、根 oh-package modelVersion；**runtimeOS 与源同步——源显式 HarmonyOS 形态时保留并改写全形态版本串（如 5.0.5(17)），缺省 OH 形态**；Android/iOS 壳不随 OH API 变。modify 不适用（保留源版本；hvigor 插件版本按源版本查表对齐）
- **new 模式配置迁移门**：`--migrate-configs <yes|no>`——new 模式必答（TTY 默认 no；**非 TTY 缺参=退出码 6，不代答**；非法值/modify 误用=退出码 2）。yes=白名单合并源配置进 scaffold（根 build-profile `app.signingConfigs` 整组替换 + `app.products` 按产品名深合并——**版本键恒 scaffold 版防回退**；根与 entry oh-package `dependencies/devDependencies/overrides` 合并（源版本覆盖同名、scaffold 独有键保留）；AppScope/app.json5 标量源覆盖（`bundleName` 保留 scaffold 定制版）；code-linter/.gitignore/obfuscation-rules 无冲突拷贝；**hvigorfile.ts/hvigor-config/entry build-profile 恒保留模板并逐条写明原因**）。含**遗漏/多改双向校验**（合并前后 diff：变更路径⊆白名单、不变量恒定、应迁键落齐），失败自动回滚并以退出码 1 失败；产物 `config_migration` 落账
- **平台版本基线**：生成后实测提取 `.arkui-x/android/app/build.gradle` 的 min/target/compileSdkVersion 与 iOS pbxproj `IPHONEOS_DEPLOYMENT_TARGET` → `skeleton-result.json` 可选字段 `platform_baseline`（F4 消费；未提取不输出）
- 产出 `skeleton-result.json`（schema_version=1：mode+platform+壳字段+environment；壳路径相对——modify 相对工程根、new 相对输出目录）+骨架报告+编译验证辅助（命令文本与脚本，不直接执行）

**不做：** 接口适配分析（F2）、桥接代码生成与 @ohos.* 改写（F3）、流程编排（F4）、直接执行编译、自动回滚（就地改造无事务性，以工程版本控制为恢复手段）。

## 使用流程

1. **前置**：先跑 F2 扫描获得 ScanReport。
2. **执行**：
   ```bash
   node scripts/skeleton.js <工程根> --scan-report <F2 scan-report.json> \
     [--mode modify|new] [--platform both|android|ios] [--out <输出目录>] \
     [--confirm-overwrite skip|overwrite|abort] [--yes] [--ace-bin <ace 路径>] \
     [--ace-modify] [--scaffold-from [目录]] [--migrate-configs <yes|no>] \
     [--compile-sdk <版本>] [--timeout-ms <毫秒>]
   ```
   - 交互定序：模式→平台→（new）配置迁移→（new）Compile SDK→（new）输出目录非空覆盖确认→生成
   - `--mode` 未指定交互引导（默认建议 modify）；非交互须显式（缺失→码 2）
   - `--platform` 未指定交互引导（默认 both）；非交互缺省 both；非法→码 2
   - `--confirm-overwrite` 输出目录非空确认非交互等价（skip/overwrite/abort）；非 TTY 缺省 abort
   - `--yes` 跳过 modify 计划清单确认（非 TTY 无则退出码 6）——归档/ace 两路径同守卫
   - `--ace-modify` modify 走 ace 工具路径（默认归档自修改；与 `--scaffold-from` 互斥）
   - `--ace-bin` ace 命令路径（默认 PATH 中的 ace）；buildArkTS 占位符与 local.properties 推导源
   - `--timeout-ms` ace 子进程超时（**默认 300000ms/5 分钟**；`ARKUIX_ACE_TIMEOUT_MS` 可覆盖：显式参数>环境变量>默认）
3. **产物**：`skeleton-result.json` + `migration-skeleton-report.md` +（环境就绪时）`verification/` 编译命令与脚本（结果留白，开发者执行后确认）。

## 退出码

| 码 | 语义 |
|----|------|
| 0 | 完成/产出；或用户跳过（stdout 明示"已跳过"） |
| 1 | 内部错误 |
| 2 | 输入无效（根目录不存在/不可读、参数非法、工程缺三件套） |
| 3 | 模型拒绝（project_model=fa；ScanReport 缺失/不可解析/unknown） |
| 4 | 环境不满足（`--ace-modify` 且 SDK < API 22；归档 modify 不受此门槛） |
| 5 | 工具失败（ace 非零退出或超时） |
| 6 | 用户中止（交互无效×3 或流结束、覆盖 abort、计划确认无 --yes、new 缺 --migrate-configs） |

## 决策树

- 输入：工程根 + F2 ScanReport
  - 模型门：stage→放行；fa→退出码 3（零写）；缺失/不可解析/unknown→退出码 3（引导先跑 F2，零写）
  - F2 分类逐桶确认（风险序 unknown→①；--yes 跳过；非 TTY 未确认→退出码 6 零产出+呈报块）
  - mode：
    - modify（默认建议）：归档自修改（默认，零 ace）注入 .arkui-x 壳/hvigorfile 改写/hvigor-config 插件/buildArkTS 占位/local.properties/多模块装配+ignoreCrossPlatform；--ace-modify（工具路径）SDK < API 22→退出码 4（幂等重跑豁免），非 TTY 多模块管道预喂/--modify-entry，崩溃截获给 A/B/C 指引
    - new：配置迁移门（--migrate-configs yes|no；非 TTY 缺参=码 6）→ Compile SDK 门（--compile-sdk；非 TTY 缺参=码 6；推荐最高/源工程版本）；--scaffold-from [目录]（默认内置归档 26.0.0，零交互；所选≠26.0.0 时物化做六元组替换）/无归档→ace create（TTY 透传 6 题预告；非 TTY+真 ace 短路给手动指引）
  - platform（both 默认/android/ios）→壳按平台裁剪
  -（new）输出目录非空确认（skip=码 0/overwrite/abort=码 6）
  -（new）源码迁入+哈希校验+registerModules+assembleModules（har 不入 moduleLists）
  -（new + migrate-configs=yes）配置白名单合并+遗漏/多改双向校验（失败回滚+码 1）
  - 产出：skeleton-result.json（含 platform_baseline+config_migration+ace_warnings）+报告+验证辅助

## 关键行为

- **modify 失败**（非零退出/**超时**/产物断言不过）：输出失败原因（含实际超时阈值）+实际改动文件清单+"建议改用 new 模式"，不静默继续
- **FA/模型未知**：提示并停止，工程零新增/零变更
- **源码迁入完整性**：new 迁入后做文件集合+内容哈希校验
- **确定性**：同输入同产物（排除时间戳类字段）

## 已知限制与实测行为

- **ace create 交互**：TTY 透传前打印预告+建议答案；非 TTY+真 ace 给手动指引（A.命令 B.重跑跳过 C.TTY），不试管道；非 TTY+mock 管道预喂。Compile SDK=input 文本（输菜单编号如 16=26.0.0）。CI 推荐：手动 create 一次后以 scaffold 目录复制替代
- **scaffold 在场**自动跳过 ace create；需重建清理目录后重跑
- **modify 幂等**：`.arkui-x/arkui-x-config.json5` 在场跳过注入；hvigorfile 含 plugin 跳过
- **多模块 --ace-modify**：非 TTY 管道预喂 [平台,entry]；Windows+ace 26.0.0 管道静默失败→回退手动或用默认归档路径。崩溃 ERR_USE_AFTER_CLOSE 替换为指引
- **new 多模块布局**：按 build-profile modules 逐模块迁入；entry→合入 scaffold entry/；业务名→`<outDir>/<模块名>/`；零迁入=码 2
- **build-profile** 宽松 JSON5 解析（无引号键/注释/尾逗号）；modify 改动清单=全工程哈希 diff
- **ace WARN 沉淀**至 `ace_warnings`+报告段；TTY 透传无法捕获时静态复核兜底
- **F2 分类逐桶确认**：模型门后、mode 询问前，按风险序逐桶确认（y/a/n）；非 TTY 未确认=码 6+呈报块；agent 须完整转述后再 --yes
- **Windows ace 启动**：.js mock 经 node；win32 ace.cmd 经 shell:true；ENOENT 合成
- 失败出口附 A/B/C 指引；部分产物保留供排查
- **归档物化（推荐 CI）**：`--scaffold-from [目录]`（默认内置 scaffold-26.0.0）——零交互/零 ace/版本确定性。仅替换项目名/bundleName/java 包/注入 buildArkTS/按 platform 裁剪。`--compile-sdk` 按固化版本表做六元组替换
- **ignoreCrossPlatform**：默认注入降 11706007 为警告（编译解锁）；运行时仍不可用需 canIUse/Bridge 接线；`--strict-crossplatform` 恢复严格
- **多模块编译前必办**：ace build apk 只在工程根 ohpm install；file: 依赖需逐模块 install
- **归档扩展边界**：iOS 签名保留模板默认；其他 SDK 版本已支持（--compile-sdk）；runtimeOS/Framework/library 需扩展 make-scaffold-archive
- **hvigor 布局**：不含 hvigor-wrapper.js/hvigorw（ace API≥12 删三件）；hvigorw 自举=跑一次 ace build 或 DevEco 打开；config=modelVersion+arkui-x-plugin
- **local.properties**：nodejs.dir/arkui-x.dir(SDK 根/licenses 层)/sdk.dir(OH SDK 根)；在场不覆盖
- **ARKUIX_SDK_DIR 双语义路由**：本 Skill 只接受 ArkUI-X SDK 形态（含 arkui-x/），OH SDK 形态不误用
- **多模块装配**：modify 缺省按工程真实模块回写 modules+moduleLists（har 不入列）
- **Windows hvigorw**：旧 SDK 管理模式被 hvigor 6.x 拒绝（00308018）；pnpm 10 可能需 junction node_modules

## 检查清单（验收自检）

```bash
npm run guard                 # = 单测 + 端到端验收（一键自测）
node --test scripts/          # 全部单测（mock-ace 替身）
node benchmark/compare.js     # 端到端验收（fixture + mock-ace + 平台三取值 + 退出码全映射 + 3 次一致性）
```

- [ ] 单测全绿；benchmark 全 PASS（含 3 次一致性）
- [ ] 幂等：已 modify 工程重跑码 0 不二次注入；`.arkui-x/` 在场跳过 create/modify
- [ ] 零写中止：模型拒绝/分类未确认/配置迁移缺参/覆盖 abort 各路径目录零变更
- [ ] 配置迁移：yes 合并后版本键不变量、应迁键落齐、校验失败回滚；非 TTY 缺 --migrate-configs=码 6；非法值/modify 误用=码 2
- [ ] platform_baseline：modify/new 均实测提取（归档 minSdk 26/compileSdk 33/iOS 10.0）；未选平台侧省略；new+--compile-sdk 时 OH 侧与所选版本一致
- [ ] Compile SDK 门：非 TTY 缺 --compile-sdk=码 6；未收录版本=码 2+清单；选 24 产物六元组=ON 表值，runtimeOS 恒 OpenHarmony
- [ ] 归档物化确定性：compileSdkVersion 26.0.0 断言、bundleName/java 包重组、buildArkTS 占位符
- [ ] 退出码契约 0~6 未破坏
- [ ] 改 skeleton-result 结构时：`rules/schema.json`（additionalProperties:false）与 F4 `rules/schemas/skeleton-result.schema.json` 同步

自测可在 macOS/Linux/Windows 全平台运行：mock ace 统一以 `.js` 后缀经 node 启动；报告/清单相对路径标识符归一为 `/` 分隔；win32 下 local.properties 按 ace 转义规则（`\`→`\\`、`:`→`\:`）断言。
