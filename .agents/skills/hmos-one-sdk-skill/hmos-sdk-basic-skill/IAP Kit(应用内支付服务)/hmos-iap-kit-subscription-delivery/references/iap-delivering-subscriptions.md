# 权益发放
---
# 权益发放
#### 对生效中的订阅发放权益
#### 场景介绍
用户购买自动续期订阅商品后，若订阅处于生效状态，开发者需要及时给用户发放对应权益。
在应用启动时，获取用户当前处于生效状态的订阅列表，处理此部分订阅的权益发放。建议先检查当前订阅对应权益的发放状态，未发放再补充发放权益。在权益发放成功后，向IAP确认发货，完成购买。
建议单机应用将用户权益和订阅状态关联。如果订阅处于生效状态，始终为用户发放权益。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/2a/v3/NHWpJrR8Qlay2ldDpniTnA/zh-cn_image_0000002659220917.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=AABAE77890D6D36493E13649FCED05EB990226CAF009CC181616B76280D9A67C)
1.
应用客户端向IAP Kit发起 [queryPurchases](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，查询用户生效中的订阅列表。
2.
IAP Kit返回 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 列表。 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 为JWS格式的字符串，承载了相关的订阅信息。
3.
应用客户端向应用服务器上报 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 列表。
4.
应用服务器需对每个 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .jwsSubscriptionStatus进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，验证成功可得到对应的 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。
5.
处理权益发放。检查 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.lastPurchaseOrder是否已发放权益，未发放则需发放相关权益，并记录对应的订单信息（ [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ）。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/62/v3/Cq-LuCvWRiaa5sNzFYT1bw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=7A5A30D9F9DB82DC9E1236484FC5A084A6209230AE49353F3FDE1FD4051F82F4)
建议单机应用将用户权益和订阅状态关联。如果订阅处于生效状态，始终为用户发放权益。
6.
应用客户端向应用服务器查询订单的发货状态。
7.
应用服务器返回对应的发货状态以及订单信息（ [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ）。
8.
发放权益后应用客户端向IAP Kit发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，以此通知IAP服务器更新商品的发货状态，完成购买流程。应用成功执行 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 之后，IAP服务器会将相应商品标记为已发货状态。此步骤也可放到应用服务器处理。应用服务器可通过请求服务端 [订阅确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-sub.md) 接口来确认发货，完成购买流程。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a3/v3/yDfoXc3-Rum_pJUtbgSIVw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=4B25AFCFDCABEDDB98645815B2D2EEC24033F1BB6093E81C09E0485EDF2BFBDC)
对于自动续期订阅商品，如果不执行此步骤，会导致后续自动续期无法扣费 ，以及同一个订阅组不同自动续期订阅商品无法切换等问题。
#### 开发步骤
1.
应用客户端向IAP Kit发起 [queryPurchases](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，获取生效中的订阅列表。
在请求参数 [QueryPurchasesParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中指定productType为 [iap.ProductType.AUTORENEWABLE](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) ，同时指定queryType为 [iap.PurchaseQueryType.CURRENT_ENTITLEMENT](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 。当接口请求成功时，IAP Kit将返回一个 [QueryPurchaseResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 对象，该对象包含承载了订阅信息的 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的列表。
2.
验证订单信息。对每个 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .jwsSubscriptionStatus进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，验证成功可得到 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。建议应用客户端将 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 发送至应用服务器，在应用服务器执行此操作。
为了提高安全性，可从 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.lastPurchaseOrder中解析出purchaseToken和purchaseOrderId信息，并通过服务端 [订阅状态查询](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-query-subscription-status.md) 接口向IAP服务器查询最新的订阅状态信息，进一步确认订阅信息的准确性。
3.
展示订阅状态。
- 如果[SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md).lastSubscriptionStatus.status=1，表示订阅处于生效状态。
- 如果[SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md).lastSubscriptionStatus.status=1且[SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md).lastSubscriptionStatus.renewalInfo.autoRenewStatusCode值为1时，表示订阅处于自动续期状态。此状态的商品无法再次购买，需要屏蔽相关的购买入口。
4.
权益发放。获取 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.lastPurchaseOrder（下文标记为 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ），处理权益发放。
可先检查此笔订单权益的发放状态，未发放则补充发放权益，成功后记录 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 等信息，用于后续检查权益发放状态。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/72/v3/z9sxRTsmSXeGkfj7yyFHfg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=E19C23B5684A518AF9CCA44255FCC12E40DE7E9D2DA89B7F745A55D28F8A62AF)
建议单机应用将用户权益和订阅状态关联。如果订阅处于生效状态，始终为用户发放权益。
5.
在发放权益后，如果 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .finishStatus不为1，应用需调用 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 接口确认发货，完成购买流程。
发起请求时，需在请求参数 [FinishPurchaseParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中携带 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 中的productType、purchaseToken、purchaseOrderId。请求成功后，IAP服务器会将相应商品标记为已发货。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/92/v3/vcQlUC8vSbG8Cf4_Pyt4JQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=A875B6C884288075E6D76179904141567D4AEDA1B8DCB68E92A5717639F9AAD4)
此步骤也可放到应用服务器处理。应用服务器可通过请求服务端 [订阅确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-sub.md) 接口来确认发货，完成购买流程。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ff/v3/CeTnzvqLSauBjPMZnilzBw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=6DBA7A6A87F89C5E59834EE595E7949825F4B85FDD99B4A92D79BC64C1F898FB)
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
  queryPurchases(context: common.UIAbilityContext) {
    const param: iap.QueryPurchasesParameter = {
      productType: iap.ProductType.AUTORENEWABLE,
      queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
    };
    iap.queryPurchases(context, param).then((res: iap.QueryPurchaseResult) => {
      console.info('Succeeded in querying purchases.');
      const purchaseDataList: string[] = res.purchaseDataList;
      if (purchaseDataList === undefined || purchaseDataList.length <= 0) {
        return;
      }
      for (let i = 0; i < purchaseDataList.length; i++) {
        const jwsSubscriptionStatus: string = JSON.parse(purchaseDataList[i]).jwsSubscriptionStatus;
        if (!jwsSubscriptionStatus) {
          continue;
        }
        // 对jwsSubscriptionStatus进行解码验签
        const subscriptionStatus: string = JWSUtil.decodeJwsObj(jwsSubscriptionStatus);
        // 需自定义SubGroupStatusPayload类，包含的信息请参见SubGroupStatusPayload
        const subGroupStatusPayload: SubGroupStatusPayload = JSON.parse(subscriptionStatus);
        const lastSubscriptionStatus = subGroupStatusPayload.lastSubscriptionStatus;
        if (!lastSubscriptionStatus) {
          continue;
        }
        // 根据status判断订阅的状态
        const status = lastSubscriptionStatus.status;
        // 更新商品的订阅状态
        // ...
        // 处理权益发放
        const purchaseOrderPayload = lastSubscriptionStatus.lastPurchaseOrder;
        if (purchaseOrderPayload === undefined) {
          continue;
        }
        if (status === '1') {
          // 订阅处于生效状态
          // 处理权益发放。检查此笔订单权益的发放状态，未发放则补充发放权益
          // ...
        }
        // 发放权益后向IAP Kit发送finishPurchase请求，确认发货，完成购买
        if (purchaseOrderPayload && purchaseOrderPayload.finishStatus !== '1') {
          this.finishPurchase(context, purchaseOrderPayload);
        }
      }
    }).catch((err: BusinessError) => {
      // 请求失败
      console.error(`Failed to query purchases. Code is ${err.code}, message is ${err.message}`);
    })
  }
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
#### 确保权益发放
用户购买自动续期订阅成功或者自动续期成功后，开发者需要及时给用户发放相关权益。但实际应用场景中，若出现异常（网络错误等）将导致应用无法知道用户实际是否支付成功，从而无法及时发放权益，即出现掉单情况。
为了确保权益发放，需要在 [createPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求返回 [iap.IAPErrorCode.PRODUCT_OWNED](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 或 [iap.IAPErrorCode.SYSTEM_ERROR](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 时检查用户是否存在已购但未确认发货的商品，如果存在则发放相关权益，然后向IAP Kit确认发货，完成购买。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4a/v3/FEM44f7jS6CTRFQzVGsQrQ/zh-cn_image_0000002628701726.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=FEB13E430562ED45BEDDA5D18245397AB1D215030C8C41A92020AB59E590F042)
1.
应用客户端向IAP Kit发起 [queryPurchases](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，查询用户已购买但未确认发货的订阅列表。
2.
IAP Kit返回 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 列表。 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 为JWS格式的字符串，承载了相关的订阅信息。
3.
应用客户端向应用服务器上报 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 列表。
4.
应用服务器需对每个 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .jwsSubscriptionStatus进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，验证成功可得到对应的 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。
5.
处理权益发放。检查 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.lastPurchaseOrder是否已发放权益，未发放则需发放相关权益，并记录对应的订单信息（ [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ）。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/0e/v3/vf2GpBisTD2Se20I6NaO7g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=C494685206E869E85994FBCD972D58B0A084372960A84E17816927B473F28955)
建议单机应用将用户权益和订阅状态关联。如果订阅处于生效状态，始终为用户发放权益。
6.
应用客户端向应用服务器查询订单的发货状态。
7.
应用服务器返回对应的发货状态以及订单信息（ [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) ）。
8.
发放权益后应用客户端向IAP Kit发送 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，以此通知IAP服务器更新商品的发货状态，完成购买流程。应用成功执行 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 之后，IAP服务器会将相应商品标记为已发货状态。此步骤也可放到应用服务器处理。应用服务器可通过请求服务端 [订阅确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-sub.md) 接口来确认发货，完成购买流程。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6b/v3/q50QqCx2S9-S_7MNTeZDmg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=ACC93C5D2B89A032764D018310C4C80FCC0FB012BE395723398ABB76157B2DE9)
对于自动续期订阅商品，如果不执行此步骤，会导致后续自动续期无法扣费 ，以及同一个订阅组不同自动续期订阅商品无法切换等问题。
#### 开发步骤
1.
应用客户端向IAP Kit发起 [queryPurchases](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求，获取用户已购但未确认发货的订阅列表。
在请求参数 [QueryPurchasesParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中指定productType为 [iap.ProductType.AUTORENEWABLE](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) ，同时指定queryType为 [iap.PurchaseQueryType.UNFINISHED](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 。当接口请求成功时，IAP Kit将返回一个 [QueryPurchaseResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 对象，该对象包含承载了订阅信息的 [PurchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的列表。
2.
验证订单信息。对每个 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .jwsSubscriptionStatus进行 [解码验签](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-verifying-signature.md) ，验证成功可得到 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 的JSON字符串。建议应用客户端将 [purchaseData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 发送至应用服务器，在应用服务器执行此操作。
为了提高安全性，可从 [SubGroupStatusPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) .lastSubscriptionStatus.lastPurchaseOrder中解析出purchaseToken和purchaseOrderId信息，并通过服务端 [订阅状态查询](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-query-subscription-status.md) 接口向IAP服务器查询最新的订阅状态信息，进一步确认订阅信息的准确性。
3.
处理权益发放。
如果SubGroupStatusPayload.lastSubscriptionStatus.status=1，表示订阅处于生效状态。需要对生效状态的订阅处理权益发放。建议先检查此笔订单权益的发放状态，未发放则补充发放权益，成功后记录 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 等信息，用于后续检查权益发放状态。
建议单机应用将用户权益和订阅状态关联。如果订阅处于生效状态，始终为用户发放权益。
4.
在发放权益后，如果PurchaseOrderPayload.finishStatus不为1，应用需调用 [finishPurchase](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 接口确认发货，完成购买流程。
发起请求时，需在请求参数 [FinishPurchaseParameter](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 中携带 [PurchaseOrderPayload](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-data-model.md) 中的productType、purchaseToken、purchaseOrderId。请求成功后，IAP服务器会将相应商品标记为已发货。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f6/v3/BFERZWK4TiibhIiR1GXwOA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=B97C61B13AD61EADC979EDEC5D6C85FDE63C209E817308B3D65F7427CABD947B)
此步骤也可放到应用服务器处理。应用服务器可通过请求服务端 [订阅确认发货](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-confirm-purchase-for-sub.md) 接口来确认发货，完成购买流程。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/19/v3/jouvqg1ZSregIMYNxuVfTA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105220Z&HW-CC-Expire=86400&HW-CC-Sign=3B04ABCF8D6DD5389474A1496E56C5F99E89B963FD409768313D929B2F335252)
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
  queryPurchases(context: common.UIAbilityContext) {
    const param: iap.QueryPurchasesParameter = {
      productType: iap.ProductType.AUTORENEWABLE,
      queryType: iap.PurchaseQueryType.UNFINISHED
    };
    iap.queryPurchases(context, param).then((res: iap.QueryPurchaseResult) => {
      console.info('Succeeded in querying purchases.');
      const purchaseDataList: string[] = res.purchaseDataList;
      if (purchaseDataList === undefined || purchaseDataList.length <= 0) {
        return;
      }
      for (let i = 0; i < purchaseDataList.length; i++) {
        const jwsSubscriptionStatus: string = JSON.parse(purchaseDataList[i]).jwsSubscriptionStatus;
        if (!jwsSubscriptionStatus) {
          continue;
        }
        // 对jwsSubscriptionStatus进行解码验签
        const subscriptionStatus: string = JWSUtil.decodeJwsObj(jwsSubscriptionStatus);
        // 需自定义SubGroupStatusPayload类，包含的信息请参见SubGroupStatusPayload
        const subGroupStatusPayload: SubGroupStatusPayload = JSON.parse(subscriptionStatus);
        const lastSubscriptionStatus = subGroupStatusPayload.lastSubscriptionStatus;
        if (!lastSubscriptionStatus) {
          continue;
        }
        // 根据status判断订阅的状态
        const status = lastSubscriptionStatus.status;
        // 更新商品的订阅状态
        // ...
        // 处理权益发放
        const purchaseOrderPayload = lastSubscriptionStatus.lastPurchaseOrder;
        if (purchaseOrderPayload === undefined) {
          continue;
        }
        if (status === '1') {
          // 订阅处于生效状态
          // 处理权益发放。检查此笔订单权益的发放状态，未发放则补充发放权益
          // ...
        }
        // 发放权益后向IAP Kit发送finishPurchase请求，确认发货，完成购买
        if (purchaseOrderPayload && purchaseOrderPayload.finishStatus !== '1') {
          this.finishPurchase(context, purchaseOrderPayload);
        }
      }
    }).catch((err: BusinessError) => {
      // 请求失败
      console.error(`Failed to query purchases. Code is ${err.code}, message is ${err.message}`);
    })
  }
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