---
name: hmos-iap-kit-nonrenewable-purchase
description: 实现非续期订阅商品购买流程，支持环境检查、商品查询、购买发起、结果处理和发货确认，适用于订阅类增值功能访问场景，支持Phone/Tablet/PC/2in1/TV/Car设备，API版本5.0.2(14)+
---

# 非续期订阅商品购买技能

## 功能描述

本技能提供HarmonyOS IAP Kit非续期订阅商品的完整购买流程实现能力，包括：
- 环境状态检查：验证用户账号服务地是否支持IAP结算
- 商品信息查询：获取AppGallery Connect配置的非续期订阅商品详情
- 购买流程发起：拉起IAP收银台完成商品购买
- 购买结果处理：解码验签购买数据，发放权益
- 发货确认流程：通知IAP服务器更新发货状态，完成购买

非续期订阅商品特点：用户购买后可在一段时间访问App增值功能，周期结束后需再次购买续期。

## 使用场景

### 触发词
- "非续期订阅购买"
- "订阅商品购买"
- "IAP购买"
- "应用内支付"
- "购买订阅"

### 能做
- 检查用户账号所在服务地是否支持IAP结算
- 查询已配置的非续期订阅商品信息并展示
- 发起非续期订阅商品购买请求
- 处理购买成功/失败结果
- 解码验签购买数据并发放权益
- 确认发货完成购买流程
- 处理购买失败时的补发货场景

### 绝不做
- 不处理消耗型商品购买（使用消耗型商品购买技能）
- 不处理非消耗型商品购买（使用非消耗型商品购买技能）
- 不处理自动续期订阅商品购买（使用自动续期订阅技能）
- 不处理超出IAP支持范围的支付请求
- 不跳过验签步骤直接发放权益

### 补充
- 支持设备：Phone、Tablet、PC/2in1（4.0.0+）、TV（5.1.1(19)+）、Car（26.0.0+）
- 当前IAP仅支持中国境内（香港、澳门、台湾除外）
- 单次最多查询200个商品，建议分批查询
- 购买quantity参数支持1-10个商品批量购买（5.0.3(15)+）
- 建议通过应用服务器接收购买结果以提高安全性

## 调用规范和规则

### 输入约束
- 商品ID：必须在AppGallery Connect配置且生效，最多200个
- 商品类型：必须指定为ProductType.NONRENEWABLE（值3）
- Context类型：必须使用UIAbilityContext
- 购买数量：quantity取值范围1-10（可选）
- 开发者Payload：自定义参数，长度不限

### 执行约束
- 接口调用频次：避免频繁调用，防止1001860004错误
- 环境检查：必须先调用queryEnvironmentStatus检查支持性
- 验签要求：必须对jwsPurchaseOrder解码验签后发放权益
- 发货确认：必须在权益发放成功后调用finishPurchase
- 购买流程：必须按顺序执行（检查→查询→购买→处理→确认）

### 内容约束
- 禁止跳过环境检查直接购买
- 禁止跳过验签直接发放权益
- 禁止在发货前调用finishPurchase
- 禁止使用已废弃的purchase接口（使用createPurchase）
- 禁止忽略purchaseOrderRevocationReasonCode字段

### 降级约束
- 网络失败：提示用户检查网络连接，提供重试机制
- 环境不支持：隐藏IAP功能入口，提示用户服务地不支持
- 商品查询失败：展示缓存商品信息或提示稍后重试
- 购买失败：根据错误码判断是否需要补发货（PRODUCT_OWNED/SYSTEM_ERROR）
- 验签失败：拒绝发放权益，记录异常日志

## 调用流程和步骤

### 步骤1：准备阶段 - 环境检查

**前置校验**：
1. 检查用户是否登录华为账号
2. 检查应用是否已授权IAP权限
3. 检查设备API版本是否>=5.0.2(14)

**参数准备**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 获取UIAbilityContext
const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
```

**环境检查代码**：
```typescript
async function checkIAPEnvironment(context: common.UIAbilityContext): Promise<boolean> {
  try {
    await iap.queryEnvironmentStatus(context);
    console.info('IAP environment is supported.');
    return true;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to query environment status. Code: ${error.code}, Message: ${error.message}`);
    
    // 如果返回1001860054，说明用户账号所在服务地不支持IAP
    if (error.code === 1001860054) {
      console.warn('User account service region does not support IAP.');
      // 应用需隐藏相关IAP功能入口
    }
    return false;
  }
}
```

### 步骤2：查询商品信息

**查询商品列表**：
```typescript
async function queryNonrenewableProducts(
  context: common.UIAbilityContext,
  productIds: string[]
): Promise<Array<iap.Product>> {
  // 构造查询参数
  const queryProductParam: iap.QueryProductsParameter = {
    productType: iap.ProductType.NONRENEWABLE, // 非续期订阅商品
    productIds: productIds // 最多200个商品ID
  };

  try {
    const products = await iap.queryProducts(context, queryProductParam);
    console.info(`Succeeded in querying products. Count: ${products.length}`);
    
    // 展示商品信息：名称、价格、描述等
    products.forEach(product => {
      console.info(`Product: ${product.productId}, Name: ${product.productName}, Price: ${product.price}`);
    });
    
    return products;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to query products. Code: ${error.code}, Message: ${error.message}`);
    throw error;
  }
}
```

### 步骤3：发起购买请求

**购买示例代码**：
```typescript
async function purchaseNonrenewableProduct(
  context: common.UIAbilityContext,
  productId: string,
  quantity?: number // 可选，购买数量1-10
): Promise<iap.CreatePurchaseResult> {
  // 构造购买参数
  const purchaseParam: iap.PurchaseParameter = {
    productType: iap.ProductType.NONRENEWABLE,
    productId: productId, // 必须在AppGallery Connect配置
    developerPayload: 'custom_payload_string' // 可选
  };

  // 如果需要批量购买（5.0.3(15)+）
  if (quantity && quantity >= 1 && quantity <= 10) {
    purchaseParam.quantity = quantity;
  }

  try {
    const result = await iap.createPurchase(context, purchaseParam);
    console.info('Purchase succeeded.');
    return result;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Purchase failed. Code: ${error.code}, Message: ${error.message}`);
    throw error;
  }
}
```

### 步骤4：购买结果处理 - 成功场景

**解码验签并发放权益**：
```typescript
import { JWSUtil } from '../common/JWSUtil'; // 自定义JWS解码工具

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: number;
  productId: string;
  purchaseTime: number;
  price: number;
  currency: string;
  purchaseOrderRevocationReasonCode?: string;
  // ...其他字段见PurchaseOrderPayload定义
}

async function handlePurchaseSuccess(
  context: common.UIAbilityContext,
  result: iap.CreatePurchaseResult
): Promise<void> {
  // 1. 解析购买数据
  const purchaseData = JSON.parse(result.purchaseData);
  const jwsPurchaseOrder = purchaseData.jwsPurchaseOrder;

  if (!jwsPurchaseOrder) {
    console.error('No purchase order data found.');
    return;
  }

  // 2. 解码验签JWS数据（建议在应用服务器执行）
  const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
  const orderPayload: PurchaseOrderPayload = JSON.parse(purchaseStr);

  // 3. 检查订单撤销原因
  if (orderPayload.purchaseOrderRevocationReasonCode) {
    console.warn(`Purchase order revoked. Reason: ${orderPayload.purchaseOrderRevocationReasonCode}`);
    // 不发放权益
    return;
  }

  // 4. 发放权益（开发者自定义逻辑）
  try {
    await deliverEntitlement(orderPayload);
    console.info('Entitlement delivered successfully.');
    
    // 5. 发货成功后，确认完成购买
    await confirmPurchaseFinish(context, orderPayload);
  } catch (err) {
    console.error('Failed to deliver entitlement:', err);
    // 不调用finishPurchase，等待下次补发货
  }
}

// 发放权益示例（开发者实现）
async function deliverEntitlement(order: PurchaseOrderPayload): Promise<void> {
  // 检查是否已发放权益
  const isDelivered = await checkDeliverStatus(order.purchaseOrderId);
  if (isDelivered) {
    console.info('Entitlement already delivered.');
    return;
  }

  // 发放权益逻辑：解锁功能、延长访问时间等
  // 记录订单信息用于后续查询
  await saveDeliverRecord(order);
}

// 确认发货完成购买
async function confirmPurchaseFinish(
  context: common.UIAbilityContext,
  order: PurchaseOrderPayload
): Promise<void> {
  const finishParam: iap.FinishPurchaseParameter = {
    productType: order.productType,
    purchaseToken: order.purchaseToken,
    purchaseOrderId: order.purchaseOrderId
  };

  try {
    await iap.finishPurchase(context, finishParam);
    console.info('Purchase finished successfully.');
    // IAP服务器将商品标记为已发货，非续期订阅商品可再次购买
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to finish purchase. Code: ${error.code}, Message: ${error.message}`);
  }
}
```

### 步骤5：购买结果处理 - 失败场景

**错误处理和补发货检查**：
```typescript
async function handlePurchaseError(err: BusinessError): Promise<void> {
  console.error(`Purchase failed. Code: ${err.code}, Message: ${err.message}`);

  // 检查是否需要补发货
  if (err.code === iap.IAPErrorCode.PRODUCT_OWNED || err.code === iap.IAPErrorCode.SYSTEM_ERROR) {
    console.warn('Need to check and deliver entitlement.');
    // 参见权益发放流程检查是否需要补发货
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-delivering-nonrenewable
  }

  // 其他错误处理
  switch (err.code) {
    case 1001860000: // USER_CANCELED
      console.info('User canceled the purchase.');
      break;
    case 1001860004: // FREQUENT_CALLS
      console.warn('API calls too frequent. Please retry later.');
      break;
    case 1001860005: // NETWORK_ERROR
      console.error('Network error. Please check connection.');
      break;
    case 1001860054: // ACCOUNT_TERRITORY_NOT_SUPPORTED
      console.error('User account region does not support IAP.');
      break;
    default:
      console.error('Unknown error:', err.code);
  }
}
```

### 步骤6：完整流程集成示例

**完整购买流程**：
```typescript
@Entry
@Component
struct NonrenewablePurchasePage {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async purchaseFlow(productId: string): Promise<void> {
    try {
      // 步骤1：检查环境
      const envSupported = await checkIAPEnvironment(this.context);
      if (!envSupported) {
        console.error('IAP not supported in current region.');
        return;
      }

      // 步骤2：查询商品
      const products = await queryNonrenewableProducts(this.context, [productId]);
      if (products.length === 0) {
        console.error('Product not found.');
        return;
      }

      // 步骤3：发起购买
      const result = await purchaseNonrenewableProduct(this.context, productId);

      // 步骤4：处理购买成功
      await handlePurchaseSuccess(this.context, result);

    } catch (err) {
      const error = err as BusinessError;
      await handlePurchaseError(error);
    }
  }

  build() {
    Column() {
      Button('购买订阅')
        .onClick(() => {
          this.purchaseFlow('ohos_nonrenewable_001');
        })
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001860000 | 用户取消当前操作 | 正常流程，无需特殊处理 |
| 1001860001 | 通用系统错误 | 检查系统状态，稍后重试 |
| 1001860002 | 应用未被授权访问接口 | 检查应用IAP权限配置 |
| 1001860003 | 无效的商品信息 | 检查商品ID是否在AppGallery Connect配置 |
| 1001860004 | 接口访问过频 | 控制调用频次，建议间隔>100ms |
| 1001860005 | 网络连接异常 | 检查网络连接，提供重试机制 |
| 1001860007 | 商品所属应用未在指定地区上架 | 检查应用发布地区配置 |
| 1001860050 | 未登录华为账号 | 提示用户登录华为账号 |
| 1001860051 | 已拥有该商品 | 检查是否需要补发货 |
| 1001860052 | 未拥有该商品，发货失败 | 检查订单状态和购买流程 |
| 1001860053 | 购买已完成，无需重复发货 | 检查发货记录，避免重复操作 |
| 1001860054 | 用户账号所在服务地不支持IAP | 隐藏IAP功能入口 |
| 1001860056 | 用户交易被拒绝 | 检查用户支付权限 |
| 1001860059 | 无效的优惠信息 | 检查优惠ID和签名参数 |
| 1001860060 | 无效的签名信息 | 检查验签流程和签名数据 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.IAPKit": "5.0.2+",
    "@kit.AbilityKit": "4.0.0+",
    "@kit.BasicServicesKit": "4.0.0+"
  }
}
```

### 环境要求
- HarmonyOS API版本：>=5.0.2(14)
- Stage模型：本模块接口仅可在Stage模型下使用
- 设备支持：Phone/Tablet/PC/2in1/TV/Car（各设备起始版本不同）
- 元服务支持：从5.0.2(14)开始支持

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.IAPKit'
```
**解决方法**：确保HarmonyOS SDK版本>=5.0.2(14)，检查oh-package.json5依赖配置

**问题2：Context类型错误**
```
Error: Parameter error. Context type mismatch.
```
**解决方法**：使用UIAbilityContext而非其他Context类型

**问题3：商品类型参数错误**
```
Error: Invalid productType parameter.
```
**解决方法**：确保productType为iap.ProductType.NONRENEWABLE（值3）

**问题4：JWS解码失败**
```
Error: Failed to decode JWS object.
```
**解决方法**：检查JWSUtil实现，确保使用正确的公钥验签

## 常见问题与解决方法

### Q1：购买成功但未收到权益？
**原因**：发货流程中断，未调用finishPurchase或应用服务器未处理购买结果
**解决方法**：
- 检查应用服务器是否接收到购买通知
- 使用服务端关键事件通知接收购买结果
- 查询未发货订单并补发货
- 参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-delivering-nonrenewable

### Q2：用户购买后仍提示未拥有权益？
**原因**：购买数据验签失败或权益发放逻辑异常
**解决方法**：
- 检查jwsPurchaseOrder解码验签是否成功
- 检查purchaseOrderRevocationReasonCode字段是否为空
- 确认权益发放逻辑正确执行
- 查询购买记录确认订单状态

### Q3：用户取消购买但提示系统错误？
**原因**：错误码处理不当，混淆USER_CANCELED和SYSTEM_ERROR
**解决方法**：
- 正确区分错误码1001860000（用户取消）和1001860001（系统错误）
- 用户取消为正常流程，无需补发货
- 系统错误需检查是否需要补发货

### Q4：接口调用频繁报错？
**原因**：短时间内大量调用IAP接口触发频次限制
**解决方法**：
- 控制API调用频次，建议间隔>=100ms
- 实现调用队列和限流机制
- 批量查询时使用单次queryProducts请求（最多200个商品）

### Q5：商品查询返回空列表？
**原因**：商品未在AppGallery Connect配置或未生效
**解决方法**：
- 检查商品ID是否正确配置
- 确认商品状态为VALID（生效状态）
- 检查商品所属应用是否在当前地区上架
- 确认商品类型为非续期订阅商品

### Q6：如何处理批量购买场景？
**原因**：用户需一次购买多个订阅周期
**解决方法**：
- 使用quantity参数（5.0.3(15)+），取值范围1-10
- 发货时校验商品数量与订单数量一致
- 记录购买数量用于权益时长计算
- 注意：权益时长叠加需开发者自行管理

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "productId": "ohos_nonrenewable_001",
  "purchaseOrderId": "order_xxx",
  "purchaseToken": "token_xxx",
  "purchaseTime": 1704067200000,
  "price": 1000,
  "currency": "CNY",
  "quantity": 1,
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

- [API开发指南 - 接入购买](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-integrate-nonrenewable)
- [API开发指南 - 配置商品信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-config-product)
- [API开发指南 - 权益发放](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-delivering-nonrenewable)
- [API开发指南 - 使用入门](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-dev-guide)
- [API参考 - IAP模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)
- [API参考 - 数据模型](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-data-model)
- [API参考 - 错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-error-code)
- [API参考 - 解码验签](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-verifying-signature)
- [API参考 - 服务端关键事件通知](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-key-event-notifications)
- [API参考 - 订单状态查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-query-order-status)
- [API参考 - 订单确认发货](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-confirm-purchase-for-order)

## 完整示例代码

- [ArkTS完整示例](assets/nonrenewable_purchase_example.ets)
- [JWS解码工具示例](assets/jws_util_example.ts)
- [服务端验签示例](assets/server_verify_example.py)
- [配置文件示例](assets/iap_config.json)

## 测试用例

### 正向测试用例
- [环境检查成功场景](tests/test_environment_check.py)：验证queryEnvironmentStatus成功返回
- [商品查询成功场景](tests/test_query_products.py)：验证queryProducts返回商品列表
- [购买成功场景](tests/test_purchase_success.py)：验证完整购买流程成功
- [发货确认成功场景](tests/test_finish_purchase.py)：验证finishPurchase成功调用

### 边界测试用例
- [最大商品数量查询](tests/test_max_products_query.py)：测试查询200个商品
- [批量购买场景](tests/test_quantity_purchase.py)：测试quantity参数1-10范围
- [重复购买检查](tests/test_repeat_purchase.py)：测试已购买商品再次购买
- [设备兼容性测试](tests/test_device_compatibility.py)：测试不同设备类型支持

### 异常测试用例
- [网络异常处理](tests/test_network_error.py)：测试网络连接失败场景
- [环境不支持处理](tests/test_region_not_support.py)：测试1001860054错误码
- [商品无效处理](tests/test_invalid_product.py)：测试未配置商品购买
- [验签失败处理](tests/test_signature_failure.py)：测试JWS解码验签失败
- [用户取消处理](tests/test_user_cancel.py)：测试用户取消购买流程