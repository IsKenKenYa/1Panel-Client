---
name: appgallery-productview-loadservice
description: 加载元服务卡片加桌页面，支持真机Phone/Tablet/PC/2in1/TV设备，不支持模拟器，适用于快速访问和管理元服务卡片场景
---

# 添加元服务卡片至桌面技能

## 功能描述

调用AppGallery Kit提供的`productViewManager.loadService`接口，加载元服务卡片加桌页面，用户点击"添加至桌面"按钮，将元服务卡片添加至桌面。提供完整的回调机制，接收加桌结果、错误信息、页面状态变化等信息。

**核心能力**：
- 展示元服务详情页，添加至桌面
- 接收加桌结果（成功/失败/异常）
- 监听页面状态变化（打开/关闭）
- 错误处理和降级方案

## 使用场景

### 触发词
- "添加元服务卡片至桌面"
- "元服务加桌"
- "loadService"
- "卡片加桌"
- "元服务卡片"

### 能做
- 加载指定元服务的卡片加桌页面
- 接收并处理加桌结果信息（成功、失败、异常）
- 监听加桌页面的生命周期状态（打开、关闭）
- 处理加载过程中的错误和异常
- 获取加桌卡片的详细信息（包名、卡片名称、尺寸等）

### 绝不做
- 不支持模拟器运行（必须在真机上调试）
- 不支持超出Phone/Tablet/PC/2in1/TV设备类型的操作
- 不直接创建桌面快捷方式（需要用户点击确认）
- 不处理非元服务类型的应用加桌

### 补充
- 从API version 4.1.0(11)开始支持
- 仅支持Stage模型
- 需要真机调试，模拟器会提示无法获取内容
- 从6.0.2(22)版本开始支持TV设备
- 系统能力要求：SystemCapability.AppGalleryService.Distribution.Recommendations

## 调用规范和规则

### 输入约束
- uri参数：必须提供有效的元服务加桌链接，格式为`store://appgallery.huawei.com/oper/addhome?referrer=xxxx&id=xxxx&installType=xxxx&s=xxxx`
- context参数：必须是有效的UIAbilityContext对象
- callback参数：可选，但强烈建议提供以接收加桌结果和错误信息

### 执行约束
- 最大耗时：无明确限制，但建议处理时间不超过30秒
- 设备限制：仅支持Phone、Tablet、PC/2in1、TV（6.0.2(22)+）
- 线程限制：仅支持在主线程调用
- 模型限制：仅支持Stage模型

### 内容约束
- 禁止使用模拟器测试
- 禁止在非支持的设备类型上调用
- 禁止在FA模型下使用
- 禁止传入无效或空的uri参数

### 降级约束
- 设备不支持：提示用户"当前设备不支持此功能"
- 模拟器环境：提示用户"请使用真机调试"
- uri无效：通过onError回调返回错误信息，提示用户检查链接
- 页面加载失败：通过onError回调返回错误码，提供重试或取消选项

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认运行环境为真机设备（非模拟器）
2. 确认设备类型为Phone/Tablet/PC/2in1/TV（6.0.2(22)+）
3. 确认应用模型为Stage模型
4. 确认已导入必要的模块

**参数准备**：
```typescript
// 导入必要模块
import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 准备UIAbilityContext
const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

// 准备Want参数（必填uri）
const wantParam: Want = {
  uri: 'store://appgallery.huawei.com/oper/addhome?referrer=xxxx&id=xxxx&installType=xxxx&s=xxxx'
};

// 准备回调函数
const callback: productViewManager.ServiceViewCallback = {
  onReceive: (data: productViewManager.ServiceViewReceiveData) => {
    // 处理加桌结果
  },
  onError: (error: BusinessError) => {
    // 处理错误信息
  },
  onAppear: () => {
    // 页面成功打开
  },
  onDisappear: () => {
    // 页面关闭
  }
};
```

### 步骤2：调用API

**示例代码**：
```typescript
import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'LoadService';

@Entry
@Component
struct LoadServiceView {
  build() {
    Column() {
      Button('添加元服务卡片至桌面')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          try {
            const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            
            const wantParam: Want = {
              uri: 'store://appgallery.huawei.com/oper/addhome?referrer=xxxx&id=xxxx&installType=xxxx&s=xxxx'
            };
            
            const callback: productViewManager.ServiceViewCallback = {
              onReceive: (data: productViewManager.ServiceViewReceiveData) => {
                hilog.info(0x0001, TAG, `加桌结果: ${data.result}, 描述: ${data.msg}`);
                hilog.info(0x0001, TAG, `卡片信息: ${JSON.stringify(data.formInfo)}`);
              },
              onError: (error: BusinessError) => {
                hilog.error(0x0001, TAG, `加载失败: ${error.code}, ${error.message}`);
              },
              onAppear: () => {
                hilog.info(0x0001, TAG, '加桌页面成功打开');
              },
              onDisappear: () => {
                hilog.info(0x0001, TAG, '加桌页面已关闭');
              }
            };
            
            productViewManager.loadService(uiContext, wantParam, callback);
          } catch (err) {
            const error = err as BusinessError;
            hilog.error(0x0001, TAG, `调用失败: ${error.code}, ${error.message}`);
          }
        })
        .width('80%')
        .height(60)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

### 步骤3：错误处理

```typescript
onError: (error: BusinessError) => {
  switch (error.code) {
    case 401:
      hilog.error(0x0001, TAG, '参数错误：请检查uri是否有效');
      break;
    case 1011:
      hilog.error(0x0001, TAG, '拉起/切前台失败');
      break;
    case 1012:
      hilog.error(0x0001, TAG, '切后台失败');
      break;
    case 1013:
      hilog.error(0x0001, TAG, '销毁失败');
      break;
    default:
      hilog.error(0x0001, TAG, `未知错误: ${error.code}, ${error.message}`);
  }
}
```

### 步骤4：结果处理

```typescript
onReceive: (data: productViewManager.ServiceViewReceiveData) => {
  switch (data.result) {
    case productViewManager.ReceiveDataResult.SUCCESS:
      hilog.info(0x0001, TAG, '加桌成功');
      const formInfo = data.formInfo;
      hilog.info(0x0001, TAG, `包名: ${formInfo.bundleName}`);
      hilog.info(0x0001, TAG, `卡片名称: ${formInfo.name}`);
      hilog.info(0x0001, TAG, `Ability名称: ${formInfo.abilityName}`);
      hilog.info(0x0001, TAG, `模块名: ${formInfo.moduleName}`);
      hilog.info(0x0001, TAG, `卡片尺寸: ${formInfo.defaultDimension}`);
      break;
    case productViewManager.ReceiveDataResult.FAILURE:
      hilog.warn(0x0001, TAG, `加桌失败: ${data.msg}`);
      break;
    case productViewManager.ReceiveDataResult.EXCEPTION:
      hilog.error(0x0001, TAG, `加桌异常: ${data.msg}`);
      break;
    default:
      hilog.warn(0x0001, TAG, `未知结果: ${data.result}`);
  }
}
```

## 错误码说明

### API调用错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，可能原因：必填参数未指定或参数类型错误 | 检查uri参数是否有效，确认context类型正确 |
| 1011 | 拉起/切前台失败 | 检查设备是否支持，确认应用市场服务可用 |
| 1012 | 切后台失败 | 系统内部错误，建议重试 |
| 1013 | 销毁失败 | 系统内部错误，建议重试 |

### 加桌结果码

| 结果码 | 值 | 说明 | 处理建议 |
|-------|---|------|---------|
| SUCCESS | 1000 | 加桌成功 | 记录卡片信息，更新UI状态 |
| FAILURE | 1001 | 加桌失败 | 提示用户失败原因，提供重试选项 |
| EXCEPTION | 1002 | 加桌异常 | 记录异常信息，提示用户联系客服 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": ">=4.1.0",
    "@kit.AbilityKit": ">=4.1.0",
    "@kit.PerformanceAnalysisKit": ">=4.1.0",
    "@kit.BasicServicesKit": ">=4.1.0"
  }
}
```

### 环境要求
- DevEco Studio：>=4.1
- HarmonyOS SDK：>=4.1.0(11)
- 运行设备：Phone/Tablet/PC/2in1/TV（真机）
- 应用模型：Stage模型

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.AppGalleryKit' or its corresponding type declarations.
```
**解决方法**：确保HarmonyOS SDK版本>=4.1.0(11)，在DevEco Studio中更新SDK。

**问题2：类型定义错误**
```
Property 'loadService' does not exist on type 'productViewManager'.
```
**解决方法**：检查SDK版本是否支持该接口（API version 4.1.0(11)+），确认导入语句正确。

**问题3：设备不支持错误**
```
运行时返回401错误码
```
**解决方法**：确认设备类型为支持的类型，TV设备需要6.0.2(22)+版本。

## 常见问题与解决方法

### Q1：模拟器提示无法获取内容
**原因**：应用市场推荐服务不支持模拟器
**解决方法**：
- 使用真机进行调试和测试
- 在真机上运行应用才能正常加载加桌页面

### Q2：loadService返回401错误码
**原因**：参数错误或设备不支持
**解决方法**：
- 检查uri参数是否有效且格式正确
- 确认设备类型为Phone/Tablet/PC/2in1/TV
- TV设备需要6.0.2(22)+版本

### Q3：onReceive回调未触发
**原因**：未提供callback参数或页面未成功打开
**解决方法**：
- 确保提供完整的ServiceViewCallback对象
- 通过onAppear和onError回调确认页面状态
- 检查用户是否点击了"添加至桌面"按钮

### Q4：获取不到卡片详细信息
**原因**：加桌失败或异常
**解决方法**：
- 检查onReceive回调中的result值
- 如果result为FAILURE或EXCEPTION，查看msg字段了解原因
- 确认元服务卡片链接有效且元服务已上架

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "completed",
  "result": "SUCCESS/FAILURE/EXCEPTION",
  "msg": "加桌结果描述信息",
  "formInfo": {
    "bundleName": "元服务包名",
    "name": "卡片名称",
    "abilityName": "Ability名称",
    "moduleName": "模块名",
    "defaultDimension": "卡片尺寸"
  },
  "apiUsed": [
    "productViewManager.loadService"
  ],
  "callbacksTriggered": [
    "onAppear",
    "onReceive",
    "onDisappear"
  ]
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/appgallery-productview-loadservice)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager)
- [UIAbilityContext参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext)
- [Want参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want)

## 完整示例代码

- [ArkTS完整示例](assets/loadservice_example.ets)
- [错误处理示例](assets/error_handling.ets)
- [结果处理示例](assets/result_handling.ets)

## 测试用例

### 正向测试用例
- [正常加桌流程](tests/test_positive.ets)：验证完整的加桌成功流程
- [回调触发验证](tests/test_callbacks.ets)：验证所有回调函数正确触发
- [卡片信息获取](tests/test_forminfo.ets)：验证获取的卡片信息完整性

### 边界测试用例
- [空uri参数](tests/test_empty_uri.ets)：验证参数校验机制
- [无效uri格式](tests/test_invalid_uri.ets)：验证错误处理机制
- [设备兼容性](tests/test_device_compatibility.ets)：验证不同设备类型支持

### 异常测试用例
- [模拟器运行](tests/test_emulator.ets)：验证模拟器不支持提示
- [网络异常](tests/test_network_error.ets)：验证网络异常处理
- [用户取消加桌](tests/test_user_cancel.ets)：验证用户取消场景