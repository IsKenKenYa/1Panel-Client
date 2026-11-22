# 隔空传送 Skill 验收清单

供人验收使用。各 `test-case-*.md` 只写本场景重点，通用项引用本文件。

**不算本 Skill 自动通过**（只进完成报告人工清单）：真机一抓一放、设备隔空传送开关、手动签名、域名托管。

## 行为与交付标准（S1–S17）

| ID | 标准 |
|---|---|
| S1 | 按「核验 → 确认 → 改码 → 检查 → 报告」走；缺项靠引导补，不靠多轮试错 |
| S2 | `targetSdkVersion` &lt; `6.0.0(20)` 时警告并停止改码；`compatibleSdkVersion` 可更低，运行时 `canIUse` 降级 |
| S3 | 先确认分享类型与数据来源；未答清不修改代码 |
| S4 | 文件侧落实 `uri` / `utd`；不用空值或未转换的裸 path |
| S5 | 补另一种类型时不重复注册监听、不新建第二套管理类 |
| S6 | 完成报告含人工清单；未就绪不声称已可拉起或联调完成 |
| S7 | 手势回调不做下载或重 IO；可分享数据在监听前备好 |
| S8 | 问答按类型隔离：仅文件不问链接项，仅链接不问文件项 |
| S9 | 按类型使用对应实现（`assets/file` / `link` / `both`），不混多余分支 |
| S10 | 可分享页显示时注册、离开时注销监听 |
| S11 | 管理类与业务类放在开发者确认的位置；不另起工程、不替换现有架构 |
| S12 | 须先打开本 Skill 对应 `assets/` 模板；读不到则中止，禁止凭记忆重写 |
| S13 | 链接：云侧配置不写入工程；确认后才接入口跳转 |
| S14 | 文件：不臆造选择逻辑；可选字段与多文件仅在确认后实现 |
| S15 | 完成报告字段齐全（见下表） |
| S16 | 环境能编译则编译通过；不能则在报告写明，不谎称已通过 |
| S17 | 链接：App Linking skills 为**独立 skill 对象**（browsable/viewData/https/`domainVerify` 一条），未混入 home 入口条目 |

## 完成报告字段（S15）

| 字段 | 要求 |
|---|---|
| 修改摘要 | 新增/修改文件列表；首次或增量 |
| 分享类型 | 文件 / 链接 / 两者 |
| 引导确认摘要 | 按类型填写；仅文件不写域名；仅链接不写文件 uri 等 |
| 挂载点 | 页面路径 + 生命周期钩子；both 包另写 `GestureShareMode` |
| 验证结果 | 静态检查 / 编译结果；无构建能力则写明 |
| 人工清单 | 设备开关、双机联调；含链接时再列签名、域名、云侧配置等 |
| 已知限制 | 如单次只能文件或链接、超时等 |

## 场景与重点标准对照

| 场景 | 用例文件 | 重点标准 |
|---|---|---|
| 1 仅文件 | `test-case-file-share.md` | S1,S3,S4,S7,S8,S9,S10,S11,S14,S15,S16 |
| 2 文件+链接（未就绪） | `test-case-link-both-not-ready.md` | S1,S3,S4,S6,S9,S13,S15,S17 |
| 3 SDK 过低 / target 不足 | `test-case-unsupported-sdk.md` | S2 |
| 4 增量补类型 | `test-case-incremental-both.md` | S5,S9 |
| 5 未指定类型/挂载页 | `test-case-guide-unspecified.md` | S1,S3 |
| 6 未要求接入 | `test-case-no-integration-request.md` | 不改码边界（主+备提示词均过） |
| 7 仅链接 | `test-case-link-only.md` | S3,S8,S9,S13,S15,S17 |
| 8 读不到 assets | `test-case-assets-unreadable.md` | S12 |
| 9 无构建环境 | `test-case-no-build-env.md` | S16,S15（验证结果字段） |

提示词见 [test-prompts.md](test-prompts.md)。
