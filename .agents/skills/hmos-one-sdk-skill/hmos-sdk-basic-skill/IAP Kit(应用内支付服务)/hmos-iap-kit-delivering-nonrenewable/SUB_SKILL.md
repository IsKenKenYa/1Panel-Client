---
name: hmos-iap-kit-delivering-nonrenewable
description: 查询并发放非续期订阅商品的权益，处理掉单场景，确保用户权益及时发放，适用于应用启动时或购买异常时的权益补发
---

# 非续期订阅商品权益发放技能

## 功能描述

本技能提供非续期订阅商品权益发放和掉单处理能力。在用户购买商品后，因网络错误、进程中止等异常导致应用无法及时发放权益时，通过查询已购未发货商品并补发权益，确保用户权益不丢失。支持在应用启动时或购买请求返回特定错误码时自动检查并处理。

主要功能：
- 查询已购未发货的非续期订阅商品
- JWS数据解码验签获取订单信息
- 验证订单状态并发放权益
- 确认发货完成购买流程
- 支持批量购买商品的数量校验

## 使用场景

### 触发词
- "非续期订阅商品权益发放"
- "掉单处理"
- "补发权益"
- "查询未发货订单"
- "IAP发货确认"

### 能做
- 在应用启动时查询用户已购未发货的非续期订阅商品
- 当createPurchase返回PRODUCT_OWNED或SYSTEM_ERROR错误码时查询并补发权益
- 对JWS格式的订单数据进行解码验签
- 检查订单撤销原因并判断是否需要发放权益
- 校验批量购买的商品数量避免漏发多发
- 发货成功后调用finishPurchase确认发货完成购买

### 绝不做
- 不处理消耗型商品的权益发放（请使用消耗型商品技能）
- 不处理非消耗型商品的权益发放（请使用非消耗型商品技能）
- 不处理自动续期订阅商品的权益发放（请使用自动续期订阅商品技能）
- 不在发货失败时调用finishPurchase（必须确保发货成功）
- 不跳过JWS验签步骤直接处理订单数据

### 补充
- 需要在应用客户端和服务器配合完成权益发放流程
- 应用服务器负责JWS验签和权益发放状态管理
- 建议使用应用服务器REST API完成发货确认，避免客户端处理延迟
- 对于支持批量购买的商品，必须校验quantity字段避免数量不一致

## 调用规范和规则

### 输入约束
- productType：必须为NONRENEWABLE（非续期订阅商品）
- queryType：建议使用UNFINISHED查询未发货订单
- JWS数据：必须包含完整的jwsPurchaseOrder字段
- purchaseToken：从PurchaseOrderPayload中获取，最大长度128位
- purchaseOrderId：从PurchaseOrderPayload中获取，最大长度256

### 执行约束
- 最大查询耗时：5秒
- JWS验签必须在应用服务器执行
- 发货确认必须在权益发放成功后执行
- 批量购买数量校验必须在发货前完成
- 接口调用间隔：建议大于5秒，避免触发频率限制

### 内容约束
- 禁止跳过JWS验签直接处理订单数据
- 禁止在未验证purchaseOrderRevocationReasonCode的情况下发放权益
- 禁止忽略quantity字段导致数量不一致
- 禁止在发货失败时调用finishPurchase
- 禁止使用高危函数处理支付数据（如eval、exec等）

### 降级约束
- 查询失败：提示用户稍后重试或引导用户查看订单详情
- JWS验签失败：记录错误日志并拒绝发放权益，通知用户联系客服
- 网络异常：延迟5秒后重试，最多重试3次
- 权益发放失败：不调用finishPurchase，保留订单状态供后续处理
- 发货确认失败：记录失败原因，提供手动发货入口

## 调用流程和步骤

### 步骤1：查询未发货订单

**前置校验**：
1. 用户已登录华为账号
2. 应用已开启IAP服务权限
3. 确认商品类型为非续期订阅商品（NONRENEWABLE）

**参数准备**：
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';

const param: iap.QueryPurchasesParameter = {
  productType: iap.ProductType.NONRENEWABLE,
  queryType: iap.PurchaseQueryType.UNFINISHED
};
```

**调用API**：
```typescript
async function queryUnfinishedPurchases(context: common.UIAbilityContext): Promise<iap.QueryPurchaseResult> {
  try {
    const result: iap.QueryPurchaseResult = await iap.queryPurchases(context, param);
    console.info('Succeeded in querying purchases.');
    
    if (result.purchaseDataList === undefined || result.purchaseDataList.length <= 0) {
      console.info('No unfinished purchases found.');
      return result;
    }
    
    return result;
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to query purchases. Code: ${err.code}, Message: ${err.message}`);
    throw error;
  }
}
```

### 步骤2：解码验签订单数据

**处理逻辑**：
1. 从purchaseDataList中提取每个purchaseData
2. 解析JSON获取jwsPurchaseOrder字段
3. 将jwsPurchaseOrder发送到应用服务器
4. 应用服务器执行JWS解码验签

**示例代码**：
```typescript
import { JWSUtil } from '../common/JWSUtil';

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: number;
  productId: string;
  quantity?: number;
  purchaseOrderRevocationReasonCode?: string;
  purchaseTime: number;
  price: number;
  currency: string;
}

async function decodeAndVerifyPurchaseData(purchaseDataList: string[]): Promise<PurchaseOrderPayload[]> {
  const orderPayloadList: PurchaseOrderPayload[] = [];
  
  for (let i = 0; i < purchaseDataList.length; i++) {
    try {
      const purchaseDataObj = JSON.parse(purchaseDataList[i]);
      const jwsPurchaseOrder: string = purchaseDataObj.jwsPurchaseOrder;
      
      if (!jwsPurchaseOrder) {
        console.warn(`Missing jwsPurchaseOrder in purchaseData[${i}]`);
        continue;
      }
      
      const decodedStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
      const orderPayload: PurchaseOrderPayload = JSON.parse(decodedStr);
      
      orderPayloadList.push(orderPayload);
      console.info(`Successfully decoded order: ${orderPayload.purchaseOrderId}`);
    } catch (error) {
      console.error(`Failed to decode purchaseData[${i}]:`, error);
    }
  }
  
  return orderPayloadList;
}
```

**注意**：JWSUtil为自定义类，参考示例代码实现。建议在应用服务器执行验签操作。

### 步骤3：验证订单状态并发放权益

**验证条件**：
1. 检查purchaseOrderRevocationReasonCode是否为空（为空表示购买成功）
2. 检查订单是否已发放权益（查询应用服务器发货状态）
3. 校验quantity字段（批量购买场景）

**权益发放示例**：
```typescript
async function deliverRights(orderPayload: PurchaseOrderPayload): Promise<boolean> {
  if (orderPayload.purchaseOrderRevocationReasonCode) {
    console.warn(`Order revoked: ${orderPayload.purchaseOrderId}, Reason: ${orderPayload.purchaseOrderRevocationReasonCode}`);
    return false;
  }
  
  const deliveryStatus = await queryDeliveryStatus(orderPayload.purchaseOrderId);
  if (deliveryStatus === 'delivered') {
    console.info(`Order already delivered: ${orderPayload.purchaseOrderId}`);
    return false;
  }
  
  if (orderPayload.quantity && orderPayload.quantity > 1) {
    console.info(`Batch purchase detected. Quantity: ${orderPayload.quantity}`);
  }
  
  try {
    await deliverRightsToUser(orderPayload);
    await recordDeliveryStatus(orderPayload);
    console.info(`Successfully delivered rights for order: ${orderPayload.purchaseOrderId}`);
    return true;
  } catch (error) {
    console.error(`Failed to deliver rights for order: ${orderPayload.purchaseOrderId}`, error);
    return false;
  }
}
```

### 步骤4：确认发货完成购买

**参数准备**：
```typescript
const finishPurchaseParam: iap.FinishPurchaseParameter = {
  productType: Number(orderPayload.productType),
  purchaseToken: orderPayload.purchaseToken,
  purchaseOrderId: orderPayload.purchaseOrderId
};
```

**调用API**：
```typescript
async function confirmDelivery(context: common.UIAbilityContext, orderPayload: PurchaseOrderPayload): Promise<void> {
  const finishPurchaseParam: iap.FinishPurchaseParameter = {
    productType: Number(orderPayload.productType),
    purchaseToken: orderPayload.purchaseToken,
    purchaseOrderId: orderPayload.purchaseOrderId
  };
  
  try {
    await iap.finishPurchase(context, finishPurchaseParam);
    console.info('Succeeded in finishing purchase.');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to finish purchase. Code: ${err.code}, Message: ${err.message}`);
    throw error;
  }
}
```

**重要提示**：
- 必须在权益发放成功后才调用finishPurchase
- 调用成功后，IAP服务器会将商品标记为已发货状态
- 对于非续期订阅商品，不执行此步骤会导致用户无法再次购买该商品

### 步骤5：完整流程示例

```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { JWSUtil } from '../common/JWSUtil';

@Entry
@Component
struct Index {
  async handleUnfinishedPurchases(context: common.UIAbilityContext): Promise<void> {
    try {
      const queryParam: iap.QueryPurchasesParameter = {
        productType: iap.ProductType.NONRENEWABLE,
        queryType: iap.PurchaseQueryType.UNFINISHED
      };
      
      const queryResult = await iap.queryPurchases(context, queryParam);
      console.info('Succeeded in querying purchases.');
      
      const purchaseDataList = queryResult.purchaseDataList;
      if (!purchaseDataList || purchaseDataList.length <= 0) {
        return;
      }
      
      for (let i = 0; i < purchaseDataList.length; i++) {
        const purchaseDataObj = JSON.parse(purchaseDataList[i]);
        const jwsPurchaseOrder = purchaseDataObj.jwsPurchaseOrder;
        
        if (!jwsPurchaseOrder) {
          continue;
        }
        
        const decodedStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
        const orderPayload = JSON.parse(decodedStr) as PurchaseOrderPayload;
        
        if (!orderPayload.purchaseOrderRevocationReasonCode) {
          const delivered = await this.deliverRights(orderPayload);
          
          if (delivered) {
            await this.confirmDelivery(context, orderPayload);
          }
        }
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to handle unfinished purchases. Code: ${error.code}, Message: ${error.message}`);
    }
  }
  
  async deliverRights(orderPayload: PurchaseOrderPayload): Promise<boolean> {
    return true;
  }
  
  async confirmDelivery(context: common.UIAbilityContext, orderPayload: PurchaseOrderPayload): Promise<void> {
    const finishParam: iap.FinishPurchaseParameter = {
      productType: Number(orderPayload.productType),
      purchaseToken: orderPayload.purchaseToken,
      purchaseOrderId: orderPayload.purchaseOrderId
    };
    
    await iap.finishPurchase(context, finishParam);
    console.info('Succeeded in finishing purchase.');
  }
  
  build() {}
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001860000 | 用户取消当前操作 | 向用户提示操作取消，无需补发权益 |
| 1001860001 | 系统内部错误 | 调用queryPurchases查询是否有未发货订单，及时发放权益 |
| 1001860002 | 应用未被授权访问接口 | 检查应用签名配置和IAP服务开关状态 |
| 1001860003 | 无效的商品信息 | 检查商品ID是否在AppGallery Connect配置并审核通过 |
| 1001860004 | 接口访问过频 | 控制调用频率，间隔至少5秒 |
| 1001860005 | 网络连接异常 | 提示用户检查网络，延迟后重试 |
| 1001860050 | 未登录华为账号 | 引导用户登录华为账号 |
| 1001860051 | 已拥有该商品 | 调用queryPurchases确认是否有未发货订单，发货后调用finishPurchase |
| 1001860052 | 未拥有该商品 | 查询用户是否购买了该商品 |
| 1001860053 | 已完成发货 | 查询订单发货状态，避免重复发货 |
| 1001860054 | 用户账号服务地不支持IAP | 提示用户当前地区不支持IAP服务 |
| 1001860056 | 用户交易被拒绝 | 建议稍后重试或更换支付方式 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.IAPKit": "系统Kit，无需额外安装",
    "@kit.AbilityKit": "系统Kit，无需额外安装",
    "@kit.BasicServicesKit": "系统Kit，无需额外安装"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低版本4.1.0(11)
- Stage模型：必须使用Stage模型开发
- 权限配置：需要配置IAP服务权限
- 设备支持：Phone、PC/2in1、Tablet设备

### 常见编译问题

**问题1：导入IAPKit失败**
```
Error: Cannot find module '@kit.IAPKit'
```
**解决方法**：确保HarmonyOS SDK版本≥4.1.0(11)，检查项目配置文件中是否正确引用系统Kit

**问题2：JWSUtil类未定义**
```
Error: Cannot find name 'JWSUtil'
```
**解决方法**：参考示例代码自定义JWSUtil类，或使用应用服务器REST API进行验签

**问题3：类型定义错误**
```
Error: Property 'purchaseDataList' does not exist on type 'QueryPurchaseResult'
```
**解决方法**：检查API版本，确保使用QueryPurchaseResult而非废弃的QueryPurchasesResult

**问题4：参数类型不匹配**
```
Error: Type 'string' is not assignable to type 'number'
```
**解决方法**：使用Number()转换productType，确保参数类型正确

## 常见问题与解决方法

### Q1：应用启动时如何自动检查未发货订单？
**原因**：需要在UIAbility的onCreate或onForeground生命周期中调用
**解决方法**：
- 在UIAbility.onCreate中调用queryPurchases检查未发货订单
- 使用async/await处理异步调用
- 避免阻塞UI线程，建议使用后台任务处理

### Q2：如何处理批量购买的商品数量不一致？
**原因**：quantity字段表示购买数量，发货数量必须匹配
**解决方法**：
- 发货前校验quantity字段
- 记录订单的quantity值
- 确保发货数量与购买数量一致
- 避免漏发或多发权益

### Q3：JWS验签失败如何处理？
**原因**：签名密钥不匹配或数据损坏
**解决方法**：
- 检验签密钥配置是否正确
- 使用应用服务器REST API验签
- 记录验签失败日志供排查
- 拒绝发放权益并通知用户

### Q4：发货确认失败会导致什么问题？
**原因**：未调用finishPurchase或调用失败
**解决方法**：
- 用户无法再次购买该商品
- 订单状态保留为未发货
- 需要手动重试finishPurchase
- 可使用应用服务器REST API确认发货

### Q5：如何避免重复发放权益？
**原因**：未检查订单的发货状态
**解决方法**：
- 发货前查询应用服务器发货记录
- 使用purchaseOrderId唯一标识订单
- 记录发货成功状态
- 发货前验证finishStatus字段

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "processedOrders": 3,
  "deliveredOrders": 2,
  "skippedOrders": 1,
  "failedOrders": 0,
  "apiUsed": [
    "iap.queryPurchases",
    "iap.finishPurchase"
  ],
  "details": [
    {
      "purchaseOrderId": "order123",
      "productId": "product001",
      "deliveryStatus": "delivered",
      "finishStatus": "completed"
    }
  ]
}
```

## 参考文档

- [权益发放开发指南](references/iap-delivering-nonrenewable.md)
- [IAP API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)
- [数据类型说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-data-model)
- [错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-error-code)
- [JWS验签说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-verifying-signature)
- [订单确认发货REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-confirm-purchase-for-order)

## 完整示例代码

- [ArkTS示例代码](assets/deliver_nonrenewable_rights.ets)
- [JWSUtil工具类](assets/JWSUtil.ts)
- [PurchaseOrderPayload定义](assets/PurchaseOrderPayload.ts)

## 测试用例

### 正向测试用例
- [测试正常购买流程](tests/test_positive.py)：购买成功后发放权益并确认发货
- [测试应用启动检查](tests/test_app_start.py)：应用启动时查询并补发权益
- [测试批量购买](tests/test_batch_purchase.py)：校验quantity字段正确处理

### 边界测试用例
- [测试已发货订单](tests/test_already_delivered.py)：跳过已发货订单避免重复
- [测试撤销订单](tests/test_revoked_order.py)：不发放已撤销订单权益
- [测试数量边界](tests/test_quantity_limit.py)：处理quantity=10的批量购买

### 异常测试用例
- [测试网络异常](tests/test_network_error.py)：网络异常时延迟重试
- [测试验签失败](tests/test_signature_failed.py)：验签失败时拒绝发放权益
- [测试发货失败](tests/test_delivery_failed.py)：发货失败时不调用finishPurchase
- [测试权限不足](tests/test_permission_denied.py)：应用未授权时的处理逻辑