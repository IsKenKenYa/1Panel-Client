# ComponentContent 构造函数签名错误

## 坑点描述

在 P2 方向（C→ArkTS）中，ArkTS 侧用 `@Builder` 定义组件后，需用 `ComponentContent` 封装才能传给 Native 侧。HarmonyOS NEXT（API 12+）的 `ComponentContent` 构造函数要求**三个参数**：

1. `UIContext` — 通过自定义组件的 `this.getUIContext()` 获取
2. `WrappedBuilder<[T]>` — 通过 `wrapBuilder()` 包装 `@Builder` 函数
3. `T args` — builder 参数

常见错误：
- **漏传 `UIContext`**：直接传 `WrappedBuilder` 或 `@Builder` 函数作为第一个参数 → 编译报 `Argument of type 'WrappedBuilder<...>' is not assignable to parameter of type 'UIContext'`
- **直接传 `@Builder` 函数**：未用 `wrapBuilder()` 包装 → 类型不匹配
- **在组件外部创建**：全局函数中无法获取 `UIContext`（`getUIContext()` 是自定义组件内置方法）

## API 事实

本坑点涉及的 ArkTS API（`ComponentContent` 构造 / `getUIContext()` / `wrapBuilder()`）的完整签名、.d.ts 符号定位与来源核验方式见 `references/api-facts.md`——该文件为本 skill 的 ArkTS API 唯一权威源，本文件不在本地重复维护签名表与行号，避免行号漂移与重复维护。

关键要点（细节见 `api-facts.md` ArkTS API 表）：

- `ComponentContent` 构造函数要求三个参数：`UIContext`（`this.getUIContext()` 获取）、`WrappedBuilder<[T]>`（`wrapBuilder()` 包装 `@Builder` 函数）、`args: T`
- `getUIContext()` 是自定义组件（`@Component struct`）的内置方法，返回组件所属的 `UIContext`，**不得**在组件外部调用
- `wrapBuilder()` 是 ArkTS 全局内置函数，无需 import
- `ComponentContent` 只有一个泛型参数 `T extends Object`（非 `Object, Object` 两个）。`string`、自定义 `interface` / `class` 均满足 `T extends Object` 约束

## 错误用法（反模式）

```typescript
// ❌ 错误 1：漏传 UIContext，直接传 @Builder 函数作为第一个参数
const content = new ComponentContent(myBuilder, { message: 'hello' });
// 编译报错：Argument of type '...Builder...' is not assignable to parameter of type 'UIContext'

// ❌ 错误 2：漏传 UIContext，传了 wrapBuilder 但位置错误
const content = new ComponentContent(wrapBuilder(myBuilder), { message: 'hello' });
// 编译报错：Argument of type 'WrappedBuilder<...>' is not assignable to parameter of type 'UIContext'

// ❌ 错误 3：在组件外部创建 ComponentContent（无法获取 UIContext）
export function createContent(): ComponentContent<Params> {
  // getUIContext() 在组件外部不可用，UIContext 无法获取
  return new ComponentContent<Params>(???, wrapBuilder(myBuilder), { message: 'hello' });
}
```

## 正确用法

```typescript
import { ComponentContent } from '@kit.ArkUI';

@Builder
function myBuilder(message: string) {
  Text(message)
}

@Entry
@Component
struct Index {
  private content: ComponentContent<string> | null = null;

  aboutToAppear() {
    // ✅ 正确：在组件内创建，传 this.getUIContext() + wrapBuilder + args
    this.content = new ComponentContent<string>(
      this.getUIContext(),
      wrapBuilder(myBuilder),
      'hello'
    );
  }

  aboutToDisappear() {
    if (this.content !== null) {
      this.content.dispose();
      this.content = null;
    }
  }
}
```

## 风险

- 编译期报类型不匹配错误（`WrappedBuilder` 不可赋值给 `UIContext`），但错误信息可能具有误导性——开发者可能误以为是 `wrapBuilder` 用法错误，而非漏传 `UIContext` 参数
- 在组件外部（全局函数）创建 `ComponentContent` 时无法获取 `UIContext`，需将创建逻辑移入组件生命周期方法（如 `aboutToAppear`）内
- `ComponentContent` 的泛型只有一个参数 `T`，误写为 `ComponentContent<Object, Object>` 会导致类型声明与实际不符
