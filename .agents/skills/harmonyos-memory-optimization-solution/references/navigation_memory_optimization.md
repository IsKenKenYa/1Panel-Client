# Navigation 内存优化策略指南

## 目录

1. [内存优化概述](#内存优化概述)
2. [configuration 属性](#configuration-属性)
3. [NavigationConfiguration 配置项](#navigationconfiguration-配置项)
4. [stackSizeLimit 路由栈大小限制](#stacksizelimit-路由栈大小限制)
5. [recyclePagesOnLowMemory 低内存回收](#recyclepagesonlowmemory-低内存回收)
6. [clearContentStackOnPrimaryNavigation 左起右清栈](#clearcontentstackonprimarynavigation-左起右清栈)
7. [完整使用示例](#完整使用示例)

---

## 内存优化概述

Navigation 组件是路由导航的根视图容器，一般作为 Page 页面的根容器使用。当应用通过 NavPathStack 管理多个 NavDestination 子页面时，路由栈中的所有页面实例（包括不可见页面）都会占用内存。随着页面不断入栈，内存占用持续增长，尤其在深度嵌套路由或长列表+导航场景下更为突出。

从 API version 26.0.0 开始，Navigation 新增 `configuration` 属性，支持通过 `NavigationConfiguration` 配置路由栈大小限制；从 API version 26.1.0 开始，新增 `recyclePagesOnLowMemory` 和 `clearContentStackOnPrimaryNavigation` 属性，在低内存时自动回收不可见页面，进一步降低内存占用。

---

## configuration 属性

### 接口说明

```typescript
configuration(config: NavigationConfiguration)
```

设置 Navigation 配置项，包括路由栈大小限制、低内存回收和左起右清栈能力。

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

**参数：**

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| config | [NavigationConfiguration](#navigationconfiguration-配置项) | 是 | Navigation 配置项。 |

### 基本用法

```typescript
Navigation(this.stack) {
  // ...
}
.configuration({
  stackSizeLimit: 5,
  recyclePagesOnLowMemory: true,
  clearContentStackOnPrimaryNavigation: false
})
```

---

## NavigationConfiguration 配置项

Navigation 配置项。

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

### 属性

| 名称 | 类型 | 只读 | 可选 | 起始版本 | 说明 |
| --- | --- | --- | --- | --- | --- |
| stackSizeLimit | number | 否 | 是 | 26.0.0 | Navigation 路由栈的活跃页面节点数量限制。默认值：0，表示不限制。取值小于等于 0 时不限制；取值大于 0 时，将活跃页面节点数量限制为指定值，超过限制后按先入先出顺序自动销毁较早入栈的页面节点，NavPathInfo 完整保留在路由栈中，支持后续重新创建页面。 |
| recyclePagesOnLowMemory | boolean | 否 | 是 | 26.1.0 | 是否在收到低内存信号时回收不可见页面。默认值：false。true：收到低内存信号时回收不可见的 NavDestination 页面实例，NavPathInfo 会保留，页面后续可被重新创建；false：收到低内存信号时不回收。 |
| clearContentStackOnPrimaryNavigation | boolean | 否 | 是 | 26.1.0 | 是否开启 Navigation 左起右清栈能力。默认值：false。详见[左起右清栈](#clearcontentstackonprimarynavigation-左起右清栈)。 |

---

## stackSizeLimit 路由栈大小限制

### 工作原理

`stackSizeLimit` 限制路由栈中活跃页面节点（NavDestination 实例）的数量。当页面不断入栈超过限制时，系统按照先入先出（FIFO）顺序自动销毁较早入栈的页面实例。

### 关键特性

1. **NavPathInfo 保留**：被销毁的页面实例的 NavPathInfo（包括页面名称、参数等）仍完整保留在路由栈中。
2. **支持重新创建**：当用户回退到被销毁的页面时，系统会根据保留的 NavPathInfo 重新创建 NavDestination 页面实例。
3. **默认不限制**：默认值为 0，表示不限制路由栈大小，所有页面实例常驻内存。
4. **取值规则**：取值小于等于 0 时不限制；取值大于 0 时限制为指定值。

### 示例

```typescript
Navigation(this.stack) {
  // ...
}
.configuration({
  stackSizeLimit: 5 // 限制活跃页面节点数量为5，超过后自动销毁最早入栈的页面
})
```

---

## recyclePagesOnLowMemory 低内存回收

### 工作原理

`recyclePagesOnLowMemory` 控制是否在整机低内存时自动回收不可见的 NavDestination 页面实例。当整机内存达到 `MEMORY_LEVEL_LOW` 或 `MEMORY_LEVEL_CRITICAL` 时，系统自动回收路由栈中不可见的页面实例。

**起始版本：** 26.1.0

### 关键特性

1. **仅回收不可见页面**：只回收路由栈中当前不可见的 NavDestination 页面实例，不影响当前可见页面。
2. **NavPathInfo 保留**：回收后页面的 NavPathInfo 仍保留在路由栈中，用户回退时可重新创建页面。
3. **默认不回收**：默认值为 false，低内存时不自动回收。
4. **与生命周期联动**：回收和重新创建时会触发自定义组件生命周期回调（`aboutToDisappear` / `aboutToAppear` 等）。

### 示例

```typescript
Navigation(this.stack) {
  // ...
}
.configuration({
  recyclePagesOnLowMemory: true // 低内存时自动回收不可见页面
})
```

---

## clearContentStackOnPrimaryNavigation 左起右清栈

### 工作原理

`clearContentStackOnPrimaryNavigation` 控制 Navigation 在 Split 模式下的左起右清栈能力。

**起始版本：** 26.1.0

### 左起右清栈说明

Navigation 显示为 Split 模式时，如果用户在主页侧（NavBar 或主页 NavDestination）的操作（如点击页面中的按钮等）触发了页面跳转，那么 Navigation 页面栈中第一个新创建的页面之前的页面会被系统清除，只保留第一个新创建的页面及其之后的页面。

### 示例

```typescript
Navigation(this.stack) {
  Column() {
    MyControlPanel()
  }
  .width('100%')
  .height('100%')
}
.width('100%')
.height('100%')
.title('NavBar')
.titleMode(NavigationTitleMode.Mini)
.mode(NavigationMode.Split)
.navDestination(this.MyDestMap)
.configuration({
  clearContentStackOnPrimaryNavigation: true // 开启左起右清栈
})
```

---

## 完整使用示例

### 示例1：组合配置路由栈限制与低内存回收

```typescript
@Entry
@Component
struct NavigationMemoryOptimizeDemo {
  private stack: NavPathStack = new NavPathStack();

  @Builder
  MyDestMap(name: string) {
    if (name === 'one') {
      MyPageOne()
    } else {
      MyPageTwo()
    }
  }

  build() {
    Navigation(this.stack) {
      Column() {
        Button('push pageOne').onClick(() => {
          this.stack.pushPath({ name: 'one' })
        })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('NavBar')
    .navDestination(this.MyDestMap)
    .configuration({
      // 限制活跃页面节点数量为5
      stackSizeLimit: 5,
      // 低内存时自动回收不可见页面
      recyclePagesOnLowMemory: true
    })
  }
}
```

参考[Navigation 内存优化示例](../assets/NavigationMemOptExample.ets)

### 示例2：开启左起右清栈效果

```typescript
@Component
struct MyControlPanel {
  private stack: NavPathStack | undefined = undefined;

  aboutToAppear(): void {
    let info = this.queryNavigationInfo();
    if (info) {
      this.stack = info.pathStack;
    }
  }

  build() {
    Column() {
      Button('push pageOne').onClick(() => {
        this.stack?.pushPath({ name: 'one' })
      }).margin({ top: 25 })
      Button('push pageTwo').onClick(() => {
        this.stack?.pushPath({ name: 'two' })
      }).margin({ top: 25 })
      Button('pop').onClick(() => {
        this.stack?.pop()
      }).margin({ top: 25 })
    }
  }
}

@Component
struct MyPageOne {
  build() {
    NavDestination() {
      Column() {
        MyControlPanel()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('PageOne')
  }
}

@Component
struct MyPageTwo {
  build() {
    NavDestination() {
      Column() {
        MyControlPanel()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('PageTwo')
  }
}

@Entry
@Component
struct NavigationConfig {
  private stack: NavPathStack = new NavPathStack();

  @Builder
  MyDestMap(name: string) {
    if (name === 'one') {
      MyPageOne()
    } else {
      MyPageTwo()
    }
  }

  build() {
    Navigation(this.stack) {
      Column() {
        MyControlPanel()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('NavBar')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Split)
    .navDestination(this.MyDestMap)
    .configuration({
      clearContentStackOnPrimaryNavigation: true
    })
  }
}
```

## 核心约束

- `configuration` 属性通过 `NavigationConfiguration` 配置路由栈内存优化策略，`stackSizeLimit` 从 API 26.0.0 开始支持，`recyclePagesOnLowMemory` 和 `clearContentStackOnPrimaryNavigation` 从 API 26.1.0 开始支持。
- `stackSizeLimit` 限制路由栈活跃页面节点（NavDestination 实例）数量，超过限制后按 FIFO 销毁最早入栈的页面实例；NavPathInfo 保留在路由栈中，回退时可重新创建。默认值 0 表示不限制。
- `recyclePagesOnLowMemory` 控制低内存时是否自动回收不可见 NavDestination 页面实例（NavPathInfo 保留），默认 false 不回收。
- 页面实例被销毁/回收后重新创建时会触发自定义组件生命周期回调，必须确保 `aboutToAppear` / `aboutToDisappear` 能正确处理页面状态初始化。
- `clearContentStackOnPrimaryNavigation` 仅在 Navigation 显示为 Split 模式时生效，Stack 模式下不生效。
- `stackSizeLimit` 与 `recyclePagesOnLowMemory` 可同时配置，前者限制活跃页面数量上限，后者在低内存时进一步回收。
- `configuration` 仅可在 Stage 模型下使用。

