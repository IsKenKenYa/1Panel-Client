# 减少颜色资源维护：反色

反色可以减少部分深色颜色资源定义与后续维护，但开发者需要根据业务设计、验证反色算法。系统默认算法是保留 alpha 的 RGB 取反，不一定满足品牌色、状态色或前景/背景可读性要求。

## 生效前提

对当前 SDK 支持反色的组件和颜色属性，先确认：

1. **平台 API 20 及以上。** 反色 C API 从 API 20 起提供，需同时核对编译声明、链接和运行设备。
2. **已开启高性能。** 目标模块 `module.metadata` 中 `configColorModeChangePerformanceInArkUI` 的 `value` 为字符串 `"true"`，位置见[高性能开关](high-performance.md)。
3. **Native C API 已初始化，反色已启用。** 在目标节点创建前的 UI 线程同步调用 `OH_ArkUI_SetForceDarkConfig(..., true, ..., algorithm)`。本 Skill 将该配置放在 `windowStage.loadContent` 的加载成功回调内，以完整覆盖目标节点、避免反色不全。调用前完成或复用 Native C API 初始化，检查加载结果和反色配置返回值。
4. **目标组件所在作用域处于深色，且包含在配置范围内。** 检查应用/局部颜色模式，以及配置中的 `uiContext` 和 `nodeType` 是否覆盖目标组件。
5. **目标组件允许反色。** API 21+ 检查组件及祖先是否设置 `allowForceDark(false)`；任一处禁用都会排除对应子树。未设置该属性或设置 `true` 均可，`true` 不能覆盖祖先的 `false`，也不能代替第 2、3 项。

## 颜色的处理顺序

| 颜色来源 | 深色模式下的处理 |
| --- | --- |
| 直接色值，如 `.fontColor('#FF203040')` | 满足上述条件时进入反色算法 |
| `$r` 引用的颜色资源有可用的同名 dark 定义 | 优先使用该资源的 dark 值 |
| `$r` 引用的颜色资源没有 dark 定义 | 在支持的实现中可进入反色算法 |

这里检查的是**当前颜色资源**，不是要求整个工程都没有 `dark/color.json`。同一应用可以保留精确配色的 dark 资源，让其他颜色进入算法。不得把“`$r` 引用的颜色不能进入反色、需要改成字面量”当作规则陈述；精简时保留 base 定义，只评估移除对应的 dark 定义。具体支持范围按目标 SDK 和颜色属性核对，版本条件与官方来源见 [API 与适配依据](api-facts.md)。

跨 HAP/HSP 时检查该资源所属模块的 dark 定义，并保留 Resource 的模块信息；不能用调用方是否有同名 dark 颜色判断。访问方式见[跨包资源](adaptation.md#访问跨-haphsp-包资源)。

## 方案选择

1. 检查能否复用系统语义颜色，以及哪些颜色需要精确控制。
2. 保留需要精确控制的 dark 资源，评估其他颜色交由算法处理。
3. 检查 API 20+、高性能开关及 Native 接入条件。需要新增 Native 模块时，说明实际接入范围，按当次任务要求落实。
4. 验证目标 SDK 与属性后逐项精简，保持 base 定义和有效引用，不批量删除整个 dark 文件。

## C API 接入

首次接入时，先调用 `OH_ArkUI_QueryModuleInterfaceByName` 完成 Native C API 初始化，再调用 `OH_ArkUI_SetForceDarkConfig` 配置反色：

```cpp
#include <arkui/native_interface.h>
#include <arkui/native_node.h>

// 仅演示算法接入；业务需自行设计，不能直接视为产品配色。
static uint32_t ExampleInvert(uint32_t argb)
{
    return (argb & 0xFF000000) | ((~argb) & 0x00FFFFFF);
}

int ConfigureDarkInversion()
{
    // 先完成 Native C API 初始化，供后续反色配置使用。
    auto* api = OH_ArkUI_QueryModuleInterfaceByName(
        ARKUI_NATIVE_NODE, "ArkUI_NativeNodeAPI_1");
    if (api == nullptr) {
        return -1;
    }
    return OH_ArkUI_SetForceDarkConfig(
        nullptr, true, ARKUI_NODE_UNDEFINED, ExampleInvert);
}
```

先查询接口的原因是：`OH_ArkUI_SetForceDarkConfig` 依赖 Native C API 已初始化，自身不会完成初始化；未初始化时返回 500（`ARKUI_ERROR_CODE_CAPI_INIT_ERROR`）。只导入 `.so` 或注册 N-API 模块不能代替这一步。同一进程已有初始化时可以复用，无需重复查询。

本 Skill 的反色接入统一在 `windowStage.loadContent` 加载成功回调内，于节点创建前的 UI 线程同步完成配置，以保证目标节点完整生效、避免反色不全。下面的写法明确将调用放在成功回调体内。

以下假设工程已有 `nativeTheme.configure(enabled)` N-API 桥，内部完成或复用上述 C API 初始化后设置反色。合并原有 Ability 生命周期和加载错误处理：

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

- `nullptr` 配合上述用法按进程配置，`ARKUI_NODE_UNDEFINED` 表示所有组件；可按真实需求配置指定组件类型。
- 传入空算法指针可使用系统默认算法；这不表示默认算法满足业务要求。
- 跨实例独立算法、混合全局禁用/局部启用等能力按目标版本文档核对，不自行扩展。
- `allowForceDark` 从 API 21 起提供，不把此属性用于 API 20 工程。
- UIExtension 跨进程场景需宿主和扩展协同适配；遇到该场景再展开相应接口。

## 利用反色方法精简 color.json 前的检查

选择有 dark、无 dark 和直接色值三类输入，对比算法开/关、高性能开/关。检查冷启动深色和双向切换，同时确认透明度、品牌色、状态色及前景/背景对比。配置成功返回值不能替代实际界面和算法调用验证。
