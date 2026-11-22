# 功能与兼容性

每个用例独立使用，需求句只描述开发者诉求。普通前提简述，只列与测试目标有关的文件；ETS 页面完整，color.json 保留默认模板的启动窗背景色，JSON5 仅展示相关配置。路径相对于工程根目录，其余文件采用标准 Stage 工程配置，pages/Index 已登记。

**通用报告要求**：工程任务的最终报告使用“深浅色适配报告”标题，并依次组织“适配结论”“工程检查与改动”“高性能切换说明”“验证结果”。面向开发者的报告不展示内部路由编号；修改任务按授权完成必要改动，默认能力已满足时说明依据。报告中的改动、检查和验证状态必须与实际执行一致，不套用示例完成态，不固定添加“本次未修改工程”等声明。下列各用例的技术验证标准仍须满足，措辞无需逐字匹配示例。

---

### 测试用例：FUNC-001

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：默认效果已经满足

#### 输入

协助适配深色模式。

文件：`build-profile.json5`

```json5
{
  "app": {
    "products": [
      {
        "name": "default",
        "targetSdkVersion": "26.0.0",
        "compatibleSdkVersion": "26.0.0",
        "runtimeOS": "HarmonyOS"
      }
    ]
  }
}
```

文件：`entry/src/main/ets/entryability/EntryAbility.ets`

```ts
import { ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    this.context.getApplicationContext().setColorMode(
      ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }
}
```

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column({ space: 16 }) {
      Text('订单')
      Button('确认')
    }
    .width('100%')
    .height('100%')
  }
}
```

文件：`entry/src/main/module.json5`

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "metadata": []
  }
}
```

#### 预期输出

**验证标准**：

- 从工程文件判断现状：根 build-profile.json5 的 default 产品声明 targetSdkVersion 和 compatibleSdkVersion 均为 26.0.0；Ability 设置跟随系统，页面使用默认主题，module.metadata 未配置高性能。
- 明确说明本例当前已默认支持深浅色，无需额外功能适配。
- 指出当前 metadata 为空，尚未启用高性能切换，当前为非高性能模式。
- 说明高性能切换从 API 20 起提供；从有效产品配置读取本例目标 API 26，不将目标版本当成已经核实的编译 SDK 或设备版本。
- 给出可操作的高性能配置说明：在 entry/src/main/module.json5 的 module.metadata 中添加 name 为 configColorModeChangePerformanceInArkUI、value 为字符串 "true" 的配置，保留其他配置，不使用布尔值。接受 JSON5 片段或清楚的文字说明，不限定完整代码块形式；仅泛称“高性能开关”而未给出准确配置名称，不满足此项。
- 按含义说明两种流程：默认切换时全量重新设置组件属性，高性能在仅颜色模式变化且满足优化条件时减少这部分前端执行，并按当前模式更新颜色。无需逐项复述内部环节，不因未出现某个固定术语或指定句子单独判失败。
- 可概括收益为减少重复执行开销、改善切换性能，不要求逐项列出 CPU、属性设置和绘制等术语；不编造提升比例或承诺零开销。
- 介绍版本、配置和机制后，说明高性能为可选接入；提供接入说明时不擅自修改配置，不声称已启用或已完成设备验证。

**配置示例（省略无关字段，仅为一种可接受的说明形式）**：

```json5
{
  "module": {
    "metadata": [
      {
        "name": "configColorModeChangePerformanceInArkUI",
        "value": "true"
      }
    ]
  }
}
```

---

### 测试用例：FUNC-002

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：自定义颜色资源

#### 输入

协助适配深色模式，订单标题在深色下显示为 #FFE6E6E6。

前置条件：API 26，应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统。

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('订单标题')
        .fontColor('#FF202020')
    }
    .width('100%')
    .height('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 识别当前 fontColor 直接设置 #FF202020；将该颜色适配为按深浅色匹配的资源。
- 给出 entry/src/main/resources/base/element/color.json，使用 invoice_title=#FF202020；给出 entry/src/main/resources/dark/element/color.json，使用同名 invoice_title=#FFE6E6E6。
- 给出完整页面，将 fontColor 的直接色值替换为 $r('app.color.invoice_title')，由同一个资源名匹配深浅色配色。
- 说明本次资源适配无需以高性能或反色为前提；高性能可以作为后续选项介绍。

**资源与页面示例**：

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "invoice_title",
      "value": "#FF202020"
    }
  ]
}
```

文件：`entry/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "invoice_title",
      "value": "#FFE6E6E6"
    }
  ]
}
```

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('订单标题')
        .fontColor($r('app.color.invoice_title'))
    }
    .width('100%')
    .height('100%')
  }
}
```

---

### 测试用例：FUNC-003

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：通过反色减少颜色资源维护

#### 输入

希望缩减 color.json，品牌色保持精确。

前置条件：API 26；应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统；已有可用的 N-API/C++ 模块，尚未开启高性能和反色。

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column({ space: 16 }) {
      Text('品牌标题')
        .fontColor($r('app.color.brand'))
      Text('正文')
        .fontColor($r('app.color.body'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "brand",
      "value": "#FF164B9A"
    },
    {
      "name": "body",
      "value": "#FF203040"
    }
  ]
}
```

文件：`entry/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "brand",
      "value": "#FF8AB4F8"
    },
    {
      "name": "body",
      "value": "#FFDFCFBF"
    }
  ]
}
```

#### 预期输出

**验证标准**：

- 提供反色方案，说明需开发者设计、验证业务算法，系统默认算法不保证满足需求。
- 说明 API 20+、高性能、Native C API 初始化，以及在 loadContent 加载成功回调内、节点创建前的 UI 线程同步配置反色的接入条件。
- 保留 brand 的精确 dark 定义；body 在算法效果确认后可评估移除对应 dark 定义，保留 base 资源。
- 解释当前颜色有 dark 定义时优先使用资源，无同名 dark 时在目标属性支持的条件下评估反色。
- 精简 body 的 dark 定义前，说明需要确认业务算法和目标显示效果；输入明确出现局部颜色模式、限定配置范围或反色禁用设置时，再分析对应限制。本例未提供这些特殊配置，不因未逐项展开 uiContext、nodeType 或 allowForceDark 条件单独判失败；未实测时不声称已通过设备验证。

---

### 测试用例：FUNC-004

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：WithTheme 固定局部深色

#### 输入

只把卡片固定为深色，页面其他区域保持原样。

前置条件：API 12；应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统。

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column({ space: 24 }) {
      Text('页面标题')
      Column({ space: 8 }) {
        Text('卡片标题')
          .fontColor($r('app.color.card_title'))
        Text('卡片正文')
          .fontColor($r('app.color.card_body'))
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_background'))
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "card_title",
      "value": "#FF202020"
    },
    {
      "name": "card_body",
      "value": "#FF404040"
    },
    {
      "name": "card_background",
      "value": "#FFF5F5F5"
    }
  ]
}
```

文件：`entry/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "card_title",
      "value": "#FFF0F0F0"
    },
    {
      "name": "card_body",
      "value": "#FFCCCCCC"
    },
    {
      "name": "card_background",
      "value": "#FF202020"
    }
  ]
}
```

#### 预期输出

**验证标准**：

- 用 WithTheme({ colorMode: ThemeColorMode.DARK }) 仅包裹卡片，卡片外继续跟随应用。
- 卡片内的两个 Text 由一个直接子容器承载，尺寸、间距和背景属性放在内部容器上。
- 使用现有 card_title、card_body、card_background 的 base/dark 资源，给出完整修改页面。
- 说明 WithTheme 从 API 12 起提供，单独使用无需开启高性能或接入反色。

---

### 测试用例：FUNC-005

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：低版本能力限制

#### 输入

想开启高性能深浅色切换和反色，并让卡片退出自动反色。

前置条件：API 18；应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统。

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Column() {
        Text('卡片')
          .fontColor($r('app.color.card_text'))
      }
      .padding(16)
      .backgroundColor($r('sys.color.ohos_id_color_background'))
    }
    .width('100%')
    .height('100%')
  }
}
```

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "card_text",
      "value": "#FF202020"
    }
  ]
}
```

文件：`entry/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "card_text",
      "value": "#FFE6E6E6"
    }
  ]
}
```

#### 预期输出

**验证标准**：

- 指出高性能和反色 C API 从 API 20 起提供，allowForceDark 从 API 21 起提供，API 18 无法直接接入这些能力。
- 当前可保留普通资源适配；如果需要新能力，说明应评估的升级范围，由开发者决定。
- 给出的方案符合当前 API 条件。

---

### 测试用例：FUNC-006

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：开启高性能后的 V1 兼容性检查

#### 输入

检查当前页面开启高性能深浅色后有什么问题

前置条件：API 26，已开启高性能。

文件：`entry/src/main/ets/common/ThemeCache.ets`

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';

export class ThemeCache {
  colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
}

export const themeCache: ThemeCache = new ThemeCache();
```

文件：`entry/src/main/ets/entryability/EntryAbility.ets`

```ts
import { Configuration, ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { themeCache } from '../common/ThemeCache';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    this.context.getApplicationContext().setColorMode(
      ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    this.updateMode(this.context.config.colorMode);
  }

  onConfigurationUpdate(config: Configuration): void {
    this.updateMode(config.colorMode);
  }

  private updateMode(mode: ConfigurationConstant.ColorMode | undefined): void {
    if (mode === undefined) {
      return;
    }
    themeCache.colorMode = mode;
    AppStorage.setOrCreate('colorMode', mode);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }
}
```

文件：`entry/src/main/ets/pages/Index.ets`

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';
import { themeCache } from '../common/ThemeCache';

@Entry
@Component
struct Index {
  selectTitlePaint(): Resource {
    return themeCache.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? $r('app.color.title_dark') : $r('app.color.title_light');
  }

  build() {
    Column() {
      Text('函数选择标题')
        .fontColor(this.selectTitlePaint())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "title_light",
      "value": "#FF202020"
    },
    {
      "name": "title_dark",
      "value": "#FFE6E6E6"
    }
  ]
}
```

#### 预期输出

**验证标准**：

- 输入页面只包含 Text('函数选择标题').fontColor(this.selectTitlePaint()) 这一处配色，没有已适配的统一资源标题、@StorageLink/@Watch 或监听更新标题；这些是待生成的修复，不是输入前提。
- 定位 selectTitlePaint 读取普通 themeCache 并选择不同资源，缓存字段变化后缺少目标属性重新选择资源的触发路径。Ability 已更新 AppStorage，不等于页面已经建立监听链路。
- 结合更新机制解释：高性能不再因单纯颜色变化全量重执行前端属性设置，不会保证自动重新调用该函数；显式监听和状态驱动的前端更新仍然有效，不能写成完全不执行前端。
- 给出兼容方案：建立从 AppStorage 到页面的可观测状态链路（如 `@StorageLink`），使按模式选择资源的逻辑拥有状态驱动的更新触发。写法任选其一：在绑定处直接读取该状态（如 `fontColor(this.selectTitlePaint())`，函数读取 `this.mode`），或用 `@Watch` 回调把选择结果写入独立绑定状态；selectTitlePaint 改为读取 this.mode 执行原有三元选择，并补齐首次显示（@StorageLink 初次链接即读取既有 AppStorage 值，属可行的首次显示处理之一）。仅返回 Resource 而页面没有任何读取可观测状态的更新路径，不构成有效修复。
- 给出高性能资源方案：新增或合并 title_color 的 base/dark 同名定义，将这一处 Text 改为直接绑定同一资源；输入中尚无 title_color，不能声称保留了已有统一资源适配。纯配色优先推荐此方案。
- 说明两种方案的性能取舍，分别给出涉及文件的相对路径与完整代码；兼容方案需完整展示状态观察、资源选择、更新到绑定的路径和首次显示初始化，已正确的 Ability 写入可明确复用。检查冷启动深色及双向切换。

**兼容方案页面示例**（输出，不属于输入；以下为一种可接受写法，在绑定处直接读取 @StorageLink 状态的选择函数同样可接受）：

文件：`entry/src/main/ets/pages/Index.ets`

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @StorageLink('colorMode') @Watch('refreshPaint')
  mode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State watchedPaint: Resource = $r('app.color.title_light');

  aboutToAppear(): void {
    this.refreshPaint();
  }

  refreshPaint(): void {
    this.watchedPaint = this.selectTitlePaint();
  }

  selectTitlePaint(): Resource {
    return this.mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? $r('app.color.title_dark') : $r('app.color.title_light');
  }

  build() {
    Column() {
      Text('函数选择标题')
        .fontColor(this.watchedPaint)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

更新链路为 AppStorage → @StorageLink 的 mode → @Watch 的 refreshPaint → selectTitlePaint 三元选择 → watchedPaint → fontColor。首次显示主动调用 refreshPaint，因为 @Watch 不负责初始化。相关配色仍需前端执行；不能将恢复换色等同于获得纯资源换色所减少的全部开销。

**优化写法示例**（高性能资源方案，输出，不属于输入）：

将同一个标题直接绑定到 title_color，在 base/dark 中分别配置颜色。此方案与上方兼容方案分别应用于同一份原始输入。

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('函数选择标题')
        .fontColor($r('app.color.title_color'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

在已有资源中合并以下同名颜色定义，JSON 仅展示相关条目，保留其他资源。

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "title_color",
      "value": "#FF202020"
    }
  ]
}
```

文件：`entry/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "title_color",
      "value": "#FFE6E6E6"
    }
  ]
}
```

本例已开启高性能。切换时由资源更新流程解析同一个 title_color 的当前模式值，无需为这项配色执行 selectTitlePaint、三元选择或新增 @StorageLink/@Watch，减少相关前端执行与重复属性设置，仍会完成必要的颜色更新与绘制。只清理这项配色不再需要的逻辑；title_light/title_dark、ThemeCache 或事件更新若仍有其他业务引用则保留。

---

### 测试用例：FUNC-007

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：开启高性能后的 V2 兼容性检查

#### 输入

检查当前页面开启高性能深浅色后有什么问题

前置条件：API 26，已开启高性能。

文件：`entry/src/main/ets/common/ThemeModels.ets`

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';

export class ThemeState {
  colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
}

export const themeState: ThemeState = new ThemeState();
```

文件：`entry/src/main/ets/entryability/EntryAbility.ets`

```ts
import { Configuration, ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { themeState } from '../common/ThemeModels';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    this.context.getApplicationContext().setColorMode(
      ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    this.updateMode(this.context.config.colorMode);
  }

  onConfigurationUpdate(config: Configuration): void {
    this.updateMode(config.colorMode);
  }

  private updateMode(mode: ConfigurationConstant.ColorMode | undefined): void {
    if (mode === undefined) {
      return;
    }
    themeState.colorMode = mode;
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }
}
```

文件：`entry/src/main/ets/pages/Index.ets`

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';
import { ThemeState, themeState } from '../common/ThemeModels';

@Entry
@ComponentV2
struct Index {
  @Local theme: ThemeState = themeState;

  build() {
    Column() {
      Text('主题状态标题')
        .fontColor(this.theme.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          ? $r('app.color.title_dark') : $r('app.color.title_light'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "title_light",
      "value": "#FF202020"
    },
    {
      "name": "title_dark",
      "value": "#FFE6E6E6"
    }
  ]
}
```

#### 预期输出

**验证标准**：

- 输入只保留 ThemeState 模型、themeState 实例和一个主题状态标题，不预置正确实现作为对照。
- 定位为更新触发缺失：默认模式依靠切换时的全量前端更新重新执行属性设置，三元表达式得以重读 colorMode；开启高性能后不再全量执行前端，该隐式触发消失。ThemeState 为普通类（无 @ObservedV2/@Trace），@Local 只观察引用本身、不深入实例字段，状态驱动的重执行也不成立，因此切换后标题颜色不更新。说明三元依赖前端重执行、高性能下需要有效更新触发，不写成“三元表达式与高性能机制冲突/不兼容”的绝对判词。
- 给出兼容方案：为既有 ThemeState 补 @ObservedV2 和 @Trace，保留同一实例和页面对 this.theme.colorMode 的直接读取，初始化和配置变化均写入该实例；不新增第二个模型或实例。
- 补齐 @ObservedV2 和 @Trace 后，三元表达式经状态更新重执行，属于有效更新触发，在高性能模式下保留这部分前端执行、享受不到纯资源换色省掉的这部分开销；不因此判三元不兼容，也不为本例强行增加 @Monitor 或 V1 的 Watch。确有额外业务处理时再按 V2 机制监听。
- 给出高性能资源方案：新增或合并 title_color 的 base/dark 定义，移除该配色的三元表达式并直接绑定同一资源；输入尚无统一资源适配，不能声称已存在。
- 保持 V2，说明性能取舍，给出涉及文件的相对路径与完整代码，检查冷启动深色及双向切换。

**兼容方案模型示例**（输出，不属于输入）：

文件：`entry/src/main/ets/common/ThemeModels.ets`

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';

@ObservedV2
export class ThemeState {
  @Trace colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
}

export const themeState: ThemeState = new ThemeState();
```

页面继续使用 @Local theme: ThemeState = themeState，并在 fontColor 的三元表达式中直接读取 this.theme.colorMode。字段变化后执行相关前端选择与属性设置；若要减少这部分执行，采用同名 base/dark 资源方案。

---

### 测试用例：FUNC-008

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：反色初始化及调用时机

#### 输入

反色没有生效，请检查初始化和调用时机。

前置条件：API 26；应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统；已开启高性能，N-API 模块可正常导入，Native configure 已包含 C API 初始化。观察时先将系统设为深色，启动应用，待页面文字显示后再点击“开启反色”。

文件：`entry/src/main/ets/entryability/EntryAbility.ets`

```ts
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }
}
```

文件：`entry/src/main/ets/pages/Index.ets`

```ts
import nativeTheme from 'libnativetheme.so';

@Entry
@Component
struct Index {
  build() {
    Column({ space: 16 }) {
      Text('反色文字')
        .fontColor('#FF203040')
      Button('开启反色')
        .onClick(() => {
          const code: number = nativeTheme.configure(true);
          if (code !== 0) {
            console.error('反色配置失败，错误码：' + code);
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

文件：`entry/src/main/cpp/native_theme.cpp`

```cpp
#include <arkui/native_interface.h>
#include <arkui/native_node.h>
#include <napi/native_api.h>

static uint32_t Invert(uint32_t argb)
{
    return argb ^ 0x00FFFFFF;
}

static napi_value Configure(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    bool enabled = true;
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (argc == 1) {
        napi_get_value_bool(env, args[0], &enabled);
    }
    auto* api = OH_ArkUI_QueryModuleInterfaceByName(
        ARKUI_NATIVE_NODE, "ArkUI_NativeNodeAPI_1");
    const int32_t code = api == nullptr ? -1 : OH_ArkUI_SetForceDarkConfig(
        nullptr, enabled, ARKUI_NODE_TEXT, Invert);
    napi_value result;
    napi_create_int32(env, code, &result);
    return result;
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor method = {
        "configure", nullptr, Configure, nullptr, nullptr, nullptr, napi_default, nullptr
    };
    napi_define_properties(env, exports, 1, &method);
    return exports;
}

static napi_module themeModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "nativetheme",
    .nm_priv = nullptr,
    .reserved = { 0 }
};

extern "C" __attribute__((constructor)) void RegisterNativeTheme()
{
    napi_module_register(&themeModule);
}
```

文件：`entry/src/main/cpp/types/libnativetheme/index.d.ts`

```ts
export const configure: (enabled: boolean) => number;
```

#### 预期输出

**验证标准**：

- 确认 Native configure 已查询 OH_ArkUI_QueryModuleInterfaceByName，且在配置反色前完成 C API 初始化；保留这条正确链路，不误报为初始化缺失。
- 定位问题为页面和 Text 已创建后，才在 onClick 中首次调用 configure(true) 开启反色。现有节点不会因此按预期立即反色，接口返回 0 也不等于文字颜色已经更新。
- 将反色配置提前到 windowStage.loadContent 的加载成功回调内，在目标节点创建前的 UI 线程同步完成；先检查加载错误，再调用 Native 配置并检查返回值。
- 保留已有 Native 初始化与算法，给出涉及文件的修复代码，结合 Text 的配置范围和深色作用域说明生效条件。首次配置时机已正确修复时，不因页面保留开启/关闭按钮而单独判失败，不要求删除所有按钮。
- 保留 Text('反色文字') 作为观察项，说明修复后可在深色作用域核对反色效果；不要求列出具体反色色值。

**加载成功回调内配置反色的修复示例**（输出，不属于输入）：

Native configure 中的初始化和算法已经正确，保留其实现；将 ArkTS 的首次配置从 onClick 提前到加载成功回调内。

下方展示一种最小修复写法。页面按钮可按业务需求保留、调整或移除，验收重点为目标节点的反色配置是否在正确时机完成。

文件：`entry/src/main/ets/entryability/EntryAbility.ets`

```ts
import { ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import nativeTheme from 'libnativetheme.so';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    this.context.getApplicationContext().setColorMode(
      ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error('页面加载失败，错误码：' + err.code);
        return;
      }
      const code: number = nativeTheme.configure(true);
      if (code !== 0) {
        console.error('反色配置失败，错误码：' + code);
      }
    });
  }
}
```

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('反色文字')
        .fontColor('#FF203040')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

---

### 测试用例：FUNC-009

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：有同名 dark 颜色资源时未进入反色算法

#### 输入

已经开启反色，为什么下面最后一个 Text 没有按 Invert 算法反色？

前置条件：API 26；应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统；高性能与反色已在 loadContent 加载成功回调内、节点创建前的 UI 线程启用，配置覆盖 Text，回调为下方 Invert，目标 Text.fontColor 支持反色。

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column({ space: 16 }) {
      Text('直接色值')
        .fontColor('#FF203040')
      Text('仅 base 资源')
        .fontColor($r('app.color.no_dark'))
      Text('有 dark 资源')
        .fontColor($r('app.color.with_dark'))
    }
    .width('100%')
    .height('100%')
  }
}
```

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "no_dark",
      "value": "#FF102030"
    },
    {
      "name": "with_dark",
      "value": "#FF405060"
    }
  ]
}
```

文件：`entry/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "with_dark",
      "value": "#FF778899"
    }
  ]
}
```

以下为已接入的反色算法：

文件：`entry/src/main/cpp/native_theme.cpp`

```cpp
#include <cstdint>

static uint32_t Invert(uint32_t argb)
{
    if (argb == 0xFF102030) {
        return 0xFF12AB34;
    }
    return argb ^ 0x00FFFFFF;
}
```

#### 预期输出

**验证标准**：

- 定位最后一个 Text 绑定的 with_dark 在 base/dark 中均有同名定义：深色时优先使用其 dark 配色，不再对该颜色执行 Invert，属于资源优先级规则。
- 前置条件已经满足高性能、Native 初始化、配置时机与 Text 范围要求，不将该现象误判为反色未开启、初始化缺失或调用时机错误。
- 说明判断对象是当前颜色资源是否有同名 dark 定义，不是工程中是否存在整个 dark/color.json；同一页面可以同时保留精确 dark 配色并让其他支持的颜色进入反色。
- 本例验证对资源优先级的解释，不要求计算具体反色色值或提供设备验证步骤，也无需为了该现象重写算法或重新接入反色。

---

### 测试用例：FUNC-010

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：节点较多的页面优化切换性能并用 trace 验证

#### 输入

页面节点很多，用默认深浅色切换明显卡顿，怎么优化？

前置条件：API 26；应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统；未开启高性能。

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  private orders: string[] = [];

  aboutToAppear(): void {
    for (let i = 1; i <= 200; i++) {
      this.orders.push('订单 ' + i);
    }
  }

  build() {
    Column() {
      Text('订单列表')
        .fontSize(20)
        .fontColor($r('app.color.title_color'))
      List() {
        ForEach(this.orders, (name: string) => {
          ListItem() {
            Column() {
              Text(name)
                .fontColor($r('app.color.title_color'))
              Text(name + ' 的商品、金额与状态')
                .fontColor($r('app.color.body_color'))
            }
            .width('100%')
            .padding(12)
          }
        }, (name: string) => name)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "title_color",
      "value": "#FF202020"
    },
    {
      "name": "body_color",
      "value": "#FF404040"
    }
  ]
}
```

文件：`entry/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "title_color",
      "value": "#FFE6E6E6"
    },
    {
      "name": "body_color",
      "value": "#FFCCCCCC"
    }
  ]
}
```

文件：`entry/src/main/module.json5`

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
  }
}
```

#### 预期输出

**验证标准**：

- 从工程文件判断现状：module.json5 未配置 metadata，高性能未开启，当前为默认流程；应用跟随系统，页面配色均为同名 base/dark 资源直接绑定。
- 解释默认流程在节点较多时的开销：颜色模式变化时全量重新执行前端组件的属性设置，前端执行和重复属性设置的开销随节点数量增长；本页包含数百个 Text，是切换卡顿的主要来源。
- 给出优化：在 entry/src/main/module.json5 的 module.metadata 中添加 configColorModeChangePerformanceInArkUI，value 为字符串 "true"；说明该能力从 API 20 起提供。
- 说明开启后的更新机制与收益来源：仅颜色模式变化且满足优化条件时，通过已注册的颜色资源与属性更新回调更新已有节点，减少全量前端执行和重复属性设置、降低 CPU 工作量；需要变化的颜色仍会更新和绘制，不承诺零开销、不编造提升比例。
- 给出可执行的 trace 验证方式，任选其一即可：通过 DevEco Studio Profiler 采集和分析 trace（开启前后各采集一次深浅色切换），或使用 hitrace 命令行采集；不要求同时提供多种方式或引用特定参考文件。切换只通过系统设置触发。定位应用主线程中 `OHOS::AppExecFwk::OHOSApplication::OnConfigurationUpdated` 后的切换处理片段：开启高性能时看 `AceContainer::UpdateColorMode` 下的 `Animate`；未开启时找到其下包含 `ViewFunctions::ExecuteReload` 前端刷新方法的 `Animate`。分别读取这两个目标 `Animate` 从开始到结束的总耗时进行对比，不能把 `ViewFunctions::ExecuteReload` 的单独耗时作为本次总耗时。结合子调用说明减少的是前端刷新次数，measure 和 render 的次数不会因此减少，不以测量、布局或渲染打点次数减少作为生效判据；不以参考文档中的定性收益预期当作本用例的实测结果或验收阈值。

**配置示例（省略无关字段）**：

```json5
{
  "module": {
    "metadata": [
      {
        "name": "configColorModeChangePerformanceInArkUI",
        "value": "true"
      }
    ]
  }
}
```

---

### 测试用例：FUNC-011

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：跨 HSP 资源的深浅色定义归属

#### 输入

共享标题切到深色后颜色不变，希望深色显示为 #FFE6E6E6。

前置条件：API 26；应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统；已开启高性能。同一应用的 entry 和 library HSP 均已安装。

文件：`entry/oh-package.json5`

```json5
{
  "name": "entry",
  "version": "1.0.0",
  "dependencies": {
    "library": "file:../library"
  }
}
```

文件：`library/src/main/module.json5`

```json5
{
  "module": {
    "name": "library",
    "type": "shared"
  }
}
```

文件：`entry/src/main/ets/pages/Index.ets`

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('共享标题')
        .fontColor($r('[library].color.shared_title'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

文件：`entry/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "shared_title",
      "value": "#FF445566"
    }
  ]
}
```

文件：`entry/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "shared_title",
      "value": "#FFABCDEF"
    }
  ]
}
```

文件：`library/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "shared_title",
      "value": "#FF202020"
    }
  ]
}
```

#### 预期输出

**验证标准**：

- 定位 shared_title 属于 library HSP；在 library/src/main/resources/dark/element/color.json 增加同名资源 #FFE6E6E6，保留其 base 定义。
- 保留页面的 $r('[library].color.shared_title') 和 HSP 依赖；entry 的同名 dark 颜色不会替代 library 的资源。
- 给出完整页面和必要颜色配置，说明跨 HSP 资源存在性需核对实际模块和运行结果。
- 核对冷启动深色及双向切换，确认使用 library 的目标资源。

---

### 测试用例：FUNC-012

**skill**：hmos-arkui-dark-light-adaptation  
**类型**：functional（功能验证）  
**场景**：保留 HSP 导出的 Resource 封装

#### 输入

HSP 导出的这种颜色写法能适配深浅色和高性能切换吗？

前置条件：API 26；应用已设置 `setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)` 跟随系统；已开启高性能。library 是同应用已安装的 HSP。

文件：`entry/oh-package.json5`

```json5
{
  "name": "entry",
  "version": "1.0.0",
  "dependencies": {
    "library": "file:../library"
  }
}
```

文件：`library/oh-package.json5`

```json5
{
  "name": "library",
  "version": "1.0.0",
  "main": "Index.ets"
}
```

文件：`library/src/main/ets/common/SharedColors.ets`

```ts
export class SharedColors {
  static title(): Resource {
    return $r('app.color.shared_title');
  }
}
```

文件：`library/Index.ets`

```ts
export { SharedColors } from './src/main/ets/common/SharedColors';
```

文件：`entry/src/main/ets/pages/Index.ets`

```ts
import { SharedColors } from 'library';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('共享标题')
        .fontColor(SharedColors.title())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

文件：`library/src/main/resources/base/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "shared_title",
      "value": "#FF202020"
    }
  ]
}
```

文件：`library/src/main/resources/dark/element/color.json`

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "shared_title",
      "value": "#FFE6E6E6"
    }
  ]
}
```

#### 预期输出

**验证标准**：

- 识别 SharedColors.title() 返回 library 内的稳定 Resource，现有 base/dark 配置和属性绑定可以保留。
- 核对 SharedColors 经 library/Index.ets 导出，调用方通过依赖包名导入，资源名由 HSP 内部管理。
- 结合保留的 Resource 解释深浅色匹配与高性能资源更新，无需改成一次读取的 number 缓存。
