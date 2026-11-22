# 属性更新兼容性

## 判断依据

检查颜色模式变化后，组件属性能否正确更新，并定位需要调整的代码。

| 检查内容 | 如何判断与处理 |
| --- | --- |
| 属性函数或主题对象按模式返回不同值 | 读取调用定义、数据来源和触发更新的路径。只依赖全量重新执行时，改为统一资源或事件驱动状态 |
| 普通成员变量、非响应式主题或缓存 | 核对写入后是否会更新目标属性；仅改变普通字段不足以证明 UI 会刷新 |
| AppStorage 或共享模型已更新 | 核对实际 key、对象身份、观察字段、回调及绑定位置是否连通 |
| 跨 HAP/HSP 的颜色 | 核对资源所属模块及其 base/dark；保留稳定的跨 HSP Resource。模块 Context 的独立配置和读出的颜色数值需有显式更新路径 |
| 颜色变化回调只返回资源 | 检查返回值是否被使用；监听回调返回一个值不等于更新 UI |
| 初始值只在变化回调中设置 | 补查冷启动即深色时的初始化 |
| 自定义节点或脱离页面树的内容 | 核对版本与实际环境通知方式，避免新增重复的全量更新 |

函数、条件分支或 `$r` 的出现本身不是问题，不得把“按模式选择的条件表达式与高性能机制不兼容”作为定性结论。默认模式依靠全量前端更新重执行这类表达式；开启高性能后需要状态驱动的有效更新触发，缺触发（如状态不可观测）才是要定位的问题。已连通的响应式更新保留；直接统一资源绑定通常不需要业务监听器。

## 两个修复方案

发现开启高性能后，按模式返回不同资源的属性缺少有效更新路径时，同时给出两种方案，让开发者了解改动和性能差异：

| 方案 | 资源与业务写法 | 更新方式 |
| --- | --- | --- |
| 方案一：兼容更新 | 保留 title_light/title_dark 及原有选择逻辑 | 监听模式变化，更新 UI 绑定的状态；相关属性仍通过前端更新 |
| 方案二：高性能资源 | 统一为 title_color，在 base/dark 定义不同值 | 直接绑定同一个 Resource，由颜色资源更新流程换色 |

交付两个方案时，分别提供涉及文件的相对路径与完整代码，包括需要调整的页面、模型、事件写入和资源定义；已正确的代码注明复用。兼容方案须覆盖首次显示初始化和后续模式变化，推荐方案与备选方案使用相同的代码完整性要求。

方案一保证功能兼容，受影响的配色仍需前端选择和属性更新，无法获得方案二减少这部分执行的收益。该限制只涉及依赖这些更新的部分，其他属性仍可使用资源更新流程。纯配色优先方案二；需要保留业务主题、文本内容、尺寸或布局联动时，保持业务语义，使用方案一的状态更新。

## 方案一：保留业务判断，兼容更新

### V1：StorageLink/Watch 更新绑定状态

新建或复用 AppStorage key 前，先检查工程内既有占用：检索 `AppStorage.` 的读写调用、`@StorageLink`/`@StorageProp` 的既有 key，并核对多 UIAbility 写入方与 oh_modules 第三方依赖。按结果处理：

| 检查结果 | 处理 |
| --- | --- |
| 同 key 已存不同类型 | 更换 key（如加应用前缀 `app_color_mode`）。强行链接类型不匹配，运行时异常或静默失效 |
| 同 key 存在其他写入方 | 收敛为单一写入方或换 key。多写入方互相覆盖，会意外触发其他订阅者的 Watch |
| 同 key、同类型、同语义 | 直接复用，不重复初始化 |

写入方初始化须先于页面链接：事件源放在 UIAbility `onCreate`（早于 `loadContent`）即可满足。

事件来源示意，合并原有生命周期并保留业务：

```ts
// UIAbility 初始化：
AppStorage.setOrCreate('colorMode', this.context.config.colorMode);
// onConfigurationUpdate(newConfig: Configuration)：
if (newConfig.colorMode !== undefined) {
  AppStorage.setOrCreate('colorMode', newConfig.colorMode);
}
```

适配后的页面示例：新增监听后，在回调中重新执行原有资源选择函数，将结果写入实际绑定的状态。

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @StorageLink('colorMode') @Watch('refreshPaint')
  mode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
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
    Text('函数选择标题').fontColor(this.watchedPaint)
  }
}
```

更新链路为 AppStorage → StorageLink 的 mode → Watch 回调 → selectTitlePaint 中的三元选择 → watchedPaint → fontColor。Watch 回调必须使用选择结果更新绑定状态，只调用函数并丢弃返回值不会更新该属性。Watch 不在首次初始化时自动执行，因此 aboutToAppear 主动同步一次。

这是有效的兼容更新链路，可保留原有 title_light/title_dark 定义和选择逻辑。高性能省去的是颜色变化引起的全量前端属性重执行，不会关闭正常的状态驱动更新；切换时仍需执行上述监听、资源选择和前端属性更新。不能把恢复正常换色描述成该属性已获得纯资源换色的高性能收益。首次显示和后续变化都需覆盖。参见 [Watch 的观察变化和行为表现](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-watch.md#观察变化和行为表现)。

### V2：共享可观测对象与属性绑定

```ts
// ThemeState.ets
import { ConfigurationConstant } from '@kit.AbilityKit';

@ObservedV2
export class ThemeState {
  @Trace colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
}

export const themeState: ThemeState = new ThemeState();
```

初始化时从当前配置写入 `themeState.colorMode`；颜色变化事件或应用主动设置模式的有效路径更新同一对象。

```ts
// Index.ets
import { ConfigurationConstant } from '@kit.AbilityKit';
import { ThemeState, themeState } from '../common/ThemeState';

@Entry
@ComponentV2
struct Index {
  @Local theme: ThemeState = themeState;

  build() {
    Text('标题').fontColor(this.theme.colorMode ===
      ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      ? $r('app.color.title_dark') : $r('app.color.title_light'))
  }
}
```

- `@ObservedV2` 标记类，内部字段仍需 `@Trace` 才能观察对应变化；仅有类装饰器或将对象放入 `@Local` 都不能替代字段观察。可在同一个 ThemeState 模型上补齐装饰器，无需另建对照对象。见 [ObservedV2/Trace 的观察能力](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-new-observedv2-and-trace/)。
- 需要监听后的业务处理时，可使用 `@Monitor('theme.colorMode')` 更新 UI 绑定的 `@Local` 状态，并补齐首次显示的初始化。
- `@Computed` 用于可复用的派生结果，装饰 getter，依赖需可观测。它不是每个简单配色分支都需要添加的步骤。
- AppStorageV2.connect 可共享可观测 class 对象；事件侧和页面侧必须获取相同 key、类型对应的对象，并处理返回结果。
- V1 AppStorage 与 AppStorageV2 不会因为 key 相同而自动同步。按组件保持原有 V1/V2 模型，不机械互换装饰器。

这同样是兼容更新：状态变化后前端重新执行相关选择和属性设置。保留有效实现时，向开发者说明它与下一方案的性能差异。

## 方案二：统一资源名，使用高性能颜色更新

将按深浅色选择 title_light/title_dark 的三元表达式替换为直接绑定 title_color。以下两个文件位于同一个资源所属模块。

`entry/src/main/resources/base/element/color.json`：

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

`entry/src/main/resources/dark/element/color.json`：

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

`entry/src/main/ets/pages/Index.ets`：

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('标题').fontColor($r('app.color.title_color'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

高性能开关已正确配置时，该配色使用统一资源更新，不需为它新增 StorageLink/Watch。V2 页面使用相同资源配置，保持 ComponentV2。只清理这项配色不再需要的监听或资源选择，保留其他业务使用的逻辑与资源。跨 HSP 时在 HSP 中配置，并保留跨包 Resource 引用，见[跨包资源](adaptation.md#访问跨-haphsp-包资源)。

## 扫描结果的使用

`scan_dark_light.py` 提供版本、配置、颜色资源、状态字段、绑定及函数调用候选，支持查看同文件方法和可关联的调用。动态配置、复杂间接调用和跨文件对象关系仍需读取代码确认。

确认问题时输出文件与行号、实际链路、影响和改法。证据不足时列明缺少的定义或触发点；不把候选直接写成已确认故障，也不把未命中候选写成全工程通过。
