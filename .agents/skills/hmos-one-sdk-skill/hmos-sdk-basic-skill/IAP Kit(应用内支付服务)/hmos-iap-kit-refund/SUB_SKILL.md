---
name: hmos-iap-kit-refund
description: 拉起应用内支付退款界面,支持非游戏类应用的订单退款,需要传入购买订单号ID,仅支持Phone/Tablet/2in1设备,API版本5.0.3(15)以上,适用于售后退款场景
---

# IAP Kit退款技能

## 功能描述

本技能用于实现HarmonyOS应用内支付(IAP Kit)的退款功能。通过调用`createRefundRequest` API拉起退款界面,用户可以在应用内直接发起退款申请。该功能仅支持非游戏类应用,且仅适用于Phone、Tablet、2in1设备。

**核心能力**:
- 拉起退款界面,引导用户完成退款流程
- 支持非游戏类应用的订单退款
- 传入购买订单号ID(purchaseOrderId)标识具体订单
- 异步处理退款请求,返回Promise结果

**使用前提**:
- 应用已集成IAP Kit
- 用户已购买应用内商品
- 应用类型为非游戏类应用
- 设备类型为Phone/Tablet/2in1
- API版本不低于5.0.3(15)

## 使用场景

### 触发词
- "退款" - 用户需要退款已购买的商品
- "申请退款" - 用户主动申请退款
- "订单退款" - 针对特定订单发起退款
- "售后退款" - 售后服务中的退款场景
- "IAP退款" - 应用内支付退款

### 能做
- 拉起退款界面供用户填写退款信息
- 传入指定订单的购买订单号ID
- 异步处理退款请求并返回结果
- 处理退款成功和失败的回调
- 显示退款状态和进度

### 绝不做
- 不处理游戏类应用的退款(仅支持非游戏应用)
- 不在不支持的设备上调用(Wearable/TV等设备不支持)
- 不直接执行退款操作(仅拉起退款界面)
- 不处理退款审核流程(开发者审核在AppGallery Connect)
- 不处理跨应用的订单退款

### 补充
- 退款只能由用户发起,开发者无法主动退款
- 退款申请提交后需要开发者审核(非游戏类应用)
- 退款流程非实时,通常需要7个工作日完成
- 用户需满足最低系统版本要求(6.16.10)
- purchaseOrderId长度最大256字符

## 调用规范和规则

### 输入约束
- purchaseOrderId: 必须是有效的购买订单号ID,最大长度256字符
- context: 必须是UIAbilityContext类型的上下文对象
- 应用类型: 必须是非游戏类应用
- 设备类型: 仅支持Phone/Tablet/2in1设备

### 执行约束
- API调用频次: 不得频繁调用,避免触发1001860004错误码
- 异步处理: 使用Promise异步回调,不阻塞主线程
- 网络依赖: 需要网络连接,网络异常时返回1001860005错误码
- 最大耗时: 无硬性限制,但建议在10秒内完成

### 内容约束
- 禁止传入空字符串作为purchaseOrderId
- 禁止传入已退款的订单ID(返回1001860061错误码)
- 禁止在不支持的设备上调用(返回801错误码)
- 禁止在游戏类应用中调用
- 禁止使用无效的context对象

### 降级约束
- 网络失败: 提示用户检查网络连接,稍后重试
- 设备不支持: 提示用户当前设备不支持退款功能
- 订单已退款: 提示用户订单已在退款流程中或已退款
- 权限不足: 引导用户登录华为账号或检查应用权限
- 用户取消: 正常处理用户取消操作,不视为错误

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查设备类型是否支持(Phone/Tablet/2in1)
2. 检查应用类型是否为非游戏类应用
3. 检查API版本是否不低于5.0.3(15)
4. 检查用户是否已登录华为账号
5. 检查purchaseOrderId是否有效(非空且长度≤256)

**参数准备**:
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
const purchaseOrderId: string = '订单号ID'; // 从购买记录中获取
```

### 步骤2: 调用API

**示例代码**:
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct RefundPage {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  
  createRefundRequest(purchaseOrderId: string): void {
    iap.createRefundRequest(this.context, purchaseOrderId).then(() => {
      console.info('Succeeded in creating refund request.');
      this.handleRefundSuccess();
    }).catch((err: BusinessError) => {
      console.error(`Failed to create refund request. Code is ${err.code}, message is ${err.message}`);
      this.handleRefundError(err);
    });
  }
  
  handleRefundSuccess(): void {
    AlertDialog.show({
      title: '退款申请已提交',
      message: '您的退款申请已提交,请等待审核。审核结果将在7个工作日内通知您。',
      confirm: {
        value: '确定',
        action: () => {}
      }
    });
  }
  
  handleRefundError(err: BusinessError): void {
    let errorMsg: string = '';
    switch (err.code) {
      case 1001860000:
        errorMsg = '用户取消了退款操作';
        break;
      case 1001860001:
        errorMsg = '系统内部错误,请稍后重试';
        break;
      case 1001860002:
        errorMsg = '应用未被授权,请检查应用权限';
        break;
      case 1001860004:
        errorMsg = '操作过于频繁,请稍后重试';
        break;
      case 1001860005:
        errorMsg = '网络连接异常,请检查网络';
        break;
      case 1001860054:
        errorMsg = '当前账号所在地区不支持退款';
        break;
      case 1001860061:
        errorMsg = '订单已退款或正在退款中';
        break;
      case 1001860062:
        errorMsg = '该订单不允许退款';
        break;
      default:
        errorMsg = `退款失败: ${err.message}`;
        break;
    }
    
    AlertDialog.show({
      title: '退款失败',
      message: errorMsg,
      confirm: {
        value: '确定',
        action: () => {}
      }
    });
  }
  
  build() {
    Column() {
      Button('申请退款')
        .onClick(() => {
          const purchaseOrderId = '您的订单号ID'; // 实际应从购买记录获取
          this.createRefundRequest(purchaseOrderId);
        })
    }
  }
}
```

### 步骤3: 错误处理

```typescript
try {
  await iap.createRefundRequest(context, purchaseOrderId);
  console.info('Refund request created successfully.');
} catch (error) {
  const err = error as BusinessError;
  console.error(`Refund request failed. Code: ${err.code}, Message: ${err.message}`);
  
  switch (err.code) {
    case 401:
      console.error('参数错误,请检查purchaseOrderId是否有效');
      break;
    case 801:
      console.error('当前设备不支持退款功能');
      break;
    case 1001860000:
      console.info('用户取消了退款操作');
      break;
    case 1001860001:
      console.error('系统内部错误');
      break;
    case 1001860002:
      console.error('应用未被授权访问退款接口');
      break;
    case 1001860004:
      console.error('API调用频率过高');
      break;
    case 1001860005:
      console.error('网络连接失败');
      break;
    case 1001860054:
      console.error('账号所在地区不支持IAP');
      break;
    case 1001860061:
      console.error('订单已退款或正在退款中');
      break;
    case 1001860062:
      console.error('不允许退款');
      break;
    default:
      console.error('未知错误:', err.message);
      break;
  }
}
```

### 步骤4: 降级处理

```typescript
async function createRefundRequestWithFallback(context: common.UIAbilityContext, purchaseOrderId: string): Promise<void> {
  try {
    await iap.createRefundRequest(context, purchaseOrderId);
    console.info('Refund request created successfully.');
  } catch (error) {
    const err = error as BusinessError;
    
    if (err.code === 1001860005) {
      console.warn('网络连接失败,引导用户手动申请退款');
      showManualRefundGuide();
    } else if (err.code === 801) {
      console.warn('设备不支持,引导用户通过其他方式退款');
      showAlternativeRefundMethod();
    } else if (err.code === 1001860061 || err.code === 1001860062) {
      console.warn('订单退款受限,显示退款状态');
      showRefundStatus(purchaseOrderId);
    } else {
      console.error('退款失败:', err.message);
      showGenericErrorDialog(err.message);
    }
  }
}

function showManualRefundGuide(): void {
  AlertDialog.show({
    title: '网络连接失败',
    message: '请检查网络连接后重试,或通过以下路径手动申请退款:\n系统设置 > 华为账号 > 付款与账单 > 购买记录',
    confirm: {
      value: '确定',
      action: () => {}
    }
  });
}

function showAlternativeRefundMethod(): void {
  AlertDialog.show({
    title: '当前设备不支持退款',
    message: '请在手机或平板设备上申请退款,或联系客服处理退款事宜。',
    confirm: {
      value: '确定',
      action: () => {}
    }
  });
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因:1.必填参数未指定;2.参数类型错误 | 检查purchaseOrderId是否为非空字符串且长度≤256;检查context是否为UIAbilityContext |
| 801 | 设备能力不支持。当前设备不支持退款功能 | 在支持的设备(Phone/Tablet/2in1)上调用,或引导用户使用其他方式退款 |
| 1001860000 | 用户取消了当前操作 | 正常处理,不视为错误,无需特殊处理 |
| 1001860001 | 系统内部错误 | 提示用户稍后重试,若持续失败联系客服 |
| 1001860002 | 应用未被授权访问接口 | 检查应用是否在AppGallery Connect配置IAP权限 |
| 1001860004 | 接口访问过频 | 降低调用频率,避免短时间内多次调用 |
| 1001860005 | 网络连接异常 | 检查网络连接,引导用户在网络良好环境下操作 |
| 1001860054 | 用户账号所在服务地不支持IAP | 提示用户当前地区不支持退款功能 |
| 1001860061 | 商品已退款或退款中 | 提示用户订单已在退款流程中,无需重复申请 |
| 1001860062 | 不允许退款 | 检查订单状态,提示用户该订单不支持退款 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.IAPKit": "5.0.3(15)或更高版本",
    "@kit.AbilityKit": "5.0.0(12)或更高版本",
    "@kit.BasicServicesKit": "5.0.0(12)或更高版本"
  }
}
```

### 环境要求
- HarmonyOS API版本: 5.0.3(15)或更高
- 设备类型: Phone/Tablet/2in1
- 应用模型: Stage模型
- 用户系统版本: 6.16.10或更高(用于退款申请)

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.IAPKit'
```
**解决方法**: 确保项目已配置HarmonyOS SDK,且API版本不低于5.0.3(15)

**问题2: context类型错误**
```
Error: Type 'common.Context' is not assignable to type 'common.UIAbilityContext'
```
**解决方法**: 使用`this.getUIContext().getHostContext() as common.UIAbilityContext`获取正确的context

**问题3: purchaseOrderId参数错误**
```
Error: Parameter error. purchaseOrderId is empty
```
**解决方法**: 确保purchaseOrderId为非空字符串,且长度不超过256字符

## 常见问题与解决方法

### Q1: 用户点击退款按钮后界面没有反应
**原因**: 
- purchaseOrderId为空字符串
- context对象无效
- 设备不支持退款功能

**解决方法**:
- 检查purchaseOrderId是否从购买记录中正确获取
- 使用正确的UIAbilityContext对象
- 在支持的设备(Phone/Tablet/2in1)上测试

### Q2: 退款申请提交后多久能完成
**原因**: 退款流程涉及用户申请、开发者审核、华为操作等多个环节

**解决方法**:
- 提示用户退款流程非实时,通常需要7个工作日
- 在应用内提供退款状态查询功能
- 引导用户查看退款记录了解进度

### Q3: 游戏类应用能否使用此功能
**原因**: createRefundRequest API明确说明仅支持非游戏类应用

**解决方法**:
- 游戏类应用退款由华为游戏运营人员审核,开发者无需处理
- 游戏类应用不应调用此API,引导用户通过系统设置申请退款

### Q4: 如何获取purchaseOrderId
**原因**: purchaseOrderId是购买订单的唯一标识

**解决方法**:
- 通过queryPurchases或createPurchase接口获取购买结果
- 从购买结果中提取purchaseOrderId字段
- 在应用内保存购买记录,供退款时使用

### Q5: 用户在Wearable设备上无法退款
**原因**: 该API不支持Wearable设备

**解决方法**:
- 检测设备类型,在不支持设备上提示用户使用其他方式退款
- 引导用户在手机或平板设备上申请退款
- 或引导用户通过"系统设置 > 华为账号 > 付款与账单 > 购买记录"路径手动申请

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "refundRequestCreated": true,
  "purchaseOrderId": "传入的订单号ID",
  "message": "退款申请已提交,等待审核",
  "apiUsed": [
    "iap.createRefundRequest"
  ],
  "deviceType": "Phone/Tablet/2in1",
  "appVersion": "API 5.0.3(15)或更高"
}
```

## 参考文档

- [退款开发指南](references/iap-refund.md)
- [IAP API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)

## 完整示例代码

- [ArkTS退款示例](assets/iap-refund-example.ets)
- [退款流程说明](assets/refund-flow.md)

## 测试用例

### 正向测试用例
- [正常退款流程](tests/test_positive.ts): 测试在Phone设备上正常发起退款申请
- [获取订单号并退款](tests/test_positive.ts): 测试从购买记录获取purchaseOrderId并退款

### 边界测试用例
- [purchaseOrderId长度256](tests/test_boundary.ts): 测试purchaseOrderId最大长度256字符
- [多次退款同一订单](tests/test_boundary.ts): 测试对已退款订单再次申请退款(应返回1001860061错误码)

### 异常测试用例
- [空purchaseOrderId](tests/test_exception.ts): 测试传入空字符串(应返回401错误码)
- [不支持设备](tests/test_exception.ts): 测试在Wearable设备上调用(应返回801错误码)
- [网络断开](tests/test_exception.ts): 测试在无网络环境下调用(应返回1001860005错误码)
- [未登录账号](tests/test_exception.ts): 测试用户未登录华为账号时的行为