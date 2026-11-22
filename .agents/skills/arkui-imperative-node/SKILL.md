---
name: arkui-imperative-node
description: 指导开发者快速接入 ArkUI 命令式节点（BuilderNode/FrameNode/RenderNode）。当用户提到"命令式节点""BuilderNode""FrameNode""RenderNode""动态挂载""预创建组件""命令式框架""NodeContainer""NodeController""节点不显示""dispose""内存释放""@Reusable 联用""aboutToDisappear 不触发""冻结 update""文件路径""组件信息"等关键词时使用此 Skill。覆盖场景判断、API 选型、骨架代码生成、文件路径输入与上下文感知方案生成和常见问题排障五个能力。
license: MIT
metadata:
  author: arkui-team
  version: "1.0.0"
---

# ArkUI 命令式框架快速接入

本 Skill 指导开发者完成命令式节点的场景判断、API 选型、骨架代码生成和常见问题排障，帮助开发者明确使用场景并完成接入，防止滥用，降低使用门槛和排障成本。

## 场景分流决策树

当开发者请求使用命令式节点时，按以下三级决策树进行分流。每级以需求语义（是否需要/选哪个 API/如何接入）判定。

```
开发者输入：场景描述或代码
  │
  ├─ 开发者是否不确定是否需要命令式节点？
  │    ├─ 是 → 场景判断（AC-1）
  │    │    ├─ 场景为"运行时动态增删组件，需灵活挂载到不同父节点" → 建议使用（R-1）
  │    │    ├─ 场景为"提前预创建组件优化初始化耗时" → 建议使用 BuilderNode（R-2）
  │    │    └─ 场景可在 build 内通过 ForEach/LazyForEach/if-else 满足 → 不建议使用（R-3）
  │    │
  │    └─ 否 → L2：选哪个 API？
  │         ├─ 需求含"整体控制节点树 + 内部 @Builder 声明式 + 状态管理"
  │         │    → BuilderNode（AC-2.1）
  │         ├─ 需求含"命令式控制内部树 + 自定义测量/布局/绘制"
  │         │    → FrameNode（AC-2.2）
  │         ├─ 需求含"仅渲染属性 + 自定义绘制 + 不参与布局和事件"
  │         │    → RenderNode（AC-2.3）
  │         ├─ 需求不明确 → 读取 [API 选型决策矩阵](references/api-selection.md) 辅助判断
  │         │
  │         └─ 确定 API 后（含上述全部分支）→ L3：生成骨架代码
  │              ├─ BuilderNode → 加载 [模板](templates/builder-node-template.ets)（AC-3.1）
  │              ├─ FrameNode → 加载 [模板](templates/frame-node-template.ets)（AC-3.2）
  │              └─ RenderNode → 加载 [模板](templates/render-node-template.ets)（AC-3.3）
  │
  ├─ 开发者提供了文件路径和组件信息？
  │    ├─ 是 → 读取代码文件 → 分析组件上下文（识别组件类型/build结构/已有节点树）
  │    │    → 按 L2 选型 → 输出修改后的完整代码（AC-6, AC-7）
  │    └─ 否 → 继续 L1 场景判断流程
  │
  └─ 开发者描述的是已有问题（排障分支）
       ├─ "节点置空后内存没释放" → [dispose 排障](references/troubleshooting/dispose-memory.md)
       ├─ "BuilderNode 创建后不显示" → [节点不显示排障](references/troubleshooting/node-not-display.md)
       ├─ "@Reusable/@ReusableV2 联用 JSCrash" → [@Reusable 排障](references/troubleshooting/reusable-conflict.md)
       ├─ "aboutToDisappear 没触发" → [aboutToDisappear 排障](references/troubleshooting/about-to-disappear.md)
       ├─ "冻结后 update 不更新" → [冻结 update 排障](references/troubleshooting/freeze-update.md)
       ├─ "@Builder 内 Repeat 报错" → SKILL.md 反模式章节（C-6）
       ├─ "JSON.stringify crash" → SKILL.md 反模式章节（C-7）
       ├─ "复用事件不传递" → [@Reusable 排障](references/troubleshooting/reusable-conflict.md)（reuse/recycle）
       └─ "@Link/@Consume 状态不更新" → [@Reusable 排障](references/troubleshooting/reusable-conflict.md)（状态同步跨界）
```

> **路由唯一性规则（强制）：** 决策树每个分支必须路由至唯一类别，禁止同时列举两种或多种 API。例如：需求含"自定义绘制"且不含"命令式控制内部树"时，必须直接路由至 RenderNode，不得同时提及 FrameNode 作为备选项。

## API 选型速查

| API | 核心特征 | 适用场景 | API 版本 | 模板 |
|---|---|---|---|---|
| BuilderNode | 整体控制节点树 + 内部 @Builder 声明式 + 状态管理 | 动态挂载声明式组件树、预创建组件 | API 12+ | [模板](templates/builder-node-template.ets) |
| FrameNode | 命令式控制内部树 + 自定义测量/布局/绘制 | 第三方框架节点树、混合显示 | API 12+ | [模板](templates/frame-node-template.ets) |
| RenderNode | 仅渲染属性 + 自定义绘制 + 不参与布局和事件 | 轻量渲染、自定义绘制 | API 12+ | [模板](templates/render-node-template.ets) |

### 多节点池管理

当开发者需要管理多个 BuilderNode，在不同位置动态挂载/卸载/转移时，加载 [池管理指导](references/builder-node-pool-guide.md) 生成池管理框架。

| 场景 | 路由到 |
|------|--------|
| 多个 BuilderNode 动态挂载/卸载/转移 | [池管理指导](references/builder-node-pool-guide.md) |

## 反模式警告：BuilderNode 子节点禁止使用 @Reusable

> **此节为生成代码前的强制检查项，违反会导致 JSCrash。**

BuilderNode 的复用机制与 @Reusable 装饰器的复用机制相互冲突。当 BuilderNode 的子节点为自定义组件时，不支持该自定义组件使用 @Reusable 装饰器标记，否则将导致应用程序触发 JSCrash。

**禁止写法（触发 JSCrash）：**

```typescript
// ❌ 错误：BuilderNode 的 @Builder 内直接使用 @Reusable 自定义组件
@Builder
function buildNode(param: Params) {
  ReusableChildComponent({ item: param.item })  // JSCrash: @Reusable 与 BuilderNode 冲突
}

@Reusable
@Component
struct ReusableChildComponent {
  // ...
}
```

**正确写法：**

```typescript
// ✅ 正确：用普通自定义组件包裹 @Reusable 组件
@Builder
function buildNode(param: Params) {
  ChildComponent2({ item: param.item })  // 普通组件包裹
}

@Component
struct ChildComponent2 {
  build() {
    ReusableChildComponent({ item: this.item })  // @Reusable 组件被普通组件包裹
  }
}
```

**生成代码前的自检规则：**
1. 检查生成的 @Builder 内是否直接使用了 @Reusable 标记的自定义组件 — **如果出现，必须用普通组件包裹**
2. 若需传递复用事件，使用 BuilderNode 的 `reuse(params)` 和 `recycle()` 接口，而非 @Reusable

## 反模式警告：BuilderNode 仅可作为叶子节点

> **此节为生成代码前的强制检查项，违反会导致节点行为异常。**

BuilderNode 仅可作为叶子节点进行使用。如有更新需要，建议通过 BuilderNode 中的 `update` 方式触发更新，不建议通过 BuilderNode 中获取的 RenderNode 对节点进行修改操作。

**禁止写法：**

```typescript
// ❌ 错误：在 BuilderNode 获取的 RenderNode 上直接修改节点
const builderNode = new BuilderNode(context);
builderNode.build(wrapBuilder(buildText), params);
const renderNode = builderNode.getFrameNode()?.getRenderNode();
renderNode?.children  // 不可通过 RenderNode 修改 BuilderNode 内部节点
```

**正确写法：**

```typescript
// ✅ 正确：通过 update 方法更新 BuilderNode 内部组件
const builderNode = new BuilderNode(context);
builderNode.build(wrapBuilder(buildText), params);
builderNode.update(newParams);  // 通过 update 触发声明式更新
```

## 反模式警告：build 前调用 getFrameNode 返回 null

> **此节为生成代码前的强制检查项，违反会导致节点不显示。**

一个新建的 BuilderNode 在 `build` 之后才能通过 `getFrameNode` 获取到一个指向根节点的 FrameNode 对象，否则返回 null。null 节点挂载后不会显示。

**禁止写法：**

```typescript
// ❌ 错误：build 前调用 getFrameNode
const builderNode = new BuilderNode(context);
const frameNode = builderNode.getFrameNode();  // 返回 null！
rootNode.appendChild(frameNode);  // 挂载 null，节点不显示
builderNode.build(wrapBuilder(buildText), params);  // build 在 getFrameNode 之后
```

**正确写法：**

```typescript
// ✅ 正确：先 build 再 getFrameNode
const builderNode = new BuilderNode(context);
builderNode.build(wrapBuilder(buildText), params);  // 先 build
const frameNode = builderNode.getFrameNode();        // 再获取，返回有效 FrameNode
rootNode.appendChild(frameNode);                     // 挂载有效节点
```

## 反模式警告：节点双挂导致不显示

> **此节为生成代码前的强制检查项，违反会导致节点不显示。**

同一个 FrameNode 只能挂载到一个父节点下。如果将同一个节点挂载到多个父节点，只有最后一次挂载生效，之前的挂载会被移除，可能导致节点不显示。

**禁止写法：**

```typescript
// ❌ 错误：同一个节点挂载到两个父节点
const builderNode = new BuilderNode(context);
builderNode.build(wrapBuilder(buildText), params);
const frameNode = builderNode.getFrameNode();

parentA.appendChild(frameNode);  // 挂载到 parentA
parentB.appendChild(frameNode);  // 又挂载到 parentB — parentA 下的节点被移除！
```

**正确写法：**

```typescript
// ✅ 正确：确保节点只挂载到一个父节点
const builderNode = new BuilderNode(context);
builderNode.build(wrapBuilder(buildText), params);
const frameNode = builderNode.getFrameNode();

parentA.appendChild(frameNode);  // 只挂载到一个父节点
```

## 反模式警告：@Builder 内禁止直接使用 Repeat

> **此节为生成代码前的强制检查项，违反会导致编译错误或渲染异常。**

BuilderNode 仅支持在自定义组件（`@Component`/`@ComponentV2`）中使用 Repeat 组件。`@Builder` 函数体内不能直接使用 Repeat，需将 Repeat 放在自定义组件内部，再在 @Builder 中使用该自定义组件。

**禁止写法：**

```typescript
// ❌ 错误：@Builder 内直接使用 Repeat
@Builder
function buildList(params: Params) {
  Repeat(params.items)  // 编译错误 / 渲染异常
    .each((item) => { Text(item) })
}
```

**正确写法：**

```typescript
// ✅ 正确：Repeat 放在自定义组件内，@Builder 使用该组件
@Component
struct ListContent {
  @Prop items: string[] = [];
  build() {
    Repeat(this.items)
      .each((item) => { Text(item) })
  }
}

@Builder
function buildList(params: Params) {
  ListContent({ items: params.items })
}
```

## 反模式警告：BuilderNode 对象禁止 JSON 序列化

> **此节为生成代码前的强制检查项，违反会导致 JSCrash。**

BuilderNode 对象不支持使用 JSON 序列化。BuilderNode 内部持有后端实体节点的引用关系（含循环引用），`JSON.stringify(builderNode)` 会因循环引用导致 JSCrash。

**禁止写法：**

```typescript
// ❌ 错误：对 BuilderNode 对象调用 JSON.stringify
const builderNode = new BuilderNode(context);
builderNode.build(wrapBuilder(buildText), params);
const json = JSON.stringify(builderNode);  // JSCrash！循环引用
```

**正确写法：**

```typescript
// ✅ 正确：只序列化业务数据，不序列化 BuilderNode 对象
const params = new Params('hello');
const json = JSON.stringify(params);  // 序列化参数对象，安全
```

## 生成代码前的自检规则

生成骨架代码前后，必须逐项核对以下检查清单。Critical 项违反会导致编译错误或运行时崩溃，必须修复；Warning 项违反会导致功能异常，建议修复。

**骨架生成通用规则（仅适用于从零生成骨架代码，不适用于排障修复）：** 从零生成 `@Entry @Component` 页面骨架时必须：
1. 使用 `@State controller: XxxController | undefined` 声明控制器（不能用 `private`），并提供 Dispose + Create 按钮交互。Dispose 按钮中先调 dispose 再置 `this.controller = undefined`，确保 UI 刷新清空内容。
2. `build()` 方法的根节点必须是容器组件（`Column` / `Row` / `Stack` 等），不能直接放 `NodeContainer` 或 `Button` 作为根节点（ArkTS 编译要求 `@Entry` 的 build 根节点为容器组件）。
3. 颜色值使用 ARGB 数字格式（`0xAARRGGBB`），不使用对象字面量 `{ alpha, red, green, blue }`（ArkTS 禁止无类型对象字面量）。

**排障修复规则：** 排障修复只改问题点，保持 bad case 其余代码不变。修复后的代码与 bad case 的差异应最小化，仅体现修复方向。

### Critical（必须修复）

- [ ] **C-1：BuilderNode 子节点禁止 @Reusable** — @Builder 内直接使用 @Reusable 自定义组件会触发 JSCrash，必须用普通组件包裹
- [ ] **C-2：BuilderNode build 后才能 getFrameNode** — build 前调用 getFrameNode 返回 null，挂载后不显示
- [ ] **C-3：节点不可双挂** — 同一 FrameNode 只能挂载到一个父节点，双挂导致前一次挂载被移除
- [ ] **C-4：骨架含四结构** — 创建、挂载、占位容器（NodeContainer）、dispose 释放四个核心结构必须完整
- [ ] **C-5：BuilderNode 仅叶子节点** — 不可通过 BuilderNode 的 RenderNode 修改内部节点，需用 update 更新
- [ ] **C-6：@Builder 内禁止直接使用 Repeat** — Repeat 仅支持在自定义组件中使用，@Builder 内直接用 Repeat 会编译错误或渲染异常，需包裹在 @Component 内
- [ ] **C-7：BuilderNode 对象禁止 JSON 序列化** — JSON.stringify(builderNode) 因循环引用导致 JSCrash，只序列化业务数据参数

### Warning（建议修复）

- [ ] **W-1：dispose 必须主动调用** — BuilderNode/FrameNode/RenderNode 对应后端实体节点，置空前端对象不释放后端，需主动 dispose
- [ ] **W-2：aboutToDisappear 不会触发** — BuilderNode 不是声明式组件，不触发 @Component 生命周期，需主动 dispose 管理生命周期
- [ ] **W-3：冻结态 update 不生效** — BuilderNode 处于冻结态时 update 不更新，这是正常行为，需解冻后再 update
- [ ] **W-4：标注 API 版本** — 骨架代码中标注 API 版本要求（BuilderNode/FrameNode/RenderNode 基础 API 12+）

## 排障检查项

检查命令式节点使用中的常见问题。读取开发者代码，按以下检查规则逐项分析，发现问题时输出诊断+修复建议+文档链接。检查项与分类仅用于内部核对；发现指向实际原因和修复建议，不输出未命中项。

**排障输出原则：**

1. **good case 零建议**：代码已正确处理某项检查（如已调用 dispose、已正确挂载、已用普通组件包裹）时，确认正确性即可，不追加防御性建议，只输出"代码正确，未发现问题"。
2. **修改建议只限命中的问题点**：修复方向唯一且明确的问题（如 @Builder 内 Repeat、JSON 序列化），修改建议只限该唯一修复方向；禁止追加 dispose/生命周期等与本次问题无关的范围外修改建议。
3. **跨范围提示的条件**：若确需附带范围外提示，必须显式标注"超出本次问题范围，不作为修改建议"；无法如此标注时，直接略去不提。
4. **输出完整代码**：排障修复必须给出修复后的完整可运行代码（遵循排障修复规则：只改问题点、其余代码不变），不得只给局部代码片段。

| 检查项 | 检查规则 | 详细规则 |
|---|---|---|
| @Reusable/@ReusableV2 冲突 | 检查 @Builder 内直接子组件是否标注了 @Reusable（V1）或 @ReusableV2（V2），两者都会 JSCrash，需用普通 @Component/@ComponentV2 包裹 | [检查规则](references/troubleshooting/reusable-conflict.md) |
| 节点不显示 | 检查双挂（同一 controller 绑定多个 NodeContainer）、build前getFrameNode、makeNode重复创建、RenderNode未上树、缺selfIdealSize、@Builder根为语法节点 | [检查规则](references/troubleshooting/node-not-display.md) |
| dispose 释放 | 检查是否调用 dispose()（不只置null）、dispose后是否继续访问、循环引用、isDisposed守卫 | [检查规则](references/troubleshooting/dispose-memory.md) |
| aboutToDisappear 不触发 | 检查是否依赖 aboutToDisappear 做清理（BuilderNode 不触发生命周期，dispose 也不会同步触发回调；应将清理逻辑剪切前移到释放方法中、dispose 前显式执行并删除回调中的原语句，避免 GC/进程退出时重复执行，再在宿主 aboutToDisappear 中兜底调用） | [检查规则](references/troubleshooting/about-to-disappear.md) |
| 冻结态 update 不生效 | 检查是否在冻结态调用 update（冻结链需三条件：NodeContainer 宿主 freezeWhenInactive: true + 宿主不活跃（所在 NavDestination 被覆盖/Tab 未选中/LazyForEach 离屏）+ inheritFreezeOptions(true)；Navigation 首页不冻结。冻结时 update 缓存不生效、解冻自动应用，设计行为非缺陷） | [检查规则](references/troubleshooting/freeze-update.md) |
| @Builder 内 Repeat | 检查 @Builder 函数体内是否直接使用 Repeat（仅支持在自定义组件中使用，运行时 crash） | [检查规则](references/troubleshooting/repeat-in-builder.md) |
| JSON 序列化 | 检查是否对 BuilderNode 对象调用 JSON.stringify（循环引用导致 JSCrash） | [检查规则](references/troubleshooting/json-serialize-crash.md) |
| reuse/recycle 复用事件未传递 | 检查 @Reusable 组件的 aboutToReuse/aboutToRecycle 是否手动调用了 builderNode.reuse()/recycle()（BuilderNode 隔断复用事件） | [检查规则](references/troubleshooting/reuse-recycle-transfer.md) |
| @Link/@Consume 状态同步跨界 | 检查 BuilderNode 内部组件是否使用了 @Link（不支持）或 @Consume/@Provide（默认隔断，API 20+ 可开启） | [检查规则](references/troubleshooting/state-sync-crossing.md) |

## 工作流程

1. **收集输入** — 获取开发者的场景描述或代码。判断属于场景判断、API 选型、骨架生成还是排障。
   - 若开发者提供了文件路径：使用 Read 工具读取指定 .ets 文件，分析组件上下文（组件类型、build结构、已有节点树），读取 [代码上下文分析规则](references/code-context-analysis.md)
2. **异常检查** — 验证需求是否与命令式节点相关。不相关时提示"需求与命令式节点无关"，不臆造方案。
3. **场景分流** — 按三级决策树判定：场景判断 → API 选型 → 骨架生成，或排障分支。
4. **读取详细规则** — **必须用 Read 读取命中检查项对应的 references 详细规则文件**，再核对成立条件。不得仅凭 SKILL.md 的一行摘要直接输出方案。
5. **输出方案** — 根据分流结果输出场景判断结论+依据、API 选型推荐+决策依据、骨架代码（加载对应模板）、或排障方案+修复建议。
6. **自检** — 生成代码后逐项核对自检规则清单（C-1~C-7, W-1~W-4），确保无反模式。

## 异常输入处理

当开发者输入满足以下任一条件时，输出明确的无法处理提示并请求补充输入，不臆造方案：

1. **需求描述为空** — 提示"请提供场景描述或需求说明（如动态挂载组件、预创建组件、自定义绘制等）"
2. **需求与命令式节点无关** — 提示"需求与命令式节点（BuilderNode/FrameNode/RenderNode）无关，请提供相关需求"
3. **排障描述缺少症状** — 提示"请描述具体问题现象（如节点不显示、内存未释放、JSCrash 等）"
4. **API 选型条件不明确** — 提示"请说明需求维度：是否需要声明式构建内部树？是否需要自定义测量布局？是否仅需要渲染？"

## 共同边界

- 只读开发者提供的代码和描述，输出指导方案和骨架代码，不直接修改应用代码。
- 不编造 API 签名、版本号或行为事实；API 事实以 OpenHarmony SDK 发布声明为准。
- 骨架代码为最小可运行模板，不含完整业务逻辑；开发者需按实际需求填充。
- 排障建议为参考方案，开发者需结合实际代码验证。
- 区分 API 版本（BuilderNode/FrameNode/RenderNode 基础 API 12+），按工程 API 版本核对适用条件。
- 命令式节点检查不扩张为声明式 UI 全链路分析；跨模块问题转交对应 Skill。

## 输出检查

- [ ] 场景判断输出包含判断结论和判断依据，不仅给结论
- [ ] API 选型输出包含推荐 API 和决策依据（适用条件+选择理由），不仅给结论
- [ ] 骨架代码包含创建、挂载、占位容器、dispose 释放四个核心结构
- [ ] 骨架代码标注 API 版本要求
- [ ] 生成代码后已逐项核对自检规则清单（C-1~C-7, W-1~W-4）
- [ ] 排障输出包含问题原因分析和修复建议
- [ ] 不编造 API 签名、版本号或行为事实；未知条件明确标记

## 参考资源

| 资源 | 路径 | 说明 |
|---|---|---|
| 场景判断规则 | `references/scene-judgment.md` | 何时建议/不建议使用命令式节点（R-1~R-3） |
| API 选型决策矩阵 | `references/api-selection.md` | BuilderNode/FrameNode/RenderNode 选型（R-4~R-6） |
| BuilderNode 指导 | `references/builder-node-guide.md` | 创建/build/挂载/dispose 使用指导（R-7） |
| FrameNode 指导 | `references/frame-node-guide.md` | 创建/挂载/getRenderNode/dispose 使用指导（R-8） |
| RenderNode 指导 | `references/render-node-guide.md` | 创建/挂载/draw/dispose 使用指导（R-9） |
| 池管理指导 | `references/builder-node-pool-guide.md` | NodePool+NodeItem 架构、动态转移（R-10） |
| dispose 排障 | `references/troubleshooting/dispose-memory.md` | 内存未释放排障（R-11） |
| 节点不显示排障 | `references/troubleshooting/node-not-display.md` | 节点双挂排障（R-12） |
| @Reusable 排障 | `references/troubleshooting/reusable-conflict.md` | 复用冲突排障（R-13） |
| aboutToDisappear 排障 | `references/troubleshooting/about-to-disappear.md` | 生命周期说明（R-14） |
| 冻结 update 排障 | `references/troubleshooting/freeze-update.md` | 冻结态说明（R-15） |
| 代码上下文分析 | `references/code-context-analysis.md` | 文件路径输入→读取代码→分析组件上下文（R-16） |
| Repeat 排障 | `references/troubleshooting/repeat-in-builder.md` | @Builder 内 Repeat 运行时 crash 排障（R-17） |
| JSON 序列化排障 | `references/troubleshooting/json-serialize-crash.md` | JSON.stringify 循环引用 JSCrash 排障（R-18） |
| 复用事件排障 | `references/troubleshooting/reuse-recycle-transfer.md` | reuse/recycle 复用事件未传递排障（R-19） |
| 状态同步排障 | `references/troubleshooting/state-sync-crossing.md` | @Link/@Consume 跨界状态同步排障（R-20） |
| BuilderNode 模板 | `templates/builder-node-template.ets` | BuilderNode 骨架代码模板 |
| FrameNode 模板 | `templates/frame-node-template.ets` | FrameNode 骨架代码模板 |
| RenderNode 模板 | `templates/render-node-template.ets` | RenderNode 骨架代码模板 |

测试用例（test-cases/）不属于运行知识，正常诊断不读取其中的预期答案。
