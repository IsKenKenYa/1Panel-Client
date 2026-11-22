---
name: hmos-iap-kit-integrate-purchase
description: 接入消耗型和非消耗型商品购买功能,支持查询环境状态、展示商品列表、发起购买、处理购买结果、发放权益并完成购买,适用于应用内购买场景
version: 1.0.0
compatibility:
  api_version: '>=4.0.0(10)'
  device:
    - Phone
    - Tablet
    - PC/2in1
    - Wearable (>=5.1.0(18))
    - TV (>=5.1.1(19))
    - Car (>=26.0.0)
---

# IAP Kit 商品购买接入技能

## 功能描述

本技能提供华为应用内支付(IAP Kit)消耗型和非消耗型商品购买的完整接入能力,包括:
- 检查用户账号服务地是否支持IAP结算
- 查询并展示商品列表
- 发起购买请求并拉起收银台
- 处理购买结果(成功/失败)
- 发放权益并确认发货完成购买流程

适用于应用内购买场景,如游戏道具购买、会员权益购买、功能解锁等一次性付款的商品购买。

## 使用场景

### 触发词
- "接入IAP购买"
- "实现应用内支付"
- "消耗型商品购买"
- "非消耗型商品购买"
- "商品购买接入"
- "IAP Kit购买"

### 能做
- 接入消耗型商品购买流程(可重复购买)
- 接入非消耗型商品购买流程(一次性购买)
- 检查IAP服务可用性
- 展示商品信息(名称、价格等)
- 处理购买结果并发放权益
- 确认发货完成购买
- 处理优惠促销(可选)

### 绝不做
- 不处理订阅型商品购买(自动续期订阅和非续期订阅)
- 不处理支付退款流程
- 不直接处理支付密码或支付验证
- 不在未验证购买结果的情况下发放权益
- 不跳过发货确认步骤

### 补充
- 必须在AppGallery Connect配置商品信息并审核通过
- 必须配置应用身份信息和签名
- 建议通过应用服务器接收购买结果提高安全性
- 消耗型商品必须调用finishPurchase才能再次购买
- 非消耗型商品购买后永久拥有,无法再次购买
- 当前IAP Kit仅支持中国境内(港澳台除外)结算

## 调用规范和规则

### 输入约束
- 商品ID: 必须在AppGallery Connect配置并通过审核
- 商品类型: 必须明确指定CONSUMABLE(消耗型)或NONCONSUMABLE(非消耗型)
- 商品数量: queryProducts每次最多查询200个商品
- 单次购买数量: 消耗型商品quantity参数取值范围1-10
- 上下文参数: 必须使用UIAbilityContext

### 执行约束
- API调用频次: 默认间隔5秒,避免触发1001860004错误
- 最大耗时: 单次购买流程建议不超过60秒
- 验签操作: 必须对jwsPurchaseOrder进行解码验签
- 权益发放: 必须在发货成功后调用finishPurchase
- 错误重试: SYSTEM_ERROR错误需通过queryPurchases确认补发货

### 内容约束
- 禁止跳过验签: 必须验证jwsPurchaseOrder签名真实性
- 禁止提前finishPurchase: 必须在权益发放成功后确认
- 禁止使用过期purchaseToken: purchaseToken与订单一一对应
- 禁止忽略错误码: PRODUCT_OWNED和SYSTEM_ERROR需特殊处理补发货
- 禁止高危函数: 不使用eval、exec等动态执行函数

### 降级约束
- 网络失败: 提示用户检查网络,允许重试
- 账号未登录: 引导用户登录华为账号
- 服务地不支持: 隐藏IAP功能入口
- 商品未审核: 使用沙盒测试账号测试
- 验签失败: 拒绝发放权益,记录异常日志
- 补发货失败: 记录订单信息,提示用户联系客服

## 调用流程和步骤

### 步骤1: 检查环境状态

**前置校验**:
1. 确认应用已配置IAP服务开关
2. 确认应用签名信息正确
3. 确认用户已登录华为账号

**示例代码**:
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function checkIAPEnvironment(context: common.UIAbilityContext): Promise<boolean> {
  try {
    await iap.queryEnvironmentStatus(context);
    console.info('IAP environment is supported.');
    return true;
  } catch (err) {
    const error = err as BusinessError;
    if (error.code === 1001860054) {
      console.error('User account service region does not support IAP.');
      return false;
    }
    console.error(`Failed to query environment status. Code: ${error.code}, Message: ${error.message}`);
    return false;
  }
}
```

### 步骤2: 查询商品信息

**参数准备**:
```typescript
const queryProductParam: iap.QueryProductsParameter = {
  productType: iap.ProductType.CONSUMABLE,
  productIds: ['product001', 'product002']
};
```

**示例代码**:
```typescript
async function queryProducts(context: common.UIAbilityContext): Promise<Array<iap.Product>> {
  const queryProductParam: iap.QueryProductsParameter = {
    productType: iap.ProductType.CONSUMABLE,
    productIds: ['product001']
  };
  
  try {
    const products = await iap.queryProducts(context, queryProductParam);
    console.info(`Succeeded in querying products. Count: ${products.length}`);
    return products;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to query products. Code: ${error.code}, Message: ${error.message}`);
    throw error;
  }
}
```

### 步骤3: 发起购买请求

**示例代码**:
```typescript
async function createPurchase(context: common.UIAbilityContext, productId: string): Promise<iap.CreatePurchaseResult> {
  const purchaseParam: iap.PurchaseParameter = {
    productType: iap.ProductType.CONSUMABLE,
    productId: productId
  };
  
  try {
    const result = await iap.createPurchase(context, purchaseParam);
    console.info('Succeeded in creating purchase.');
    return result;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to create purchase. Code: ${error.code}, Message: ${error.message}`);
    throw error;
  }
}
```

### 步骤4: 处理购买结果

**解码验签示例**:
```typescript
import { JWSUtil } from '../common/JWSUtil';

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: string;
  productId: string;
  price: number;
  currency: string;
  purchaseTime: number;
  purchaseOrderRevocationReasonCode?: string;
}

async function handlePurchaseResult(result: iap.CreatePurchaseResult): Promise<PurchaseOrderPayload> {
  const purchaseData = JSON.parse(result.purchaseData);
  const jwsPurchaseOrder = purchaseData.jwsPurchaseOrder;
  
  if (!jwsPurchaseOrder) {
    throw new Error('No purchase order data found.');
  }
  
  const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
  const purchaseOrderPayload = JSON.parse(purchaseStr) as PurchaseOrderPayload;
  
  if (purchaseOrderPayload.purchaseOrderRevocationReasonCode) {
    console.warn('Purchase order revoked:', purchaseOrderPayload.purchaseOrderRevocationReasonCode);
    throw new Error('Purchase order has been revoked.');
  }
  
  console.info('Purchase verified successfully.');
  return purchaseOrderPayload;
}
```

### 步骤5: 发放权益并完成购买

**示例代码**:
```typescript
async function deliverProduct(purchaseOrder: PurchaseOrderPayload): Promise<boolean> {
  try {
    console.info(`Delivering product: ${purchaseOrder.productId}, Order: ${purchaseOrder.purchaseOrderId}`);
    await deliverProductToUser(purchaseOrder.productId);
    await recordPurchaseOrder(purchaseOrder);
    return true;
  } catch (error) {
    console.error('Failed to deliver product:', error);
    return false;
  }
}

async function finishPurchase(context: common.UIAbilityContext, purchaseOrder: PurchaseOrderPayload): Promise<void> {
  const finishPurchaseParam: iap.FinishPurchaseParameter = {
    productType: Number(purchaseOrder.productType),
    purchaseToken: purchaseOrder.purchaseToken,
    purchaseOrderId: purchaseOrder.purchaseOrderId
  };
  
  try {
    await iap.finishPurchase(context, finishPurchaseParam);
    console.info('Succeeded in finishing purchase.');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to finish purchase. Code: ${error.code}, Message: ${error.message}`);
    throw error;
  }
}
```

### 步骤6: 完整购买流程整合

**示例代码**:
```typescript
async function completePurchaseFlow(context: common.UIAbilityContext, productId: string): Promise<void> {
  try {
    const isSupported = await checkIAPEnvironment(context);
    if (!isSupported) {
      throw new Error('IAP is not supported in current region.');
    }
    
    const products = await queryProducts(context);
    const product = products.find(p => p.productId === productId);
    if (!product) {
      throw new Error('Product not found.');
    }
    
    const purchaseResult = await createPurchase(context, productId);
    const purchaseOrder = await handlePurchaseResult(purchaseResult);
    
    const delivered = await deliverProduct(purchaseOrder);
    if (!delivered) {
      throw new Error('Failed to deliver product.');
    }
    
    await finishPurchase(context, purchaseOrder);
    console.info('Purchase flow completed successfully.');
    
  } catch (error) {
    console.error('Purchase flow failed:', error);
    throw error;
  }
}
```

### 步骤7: 错误处理与补发货

**示例代码**:
```typescript
async function handlePurchaseError(context: common.UIAbilityContext, error: BusinessError): Promise<void> {
  if (error.code === iap.IAPErrorCode.PRODUCT_OWNED || error.code === iap.IAPErrorCode.SYSTEM_ERROR) {
    console.warn('Need to check for pending deliveries.');
    
    try {
      const queryParam: iap.QueryPurchasesParameter = {
        productType: iap.ProductType.CONSUMABLE
      };
      const purchases = await iap.queryPurchases(context, queryParam);
      
      for (const purchase of purchases.purchaseDataList) {
        const purchaseData = JSON.parse(purchase.purchaseData);
        const jwsPurchaseOrder = purchaseData.jwsPurchaseOrder;
        const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
        const purchaseOrder = JSON.parse(purchaseStr) as PurchaseOrderPayload;
        
        const delivered = await deliverProduct(purchaseOrder);
        if (delivered) {
          await finishPurchase(context, purchaseOrder);
        }
      }
    } catch (err) {
      console.error('Failed to handle pending purchases:', err);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001860000 | 用户取消当前操作 | 提示用户操作已取消 |
| 1001860001 | 系统内部错误 | 通过queryPurchases确认补发货,或重试 |
| 1001860002 | 应用未被授权 | 检查应用签名和IAP服务开关配置 |
| 1001860003 | 无效的商品信息 | 检查商品ID和类型,确认商品已审核通过 |
| 1001860004 | 接口访问过频 | 控制API调用间隔至少5秒 |
| 1001860005 | 网络连接异常 | 提示用户检查网络连接 |
| 1001860007 | 应用未在指定地区上架 | 在AppGallery Connect配置上架地区 |
| 1001860050 | 未登录华为账号 | 引导用户登录华为账号 |
| 1001860051 | 已拥有该商品 | 消耗型需finishPurchase,非消耗型已购买 |
| 1001860052 | 未拥有该商品无法发货 | 通过queryPurchases确认购买状态 |
| 1001860053 | 购买已完成无需重复发货 | 通过queryPurchases确认发货记录 |
| 1001860054 | 账号服务地不支持IAP | 隐藏IAP功能入口 |
| 1001860056 | 用户交易被拒绝 | 稍后重试或更换支付方式 |
| 1001860059 | 无效的优惠信息 | 检查商品是否配置了优惠活动 |
| 1001860060 | 无效的签名信息 | 检查优惠签名生成过程 |
| 1001860061 | 商品已退款或退款中 | 引导用户查看订单退款状态 |
| 1001860062 | 不允许退款 | 游戏场景不展示退款入口 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.IAPKit": ">=4.0.0(10)",
    "@kit.AbilityKit": ">=4.0.0(10)",
    "@kit.BasicServicesKit": ">=4.0.0(10)"
  }
}
```

### 环境要求
- HarmonyOS API版本: >=4.0.0(10)
- 开发工具: DevEco Studio >=3.1
- 应用模型: Stage模型(仅支持)
- 设备支持: Phone/Tablet/PC/2in1(全部), Wearable(>=5.1.0(18)), TV(>=5.1.1(19)), Car(>=26.0.0)

### 常见编译问题

**问题1: 导入IAPKit模块失败**
```
Module '@kit.IAPKit' not found
```
**解决方法**: 确保项目API版本>=4.0.0(10),在build-profile.json5中配置正确的compileSdkVersion

**问题2: UIAbilityContext类型错误**
```
Type 'Context' is missing the following properties from type 'UIAbilityContext'
```
**解决方法**: 使用`this.getUIContext().getHostContext() as common.UIAbilityContext`获取正确的上下文

**问题3: JWS验签失败**
```
Invalid JWT signature
```
**解决方法**: 使用正确的公钥验签,参考[JWS验签文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-verifying-signature)

**问题4: 商品查询返回空列表**
```
Product list is empty
```
**解决方法**: 确认商品在AppGallery Connect已创建并审核通过,检查商品ID和类型匹配

## 常见问题与解决方法

### Q1: 购买成功但未收到购买结果
**原因**: 可能购买了但回调失败或网络异常
**解决方法**:
- 使用queryPurchases查询已购未发货商品
- 通过应用服务器接收关键事件通知
- 记录purchaseToken用于后续查询

### Q2: 消耗型商品无法再次购买
**原因**: 未调用finishPurchase完成购买流程
**解决方法**:
- 确认权益发放成功后立即调用finishPurchase
- 检查finishPurchase参数purchaseToken和purchaseOrderId是否正确
- 通过queryPurchases确认发货状态

### Q3: 非消耗型商品提示已购买
**原因**: 非消耗型商品购买后永久拥有
**解决方法**:
- 非消耗型商品无法重复购买是正常行为
- 可通过queryPurchases查询用户拥有的非消耗型商品
- 在购买前检查用户是否已拥有该商品

### Q4: 沙盒测试提示账号不是测试账号
**原因**: 未在AppGallery Connect配置测试账号
**解决方法**:
- 在AppGallery Connect的"用户与访问"添加测试账号
- 使用debug签名的应用进行测试
- 参考[沙盒测试文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-sandbox)

### Q5: 验签失败导致无法发放权益
**原因**: JWS签名验证失败或公钥不正确
**解决方法**:
- 使用IAP提供的公钥进行验签
- 参考解码验签文档正确处理JWS格式
- 验签失败时拒绝发放权益并记录异常

### Q6: 如何处理优惠促销
**原因**: 需要配置自定义人群促销
**解决方法**:
- 在AppGallery Connect配置商品的优惠促销
- 通过queryProducts查询商品的优惠信息
- 购买时传入优惠相关参数(需服务器签名)
- 参考[优惠促销文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-config-product)

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "productId": "product001",
  "purchaseOrderId": "order123456",
  "purchaseToken": "token789",
  "productType": "CONSUMABLE",
  "price": 100,
  "currency": "CNY",
  "purchaseTime": 1234567890,
  "delivered": true,
  "finished": true,
  "apiUsed": [
    "iap.queryEnvironmentStatus",
    "iap.queryProducts",
    "iap.createPurchase",
    "iap.finishPurchase"
  ]
}
```

## 参考文档

- [API开发指南](references/iap-integrate-purchase-guide.md)
- [IAP ArkTS API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)
- [IAP数据模型参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-data-model)
- [IAP错误码参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-error-code)
- [JWS验签说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-verifying-signature)
- [配置商品信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-config-product)
- [配置应用身份信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-config-app-identity-info)
- [沙盒测试](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-sandbox)
- [权益发放](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-delivering-products)
- [服务端关键事件通知](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-key-event-notifications)

## 完整示例代码

- [ArkTS完整示例](assets/iap_purchase_example.ets)
- [JWS验签工具类](assets/JWSUtil.ts)
- [配置文件示例](assets/iap_config.json)

## 测试用例

### 正向测试用例
- [成功购买消耗型商品](tests/test_purchase_consumable_success.ts): 正常流程购买消耗型商品并完成发货
- [成功购买非消耗型商品](tests/test_purchase_nonconsumable_success.ts): 正常流程购买非消耗型商品
- [批量购买消耗型商品](tests/test_purchase_multiple_consumable.ts): 使用quantity参数购买多个消耗型商品

### 边界测试用例
- [查询最大商品数量](tests/test_query_max_products.ts): 测试查询200个商品上限
- [购买最大数量商品](tests/test_purchase_max_quantity.ts): 测试quantity=10的上限
- [重复购买非消耗型商品](tests/test_purchase_nonconsumable_duplicate.ts): 测试已购买商品的处理

### 异常测试用例
- [用户取消购买](tests/test_purchase_user_canceled.ts): 测试用户取消购买流程
- [网络异常处理](tests/test_purchase_network_error.ts): 测试网络异常的降级处理
- [验签失败处理](tests/test_purchase_signature_invalid.ts): 测试JWS验签失败的拒绝处理
- [服务地不支持](tests/test_purchase_region_not_supported.ts): 测试账号服务地不支持IAP的情况
- [商品未审核](tests/test_product_not_approved.ts): 测试商品未审核通过的处理