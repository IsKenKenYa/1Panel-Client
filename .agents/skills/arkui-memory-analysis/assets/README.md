# ArkUI 内存热点分析

开发者提供 .ets 源码文件/目录或 ArkUI inspector dump 文件。Skill 先读实际代码或解析 dump 节点树，再输出"热点类型 → 位置 → 问题描述 → 修复建议 → 严重度"的分析报告。默认只生成分析报告，由开发者选择是否应用修复方案。

## 模块组成

| 模块 | 运行入口 | 脚本 | 负责范围 |
|---|---|---|---|
| 源码静态分析 | [源码检查项](../SKILL.md#源码检查项) | `scripts/analyze-arkui-source.mjs` | .ets 源码中 18 类 ArkUI 反模式检测 |
| Dump 文件分析 | [Dump 检查项](../SKILL.md#dump-检查项) | `scripts/analyze-arkui-dump.mjs` | inspector dump 节点树结构分析 |
| 报告生成 | [报告格式](../SKILL.md#报告格式) | `scripts/generate-arkui-report.mjs` | 汇总 schema 输出 Markdown 报告 + HTML 可视化 |
| 用例构造指南 | [工作流程](../SKILL.md#工作流程) | `scripts/generate-test-guide.mjs` | 从源码 schema 生成内存测试用例构造指南（含页面导航路径） |

AI Agent + 脚本结合：脚本做秒级确定性检测（标准化 schema），AI 加载 SKILL.md 的 18 类规则做语义补充（常量间接控制、跨文件关联）。两者合并去重后输出完整结果。

## 分析与验收边界

- 源码分析为非 AST 工具：通过关键词/正则 + 反模式匹配 + LLM 比对给结论，不依赖 AST 解析。
- Dump 分析基于组件树结构做定性判断，内存为估算值（基础 native heap from memory.csv + 图形 DMA：Image = w×h×4，XComponent/Web = w×h×4×5，Canvas = w×h×4×3）。
- 空输入或无命中时输出"未发现已知故障"而非报错。
- 报告同时产出标准化 schema（JSON），供下游工具（可视化/用例构造/CI-CD）消费。
- 不自动修改应用代码、连接设备采集或上传材料。
- 检查 ArkUI 内存时，区分状态管理 V1/V2，并核对最低兼容与目标 API 版本。

检查项集中在 SKILL.md，按需读取其直接链接的 [故障树模式库](../references/arkui-anti-patterns.md)。test-cases/ 是维护材料，不作为诊断知识加载，也不把参考答案交给被测模型。

## 目录说明

| 目录 | 说明 |
|---|---|
| `SKILL.md` | Skill 唯一根级文件 |
| `references/` | 故障树模式库（18 类热点详情） |
| `scripts/` | 分析脚本（源码分析/dump 分析/报告生成/用例构造指南/install.sh）+ memory.csv |
| `assets/` | 模块说明、工具用户指南、npm 包 |
| `test-cases/` | 测试用例（trigger.md + functional.md） |

`test-cases/` 保留在技能根层级是流水线契约：仓库智能检视流水线（hmos-skill-test-runner）只识别 `<skill>/test-cases/` 路径下的 trigger.md / functional.md 等固定文件名，将该目录移入 assets/ 等其他位置会导致流水线判定"没有用例目录"并记结构 blocker。该目录是维护材料与门禁入口，不作为运行知识加载（SKILL.md 已声明），预期输出不进入被测会话。

## 当前交付

18 类 ArkUI 内存热点检测规则（H-01~H-18，H-04 含源码+dump 两侧），覆盖不可见页面、Tabs 缓存/预加载/动画、长列表非懒加载/CachedCount、布局冗余、页面栈过深、缓存池未释放、XComponent 未释放、不合理超大图、命令式节点缓存、Canvas 渐变、ImageAnimator 帧集过量、Video 常驻、ArkWeb 预渲染过多、BuilderNode 销毁流程不完整、缓存池清空使能未设置。

6 条通用语义关联原则（非固化规则，覆盖未知问题）：不可见+资源持有=浪费、已消失仍存在=泄漏、有创建无释放=缺失、比率失调=系统性、常量间接控制=劣化、跨文件引用=全局持有。

三种分析模式：仅源码 / 仅 dump / 综合分析。产出目录 `arkui_memory_analysis/` 含 Markdown 报告 + 标准化 JSON + 用例构造指南 + HTML 可视化。
