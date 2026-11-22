# 重构为MVVM工作流：已有项目重构为 MVVM

适用于已有代码需要整改为 MVVM 架构。**逐页面推进，每改完一个 Page 就验证功能不变。**

## 0. 确定整改顺序

按风险由低到高排序：

```
1. 纯展示页面（只读，无交互）→ 最安全
2. 简单表单页（有提交，无复杂状态）
3. 列表页（有增删改，状态较复杂）
4. 多 Tab / 嵌套导航页（跨组件状态共享）
```

## 1. 扫描现状

识别目标页面中违反 MVVM 的问题：

| 检查项 | 排查方式 |
|--------|---------|
| Page 中包含业务逻辑 | Page struct 内有数据处理、API 调用、状态计算 |
| View 直接访问 Model | View 文件 import 了 model/ 目录 |
| 状态管理混乱 | 同一份数据在多处被 `@State` 管理 |
| 组件职责不清 | 一个 struct 同时承担数据获取、业务计算和 UI 渲染 |

参考 [anti-patterns.md](references/anti-patterns.md) 逐项对照。

## 2. 提取 ViewModel

从 Page/View 中剥离状态和逻辑，创建 ViewModel 类：

```
原始 Page 中的代码：
├─ @State xxx → 移入 ViewModel，加观测装饰器
├─ 业务方法（数据处理、计算）→ 移入 ViewModel
├─ API / 数据库调用 → 移入 Repository（Model 层）
└─ 纯 UI 状态（如选中标签）→ 保留在 Page/View 中
```

**操作顺序**：
1. 新建 ViewModel 文件，声明类和属性（不加装饰器）
2. 将 Page 中的 `@State` 变量和业务方法搬迁过来
3. 给 ViewModel 属性加上观测装饰器（`@Trace`/`@Observed`）
4. Page 中改为持有 ViewModel 实例，通过方法调用

## 3. 分离 Model

根据 [代码文件原则](#代码文件原则) 逐项判断 ViewModel/View 中的代码归属：

```
ViewModel 中的代码：
├─ http.createHttp().request(...) → 移入 Repository
├─ preferences.get(...)          → 移入 Repository
├─ 数据结构定义（interface/class）→ 移入 Model 文件
├─ 纯算法、系统能力封装           → 移入 util/
└─ 纯业务逻辑（过滤、排序、计算）→ 保留在 ViewModel
```

## 4. 重组 View

将 Page 瘦身为纯组装角色：

```
整改后的 Page：
├─ 创建 ViewModel 实例（@Local/@State）
├─ aboutToAppear 中调用 ViewModel 初始化方法
└─ build() 中只做布局和子组件组装

整改后的 View：
├─ 通过 @Param/@Prop 接收 ViewModel 数据
├─ 通过 @Event/回调 向上传递用户操作
└─ 不直接 import Model 文件
```

## 5. 逐页验证

每完成一个页面的整改，立即验证。

> 前置：先 `devecocli --version` 确认已安装；未安装需向用户确认后 `npm install -g @deveco/deveco-cli@latest`（需 Node.js >= 18、DevEco Studio >= 6.1.0）再继续，用户拒绝则走人工走查。

1. 用 `devecocli build` 对修改过的 `.ets` 文件做编译检查，修复报错直到通过
2. 必要时用 `devecocli build` 做完整构建验证（增量结果可疑时先 `devecocli build clean` 再重跑）
3. 逐项检查数据流合规性：

| 验证项 | 方式 |
|--------|------|
| 功能不变 | 手动测试页面所有交互 |
| 数据流合规 | View 不直接访问 Model，事件通过 ViewModel 传递 |
| 装饰器配套 | V1/V2 未混用 |
| 无冗余状态 | 同一份数据只在一处管理 |

验证通过后再推进下一个页面。