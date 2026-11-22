# 接入购买
---
# 接入购买
#### 场景介绍
在应用内购买场景中，用户会采用一次性付款的方式购买消耗型商品或非消耗型商品。请结合实际业务场景选择提供的商品类型。
在接入消耗型/非消耗型商品购买能力前，需要提前 [配置商品信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/开发准备/配置商品信息/iap-config-product.md) 。用户在应用内购买时，应用拉起IAP Kit的收银台，收银台处会展示商品名称、商品价格等信息，用户根据需求完成商品购买。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ba/v3/P_MhlE5QQUGFruvC8GnJ4Q/zh-cn_image_0000002659100951.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=B521F3A201CC20044A5D9B8D4BB2A0B11DB92332E5AC19090404E3846B494F9F)
#### 提供优惠
为了提供更有吸引力的消耗型/非消耗型商品购买，华为应用内支付支持开发者配置优惠促销（自定义人群促销）。
可以针对用户群体、优惠地域进行自定义选择，支持开发者进行个性化的优惠活动配置。开发者可以在发起购买前，查询该商品的优惠活动信息，在最终发起购买时，将优惠活动信息传递到华为应用内支付，最终将优惠活动信息展示给用户。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/3b/v3/YlFUId7lSbqvntkbVVM6Hw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=13CB00A1970882116C78B6F79ECF2FF499CBB1681397720C31FC7874698F3921)
-
当前优惠促销涉及 [生成优惠签名购买参数](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-server-subscribe-offer-sign.md) 处理，推荐具备服务器的开发者接入使用。
-
优惠促销无使用次数限制。
#### 约束与限制
消耗型/非消耗型商品购买能力支持Phone、Tablet、PC/2in1设备，并且从5.1.0（18）版本开始，新增支持Wearable设备。从5.1.1(19）版本开始，新增支持TV设备，从26.0.0版本开始，新增支持Car设备。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/58/v3/nay2R-dTQ4uW6fJQJQbOVg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=038816144ED7B02C9F16CF766FDC385604B393A353E3B2A31F97DEFEB20DCB54)
如下业务流程对于单机应用同样适用。在单机应用中，应用服务器和应用客户端的交互放在应用客户端完成，应用服务器和IAP服务器交互的部分可不处理。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/5d/v3/w-WvR5OoRnmr3c56F0JiGQ/zh-cn_image_0000002628861600.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=E5FC97763A29C88590E9AF4E437671B735D0A52FC040A75A2716B7479D8A5EE8)
**展示商品**
1.
应用客户端向IAP Kit发起 [queryEnvironmentStatus](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，检查当前用户登录的华为账号所在的服务地是否在IAP Kit支持结算的国家/地区中。
如果接口返回错误码“ [1001860054](D:/code/APIDevice/output/md_output/harmonyos-references/errorcode-iap.md) ：用户账号所在服务地不在IAP Kit支持结算的国家/地区中”，应用需隐藏相关IAP功能入口。
2.
应用客户端向IAP Kit发起 [queryProducts](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求来获取在 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 上配置的商品信息。
3.
应用客户端根据返回的商品信息展示可供购买的商品列表，包含商品名称、价格等信息。
**购买及结果确认**
1.
用户发起购买后，应用客户端向IAP Kit发起 [createPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 购买请求或通过 [IAP嵌入式收银台组件](D:/code/APIDevice/output/md_output/harmonyos-references/iap-cashier-component.md) 发起购买请求（只支持TV），请求中携带商品ID、商品类型等信息。IAP Kit创建订单并展示收银台。
2.
购买结果确认。如购买成功，可通过应用客户端或应用服务器接收购买结果，建议通过应用服务器接收购买结果。
**方式一：通过客户端接收购买结果**
1.
用户购买成功时，IAP Kit返回包含订单信息的 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 数据。
2.
应用客户端向应用服务器上报 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 数据。
3.
应用服务器需对 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .jwsPurchaseOrder进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，成功后可得到 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。
**（建议）方式二：通过服务器接收购买结果**
1.
为了提高安全性，开发者可以接入 [服务端关键事件通知](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-key-event-notifications.md) ，在用户购买成功时，IAP服务器将发送订单关键事件通知。
2.
应用服务器可从NotificationPayload. [NotificationMetaData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-key-event-notifications.md) 中解析出purchaseToken和purchaseOrderId信息，并通过服务端 [订单状态查询](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-query-order-status.md) 接口向IAP服务器查询最新的订单信息，进一步确认订单的准确性。
3.
IAP服务器返回订单信息 [jwsPurchaseOrder](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-query-order-status.md) 。
4.
应用服务器需对 [jwsPurchaseOrder](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-query-order-status.md) 进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，成功后可得到 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fd/v3/BL6tk7FVSke5PmcIeZBYoQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=E41A6BE666E5461EF9C6B86C1E0B6D9AE8C93CA75668CBB0EA5D832EA2BF39C4)
如果购买失败，请参见 [权益发放](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/商品购买/消耗型_非消耗型商品购买/权益发放/iap-delivering-products.md) 处理，及时发放权益。
**发放权益**
1.
确认购买成功后，需要处理权益发放。检查当前 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 是否已发放权益，未发放则发放相关权益，并记录对应的订单信息（ [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ），用于后续检查权益发放状态。
2.
应用客户端向应用服务器查询订单的发货状态。
3.
应用服务器返回对应的发货状态以及订单信息（ [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ）。
4.
发货成功后应用客户端向IAP Kit发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，以此通知IAP服务器更新商品的发货状态，完成购买流程。
应用成功执行此步骤后，IAP服务器会将相应商品标记为已发货状态。对于消耗型商品，IAP服务器会将相应商品重新设置为可购买状态，用户即可再次购买该商品。对于非消耗型商品，用户购买后永久拥有，无法再次购买该商品。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/04/v3/xe4tBSzwS--sX3XZ5p2pNA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=684F9E410486D9C07DF98BBE13555EC6744C2FEFCCAE9F6530177C8D22C5A6C1)
此步骤也可放到应用服务器处理。应用服务器可通过请求服务端 [订单确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-order.md) 接口来确认发货，完成购买流程。
确保在发货成功之后再执行此步骤，否则可能导致IAP服务器已经确认发货但是应用没有发货的问题。
#### 开发步骤
#### 展示商品
1.
检查应用引入IAP Kit的可用性。
在使用应用内支付之前，应用客户端需要向IAP Kit发送 [queryEnvironmentStatus](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，以此判断用户当前登录的华为账号所在的服务地是否在IAP Kit支持结算的国家/地区中。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/84/v3/wByvkqchTOm9C5qJiMT1SQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=8F3D802C795283505B9B1E0869E1345123FF342BDE2113A2E68BCBDF2C06E10F)
当前IAP Kit支持结算的国家/地区仅有中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）。
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
@Entry
@Component
struct Index {
  queryEnvironmentStatus(context: common.UIAbilityContext) {
    iap.queryEnvironmentStatus(context).then(() => {
      // 请求成功
      console.info('Succeeded in querying environment status.');
    }).catch((err: BusinessError) => {
      // 请求失败
      // 如果接口返回错误码“1001860054 用户账号所在服务地不在IAP Kit支持结算的国家/地区中”，应用需隐藏相关IAP功能入口
      console.error(`Failed to query environment status. Code is ${err.code}, message is ${err.message}`);
    });
  }
  build() {}
}
```
2.
展示商品列表。
应用客户端通过 [queryProducts](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 来获取在 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 上配置的商品信息。发起请求时，需在请求参数 [QueryProductsParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中携带相关的商品ID，并根据实际配置指定其商品类型productType。
当接口请求成功时，IAP Kit将返回商品信息 [Product](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 的列表。 应用可以使用 [Product](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 包含的商品价格、名称和描述等信息，向用户展示可供购买的商品列表。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/46/v3/GChbSUArSLCa0alliTBChQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=7C030DF52CBAC7A5D401E4563435862D76B65E3C48883BA2D788E7DEA37EE2B4)
[queryProducts](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 每次只能查询一种商品类型的商品，每次最多查询200个商品，否则请求将报错。
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
@Entry
@Component
struct Index {
  queryProducts(context: common.UIAbilityContext) {
    const queryProductParam: iap.QueryProductsParameter = {
      // iap.ProductType.CONSUMABLE：消耗型商品
      // iap.ProductType.NONCONSUMABLE：非消耗型商品
      productType: iap.ProductType.CONSUMABLE,
      // productIds中的商品需要替换成开发者在AppGallery Connect网站配置的商品
      productIds: ['ohos_consume_001']
    };
    iap.queryProducts(context, queryProductParam).then(() => {
      // 请求成功
      console.info('Succeeded in querying products.');
      // 展示商品信息
      // ...
    }).catch((err: BusinessError) => {
      // 请求失败
      console.error(`Failed to query products. Code is ${err.code}, message is ${err.message}`);
    });
  }
  build() {}
}
```
#### 发起购买
用户发起购买时，应用客户端向IAP Kit发送 [createPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求来拉起IAP Kit收银台或通过 [IAP嵌入式收银台组件](D:/code/APIDevice/output/md_output/harmonyos-references/iap-cashier-component.md) 发起购买请求（只支持TV）。发起请求时，需在请求参数 [PurchaseParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中携带此前已在华为 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 网站上配置并生效的商品ID，并根据实际配置指定其productType。
如需单次购买多个商品（仅消耗型商品），可在PurchaseParameter中拼接quantity参数，quantity取值范围1-10。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c0/v3/PDJpBEgPRraqGdIn-FwBcg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=0F80D774E26E88C7799B0245E60044AF733DEE835B3E7B5B0CDCE59538059AF0)
开发过程中易出现频繁调用接口的现象，建议控制接口调用频度，具体可参见 [1001860004 接口访问过频](D:/code/APIDevice/output/md_output/harmonyos-references/errorcode-iap.md) 。
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
@Entry
@Component
struct Index {
  createPurchase(context: common.UIAbilityContext) {
    const createPurchaseParam: iap.PurchaseParameter = {
      // iap.ProductType.CONSUMABLE：消耗型商品
      // iap.ProductType.NONCONSUMABLE：非消耗型商品
      productType: iap.ProductType.CONSUMABLE,
      // productId需要替换成开发者在AppGallery Connect网站配置商品信息时设置的“商品ID”
      productId: 'ohos_consume_001'
    };
    iap.createPurchase(context, createPurchaseParam).then((result) => {
      console.info('Succeeded in creating purchase.');
      // 购买成功，处理购买结果
      // dealPurchaseResult实现请参见下一步
      this.dealPurchaseResult(result);
    }).catch((err: BusinessError) => {
      // 购买失败
      console.error(`Failed to create purchase. Code is ${err.code}, message is ${err.message}`);
      // dealPurchaseError实现请参见下一步
      this.dealPurchaseError(err);
    })
  }
  build() {}
}
```
#### 购买结果处理
**【结果1：购买成功】**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ee/v3/7VPXsME4Rc2RhX_oEXrCxA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=4B18646143F793B0FD0EAFC58477C19ECF34FB4CF6D2BF5E5A099E5051051A04)
1.
为了提高安全性，建议应用服务器接入 [服务端关键事件通知](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-key-event-notifications.md) 以接收购买成功结果并通过应用服务器来处理 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) 、完成购买等操作。
2.
请务必确保发货成功后再执行完成购买步骤，本步骤可通过请求服务端 [订单确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-order.md) 接口来确认发货，完成购买流程。
以下内容为 **通过客户端接收购买结果** 及处理的步骤说明。
1.
当用户购买成功时，应用客户端将接收到一个 [CreatePurchaseResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 对象，其 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 字段包括了此次购买的结果信息。
2.
对 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .jwsPurchaseOrder进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，验证成功可得到 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。建议应用客户端将 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 发送至应用服务器，在应用服务器执行此操作。
3.
验签成功后，如果 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .purchaseOrderRevocationReasonCode为空，则代表购买成功，即可发放相关权益。
建议先检查此笔订单权益的发放状态，未发放则发放权益，成功后记录 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 等信息，用于后续检查权益发放状态。
4.
完成购买。
发放权益后，应用客户端需要发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求确认发货，以此通知IAP服务器更新商品的发货状态，完成购买流程。发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求时，需在请求参数 [FinishPurchaseParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中携带 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 中的productType、purchaseToken、purchaseOrderId。
应用成功执行此步骤后，IAP服务器会将相应商品标记为已发货状态。对于消耗型商品，IAP服务器会将相应商品重新设置为可购买状态，用户即可再次购买该商品。对于非消耗型商品，用户购买后永久拥有，无法再次购买该商品。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/06/v3/2wfOFZUESoyVg6cXMZuBtQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=4ADCC8B61F5222D29DAF87828AFCF4C75B11C4AA3D3695E8038A0C5BC4780241)
JWSUtil为自定义类，可参见 [示例代码](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/使用入门/iap-dev-guide.md) 。
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
// JWSUtil为自定义类
import { JWSUtil } from '../common/JWSUtil';
@Entry
@Component
struct Index {
  /**
   * 购买结果处理
   *
   * @param result 商品购买结果
   */
  dealPurchaseResult(context: common.UIAbilityContext, result: iap.CreatePurchaseResult) {
    const jwsPurchaseOrder: string = JSON.parse(result.purchaseData).jwsPurchaseOrder;
    if (!jwsPurchaseOrder) {
      return;
    }
    // 对jwsPurchaseOrder进行解码验签
    const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
    // 需自定义PurchaseOrderPayload类，包含的信息请参见PurchaseOrderPayload
    const purchaseOrderPayload = JSON.parse(purchaseStr) as PurchaseOrderPayload;
    // 处理发货
    // ...
    // 发货成功后向IAP Kit发送finishPurchase请求，确认发货，完成购买
    // finishPurchase请求的参数来源于purchaseOrderPayload
    this.finishPurchase(context, purchaseOrderPayload);
  }
  /**
   * 确认发货，完成购买
   *
   * @param purchaseOrder 订单信息，来源于购买请求
   */
  finishPurchase(context: common.UIAbilityContext, purchaseOrder: PurchaseOrderPayload) {
    const finishPurchaseParam: iap.FinishPurchaseParameter = {
      productType: Number(purchaseOrder.productType),
      purchaseToken: purchaseOrder.purchaseToken,
      purchaseOrderId: purchaseOrder.purchaseOrderId
    };
    iap.finishPurchase(context, finishPurchaseParam).then(() => {
      // 请求成功
      console.info('Succeeded in finishing purchase.');
    }).catch((err: BusinessError) => {
      // 请求失败
      console.error(`Failed to finish purchase. Code is ${err.code}, message is ${err.message}`);
    });
  }
  build() {}
}
```
**【结果2：购买失败】**
当用户购买失败时，需要针对code为 [iap.IAPErrorCode.PRODUCT_OWNED](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 和 [iap.IAPErrorCode.SYSTEM_ERROR](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 的场景，检查是否需要补发货，确保权益发放，具体请参见 [权益发放](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/商品购买/消耗型_非消耗型商品购买/权益发放/iap-delivering-products.md) 。
```typescript
import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
dealPurchaseError(err: BusinessError) {
  if (err.code === iap.IAPErrorCode.PRODUCT_OWNED || err.code === iap.IAPErrorCode.SYSTEM_ERROR) {
    // 参见权益发放检查是否需要补发货，确保权益发放
    // ...
  }
}
```