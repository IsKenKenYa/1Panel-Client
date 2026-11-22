# 接入自动续期订阅
---
# 接入自动续期订阅
#### 约束与限制
自动续期订阅能力支持Phone、Tablet、PC/2in1设备，并且从5.1.1(19）版本开始，新增支持TV设备，从26.0.0版本开始，新增支持Car设备。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/51/v3/73lViYK0R9-LjQ8IcipsHw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=5243A95892894F4EB28D7F6C4F2FEFA044EEC5948857E4C9F74DDBE5F3C53195)
如下业务流程对于单机应用同样适用。在单机应用中，应用服务器和应用客户端的交互放在应用客户端完成，应用服务器和IAP服务器交互的部分可不处理。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4d/v3/MIIrMt29Sue3GtWoATFfEw/zh-cn_image_0000002628861604.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=58C678C2E12F73EB41D7E3D1E110B198E288D7EB37FBBD896D37E4CDE0C4FDDB)
**展示商品**
1.
应用客户端向IAP Kit发起 [queryEnvironmentStatus](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，检查当前用户登录的华为账号所在的服务地是否在IAP Kit支持结算的国家/地区中。
如果接口返回错误码“ [1001860054](D:/code/APIDevice/output/md_output/harmonyos-references/errorcode-iap.md) ：用户账号所在服务地不在IAP Kit支持结算的国家/地区中”，应用需隐藏相关IAP功能入口。
2.
应用客户端向IAP Kit发起 [queryProducts](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求来获取在 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 上配置的商品信息。
3.
应用客户端根据返回的商品信息展示可供购买的商品列表，包含商品名称、价格等信息。
**检查权益发放状态**
1.
应用客户端向IAP Kit发起 [queryPurchases](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，获取当前生效中的订阅列表。IAP Kit返回 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 列表。 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 为JWS格式的字符串，承载了相关的订阅信息。
2.
应用客户端展示商品的订阅状态，需要屏蔽处于自动续期状态的商品的购买入口。同时处理商品的权益发放。
3.
若商品未确认发货，需要在权益发放后，向IAP Kit发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，以此通知IAP服务器更新商品的发货状态，完成购买流程。应用成功执行 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 之后，IAP服务器会将相应商品标记为已发货状态。
此步骤也可放到应用服务器处理。应用服务器可通过请求服务端 [订阅确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-sub.md) 接口来确认发货，完成购买流程。
具体请参见 [对生效中的订阅发放权益](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/商品购买/自动续期订阅商品购买/权益发放/iap-delivering-subscriptions.md) 。
**购买及结果确认**
1.
用户发起购买后，应用客户端向IAP Kit发起 [createPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 购买请求或通过 [IAP嵌入式收银台组件](D:/code/APIDevice/output/md_output/harmonyos-references/iap-cashier-component.md) 发起购买请求（只支持TV），请求中携带商品ID、商品类型等信息。IAP Kit创建订单并展示收银台。
2.
购买结果确认。如购买成功，可通过应用客户端或应用服务器接收购买结果，建议通过应用服务器接收购买结果。
**方式一：通过客户端接收购买结果**
1. 用户购买成功时，IAP Kit返回包含订阅状态信息的[PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md)数据。
2. 应用客户端向应用服务器上报[PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md)数据。
3. 应用服务器对[PurchaseData.jwsSubscriptionStatus](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md)进行[解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md)，成功后可得到[SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md)的JSON字符串。
**（建议）方式二：通过服务器接收购买结果**
1.
为了提高安全性，开发者可以接入 [服务端关键事件通知](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-key-event-notifications.md) ，在用户购买成功时，IAP服务器将发送订单关键事件通知。
2.
应用服务器可从NotificationPayload. [NotificationMetaData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-key-event-notifications.md) 中解析出purchaseToken和purchaseOrderId信息，并通过服务端 [订阅状态查询](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-query-subscription-status.md) 接口向IAP服务器查询最新的订阅状态信息，进一步确认订阅信息的准确性。
3.
IAP服务器返回订阅组相关订阅状态数据 [jwsSubGroupStatus](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-query-subscription-status.md) 。
4.
应用服务器对 [jwsSubGroupStatus](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-query-subscription-status.md) 进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，成功后可得到 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4a/v3/gM_KMt3cTQefelIOV7xV0g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=B5AF6246A498AEA4F7171CCE60E10060C32353AB41D09EAE96273630F4CC9968)
如果购买失败，请参见 [确保权益发放](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/商品购买/自动续期订阅商品购买/权益发放/iap-delivering-subscriptions.md) 处理，及时发放权益。
**发放权益**
1.
确认购买成功后，需要处理权益发放。检查 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.lastPurchaseOrder是否已发放权益，未发放则需发放相关权益，并记录对应的订单信息（ [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ），用于后续检查权益发放状态。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/73/v3/E6nAxmQoT8CsDpzfTUjSag/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=C76FCB85B383E390BB3C5138F55CE719112965CE6D812DDC2D556C9914459C90)
建议单机应用将用户权益和订阅状态关联。如果订阅处于生效状态，始终为用户发放权益。
2.
应用客户端向应用服务器查询订单的发货状态。
3.
应用服务器返回对应的发货状态以及订单信息（ [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ）。
4.
发货成功后应用客户端向IAP Kit发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，以此通知IAP服务器更新商品的发货状态，完成购买流程。应用成功执行 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 之后，IAP服务器会将相应商品标记为已发货状态，后续该商品即可正常续期。
此步骤也可放到应用服务器处理。应用服务器可通过请求服务端 [订阅确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-sub.md) 接口来确认发货，完成购买流程。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/56/v3/6ZPXJw9UQWymMvBN2vMTpw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=C97F3F318815883AEE403DB08255A9343606A8987FE182B365ACDAA3C028152F)
对于自动续期订阅商品，如果不执行此步骤，会导致后续自动续期无法扣费，以及同一个订阅组不同自动续期订阅商品无法切换等问题。
#### 开发步骤
#### 展示商品
1.
检查应用引入IAP Kit的可用性。
在使用应用内支付之前，应用客户端需要向IAP Kit发送 [queryEnvironmentStatus](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，以此判断用户当前登录的华为账号所在的服务地是否在IAP Kit支持结算的国家/地区中。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e9/v3/sysZJmOjQ2-P3RXjDo4Inw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=6BFAE7E888CC1664C501F214FCF3C9259A2E0A88166970728DBE3A3E31676BB3)
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
应用客户端通过 [queryProducts](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 来获取在 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 上配置的商品信息。发起请求时，需在请求参数 [QueryProductsParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中携带相关的商品ID，并指定其productType为 [iap.ProductType.AUTORENEWABLE](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 。
当接口请求成功时，IAP Kit将返回商品信息 [Product](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 的列表。 应用可以使用 [Product](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 包含的商品价格、名称和描述等信息，向用户展示可供购买的商品列表。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/10/v3/iSKZ_7pxSGm_2XmXL79AdQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=3046169A5132D61C46A46DDBFB073B1FBB6CFFC097C6AFCE5E135A89720CFE86)
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
      productType: iap.ProductType.AUTORENEWABLE,
      // productIds中的商品需要替换成开发者在AppGallery Connect网站配置的商品
      productIds: ['product1', 'product2', 'product3']
    };
    iap.queryProducts(context, queryProductParam).then((result) => {
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
#### 展示订阅状态、发放权益
1.
应用获取用户当前生效中的订阅列表。
2.
应用客户端展示对应商品的订阅状态。此处需要屏蔽处于自动续期状态的商品的购买入口。
3.
处理生效中的订阅的权益发放。
具体可参见 [对生效中的订阅发放权益](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/商品购买/自动续期订阅商品购买/权益发放/iap-delivering-subscriptions.md) 。
#### 发起购买
用户发起购买时，应用可通过向IAP Kit发送 [createPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求来拉起IAP Kit收银台或通过 [IAP嵌入式收银台组件](D:/code/APIDevice/output/md_output/harmonyos-references/iap-cashier-component.md) 发起购买请求（只支持TV）。发起请求时，应用需在请求参数 [PurchaseParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中携带此前已在华为 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 网站上配置并生效的自动续期订阅的商品ID，并指定其productType为 [iap.ProductType.AUTORENEWABLE](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/38/v3/B0R81DITR-uu_CIcRrQ2kw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=92A7F26EF7517FD6014FE0CBFCF6DBEBD7712F40A2757B09FE94778E767373F5)
开发过程中易出现频繁调用接口的现象，建议控制接口调用频度，具体可参见 [1001860004 接口访问过频](D:/code/APIDevice/output/md_output/harmonyos-references/errorcode-iap.md) 。
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
@Entry
@Component
struct Index {
  subscribe(context: common.UIAbilityContext) {
    const createPurchaseParam: iap.PurchaseParameter = {
      productType: iap.ProductType.AUTORENEWABLE,
      // productId需要替换成开发者在AppGallery Connect网站配置商品信息时设置的“商品ID”
      productId: 'test001'
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
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/75/v3/lVQEPpbsTGK3dYPmvq-flQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=028EEF53A101D8011E944A41A362A94744FFC7BE45BEBDF28D0051022E5B7381)
1.
为了提高安全性，建议应用服务器接入 [服务端关键事件通知](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-key-event-notifications.md) 以接收购买成功结果并通过应用服务器来处理 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) 、完成购买等操作。
2.
请务必确保发货成功后再执行完成购买步骤，本步骤可通过请求服务端 [订阅确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-sub.md) 接口来确认发货，完成购买流程。
以下内容为 **通过客户端接收购买结果** 及处理的步骤说明。
1.
当用户购买成功时，应用将接收到一个 [CreatePurchaseResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 对象，其 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 字段包括了此次购买的结果信息。
2.
对 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .jwsSubscriptionStatus进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，验证成功可得到 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。建议应用客户端将 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 发送至应用服务器，在应用服务器执行此操作。
3.
验签成功后，检查 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.status是否为1（生效中），是则发放相关权益。
建议先检查此笔订单权益的发放状态，未发放则发放权益，成功后记录 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.lastPurchaseOrder等信息，用于后续检查权益发放状态。
4.
完成购买。
发放权益后，应用需发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求确认发货，以此通知IAP服务器更新商品的发货状态，完成购买流程。发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求时，需在请求参数 [FinishPurchaseParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中携带 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 中的productType、purchaseToken、purchaseOrderId，其中 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 为 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.lastPurchaseOrder。请求成功后，IAP服务器会将相应商品标记为已发货。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6f/v3/Z2AjvDvhSOONnK0Bs3FBOw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=9EF18276D455520F0C4EF61292B6932FFC01CD05EDD22AA21D391AFDB14CEFAF)
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
    const jwsSubscriptionStatus: string = JSON.parse(result.purchaseData).jwsSubscriptionStatus;
    if (!jwsSubscriptionStatus) {
      return;
    }
    const subscriptionStatus: string = JWSUtil.decodeJwsObj(jwsSubscriptionStatus);
    if (!subscriptionStatus) {
      return;
    }
    // 需自定义SubGroupStatusPayload类，包含的信息请参见SubGroupStatusPayload
    const subGroupStatusPayload: SubGroupStatusPayload = JSON.parse(subscriptionStatus);
    const lastSubscriptionStatus = subGroupStatusPayload.lastSubscriptionStatus;
    if (!lastSubscriptionStatus || lastSubscriptionStatus.status !== '1') {
      return;
    }
    const purchaseOrderPayload = lastSubscriptionStatus.lastPurchaseOrder;
    if (purchaseOrderPayload === undefined) {
      return;
    }
    // 处理发货
    // ...
    // 发货成功后向IAP Kit发送finishPurchase请求，确认发货，完成购买
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
当用户购买失败时，需要针对code为 [iap.IAPErrorCode.PRODUCT_OWNED](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 和 [iap.IAPErrorCode.SYSTEM_ERROR](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 的场景，检查是否需要补发货，确保权益发放，具体请参见 [确保权益发放](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/商品购买/自动续期订阅商品购买/权益发放/iap-delivering-subscriptions.md) 。
```typescript
import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
dealPurchaseError(err: BusinessError) {
  if (err.code === iap.IAPErrorCode.PRODUCT_OWNED || err.code === iap.IAPErrorCode.SYSTEM_ERROR) {
    // 参见确保权益发放检查是否需要补发货，确保权益发放
    // ...
  }
}
```