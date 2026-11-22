# 非崩溃型白屏分析（White-Screen Analyzer）

受理**进程存活但界面空白**的白屏：冷启动白屏、`Navigation` 跳转后白屏、`pop`/`clear`
后白屏。这类故障通常没有 JSCrash 签名、编译也能通过，因此**不走 faultlog 分诊链路**，
以 source-first 检视为主。本 Analyzer 在以下情形被加载：

- 用户口述页面空白但应用未退出（无日志、无复现要求）；
- 采集流程未取得任何 crash 日志、且症状为"空白但存活"（此时不得判定运行时健康，
  也不得进入"证据不足请重试"的采集死循环——直接切换本路径）。

基于当前工程与用户显式提供的证据诊断；不得依据无关工程推断修复。当用户明确表示
"先别复现，直接定位"时，直接走本路径的 source-first 流程，不索要日志、不要求连接设备。

## 聚焦检视顺序

按症状收窄检视范围，不做全工程宽泛读取。

### 冷启动白屏

1. 读 `entry/src/main/module.json5` 引用的页面元数据，通常是
   `resources/base/profile/main_pages.json`。
2. 读 `EntryAbility.ets`，比对 `windowStage.loadContent(...)` 传入的字面量与已注册
   页面、实际存在的 `.ets` 文件。
3. 读入口页，检视其根 `Navigation`、初始 `NavPathStack` 与可见子内容。
4. 在入口页与路由常量中搜索 `hideNavBar`、`navDestination`、`pushPath`、
   `pushPathByName`。

### 点击 / push / pop / clear 后白屏

1. 从复现步骤指名的点击处理器出发，记录其路由名。
2. 找到持有它的 `NavPathStack` 与 `Navigation(...).navDestination(...)` builder。
3. 先核对名称相等性、builder 分发与 `NavDestination` 根，再读无关页面。

对不熟悉的行为，用聚焦关键词查询本地 HarmonyOS 文档：

```bash
devecocli docs search Navigation 白屏 hideNavBar NavDestination
devecocli docs search loadContent main_pages 页面路径
devecocli docs search pushPathByName 路由 空白
```

读取搜索返回的 documentId；不得假设固定 documentId 在每个文档版本中都存在。

## 高信号模式

### 1. `loadContent` 指向缺失或未注册的页面

证据：

- `windowStage.loadContent('pages/Index', ...)`
- `main_pages.json` 注册的是 `pages/IndexPage`
- `pages/IndexPage.ets` 存在而 `pages/Index.ets` 不存在

修复 `loadContent` 字面量为精确的已注册页面路径。不得创建重复的占位入口页。

### 2. `hideNavBar(true)` 隐藏了唯一启动内容

`Navigation` 有首页/NavBar 内容区与 `NavDestination` 栈。启动时栈为空、且预期首页就在
`Navigation { ... }` 子内容中时，`.hideNavBar(true)` 会隐藏唯一可见内容而呈现白屏。

优先移除 `.hideNavBar(true)`；若意图只是隐藏系统标题栏，改为 `.hideTitleBar(true)`。
保留首页作为 `Navigation` 的子内容。

不得为了保住 `.hideNavBar(true)` 而在 `aboutToAppear` 里无条件 push 首页路由、加路由
拦截钩子、清空 `Navigation` 子内容——这会改变返回栈行为，且目标 builder 不返回有效
`NavDestination` 时依然白屏。

### 3. destination builder 不返回 `NavDestination`

`Navigation(...).navDestination(builder)` 选中的每个分支都必须以 `NavDestination`
为根包裹目标页：

```ets
@Builder
pageMap(name: string, param: Object) {
  if (name === RouteName.DETAIL) {
    NavDestination() {
      DetailPage()
    }
    .hideTitleBar(true)
  }
}
```

包裹只针对被 push 的目标页。正常首页组件是 `Navigation { ... }` 的直接子内容
（NavBar 内容），不得仅因其位置而额外包裹。

### 4. 多个 `.navDestination(...)` 注册互相竞争

不得按路由逐个链式注册 `.navDestination(builderA).navDestination(builderB)`。
`navDestination` 只接受一个分发器。把竞争注册合并为一个按 `name` 分支的 builder，
并确保每个分支返回 `NavDestination` 根。

### 5. 路由名或注册不匹配

将 `pushPath`/`pushPathByName` 传入的精确名称与以下各项逐一比对：

- destination builder 中的分支名
- 路由常量
- 使用系统路由表时的表项
- 相关时的 module 类型与跨模块路由配置

修复不匹配的名称或注册；不得用兜底页掩盖缺陷。

## 证据与验证契约

三种结论分开表述，不得混同：

- **根因匹配**：源码证据命中上述不变式之一，且改动直接恢复该不变式。
- **构建验证**：改动后 `devecocli check arkts` 和/或 `devecocli build` 成功。
  构建成功**不能**证明界面可见。
- **运行时验证**：受影响的启动或跳转路径被实际执行，且有设备/UI 内容证据或自动化
  视觉断言显示预期非空内容。

运行时验证不可得时，明确说明"源码级修复与构建已完成，但白屏是否消失未验证"。
进程成功启动或无崩溃日志**不构成**视觉证据。

## 输出格式要求

报告正文遵循主 Skill 交付节的路由规则（会话内只回简洁摘要，正文经
`export_report.py --type white_screen` 落盘 HTML），章节结构如下：

1. `# 非崩溃型白屏分析报告` —— 标题
2. `## 症状与检视路径` —— 白屏发生时机（冷启动/跳转/返回）、进程存活状态、
   所走的检视顺序与命中的检视步骤
3. `## 根因分析` —— 命中的高信号模式编号与源码证据（文件:行号 + 关键代码）
4. `## 修复建议` —— 遵循最小改动约束，按模式的修复方向给出源码 diff
5. `## 验证状态` —— 按三档契约明确标注（根因匹配/构建验证/运行时验证），
   运行时未验证时必须如实声明
