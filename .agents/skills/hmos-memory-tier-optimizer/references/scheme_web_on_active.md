# 方案九：Web 预渲染活跃状态优化

## 来源

基于华为 HarmonyOS 最佳实践 `@performance/web-on-active-check`：
https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-web-on-active-check

官方建议：使用 Web 预渲染技术的应用，在预渲染完成后通过 `onFirstMeaningfulPaint` 调用停止渲染接口 `onInactive`。

## 适用场景

- 页面使用 `Web({ ... })` 组件。
- 代码中显式调用 `WebviewController.onActive()`，或使用 Web 预渲染、预编译脚本、预加载能力。
- `onActive()` 后未在 `onFirstMeaningfulPaint` 回调中调用 `onInactive()`。
- Web 预渲染完成后 native heap、ArkWeb 相关进程或渲染资源占用持续偏高。

## 优化原理

`onActive()` 会让 Web 处于活跃渲染状态。预渲染场景下，首个有意义绘制完成后，预渲染目标已经达成；如果继续保持活跃渲染，Web 渲染资源可能持续占用。应在 `onFirstMeaningfulPaint` 中调用 `onInactive()` 停止渲染，等页面真实可见或需要交互时再按业务路径恢复活跃。

## 检测规则

### 关键词

| 关键词 | 用途 |
|--------|------|
| `Web(` | 定位 Web 组件 |
| `onActive` | 定位活跃渲染启动点 |
| `onInactive` | 判断是否有停止渲染 |
| `onFirstMeaningfulPaint` | 判断是否在首个有意义绘制后停止渲染 |
| `precompileJavaScript` | 定位 Web 预编译脚本场景 |
| `onControllerAttached` | 定位控制器挂载后的预处理场景 |

### 告警条件

满足以下任一组时输出 High 级别告警：

- 存在 `Web(` 和 `controller.onActive()`，但同一 Web 链式调用中缺少 `onFirstMeaningfulPaint`。
- 存在 `onFirstMeaningfulPaint`，但回调中未调用 `controller.onInactive()`。
- 存在 `precompileJavaScript`、`onControllerAttached`、预渲染或预加载逻辑，但没有停止渲染路径。

## ArkTS 修改模板

```ts
import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct WebComponent {
  private controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Web({ src: 'https://www.example.com', controller: this.controller })
        .onPageBegin(() => {
          this.controller.onActive();
        })
        .onFirstMeaningfulPaint(() => {
          this.controller.onInactive();
        })
    }
  }
}
```

## 与预加载方案的关系

本方案与 `scheme_web_preload.md` 配套使用：

- `scheme_web_preload.md` 负责 Web 预加载能力是否需要按设备分档。
- 本方案负责 Web 预渲染或 `onActive()` 后是否在首个有意义绘制完成时停止渲染。

不要把 `onInactive()` 当作组件销毁替代。如果 Web 组件已经不再需要，应通过条件渲染或页面生命周期让组件下树；如果只是预渲染阶段结束，则使用 `onInactive()` 控制活跃状态。

## 验证方式

1. 在 `code-linter.json5` 中启用官方规则：

```json5
{
  "rules": {
    "@performance/web-on-active-check": "warn"
  }
}
```

2. 重新扫描 ArkTS 代码，确认 `onActive()` 或 Web 预渲染路径附近存在 `onFirstMeaningfulPaint(() => controller.onInactive())`。
3. 采集优化前后 meminfo，对比 native heap、ArkWeb 相关进程和 PSS 总量。
4. 回归页面真实展示和交互路径，确认页面进入可交互状态时业务仍会按需恢复 Web 活跃状态。

## 注意事项

- 普通 Web 页面没有使用 `onActive()`、预渲染或预编译脚本时，不强制套用本方案。
- 不要在首个有意义绘制前调用 `onInactive()`，否则可能影响预渲染收益。
- 如果同一页面存在多个 Web 控制器，应逐个检查控制器与 `onInactive()` 的配对关系。
