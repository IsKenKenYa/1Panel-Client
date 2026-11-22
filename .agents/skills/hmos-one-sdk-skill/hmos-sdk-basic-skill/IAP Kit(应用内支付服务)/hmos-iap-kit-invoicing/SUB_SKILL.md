---
name: hmos-iap-kit-invoicing
description: 拉起开发票页面，支持用户申请开发票，需要传入订单号purchaseOrderId，仅支持Stage模型和API版本6.1.0(23)及以上，适用于应用内接入开票入口场景
---

# IAP Kit开票技能

## 功能描述

本技能用于应用内接入开发票入口，通过调用IAP Kit的showManagedInvoices接口拉起开发票页面，让用户可以快速申请开发票。从API版本6.1.0(23)开始支持开票功能。

**核心能力**：
- 拉起华为官方开发票页面
- 传入待开发票的订单号
- 用户可在页面中填写发票信息并提交申请

**适用范围**：
- 用户购买应用内数字商品后需要申请开发票的场景
- 应用内需要提供开发票入口的场景

**限制条件**：
- 仅支持Stage模型
- API版本要求：6.1.0(23)及以上
- 需要传入有效的订单号（purchaseOrderId）
- 用户需已登录华为账号
- 设备需支持IAP功能

**典型场景**：
- 应用内订单详情页提供开发票按钮
- 应用内发票中心入口
- 用户购买后主动申请开票

## 使用场景

### 触发词
- "开票" - 拉起开发票页面
- "开发票" - 用户申请开发票
- "申请发票" - 用户主动申请发票
- "发票" - 发票相关功能
- "showManagedInvoices" - 直接使用API名称

### 能做
- 拉起华为官方开发票页面，让用户填写发票信息
- 传入指定订单的purchaseOrderId，为该订单申请开发票
- 处理开票请求的成功和失败回调
- 提供错误码处理和用户提示

### 绝不做
- 不处理发票审核和发放流程（由华为系统后台处理）
- 不直接生成发票文件（由用户在开发票页面填写信息后系统生成）
- 不处理发票查询和下载（需要其他API或用户手动操作）
- 不支持批量开票（每次只能处理一个订单）

### 补充
- 开票功能需要用户先完成支付并获得有效订单
- 用户可在"手机设置 > 华为账号 > 付款与账单 > 发票中心"查看开票状态
- 应用需要先查询订单信息获取purchaseOrderId再调用开票接口
- 建议在订单详情页或发票中心页提供开票入口

## 调用规范和规则

### 输入约束
- **订单号要求**：purchaseOrderId必须为有效的订单号，长度不超过系统限制
- **上下文要求**：context必须为有效的UIAbilityContext对象
- **参数校验**：purchaseOrderId不能为空字符串
- **用户状态**：用户必须已登录华为账号

### 执行约束
- **最大耗时**：接口调用建议设置超时时间（建议10秒）
- **调用频次**：避免频繁调用，建议在用户主动触发时调用
- **异步处理**：必须使用Promise异步回调方式处理结果
- **错误处理**：必须捕获BusinessError异常并处理

### 内容约束
- **禁止生成**：不生成发票文件，不修改发票内容
- **禁止高危操作**：不使用eval、exec等高危函数
- **禁止操作**：不直接操作用户账号信息，不访问敏感数据
- **权限限制**：仅申请必要的IAP权限

### 降级约束
- **网络失败**：提示用户检查网络连接，稍后重试
- **API不可用**：提示用户系统暂不支持开票功能，引导用户去系统设置中的发票中心申请
- **订单无效**：提示用户订单信息无效或已开票，引导查看订单状态
- **用户未登录**：提示用户先登录华为账号

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否支持（需要6.1.0(23)及以上）
2. 检查用户是否已登录华为账号
3. 获取有效的UIAbilityContext对象
4. 获取待开票订单的purchaseOrderId

**参数准备**：
```typescript
// 准备必要的上下文和订单号
const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
const purchaseOrderId: string = 'ORDER_ID_FROM_PURCHASE'; // 从订单信息中获取
```

### 步骤2：调用API

**示例代码**：
```typescript
import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 拉起开发票页面
 * @param context UIAbility上下文
 * @param purchaseOrderId 待开发票的订单号
 */
async function showManagedInvoices(
  context: common.UIAbilityContext,
  purchaseOrderId: string
): Promise<void> {
  try {
    // 参数校验
    if (!purchaseOrderId || purchaseOrderId.trim() === '') {
      console.error('purchaseOrderId is invalid');
      throw new Error('Invalid purchaseOrderId');
    }
    
    // 调用iap.showManagedInvoices拉起开发票页面
    await iap.showManagedInvoices(context, purchaseOrderId);
    
    // 请求成功
    console.info('Succeeded in showing invoice page.');
    // 开发票页面已拉起，用户可在此页面填写发票信息并提交
    
  } catch (error) {
    // 请求失败
    const err = error as BusinessError;
    console.error(`Failed to show invoice page. Code is ${err.code}, message is ${err.message}`);
    throw err;
  }
}
```

### 步骤3：错误处理

```typescript
// 错误处理代码
try {
  await showManagedInvoices(context, purchaseOrderId);
} catch (error) {
  const err = error as BusinessError;
  
  switch (err.code) {
    case 1001860000:
      // 用户取消操作
      console.info('User canceled the invoice operation.');
      // 提示用户：您已取消开发票操作
      break;
      
    case 1001860001:
      // 系统内部错误
      console.error('System internal error.');
      // 提示用户：系统错误，请稍后重试
      break;
      
    case 1001860002:
      // 应用未授权
      console.error('App is not authorized.');
      // 提示用户：应用未授权访问发票功能
      break;
      
    case 1001860004:
      // 接口访问过频
      console.error('Too frequent API calls.');
      // 提示用户：请稍后再试
      break;
      
    case 1001860005:
      // 网络连接异常
      console.error('Network connection error.');
      // 提示用户：网络异常，请检查网络连接后重试
      break;
      
    case 1001860050:
      // 未登录华为账号
      console.error('HUAWEI ID is not signed in.');
      // 提示用户：请先登录华为账号
      // 引导用户登录
      break;
      
    case 1001860054:
      // 用户账号所在服务地暂不支持IAP
      console.error('The country or region does not support IAP.');
      // 提示用户：当前地区暂不支持发票功能
      break;
      
    case 401:
      // 参数错误
      console.error('Parameter error.');
      // 提示用户：订单信息无效
      break;
      
    default:
      // 其他错误
      console.error(`Unknown error: ${err.message}`);
      // 提示用户：开发票失败，请稍后重试或联系客服
      break;
  }
}
```

### 步骤4：降级处理

```typescript
// 降级处理代码
async function showInvoiceFallback(
  context: common.UIAbilityContext,
  purchaseOrderId: string
): Promise<void> {
  try {
    // 尝试调用主要接口
    await iap.showManagedInvoices(context, purchaseOrderId);
  } catch (error) {
    const err = error as BusinessError;
    
    // 如果接口调用失败，提供降级方案
    if (err.code === 1001860005 || err.code === 1001860001) {
      // 网络错误或系统错误时，提示用户使用系统发票中心
      console.warn('Invoice API failed, suggesting user to use system invoice center.');
      // 显示对话框提示用户
      // "开发票功能暂时不可用，您可以前往：手机设置 > 华为账号 > 付款与账单 > 发票中心 申请开发票"
    } else {
      // 其他错误直接抛出
      throw err;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。purchaseOrderId无效或为空 | 检查订单号是否正确，确保订单号不为空 |
| 1001860000 | 用户取消当前操作 | 用户主动取消，无需处理，可记录日志 |
| 1001860001 | 系统内部错误 | 提示用户稍后重试，或引导用户使用系统发票中心 |
| 1001860002 | 应用未被授权访问接口 | 检查应用配置，确保已在AppGallery Connect配置IAP权限 |
| 1001860004 | 接口访问过频 | 提示用户稍后再试，避免频繁调用 |
| 1001860005 | 网络连接异常 | 提示用户检查网络连接，稍后重试 |
| 1001860050 | 未登录华为账号 | 引导用户先登录华为账号 |
| 1001860054 | 用户账号所在服务地暂不支持IAP | 提示用户当前地区暂不支持发票功能 |

**注意**：以上错误码基于IAP Kit通用错误码推断，showManagedInvoices接口的具体错误码请参考最新API文档。

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.IAPKit": "^6.1.0",
    "@kit.AbilityKit": "最新版本",
    "@kit.BasicServicesKit": "最新版本"
  }
}
```

### 环境要求
- **API版本**：HarmonyOS 6.1.0(23)及以上
- **模型约束**：仅支持Stage模型
- **设备支持**：支持IAP功能的设备（Phone、Tablet等）
- **用户账号**：需要登录华为账号

### 常见编译问题

**问题1：导入IAP模块失败**
```
Error: Cannot find module '@kit.IAPKit'
```
**解决方法**：
- 确保项目API版本为6.1.0(23)及以上
- 在oh-package.json5中添加依赖声明
- 运行`ohpm install`安装依赖

**问题2：context类型错误**
```
Error: Type 'UIAbilityContext' is not assignable to type 'Context'
```
**解决方法**：
- 确保使用正确的UIAbilityContext获取方式
- 使用`this.getUIContext().getHostContext() as common.UIAbilityContext`

**问题3：Promise处理错误**
```
Error: Promise rejection handled incorrectly
```
**解决方法**：
- 确保使用try-catch捕获Promise异常
- 使用BusinessError类型处理错误对象

## 常见问题与解决方法

### Q1：如何获取purchaseOrderId？
**原因**：开票接口需要传入订单号
**解决方法**：
- 通过购买流程返回的PurchaseResult获取purchaseOrderId
- 使用queryPurchases或queryPurchaseRecords接口查询已购买订单信息
- 从订单详情数据中提取purchaseOrderId字段

### Q2：用户取消开票操作怎么办？
**原因**：用户可能主动取消开发票流程
**解决方法**：
- 捕获错误码1001860000（USER_CANCELED）
- 不做额外处理，记录日志即可
- 可在UI上提示用户取消成功

### Q3：调用接口后页面没有拉起？
**原因**：可能是参数错误、权限不足或系统不支持
**解决方法**：
- 检查purchaseOrderId是否有效
- 检查用户是否已登录华为账号
- 检查应用是否有IAP权限配置
- 检查API版本是否满足要求（6.1.0(23)及以上）
- 提供降级方案引导用户使用系统发票中心

### Q4：如何判断订单是否已经开票？
**原因**：避免重复开票
**解决方法**：
- 在调用开票接口前，查询订单状态
- 已开票的订单调用接口会返回错误提示
- 建议在订单详情页显示发票状态

### Q5：开发票功能在某些设备不可用？
**原因**：部分设备或地区不支持IAP或开票功能
**解决方法**：
- 检查错误码1001860054（地区不支持）
- 提供降级方案引导用户使用系统发票中心
- 在应用启动时检查环境状态（queryEnvironmentStatus）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "action": "show_invoice_page",
  "message": "开发票页面已拉起，用户可在此页面填写发票信息",
  "purchaseOrderId": "传入的订单号",
  "apiUsed": [
    "iap.showManagedInvoices"
  ],
  "timestamp": "调用时间戳"
}
```

**失败情况输出**：
```json
{
  "status": "failed",
  "action": "show_invoice_page",
  "errorCode": "错误码",
  "errorMessage": "错误描述",
  "purchaseOrderId": "传入的订单号",
  "suggestion": "建议处理方案",
  "fallback": "降级方案说明"
}
```

## 参考文档

- [API开发指南 - 开票](references/api-guide.md)
- [API参考说明 - IAP模块](references/api-reference.md)
- [在线文档 - 开票](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-invoicing)
- [在线文档 - IAP API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)

## 完整示例代码

- [ArkTS示例 - 拉起开发票页面](assets/show_invoice_example.ets)
- [ArkTS示例 - 带错误处理的开票示例](assets/show_invoice_with_error_handling.ets)

## 测试用例

### 正向测试用例
- **正常开票流程**：传入有效订单号，成功拉起开发票页面
- **用户填写发票信息**：用户在页面填写发票信息并提交成功

### 边界测试用例
- **订单号为空字符串**：传入空字符串，预期返回参数错误（401）
- **超长订单号**：传入超长订单号，测试系统限制
- **用户取消操作**：用户主动取消开票流程，预期返回错误码1001860000

### 异常测试用例
- **网络异常**：模拟网络断开，预期返回错误码1001860005
- **用户未登录**：用户未登录华为账号，预期返回错误码1001860050
- **地区不支持**：用户账号地区不支持IAP，预期返回错误码1001860054
- **应用未授权**：应用未配置IAP权限，预期返回错误码1001860002