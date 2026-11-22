---
name: hmos-iap-kit-integrate-subscription
description: 接入自动续期订阅商品购买流程，支持Phone/Tablet/PC/2in1/TV/Car设备，需完成权益发放和finishPurchase确认，适用于订阅制服务场景
---

# 接入自动续期订阅技能

## 功能描述

本技能实现HarmonyOS应用内支付（IAP Kit）自动续期订阅商品的完整接入流程，包括环境检查、商品查询、购买发起、结果处理、权益发放和购买确认等关键环节。自动续期订阅商品支持按周期自动扣费续订，适用于会员服务、内容订阅等场景。

**核心能力**：
- 检查用户账号服务地是否支持IAP结算
- 查询并展示订阅商品信息
- 发起订阅购买并拉起收银台
- 处理购买结果并解码验签
- 发放订阅权益并确认发货
- 管理订阅状态和续期逻辑

**设备支持**：Phone、Tablet、PC/2in1、TV（5.1.1(19)及以上）、Car（26.0.0及以上）

**API版本**：起始版本4.1.0(11)，支持Stage模型

## 使用场景

### 触发词
- "接入自动续期订阅"
- "自动续期订阅购买"
- "订阅商品购买流程"
- "IAP订阅接入"
- "自动续期订阅"

### 能做
- 实现完整的自动续期订阅商品购买流程
- 检查IAP环境可用性并展示订阅商品列表
- 发起订阅购买并处理购买结果
- 解码验签JWS格式数据获取订阅状态
- 发放权益并确认发货完成购买流程
- 处理购买失败场景的补发货逻辑
- 查询用户当前生效的订阅列表

### 绝不做
- 不处理消耗型商品购买流程（需使用消耗型商品技能）
- 不处理非消耗型商品购买流程（需使用非消耗型商品技能）
- 不处理非续期订阅商品购买流程
- 不绕过权益发放直接确认发货
- 不重复确认已发货的订单
- 不在未验签的情况下直接处理购买数据

### 补充
- 必须确保权益发放成功后再调用finishPurchase确认发货
- 对于购买失败场景（错误码1001860001或1001860051），需检查是否需要补发货
- 建议使用服务端关键事件通知接收购买结果，提高安全性
- 单机应用可使用客户端接收购买结果，但建议在应用服务器验签
- 订阅商品购买后若不执行finishPurchase，会导致后续自动续期无法扣费

## 调用规范和规则

### 输入约束
- 商品ID：必须在AppGallery Connect配置且审核通过，每次最多查询200个商品
- 商品类型：必须指定为`iap.ProductType.AUTORENEWABLE`（自动续期订阅）
- 用户账号：必须已登录华为账号
- 服务地限制：仅支持中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）

### 执行约束
- API调用频次：默认间隔5秒，避免频繁调用（错误码1001860004）
- 权益发放：必须在验签成功后发放权益，检查订单是否已发放
- 确认发货：必须在权益发放成功后调用finishPurchase
- 验签要求：必须使用华为CBG Root CA G2证书验证JWS签名

### 内容约束
- 禁止直接处理未验签的购买数据
- 禁止跳过权益发放直接确认发货
- 禁止重复确认已发货订单（错误码1001860053）
- 禁止使用eval、exec等高危函数处理购买数据
- 禁止硬编码敏感信息（purchaseToken、purchaseOrderId等）

### 降级约束
- 网络失败（错误码1001860005）：提示用户检查网络后重试
- 商品无效（错误码1001860003）：检查商品配置状态，使用沙盒账号测试
- 服务地不支持（错误码1001860054）：隐藏IAP功能入口
- 系统错误（错误码1001860001）：通过queryPurchases检查未发货商品，补发货后重试
- 用户取消（错误码1001860000）：向用户提示操作取消

## 调用流程和步骤

### 步骤1：检查IAP环境状态

**前置校验**：
1. 确认应用已开启IAP服务开关
2. 确认用户已登录华为账号
3. 确认应用签名配置正确

**示例代码**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function checkIAPEnvironment(context: common.UIAbilityContext): Promise<boolean> {
  try {
    await iap.queryEnvironmentStatus(context);
    console.info('IAP environment is available.');
    return true;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to query environment status. Code: ${error.code}, Message: ${error.message}`);
    
    if (error.code === 1001860054) {
      console.warn('User account territory not supported. Hide IAP features.');
      return false;
    }
    
    if (error.code === 1001860050) {
      console.warn('User not logged in. Please guide user to login.');
      return false;
    }
    
    return false;
  }
}
```

### 步骤2：查询订阅商品列表

**参数准备**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function querySubscriptionProducts(
  context: common.UIAbilityContext,
  productIds: string[]
): Promise<Array<iap.Product>> {
  const queryProductParam: iap.QueryProductsParameter = {
    productType: iap.ProductType.AUTORENEWABLE,
    productIds: productIds
  };
  
  try {
    const products = await iap.queryProducts(context, queryProductParam);
    console.info(`Succeeded in querying products. Found ${products.length} products.`);
    return products;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to query products. Code: ${error.code}, Message: ${error.message}`);
    throw error;
  }
}
```

### 步骤3：查询当前生效的订阅

**示例代码**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function queryActiveSubscriptions(
  context: common.UIAbilityContext
): Promise<Array<iap.PurchaseData>> {
  const queryPurchasesParam: iap.QueryPurchasesParameter = {
    productType: iap.ProductType.AUTORENEWABLE,
    queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
  };
  
  try {
    const result = await iap.queryPurchases(context, queryPurchasesParam);
    console.info(`Succeeded in querying purchases. Found ${result.purchaseDataList.length} active subscriptions.`);
    return result.purchaseDataList;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to query purchases. Code: ${error.code}, Message: ${error.message}`);
    throw error;
  }
}
```

### 步骤4：发起订阅购买

**示例代码**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function createSubscriptionPurchase(
  context: common.UIAbilityContext,
  productId: string,
  developerPayload?: string
): Promise<iap.CreatePurchaseResult> {
  const purchaseParam: iap.PurchaseParameter = {
    productType: iap.ProductType.AUTORENEWABLE,
    productId: productId,
    developerPayload: developerPayload || ''
  };
  
  try {
    const result = await iap.createPurchase(context, purchaseParam);
    console.info('Succeeded in creating purchase.');
    return result;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to create purchase. Code: ${error.code}, Message: ${error.message}`);
    
    if (error.code === iap.IAPErrorCode.PRODUCT_OWNED || error.code === iap.IAPErrorCode.SYSTEM_ERROR) {
      console.warn('Product owned or system error. Check for supplementary delivery.');
    }
    
    throw error;
  }
}
```

### 步骤5：解码验签购买结果

**前置条件**：
- JWS数据包含订阅状态信息（jwsSubscriptionStatus）
- 使用华为CBG Root CA G2证书验签

**示例代码**：
```typescript
import { JWSUtil } from '../common/JWSUtil';

interface SubGroupStatusPayload {
  environment: string;
  applicationId: string;
  packageName: string;
  subGroupId: string;
  lastSubscriptionStatus?: SubscriptionStatus;
  historySubscriptionStatusList?: SubscriptionStatus[];
}

interface SubscriptionStatus {
  subGroupGenerationId: string;
  subscriptionId: string;
  purchaseToken: string;
  status: string;
  expiresTime: number;
  lastPurchaseOrder?: PurchaseOrderPayload;
}

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: string;
  productId: string;
  price: number;
  currency: string;
  purchaseTime: number;
}

function decodeAndVerifyPurchaseResult(result: iap.CreatePurchaseResult): SubGroupStatusPayload | null {
  try {
    const purchaseData = JSON.parse(result.purchaseData);
    const jwsSubscriptionStatus = purchaseData.jwsSubscriptionStatus;
    
    if (!jwsSubscriptionStatus) {
      console.error('No subscription status found in purchase data.');
      return null;
    }
    
    const subscriptionStatusStr = JWSUtil.decodeJwsObj(jwsSubscriptionStatus);
    if (!subscriptionStatusStr) {
      console.error('Failed to decode JWS subscription status.');
      return null;
    }
    
    const subGroupStatusPayload: SubGroupStatusPayload = JSON.parse(subscriptionStatusStr);
    console.info('Successfully decoded and verified purchase result.');
    return subGroupStatusPayload;
  } catch (error) {
    console.error('Failed to decode purchase result:', error);
    return null;
  }
}
```

### 步骤6：发放权益并确认发货

**判定条件**：
- 订阅状态必须为"1"（生效中）
- 订单未发放权益（finishStatus不为"1"）

**示例代码**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function deliverEntitlementAndFinishPurchase(
  context: common.UIAbilityContext,
  purchaseOrder: PurchaseOrderPayload
): Promise<boolean> {
  try {
    const finishStatus = purchaseOrder.finishStatus;
    if (finishStatus === '1') {
      console.warn('Purchase already finished. Skip delivery.');
      return false;
    }
    
    await deliverEntitlement(purchaseOrder);
    
    const finishPurchaseParam: iap.FinishPurchaseParameter = {
      productType: Number(purchaseOrder.productType),
      purchaseToken: purchaseOrder.purchaseToken,
      purchaseOrderId: purchaseOrder.purchaseOrderId
    };
    
    await iap.finishPurchase(context, finishPurchaseParam);
    console.info('Succeeded in finishing purchase. Delivery confirmed.');
    return true;
  } catch (error) {
    console.error('Failed to finish purchase:', error);
    return false;
  }
}

async function deliverEntitlement(purchaseOrder: PurchaseOrderPayload): Promise<void> {
  console.info(`Delivering entitlement for product: ${purchaseOrder.productId}`);
  console.info(`Purchase order ID: ${purchaseOrder.purchaseOrderId}`);
  console.info(`Purchase time: ${purchaseOrder.purchaseTime}`);
}
```

### 步骤7：处理购买失败场景

**错误码处理**：
```typescript
import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function handlePurchaseError(
  context: common.UIAbilityContext,
  error: BusinessError
): Promise<void> {
  if (error.code === iap.IAPErrorCode.PRODUCT_OWNED || error.code === iap.IAPErrorCode.SYSTEM_ERROR) {
    console.warn('Purchase failed with PRODUCT_OWNED or SYSTEM_ERROR. Check for supplementary delivery.');
    
    try {
      const activeSubscriptions = await queryActiveSubscriptions(context);
      
      for (const purchaseData of activeSubscriptions) {
        const jwsSubscriptionStatus = JSON.parse(purchaseData.jwsSubscriptionStatus || '');
        if (jwsSubscriptionStatus) {
          const subscriptionStatusStr = JWSUtil.decodeJwsObj(jwsSubscriptionStatus);
          const subGroupStatusPayload: SubGroupStatusPayload = JSON.parse(subscriptionStatusStr);
          
          if (subGroupStatusPayload.lastSubscriptionStatus) {
            const lastOrder = subGroupStatusPayload.lastSubscriptionStatus.lastPurchaseOrder;
            if (lastOrder && lastOrder.finishStatus !== '1') {
              await deliverEntitlementAndFinishPurchase(context, lastOrder);
            }
          }
        }
      }
    } catch (queryError) {
      console.error('Failed to query active subscriptions for supplementary delivery:', queryError);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001860000 | 用户取消当前操作 | 向用户提示操作取消 |
| 1001860001 | 系统内部错误 | 通过queryPurchases检查未发货商品，补发货后重试 |
| 1001860002 | 应用未被授权访问接口 | 检查应用签名配置和IAP服务开关 |
| 1001860003 | 无效的商品信息 | 检查商品ID和配置状态，使用沙盒账号测试 |
| 1001860004 | 接口访问过频 | 控制API调用频次，间隔至少5秒 |
| 1001860005 | 网络连接异常 | 提示用户检查网络连接 |
| 1001860050 | 未登录华为账号 | 引导用户登录华为账号 |
| 1001860051 | 已拥有该商品，购买失败 | 检查订阅状态，确认是否已生效 |
| 1001860052 | 未拥有该商品，发货失败 | 检查购买记录确认购买状态 |
| 1001860053 | 购买已完成，无需重复发货 | 检查订单发货状态 |
| 1001860054 | 用户账号服务地不支持IAP | 隐藏IAP功能入口 |
| 1001860056 | 用户交易被拒绝 | 稍后重试或更换支付方式 |
| 1001860059 | 无效的优惠信息 | 检查商品促销配置 |
| 1001860060 | 无效的签名信息 | 检查签名密钥和参数 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.IAPKit": "4.1.0(11)",
    "@kit.AbilityKit": "4.0.0(10)",
    "@kit.BasicServicesKit": "4.0.0(10)"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低版本4.1.0(11)
- Stage模型：仅支持Stage模型
- 设备支持：Phone、Tablet、PC/2in1、TV（5.1.1(19)+）、Car（26.0.0+）
- 开发环境：DevEco Studio 4.0及以上

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.IAPKit'
```
**解决方法**：确保HarmonyOS SDK版本不低于4.1.0(11)，在DevEco Studio中更新SDK

**问题2：类型定义缺失**
```
Error: Property 'ProductType' does not exist on type 'iap'
```
**解决方法**：检查API版本，ProductType.AUTORENEWABLE需要4.1.0(11)及以上版本

**问题3：finishPurchase调用失败**
```
Error: 1001860052 The purchase cannot be finished because the user has not paid for it
```
**解决方法**：确保在购买成功后调用finishPurchase，检查purchaseToken和purchaseOrderId参数正确

**问题4：JWS验签失败**
```
Error: Invalid purchase signature
```
**解决方法**：使用华为CBG Root CA G2证书验签，检查证书链完整性

## 常见问题与解决方法

### Q1：购买成功但未自动续期
**原因**：未调用finishPurchase确认发货，导致订阅无法正常续费
**解决方法**：
- 确保在权益发放成功后调用finishPurchase
- 检查finishStatus字段，确认订单已发货
- 通过queryPurchases检查未发货订单并补发货

### Q2：用户切换订阅商品失败
**原因**：原订阅未完成发货确认，存在未发货订单
**解决方法**：
- 通过queryPurchases查询所有生效订阅
- 检查每个订阅的finishStatus状态
- 对未发货订单执行finishPurchase确认

### Q3：购买失败但显示已拥有商品
**原因**：用户已购买该订阅商品且订阅生效中
**解决方法**：
- 通过queryPurchases查询生效订阅
- 检查订阅状态是否为"1"（生效中）
- 若订阅生效，隐藏购买入口或提示用户已订阅

### Q4：沙盒测试购买失败
**原因**：未使用沙盒测试账号或应用未使用debug签名
**解决方法**：
- 在AppGallery Connect中配置测试账号
- 使用debug签名的应用进行测试
- 登录配置的测试账号发起购买

### Q5：服务端验签失败
**原因**：证书链验证失败或签名算法错误
**解决方法**：
- 使用华为CBG Root CA G2证书（https://pki.consumer.huawei.com/ca/cer/RootCaG2Ecdsa.cer）
- 检验叶子证书OID：1.3.6.1.4.1.2011.2.415.1.1
- 使用ES256算法验签
- 参考IAP Kit-Sample-ServerDemo示例代码

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "subscriptionId": "订阅ID",
  "purchaseOrderId": "购买订单ID",
  "productId": "商品ID",
  "productType": "2",
  "purchaseTime": "购买时间戳（毫秒）",
  "expiresTime": "过期时间戳（毫秒）",
  "status": "订阅状态（1：生效中）",
  "finishStatus": "发货状态（1：已发货）",
  "apiUsed": [
    "queryEnvironmentStatus",
    "queryProducts",
    "queryPurchases",
    "createPurchase",
    "finishPurchase"
  ]
}
```

## 参考文档

- [接入自动续期订阅开发指南](references/iap-integrate-subscription.md)
- [IAP ArkTS API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)
- [IAP数据模型参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-data-model)
- [订阅确认发货REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-confirm-purchase-for-sub)
- [订阅状态查询REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-query-subscription-status)
- [JWS验签说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-verifying-signature)
- [IAP错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-error-code)
- [确保权益发放](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-delivering-subscriptions)

## 完整示例代码

- [ArkTS客户端示例](assets/iap_subscription_client.ets)
- [服务端验签示例](assets/jws_verification.java)
- [服务端订阅确认示例](assets/subscription_confirm_server.java)
- [JWSUtil工具类](assets/JWSUtil.ts)

## 测试用例

### 正向测试用例
- [测试环境检查成功](tests/test_query_environment_success.py)：验证IAP环境可用
- [测试查询商品成功](tests/test_query_products_success.py)：验证订阅商品查询
- [测试订阅购买成功](tests/test_create_purchase_success.py)：验证订阅购买流程
- [测试权益发放成功](tests/test_deliver_entitlement_success.py)：验证权益发放和确认发货

### 边界测试用例
- [测试最多200个商品查询](tests/test_query_products_max_limit.py)：验证商品查询数量限制
- [测试API调用频次限制](tests/test_api_frequency_limit.py)：验证5秒调用间隔
- [测试订阅状态切换](tests/test_subscription_switch.py)：验证订阅商品切换场景

### 异常测试用例
- [测试用户取消购买](tests/test_user_cancel_purchase.py)：验证错误码1001860000处理
- [测试网络连接失败](tests/test_network_error.py)：验证错误码1001860005处理
- [测试服务地不支持](tests/test_territory_not_supported.py)：验证错误码1001860054处理
- [测试重复发货](tests/test_duplicate_finish_purchase.py)：验证错误码1001860053处理