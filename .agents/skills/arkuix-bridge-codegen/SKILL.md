---
name: arkuix-bridge-codegen
description: 消费 F2 ScanReport 的 ③/④ 分类，为每个需桥接接口生成六件套（①Interface 契约 ②Local HarmonyOS class ③ArkUIX 桥接 class ④Android BridgePlugin ⑤iOS BridgePlugin ⑥Impl 平台分发器——一码三平台）与 BridgeArtifact(JSON)+报告(MD)。OH 应用迁移 ArkUI-X 完成扫描后需生成跨平台桥接骨架时使用；只生成骨架/胶水，平台业务以 TODO 占位待补，增量再生成不覆盖手改区。
license: MIT
metadata:
  author: ArkUI-X 团队
  version: "1.1.0"
  created: "2026-10-09"
  updated: "2026-10-13"
  keywords: ["arkui-x", "bridge-codegen", "cross-platform", "migration", "bridgeplugin", "six-piece", "bridge-artifact"]
compatibility: Requires Node.js >= 18. Fully offline; zero third-party dependencies.
---

# ArkUI-X 跨平台桥接代码生成 Skill（F3）

消费 F2 ScanReport 的 ③/④ 分类，为每个需桥接接口生成标准**六件套**（对齐 docs 一码三平台范式）：

| # | 件 | 位置（相对输出目录） | 职责 |
|---|-----|---------------------|------|
| ① | Interface.ets | `commons/<module>/interface/{Name}Interface.ets` | 统一契约（方法签名），唯一真相源 |
| ② | Local.ets | `commons/<module>/utils/{Name}Local.ets` | class 实现①：HarmonyOS 直调 @ohos.*（方法体=源工程原语句迁移） |
| ③ | ArkUIX.ets | `commons/<module>/utils/{Name}ArkUIX.ets` | class 实现①：@arkui-x.bridge 转发原生侧（单例+createBridge） |
| ④ | Android Bridge | `.arkui-x/android/.../bridge/Bridge{Name}.java` | BridgePlugin，调映射的 Android API |
| ⑤ | iOS Bridge | `.arkui-x/ios/.../BridgeSrc/Bridge{Name}.h/.m` | BridgePlugin，调映射的 iOS API |
| ⑥ | Impl.ets | `commons/<module>/impl/{Name}Impl.ets` | 平台分发器：`getInterface()`→Android/iOS 返回③，HarmonyOS 返回②——业务码零平台感知 |

另有工程级件 `commons/utils/PlatformInfo.ets`（@ohos.deviceInfo.osFullName 平台判断，⑥共用，每工程一份，在场不覆盖）。

**一码三平台语义**：业务调用统一 `XxxImpl.getInterface().method(...)`——ArkUI-X 工程（Android/iOS）走③桥接，HarmonyOS/OH 工程走②Local 直调。同一份 commons 可被 ArkUI-X scaffold 与原 OH 工程同时消费。

## 使用

```bash
node scripts/bridge.js <源工程根> --scan-report <ScanReport 路径> [--out <输出目录>]
```

- 退出码：`0` 成功（含③④均空的良性完成、单接口 Local 读取失败的部分成功）；`1` 内部错误；`2` 输入无效；`3` ScanReport 格式异常。
- 全程离线零网络；源工程只读；产物落输出目录（默认 `./arkuix-bridge/`）。

## 决策树

- 输入：源工程根 + F2 ScanReport
  - loadScanReport 契约校验：缺 adaptation.③④ → FormatError → 退出码 3（零产物）
  - ③④ 均空 → 良性完成（退出码 0，`artifacts: []`）
  - 逐接口（同 module::symbol 去重；`*include*` 头跳过披露）：
    - ②Local 提取（source=ohos→locations 全收割：锚定行噪声重锚/括号平衡/兄弟语句吸收/外围作用域收割；空壳/定位失败→status=failed 占位体+审计 local-placeholder；source=ndk/hms→显式 failed，C++ 宏/闭源不迁 .ets）
    - ①契约合成（四源优先级：SDK d.ts 声明面 > Local 调用面 > locations 调用面 > 单方法兜底）
    - 渲染六件套（①②③⑥+④⑤）：
      - ③equivalent_bridge：查 native-api-map（符号级→模块通配）；命中→④⑤围栏带等价原生 API 注释（含可选 min_android/min_ios）；未命中→unmapped_native_apis 呈报（不猜测）
      - ④degraded_bridge → 围栏带降级说明占位
      - ②Local 可编译性：自含→live 平铺；this/未解析标识符→`// ORIG` 注释化保编译
    - 增量合并：④⑤围栏内手改区保留；②Local 已存在整文件保留
    - audit 自检落 bridge-artifact（deficient=必补→agent 按 action 补全后重跑，幂等不改退出码）

## 关键语义

- **①Interface 唯一真相源**：②③④⑤ 方法签名均由①派生；签名不匹配项列入报告（`rules/type-map.json` 三端类型映射，歧义项标"需人工"）。
- **契约派生多源合并**：方法面=②Local 迁移内容全部 `symbol.method(` 调用 ∪ locations 指向源文件调用面（同方法名取最大实参面）；参数类型按实参字面量推导（number/boolean/string；回调/对象/数组→ESObject 走"需人工"通道）；返回统一 `Promise<Bridge.ResultValue>`（③callMethod 契约形态，非简化遗漏）。
- **②Local 语句提取**：括号深度平衡（嵌套回调内 `return;` 不截断；字符串/注释/模板串内括号不计深度）；锚定行是 `// [MIG]`/import/空行/纯注释/纯闭合括号行时按 symbol 双向重锚定调用行（行号漂移免疫）；同符号连续兄弟语句吸收（sensor.on+off 全迁）；语句按 `.方法名(` 分派到类方法体，未命中进类尾参考块。
- **③/④ 差异策略**：③查 `rules/native-api-map.json`（模块通识别 @ohos.multimedia.camera→camera2/AVFoundation）映射等价原生 API（未知项列入 `unmapped_native_apis` 待人工，不猜测）；④对不支持方法留降级占位。条目可选 `min_android`/`min_ios`（如 "API 21+"/"iOS 9+"）标映射原生 API 最低系统版本——在场时④⑤围栏渲染 `// 最低版本要求：…` 注释并透传 bridge-artifact（F4 消费）；未标注条目适用 F1 `platform_baseline`。策展时经 javap/官方文档验证后填入（宁缺毋错）。
- **TODO 占位标注**：④⑤ 业务逻辑区以含 接口名+平台+③④分类 三要素的 TODO 注解标注，置于 `ARKUIX-BRIDGE-HANDOFF BEGIN/END` 围栏内。
- **增量再生成**：①③④⑤ 围栏外骨架区幂等更新；围栏内手改区保留；②Local 已存在则保留开发者版本（如需重新迁移先删除）。
- **BridgeArtifact**：每条目含 `symbol` 与 `files` 五件路径（local_status=failed 亦带——供 F4/人工定位）。
- **产物自检兜底**：六件套落盘后做确定性结构自检（六件齐全/①契约方法面/②Local 括号平衡·空壳·占位/③createBridge·callMethod/④class extends BridgePlugin/⑤@interface·@implementation/⑥Impl·getInterface 分发/工程级 PlatformInfo），结果入 `bridge-artifact.json` 的 `audit`{checked, **deficient**（硬残缺必补）, **suggestions**（建议级：contract-thin 单方法兜底契约）} 与报告"产物自检"段（每项含 file/kind/detail/**action**）。**agent 标准动作：`audit.deficient` 非空时逐项读 action 指向文件与源工程 locations，补全围栏内实现/契约/②Local——补全后重跑幂等不覆盖手改，再走编译验证（ace build apk 产物判定）；suggestions 为可选增强同法处理**。自检不改退出码（残缺=待补信号；空③④良性完成不产 audit）。

## 产物

- `bridge-artifact.json`：BridgeArtifact（契约，schema_version=1；F4 编排消费）。
- `bridge-report.md`：桥接生成报告（五件套清单/签名不匹配/unmapped 待确认/Local 失败明细）。

> **临场适配判断（agent 可选参照）**：`unmapped_native_apis` 非空或④⑤围栏需适配方案时，可参照 `docs/adaptation-guide.md`（四步判断框架+证据校验红线+呈报表）给适配建议，由开发者逐项拍板后落地：默认写围栏注释；开发者明确要求时可代填围栏内实现——决策生成→编译自检→diff 呈报确认。Skill 本体不因此变行为。
> **六件套范式模版（agent 强参照）**：生成/补全/代填/审查桥接代码前先读 `docs/six-piece-paradigm.md`（各件金标准形态+命名规则+跨三端一致性清单+不变式）——偏离范式的产物审查不通过（自检+模版双闸）。

## 检查清单（验收自检）

```bash
npm test                      # 全部单测
npm run benchmark             # 端到端验收（fixture + 3 次一致性）
npm run guard                 # = 上述两项无条件全跑并汇总
```

- [ ] 单测全绿；benchmark 全 PASS（含 3 次产物一致性）
- [ ] 六件套路径约定：①`commons/<module>/interface/` ②③`utils/` ⑥`impl/`、④`.arkui-x/android/.../bridge/`、⑤`.arkui-x/ios/.../BridgeSrc/`、工程级 `PlatformInfo.ets`（在场不覆盖）
- [ ] 围栏协议：④`ARKUIX-BRIDGE-HANDOFF BEGIN/END`、⑤`#pragma mark` 成对；增量围栏内逐字节保留；②Local 已存在不覆盖
- [ ] audit 语义：local-unbalanced/local-shell/local-placeholder/interface-thin 命中时 deficient/action 指引在场；不改退出码
- [ ] unmapped 不猜测：未收录项进 `unmapped_native_apis`；③映射命中围栏含等价 API 注释
- [ ] ③类契约=d.ts 声明面优先；④⑤ 按契约全方法渲染（方法名与③callMethod 严格一致）
- [ ] 改 bridge-artifact 结构时：`rules/schema.json` 与 F4 `rules/schemas/bridge-artifact.schema.json` 同步；native-api-map 改动递增 `meta.rules_version`

## 已知限制（如实讲）

- **②Local 方法体接线深度**：**类恒可编译**——live 代码仅含 `@ohos.*` 导入与自含 const 内联；引用 `this.X` 成员或未解析标识符的语句以 `// ORIG:` 注释化保留（含接线指引：形参替换实参/赋值改 return/补 import），模块名导入（sample_common 等项目 HAR）同样注释化（需在 oh-package 声明依赖后取消）。**参数/返回值接线**仍需人工/agent 补——自检（local-unbalanced/contract-thin/contract-incomplete）兜底标记。
- **方法返回类型统一 Promise**：③转发件走 Bridge callMethod（Promise 形态），①契约即此形态——非类型缺失；void/同步语义在④⑤平台侧消化。
