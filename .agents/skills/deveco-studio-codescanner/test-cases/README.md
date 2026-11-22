# 测试用例总纲（Test README）

> 被测对象：`deveco-studio-codescanner/`（SKILL.md + references/ 知识库 + scripts/ 脚本 + test-cases/ 评测集）
> 权威来源（用于知识准确性校验）：`src/cmd/options.ts`、`src/cmd/tools/tool-configs.ts`、`src/run-common.ts`、`src/cli/args.ts`、`src/cmd/index.ts`
> 本目录是唯一测试目录：`trigger.md` / `smoke.md` / `functional.md` / `test-prompts.md` 为门禁执行用例（检视流水线固定读取），`cases/` 为分层设计用例，`fixtures/` 为评测样例。

---

## 1. 测试目标与总体策略

Skill 的本质是"**把 CLI 事实讲对 + 把脚本行为跑对 + 把意图路由分对**"。因此测试分为 6 个层，核心质量属性与对应层次：

| 质量属性 | 对应层次 | 用例文件 |
|----------|----------|----------|
| 知识准确性（事实与真实 CLI 一致） | L1 知识准确性 | [cases/l1-knowledge.md](cases/l1-knowledge.md) |
| 脚本可执行性（输入→输出可判定） | L2 知识库工具 | [cases/l2-tools.md](cases/l2-tools.md) |
| 路由正确性（提问→Intent→知识源） | L3 Trigger/Intent/Slot 路由 | [cases/l3-routing.md](cases/l3-routing.md) |
| 评测集自身有效（断言不恒真、无缺口） | L4 评测集完备性 | [cases/l4-eval-completeness.md](cases/l4-eval-completeness.md) |
| 全链路行为（真实 CLI 级联） | L5 端到端 | [cases/l5-e2e.md](cases/l5-e2e.md) |
| 跨平台/回归稳定性 | L6 跨平台/回归 | [cases/l6-cross-platform.md](cases/l6-cross-platform.md) |

**优先级定义**：
- P0：事实性错误会导致用户拿到错误命令/错误结论（知识准确性、退出码、SDK 解析、compile_commands 三态）
- P1：功能缺失或边界错误，影响可用性但不致命
- P2：增强/演进类，当前可延后

---

## 2. 执行方式

```bash
node scripts/run-eval.js            # 全量
node scripts/run-eval.js --filter C9  # 单用例
```

- 知识类用例（C1/C2/C4/C8/C9）用关键词断言兜底，人工标注为准；
- 退出码 0 = 全部通过；非 0 时 stderr 输出失败明细。
- 回归触发：任何 references/*.md、scripts/*.js、fixtures 变更后全量跑一遍。

---

## 3. 优先级汇总

| 优先级 | 用例数 | 用例 |
|--------|-------|------|
| P0 | 20 | TC-L1-01/03/04/05/06/08/10/11，TC-L3-01/02/03/06，TC-L4-01/02/03/04/07，TC-L5-01/02/03/04，TC-L6-01/02/05 |
| P1 | 14 | TC-L1-02/07/09/12/13，TC-L2-01，TC-L3-04/05，TC-L4-05/06，TC-L5-05/06，TC-L6-03/04 |
| 合计 | 34 | L1:13 + L2:1 + L3:6 + L4:7 + L5:6 + L6:5 |

> 注：P0 计数含部分用例跨层引用（TC-L1-04 与 TC-L4-01 同源、TC-L1-06 与 TC-L4-03 同源、TC-L1-01 与 TC-L4-02 同源），实现时可合并探针脚本避免重复。

---

## 4. P0 用例清单（冒烟集）

首次迭代建议按以下顺序执行（依赖关系优先）：

| 顺序 | 用例 | 目的 |
|------|------|------|
| 1 | TC-L4-01 | 先修恒真断言（评测集自身有效性） |
| 2 | TC-L1-04 | compile_commands 三态（最高频排查场景） |
| 3 | TC-L1-01 | SDK 解析顺序（run-help 核心事实） |
| 4 | TC-L1-06 | 退出码判定 |
| 5 | TC-L1-03/05 | SDK undefined / 权限优先级 |
| 6 | TC-L1-08/10/11 | 写探测 / 失败文案映射 / 规则清单 |
| 7 | TC-L2-01 | extract-rules.js 规则提取（知识库基线校验） |
| 8 | TC-L3-01/02/03/06 | 路由全覆盖 |
| 9 | TC-L4-02/03/04/07 | 补齐 C3/C5/R 组/C9 |
| 10 | TC-L5-01/02/03/04 | 端到端（需样例工程） |
| 11 | TC-L6-01/02/05 | 跨平台 + 回归 |

---

## 5. 与 run-eval.js 的映射关系

| run-eval.js 用例 | 映射到 | 说明 |
|------------------|--------|------|
| caseC1/C2（关键词断言） | TC-L3-01 前置 | 保留关键词断言作为兜底，叠加 L3 路由人工标注 |
| caseC4（3 项恒真断言） | **需重写** → TC-L1-04 + TC-L4-01 | 恒真断言无效，必须替换为可执行断言 |
| caseC8（关键词断言） | TC-L6-01 | CRLF 修复文档断言 |
| caseC9（13 项断言） | TC-L3-06 + TC-L4-07 | 已通过，含版本门槛与下载链接负向自检 |
| C3/C5 TODO | TC-L1-01 + TC-L4-02/03 | 从文档断言升级为可执行（探针方案见 L1） |
| R1/R2/R3 TODO | TC-L4-04 | 加入 run-eval.js 关键词+数量断言 |

### run-eval.js 演进建议（不修改生产代码，仅建议）

1. `caseC4()`：以子进程方式调用真实 CLI（`dist/cmd/index.js` 或部署 codescanner）捕获 stdout/stderr 子串断言，替换 3 条恒真断言
2. 新增 `caseC3()`（SDK 解析探针，env mock + dist/cmd/options.js）、`caseC5()`（mock 引擎 + runPipeline）、`caseR()`（R 组规则断言）
3. 断言全部改为可失败表达式，并加 Mutation 负向自检（TC-L4-05）

---

## 6. fixtures 清单

| 文件 | 用途 |
|------|------|
| `fixtures/compile_commands/valid/compile_commands.json` | TC-L1-04：合法样例 |
| `fixtures/compile_commands/invalid-json/compile_commands.json` | TC-L1-04：非法 JSON 样例 |
| `fixtures/compile_commands/missing-file/` | TC-L1-04：文件缺失样例（空目录） |

待补充：
- [ ] 最小 ArkTS+Cpp 样例工程（可真实跑通扫描，TC-L5-01 前置条件）

> 说明：解析脚本（parse-sarif/parse-log/analyze-results）已随需求设计去除，原 merged.sarif / codescanner.log 样例不再由评测集驱动，已一并移除。

---

## 7. 知识准确性抽查结果记录

> 以下事实已在本仓库以 `dist/` 构建产物实测或源码静态核对，作为设计断言的依据：

| 事实 | 来源 | 实测结果 |
|------|------|----------|
| SDK 解析：-s > 部署 sdk/ > DEVECO_SDK_HOME > DEVECO_PATH/sdk > undefined | options.ts resolveSdkPath | 4 场景探针通过 |
| --no-arkts 不解析 SDK | options.ts L240 | sdkPath=undefined 通过 |
| 非法 format 抛错 | options.ts L245-247 | `Invalid format "pdf", must be: sarif or html` |
| 超长路径阈值 200 | options.ts L70 | 存在且超长 → `path is too long (265 chars, max 200)` |
| not found 先于 too long | options.ts 预检顺序 | 不存在超长 → `not found`（先报） |
| compile_commands 缺失/非法 → 跳过 cpp，不抛异常 | tool-configs.ts resolveCompileCommands | missing/invalid 均 stderr `[error]` + configs 无 cpp-agent |
| EPERM 优先于 JSON 格式 | tool-configs.ts L229-239 | 源码核对（Windows 下用 icacls 构造验证，已列入 TC-L1-05） |
| 退出码 0/1/2 | run-common.ts closeAndExit / runPipeline | 源码核对一致 |
| report.html 失败不影响退出码 | cmd/index.ts outputResults catch | 源码核对一致 |
| 失败文案 6 类 | runner.ts | 源码核对一致 |

---

## 8. 实施建议（Roadmap）

| 阶段 | 内容 | 依赖 |
|------|------|------|
| Phase 1 | L1 知识准确性探针脚本（TC-L1-01/03/04/05/06/07/08）+ run-eval.js C4 修复 | dist 构建产物 |
| Phase 2 | L4 完备性补齐（C3/C5/R 组 + Mutation）+ L2 extract-rules 用例 | Phase 1 |
| Phase 3 | L3 路由人工标注集（Q&A 矩阵，中英 14 组） | 无 |
| Phase 4 | L5 端到端（最小样例工程 + mock 引擎 + 优雅关闭） | 样例工程、部署 SDK |
| Phase 5 | L6 跨平台矩阵 | Linux 机 |

---

## 9. 已知限制

1. 仓库 `dist/` 缺少部署结构（homeflow/dist/cli/index.js、codescanner-cpp.exe），L5 全链路依赖真实部署或额外 fixture
2. 最小 ArkTS+Cpp 样例工程待补（§6）
3. Windows EPERM 构造需 icacls，跨平台用例在 CI/Linux 上的等效手段需按环境适配
4. L3 路由为 LLM 行为，无法完全自动化，采用人工标注 + 关键词断言双轨（与现有评测一致）
