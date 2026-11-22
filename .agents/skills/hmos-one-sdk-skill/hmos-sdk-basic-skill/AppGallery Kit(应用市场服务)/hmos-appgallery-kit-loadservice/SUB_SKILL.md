---
name: hmos-appgallery-kit-loadservice
description: 加载元服务卡片加桌页面，支持Phone/Tablet/PC/2in1/TV设备，需要传入元服务加桌链接，通过回调接收加桌结果，适用于元服务推广和快速访问场景
---

# 添加元服务卡片至桌面技能

## 功能描述

本技能提供元服务卡片加桌功能，允许应用通过调用AppGallery Kit的`loadService`接口加载元服务卡片加桌页面，用户点击"添加至桌面"按钮将元服务卡片添加至桌面。该功能帮助用户快速访问常用元服务，提升元服务的曝光率和用户使用便捷性。

**核心能力**：
- 加载元服务卡片加桌页面
- 接收用户加桌操作结果
- 获取加桌卡片详细信息
- 支持页面生命周期回调

**技术特点**：
- 仅支持Stage模型
- 需要真机调试（不支持模拟器）
- 异步回调机制
- 支持多设备类型

## 使用场景

### 触发词
- "添加元服务卡片至桌面"
- "元服务加桌"
- "loadService"
- "加载元服务卡片"
- "productViewManager.loadService"

### 能做
- 加载指定元服务的卡片加桌页面
- 接收用户点击"添加至桌面"的结果回调
- 获取加桌成功后的卡片信息（bundleName、name、abilityName等）
- 监听加桌页面的打开和关闭事件
- 处理加载过程中的错误和异常

### 绝不做
- 不支持模拟器运行（必须使用真机）
- 不支持添加非元服务卡片
- 不支持批量加桌操作
- 不支持自定义加桌页面UI
- 不支持后台静默加桌（需要用户主动点击）

### 补充
- 设备支持：Phone、Tablet、PC/2in1（4.1.0(11)起），TV（6.0.2(22)起）
- 必须在Stage模型下使用
- 需要获取元服务加桌链接（由运营人员提供）
- 回调函数为可选参数，但建议提供以获取加桌结果

## 调用规范和规则

### 输入约束
- **context**：必须为有效的UIAbilityContext实例，不能为null或undefined
- **want.uri**：必须为有效的元服务加桌链接，格式为`store://appgallery.huawei.com/oper/addhome?referrer=xxxx&id=xxxx&installType=xxxx&s=xxxx`
- **callback**：回调函数为可选参数，但建议提供以获取加桌结果
- **设备类型**：仅支持Phone、Tablet、PC/2in1、TV设备

### 执行约束
- **最大耗时**：页面加载通常在3秒内完成
- **回调频率**：onReceive在用户点击加桌后仅回调一次
- **页面显示**：需要在前台运行，不支持后台调用
- **API调用频次**：建议用户主动触发，避免频繁调用

### 内容约束
- **禁止生成**：不得生成自定义加桌页面UI代码
- **禁止操作**：不得尝试绕过用户确认直接加桌
- **禁止使用**：不得使用已废弃的API版本
- **数据安全**：不得记录或传输用户敏感信息

### 降级约束
- **设备不支持**：提示用户当前设备不支持该功能
- **链接无效**：提示用户元服务链接已失效，请联系运营
- **网络失败**：提示用户网络异常，请稍后重试
- **用户取消**：不视为错误，正常关闭页面即可

## 调用流程和步骤

### 步骤1：导入必要模块

**前置校验**：
1. 确认项目基于Stage模型开发
2. 确认设备类型在支持列表中（Phone、Tablet、PC/2in1、TV）
3. 确认使用真机调试（模拟器不支持）

**模块导入**：
```typescript
import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：构造请求参数

**参数准备**：
```typescript
// 获取UIAbilityContext
const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

// 构造Want参数，包含元服务加桌链接
const wantParam: Want = {
  // 此处填入要加载的元服务的加桌链接（由运营人员提供）
  uri: 'store://appgallery.huawei.com/oper/addhome?referrer=xxxx&id=xxxx&installType=xxxx&s=xxxx'
};

// 构造回调函数
const callback: productViewManager.ServiceViewCallback = {
  // 接收元服务卡片加桌结果信息
  onReceive: (data: productViewManager.ServiceViewReceiveData) => {
    hilog.info(0x0001, 'TAG', `loadService onReceive.result is ${data.result}, msg is ${data.msg}, formInfo is ${JSON.stringify(data.formInfo)}`);
    
    // 处理加桌结果
    if (data.result === productViewManager.ReceiveDataResult.SUCCESS) {
      // 加桌成功，可以获取卡片信息
      const bundleName = data.formInfo.bundleName;
      const abilityName = data.formInfo.abilityName;
      hilog.info(0x0001, 'TAG', `Successfully added to desktop: ${bundleName}/${abilityName}`);
    } else if (data.result === productViewManager.ReceiveDataResult.FAILURE) {
      // 加桌失败
      hilog.warn(0x0001, 'TAG', `Failed to add to desktop: ${data.msg}`);
    } else if (data.result === productViewManager.ReceiveDataResult.EXCEPTION) {
      // 加桌异常
      hilog.error(0x0001, 'TAG', `Exception when adding to desktop: ${data.msg}`);
    }
  },
  
  // 错误处理回调
  onError: (error: BusinessError) => {
    hilog.error(0x0001, 'TAG', `loadService onError.code is ${error.code}, message is ${error.message}`);
    
    // 根据错误码处理
    if (error.code === 401) {
      hilog.error(0x0001, 'TAG', 'Parameter error, please check your input parameters');
    } else if (error.code === 1011) {
      hilog.error(0x0001, 'TAG', 'Failed to launch or switch to foreground');
    } else if (error.code === 1012) {
      hilog.error(0x0001, 'TAG', 'Failed to switch to background');
    } else if (error.code === 1013) {
      hilog.error(0x0001, 'TAG', 'Failed to destroy');
    }
  },
  
  // 当元服务卡片加桌页成功打开时回调
  onAppear: () => {
    hilog.info(0x0001, 'TAG', `loadService onAppear.`);
  },
  
  // 当元服务卡片加桌页关闭时回调
  onDisappear: () => {
    hilog.info(0x0001, 'TAG', `loadService onDisappear.`);
  }
};
```

### 步骤3：调用loadService接口

**示例代码**：
```typescript
// 调用接口，加载元服务加桌页面
productViewManager.loadService(uiContext, wantParam, callback);
```

### 步骤4：错误处理

**异常捕获**：
```typescript
try {
  // 调用接口，加载元服务加桌页面
  productViewManager.loadService(uiContext, wantParam, callback);
} catch (err) {
  const error = err as BusinessError;
  hilog.error(0x0001, 'TAG', `loadService failed. code is ${error.code}, message is ${error.message}`);
  
  // 根据错误码进行降级处理
  if (error.code === 401) {
    // 参数错误，检查want.uri是否有效
    console.error('Invalid parameters, please check the uri in want parameter');
  } else {
    // 其他错误，记录日志并提示用户
    console.error('Failed to load service page, please try again later');
  }
}
```

### 步骤5：降级处理

**降级方案**：
```typescript
async function loadServiceWithFallback(
  context: common.UIAbilityContext,
  wantParam: Want
): Promise<void> {
  try {
    // 尝试调用loadService
    await new Promise<void>((resolve, reject) => {
      const callback: productViewManager.ServiceViewCallback = {
        onReceive: (data) => {
          if (data.result === productViewManager.ReceiveDataResult.SUCCESS) {
            resolve();
          } else {
            reject(new Error(`Failed with result: ${data.result}`));
          }
        },
        onError: (error) => {
          reject(error);
        },
        onAppear: () => {},
        onDisappear: () => {}
      };
      
      productViewManager.loadService(context, wantParam, callback);
    });
  } catch (error) {
    const businessError = error as BusinessError;
    
    // 降级处理：提示用户手动操作
    if (businessError.code === 401) {
      console.warn('Current device does not support this feature');
      // 提示用户使用其他方式添加
      alert('请在应用市场中手动搜索该元服务并添加至桌面');
    } else {
      console.warn('Network error or service unavailable');
      // 提示用户稍后重试
      alert('网络异常，请稍后重试');
    }
  }
}
```

## 错误码说明

### loadService接口错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查want.uri是否为有效的元服务加桌链接，context是否为有效的UIAbilityContext |
| 1011 | 拉起/切前台失败 | 检查元服务是否已安装，或尝试重新加载页面 |
| 1012 | 切后台失败 | 通常不影响功能，可忽略此错误 |
| 1013 | 销毁失败 | 通常不影响功能，可忽略此错误 |

### ReceiveDataResult结果码

| 结果码 | 值 | 说明 | 解决方法 |
|-------|-----|------|---------|
| SUCCESS | 1000 | 加桌成功 | 无需处理，可以记录成功日志 |
| FAILURE | 1001 | 加桌失败 | 提示用户加桌失败，建议手动添加 |
| EXCEPTION | 1002 | 加桌异常 | 提示用户发生异常，建议稍后重试 |

### 设备兼容性错误

| 错误场景 | 错误码 | 说明 | 解决方法 |
|---------|--------|------|---------|
| 不支持的设备类型 | 401 | 在不支持的设备上调用接口 | 检查设备类型，仅在支持的设备上调用 |
| 模拟器运行 | - | 在模拟器上调用接口 | 使用真机调试，模拟器不支持此功能 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": ">=4.1.0",
    "@kit.AbilityKit": ">=4.1.0",
    "@kit.BasicServicesKit": ">=4.1.0",
    "@kit.PerformanceAnalysisKit": ">=4.1.0"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：>=4.1.0(11)
- **模型类型**：Stage模型
- **设备类型**：Phone、Tablet、PC/2in1（>=4.1.0），TV（>=6.0.2(22)）
- **调试方式**：真机调试（不支持模拟器）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AppGalleryKit' or its corresponding type declarations.
```
**解决方法**：
- 检查HarmonyOS SDK版本是否>=4.1.0
- 在oh-package.json5中添加依赖声明
- 执行`ohpm install`安装依赖

**问题2：UIAbilityContext类型错误**
```
Error: Type 'UIAbilityContext' is not assignable to type 'common.UIAbilityContext'.
```
**解决方法**：
- 确保正确导入类型：`import type { common } from '@kit.AbilityKit'`
- 使用类型断言：`as common.UIAbilityContext`

**问题3：getUIContext方法不存在**
```
Error: Property 'getUIContext' does not exist on type 'LoadServiceView'.
```
**解决方法**：
- 确保组件使用`@Entry`装饰器
- 确保在组件内部调用`this.getUIContext()`

**问题4：Want参数格式错误**
```
Error: Property 'uri' is missing in type 'Want'.
```
**解决方法**：
- 确保want参数包含uri字段
- 检查uri格式是否符合要求

## 常见问题与解决方法

### Q1：在模拟器上运行提示"无法获取内容"
**原因**：应用市场推荐服务不支持模拟器，仅支持真机调试。
**解决方法**：
- 使用真机进行调试
- 在模拟器中会提示"无法获取内容，请点击屏幕重试"，这是正常现象

### Q2：loadService回调不执行
**原因**：可能是回调函数未正确设置或参数格式错误。
**解决方法**：
- 检查callback参数是否正确传入
- 确保want.uri是有效的元服务加桌链接
- 检查context是否为有效的UIAbilityContext
- 在回调函数中添加日志，确认是否被调用

### Q3：加桌失败，返回FAILURE或EXCEPTION
**原因**：可能是元服务链接失效、网络异常或用户取消操作。
**解决方法**：
- 检查元服务加桌链接是否有效，联系运营人员确认
- 检查网络连接是否正常
- 如果是用户主动取消，不视为错误，正常处理即可
- 记录错误日志，用于后续问题排查

### Q4：onReceive回调中formInfo数据不完整
**原因**：可能是元服务未正确配置卡片信息。
**解决方法**：
- 联系元服务开发者确认卡片配置是否正确
- 检查formInfo中的必填字段：bundleName、name、abilityName、moduleName、defaultDimension
- 如果字段缺失，记录日志并提示用户

### Q5：页面加载缓慢或无响应
**原因**：网络问题或元服务信息加载耗时较长。
**解决方法**：
- 增加加载提示，提升用户体验
- 设置合理的超时时间，例如5秒
- 如果超时，提示用户稍后重试
- 在onAppear回调中记录页面打开时间，监控性能

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "loadService",
  "result": {
    "resultCode": 1000,
    "resultMessage": "Success",
    "cardInfo": {
      "bundleName": "com.example.metaservice",
      "abilityName": "EntryAbility",
      "moduleName": "entry",
      "name": "widget_name",
      "defaultDimension": "2x2"
    }
  },
  "callbacks": {
    "onAppear": "executed",
    "onReceive": "executed",
    "onDisappear": "executed",
    "onError": "not executed"
  },
  "apiUsed": [
    "productViewManager.loadService",
    "ServiceViewCallback.onReceive",
    "ServiceViewCallback.onError",
    "ServiceViewCallback.onAppear",
    "ServiceViewCallback.onDisappear"
  ],
  "timestamp": "2026-07-03T10:30:00Z"
}
```

## 参考文档

- [API开发指南](references/appgallery-productview-loadservice.md)
- [API参考说明](references/store-productviewmanager.md)
- [common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext)
- [Want](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want)
- [ErrorCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-base)

## 完整示例代码

- [ArkTS示例](assets/loadservice-example.ets)

## 测试用例

### 正向测试用例
- [正常加载元服务卡片](tests/test_positive.py)：测试正常加载元服务卡片加桌页面的流程
- [获取加桌结果](tests/test_positive.py)：测试接收加桌结果回调的功能
- [页面生命周期回调](tests/test_positive.py)：测试onAppear和onDisappear回调

### 边界测试用例
- [可选回调参数](tests/test_boundary.py)：测试不传入callback参数时的情况
- [空uri参数](tests/test_boundary.py)：测试uri为空字符串时的情况
- [网络超时处理](tests/test_boundary.py)：测试网络超时时的降级处理

### 异常测试用例
- [无效链接](tests/test_exception.py)：测试传入无效的元服务加桌链接
- [参数类型错误](tests/test_exception.py)：测试传入错误类型的参数
- [不支持的设备](tests/test_exception.py)：测试在不支持的设备上调用接口
- [模拟器运行](tests/test_exception.py)：测试在模拟器上运行时的错误提示