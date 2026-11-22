# Accessibility Kit - 关怀模式API参考

## API概览

Accessibility Kit提供了关怀模式相关的API接口，用于查询、设置和监听关怀模式状态。

原文链接：无直接API参考文档（基于开发指南中的接口说明整理）

## 核心API接口

### 1. 查询关怀模式状态

#### isSeniorModeEnabled()

**功能**：查询系统关怀模式开关状态

**接口定义**：
```typescript
isSeniorModeEnabled(): Promise<boolean>
```

**返回值**：
- `Promise<boolean>`：异步返回关怀模式状态
  - `true`：系统关怀模式已打开
  - `false`：系统关怀模式已关闭

**使用示例**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

accessibility.isSeniorModeEnabled().then((data: boolean) => {
  console.info(`isSeniorModeEnabled: ${JSON.stringify(data)}`);
}).catch((err: BusinessError) => {
  console.error(`failed, Code is ${err.code}, message is ${err.message}`);
});
```

**API版本**：26.0.0+

---

### 2. 监听系统关怀模式状态

#### onSeniorModeStateChange()

**功能**：注册系统关怀模式状态变化事件的监听回调

**接口定义**：
```typescript
onSeniorModeStateChange(callback: Callback<boolean>): void
```

**参数**：
- `callback: Callback<boolean>`：状态变化回调函数
  - 回调参数为boolean，表示系统关怀模式状态

**使用示例**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

// 注册监听
accessibility.onSeniorModeStateChange((data: boolean) => {
  console.info(`subscribe senior mode state change, result: ${JSON.stringify(data)}`);
});

// 取消监听
accessibility.offSeniorModeStateChange(callback);
```

**API版本**：26.0.0+

---

### 3. 取消监听系统关怀模式状态

#### offSeniorModeStateChange()

**功能**：取消注册系统关怀模式状态变化事件的监听回调

**接口定义**：
```typescript
offSeniorModeStateChange(callback?: Callback<boolean>): void
```

**参数**：
- `callback?: Callback<boolean>`：可选，要取消的回调函数。如果不传，则取消所有监听

**使用示例**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

// 取消特定监听
accessibility.offSeniorModeStateChange(callback);

// 取消所有监听
accessibility.offSeniorModeStateChange();
```

**API版本**：26.0.0+

---

### 4. 获取应用关怀模式状态

#### getSeniorModeStateForSelf()

**功能**：获取"设置"中应用管理页面关怀模式的开关状态

**接口定义**：
```typescript
getSeniorModeStateForSelf(): Promise<boolean>
```

**返回值**：
- `Promise<boolean>`：异步返回应用关怀模式状态

**使用示例**：
```typescript
import accessibility from '@ohos.accessibility';

const state = await accessibility.getSeniorModeStateForSelf();
console.info(`App senior mode state: ${state}`);
```

**API版本**：26.0.0+

---

### 5. 设置应用关怀模式状态

#### setSeniorModeStateForSelf()

**功能**：设置设备"设置"中应用管理页面内关怀模式开关状态

**接口定义**：
```typescript
setSeniorModeStateForSelf(state: boolean): Promise<void>
```

**参数**：
- `state: boolean`：关怀模式状态（true-开启，false-关闭）

**使用示例**：
```typescript
import accessibility from '@ohos.accessibility';

// 开启关怀模式
await accessibility.setSeniorModeStateForSelf(true);

// 关闭关怀模式
await accessibility.setSeniorModeStateForSelf(false);
```

**API版本**：26.0.0+

---

### 6. 监听应用关怀模式状态

#### onSeniorModeStateChangeForSelf()

**功能**：注册设备"设置"中应用管理页面内关怀模式开关状态监听

**接口定义**：
```typescript
onSeniorModeStateChangeForSelf(callback: Callback<boolean>): void
```

**参数**：
- `callback: Callback<boolean>`：状态变化回调函数

**使用示例**：
```typescript
import accessibility from '@ohos.accessibility';

const callback = (data: boolean) => {
  console.info(`App senior mode state changed: ${data}`);
};

// 注册监听
accessibility.onSeniorModeStateChangeForSelf(callback);
```

**API版本**：26.0.0+

---

### 7. 取消监听应用关怀模式状态

#### offSeniorModeStateChangeForSelf()

**功能**：取消注册设备"设置"中应用管理页面内关怀模式开关状态监听

**接口定义**：
```typescript
offSeniorModeStateChangeForSelf(callback?: Callback<boolean>): void
```

**参数**：
- `callback?: Callback<boolean>`：可选，要取消的回调函数

**使用示例**：
```typescript
import accessibility from '@ohos.accessibility';

// 取消特定监听
accessibility.offSeniorModeStateChangeForSelf(callback);

// 取消所有监听
accessibility.offSeniorModeStateChangeForSelf();
```

**API版本**：26.0.0+

## 模块导入

### 方式1：导入整个模块
```typescript
import accessibility from '@ohos.accessibility'
```

### 方式2：从Kit导入
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

## 错误处理

建议使用BusinessError进行错误处理：

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

try {
  const state = await accessibility.isSeniorModeEnabled();
} catch (err) {
  const error = err as BusinessError;
  console.error(`Error code: ${error.code}, message: ${error.message}`);
}
```

## API版本兼容性

| API接口 | 最低API版本 | Kit | 说明 |
|--------|------------|-----|------|
| isSeniorModeEnabled | 26.0.0 | AccessibilityKit | 查询系统关怀模式状态 |
| onSeniorModeStateChange | 26.0.0 | AccessibilityKit | 监听系统关怀模式状态 |
| offSeniorModeStateChange | 26.0.0 | AccessibilityKit | 取消监听系统关怀模式状态 |
| getSeniorModeStateForSelf | 26.0.0 | AccessibilityKit | 获取应用关怀模式状态 |
| setSeniorModeStateForSelf | 26.0.0 | AccessibilityKit | 设置应用关怀模式状态 |
| onSeniorModeStateChangeForSelf | 26.0.0 | AccessibilityKit | 监听应用关怀模式状态 |
| offSeniorModeStateChangeForSelf | 26.0.0 | AccessibilityKit | 取消监听应用关怀模式状态 |

## 参考文档

- [应用声明接入系统关怀模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-appconfig)
- [应用内关怀模式与系统设置同步](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-senior-mode-description)
- [获取关怀模式状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-description)