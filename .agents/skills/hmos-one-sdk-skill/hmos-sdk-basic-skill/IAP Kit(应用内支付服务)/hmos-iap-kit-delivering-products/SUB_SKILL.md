---
name: hmos-iap-kit-delivering-products
description: 发放消耗型和非消耗型商品权益，支持查询未发货订单、解码验签、发放权益、确认发货完整流程，最大支持批量购买10个商品，适用于应用内支付场景权益保障
---

# 权益发放技能

## 功能描述

本技能实现IAP Kit应用内支付场景下的权益发放功能，确保用户购买商品后及时获得相关权益。支持消耗型商品和非消耗型商品两种类型，包含完整的订单查询、验签验证、权益发放和确认发货流程，避免掉单情况导致的权益丢失。

核心能力包括：
- 查询用户已购未发货订单
- JWS格式数据解码验签
- 权益发放状态检查与处理
- 完成发货确认流程

## 使用场景

### 触发词
- "权益发放"
- "发放权益"
- "补发货"
- "掉单处理"
- "确认发货"
- "finishPurchase"
- "queryPurchases"

### 能做
- 查询已购买但未确认发货的消耗型/非消耗型商品订单
- 解码验签JWS格式的订单数据获取PurchaseOrderPayload
- 检查订单发货状态并发放相关权益
- 调用finishPurchase确认发货完成购买流程
- 处理应用启动时的掉单检查
- 处理购买请求返回PRODUCT_OWNED或SYSTEM_ERROR时的权益发放
- 支持单机应用非消耗型商品的权益恢复

### 绝不做
- 不处理自动续期订阅商品的权益发放（需使用订阅专用技能）
- 不处理支付失败的订单
- 不跳过验签直接使用订单数据
- 不在发货失败前调用finishPurchase确认发货
- 不处理已退款或退款中的订单

### 补充
- 必须在发货成功后才能调用finishPurchase确认发货
- 消耗型商品确认发货后才能再次购买，否则用户无法再次购买
- 需要在应用服务器对PurchaseData进行验签处理，确保数据完整性
- 批量购买场景需校验下单数量和实际发货数量一致性
- 单机应用非消耗型商品需要在应用首次打开时查询已购商品完成权益恢复

## 调用规范和规则

### 输入约束
- 商品类型：仅支持消耗型(iap.ProductType.CONSUMABLE)和非消耗型(iap.ProductType.NONCONSUMABLE)
- 查询类型：UNFINISHED(未发货订单)或CURRENT_ENTITLEMENT(已购非消耗型商品)
- 批量购买数量：单次最多10个商品
- 订单数据格式：JWS格式字符串，需解码验签

### 执行约束
- 最大查询订单数量：无限制，但建议分批处理
- 验签处理：必须在应用服务器执行，不能在客户端直接处理
- 发货确认时机：必须先发放权益成功后才能确认发货
- 网络超时：默认30秒，可根据实际情况调整

### 内容约束
- 禁止跳过验签步骤直接使用订单数据
- 禁止在未确认用户支付成功时发放权益
- 禁止对已发货订单重复调用finishPurchase
- 禁止使用未验证的PublicKey进行验签
- 必须校验productId和price等关键信息与实际配置一致

### 降级约束
- 网络失败：提示用户检查网络连接，稍后重试
- 验签失败：记录错误日志，不发放权益，提示用户联系客服
- 发货失败：记录失败原因，保留订单信息等待下次处理
- 查询为空：无未发货订单，跳过处理流程
- 服务器异常：使用本地缓存的订单信息尝试处理，记录异常日志

## 调用流程和步骤

### 步骤1：准备阶段 - 查询未发货订单

**前置校验**：
1. 检查用户是否登录华为账号
2. 磁盘是否有足够的存储空间记录订单信息
3. 网络连接是否正常

**参数准备**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';

const queryParam: iap.QueryPurchasesParameter = {
  productType: iap.ProductType.CONSUMABLE, // 或 iap.ProductType.NONCONSUMABLE
  queryType: iap.PurchaseQueryType.UNFINISHED // 或 CURRENT_ENTITLEMENT
};
```

### 步骤2：调用queryPurchases查询订单

**示例代码**：
```typescript
async function queryUnfinishedOrders(context: common.UIAbilityContext): Promise<void> {
  try {
    const queryParam: iap.QueryPurchasesParameter = {
      productType: iap.ProductType.CONSUMABLE,
      queryType: iap.PurchaseQueryType.UNFINISHED
    };
    
    const result: iap.QueryPurchaseResult = await iap.queryPurchases(context, queryParam);
    
    console.info('Succeeded in querying purchases.');
    
    const purchaseDataList: string[] = result.purchaseDataList;
    if (purchaseDataList === undefined || purchaseDataList.length <= 0) {
      console.info('No unfinished orders found.');
      return;
    }
    
    for (let i = 0; i < purchaseDataList.length; i++) {
      await processPurchaseData(purchaseDataList[i], context);
    }
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to query purchases. Code: ${err.code}, Message: ${err.message}`);
    handleQueryError(err);
  }
}
```

### 步骤3：解码验签获取订单详情

**验签处理**：
```typescript
import { JWSUtil } from '../common/JWSUtil';

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: string;
  productId: string;
  quantity?: number;
  purchaseTime: number;
  finishStatus?: string;
  purchaseOrderRevocationReasonCode?: string;
  price: number;
  currency: string;
  developerPayload?: string;
}

async function processPurchaseData(purchaseData: string, context: common.UIAbilityContext): Promise<void> {
  try {
    const purchaseDataObj = JSON.parse(purchaseData);
    const jwsPurchaseOrder: string = purchaseDataObj.jwsPurchaseOrder;
    
    if (!jwsPurchaseOrder) {
      console.warn('No jwsPurchaseOrder found in purchase data.');
      return;
    }
    
    const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
    const purchaseOrderPayload: PurchaseOrderPayload = JSON.parse(purchaseStr);
    
    if (purchaseOrderPayload.purchaseOrderRevocationReasonCode) {
      console.warn(`Order revoked. Reason: ${purchaseOrderPayload.purchaseOrderRevocationReasonCode}`);
      return;
    }
    
    await deliverProduct(purchaseOrderPayload, context);
  } catch (error) {
    console.error('Failed to process purchase data:', error);
  }
}
```

### 步骤4：权益发放处理

**发货逻辑**：
```typescript
async function deliverProduct(purchaseOrder: PurchaseOrderPayload, context: common.UIAbilityContext): Promise<void> {
  try {
    const isDelivered = await checkDeliveryStatus(purchaseOrder.purchaseOrderId);
    
    if (isDelivered) {
      console.info(`Order ${purchaseOrder.purchaseOrderId} already delivered.`);
      return;
    }
    
    await grantUserRights(purchaseOrder.productId, purchaseOrder.quantity || 1);
    await recordDeliveryInfo(purchaseOrder);
    
    console.info(`Successfully delivered product: ${purchaseOrder.productId}`);
    
    await finishPurchase(context, purchaseOrder);
  } catch (error) {
    console.error('Failed to deliver product:', error);
    recordDeliveryFailure(purchaseOrder, error);
  }
}
```

### 步骤5：确认发货完成流程

**finishPurchase调用**：
```typescript
async function finishPurchase(context: common.UIAbilityContext, purchaseOrder: PurchaseOrderPayload): Promise<void> {
  try {
    const finishParam: iap.FinishPurchaseParameter = {
      productType: Number(purchaseOrder.productType),
      purchaseToken: purchaseOrder.purchaseToken,
      purchaseOrderId: purchaseOrder.purchaseOrderId
    };
    
    await iap.finishPurchase(context, finishParam);
    
    console.info('Succeeded in finishing purchase.');
    console.info(`Product ${purchaseOrder.productId} marked as delivered.`);
    
    if (purchaseOrder.productType === '0') {
      console.info('Consumable product can be purchased again.');
    } else {
      console.info('Non-consumable product owned permanently.');
    }
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to finish purchase. Code: ${err.code}, Message: ${err.message}`);
    handleFinishError(err, purchaseOrder);
  }
}
```

### 步骤6：错误处理

**错误码处理**：
```typescript
function handleQueryError(err: BusinessError): void {
  switch (err.code) {
    case 1001860005:
      console.error('Network connection error. Please check network.');
      break;
    case 1001860050:
      console.error('User not logged in. Please login Huawei ID.');
      break;
    case 1001860054:
      console.error('User region does not support IAP.');
      break;
    case 1001860001:
      console.error('System internal error. Retry or query purchases again.');
      break;
    default:
      console.error(`Unknown error: ${err.code}`);
  }
}

function handleFinishError(err: BusinessError, purchaseOrder: PurchaseOrderPayload): void {
  switch (err.code) {
    case 1001860052:
      console.error('Purchase not paid. Cannot finish.');
      break;
    case 1001860053:
      console.warn('Purchase already finished. Skip duplicate finish.');
      break;
    case 1001860001:
      console.error('System error. Retry finish purchase later.');
      recordPendingFinish(purchaseOrder);
      break;
    default:
      console.error(`Failed to finish: ${err.code}`);
      recordPendingFinish(purchaseOrder);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001860000 | 用户取消当前操作 | 向用户提示操作已取消 |
| 1001860001 | 系统内部错误 | 通过queryPurchases确认是否存在未发货订单，及时发放权益 |
| 1001860002 | 应用未被授权 | 检查应用签名配置和支付服务开关是否开启 |
| 1001860003 | 无效的商品信息 | 检查商品ID和类型配置是否正确 |
| 1001860004 | 接口访问过频 | 控制调用频率，默认间隔5秒 |
| 1001860005 | 网络连接异常 | 提示用户检查网络连接 |
| 1001860050 | 未登录华为账号 | 引导用户登录华为账号 |
| 1001860051 | 已拥有该商品 | 消耗型商品检查是否发货并确认，非消耗型商品不能重复购买 |
| 1001860052 | 未拥有该商品 | 通过queryPurchases确认购买状态 |
| 1001860053 | 购买已完成发货 | 查询确认发货记录，避免重复操作 |
| 1001860054 | 用户地区不支持IAP | 隐藏IAP功能入口，仅支持中国大陆（不含港澳台） |
| 1001860056 | 用户交易被拒绝 | 稍后重试或更换支付方式 |

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
- HarmonyOS SDK: 4.1.0(11)及以上
- Stage模型应用
- 已开启和激活应用内购买服务
- 已配置商品信息并通过审核

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.IAPKit'
```
**解决方法**：确保项目已正确配置HarmonyOS SDK依赖，在build-profile.json5中添加正确的SDK配置。

**问题2：类型定义缺失**
```
Error: Cannot find name 'PurchaseOrderPayload'
```
**解决方法**：自定义PurchaseOrderPayload接口类型，参考iap-data-model.md中的定义。

**问题3：JWSUtil类未定义**
```
Error: Cannot find name 'JWSUtil'
```
**解决方法**：参考示例代码实现JWS解码验签工具类，或使用第三方JWT库。

## 常见问题与解决方法

### Q1：如何避免掉单导致的权益丢失？
**原因**：网络错误、进程中止等异常导致应用无法确认用户是否支付成功。
**解决方法**：
- 在应用启动时调用queryPurchases查询未发货订单
- 在购买返回PRODUCT_OWNED或SYSTEM_ERROR错误时查询订单
- 定期检查并处理未发货订单
- 在服务器端记录订单状态，支持补发货

### Q2：如何处理批量购买的权益发放？
**原因**：用户一次购买多个消耗型商品，需要发放相应数量的权益。
**解决方法**：
- 校验PurchaseOrderPayload.quantity字段
- 发放权益数量必须与购买数量一致
- 记录每个商品的发放情况
- 避免漏发或多发

### Q3：单机应用如何保障非消耗型商品权益？
**原因**：用户卸载重装或更换设备后权益丢失。
**解决方法**：
- 应用首次打开时查询CURRENT_ENTITLEMENT类型的订单
- 解码验签获取PurchaseOrderPayload
- 发放已购非消耗型商品权益
- 调用finishPurchase确认发货

### Q4：验签失败如何处理？
**原因**：签名密钥不合法、证书链验证失败、数据被篡改。
**解决方法**：
- 使用Huawei CBG Root CA G2证书验证证书链
- 校验叶子证书OID：1.3.6.1.4.1.2011.2.415.1.1
- 从叶子证书获取PublicKey验签
- 验签失败不发放权益，记录错误日志

### Q5：如何区分消耗型和非消耗型商品处理？
**原因**：两种商品类型的权益发放和确认逻辑不同。
**解决方法**：
- 消耗型商品：发货后可再次购买，必须调用finishPurchase确认
- 非消耗型商品：永久拥有，不能再次购买
- 使用PurchaseOrderPayload.productType区分（0为消耗型，1为非消耗型）
- 单机应用非消耗型商品需额外处理权益恢复

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "processedOrders": 3,
  "deliveredProducts": [
    {
      "productId": "testConsumeProduct01",
      "purchaseOrderId": "PO123456789",
      "productType": "consumable",
      "quantity": 5,
      "deliveryStatus": "delivered",
      "finishStatus": "finished"
    }
  ],
  "failedOrders": [],
  "apiUsed": [
    "iap.queryPurchases",
    "iap.finishPurchase",
    "JWSUtil.decodeJwsObj"
  ],
  "timestamp": "2026-07-03T10:14:20Z"
}
```

## 参考文档

- [权益发放开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-delivering-products)
- [IAP ArkTS API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)
- [IAP数据模型](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-data-model)
- [IAP错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-error-code)
- [对返回结果验签](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-verifying-signature)
- [接入购买流程](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-integrate-purchase)
- [使用入门示例代码](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-dev-guide)
- [订单确认发货REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-confirm-purchase-for-order)

## 完整示例代码

- [ArkTS完整示例](assets/iap-delivering-products-example.ets)
- [JWS验签工具类](assets/JWSUtil.ts)
- [服务器验签示例](assets/jws-verification-server.java)
- [配置文件示例](assets/iap-config.json)

## 测试用例

### 正向测试用例
- [查询未发货订单成功](tests/test_query_purchases_positive.ts)：验证正常查询流程
- [解码验签成功](tests/test_jws_decode_positive.ts)：验证JWS解码验签流程
- [发货确认成功](tests/test_finish_purchase_positive.ts)：验证finishPurchase调用成功

### 边界测试用例
- [批量购买10个商品](tests/test_batch_purchase_boundary.ts)：验证批量购买边界值
- [查询为空订单](tests/test_empty_orders_boundary.ts)：验证无订单时的处理
- [单机应用权益恢复](tests/test_standalone_app_boundary.ts)：验证非消耗型商品权益恢复

### 异常测试用例
- [网络连接失败](tests/test_network_error_exception.ts)：验证网络异常处理
- [验签失败](tests/test_signature_error_exception.ts)：验签失败时的降级处理
- [重复发货](tests/test_duplicate_delivery_exception.ts)：验证重复发货的拦截
- [未支付订单](tests/test_unpaid_order_exception.ts)：验证未支付订单的处理