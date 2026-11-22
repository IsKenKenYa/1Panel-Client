# RN（React Native OpenHarmony）内存优化

**适用场景**：鸿蒙应用嵌入 RNOH（React Native OpenHarmony）引擎，JS 运行时对象、图片解码内存、页面缓存、组件状态等占用过高，存在虚拟机参数未调优、后台 GC 未启用、图片未 resize、内存压力未监听等问题。

本方案包含四个互补的优化项：

1. **onMemoryLevel 内存压力监听**：通过 `AppState.addEventListener('memoryLevelChange', ...)` 监听系统内存压力等级，分级执行回收策略
2. **虚拟机后台 GC**：RN 实例配置 `enableBackgroundGC: true`，应用退后台时自动触发 JS VM GC
3. **JSVM 启动参数调优**：使用 `JSVM_INIT_OPTIONS_PRESET.LOW_MEMORY` 预设参数，降低新生代空间和 GC 触发阈值
4. **图片 Resize 适配**：缩略图/列表图/头像图使用 `resizeMethod="resize"`，避免大图解码浪费内存

## 架构概览

```
┌──────────────────────────────────────────────┐
│           React Native JS 层                  │
│  React 组件 / JS 业务逻辑 / Image / FlatList  │
├──────────────────────────────────────────────┤
│           RNOH 桥接层                         │
│  RNApp 配置 / RNAbility / JSVM 引擎          │
│  onMemoryLevel 透传 / enableBackgroundGC      │
├──────────────────────────────────────────────┤
│           ArkUI Native 层                     │
│  ArkUI 节点树 / 图片解码 / 组件渲染           │
└──────────────────────────────────────────────┘
```

## 问题定位

### 关键文件

| 文件路径 | 说明 |
|---------|------|
| RN 实例配置文件（创建 `RNApp` 的 `.ets` 文件） | `enableBackgroundGC`、`jsvmInitOptions` 配置 |
| RNAbility 或 UIAbility 派生类 | `onMemoryLevel` 系统回调接收 |
| JS 组件文件（`.tsx`/`.ts`） | `memoryLevelChange` 监听、`resizeMethod` 设置 |
| `package.json` | RNOH 依赖版本确认 |

### 搜索关键词

| 关键词 | 文件 | 检查内容 |
|--------|------|---------|
| `RNApp` | `.ets` 文件 | RN 实例创建配置，是否启用 `enableBackgroundGC` |
| `enableBackgroundGC` | `.ets` 文件 | 是否设置为 `true` |
| `jsvmInitOptions` | `.ets` 文件 | 是否配置 JSVM 启动参数，是否使用 LOW_MEMORY 预设 |
| `JSVM_INIT_OPTIONS_PRESET` | `.ets` 文件 | 是否导入并使用预设参数 |
| `RNAbility` | `.ets` 文件 | 是否继承 RNAbility（框架自动接收 onMemoryLevel） |
| `memoryLevelChange` | `.ts`/`.tsx` 文件 | JS 侧是否监听内存压力变化 |
| `memoryWarning` | `.ts`/`.tsx` 文件 | 是否监听内存警告 |
| `resizeMethod` | `.ts`/`.tsx` 文件 | 图片组件是否设置 `resizeMethod="resize"` |
| `@rnoh/react-native-openharmony` | `package.json` | 确认项目使用 RNOH |

---

## 优化项一：onMemoryLevel 内存压力监听

### 原理

HarmonyOS 提供 `onMemoryLevel()` 接口，通知应用当前系统内存压力状态（MODERATE / LOW / CRITICAL）。RNOH 已接入该能力，当应用继承 `RNAbility` 时，框架自动将内存压力信号透传到 JS 侧。开发者通过 `AppState.addEventListener('memoryLevelChange', callback)` 监听，按等级执行分级回收策略。

**注意**：后台已冻结的应用不会收到 `onMemoryLevel()` 回回，该接口仅适用于前台或可运行状态。

### 代码修改模板

#### 1. 确认 RNAbility 继承（ArkTS 侧）

```typescript
// ⚠️ 以下代码为 ArkTS 修改
// 确认应用的主 Ability 继承自 RNAbility，框架会自动接收 onMemoryLevel 回调
// 搜索项目中的 Ability 类定义，检查是否继承 RNAbility

// 正确示例：
import { RNAbility } from '@rnoh/react-native-openharmony';

export default class EntryAbility extends RNAbility {
  // 框架会自动处理 onMemoryLevel 并透传到 JS 侧
}
```

#### 2. JS 侧内存压力监听

```tsx
// ⚠️ 以下代码为 React Native JS/TSX 修改

import React, { useEffect } from 'react';
import { AppState, AppStateStatus } from 'react-native';

interface MemoryLevelInfo {
  level: number;
  levelName: string;
}

// 内存等级常量
const MEMORY_LEVEL_MODERATE = 0;   // 系统内存达到中等水平
const MEMORY_LEVEL_LOW = 1;        // 系统内存不足
const MEMORY_LEVEL_CRITICAL = 2;   // 系统内存非常紧张

/**
 * 内存压力监听 Hook
 * 在应用根组件或关键页面中使用
 */
export function useMemoryPressure(): void {
  useEffect(() => {
    // 监听内存等级变化
    const memoryLevelSubscription = AppState.addEventListener(
      'memoryLevelChange' as any,
      (info: MemoryLevelInfo) => {
        console.log('[Memory] level=', info.level, 'levelName=', info.levelName);

        switch (info.level) {
          case MEMORY_LEVEL_MODERATE:
            // 暂停低优先级预加载、减少缓存写入
            handleModeratePressure();
            break;
          case MEMORY_LEVEL_LOW:
            // 清理可重建缓存：图片内存缓存、列表数据缓存
            handleLowPressure();
            break;
          case MEMORY_LEVEL_CRITICAL:
            // 立即释放大对象、终止非必要任务、清理离屏资源
            handleCriticalPressure();
            break;
        }
      },
    );

    // 监听内存警告（仅在 CRITICAL 时额外触发）
    const memoryWarningSubscription = AppState.addEventListener(
      'memoryWarning',
      () => {
        console.warn('[Memory] memoryWarning received');
      },
    );

    return () => {
      memoryLevelSubscription.remove();
      memoryWarningSubscription.remove();
    };
  }, []);
}

// 分级回收策略函数
function handleModeratePressure(): void {
  // 暂停低优先级预加载任务
  // 减少缓存写入频率
}

function handleLowPressure(): void {
  // 清理图片内存缓存
  // 清理列表数据缓存
  // 释放离屏页面临时状态
}

function handleCriticalPressure(): void {
  // 立即释放大对象引用
  // 终止非必要后台任务
  // 清理所有可重建资源
}
```

---

## 优化项二：虚拟机后台 GC

### 原理

RNOH 提供 `enableBackgroundGC` 配置项。开启后，应用进入后台时框架向 JS 运行时发送后台内存压力信号，触发一次 GC，释放已经不可达的 JS 对象。适合用于降低后台态的 JS 堆占用，减少应用在后台驻留时对系统内存的持续占用。

**注意**：该能力只能回收已经不可达的对象，仍被引用的缓存不会因 GC 自动释放。

### 代码修改模板

```typescript
// ⚠️ 以下代码为 ArkTS 修改
// 在创建 RN 实例时开启 enableBackgroundGC

import { RNApp } from '@rnoh/react-native-openharmony';

// 修改前：未启用后台 GC
// RNApp({
//   rnInstanceConfig: {
//     name: 'app_name',
//     createRNPackages: getRNOHPackages,
//   },
//   appKey: 'app_name',
// })

// 修改后：启用后台 GC
RNApp({
  rnInstanceConfig: {
    name: 'app_name',
    createRNPackages: getRNOHPackages,
    enableBackgroundGC: true,  // 应用退后台时自动触发 JS VM GC
  },
  appKey: 'app_name',
})
```

**前置条件**：如果应用使用 ArkTS 页面路由容器，需确保前后台生命周期已正确接入，保证 RN 页面在进入后台时能收到对应的生命周期信号。

---

## 优化项三：JSVM 启动参数调优

### 原理

RNOH 在 `RNInstance` 配置中提供 `jsvmInitOptions`，用于向 JSVM 传递启动参数。框架内置了 `DEFAULT`、`LOW_MEMORY`、`HIGH_PERFORMANCE` 三套预设，通过调节 GC 触发时机和年轻代空间大小，在"更低内存占用"和"更高运行性能"之间做平衡。

**核心参数说明**：

| 参数 | 含义 | LOW_MEMORY 值 | 作用 |
|------|------|--------------|------|
| `--incremental-marking-hard-trigger` | 增量标记触发阈值（%） | 40 | 更早触发 GC，减少内存峰值 |
| `--min-semi-space-size` | 新生代最小大小（MB） | 1 | 减小年轻代空间，降低基础占用 |
| `--max-semi-space-size` | 新生代最大大小（MB） | 4 | 限制年轻代上限 |

**注意**：`jsvmInitOptions` 仅在使用 JSVM 引擎时生效，对 Hermes 无效。

### 代码修改模板

```typescript
// ⚠️ 以下代码为 ArkTS 修改

import {
  JSVM_INIT_OPTIONS_PRESET,
  RNApp,
} from '@rnoh/react-native-openharmony';

// 修改前：未配置 JSVM 参数（使用默认配置）
// RNApp({
//   rnInstanceConfig: {
//     name: 'app_name',
//     createRNPackages: getRNOHPackages,
//   },
//   appKey: 'app_name',
// })

// 修改后：使用 LOW_MEMORY 预设
RNApp({
  rnInstanceConfig: {
    name: 'app_name',
    createRNPackages: getRNOHPackages,
    jsvmInitOptions: JSVM_INIT_OPTIONS_PRESET.LOW_MEMORY,
  },
  appKey: 'app_name',
})
```

**可选**：同时启用后台 GC + JSVM 调优（推荐组合）：

```typescript
import {
  JSVM_INIT_OPTIONS_PRESET,
  RNApp,
} from '@rnoh/react-native-openharmony';

RNApp({
  rnInstanceConfig: {
    name: 'app_name',
    createRNPackages: getRNOHPackages,
    enableBackgroundGC: true,                                  // 退后台 GC
    jsvmInitOptions: JSVM_INIT_OPTIONS_PRESET.LOW_MEMORY,     // JSVM 低内存参数
  },
  appKey: 'app_name',
})
```

---

## 优化项四：图片 Resize 适配

### 原理

图片通常是 RN 页面中最容易产生较大内存占用的一类资源。当图片原始尺寸远大于组件实际显示尺寸时，即使最终只显示在较小区域，解码过程仍可能占用较多内存。RNOH 支持 `resizeMethod` 属性透传到底层图片节点。

- **resize**：在解码前对图片进行缩放，适合"图片明显大于显示区域"的场景
- **scale**：直接对图片做缩放显示，适合图片与显示区域尺寸接近的场景
- **auto**：框架自动选择

### 代码修改模板

```tsx
// ⚠️ 以下代码为 React Native JS/TSX 修改

import { Image } from 'react-native';

// 修改前：未指定 resizeMethod（依赖默认行为）
// <Image
//   source={{ uri: imageUrl }}
//   style={{ width: 120, height: 120 }}
// />

// 修改后：显式指定 resize="resize"
<Image
  source={{ uri: imageUrl }}
  style={{ width: 120, height: 120 }}
  resizeMethod="resize"
/>
```

**适用场景**（建议优先使用 resize）：

| 场景 | resizeMethod | 说明 |
|------|-------------|------|
| 长列表缩略图 | `resize` | 列表中大量小图，原图通常远大于显示区域 |
| 宫格图片 | `resize` | 多图网格，单图显示面积小 |
| 头像图 | `resize` | 头像尺寸固定且较小 |
| 瀑布流/小卡片 | `resize` | 卡片中图片通常缩放显示 |
| 大图预览/全屏图 | `scale` 或不设置 | 需要高质量显示，原图与显示尺寸接近 |

---

## 设备分档策略

### onMemoryLevel 回收策略分档

| 内存等级 | low（低端机） | medium（中端机） | high（高端机） |
|---------|-------------|---------------|-------------|
| MODERATE | 暂停所有预加载 + 清理非活跃缓存 | 暂停低优先级预加载 | 减少缓存写入频率 |
| LOW | 释放所有可重建缓存 + 终止后台任务 | 清理图片/列表缓存 | 暂停预加载 |
| CRITICAL | 释放全部非必要资源 | 释放大对象 + 清理离屏资源 | 清理可重建缓存 |

### JSVM 启动参数分档

| 设备分档 | jsvmInitOptions | 说明 |
|---------|----------------|------|
| low（≤8GB） | `LOW_MEMORY` | 新生代 1-4MB，GC 更早触发 |
| medium | `LOW_MEMORY` | 同上，平衡内存与性能 |
| high（>8GB） | `DEFAULT` 或 `HIGH_PERFORMANCE` | 按需选择，性能优先 |

---

## 其他优化建议

以下为低优先级建议，不包含完整代码模板，仅在分析报告中输出方向性建议：

### 长列表虚拟化

在 `FlatList`、`SectionList`、`VirtualizedList` 等长列表场景中，合理配置：

| 属性 | 建议值 | 说明 |
|------|--------|------|
| `removeClippedSubviews` | `true` | 移除屏幕外原生视图 |
| `initialNumToRender` | 按首屏可见项数 | 减少初始渲染数量 |
| `windowSize` | 按设备分档调整 | 控制渲染窗口大小 |
| `getItemLayout` | 固定高度项使用 | 跳过动态测量 |

数据量大、Item 结构复杂的场景，可评估使用 `FlashList` 替代。

### React 组件记忆化

| 优化手段 | 适用场景 | 说明 |
|---------|---------|------|
| `React.memo` | 列表 Item、重复渲染子组件 | 浅比较 Props 避免重渲染 |
| `PureComponent` | class 组件 | 内置 shouldComponentUpdate |
| `useMemo` | 计算结果、对象引用 | 缓存计算值 |
| `useCallback` | 事件处理函数 | 稳定函数引用 |

**关键**：保持 Props 引用稳定，避免匿名函数和内联对象导致记忆化失效。

### 生命周期资源释放

| 生命周期时机 | 需释放资源 |
|------------|----------|
| `useEffect` 返回函数 | 事件订阅、定时器 |
| `componentWillUnmount` | 缓存数据、大对象引用 |
| 页面隐藏 | 临时状态、预加载数据 |

### 大数据跨线程传递

| 场景 | 推荐方式 | 说明 |
|------|---------|------|
| Worker 间传递大对象 | Sendable / ISendable | 减少拷贝开销 |
| 并发任务数据共享 | Sendable 数据结构 | 共享而非复制 |

---

## 注意事项

- **onMemoryLevel 不适用于后台冻结态**：后台已冻结的应用不会收到回调，不能替代后台内存回收策略（需配合 `enableBackgroundGC`）
- **enableBackgroundGC 只回收不可达对象**：仍被引用的缓存不会自动释放，需结合业务逻辑主动清理
- **jsvmInitOptions 仅对 JSVM 引擎生效**：使用 Hermes 引擎时此配置无效
- **resizeMethod 仅在 RNOH 中生效**：需确认 RNOH 版本支持该属性透传
- **建议优先使用框架预设参数**：`JSVM_INIT_OPTIONS_PRESET.LOW_MEMORY` 而非自定义参数
- **前后台生命周期必须正确接入**：`enableBackgroundGC` 依赖 RN 页面收到前后台信号才能生效
- **图片同时配合服务端裁剪**：建议服务端按尺寸下发图片资源，避免下载超过实际显示需要的大图

## 验证方式

1. 修改前后使用 `hidumper --mem <PID>` 对比 JS heap 和 native heap 占用
2. 通过 `AppState.addEventListener('memoryLevelChange', ...)` 日志确认内存压力事件正常接收
3. 退后台后通过 `hidumper --mem <PID>` 确认 JS heap 占用下降（enableBackgroundGC 生效）
4. 对比使用 `LOW_MEMORY` 前后的新生代空间大小（通过 JSVM 调试接口）
5. 在长列表页面中使用 `resizeMethod="resize"` 前后对比 native heap 占用变化
