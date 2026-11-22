# 1. 模块导入（import）约束

## 规则

| 规则 | 说明 |
|------|------|
| **禁止使用 `@ohos.*` 路径导入** | 旧版导入路径，**必须用 `@kit.*` 替代**。`import router from '@ohos.router'` → `import { router } from '@kit.ArkUI'` |
| **禁止凭记忆编造 import** | 模块路径和导出符号必须来自检索结果/速查表，不得猜测 |
| **禁止遗漏必要的 import** | 代码中使用的外部类型/函数/枚举必须有对应 import 声明 |
| **禁止 import 未使用的模块** | 导入了但未使用的模块必须删除 |
| **禁止从错误 kit 导入** | 每个 API 只属于一个 kit，不能从错误的 kit 导入（参考下方速查表） |

## Kit 导入速查表

### @kit.ArkUI（UI 开发核心 kit）

```ts
import {
  UIContext, window, BuilderNode, FrameNode, NodeController,
  ComponentContent, NodeContent, NodeRenderState,
  LengthMetrics, ColorMetrics, matrix4, curves,
  router, PromptAction, ImageModifier, KeyboardAvoidMode,
  Font, uiObserver, UIUtils,
  Theme, ThemeControl, CustomColors, CustomTheme,
  CircleShape, RectShape, EllipseShape, PathShape, Binding
} from '@kit.ArkUI'
```

| 使用场景 | 导入符号 |
|---------|---------|
| UI 上下文操作 | `UIContext` |
| 窗口管理 | `window` |
| 自定义节点 | `BuilderNode`, `FrameNode`, `NodeController` |
| 自定义内容 | `ComponentContent`, `NodeContent` |
| 节点渲染状态 | `NodeRenderState` |
| 尺寸/颜色度量 | `LengthMetrics`, `ColorMetrics` |
| 矩阵变换 / 动画曲线 | `matrix4`, `curves` |
| 页面路由 / 弹窗提示 | `router`, `PromptAction` |
| 图片属性修改器 / 键盘避让 | `ImageModifier`, `KeyboardAvoidMode` |
| 自定义字体 / UI 观察者 | `Font`, `uiObserver` |
| V1/V2 兼容工具 | `UIUtils` |
| 主题相关 | `Theme`, `ThemeControl`, `CustomColors`, `CustomTheme` |
| Shape 裁切 | `CircleShape`, `RectShape`, `EllipseShape`, `PathShape` |
| 数据绑定 | `Binding` |

### @kit.AbilityKit（应用模型 kit）

```ts
import { UIAbility, AbilityConstant, Want, common, Configuration, ConfigurationConstant, bundleManager } from '@kit.AbilityKit'
```

| 使用场景 | 导入符号 |
|---------|---------|
| Ability 生命周期 | `UIAbility`, `AbilityConstant` |
| Ability 间通信 | `Want` |
| 获取上下文类型 | `common`（如 `common.UIAbilityContext`） |
| 配置变更 / 包管理 | `Configuration`, `ConfigurationConstant`, `bundleManager` |

### @kit.BasicServicesKit（基础服务 kit）

```ts
import { BusinessError, request, commonEventManager } from '@kit.BasicServicesKit'
```

| 使用场景 | 导入符号 |
|---------|---------|
| 错误类型捕获 | `BusinessError` |
| 网络下载 / 公共事件 | `request`, `commonEventManager` |

### 其他 kit

| Kit | 导入符号 | 使用场景 |
|-----|---------|---------|
| `@kit.ArkData` | `unifiedDataChannel`, `uniformTypeDescriptor` | 拖拽数据传递（UTD） |
| `@kit.ImageKit` | `image` | 图片处理（编解码、缩放等） |
| `@kit.InputKit` | `pointer`, `IntentionCode` | 光标样式、输入设备 |
| `@kit.ArkGraphics2D` | `uiEffect` | 模糊效果等图形能力 |
| `@kit.CoreFileKit` | `fileIo` | 文件读写 |
| `@kit.ArkTS` | `buffer` | 二进制缓冲区 |
| `@kit.PerformanceAnalysisKit` | `hilog` | 日志输出 |

## 全局内置（不需要 import）

基础组件（`Column/Row/Text/Button/Image/List/Grid/Scroll/Stack/Flex/Tabs/Navigation/NavDestination/TextInput` 等）、控制器类型（`SwiperController/TextInputController/Scroller/NavPathStack` 等直接 `new`）、渲染控制（`ForEach/LazyForEach/if-else`）、`AttributeModifier`/`AttributeUpdater` 等扩展接口、枚举（`Color/FontWeight/Curve/FlexAlign/Alignment/Axis/ImageFit/InputType/ButtonType/TextAlign/TextOverflow/Visibility/PlayMode` 等）全局可用。

**特别注意以下全局类型不要 import（`@kit.ArkUI` 不导出它们）：**
- `NavPathStack`、`AppStorage`、`canIUse`、`getContext` — 全局可用，不要 import
- `ObservedV2`、`Trace` — 装饰器全局可用，不要 import
- `Resource`、`ResourceColor`、`ResourceStr` — 全局类型，不要 import
- `AlertDialog`、`ActionSheet`、`DatePickerDialog`、`TimePickerDialog`、`TextPickerDialog` — 弹窗全局可用（但建议通过 UIContext 调用）
- `LocalStorage`、`PersistentStorage`、`AppStorage` — 状态类型全局可用

**以下需要 import：**
- `AppStorageV2`、`PersistenceV2` — **需要**从 `@kit.ArkUI` 导入
- 小写 `curves` 命名空间 — **需要**从 `@kit.ArkUI` 导入（`Curve.*` 枚举是全局的）

> **注意**：`AttributeModifier` 不要在 `@kit.ArkUI` 里 import，它在全局 component 作用域（实测 TC_EXT_COMPONENT_001）。

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 |
|-----------|-----------|
| `import router from '@ohos.router'` | `import { router } from '@kit.ArkUI'` |
| `import window from '@ohos.window'` | `import { window } from '@kit.ArkUI'` |
| `import promptAction from '@ohos.promptAction'` | `import { PromptAction } from '@kit.ArkUI'`（或通过 UIContext 获取） |
| `import { BusinessError } from '@ohos.base'` | `import { BusinessError } from '@kit.BasicServicesKit'` |
| `import { UIAbility } from '@kit.ArkUI'` | `import { UIAbility } from '@kit.AbilityKit'` |
| `import { hilog } from '@kit.ArkUI'` | `import { hilog } from '@kit.PerformanceAnalysisKit'` |
| `import { image } from '@kit.ArkUI'` | `import { image } from '@kit.ImageKit'` |
| `import { fileIo } from '@kit.ArkUI'` | `import { fileIo } from '@kit.CoreFileKit'` |
| `import { mediaQuery } from '@kit.ArkUI'`（小写 q） | `import { MediaQuery } from '@kit.ArkUI'`（大写 Q） |

## 参考

- **关键**：ArkTS 全局内置能力已在上文列出；凡是不在列表中的，必须先查速查表或检索确认再写，不凭记忆编造
- 组件/struct 基本约束见 [03-component](03-component.md)：创建组件不需要 `new`；`struct` 无继承；static 无意义；组件名不得与系统组件重名