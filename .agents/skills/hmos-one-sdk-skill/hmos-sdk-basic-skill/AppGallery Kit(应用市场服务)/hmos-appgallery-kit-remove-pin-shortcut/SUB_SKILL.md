---
name: hmos-appgallery-kit-remove-pin-shortcut
description: 删除应用桌面快捷方式,支持标准删除和静默删除两种模式,需要shortcutId参数,适用于快捷方式管理、应用功能入口清理场景
---

# 删除应用内快捷方式技能

## 功能描述

本技能用于删除应用已创建的桌面快捷方式。通过调用 `productViewManager.removePinShortcut` 接口,用户可以删除当前应用的桌面快捷方式。该功能支持两种删除模式:

1. **标准删除**: 调用接口后弹出系统确认框,用户确认后删除快捷方式
2. **静默删除**: 申请静默删除权限后,无需用户确认即可直接删除快捷方式

**核心能力**:
- 删除指定的桌面快捷方式
- 支持通过shortcutId精确定位快捷方式
- 支持静默删除模式(需申请权限)
- 提供Promise异步回调

## 使用场景

### 触发词
- "删除快捷方式"
- "移除快捷方式"
- "清理快捷方式"
- "删除桌面快捷方式"
- "remove shortcut"
- "删除应用内快捷方式"

### 能做
- 删除应用已创建的桌面快捷方式
- 通过shortcutId精确删除指定快捷方式
- 提供标准删除和静默删除两种模式
- 删除前可先通过checkPinShortcutPermitted检查快捷方式是否存在

### 绝不做
- 不能删除其他应用的快捷方式(只能删除当前应用的快捷方式)
- 不能在没有shortcutId的情况下执行删除
- 不能在模拟器上执行(仅支持真机)
- 不能在TV设备上使用(6.0.2(22)版本开始TV设备才支持快捷方式功能)

### 补充
- **版本要求**: HarmonyOS 6.1.1(24)及以上版本
- **设备支持**: Phone、Tablet、PC/2in1,以及TV(从6.0.2(22)版本开始)
- **模型约束**: 仅可在Stage模型下使用
- **模拟器限制**: 不支持模拟器,必须使用真机调试
- **静默删除**: 需要在AppGallery Connect中申请"静默删除桌面快捷方式"权限

## 调用规范和规则

### 输入约束
- **shortcutId**: 字符串类型,长度不超过63字节,必须是通过checkPinShortcutPermitted接口获取的有效快捷方式ID
- **context**: UIAbilityContext对象,必须是当前应用的上下文
- **权限要求**: 
  - 标准删除: 无需特殊权限
  - 静默删除: 需要在AppGallery Connect中申请"静默删除桌面快捷方式"权限

### 执行约束
- **最大耗时**: 接口调用应在5秒内完成
- **前置条件**: 
  - 应用已创建对应的桌面快捷方式
  - shortcutId有效且未过期
  - 用户已授权删除操作(标准删除模式)
- **并发限制**: 不建议短时间内频繁调用删除接口

### 内容约束
- **禁止操作**: 
  - 禁止使用无效或过期的shortcutId
  - 禁止删除其他应用的快捷方式
  - 禁止在没有用户确认的情况下强制删除(未申请静默权限时)

### 降级约束
- **快捷方式不存在**: 提示用户快捷方式已被删除或不存在
- **权限不足**: 引导用户申请静默删除权限或使用标准删除模式
- **设备不支持**: 提示当前设备不支持此功能,建议用户手动删除快捷方式
- **网络异常**: 提示网络异常,建议稍后重试

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查设备是否为真机(模拟器不支持)
2. 检查HarmonyOS版本是否≥6.1.1(24)
3. 检查设备类型是否支持(Phone/Tablet/PC/2in1/TV)
4. 确认要删除的快捷方式shortcutId

**参数准备**:
```typescript
// 导入必要的模块
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

// 准备参数
const TAG: string = 'RemovePinShortcut';
```

### 步骤2: 调用API删除快捷方式

**示例代码**:
```typescript
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'RemovePinShortcut';

@Entry
@Component
struct RemovePinShortcut {
  build() {
    Column() {
      Button("RemovePinShortcut")
        .onClick(() => {
          try {
            // 获取UIAbility上下文
            const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            
            // 设置快捷方式ID(通过checkPinShortcutPermitted接口获取)
            const shortcutId = 'xxx'; // 替换为实际的shortcutId
            
            // 调用删除快捷方式接口
            productViewManager.removePinShortcut(uiContext, shortcutId)
              .then(() => {
                hilog.info(0x0001, TAG, `removePinShortcut success.`);
                // 删除成功后的处理
              })
              .catch((error: BusinessError) => {
                hilog.error(0x0001, TAG, `removePinShortcut error. code is ${error.code}, message is ${error.message}`);
                // 删除失败的处理
              });
          } catch (err) {
            hilog.error(0x0001, TAG, `removePinShortcut failed, code is ${err.code}, message is ${err.message}`);
            // 异常处理
          }
        })
        .width('100%')
    }
    .margin(16)
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

### 步骤3: 错误处理

```typescript
// 完整的错误处理代码
async function removeShortcut(uiContext: common.UIAbilityContext, shortcutId: string): Promise<void> {
  try {
    // 参数校验
    if (!uiContext) {
      throw new Error('UIAbilityContext is required');
    }
    if (!shortcutId || shortcutId.length === 0) {
      throw new Error('shortcutId is required and cannot be empty');
    }
    if (shortcutId.length > 63) {
      throw new Error('shortcutId length cannot exceed 63 bytes');
    }

    // 调用删除接口
    await productViewManager.removePinShortcut(uiContext, shortcutId);
    hilog.info(0x0001, TAG, 'removePinShortcut success.');
    
  } catch (error) {
    const err = error as BusinessError;
    
    // 错误码处理
    switch (err.code) {
      case 401:
        hilog.error(0x0001, TAG, 'Parameter error. Please check the input parameters.');
        break;
      case 1006620001:
        hilog.error(0x0001, TAG, 'System internal error. Please try again later.');
        break;
      case 1006620006:
        hilog.error(0x0001, TAG, 'The shortcut is not verified or has expired.');
        break;
      case 1006620007:
        hilog.error(0x0001, TAG, 'User refused to delete shortcut.');
        break;
      default:
        hilog.error(0x0001, TAG, `removePinShortcut failed, code: ${err.code}, message: ${err.message}`);
    }
    
    throw err;
  }
}
```

### 步骤4: 降级处理

```typescript
// 降级处理代码
async function removeShortcutWithFallback(
  uiContext: common.UIAbilityContext, 
  shortcutId: string
): Promise<void> {
  try {
    // 尝试调用API删除
    await productViewManager.removePinShortcut(uiContext, shortcutId);
    hilog.info(0x0001, TAG, 'removePinShortcut success.');
    
  } catch (error) {
    const err = error as BusinessError;
    
    // 根据错误码进行降级处理
    if (err.code === 401) {
      // 参数错误,提示用户检查参数
      hilog.warn(0x0001, TAG, 'Invalid parameters, please check shortcutId.');
      throw new Error('Invalid parameters');
      
    } else if (err.code === 1006620007) {
      // 用户拒绝删除,标准删除模式下的正常行为
      hilog.info(0x0001, TAG, 'User cancelled the delete operation.');
      return; // 不抛出异常,视为正常取消
      
    } else if (err.code === 1006620006) {
      // 快捷方式不存在或已过期
      hilog.warn(0x0001, TAG, 'Shortcut does not exist or has expired.');
      throw new Error('Shortcut not found');
      
    } else {
      // 其他错误,记录日志并提示用户
      hilog.error(0x0001, TAG, `removePinShortcut failed: ${err.message}`);
      throw err;
    }
  }
}
```

### 步骤5: 完整使用示例

```typescript
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'RemovePinShortcut';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct RemoveShortcutExample {
  // 存储快捷方式ID(实际使用时需要先通过checkPinShortcutPermitted获取)
  private shortcutId: string = 'id_test1';

  build() {
    Column({ space: 20 }) {
      Text('快捷方式管理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Button('删除快捷方式')
        .width('80%')
        .height(50)
        .onClick(() => this.removeShortcut());

      Text('提示: 删除快捷方式需要用户确认')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10 });

    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }

  /**
   * 删除快捷方式
   */
  private async removeShortcut(): Promise<void> {
    try {
      // 1. 获取UIAbility上下文
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      // 2. 参数校验
      if (!this.shortcutId || this.shortcutId.length === 0) {
        hilog.error(DOMAIN, TAG, 'shortcutId is required');
        this.showToast('快捷方式ID不能为空');
        return;
      }

      // 3. 调用删除接口
      hilog.info(DOMAIN, TAG, `Removing shortcut: ${this.shortcutId}`);
      await productViewManager.removePinShortcut(uiContext, this.shortcutId);
      
      // 4. 删除成功
      hilog.info(DOMAIN, TAG, 'removePinShortcut success.');
      this.showToast('快捷方式删除成功');
      
    } catch (error) {
      const err = error as BusinessError;
      this.handleRemoveError(err);
    }
  }

  /**
   * 处理删除错误
   */
  private handleRemoveError(error: BusinessError): void {
    let message: string = '删除失败';
    
    switch (error.code) {
      case 401:
        message = '参数错误,请检查快捷方式ID';
        break;
      case 1006620001:
        message = '系统内部错误,请稍后重试';
        break;
      case 1006620006:
        message = '快捷方式不存在或已过期';
        break;
      case 1006620007:
        message = '用户取消删除操作';
        return; // 用户取消不算错误
      default:
        message = `删除失败: ${error.message}`;
    }
    
    hilog.error(DOMAIN, TAG, `removePinShortcut error: code=${error.code}, message=${error.message}`);
    this.showToast(message);
  }

  /**
   * 显示Toast提示
   */
  private showToast(message: string): void {
    // 实际使用时可以调用promptAction.showToast
    hilog.info(DOMAIN, TAG, `Toast: ${message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查shortcutId是否为空,长度是否超过63字节 |
| 1006620001 | 系统内部错误 | 稍后重试,如持续出现请联系技术支持 |
| 1006620006 | 快捷方式未验证或已过期 | 快捷方式可能已被删除,或tid已过期,需重新校验 |
| 1006620007 | 用户拒绝删除快捷方式 | 用户在确认框中选择了取消,属正常行为 |

**注意**: 错误码说明基于相关API推断,具体错误码可能需要参考最新文档。

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AbilityKit": "^6.1.1(24)",
    "@kit.BasicServicesKit": "^6.1.1(24)",
    "@kit.PerformanceAnalysisKit": "^6.1.1(24)",
    "@kit.AppGalleryKit": "^6.1.1(24)"
  }
}
```

### 环境要求
- **HarmonyOS SDK**: 6.1.1(24)及以上版本
- **DevEco Studio**: 4.0及以上版本
- **设备要求**: Phone、Tablet、PC/2in1,或TV(从6.0.2(22)开始)
- **调试方式**: 必须使用真机调试,不支持模拟器

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.AppGalleryKit'
```
**解决方法**: 
- 确保HarmonyOS SDK版本≥6.1.1(24)
- 在`build-profile.json5`中配置正确的SDK版本
- 同步项目依赖

**问题2: getUIContext方法不存在**
```
Error: Property 'getUIContext' does not exist on type 'Component'
```
**解决方法**: 
- 确保使用的是最新的ArkUI组件语法
- 检查DevEco Studio版本是否支持最新API
- 确认组件使用了@Entry和@Component装饰器

**问题3: 模拟器运行提示错误**
```
Error: 应用市场推荐服务不支持模拟器
```
**解决方法**: 
- 使用真机进行调试
- 模拟器环境不支持此功能

**问题4: 删除快捷方式无响应**
```
调用接口后没有弹出确认框,也没有错误信息
```
**解决方法**: 
- 检查设备是否支持该功能
- 确认shortcutId是否正确
- 查看日志输出,确认接口是否被正确调用
- 检查是否在TV设备上运行(6.0.2(22)以下版本不支持)

## 常见问题与解决方法

### Q1: 如何获取要删除的快捷方式shortcutId?
**原因**: 删除快捷方式需要提供shortcutId参数
**解决方法**:
- 首先通过`productViewManager.checkPinShortcutPermitted`接口创建快捷方式时会返回shortcutId
- 将shortcutId保存到本地存储,删除时从本地存储读取
- 示例代码:
```typescript
// 创建快捷方式时保存shortcutId
const result = await productViewManager.checkPinShortcutPermitted(...);
const shortcutId = 'id_test1'; // 使用创建时定义的shortcutId
// 保存到本地存储
localStorage.setItem('shortcutId', shortcutId);

// 删除时读取
const savedShortcutId = localStorage.getItem('shortcutId');
await productViewManager.removePinShortcut(context, savedShortcutId);
```

### Q2: 标准删除和静默删除有什么区别?
**原因**: 用户可能不了解两种删除模式的区别
**解决方法**:
- **标准删除**: 调用接口后,系统会弹出确认框,用户需要手动确认才会删除快捷方式
- **静默删除**: 需要在AppGallery Connect中申请权限,调用接口后无需用户确认直接删除
- 申请静默删除权限步骤:
  1. 登录AppGallery Connect
  2. 选择项目和应用
  3. 进入"开放能力管理"页面
  4. 申请"静默删除桌面快捷方式"权限
  5. 提交申请材料(应用介绍、使用场景、录屏等)
  6. 等待1-3个工作日审批

### Q3: 删除快捷方式失败,提示"快捷方式不存在或已过期"怎么办?
**原因**: 快捷方式可能已被手动删除或tid已过期
**解决方法**:
- 快捷方式可能已被用户手动从桌面删除
- tid(Transaction ID)可能已过期,需要重新校验
- 建议在删除前先检查快捷方式是否存在:
```typescript
// 检查快捷方式是否存在(需要先实现检查逻辑)
try {
  await productViewManager.removePinShortcut(context, shortcutId);
} catch (error) {
  if (error.code === 1006620006) {
    // 快捷方式不存在,提示用户或自动处理
    console.log('快捷方式已不存在,无需删除');
  }
}
```

### Q4: 在模拟器上运行提示"无法获取内容,请点击屏幕重试"怎么办?
**原因**: 应用市场推荐服务不支持模拟器
**解决方法**:
- 必须使用真机进行调试
- 模拟器环境下无法使用快捷方式相关功能
- 确保真机系统版本≥6.1.1(24)

### Q5: 如何判断删除是否成功?
**原因**: 用户需要确认删除操作的结果
**解决方法**:
- 使用Promise的then和catch回调处理结果
- then: 删除成功
- catch: 删除失败或用户取消
- 错误码1006620007表示用户取消,属正常行为,不应视为错误
```typescript
productViewManager.removePinShortcut(context, shortcutId)
  .then(() => {
    // 删除成功
    console.log('快捷方式删除成功');
  })
  .catch((error: BusinessError) => {
    if (error.code === 1006620007) {
      // 用户取消删除
      console.log('用户取消了删除操作');
    } else {
      // 删除失败
      console.error('删除失败:', error.message);
    }
  });
```

## 输出结果报告

执行删除快捷方式操作完成后,应输出以下信息:

```typescript
{
  "status": "success", // 或 "failed"
  "action": "removePinShortcut",
  "shortcutId": "id_test1",
  "timestamp": "2026-07-03T10:30:00.000Z",
  "message": "快捷方式删除成功",
  "apiUsed": [
    "productViewManager.removePinShortcut"
  ]
}
```

**成功状态**:
- status: "success"
- message: "快捷方式删除成功"或"用户取消删除操作"

**失败状态**:
- status: "failed"
- message: 错误描述信息
- 错误码: 具体错误码

## 参考文档

- [API开发指南 - 删除应用内快捷方式](references/appgallery-productview-removeshortcut.md)
- [API参考说明 - productViewManager](references/store-productviewmanager.md)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-error-code)

## 完整示例代码

- [ArkTS示例 - 删除快捷方式](assets/remove-shortcut-example.ets)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [删除已存在的快捷方式](tests/test_positive.ts): 测试正常删除已创建的快捷方式
- [删除后重新创建快捷方式](tests/test_positive.ts): 测试删除后可以重新创建同名快捷方式
- [静默删除快捷方式](tests/test_positive.ts): 测试申请权限后的静默删除功能

### 边界测试用例
- [删除shortcutId最大长度的快捷方式](tests/test_boundary.ts): 测试shortcutId为63字节时的删除
- [删除最后一个快捷方式](tests/test_boundary.ts): 测试删除应用的最后一个快捷方式
- [并发删除多个快捷方式](tests/test_boundary.ts): 测试同时删除多个快捷方式的情况

### 异常测试用例
- [删除不存在的快捷方式](tests/test_exception.ts): 测试删除无效shortcutId的处理
- [使用空shortcutId删除](tests/test_exception.ts): 测试参数为空的错误处理
- [shortcutId超长删除](tests/test_exception.ts): 测试shortcutId超过63字节的情况
- [模拟器环境删除](tests/test_exception.ts): 测试在模拟器上的错误提示
- [用户取消删除](tests/test_exception.ts): 测试用户在确认框点击取消的处理