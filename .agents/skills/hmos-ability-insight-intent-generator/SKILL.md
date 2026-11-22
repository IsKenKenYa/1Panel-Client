---
name: hmos-ability-insight-intent-generator
description: |
  Generates OpenHarmony intent decorator code from user requirements with automatic decorator selection.
  Use when the user mentions "intent", "@InsightIntent", or needs to integrate app functionality with AI entry points.
  Provides decorator selection decision tree, parameter validation, build config checking, and compilation verification with auto-fix.
license: MIT
---

# OpenHarmony 意图装饰器代码生成器

你是一个辅助 OpenHarmony 应用生成意图的专家。通过分析用户需求，结合现有代码，生成正确的意图代码（装饰器 + 功能实现）。

## 🚨 底线（必须无条件遵守）

1. **禁止编造**：所有字段名、类型、导入语句必须严格遵循官方 API，不得自创。

2. **禁止省略检查**：每次生成前必须执行下文列出的所有强制检查步骤。

3. **按需阅读子文档（高效策略）**：

   - **先速读结构**：打开子文档后，快速浏览标题（`#`、`##`、`###`）、表格、代码块标题，了解文档包含哪些章节。

   - **再精读需要部分**：根据当前任务，优先精读最相关的 1-2 个章节（如“代码模板”“核心规则”“自检清单”）。如果信息不足，再继续阅读其他必要章节。

   - **禁止逐字通读**：不要从头到尾朗读整个文档，除非文档极短（<50 行）或需要理解完整上下文。

   - **每个步骤只阅读该步骤实际需要的文档**，采用“速读+精读”方式。

   - **🚫 禁止递归引用**：子文档中的链接仅用于索引，你在步骤 N 中**只应打开该步骤指定的子文档**。即使子文档内有其他链接，也不得自动打开，除非当前步骤明确要求。

---

## 装饰器选择决策树（简版）

> 详细决策流程请参阅 [`decorator_selection.md`](references/decorator_selection.md)

```text
用户需求
  │
  ├─ 用户明确指定装饰器类型？
  │    ├─ 是 → 检查技术可行性 → 可行则生成 / 不可行则提示降级方案
  │    └─ 否 ↓
  │
  ├─ URI/Deep Link 跳转？
  │    ├─ 是 → 优先 @InsightIntentLink（需配置 URI）
  │    └─ 否 ↓
  │
  ├─ 关键词匹配（返回/查询/计算等纯函数）?
  │    ├─ 是 → @InsightIntentFunctionMethod（需静态方法）
  │    └─ 否 ↓
  │
  ├─ 关键词匹配（打开/跳转固定页面）?
  │    ├─ 是 → @InsightIntentPage（需确认页面已注册）
  │    └─ 否 ↓
  │
  ├─ 用户明确提及"标准意图"/系统意图/预定义意图/schema？
  │    ├─ 是 → 标记为标准意图模式 → 搜索官方文档获取 schema 规范 → @InsightIntentEntry + schema 字段
  │    └─ 否 ↓
  │
  └─ 其他（操作/动态路由/无明确匹配） → @InsightIntentEntry（通用，无 schema）
```

------

## 关键约束检查清单（必须逐项确认）

### 🔴 Critical（违反即编译失败）

- **装饰器类型**：仅使用 `@InsightIntentEntry` / `@InsightIntentLink` / `@InsightIntentPage` / `@InsightIntentFunctionMethod` / `@InsightIntentForm` / `@InsightIntentEntity`，禁止自创。
- **导入语句**：必须包含装饰器、基类、命名空间（如 `insightIntent`）且均来自 `@kit.AbilityKit`。详见 [common_rules.md#5](references/common_rules.md#5)。
- **`build-profile.json5`**：`useNormalizedOHMUrl: true`，`compileSdkVersion >= 20` 且格式与 `compatibleSdkVersion` 完全一致。详见 [project_config_checks.md](references/project_config_checks.md)。
- **`insight_intent.json`**：使用对象数组格式 `[{ "srcEntry": "./ets/..." }]`，不能是字符串数组。
- **ArkTS 严格模式**：无解构赋值、无索引访问 `obj['prop']`、无 `any`/`unknown`、无不带接口的对象字面量返回。详见 [common_rules.md#1](references/common_rules.md#1)。
- **类属性初始化**：所有属性必须有初始值（如 `name: string = ''`），禁止 `| undefined` 联合类型。
- **`@InsightIntentEntry.parameters`**：必须为 `{ type: 'object', properties: {...} }`，不支持 `integer` 类型。
- **`boolean` 参数类型兼容性**：部分 SDK 版本对 `type: 'boolean'` 的参数注入存在兼容性问题，可能导致 `onExecute` 静默不执行。**建议改用法**：使用 `type: 'string'` + `enum: ['true', 'false']`，在 `onExecute` 内转 `boolean`。
- **标准意图 `schema` 字段**：当用户明确要求生成"标准意图/系统意图/预定义意图"时，必须在 `@InsightIntentEntry` 中填写 `schema` 字段（如 `schema: 'PlayGame'`），且 `schema` 名称、参数、返回值和 `domain` 必须与官方文档一致。禁止在自定义意图（无 `schema`）中凭空编造 `schema` 字段。
- **`@InsightIntentEntry` 返回值**：必须为 `Promise<insightIntent.IntentResult<T>>`，且 `result` 字段中包含 `resultDesc`。详见 [common_rules.md#2](references/common_rules.md#2)。
- **`@InsightIntentFunctionMethod` 组合**：必须同时使用 `@InsightIntentFunction()` 装饰类，且方法为 `static`，括号不可省略。
- **`@InsightIntentPage` 使用位置**：必须直接装饰页面 `struct`，不可创建单独意图类。
- **`@InsightIntentPage` 的 `navigationId` 和 `navDestinationName`**：**必填**。缺少会导致热启动白屏。`navigationId` 必须与 Navigation 组件 `.id()` 一致。
- **`@InsightIntentForm.onAddForm` 同步约束**：`onAddForm(want: Want): FormBindingData` 必须同步返回，**不可**声明为 `async` 或返回 `Promise<FormBindingData>`。违反会导致编译错误（基类签名不匹配）。

### 🟡 Warning（强烈建议，否则可能导致运行时错误或体验问题）

| 类别               | 规则摘要                                                     | 详见                                                         |
| :----------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| **错误处理**       | `catch` 中 `throw new Error()`，不直接 `throw error`         | [common_rules.md#1](references/common_rules.md#1)            |
| **参数安全**       | 可选属性用 `??` 提供默认值；路由参数用 `try-catch` 包裹      | [common_rules.md#1](references/common_rules.md#1)            |
| **字段命名**       | `@InsightIntentEntry` 用 `abilityName`，`@InsightIntentPage` 用 `uiAbility`；`executeMode` 必须是数组 | [common_rules.md#3](references/common_rules.md#3)            |
| **冷启动（综合）** | ① DB 就绪等待（`await dbUtils.ready()`）；② 模块顶层禁用 `getContext(this)`；③ `@InsightIntentFunctionMethod` 冷启动不经过 `onWindowStageCreate`，需 `onCreate` 初始化 + `getLastWindow` 窗口恢复 | [common_rules.md#4](references/common_rules.md#4)、[code_exploration.md#5](references/code_exploration.md#5) |
| **UI 渲染**        | `@InsightIntentPage` 的 Navigation 防白屏（延迟渲染）；Tab 切换用 `@Watch` + `onAppear` | [insight_intent_page.md](references/insight_intent_page.md)  |
| **参数传递**       | Navigation 架构使用 `LocalStorage` 而非 `AppStorage`         | [architecture_checks.md](references/architecture_checks.md)  |

### 🟢 Info（优化建议，提升代码质量）

- **`llmDescription`**：包含功能描述、触发词、参数必填性，100 字以内。详见 [llm_writing_guide.md](references/llm_writing_guide.md)。
- **`keywords`**：3-8 个，包含同义词和英文，避免宽泛词。
- **日志记录**：使用 `hilog` 记录关键步骤，便于调试。
- **性能**：避免在意图中执行耗时同步操作；异步操作使用 `async/await`。
- **复用**：优先使用项目已有的常量、数据模型、工具类，不重复造轮子。详见 [code_exploration.md#0](references/code_exploration.md#0)。

------

## 整体流程（必须按顺序执行）

### 1. 项目配置检查（强制）

👉 必须阅读：[project_config_checks.md](references/project_config_checks.md)

- 读取 `build-profile.json5`，检查 `useNormalizedOHMUrl` 和 `compileSdkVersion`。
- 确保格式一致（字符串/数字与 `compatibleSdkVersion` 相同）。
- 不满足则提示用户修改，并等待确认。

### 2. 分析应用架构 & 探索现有代码（强制）

👉 必须阅读：[architecture_checks.md](references/architecture_checks.md)、[code_exploration.md](references/code_exploration.md)

- **严格遵循 [code_exploration.md#0](references/code_exploration.md#0) 的“分层探索协议”**：先 Grep 探测架构，再读 2 个关键文件，再 Grep 提取接口，最后按需定点读单方法。
- **禁止**无差别读取整个目录。
- **禁止**凭空创造键名或重复实现已有工具类。
- **检查数据库工具类的异步正确性**：当意图需要复用数据库工具类的方法时，必须打开源码验证其内部是否正确 `await` 了异步操作。常见 bug：方法标记 `async` 但内部使用 `.then()` 未 `await`，导致方法提前返回空结果。如发现此类 bug，需先修复工具类再生成意图代码。
- **如果意图为 `@InsightIntentFunctionMethod`，必须执行 [code_exploration.md#5](references/code_exploration.md#5) “EntryAbility 冷启动兼容性强制检查清单”**。

### 3. 分析用户需求 & 选择装饰器

👉 必须阅读：[decorator_selection.md](references/decorator_selection.md)

- 根据需求匹配 6 种装饰器之一，按上方决策树快速判断。
- 若用户指定类型但技术上不可行，按降级路径处理。

#### 标准意图信息获取（仅当标记为标准意图模式时执行）

👉 必须阅读：[decorator_selection.md#标准意图处理流程](references/decorator_selection.md#标准意图处理流程)

- **标记为标准意图模式**后，必须用 `arkts_knowledge_search` 搜索该标准意图的完整规范（华为开发者网站为 CSR 渲染，`webfetch` 无法获取实际内容）：
  - 搜索格式：`标准意图 {意图名称} schema domain 参数 定义`
  - 示例：`标准意图 PlayGame schema domain 参数 定义`
  - 备用搜索词：`HarmonyOS {意图名称} 标准意图 schema`
  - 中文搜索词：`鸿蒙 {意图名称} 标准意图`
  - 若 `arkts_knowledge_search` 未返回完整结果，可尝试 `webfetch` 搜索以下官方文档作为补充：
    - 标准意图接入规范：[https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-access-specifications](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-access-specifications)
    - 标准意图开发步骤：[https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-decorator-development#%E9%80%9A%E8%BF%87%E6%84%8F%E5%9B%BE%E8%A3%85%E9%A5%B0%E5%99%A8%E5%BC%80%E5%8F%91%E6%A0%87%E5%87%86%E6%84%8F%E5%9B%BE](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-decorator-development#%E9%80%9A%E8%BF%87%E6%84%8F%E5%9B%BE%E8%A3%85%E9%A5%B0%E5%99%A8%E5%BC%80%E5%8F%91%E6%A0%87%E5%87%86%E6%84%8F%E5%9B%BE)

- **必须获取的信息**：
  - 标准 `schema` 名称（如 `"PlayGame"`）
  - `domain` 名称
  - 预定义参数列表、类型、必填性
  - 返回值结构
  - `intentVersion`
- **处理规则**：
  - 搜索到完整规范 → 使用获取到的信息填充装饰器
  - 搜索不到 → 退化为自定义意图并提示用户"未找到该标准意图的官方定义，将使用自定义意图替代"
- **生成代码时**：必须在 `@InsightIntentEntry` 装饰器中添加 `schema` 字段（如 `schema: 'PlayGame'`）

### 4. 阅读对应装饰器的详细规则

根据选中的装饰器，阅读 `references/` 下的对应文件：

> - [`insight_intent_entry.md`](references/insight_intent_entry.md) - `@InsightIntentEntry` 完整规范
> - [`insight_intent_link.md`](references/insight_intent_link.md) - `@InsightIntentLink` 完整规范
> - [`insight_intent_page.md`](references/insight_intent_page.md) - `@InsightIntentPage` 完整规范
> - [`insight_intent_function.md`](references/insight_intent_function.md) - `@InsightIntentFunctionMethod` 完整规范
> - [`insight_intent_form.md`](references/insight_intent_form.md) - `@InsightIntentForm` 完整规范
> - [`insight_intent_entity.md`](references/insight_intent_entity.md) - `@InsightIntentEntity` 完整规范

### 5. 生成代码（严格遵守规范）

👉 公共规范必须阅读：[common_rules.md](references/common_rules.md)
👉 自定义意图的 `llmDescription` 和 `keywords` 编写规范请阅读：[llm_writing_guide.md](references/llm_writing_guide.md)

- 所有对象字面量必须有显式接口。
- 禁止解构赋值、禁止 `any` / `unknown`。
- 类属性必须初始化，禁止 `| undefined` 联合类型。
- 返回值必须符合对应装饰器的类型要求，且包含 `resultDesc`。
- **标准意图（有 `schema`）禁止添加 `llmDescription` 和 `keywords`**：标准意图通过 schema 名称匹配，不依赖 LLM 关键词触发。这两个字段仅用于自定义意图。
- 如果生成的是 `@InsightIntentPage` 且页面包含 `Navigation`，必须插入防白屏代码模板（详见 [insight_intent_page.md](references/insight_intent_page.md)）。
- **`insightIntent.ExecuteResult.result` 构建**：`result` 类型为 `Record<string, Object>`，必须用索引赋值方式构建（`resultData['key'] = value`）。详见 [common_rules.md#1](references/common_rules.md#1)。
- **如果意图访问数据库，必须检查并处理 DB 未初始化的情况**：不能假设 DB 已就绪。必须在查询前等待 DB 就绪信号（`await dbUtils.ready()` 或轮询 `isInitSuccess()`），超时未就绪则返回错误。
- **若使用 `@InsightIntentFunctionMethod` + `AppStorage` 中转模式**：评估冷启动时读到默认值是否可接受。若不可接受，应改用 `@InsightIntentEntry`；若可接受，需在返回结果的 `resultDesc` 中明确标注数据来源（如“应用未启动，返回默认值”）。
- **如果应用为 Tabs 架构，`@InsightIntentEntry` 必须使用 `AppStorage.setOrCreate` 信号驱动，禁止使用 `windowStage.loadContent` + `LocalStorage` 方式传递参数。**
- **如果目标页涉及硬件初始化（相机/传感器/播放器等），必须检查目标页 `aboutToAppear` 是否标记 `async`** — 若是，`build()` 不等其异步操作完成即执行，`onLoad` 中调用的硬件初始化可能在 permission/DB 未就绪时触发。详见 [common_rules.md#6](references/common_rules.md#6)。
- **如果目标页硬件工具类为 singleton（`getInstance()`），需检查其 `release()`/`close()` 方法是否有防重入保护** — 热启动时两次调用 `releaseCamera` 可能互相干扰。详见 [code_exploration.md#第3层](references/code_exploration.md#第3层)。
- **如果生成的是 `@InsightIntentForm`，必须严格执行 [insight_intent_form.md#核心规则](references/insight_intent_form.md#核心规则) 中的完整实现清单**（含 `onAddForm` 同步约束、`DataProvider`/`FormRegistry` 文件读写、轮询兜底、主应用推送等）。

### 6. 写入文件 & 配置

👉 必须阅读：[write_file_guide.md](references/write_file_guide.md)

- **新增文件**：在 `entry/src/main/ets/insightintents/` 下创建 `.ets` 文件，并更新 `insight_intent.json`（对象数组格式）。
- **修改现有文件**（如添加 `@InsightIntentPage`）：直接编辑，**无需**更新 `insight_intent.json`。
- 写入前使用 `AskUserQuestion` 工具征求用户同意。

### 7. 代码逻辑自检

- 逐项对照 [troubleshooting.md](references/troubleshooting.md) 中的所有检查点
- 结合 [common_rules.md](references/common_rules.md) 和对应装饰器文档，验证生成的代码
- 确保没有遗留任何已知的编译或运行时错误
- **运行时场景自检（@InsightIntentEntry 页面跳转型 + @InsightIntentFunctionMethod 必须）**：
  - **冷启动**：应用未运行 → 调用意图 → 页面正确显示 + 功能正常
  - **热启动（同 URL）**：应用在前台（目标页已打开）→ 调用意图（目标页相同）→ 页面无需重建但功能正常（尤其硬件类功能如相机/传感器/播放器）
  - **热启动（不同 URL）**：应用在前台 → 调用意图（目标页不同）→ 新页面正确加载 + 功能正常
  - 验证通过标准：三场景均无崩溃、白屏、功能缺失
- **空白页面检查（@InsightIntentEntry 页面跳转型 + @InsightIntentPage）**：
  - ☐ 若意图使用 `loadContent` 加载目标页，确认目标页的 `aboutToAppear` 中已完成数据初始化，字段初始值不为 `undefined`（应为 `''`、`0`、`[]` 等安全空值）
  - ☐ 若目标页依赖 `router.getParams()`，已改用 AppStorage 或静态类传递数据，并确保字段初始化时不依赖 `router.getParams()`

------

## 常见问题

- 意图未生效 → 检查 `insight_intent.json` 配置及文件路径。
- 编译错误 `Schema validate failed` → `compileSdkVersion` 格式与 `compatibleSdkVersion` 不一致。
- 运行时 16000001 → `abilityName` 与 `module.json5` 中的 Ability 名称不匹配。
- 更多错误参考 [troubleshooting.md](references/troubleshooting.md)。

------

## 子文档索引

| 文档                                                         | 内容                                                         |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| [common_rules.md](references/common_rules.md)                | **公共规则**：ArkTS 严格模式、返回值规范、字段命名、冷启动约束、导入规范 |
| [project_config_checks.md](references/project_config_checks.md) | `build-profile.json5` 完整检查流程、格式一致性               |
| [architecture_checks.md](references/architecture_checks.md)  | Navigation vs Router 识别、参数传递方案                      |
| [code_exploration.md](references/code_exploration.md)        | **分层探索协议**、冷启动窗口恢复模板、EntryAbility 兼容性检查清单 |
| [decorator_selection.md](references/decorator_selection.md)  | 装饰器选择决策树、场景匹配、降级路径（完整版）               |
| [arkts_strict_rules.md](references/arkts_strict_rules.md)    | ArkTS 严格模式详细版（common_rules.md 的扩展）               |
| [write_file_guide.md](references/write_file_guide.md)        | 文件写入流程、`insight_intent.json` 配置                     |
| [write_config_file.md](references/write_config_file.md)      | `insight_intent.json` 配置格式详细说明                       |
| [jsonschema_reference.md](references/jsonschema_reference.md) | JSON Schema 参数定义参考                                     |
| [troubleshooting.md](references/troubleshooting.md)          | 编译错误、运行时错误解决方案                                 |
| [llm_writing_guide.md](references/llm_writing_guide.md)      | `llmDescription` 和 `keywords` 编写规范                      |
| [insight_intent_*.md](references/)                           | 各装饰器详细规范（entry, link, page, function, form, entity） |

## 相关资源

### 官方文档
- [标准意图接入规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-access-specifications) — 包含所有标准意图的 schema、domain、参数和返回值定义
- [标准意图开发步骤](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-decorator-development#%E9%80%9A%E8%BF%87%E6%84%8F%E5%9B%BE%E8%A3%85%E9%A5%B0%E5%99%A8%E5%BC%80%E5%8F%91%E6%A0%87%E5%87%86%E6%84%8F%E5%9B%BE)
- [意图调试工具](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-debug)
- [通过小艺触发意图调试](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-skill-all-rec-dp-self-validation-decorator)

### 调试技巧

1.**启用详细日志**：

```typescript
const LOG_TAG: string = 'MyIntent';
hilog.debug(0x0000, LOG_TAG, 'Debug info: %{public}s', data);
```

2.**使用 DevEco Studio 调试器**：在 `onExecute()` 等方法中设置断点，查看执行器实例的属性值。

3.**检查意图注册**：查看 `insight_intent.json` 配置，确认文件路径正确。

4.**测试意图调用**：使用[意图调试工具](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-debug)测试，检查日志输出，验证返回结果。