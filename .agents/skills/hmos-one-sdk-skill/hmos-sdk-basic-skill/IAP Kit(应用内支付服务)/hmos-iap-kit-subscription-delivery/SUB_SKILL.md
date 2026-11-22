---
name: hmos-iap-kit-subscription-delivery
description: 处理自动续期订阅商品权益发放，支持查询生效订阅、验证订单、发放权益、确认发货，适用于用户订阅成功后权益保障场景
---

# 权益发放技能

## 功能描述

本技能提供自动续期订阅商品的权益发放能力。用户购买自动续期订阅商品后，开发者需要及时给用户发放对应权益。本技能覆盖完整的权益发放流程，包括查询生效中的订阅列表、验证订单信息、处理权益发放、确认发货完成购买。

**核心能力**：
- 查询用户当前处于生效状态的订阅列表
- 对订阅订单进行解码验签，验证订单信息真实性
- 根据订阅状态判断是否需要发放权益
- 发放权益后确认发货，完成购买流程

**适用范围**：
- 自动续期订阅商品（AUTORENEWABLE类型）
- 仅支持Stage模型
- API版本：4.1.0(11)及以上
- 支持在元服务中使用（5.0.0(12)及以上）

**关键限制**：
- 必须在发放权益成功后调用finishPurchase确认发货
- 不执行确认发货会导致后续自动续期无法扣费
- 同一个订阅组不同自动续期订阅商品无法切换
- 单机应用建议将用户权益和订阅状态关联

**典型场景**：
- 应用启动时查询生效订阅并发放权益
- 订阅购买成功后及时发放权益
- 处理掉单情况，确保权益发放完整性

## 使用场景

### 触发词
- "发放订阅权益"
- "处理订阅订单"
- "确认订阅发货"
- "查询生效订阅"
- "权益发放"
- "订阅权益"
- "自动续期订阅"
- "掉单处理"

### 能做
- 查询用户当前生效的自动续期订阅商品列表
- 验证订阅订单信息的真实性和完整性
- 根据订阅状态自动判断是否需要发放权益
- 发放权益后确认发货，完成购买流程
- 处理已购但未确认发货的订阅商品（掉单场景）
- 支持应用客户端和应用服务器两种处理模式

### 绝不做
- 不处理消耗型商品或非消耗型商品的权益发放
- 不直接执行支付或购买流程
- 不处理订阅商品的退款或撤销操作
- 不跳过验证订单步骤直接发放权益
- 不重复发放同一笔订单的权益

### 补充
- 建议在应用启动时主动查询生效订阅，确保权益发放完整性
- 单机应用应将用户权益和订阅状态关联，订阅生效时始终发放权益
- 应用服务器可通过REST API处理权益发放和确认发货
- 可通过订阅状态查询接口进一步确认订阅信息准确性
- JWS验证需要使用Huawei CBG Root CA G2证书

## 调用规范和规则

### 输入约束
- **商品类型**：必须为自动续期订阅商品（ProductType.AUTORENEWABLE）
- **查询类型**：支持两种查询模式
  - CURRENT_ENTITLEMENT：查询当前生效的订阅
  - UNFINISHED：查询已购但未确认发货的订阅
- **上下文参数**：必须提供UIAbilityContext
- **验证证书**：需要Huawei CBG Root CA G2证书文件

### 执行约束
- **最大耗时**：单个订阅处理不超过5秒
- **最大迭代次数**：批量处理订阅列表不超过100条
- **API调用频次**：遵循IAP Kit接口频率限制，避免FREQUENT_CALLS错误
- **验证步骤**：必须先解码验签再发放权益

### 内容约束
- **禁止跳过验证**：必须对jwsSubscriptionStatus进行解码验签
- **禁止重复发货**：一个purchaseOrderId只能发货一次
- **禁止高危操作**：不使用eval、exec等高危函数
- **禁止硬编码**：purchaseToken、purchaseOrderId等参数必须动态获取

### 降级约束
- **网络失败**：提示用户网络异常，建议稍后重试
- **验证失败**：记录错误日志，不发放权益，通知用户联系客服
- **权益发放失败**：记录失败订单，提供补发机制
- **确认发货失败**：记录未确认订单，定时重试确认

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查应用是否已导入IAP Kit模块
2. 检查用户是否已登录华为账号
3. 检查应用是否在IAP支持的服务地区
4. 确认商品类型为自动续期订阅商品

**参数准备**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { JWSUtil } from '../common/JWSUtil';

const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

const queryParam: iap.QueryPurchasesParameter = {
  productType: iap.ProductType.AUTORENEWABLE,
  queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
};
```

### 步骤2：查询订阅列表

**示例代码**：
```typescript
async function queryActiveSubscriptions(context: common.UIAbilityContext): Promise<void> {
  const param: iap.QueryPurchasesParameter = {
    productType: iap.ProductType.AUTORENEWABLE,
    queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
  };

  try {
    const result: iap.QueryPurchaseResult = await iap.queryPurchases(context, param);
    console.info('Succeeded in querying purchases.');
    
    const purchaseDataList: string[] = result.purchaseDataList;
    if (purchaseDataList === undefined || purchaseDataList.length <= 0) {
      console.info('No active subscriptions found.');
      return;
    }

    for (let i = 0; i < purchaseDataList.length; i++) {
      await processSubscriptionData(purchaseDataList[i], context);
    }
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`Failed to query purchases. Code: ${error.code}, Message: ${error.message}`);
    handleQueryError(error);
  }
}
```

### 步骤3：验证订单信息

**解码验签**：
```typescript
async function processSubscriptionData(purchaseData: string, context: common.UIAbilityContext): Promise<void> {
  try {
    const jwsSubscriptionStatus: string = JSON.parse(purchaseData).jwsSubscriptionStatus;
    if (!jwsSubscriptionStatus) {
      console.warn('No subscription status found in purchase data.');
      return;
    }

    const subscriptionStatus: string = JWSUtil.decodeJwsObj(jwsSubscriptionStatus);
    const subGroupStatusPayload: SubGroupStatusPayload = JSON.parse(subscriptionStatus);

    const lastSubscriptionStatus = subGroupStatusPayload.lastSubscriptionStatus;
    if (!lastSubscriptionStatus) {
      console.warn('No last subscription status found.');
      return;
    }

    const status = lastSubscriptionStatus.status;
    const purchaseOrderPayload = lastSubscriptionStatus.lastPurchaseOrder;

    if (purchaseOrderPayload === undefined) {
      console.warn('No purchase order found.');
      return;
    }

    if (status === '1') {
      console.info(`Subscription is active. OrderId: ${purchaseOrderPayload.purchaseOrderId}`);
      await deliverSubscriptionBenefit(purchaseOrderPayload, context);
    } else {
      console.info(`Subscription status: ${status}. No benefit delivery needed.`);
    }
  } catch (err) {
    console.error('Failed to process subscription data:', err);
    handleProcessError(err);
  }
}
```

### 步骤4：权益发放

**发放逻辑**：
```typescript
async function deliverSubscriptionBenefit(purchaseOrder: PurchaseOrderPayload, context: common.UIAbilityContext): Promise<void> {
  try {
    const orderId = purchaseOrder.purchaseOrderId;
    const productId = purchaseOrder.productId;

    const isDelivered = await checkBenefitDeliveryStatus(orderId);
    if (isDelivered) {
      console.info(`Benefit already delivered for order: ${orderId}`);
      return;
    }

    await grantUserBenefit(productId, orderId);
    await recordDeliveryOrder(purchaseOrder);

    console.info(`Benefit delivered successfully for order: ${orderId}`);

    if (purchaseOrder.finishStatus !== '1') {
      await confirmPurchaseDelivery(purchaseOrder, context);
    }
  } catch (err) {
    console.error('Failed to deliver benefit:', err);
    handleDeliveryError(err, purchaseOrder);
  }
}

async function checkBenefitDeliveryStatus(orderId: string): Promise<boolean> {
  return false;
}

async function grantUserBenefit(productId: string, orderId: string): Promise<void> {
  console.info(`Granting benefit for product: ${productId}, order: ${orderId}`);
}

async function recordDeliveryOrder(purchaseOrder: PurchaseOrderPayload): Promise<void> {
  console.info(`Recording order: ${purchaseOrder.purchaseOrderId}`);
}
```

### 步骤5：确认发货

**finishPurchase调用**：
```typescript
async function confirmPurchaseDelivery(purchaseOrder: PurchaseOrderPayload, context: common.UIAbilityContext): Promise<void> {
  const finishPurchaseParam: iap.FinishPurchaseParameter = {
    productType: Number(purchaseOrder.productType),
    purchaseToken: purchaseOrder.purchaseToken,
    purchaseOrderId: purchaseOrder.purchaseOrderId
  };

  try {
    await iap.finishPurchase(context, finishPurchaseParam);
    console.info('Succeeded in finishing purchase.');
    await updateDeliveryConfirmation(purchaseOrder.purchaseOrderId);
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`Failed to finish purchase. Code: ${error.code}, Message: ${error.message}`);
    handleFinishError(error, purchaseOrder);
  }
}

async function updateDeliveryConfirmation(orderId: string): Promise<void> {
  console.info(`Delivery confirmed for order: ${orderId}`);
}
```

### 步骤6：错误处理

**错误处理代码**：
```typescript
function handleQueryError(error: BusinessError): void {
  switch (error.code) {
    case 1001860050:
      console.error('User not logged in. Please login first.');
      break;
    case 1001860005:
      console.error('Network error. Please check network connection.');
      break;
    case 1001860004:
      console.error('Too frequent API calls. Please wait and retry.');
      break;
    case 1001860054:
      console.error('IAP not supported in current region.');
      break;
    default:
      console.error(`Query error: ${error.message}`);
  }
}

function handleFinishError(error: BusinessError, purchaseOrder: PurchaseOrderPayload): void {
  switch (error.code) {
    case 1001860052:
      console.error('Purchase not paid. Cannot finish delivery.');
      break;
    case 1001860053:
      console.error('Purchase already finished.');
      break;
    case 1001860001:
      console.error('System error. Will retry later.');
      scheduleRetryConfirmation(purchaseOrder);
      break;
    default:
      console.error(`Finish error: ${error.message}`);
  }
}

function scheduleRetryConfirmation(purchaseOrder: PurchaseOrderPayload): void {
  console.info(`Scheduled retry for order: ${purchaseOrder.purchaseOrderId}`);
}
```

### 步骤7：降级处理

**降级方案**：
```typescript
async function fallbackDeliveryProcess(purchaseOrder: PurchaseOrderPayload): Promise<void> {
  try {
    console.warn('Using fallback delivery process.');
    await recordFailedDelivery(purchaseOrder);
    await notifyUserDeliveryPending(purchaseOrder.productId);
  } catch (err) {
    console.error('Fallback delivery failed:', err);
    await alertAdministrator(purchaseOrder, err);
  }
}

async function recordFailedDelivery(purchaseOrder: PurchaseOrderPayload): Promise<void> {
  console.info(`Recording failed delivery: ${purchaseOrder.purchaseOrderId}`);
}

async function notifyUserDeliveryPending(productId: string): Promise<void> {
  console.info(`Notifying user about pending delivery for: ${productId}`);
}

async function alertAdministrator(purchaseOrder: PurchaseOrderPayload, error: any): Promise<void> {
  console.error(`Alert: Critical delivery failure for ${purchaseOrder.purchaseOrderId}`, error);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001860000 | 用户取消当前操作 | 提示用户操作已取消，无需处理 |
| 1001860001 | 系统内部错误 | 记录错误日志，稍后重试或联系客服 |
| 1001860002 | 应用未被授权访问接口 | 检查应用配置，确认IAP权限已开启 |
| 1001860003 | 无效的商品信息 | 检查商品ID是否正确配置 |
| 1001860004 | 接口访问过频 | 降低API调用频率，添加延迟 |
| 1001860005 | 网络连接异常 | 提示用户检查网络，稍后重试 |
| 1001860007 | 商品所属应用未在指定地区上架 | 检查应用上架地区配置 |
| 1001860050 | 未登录华为账号 | 引导用户登录华为账号 |
| 1001860051 | 用户已拥有该商品 | 检查订阅状态，已生效无需重复购买 |
| 1001860052 | 商品未支付，无法发货 | 确认支付状态，支付成功后再发货 |
| 1001860053 | 购买已完成，无需重复发货 | 检查finishStatus，已发货无需重复调用 |
| 1001860054 | 用户账号所在服务地不支持IAP | 提示用户当前地区不支持此服务 |
| 1001860056 | 用户交易被拒绝 | 联系客服处理交易拒绝问题 |
| 1001860059 | 无效的优惠信息 | 检查优惠ID和优惠类型配置 |
| 1001860060 | 无效的签名信息 | 检查JWS签名验证流程 |
| 1001860061 | 商品已退款或退款中 | 停止发放权益，处理退款逻辑 |
| 1001860062 | 不允许退款 | 按正常流程处理 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.IAPKit": "HarmonyOS SDK",
    "@kit.AbilityKit": "HarmonyOS SDK",
    "@kit.BasicServicesKit": "HarmonyOS SDK"
  }
}
```

### 环境要求
- HarmonyOS SDK版本：4.1.0(11)及以上
- Stage模型应用
- 设备类型：Phone、PC/2in1、Tablet（支持），Wearable不支持自动续期订阅
- 需要在AppGallery Connect配置自动续期订阅商品

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.IAPKit'
```
**解决方法**：确保已安装HarmonyOS SDK，并在oh-package.json5中正确配置依赖

**问题2：类型定义缺失**
```
Error: Cannot find name 'SubGroupStatusPayload'
```
**解决方法**：自定义数据模型类，参考数据模型定义创建interface

**问题3：JWSUtil工具类缺失**
```
Error: Cannot find module '../common/JWSUtil'
```
**解决方法**：参考JWS解码验签示例代码实现JWSUtil类，或从示例工程导入

**问题4：权限配置缺失**
```
Error: 1001860002 - The application is not authorized
```
**解决方法**：在module.json5中添加IAP权限声明

**问题5：商品未配置**
```
Error: 1001860003 - Invalid product information
```
**解决方法**：在AppGallery Connect后台配置自动续期订阅商品

## 常见问题与解决方法

### Q1：如何处理掉单情况？
**原因**：用户支付成功但应用未收到通知，导致权益未发放
**解决方法**：
- 在应用启动时查询UNFINISHED类型的订阅列表
- 检查finishStatus不为1的订单
- 补发放权益并调用finishPurchase确认发货

### Q2：订阅状态status的含义？
**原因**：需要理解订阅状态码含义才能正确处理
**解决方法**：
- status=1：订阅生效中，需要发放权益
- status=2：订阅已到期，停止发放权益
- status=3：尝试扣费，等待扣费结果
- status=5：订阅撤销，停止权益并处理退款

### Q3：为什么要调用finishPurchase？
**原因**：不确认发货会导致后续自动续期无法扣费
**解决方法**：
- 发放权益成功后必须调用finishPurchase
- finishStatus不为1时才需要调用
- 可在应用客户端或应用服务器调用
- 服务器可通过REST API订阅确认发货接口

### Q4：如何验证JWS签名？
**原因**：保证订单信息真实性和完整性
**解决方法**：
- 使用Huawei CBG Root CA G2证书验证证书链
- 校验叶子证书的OID：1.3.6.1.4.1.2011.2.415.1.1
- 使用ES256算法和PublicKey验证签名
- 参考[jwt.io](https://jwt.io/)使用开源库验签

### Q5：单机应用如何处理权益发放？
**原因**：单机应用无应用服务器，需要本地处理
**解决方法**：
- 在应用启动时查询CURRENT_ENTITLEMENT订阅列表
- 将用户权益和订阅状态关联存储
- 订阅生效时始终发放权益
- 定期查询订阅状态更新权益

### Q6：如何处理订阅切换？
**原因**：用户在同一订阅组内切换不同订阅商品
**解决方法**：
- 从SubGroupStatusPayload获取lastSubscriptionStatus
- 检查historySubscriptionStatusList历史订阅
- 根据最新的lastPurchaseOrder发放权益
- 注意subGroupGenerationId在切换时不变

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "processedSubscriptions": 5,
  "deliveredBenefits": 3,
  "confirmedPurchases": 3,
  "failedDeliveries": 0,
  "apiUsed": [
    "iap.queryPurchases",
    "iap.finishPurchase"
  ],
  "dataModelsUsed": [
    "QueryPurchasesParameter",
    "QueryPurchaseResult",
    "PurchaseData",
    "SubGroupStatusPayload",
    "PurchaseOrderPayload",
    "FinishPurchaseParameter"
  ],
  "recommendations": [
    "建议定期查询订阅状态，确保权益发放完整性",
    "建议记录所有发货订单，避免重复发货",
    "建议应用服务器处理验证和发货，提高安全性"
  ]
}
```

## 参考文档

- [权益发放开发指南](references/iap-delivering-subscriptions.md)
- [IAP ArkTS API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)
- [IAP数据模型参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-data-model)
- [订阅确认发货REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-confirm-purchase-for-sub)
- [JWS签名验证说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-verifying-signature)
- [IAP使用入门指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-dev-guide)

## 完整示例代码

- [ArkTS完整示例](assets/iap_subscription_delivery.ets)
- [JWS验证工具类](assets/JWSUtil.ts)
- [服务器端示例](assets/server_delivery_example.java)
- [配置文件示例](assets/subscription_config.json)

## 测试用例

### 正向测试用例
- [查询生效订阅成功](tests/test_query_active_subscription.py)：验证查询CURRENT_ENTITLEMENT订阅列表
- [权益发放成功](tests/test_deliver_benefit.py)：验证权益发放逻辑和发货确认
- [验证订单成功](tests/test_verify_order.py)：验证JWS解码验签流程

### 边界测试用例
- [无生效订阅](tests/test_no_active_subscription.py)：验证订阅列表为空的处理
- [已发货订单](tests/test_already_delivered.py)：验证finishStatus=1的订单处理
- [订阅已到期](tests/test_expired_subscription.py)：验证status=2的订阅处理

### 异常测试用例
- [网络错误](tests/test_network_error.py)：验证网络异常的降级处理
- [验证失败](tests/test_verification_failed.py)：验证JWS验签失败的处理
- [未登录账号](tests/test_not_logged_in.py)：验证用户未登录的错误处理
- [商品未配置](tests/test_product_not_configured.py)：验证商品ID无效的错误处理