# 默认能力与颜色资源

## 默认条件

先检查应用是否通过 `setColorMode` 固定了颜色模式，再检查系统颜色、应用资源和直接色值的使用。

默认效果满足开发者需求时，先说明“当前已支持深浅色，无需额外功能适配”。系统组件的默认主题可以呈现深浅色效果，不要求为了演示默认能力显式添加系统背景色。

对于没有开启高性能的工程，继续说明：

1. 当前为非高性能模式；高性能切换从 **API 20 起提供，包含 API 20**。
2. 配置位置是目标模块 `module.json5` 的 `module.metadata`，添加 `configColorModeChangePerformanceInArkUI`，`value` 为字符串 `"true"`，保留其他配置。
3. 默认流程在切换时全量重新执行前端组件属性设置；高性能流程在仅颜色模式变化且满足优化条件时，通过已注册的颜色资源及属性回调更新已有节点。
4. 减少全量前端执行和重复属性设置，可降低切换时的 CPU 工作量，帮助缩短切换耗时、减轻卡顿；仍会完成必要的颜色更新和绘制。实际收益取决于页面和设备，不编造提升比例。

介绍选项前读取[高性能切换](high-performance.md)中的配置示例和更新机制。先给出上述信息，再提示开发者选择是否启用；尚未选择启用时提供可操作的配置说明或示例。已明确要求启用时按已有授权接入，已选择不启用时不重复询问。最终按 [Skill 的通用报告格式](../SKILL.md#报告格式)组织，保留上述必要说明。

应用未调用 `setColorMode` 且没有任何 dark 资源时，按给定文档的规则，系统组件可能维持浅色体验。全部采用系统组件和系统颜色、希望明确跟随系统的工程，可按实际情况设置：

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';

// 合并进已有 Ability 初始化逻辑。
this.context.getApplicationContext().setColorMode(
  ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
```

使用现有异常处理，不覆盖原有生命周期。`COLOR_MODE_NOT_SET` 表示恢复跟随系统，不是高性能开关。

## 系统颜色

默认风格合适时可使用系统语义资源，不必再定义两套相同用途的应用颜色：

```ts
Text('标题')
  .fontColor($r('sys.color.ohos_id_color_text_primary'))
```

系统颜色同样需要结合应用的颜色模式配置判断效果，不保证所有自定义硬编码内容自动换色。

## 自定义资源

当默认风格不满足需求时，在目标模块中使用相同资源名：

```text
src/main/resources/
├── base/element/color.json
└── dark/element/color.json
```

base：

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "page_title",
      "value": "#FF202020"
    }
  ]
}
```

dark：

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    },
    {
      "name": "page_title",
      "value": "#FFE6E6E6"
    }
  ]
}
```

页面统一引用：

```ts
Text('标题').fontColor($r('app.color.page_title'))
```

按语义复用颜色，合并既有定义，避免重复名称或失效引用。不要为了同一个颜色差异分别创建 light/dark 两个 ID，再在属性函数中做选择。

## 访问跨 HAP/HSP 包资源

先区分同 bundle 跨 module 与跨 bundle，核对资源所属模块、依赖和已安装模块。为跨包颜色补充深浅色值时，在**资源所属模块**中配置同名 base/dark；调用方的同名资源不会替代它。

| 场景 | 访问方式 |
| --- | --- |
| 同应用、跨 HSP 的静态 UI 引用 | `$r('[library].color.shared_title')`，library 替换为真实 HSP 模块名 |
| HSP 为其他模块提供稳定的资源接口 | HSP 导出返回 Resource 的资源类，调用方直接绑定 |
| 同应用、跨 HAP/HSP，需要处理资源数据 | 使用目标模块 Context 的 resourceManager，按 ID 或名称读取 |
| 不同 bundle | 文档中的 createBundleContext 跨 bundle 方式仅支持系统应用，普通三方应用不据此接入 |

### 方式一：直接引用 HSP 资源

调用方 `entry/oh-package.json5` 合并依赖：

```json5
{
  "dependencies": {
    "library": "file:../library"
  }
}
```

资源定义在 `library/src/main/resources/`：

```text
library/src/main/resources/
├── base/element/color.json   # shared_title = #FF202020
└── dark/element/color.json   # shared_title = #FFE6E6E6
```

调用方页面直接绑定：

```ts
Text('共享标题').fontColor($r('[library].color.shared_title'))
```

`[library]` 中填写实际模块名；依赖名及公开入口按工程配置核对。该语法用于跨 HSP，不把另一个 HAP 名称套进方括号作为通用访问方式。编译时不会校验这类跨 HSP 资源是否存在，需核对资源文件及实际运行结果。

跨 HSP 原始文件可使用 `$rawfile('[library].icons/logo.png')`。rawfile 不按深浅色限定词自动匹配；需要两套图片时使用匹配限定词的 media 资源或明确的业务选择。

### 方式二：HSP 导出 Resource

`library/src/main/ets/common/SharedColors.ets`：

```ts
export class SharedColors {
  static title(): Resource {
    return $r('app.color.shared_title');
  }
}
```

`library/Index.ets` 对外导出：

```ts
export { SharedColors } from './src/main/ets/common/SharedColors';
```

调用方通过实际包名导入并绑定：

```ts
import { SharedColors } from 'library';

// 放入页面的 build 中。
Text('共享标题').fontColor(SharedColors.title())
```

资源名封装在 HSP 内部，调用方无需感知它的变更。这个方法返回稳定的 Resource，可以保留；核对其实际返回值及资源所属模块，不因为属性调用封装方法就改成颜色数值。已有 Resource 继续保留其所属 bundle/module 信息。

### 方式三：通过模块 Context 读取数据

API 12+ 的异步接口示例，用于同应用中已存在的目标 HAP/HSP：

```ts
import { application, common } from '@kit.AbilityKit';

export async function readModuleTitleColor(
  host: common.Context, moduleName: string
): Promise<number> {
  const target: common.Context = await application.createModuleContext(host, moduleName);
  return target.resourceManager.getColorByNameSync('shared_title');
}
```

调用方处理 Promise 失败；目标模块名、资源名和实际可用性均需检查。不要在 build 或逐个属性求值时反复创建 Context。

**深浅色更新需要单独处理：**新模块 Context 在创建时继承传入 Context 的资源配置，随后不会随其资源配置变化自动更新。读出的 number 也是一次取值。高性能开关不会自动更新这个缓存；确需数值处理时，在有效配置变化路径中使用新配置获取资源并更新 UI 绑定状态，同时处理首次显示。跨 HSP 的普通 UI 配色优先保留前两种 Resource 引用。

有 dark 定义时优先使用资源、无 dark 定义时评估反色，也应检查目标资源所属模块。

来源：[资源分类与访问：访问跨 HAP/HSP 包资源](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/quick-start/resource-categories-and-access.md#访问跨haphsp包资源)、[application.createModuleContext](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-ability-kit/js-apis-app-ability-application.md#applicationcreatemodulecontext)。

## 其他内容

- 图片可使用 base/media 与 dark/media 的同名资源；简单 SVG 可评估 fillColor 配合颜色资源。
- Web 的深色配置需核对 Web 专用接口，不能用普通颜色资源替代其设置。
- BuilderNode、ComponentContent 等自定义节点需核对当前版本的环境配置传递和更新方式，避免机械增加重复的全量更新。
- 局部作用域使用 [WithTheme](local-theme.md)，高性能流程见[高性能切换](high-performance.md)。
