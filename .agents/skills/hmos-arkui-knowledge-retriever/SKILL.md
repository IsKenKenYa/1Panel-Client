---
name: hmos-arkui-knowledge-retriever
description: ArkUI 知识检索层，按问题语境自动路由到 ArkTS 声明式或 NDK(C-API)知识库进行精准检索，不涉及代码生成或修改。触发场景：(1) 用户查询 ArkUI/ArkTS API 用法、参数细节或版本支持 (2) 验证组件/装饰器的正确用法 (3) 排查 ArkUI 编译错误码或运行时异常 (4) 询问状态管理 V1/V2 差异或迁移 (5) 查询 NDK / Native / C-API 接口或头文件 (6) 其他 skill 调用检索获取 API 证据。
---

# ArkUI Knowledge Retriever

## 使用场景

| 场景 | 用户输入特征 | 示例 |
|------|------------|------|
| API 用法查询 | 询问特定 API 的参数、类型、版本 | "@Local 装饰器怎么用"、"Navigation 页面跳转参数" |
| 用法验证 | 已有代码需确认 API 正确性 | "ForEach 的第三个参数是什么"、"@Param 能不能装饰组件内变量" |
| 错误排查 | 编译错误码或运行时异常 | "错误码 100060 是什么意思"、"LazyForEach 数据源报错" |
| 方案对比 | 多个技术方案需要选型 | "V1 和 V2 状态管理有什么区别"、"Navigation 和 Router 哪个好" |
| NDK/C-API 查询 | 询问 Native 侧 C 接口、头文件、NDK 用法 | "OH_NativeXComponent 怎么用"、"native_node 如何创建节点" |
| 被其他 skill 调用 | develop-skill 在方案设计后调检索验证 | 开发流程中 Step 2 的针对性检索环节 |

## 核心原则

1. **版本敏感**：关注 API version 标注和废弃标记
2. **来源标注**：每个关键结论标注知识库来源路径

## 工作流程

### Step 1: 理解查询意图 + 判断技术栈语境

分析用户问题，确定检索目标。本 skill 维护两个独立知识库，`run.py` 会根据查询语境**自动路由**：

| 技术栈 | 信号词 | 路由到 |
|--------|--------|--------|
| ArkTS 声明式 | `@`装饰器、ArkTS、声明式、ForEach/LazyForEach、状态管理、NavDestination | `references/knowledges/` |
| NDK / C-API | NDK、capi、native、OH_Native*、ArkUI_Native*、native_node、napi、C++ | `references/ndk-knowledges/` |
| 跨域(两库合查) | XComponent、EGL/OpenGLES、surface | 两个库都查并合并 |

> 路由由 `retriever.detect_domain()` 自动完成；可用 `--domain ndk|arkts|both` 手动覆盖。无强信号时默认按 ArkTS 处理。关键词提取策略：

| 查询类型 | 关键词提取策略 | 示例 |
|---------|--------------|------|
| 具体 API 查询 | 提取 API 名称 + 所属领域 | "@Local 装饰器" → `@Local 组件内状态` |
| 概念性问题 | 提取核心概念词 | "V1 V2 有什么区别" → `V1 V2 状态管理 迁移` |
| 错误排查 | 提取错误码或异常关键词 | "报错 100005" → `错误码 100005` |
| 用法验证 | 提取待验证的 API + 用法描述 | "ForEach 第三个参数" → `ForEach keyGenerator` |
| 被其他 skill 调用 | 直接使用调用方提供的关键词 | 开发流程中的针对性检索 |

### Step 2: 执行检索

默认**自动路由**：无需指定知识库，`run.py` 根据 query 语境选 ArkTS 或 NDK 库（跨域两库合查）。返回结果中 `routed_to` 标明实际查询的库，每条结果的 `knowledge_base` 字段标明来源库。

```bash
# ArkTS 查询（自动路由到 knowledges）
python {skill_dir}/scripts/run.py query "LazyForEach IDataSource" --top-k 3 --include-code --format json

# NDK / C-API 查询（自动路由到 ndk-knowledges）
python {skill_dir}/scripts/run.py query "OH_NativeXComponent 怎么用" --top-k 3 --include-code --format json

# 跨域查询（XComponent 等，两库合查）
python {skill_dir}/scripts/run.py query "XComponent surface" --top-k 5 --include-code --format json

# 手动指定技术栈（覆盖自动路由）
python {skill_dir}/scripts/run.py query "native_node" --domain ndk --top-k 3 --include-code --format json

# 按分类精确过滤（在路由到的库内）
python {skill_dir}/scripts/run.py query "@Local 装饰器" --category 02-state-management --include-code --format json

# 完整文档（关闭 compact 和去重）
python {skill_dir}/scripts/run.py query "Navigation 页面跳转" --full-content --no-compact --no-dedup --include-code --format json
```

**检索策略**：优先检索目标 API 的接口定义 → 再检索用法示例 → 最后检索已知限制和注意事项。

**⚠️ 规则/约束/行为反直觉类问题必检 `18-arkts-rules/`**：在"错误排查"与"用法验证"场景中，凡涉及**约束 / 禁止项 / 报错行为 / 反直觉行为 / "为什么 X 不生效" / 时序 / 混用边界**的问题，`18-arkts-rules/` 的规则文件往往比 `01-basics/`、`02-state-management/`、`06-interaction/` 的长文档更对症。

**该分类不止是装饰器约束**——它覆盖 7 个独立主题（焦点 / 手势事件 / 组件生命周期 / @Builder 族 / 冻结 / 复用 / 样式），每个都藏着高频反直觉行为。但这些规则文件篇幅短、关键词命中少，**极易被长文档挤出 top-k 而漏召回**。务必在常规检索之外，用 `--category` 强制针对性检索，并适当提高 `--top-k`：

```bash
# 规则/约束/反直觉行为类问题：额外强制检索 18-arkts-rules，提高 top-k 防止漏召回
python {skill_dir}/scripts/run.py query "stopPropagation 手势 父组件" --category 18-arkts-rules --top-k 8 --include-code --format json
```

> 若 `--category` 模糊检索仍返回空（短文件关键词不命中），**直接 Read 下表对应文件全文**——这些文件普遍很短（最长不过数百行），全文读取最稳妥，切忌凭"分类描述"主观判断"不归该分类"而跳过。

**`18-arkts-rules/` 主题映射（按问题特征定位必检文件）：**

| 文件 | 主题 | 高频触发关键词 / 典型反直觉行为 |
|------|------|------|
| `arkts-focus-rules.md` | 焦点系统 | 焦点/获焦/走焦、requestFocus、defaultFocus、tabIndex、tabStop、focusable、焦点组、onKeyEvent、Tab/方向键 → 「defaultFocus 不可与 FocusPriority 混用」「tabIndex 不可与 focusScopeId 同设」「焦点组不可与 tabIndex 混用」「容器叶子节点 focusable(true) 仍无法获焦」 |
| `arkts-interaction-rules.md` | 手势/事件响应链 | 手势、stopPropagation、事件冒泡、触摸测试/hitTest、onTouch、onTouchIntercept、onGestureCollectIntercept、onChildTouchTest、onGestureRecognizerJudgeBegin、手势冲突/竞争 → **「stopPropagation 不中断父组件手势」**「手势为非冒泡事件」「Touch 与手势是两条独立响应链」「各交互 API 顺序固定不可调换」 |
| `arkts-ui-basic-rules.md` | 自定义组件/生命周期 | aboutToAppear/Disappear、onPageShow、@ComponentInit/Appear/Built/Disappear、getCurrentState、onMeasureSize/onPlaceChildren、跨 Ability 迁移 → 「最小化/后台不触发 @ComponentDisappear」「嵌套创建父 BUILT 后才执行子 Appear」「生命周期装饰器不能有入参」「与 @Computed 联用不生效」「aboutToDisappear 中禁改 @Link」 |
| `arkts-ui-extension.md` | @Builder/@LocalBuilder/@BuilderParam/wrapBuilder/mutableBuilder | @Builder/@LocalBuilder/@BuilderParam、wrapBuilder/mutableBuilder、MutableBinding、UIUtils.makeBinding、按引用/按值/按回调传递、尾随闭包、this 指向 → 「@Builder 两参数以上不刷新」「仅 {} 字面量算按引用」「禁改入参(错误码140109)」「传 class 对象不刷新」「禁 @Watch 内执行 @Builder」「mutableBuilder 二次赋值才生效」 |
| `arkts-ui-freeze-rules.md` | 组件冻结 | freezeWhenInactive、active/inactive、@Reusable/@ReusableV2 冻结、inheritFreezeOptions、BuilderNode 冻结、LazyForEach/Repeat 冻结、延后刷新 → 「active/inactive ≠ 可见性」「V2 复用自动冻结且解冻不补刷新」「冻结+复用混用解冻不触发 @Watch」「BuilderNode 中间层级需三方都配置才冻结」 |
| `arkts-ui-reuse-rules.md` | 组件复用 | @Reusable/@ReusableV2、reuseId、aboutToReuse/Recycle、复用池、reusePool/poolAccepts、全局复用池、Repeat template → 「缓存池归父自定义组件→跨容器可复用」「V1 aboutToReuse 禁改父状态需 setTimeout」「V2 自动重置状态(按定义顺序)」「V1/V2 复用不可互相包含」「V2 复用不能直接用于 Repeat template」「@Reusable+ComponentContent 会 crash」 |
| `arkts-ui-styles-rules.md` | @Styles/@Extend/@AnimatableExtend | @Styles、@Extend、@AnimatableExtend、样式封装 → 「@Extend 仅全局且必须指定组件」「@Styles 不支持参数」「两者都不支持 if/else 逻辑分支」「@AnimatableExtend 参数必须 number 或 AnimatableArithmetic」 |


### Step 3: 组织检索结果

将检索到的内容按用户问题的结构组织回答：

1. **直接回答**：用检索结果中的权威文档回答问题
2. **接口签名**：附上完整的 API 接口定义（参数名、类型、顺序）
3. **代码示例**：附上知识库中的用法示例
4. **来源标注**：标注每条关键信息的知识库路径

## 知识库覆盖范围

本 skill 维护两个独立知识库，检索时按语境自动路由。

### ArkTS 声明式（`references/knowledges/`，532 篇）

```
01-basics/          → 自定义组件、声明式UI、生命周期、基础概念 (12篇)
02-state-management/ → V1(@State/@Prop/@Link等) + V2(@Local/@Param等) + 迁移指南 (74篇)
03-layout/          → Flex/Grid/List/Scroll/RelativeContainer 等布局 (54篇)
04-components/      → 各类组件 + 组件公共接口 (118篇)
05-animation/       → 属性动画/显式动画/转场动画 (27篇)
06-interaction/     → 手势/触摸/按键/拖拽/焦点/事件系统 (51篇)
07-navigation/      → Navigation/NavDestination/路由 (41篇)
08-dialog-menu/     → 弹窗/菜单/下拉选择 (30篇)
09-rendering/       → ForEach/LazyForEach/Repeat/条件渲染 (25篇)
10-extension/       → RenderNode/自定义节点/Builder (20篇)
11-theme-style/     → 主题/样式系统 + @Extend/@Styles (18篇)
12-i18n/            → 国际化 (1篇)
13-accessibility/   → 无障碍 (4篇)
14-performance/     → 性能优化 (7篇)
15-advanced/        → 高级特性 (13篇)
16-window/          → 窗口管理 (7篇)
17-error-code/      → 错误码 (30篇)
```

### NDK / C-API（`references/ndk-knowledges/`，262 篇）

```
guide/              → 开发指南:构建组件/事件/动画/布局/嵌入ArkTS/多线程 (32篇)
node/               → 节点系统:native_node.h + attributetype + node option/event/border (38篇)
text/               → 文本/选择/轮播:text/picker/swiper/styled-string/menu (29篇)
gesture-drag/       → 手势/触摸/拖拽:gesture/touch/drag 事件与识别器 (23篇)
window-display/     → 窗口/显示:windowmanager/displaymanager/画中画 (23篇)
animation/          → 动画:animate/animator/curve/transition/motionpath (20篇)
accessibility/      → native 无障碍接口 (16篇)
xcomponent/         → OH_NativeXComponent surface/事件 (16篇)
layout/             → 布局:grid/list/waterflow/margin/align (14篇)
render/             → 渲染/绘制:render/rendernode/shape/draw (9篇)
dialog/             → 对话框:native_dialog/customdialog (8篇)
common-types/       → 通用类型/接口/事件总览/杂项 (34篇)
```

## 检索结果可信度判断

1. **API version 标注**：文档中明确标注 "从 API version X 开始支持" → 高可信
2. **废弃标记**：文档中有 "从 API version X 开始废弃" → 必须遵循，提示用户不可用
3. **V1/V2 标记**：文档在 `v1/` 或 `v2/` 目录下 → 明确版本归属
4. **无版本标注**：视为不确定，建议用户额外确认
