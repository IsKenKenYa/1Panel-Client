# API 与适配依据

## 版本与配置

| 能力 | 起始版本 | 关键条件 |
| --- | --- | --- |
| WithTheme | API 12 | 核对支持组件、单个直接子组件和资源条件 |
| application.createModuleContext | API 12 | 异步创建同应用目标模块 Context；资源配置创建时继承，后续不随原 Context 自动变化 |
| 高性能颜色切换 | API 20 | module.metadata 中 configColorModeChangePerformanceInArkUI 的 value 为字符串 "true" |
| OH_ArkUI_SetForceDarkConfig | API 20 | Native C API 已初始化；本 Skill 在 loadContent 加载成功回调内、节点创建前的 UI 线程同步配置；依赖高性能 |
| allowForceDark(false) | API 21 | 用于组件退出自动反色，非局部颜色模式开关 |

编译 SDK 决定声明可用性，运行设备决定能力是否存在；target、compatible 的含义不能互换。不要把应用版本号、oh-package.json5 的 modelVersion 当作平台 API。

## 适配条件与注意事项

当前颜色资源已有 dark 定义时优先使用该资源；无 dark 定义时，按目标 SDK 和颜色属性的支持条件核对反色，不一概排除 `$r`。

WithTheme 文档示例提到 dark 资源条件。应区分系统配色与应用自定义资源，并核对应用颜色模式配置；不能将示例中的应用 dark 文件作为所有 WithTheme 用法的硬性前提。处理方式见[局部深浅色](local-theme.md)。

反色配置在 windowStage.loadContent 加载成功回调内，于节点创建前的 UI 线程同步完成，以完整覆盖目标节点、避免反色不全。先确认 Native C API 已初始化，再检查配置返回值及实际效果。具体代码见[反色接入](force-dark.md#c-api-接入)。

## 官方来源

- [应用深浅色适配](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/ui-dark-light-color-adaptation.md)
- [访问跨 HAP/HSP 包资源](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/quick-start/resource-categories-and-access.md#访问跨haphsp包资源)
- [application.createModuleContext](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-ability-kit/js-apis-app-ability-application.md#applicationcreatemodulecontext)
- [WithTheme](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-container-with-theme.md)
- [反色 C API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/capi-native-node-h.md)
- [自定义组件生命周期](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-page-custom-components-lifecycle.md)
- [allowForceDark](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-allow-force-dark.md)
- [AppStorageV2](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-appstoragev2.md)
- [Monitor](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-monitor.md)
- [Computed](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-computed.md)
