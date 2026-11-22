# @performance — 性能规则

针对 ArkUI 渲染性能、内存、资源使用、代码质量的检查规则。

## 规则集

- `plugin:@performance/recommended` — 15 条
- `plugin:@performance/all` — 35 条

> `recommended` 是 `all` 的子集。另有 39 条规则不在任何预设中（标注"—"），可通过 `rules` 字段逐条启用。

## 全部规则列表（74 条）

> **预设列说明**：`rec+all` = 在 recommended 和 all 中；`all` = 仅在 all 中；`—` = 不在任何预设中。

### UI 渲染优化

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/hp-arkui-load-on-demand` | — | warn | 推荐使用 LazyForEach |
| `@performance/hp-arkui-remove-container-without-property` | — | warn | 减少无属性冗余容器 |
| `@performance/hp-arkui-remove-redundant-nest-container` | — | warn | 减少冗余嵌套容器 |
| `@performance/hp-arkui-remove-redundant-state-var` | — | warn | 移除无关状态变量 |
| `@performance/hp-arkui-remove-unchanged-state-var` | — | warn | 移除不变状态变量 |
| `@performance/hp-arkui-use-reusable-component` | — | warn | 使用可复用组件 |
| `@performance/hp-arkui-use-object-link-to-replace-prop` | — | warn | 用 @ObjectLink 代替 @Prop |
| `@performance/hp-arkui-use-local-var-to-replace-state-var` | — | warn | 用本地变量替代状态变量 |
| `@performance/hp-arkui-use-row-column-to-replace-flex` | — | warn | 用 Row/Column 替代 Flex |
| `@performance/hp-arkui-replace-nested-reusable-component-by-builder` | — | warn | 用 Builder 替代嵌套可复用组件 |
| `@performance/hp-arkui-suggest-reuseid-for-if-else-reusable-component` | — | warn | if-else 可复用组件设置 reuseId |
| `@performance/hp-arkui-no-func-as-arg-for-reusable-component` | — | warn | 可复用组件禁止函数参数 |
| `@performance/hp-arkui-set-cache-count-for-lazyforeach-grid` | — | warn | LazyForEach 设置缓存数量 |
| `@performance/foreach-args-check` | rec+all | warn | 为 ForEach 设置 keyGenerator |
| `@performance/foreach-index-check` | all | suggestion | 避免用 index 作为 ForEach key |
| `@performance/hp-arkui-no-stringify-in-lazyforeach-key-generator` | — | warn | LazyForEach key 禁止 stringify |
| `@performance/hp-arkui-no-state-var-access-in-loop` | — | warn | 避免循环中读取状态变量 |
| `@performance/hp-arkui-use-grid-layout-options` | — | warn | 使用栅格布局选项 |
| `@performance/hp-arkui-use-id-in-get-resource-sync-api` | — | warn | 同步资源 API 使用 ID |
| `@performance/hp-arkui-use-onAnimationStart-for-swiper-preload` | — | warn | Swiper 预加载使用 onAnimationStart |
| `@performance/hp-arkui-use-attributeUpdater-control-refresh-scope` | — | warn | 用 AttributeUpdater 控制刷新范围 |
| `@performance/hp-arkui-limit-refresh-scope` | — | warn | 限制刷新范围 |
| `@performance/hp-arkui-wrap-waterflow-if-else-footer` | — | warn | WaterFlow if-else footer |
| `@performance/hp-arkui-reduce-pangesture-distance` | — | warn | 减少平移手势距离 |
| `@performance/init-list-component` | all | warn | List 组件必须初始化宽度和高度 |

### 动画

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/hp-arkui-combine-same-arg-animateto` | — | warn | 合并参数相同的 animateTo |
| `@performance/hp-arkui-use-scale-to-replace-attr-animateto` | — | warn | 用 scale 动画替代 animateTo |
| `@performance/hp-arkui-use-transition-to-replace-animateto` | — | warn | 用 transition 替代 animateTo |
| `@performance/update-state-var-between-animatetos-check` | rec+all | warn | animateTo 间避免更新状态变量 |

### 图片/媒体

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/hp-arkui-image-async-load` | — | warn | 大图异步加载 |
| `@performance/hp-arkui-suggest-use-effectkit-blur` | — | warn | 使用 EffectKit 模糊 |
| `@performance/hp-arkui-suggest-cache-avplayer` | — | warn | 缓存 AVPlayer |
| `@performance/hp-arkui-suggest-use-get-anonymousid-async` | — | warn | 异步获取匿名 ID |
| `@performance/gif-hardware-decoding-check` | rec+all | warn | 为 GIF 启用硬件解码 |
| `@performance/lottie-animation-destroy-check` | all | suggestion | 销毁 Lottie 动画 |
| `@performance/start-window-icon-check` | rec+all | suggestion | 启动图标不超过 256x256 |
| `@performance/monitor-invisible-area-in-image-animation` | rec+all | warn | 图片动画中监听不可见区域 |

### 资源使用

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/reasonable-audio-use-check` | all | suggestion | 后台释放音频资源 |
| `@performance/reasonable-sensor-use-check` | all | suggestion | 后台释放传感器资源 |
| `@performance/reasonable-gps-use-check` | all | suggestion | 后台停止定位服务 |
| `@performance/datashare-query-unrelease-check` | rec+all | warn | 数据库查询结果用完需关闭 |
| `@performance/dark-color-mode-check` | all | suggestion | 实现深色模式以降低功耗 |

### 状态管理

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/multiple-associations-state-var-check` | all | suggestion | 多组件共用数据源时条件更新 |
| `@performance/state-variable-usage-in-ui-format-check` | all | error | 状态变量在 UI 格式中的使用检查 |
| `@performance/hp-arkui-avoid-update-auto-state-var-in-aboutToReuse` | — | warn | aboutToReuse 中避免更新状态变量 |
| `@performance/hp-arkui-avoid-empty-callback` | — | warn | 避免设置空的系统回调监听 |

### 日志/代码质量

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/high-frequency-log-check` | rec+all | warn | 避免在频繁调用的函数中打印日志 |
| `@performance/hp-arkui-no-high-freq-log` | — | warn | 避免高频日志 |
| `@performance/no-use-any-import` | rec+all | warn | 避免通配符导入 |
| `@performance/hp-arkts-no-use-any-export-current` | — | warn | 不用 export * 导出当前模块 |
| `@performance/hp-arkts-no-use-any-export-other` | — | warn | 不用 export * 导出其他模块 |
| `@performance/hp-performance-no-closures` | — | warn | 避免闭包 |
| `@performance/hp-performance-no-dynamic-cls-func` | — | warn | 避免动态声明函数和类 |
| `@performance/constant-property-referencing-check-in-loops` | all | suggestion | 循环内提取常量属性访问 |
| `@performance/crypto-replacement-check` | rec+all | warn | 加密替代检查 |
| `@performance/bad-deep-clone-check` | rec+all | warn | 优先使用结构化克隆 |
| `@performance/avoid-overusing-custom-component-check` | rec+all | warn | 避免过度使用自定义组件 |
| `@performance/reuse-date-instances-check` | rec+all | warn | 复用 Date 实例 |

### 数据结构/类型

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/typed-array-check` | all | suggestion | TypedArray 检查 |
| `@performance/sparse-array-check` | all | suggestion | 稀疏数组检查 |
| `@performance/number-init-check` | all | suggestion | 数字初始化检查 |
| `@performance/timezone-interface-check` | all | suggestion | 时区接口检查 |

### Web 组件

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/web-cache-mode-check` | all | suggestion | Web 缓存模式 |
| `@performance/web-on-active-check` | rec+all | warn | Web 组件 onActive 处理 |
| `@performance/hp-arkui-use-taskpool-for-web-request` | — | warn | Web 请求用 TaskPool |
| `@performance/hp-arkui-use-word-break-to-replace-zero-width-space` | — | warn | 用 word-break 替代零宽空格 |

### JS 引擎/代码缓存

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/js-code-cache-by-precompile-check` | all | suggestion | JS 预编译代码缓存 |
| `@performance/js-code-cache-by-interception-check` | all | suggestion | JS 拦截代码缓存 |

### 渲染/组件

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/nested-post-frame-callback-check` | all | suggestion | 嵌套 postFrameCallback |
| `@performance/custom-node-memory-leak-check` | all | warn | 自定义节点内存泄漏检查 |
| `@performance/tabs-on-change-check` | all | suggestion | Tabs onChange 检查 |
| `@performance/waterflow-data-preload-check` | rec+all | suggestion | WaterFlow 数据预加载 |
| `@performance/no-high-loaded-frame-rate-range` | rec+all | warn | 禁止使用固定高帧率 |

### FFRT

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@performance/hp-ffrt-no-use-std` | — | warn | FFRT 禁止使用 std |

## 示例

```json
{
  "ruleSet": ["plugin:@performance/all"],
  "rules": {
    "@performance/hp-arkui-load-on-demand": "error",
    "@performance/foreach-args-check": "error",
    "@performance/high-frequency-log-check": "warn"
  }
}
```
