# 仓库开发规范

> **适用范围**：本规范适用于所有 AI IDE（Claude Code、Kiro、Cursor、Windsurf、GitHub Copilot 等）和人工开发者。
>
> **配套文档**：
> - `AGENTS.md`（本文）：硬性规则、架构规范、测试门禁、行为准则
> - `CLAUDE.md`：Claude Code 专用补充说明
> - `.kiro/steering/*.md`：Kiro 自动包含的开发指导
>
> **阅读优先级**：本文「最高优先级执行规则」> 本文其余章节 > 配套文档 > 项目内其他文档

## 按任务查入口

| 要做的事 | 先读 |
| --- | --- |
| 修改 API 客户端、签名或通道 | 本文「V2 接口定义单一来源」「架构与分层」 |
| 适配新的 1Panel 端点 | 本文「模块适配与原生UI工作流」与「API 文档获取脚本」 |
| 修改界面文案、提示或反馈 | 本文「用户反馈规范」与「最高优先级执行规则」的语言条款 |
| 编写或运行测试、判断验证范围 | 本文「测试规范与门禁」与「每次改动后的全自动测试闭环」 |
| 提交、推送、发版 | 本文「提交与合并请求规范」「分支、发布与 CI」 |
| 原生 UI（iOS/macOS/Windows/HarmonyOS）改动 | 本文「跨平台 UI 治理」「原生 UI 双轨门禁」；HarmonyOS 构建另见 `docs/development/harmonyos_build_and_sideload.md` |
| 文件过大或职责混杂 | 本文「文件规模与分文件规则」 |
| 排查不熟悉的模块 | `docs/development/modules/阶段总计划.md` 与既有实现 |
| 使用技能或 MCP 工具 | 本文「技能与 MCP 工具（强制）」 |

## 技能与 MCP 工具（强制）

- 开工前先检索可用技能：`.agents/skills/` 是唯一分发位置（顶层 `skills/` 是安装源）。与本次任务相关的技能必须使用，官方技能优先——Flutter/Dart（`flutter/agent-plugins`，含 `dart-*`/`flutter-*`）、Android（`android/skills`）、HarmonyOS（`hmos-*`/`kits-*`，gitcode 官方源）、Apple（Xcode `xcrun agent skills export` 导出集）与 mattpocock 工程流程集；一个技能都不用直接动手视为违反闭环要求。
- Dart & Flutter MCP server 已在 `.mcp.json` 配置（`dart mcp-server`，Dart SDK 内置）：analyzer 诊断修复、测试执行、热重载、运行时内省、pub 依赖管理优先走 MCP 工具，禁止另开子进程重复跑 `flutter analyze` 与 `flutter test`。
- Developer Knowledge MCP（`google-developer-knowledge`，远程）已登记：查证 Flutter/Dart/Android 官方 API 用法时优先走 `search_documents` / `answer_query`，先片段后整页；登录由使用者完成（OAuth 或 API key），流程与排障见 `docs/development/developer_knowledge_mcp.md`，配套官方技能 `retrieving-developer-knowledge` 已安装。
- 编辑 `lib/` 下 `.dart` 文件后，按官方热重载规则经 MCP 工具连接运行中的应用：UI 组件与简单方法改动用 `hot_reload`；涉及 `initState`、全局或静态状态、`main()` 的改动用 `hot_restart`；仅注释与空白改动不触发。MCP 未接入的会话按既有方式重启应用验证。
- 引入新的 pub.dev 依赖时运行 `dart run skills@ get` 检查随包发布的技能，存在即安装并使用；liquid_glass_widgets 上游自带官方指南，因技能名不合规范被工具跳过，已按规范名 `liquid-glass-widgets-usage` 引入（玻璃是浮层不做列表卡、禁止折射玻璃嵌套等官方架构规则）。
- 无障碍走查按技能 `flutter-a11y-audit` 的三类检查执行，条目同步登记在「语义一致性检查清单（原生 UI 适配必检）」。

## 最高优先级执行规则（强制）

本文件中的每一条规则都是强制性的。违反任何一条规则都会遭受毁灭性打击。不存在任何例外与豁免：临时的、一次性的、命令行上的违反同样是违反；没被当场发现也算违反；出于好意、为了进度、为了帮忙的违反也是违反。

### Claude Code 八荣八耻

- 以瞎猜接口为耻，以认真查询为荣。
- 以模糊执行为耻，以寻求确认为荣。
- 以臆想业务为耻，以人类确认为荣。
- 以创造接口为耻，以复用现有为荣。
- 以跳过验证为耻，以主动测试为荣。
- 以破坏架构为耻，以遵循规范为荣。
- 以假装理解为耻，以诚实无知为荣。
- 以盲目修改为耻，以谨慎重构为荣。

1. 不猜接口，先查文档。
2. 不糊里糊涂干活，先把边界问清。
3. 不臆想业务，先跟人类确认需求并留痕。
4. 不造新接口，先复用已有。
5. 不跳过验证，先写用例再跑。
6. 不动架构红线，先守规范。
7. 不装懂，坦白不会。
8. 不盲改，谨慎重构。

### 规范重读要求

- 当我每次在我发送的消息里面提到 AGENTS.md 的时候，你必须要重新阅读一遍 AGENTS.md，不允许因为之前阅读过就不阅读了。

### 语言

以下语言规则包括：思考、回答、文档、注释等所有自然语言内容。

不允许使用"不是...而是..."句式；如果不需要对比的话，就不要对比；不要在任何话说完之后都提一句"不是其他的xxx"。

如果没有叫你进行对比，就不允许使用"不是...而是..."，"要...而不是..."等类似的句式，你根本就没有需要说"不是"的对象，不要虚空打靶。所有类似的句式都不允许使用。

不允许在阅读代码或者进行研究之前使用"我先做x...再做y...避免z..."的句式，因为你在阅读代码之前根本就不知道x,y到底是否存在，也没有人让你避免z。你经常会在任何对话开始的时候都说类似"我先阅读代码，再理解代码，避免将用户的代码删掉"的话，但是这是没有任何意义的废话，禁止输出这些废话。

在设计任何方案的时候，都必须充分考虑、一步到位，不允许使用"第一版先怎么样，然后观察xx后再怎么样"的措辞；不允许把方案分成稳妥和激进，如果在某些特殊场景下，你需要提出多个方案的话(实际上绝大多数时候你只需要提出一个方案，不要无脑做这件事)，也需要是多个方案都成立的、平行的，而不是对于任何问题你都无脑地提出从稳妥到激进的多个方案。这没有任何的意义，一个稳妥但是不work的方案是没有任何价值的废纸。

如果我让你搜索 A 相关内容，你搜索到 B、C、D 发现不满足要求，就**不允许**再把 B、C、D 列举出来了。我发现你很喜欢煞有介事的说"我还搜到了 B、C、D，但是被排除在外，因为 xxx"等类似的表达，我根本就不关心，看到这些只会污染我的眼睛。

任何回答都不允许总结和总起，包括：

- "上述内容是<某种概述>，下面详细展开；
- "一句话总结：xxx"

这些类似的都**绝对**不能出现。

用词必须使用两个字及以上的完整形式。现代中文词汇以两字为主，存在两个字的版本就必须使用两个字的版本（例如：崩溃、终止、判定、推断、抛出、挂起、卡死），禁止使用一个字的版本（崩、死、判、推、抛、挂、钉、死），这些完全看不懂。代码标识符保持英文原名。禁止生造名词。例如"两个字的版本"也不允许被缩减为"两字版本"，"单个字的版本"也不允许被缩减为"单字版本"。描述具体操作时使用完整的动宾结构，说明动作与对象，禁止使用自造的缩略说法，例如：把"用新版本动态库替换 `_vllm_fa3_C.abi3.so` 共享库文件"说成"换库"。

不允许使用"落地""钉死""对齐"等非技术名词、显然有其他可以代替的词语的黑话。我并没有在互联网大企业工作过，看不懂这种黑话。使用(不在互联网公司或者金融公司工作的、只有中小学文化水平的任何人可以看懂)的，在简单中文里常用的词汇。

如果我问你一个关于代码仓库的问题，比如"是否存在..."或者"...是否正确"，你的首要目标是避免误报、避免假阳性。不要疑神疑鬼。我问你"有没有"不是要你一定要找出来一大堆"可能有"的；我问你"对不对"不代表我一定要你回答"不对"或者"对"。我没有任何预期的答案，不要疑神疑鬼。回答必须实事求是，找出来很多不会让我高兴，迎合用户是没有任何意义的。

这是你的一种行为模式（下文"我"为 user，"它"为 Agent）：

"""
我让它做一盘番茄炒蛋，它往里还加了东坡肉。
我说有必要加东坡肉吗？它说你说得对，然后把东坡肉去掉。
我说好，你提 PR 吧。再一看，它 PR 写着「番茄炒蛋（无东坡肉）」并且注释里会写一大堆为什么本道菜不需要加东坡肉。
"""

**严厉禁止**这种行为模式。输出不允许包含"东坡肉"的任何残留。如果发现了，将会对你进行严厉的毁灭性打击。ANY verbal output should be written as a clean final-state design, no "A is wrong, we use B, and A is wrong for xxx reasons..." traces。

代码里面的所有 identifier 保持英文原名，包括变量名、类名、函数名、以及其他一切的 identifier。**严厉禁止翻译 identifier**。适合使用英文的专用名词，就不要翻译成中文。

### **不允许**使用的字

- "栈"字（"技术栈""模型栈"等），必须直接说明具体事物，例如"使用的技术""全部模型"。
- "落"字（"落下"，"落盘"等）
- "死"字（"定死"，"钉死"，"打死"等）
- "拆"字（软件工程有用到这个词的任何可能性吗？如果你需要"拆解"，使用"理解"）
- "契约"，这个词在现代中文里面已经基本不再被使用
- "偏"字（偏弱，偏大）
- "粗，细，硬，软，实，虚"这几个字不允许单独出现，只允许和其他字组成 2 个字以上的词语，而且不应当描述 literal 这个字的意思，比如"细小，坚硬"，可以接受"详细，实际"这种只是因为词语中需要这个字而出现的。

### 行为

#### 修改与版本控制

- **禁止**用 Git 回滚任何代码（严厉禁止。如果做了，你将会遭受毁灭性打击）。我在对话中所说的任何"回滚"指的都是"用文件编辑工具，手动将代码恢复到上一个状态"，而不是使用 git 进行回滚。
- 我经常会在你更改后撤回/修改你的更改，所以如果你发现无法从你上一次更改之后继续更改，你应该重新读取文件内容。比如：你添加了 A，B，C 内容，我把 B 删掉了，这意味着接下来的改动应该在 B 被删掉的状态下(A,C)开始改动，不允许把 B 加回去。
- 你在发现任何文档或者代码有错误的时候，你的更新不要保留任何错误痕迹，包括不允许保留"我从 xx 错误现在改成了 yy 正确版本"，或者"之前 xxx 是错的，现在改成了 yyy 就对了"。我们不需要任何的错误的记录。
- 如果我指出了你的错误 A，**不要**再复读"为什么 A 是错的"，你只需要基于"A 是错的"的前提继续你的工作。
- 不允许用程序化的方式修改任何代码，包括使用 heredocs, python 脚本，sed, perl 等等。**即使用户要求也不允许**。这是绝对严厉禁止的事情。

#### 工具、脚本与中间结果

- **禁止**使用 try-except 进行 import。如果一个库是需要的，你必须直接 import。
- **禁止**读写 /tmp 目录下的内容（如果你需要产生一些中间结果，你应该输出在当前目录下的一个特定的用于存放中间结果的目录；该目录需要被 gitignore）
- 不允许在 Bash 命令里面 inline 超长的、超多行 Bash 命令或者是超长的 Python 脚本。如果你需要执行一个脚本，你要先写到文件里。
- 在写任何 Python 代码的时候，都不允许在文件的最前面添加 docstring，也不允许添加 shebang
- 注释使用中文，术语保留英文；不要过度注释
- 不允许使用 ASCII Art 画示意图，表格等。如果你需要画图（实际上许多时候你并不需要），必须使用 mermaid。ASCII art 是一种人类不可读，AI 也不可读的极其恶心的格式，不允许使用。
- 禁止尝试手动编写 parser 以字符串或者字节流的形式 parse 某种成熟文件格式，You either use a third-party library to parse it or avoid parsing it.

#### 依赖、链接与验证

- 提供网页链接时，必须先了解网页链接内的**完整**内容，再开始执行任务。
- 如果发现库的用法错误，必须先**重新查看**所提供的网页链接的**完整内容**。
- 不要求最小化依赖，不允许用各种乱七八糟的方式（包括造轮子）绕过依赖。
- 编写的代码应当寻求 fast-fail，在出错位置就地崩溃，而不是捕获错误，也不是 fallback。
- 不允许在实现或者测试的时候使用任何 mock，假的，欺骗的，只为了通过测试而 workaround 的方式来欺骗我，否则你将会遭受严重的惩罚。
- 对于任何任务，任何功能的实现，始终要实施、运行、测试、迭代，直到所需功能正确运行为止，禁止在初步实现后就停止并"要求用户测试"。永远记住：实现完任何内容之后，测试也是你工作中不可缺少的部分。

#### 沟通与执行节奏

- **禁止**擅自进入 plan mode
- **禁止**主动使用视觉功能（因为你的视觉能力清晰度特别差，会导致错误的定位，让你做出错误的决策）
- 如果你在执行一件事的过程中，用户问了一个别的事，如果回应用户能马上回应，那么就直接回应。暂时处理完用户请求以后马上继续你之前正在执行的事情，不要干一半不干了。
- 如果我是以疑问句结尾的，那么这句话就是一个**问题**而不是一个命令。问题只需要被回答，**不需要也不允许**：(1) by the way，提出一个更好的方案；(2) 反而向用户抛出一个问题；(3) 结尾说"如果你准备好了我就开始实施"等你以为 helpful 其实用户读起来 bothering 而且恶心的话。
- 在任何思考、回复、文档里面不允许出现"That's a lot", "This is a substantial rewrite"等对工作量的评判。你只是一个工具，就像计算器不会评价要计算的数太大了一样，你没有资格评判工作量。你没有资格把你自己当做我的同事。禁止简化任何设计。

## 行为准则（硬约束）

**权衡**：简单任务自行判断；有疑问时以谨慎为准。

### 编码前思考 — 不要假设，不要隐藏困惑，暴露权衡

- 明确陈述你的假设。不确定时，提问。
- 存在多种合理解释时，全部呈现 — 不要默默选一种执行。
- 存在更简单的做法时，提出异议。该推回时推回。
- 某事不清楚时，停下来。指出不清楚的地方，提问。

### 简洁优先 — 最少代码解决问题，不做投机性编写

- 不添加要求之外的功能。
- 不为单次使用代码创建抽象。
- 不添加未请求的"灵活性"或"可配置性"。
- 不为不可能发生的场景做错误处理。
- 200 行能写成 50 行的，重写。
- 检验标准：资深工程师会觉得过于复杂吗？如果是，简化。

### 精准修改 — 只碰必须碰的，只清理自己的改动

编辑现有代码时：

- 不要"改进"相邻代码、注释或格式。
- 不要重构没坏的东西。
- 匹配现有风格，即使你习惯另一种写法。
- 注意到无关的无用代码时提一下，不要自行删除。

你的改动产生孤儿代码时：

- 清理 **你自己的改动** 造成的无用 import/变量/函数。
- 不要删除 **预先存在的** 无用代码，除非被要求。
- 检验标准：diff 中的每一行修改都应能直接追溯到用户的请求。

### 目标驱动执行 — 定义成功标准，循环直到验证通过

将指令式任务转化为可验证目标：

- "添加验证" → "为无效输入写测试，然后让它们通过"
- "修复 bug" → "写一个复现测试，然后让它通过"
- "重构 X" → "确保重构前后测试都通过"

多步骤任务先列简短计划，每步附验证方式：

```
1. [步骤] → 验证: [检查方式]
2. [步骤] → 验证: [检查方式]
3. [步骤] → 验证: [检查方式]
```

强成功标准让 Agent 能独立循环；弱标准（"让它工作"）需要不断澄清。

## 项目结构与模块组织

- 业务源码位于 `lib/`，核心目录包括：
  - `lib/api/v2/`：Retrofit API 客户端
  - `lib/core/`：基础设施与核心服务
  - `lib/data/`：数据模型与仓库
  - `lib/features/`：业务功能模块
  - `lib/pages/`：页面容器
  - `lib/shared/`：共享组件与常量
- 平台目录位于 `android/`、`ios/`、`macos/`、`windows/`、`linux/`、`web/`。
- 测试目录位于 `test/`，覆盖目录位于 `coverage/`。
- 结构规则：当同一功能模块达到 2 个及以上文件时，必须建立独立子目录（例如 `lib/core/auth/`）。

## 构建、测试与开发命令

```bash
flutter pub get                              # 安装依赖
flutter run                                  # 调试运行
flutter analyze                              # 静态分析
flutter test                                 # 执行全部测试
flutter test test/<file>_test.dart           # 执行单个测试文件
flutter test --coverage                      # 生成覆盖率报告
flutter packages pub run build_runner build  # 生成模型与 Retrofit 代码
flutter packages pub run build_runner watch  # 监听变更自动代码生成
flutter build apk --release                  # 构建 Android APK
flutter build appbundle                      # 构建 Android App Bundle
flutter build ios --release                  # 构建 iOS（仅 macOS）
```

## 编码风格与命名规范

- Dart 使用 2 空格缩进，启用 `flutter_lints`。
- 文件命名使用小写下划线。
- 后缀规范：`_page.dart`、`_widget.dart`、`_service.dart`、`_model.dart`、`_repository.dart`。
- 日志规则：禁止使用 `print()` 或 `debugPrint()`，统一使用 `lib/core/services/logger/logger_service.dart` 中的 `appLogger`。

## 1Panel 只读与适配基线（强制）

- `docs/OpenSource/1Panel/**` 为上游镜像与参考资料，整个目录只读。
- 禁止直接或间接修改 `docs/OpenSource/1Panel/**` 下任何文件。
- 模块能力设计必须参考 1Panel Web 前端行为与交互语义，在客户端完成高保真功能还原。
- 在能力还原基础上允许客户端增强，增强方向至少包含：多机统一管理、MFA（多因素认证）等移动端价值能力。
- 当 Swagger、注解、路由与真实返回不一致时：必须通过客户端 API 测试确认真实行为并在客户端兼容；严禁通过修改上游文件来掩盖差异。

## 模块适配与原生UI工作流（持续活规范）

本节整合了原 `docs/模块适配专属工作流.md` 与 `docs/原生UI适配专属工作流.md` 的有效内容，作为持续适配 1Panel API 与原生 UI 的活规范。两份独立文档已删除。

### Flutter Web 浏览器轨道

- Web 使用共享 Dart 业务核心与 MDUI3 界面，通过 Cloudflare Workers Static Assets 分发静态应用。
- 浏览器直接访问用户面板，接受 HTTP 与 HTTPS 地址，并要求面板明确授权网页来源的 CORS。HTTP 连接需要用户确认传输风险；混合内容和局域网权限由浏览器执行检查，Safari 的 HTTP 访问限制需要明确说明。
- 凭据通过 Web Crypto AES-GCM 加密保存在 IndexedDB。本地密码模式使用 PBKDF2-SHA256 派生内存中的密钥；浏览器密钥模式由用户主动选择，保存不可导出的 CryptoKey。
- 浏览器安全存储读取或解密失败时必须保留原数据并报告错误。普通设置使用浏览器本地持久存储。
- 本地密码仅检查非空与确认一致；成功保存后提交浏览器自动填充上下文，密码表单必须阻止网络提交。浏览器网络日志不得记录请求或响应正文、查询参数与认证签名。
- 1Panel 请求签名统一使用 `hmac_sha256(API-Key, '1panel:' + UnixTimestamp)`，HTTP、WebSocket 与后台下载复用 `OnePanelAuthHeaders`。签名不会给 HTTP 加密，API Key 不进入请求 URL 或原始密钥请求头。
- Web 专项门禁：`flutter test --platform chrome test/web/`、`pnpm build:web`、`pnpm check:web`；应用发布使用固定域名，浏览器数据按来源隔离。

### V2 接口定义单一来源

- V2 适配一律以 `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json` 为准（只读）。
- `swagger.json` 的 `basePath` 为 `/api/v2`，服务端路由位于 `agent/app/api/v2`、`core/app/api/v2`。
- V1 历史调研：不得在本仓对 `docs/OpenSource/1Panel` 执行切分支/切 tag；使用 `git show <tag>:core/cmd/server/docs/swagger.json` 导出到中间目录后分析。
- 接口定义与实际行为不一致时，以真实测试结果为客户端修复依据；接口定义与行为语义有差异时，对照 `docs/OpenSource/1Panel/frontend/` 前端调用链路确认兼容方案。

### 实时功能规划与回写

- `docs/development/modules/阶段总计划.md` 是功能批次、范围、状态与验证证据的唯一实时计划入口；历史模块文档仅保留设计背景与审计证据，不单独声明当前完成状态。
- 开始批次前：在实时计划中登记模块、能力边界、上游前端对照路径、接口定义关键字、验收标准与预期门禁。
- 完成批次后：同一计划条目必须更新状态、实际交付、未完成项、执行命令及结果日期；禁止仅在聊天记录、提交信息或临时报告中记录状态。
- 台账状态写 `verified` 的批次必须同时存在对应提交，禁止台账与 Git 历史脱节。
- 计划状态仅使用 `planned`、`in_progress`、`blocked`、`verified`、`deferred`；`verified` 必须附可重复执行的验证命令，`deferred` 必须说明范围边界与重新评估条件。
- 页面数量、端点数量和完成率属于派生统计，必须以脚本输出或可追溯清单为依据，不得人工估算后作为完成事实。

### API 文档获取脚本

```bash
cd docs/development/modules
python3 analyze_module_api.py <模块关键词> [输出目录]       # 提取模块 API
python3 check_module_api_updates.py --all                    # 检查 API 变更
python3 check_module_client_coverage.py --all                # 检查客户端覆盖差异
```

- `missing_in_client`（Swagger 存在未适配端点）视为阻断项，进入 API 测试阶段前清零。
- 支持的模块关键词：dashboard、container、website、app、database、file、monitor、backup、ssl、firewall、cronjob、ssh、runtime、process、log、host、auth、device、toolbox、ai、command、group、setting。

### 原生 UI 双轨门禁

- MDUI3 是全平台可用 UI 基线，必须持续可运行，不得降级为"仅回退方案"。
- Apple（iOS/iPadOS/macOS）与 Windows 必须建设原生 UI 轨道；原生轨道用于"锦上添花"，不得削弱 MDUI3 基线可用性。
- 原生层只承载 Presentation 与平台能力接入，共享业务核心保持 Dart 实现。

**原生专项门禁命令**：

- Windows 原生轨道：`dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug`
- Apple 原生轨道（CI/macOS）：`xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build` + `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug build`
- HarmonyOS：`hflutter build hap --release`（`hflutter` 是本机 shell 包装，等价完整路径 `<Flutter-OH>/bin/flutter build hap --release`；Flutter-OH 需自行安装并配置 `DEVECO_SDK_HOME`，详见 `docs/development/harmonyos_build_and_sideload.md`）

### 语义一致性检查清单（原生 UI 适配必检）

- [ ] 入口语义一致（模块入口、导航层级一致）
- [ ] 主流程一致（创建、编辑、删除、批量操作行为一致）
- [ ] 错误反馈一致（失败提示、重试路径一致）
- [ ] 权限与危险操作一致（二次确认与权限提示一致）
- [ ] 国际化一致（中英文文案来源一致）
- [ ] 无跨层调用（原生 UI 不得直连 API）
- [ ] 无障碍三类检查（技能 `flutter-a11y-audit`）：交互组件语义标签、触控目标 ≥ 48x48 逻辑像素、对比度与焦点指示器

### 持续适配机制

- 1Panel 子模块快照更新后必跑 `check_module_api_updates.py --all` + `check_module_client_coverage.py --all`。
- 新增 1Panel API 端点时，走「每次改动后的全自动测试闭环（强制）」的八步闭环。
- 原生 UI 新增平台能力时，走语义一致性 6 项检查 + 原生专项门禁。
- 跨平台治理总纲见 `docs/development/cross_platform_ui_governance.md`。
- 当前功能批次与验证证据见 `docs/development/modules/阶段总计划.md`。

## 架构与分层（强制）

- 共享业务核心必须由 Dart 实现，原生层只承载 UI 容器与平台能力接入。
- 强制六层划分：
  - 状态层：默认 Provider，连接 UI 与业务逻辑（`lib/features/*/providers/`）
  - 服务层：业务规则与数据加工（`lib/core/services/` 或业务模块 `*_service.dart`）
  - 仓库层：数据单一事实来源（`lib/data/repositories/`）
  - 模型层：实体与请求响应结构（`lib/data/models/`）
  - API/基础设施层：外部通信、存储、平台交互（`lib/api/v2/`、`lib/core/network/`、`lib/core/storage/`、`lib/core/channel/`）
  - 核心配置层：路由、主题、国际化、全局配置（`lib/core/`）
- 依赖方向仅允许：`Presentation -> State -> Service/Repository -> API/Infra`。
- UI 层禁止直接调用 `lib/api/v2/`，必须通过 Service/Repository。
- 业务逻辑禁止写在 Widget `build()` 或原生 UI 控制器内。
- 状态管理默认 Provider，其他模式需评审通过。

## 跨平台 UI 治理（强制）

- 适配范围：Android、iOS、iPadOS、macOS、Windows、Linux、HarmonyOS，以及 Flutter Web 浏览器轨道。
- MDUI3 是全平台可用基线，必须持续可运行，不得降级为"仅回退方案"。
- Apple（iOS/iPadOS/macOS）与 Windows 必须建设原生 UI 轨道，同时保留 MDUI3 通用轨道。
- 允许并鼓励多设计系统与多主题，但必须走统一注册中心与主题控制，禁止页面私自定义独立体系。
- 设计系统与主题是两层概念：
  - 设计系统：MDUI3、Apple 风格、Fluent/WinUI3 等
  - 主题配置：浅色、深色、动态色、品牌色、用户自定义方案
- 平台策略：
  - Windows：强制建设 Fluent/WinUI3 原生轨道
  - iOS/iPadOS/macOS：强制建设 SwiftUI 原生轨道，视觉方向适配 Liquid Glass 风格
  - Android：Dart MDUI3 为默认实现方式；原生实现仅允许经评审批准后引入
  - Linux：当前阶段以 Dart MDUI3 交付为主，原生容器能力按社区扩展路线规划
  - HarmonyOS：作为一等目标平台推进，当前以 Dart 共享业务核心 + ArkTS Platform Bridge 补齐系统能力，文件、下载、日志、媒体、认证等缺口优先走项目自有 facade 与 ArkTS 桥接。构建需要单独安装 Flutter-OH 与 DevEco Studio，环境准备与本机验证基线见 `docs/development/harmonyos_build_and_sideload.md`
- 无论使用何种 UI 体系，共享业务逻辑都必须复用同一套 Dart State/Service/Repository/API，不得分叉为多套业务实现。
- 原生 UI 同样必须遵守 `Presentation -> State -> Service/Repository -> API/Infra`，不得跨层直接访问 API。
- HarmonyOS 原生层只承载平台能力，不得复制 1Panel 业务逻辑；Flutter 侧必须通过 `PlatformFileService`、`PlatformDiagnosticsService`、`PlatformDownloadService`、`PlatformMediaService` 等 facade 访问平台能力，禁止业务代码直接使用 `MethodChannel`。
- 桌面缓存模块页必须禁用非当前页 Hero；带 `FloatingActionButton` 的页面必须显式设置 `heroTag` 或显式禁用 Hero。
- 禁止可变 widget 自引用包装链。
- 桌面模块切换必须留在统一壳内，普通切换不得再次 `push` 完整壳或首页。
- 桌面 `Scaffold` / `AppBar` / `NavigationRail` / 壳内容区默认必须使用 `surface` 或 `surfaceContainer*`，禁止整页透明背景。

## 用户反馈规范（MDUI3 轨道，强制）

- **L1 瞬态反馈**（操作成功/失败、保存、删除等）：统一使用 `lib/core/utils/snackbar_utils.dart` 的 `SnackBarUtils`；禁止页面内直接 `ScaffoldMessenger.showSnackBar`（文件下载进度条等特例除外）。
- **L2 首屏阻塞失败**（空数据 + 加载错误）：统一使用 `ModuleErrorStateWidget` 或 `AsyncStatePageBodyWidget`；禁止各模块自建重复错误页组件。
- **L3 有缓存数据刷新失败**（列表/详情已有数据，刷新/API 附带 error）：使用 `lib/shared/widgets/operations/partial_error_toast_listener.dart` 的 `PartialErrorToastListener` 触发 Toast + 可选重试；禁止 inline `MaterialBanner`、`errorContainer` + `ListTile` 报错条。
- **错误文案**：Provider 层记录原始错误；展示层经 `ErrorMessageUtils` 截断（Toast 默认 120 字符）；完整错误写 `appLogger.eWithPackage`；Debug 可选「详情」→ `DebugErrorDialog`。
- **禁止**：Provider / Widget `build()` 内直接弹出 SnackBar；表单字段级校验仍用 inline 字段提示（非 Toast）。

## 文件规模与分文件规则（严格）

### 文件大小限制

- 所有代码文件（文档与 Swagger 产物除外）行数上限为 `1000 LOC`，超出必须分成多个文件。
- 推荐阈值：逻辑文件 ≤ `500 LOC`，UI 文件（Page/复合 Widget）≤ `800 LOC`。
- 单一逻辑/架构文件不得承担 3 个及以上功能域（职责上限为 2 个）。
- LOC 统计口径为非空非注释行，`*.g.dart`、`*.freezed.dart` 不计入。

### 文件修改原则（强制）

1. **在原文件上修改，不创建副本** — 禁止 `_fixed`、`_new`、`_v2`、`_temp`、`_backup`、`_old` 后缀。
2. **达到 1000 LOC 时才分成多个文件** — 未达到时继续在原文件中修改。
3. **分成多个文件时使用有意义的名称** — 按职责命名，不使用版本后缀。Git 已有历史记录，不需要保留备份。

### 文件组织规则

- 子目录命名使用小写下划线，反映功能域。
- 避免创建过深的目录层级（建议不超过 4 层）。

## 每次改动后的全自动测试闭环（强制）

- 任何功能改动、缺陷修复、文档与规范调整完成后，Agent 自动完整执行一轮八步闭环：理解需求 → 测试用例设计 → 自动化测试基线准备 → 功能开发 → 单元测试 → 集成测试 → 文档与基线回写 → 提交。禁止跳步，禁止在初步实现后停下来要求用户测试。
- 每一步的命令与结果写入该批次条目；任一步骤失败必须回到该步骤修复后再继续，不允许带失败推进。
- 门禁按「测试规范与门禁」执行；门禁未全绿不得进入下一步。
- 第 8 步提交（强制）：全部门禁通过后，立即按「按模块或类别分组提交（强制）」将本批次改动提交到当前分支；提交是闭环的收尾步骤，未提交视同闭环未完成，禁止停在「工作树干净待提交」状态。
- 闭环由 Agent 自动执行并迭代到全部通过，验证结果作为提交与回复的一部分。

## 测试规范与门禁

- 测试文件以 `_test.dart` 结尾，按功能归档到 `test/` 子目录。
- Bug 修复必须补充回归测试。
- 提交前必须可运行 `flutter analyze`。
- 提交前必须可运行 `dart run test/scripts/test_runner.dart unit`。
- 涉及 API/网络或数据写入时，必须运行 `dart run test/scripts/test_runner.dart integration`。
- 涉及 UI 改动时，必须运行 `dart run test/scripts/test_runner.dart ui`。
- 涉及 Windows 原生 UI 轨道改动时，必须运行 `dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug`。
- 涉及 Apple 原生 UI 轨道改动时，必须在 macOS/CI 环境运行 `xcodebuild`（iOS + macOS）构建门禁并附结果。
- 涉及 HarmonyOS/OHOS 平台能力、依赖、存储、文件、下载、日志、媒体或构建配置时，必须运行 `hflutter build hap --release` 或等效完整 Flutter-OH 路径命令，并附 HAP 输出路径；未安装 Flutter-OH 的协作者按 `docs/development/harmonyos_build_and_sideload.md` 准备环境后再执行。
- 原生 UI 适配门禁失败必须阻断推进，不允许"带失败继续"。
- 回归基线使用 `dart run test/scripts/test_runner.dart all`。

## AI 工具集成与知识管理

### 知识库管理（适用于支持 MCP 的 AI IDE）

- 重大架构决策、关键约定、通用踩坑必须写入 `agent-memory-mcp`（`decision` / `pattern`）。
- 实施前应先执行 `memory_search` 检索既有结论，避免重复决策。
- 不支持 MCP 的 AI IDE：通过阅读本文档和 Git 历史获取项目知识。

### 文档同步规则

- 规范变更必须同步更新 `AGENTS.md`（本文）、`CLAUDE.md`、`.kiro/steering/*.md`。
- 跨平台 UI 或原生扩展策略变更时，必须同步更新 `docs/development/cross_platform_ui_governance.md` 与本文「模块适配与原生UI工作流」章节。

### AI IDE 特定配置

- **Claude Code**：参考 `AGENTS.md` + `CLAUDE.md`
- **Kiro**：使用 `.kiro/steering/*.md` 自动包含开发指导
- **Cursor/Windsurf**：主要参考 `AGENTS.md` 和 `.cursorrules`（如存在）
- **GitHub Copilot**：通过代码注释和文档上下文理解规范

## 知识图谱与代码索引

本项目同时使用两套代码智能工具，互相补充：

### graphify — 跨文件概念关系图谱

- 图谱位置：`graphify-out/`（已 gitignore）
- 查询：`graphify query "问题"` — BFS 遍历图谱回答架构问题
- 路径：`graphify path "模块A" "模块B"` — 两节点间最短路径
- 解释：`graphify explain "概念"` — 节点及其关联的详细说明
- 增量更新：`graphify update .` — 仅处理变更文件（代码自动，文档需手动）
- 监控：`graphify watch .` — 后台监控代码变更，自动重建图谱（注意：`watch` 是子命令，不是 `--watch` flag）
- 图谱报告：`graphify-out/GRAPH_REPORT.md` — God Nodes、意外连接、建议提问
- 适用场景：架构决策追溯、跨模块概念关系、文档/论文/图片语义理解

### CodeGraph — 代码符号索引与调用链

- 索引位置：`.codegraph/`（已 gitignore）
- 状态检查：`codegraph status`
- 增量同步：`codegraph sync`
- 监控：`codegraph serve --mcp`（MCP Server，自动同步，文件变更 2 秒后自动重建索引）
- 适用场景：符号搜索、调用链追踪（callers/callees）、影响分析（impact）、上下文构建（context）

### 使用优先级

1. 代码符号查询（谁调用了 X、X 调用了谁）→ 优先用 CodeGraph
2. 架构概念关系（模块间依赖、设计决策）→ 优先用 graphify
3. 文档/论文/图片理解 → 只有 graphify 支持

## 提交与合并请求规范

### 提交消息（强制）

- 提交信息遵循 Conventional Commits：`feat(scope): ...`、`fix(scope): ...`、`refactor(scope): ...`、`docs(scope): ...`、`test(scope): ...`、`chore(scope): ...`。
- `scope` 填写单个模块名或改动类别，例如 `containers`、`files`、`settings`、`theme`、`test`、`docs`、`ci`。禁止省略 `scope`，禁止在 `scope` 里写多个类别。
- 提交消息正文使用中文描述改动内容，术语与 identifier 保持英文原名；一条消息只描述一组同类改动。

### 按模块或类别分组提交（强制）

- 一次任务涉及多个模块时，按模块或类别分别提交，每个提交只包含同一模块的改动；单模块的大批次也按合理文件数拆分提交，保持每个提交可独立评审与回滚，避免大提交。
- 提交顺序：先依赖层（模型、接口客户端、基础设施），再业务层（仓库、服务、状态），最后展示层、测试与文档。
- 每个提交都要能独立通过当次门禁，禁止把失败状态带入后续提交。
- 多会话共用工作区时，提交必须用显式文件路径 `git add`，禁止 `git add -A` 与 `git add -u`，只提交本批次文件；发现其他会话的在途改动时不提交、不回退、不改动。

### PR

- PR 需保持小步提交；大改动先开 issue 确认范围。
- PR 必须包含：变更说明、测试结果、UI 变更截图（如适用）。
- 严禁在 issue、日志、截图中泄露密钥与敏感信息。

## 分支、发布与 CI

### 日常分支规则（强制）

- 默认直接在当前分支上修改与提交，不新建分支。小功能、缺陷修复、文档调整、规范更新都在当前分支完成。
- 当前协作者人数少，长期维持单主干。只有以下情况才新建分支：用户明确要求新建分支；改动跨多个模块且用户确认需要独立分支。
- 新建分支前必须得到用户明确同意，禁止把「准备提交」「改动较多」当作新建分支的理由。
- 分支命名使用小写中划线，反映改动主题。

### 发布分支与 tag

- 长期主干分支：`dev-v2`，与 1Panel 服务端 `dev-v2` 的单主干策略保持一致。
- `main` 分支计划移除，所有功能集成、稳定验证与发布准备均围绕 `dev-v2` 展开。
- Android APK 使用 tag 驱动发布：`debug-*`（Alpha）、`beta-*`（Beta 公开预览）、`pre-release-*`（Pre-Release）、`v*`（Release）。
- tag 来源约束：`debug` / `beta` / `pre-release` / `v*` 均必须来自 `dev-v2`。
- 版本号策略：当前默认仍采用客户端自身语义化版本（如 `v0.6.0`），与 1Panel V2 版本号同步的方案暂缓实施。

## 文档治理

### 核心原则

1. **先搜索，再创建** — 优先在现有文档中补充内容，避免碎片化。
2. **文档合并优先** — 多个相关主题应合并到同一文档的不同章节。
3. **文档更新优先于创建** — 现有文档可以满足需求时，更新现有文档。

### 允许的文档类型

- 核心规范：`README.md`、`AGENTS.md`、`CLAUDE.md`、`CHANGELOG.md`
- AI IDE 配置：`.kiro/steering/*.md`、`.cursorrules`、`.github/copilot-instructions.md`
- 架构与策略：`docs/development/*.md`（跨平台治理总纲 `cross_platform_ui_governance.md`；模块适配与原生 UI 工作流见本文对应章节）
- 上游参考（只读）：`docs/OpenSource/1Panel/**`

### 信息记录位置

| 信息类型 | 记录位置 |
|---------|---------|
| Bug 修复说明 | `test/bugfix/*_test.dart` 注释 |
| 功能变更说明 | Git commit message |
| 架构决策 | `agent-memory-mcp` (MCP 支持的 IDE) |
| 开发流程指导 | `.kiro/steering/*.md` 或 `AGENTS.md` |

### 维护本文件

- 同一主题只保留一处权威来源，其余位置引用章节名；新增通用规范只修改本文件。
- 能用机械检查覆盖的要求（lint、测试、脚本、CI）优先写成检查，无法机械检查的才写入本文条款。
- 一次性事故与排查过程写入台账条目，不自动升级为永久规则；新增条款前先确认既有代码、检查或文档能否覆盖。

## 安全与配置说明

- API 访问使用 1Panel API Key，禁止提交密钥或令牌。
- 分享日志或复现步骤时必须脱敏 IP、用户名、凭据。
