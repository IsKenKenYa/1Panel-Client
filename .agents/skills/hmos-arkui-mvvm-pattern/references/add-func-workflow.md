# 实现MVVM架构工作流：新建功能

适用于从零开始构建新页面或新模块。

## 0. 识别状态分类

按照 [状态变量原则](#状态变量原则) 的决策树判断每个变量的归属。

## 1. 定义 Model

根据 [代码文件原则](#代码文件原则) 判断每段代码的归属。Model 只含纯数据结构和数据访问逻辑。

注意：这里的model不能有`@Observed`等装饰以及使用任何状态管理相关的内容，应该都是通用的纯业务逻辑。

```
model/
├── UserModel.ets          实体类：纯数据结构，无装饰器
├── TaskModel.ets          实体类：interface 或 class
└── UserRepository.ets     仓库类：封装数据源访问
    ├── fetchUser()        网络请求
    ├── saveLocal()        本地存储
    └── parseResponse()    数据转换
```

## 2. 创建 ViewModel

**每个 ViewModel 对应一个 UI 关注点**，不是每个页面一个，也不是一个管全部：

```
viewmodel/
├── LoginViewModel.ets     登录表单状态 + 验证逻辑
├── AuthViewModel.ets      全局认证状态（单例，跨页面共享）
└── CartViewModel.ets      购物车状态 + 操作逻辑
```

| 划分原则 | 示例 |
|----------|------|
| 一个页面有一个主 ViewModel | LoginPage → LoginViewModel |
| 跨页面共享的状态独立为单例 ViewModel | 登录状态 → AuthViewModel |
| 复杂组件可有自己的 ViewModel | 地址选择器 → AddressPickerViewModel |
| 不要把所有逻辑塞进一个"上帝 ViewModel" | ✗ AppViewModel 管一切 |

**ViewModel 包含什么**：

```
├── UI 状态属性（驱动渲染）     isChecked、loadState、taskList
├── UI 逻辑方法（输入验证）     validate()、updateInput()
├── 协调方法（调 Model，更新状态） loadTasks()、login()
└── 不包含                     UI 组件引用、系统 API 直接调用
```

**异步数据状态**用 `LoadState` 枚举 + 独立数据字段：

```typescript
// ✓ loadState 枚举保证阶段互斥，数据字段独立持有保持 @Trace 粒度
export enum LoadState {
  Idle = 'idle',
  Loading = 'loading',
  Success = 'success',
  Error = 'error',
}

@Trace loadState: LoadState = LoadState.Idle
@Trace taskList: TaskModel[] = []
@Trace errorMessage: string = ''
```

原因：`@Trace` 按属性独立追踪，独立字段比单对象嵌套渲染粒度更细。

| 步骤 | V2 | V1 |
|------|----|----|
| 类装饰器 | `@ObservedV2` | `@Observed` |
| 属性观测 | `@Trace` | 无（第一层自动）/ `@Track`（精确） |
| 状态监听 | `@Monitor` | `@Watch` |
| 计算属性 | `@Computed` | 无（手动实现 getter） |

## 3. 实现 View

| 步骤 | V2 | V1 |
|------|----|----|
| 组件装饰器 | `@ComponentV2` | `@Component` |
| 接收数据 | `@Param` | `@Prop`（单向）/ `@Link`（双向） |
| 输出事件 | `@Event` | `@Link` 或回调 |

View 只依赖 ViewModel，保持精简。

## 4. 组装 Page

Page 作为入口，创建 ViewModel 实例并传递给 View。Page 不含业务逻辑。

## 5. 编译验证

编写完成后必须执行编译，排查引入的错误。

> 前置：先 `devecocli --version` 确认已安装；未安装需向用户确认后 `npm install -g @deveco/deveco-cli@latest`（需 Node.js >= 18、DevEco Studio >= 6.1.0）再继续，用户拒绝则走人工走查。

1. 用 `devecocli build` 对修改过的 `.ets` 文件做编译检查（ArkTS 语法/类型检查；多模块工程用 `devecocli build --modules <模块名>`）
2. 如有报错，修复后重新构建，直到全部通过
3. 必要时用 `devecocli build` 做完整构建验证（增量结果可疑时先 `devecocli build clean` 再重跑）