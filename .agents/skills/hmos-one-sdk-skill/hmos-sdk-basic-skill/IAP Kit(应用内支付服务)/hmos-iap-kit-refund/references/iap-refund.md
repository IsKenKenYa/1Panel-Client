# 退款
---
# 退款
当 [用户申请退款](#用户申请退款) 时，对于非游戏类应用，开发者可以在 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 上审核退款订单，实现用户的退款。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/be/v3/4f5Hf_pNSiuxBMBxSOC1Ig/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=90B5000FF0DB2C56AA48A1575FEF390926648B1CD9437BF5C0B96502FD9B5318)
-
退款只能由用户发起，具体参见 [用户申请退款](#用户申请退款) 。
-
对于游戏类应用， [用户申请退款](#用户申请退款) 后，由华为游戏运营人员审核退款，开发者可跳过此章节。
#### 开发者审核退款订单
开发者使用退款管理功能，需要拥有至少一个具备退款权限的角色：账号持有者、管理员、App管理员、财务。具体可查看 [添加成员账号](https://developer.huawei.com/consumer/cn/doc/app/agc-help-manageaccount-0000001099996700#section151241455193313) 。
添加完账号后，开发者可按照以下步骤审核用户的退款订单：
1.
开发者登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) ，选择“APP”。 在应用列表中点击待处理退款订单的应用。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/22/v3/u_KkVlcBQBm91t288ewsCw/zh-cn_image_0000002628861614.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=708F3FCAA7E7385F8FF0C98B194B56D0BB63F6AB1F30FCD2CF33504908424560)
2.
在“运营”页签下，点击“产品运营 > 退款管理”，查看用户提交的退款申请，处理退款订单。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ee/v3/BWbNxTpuS1-_9u_BnchFWA/zh-cn_image_0000002659220927.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=B6A7288A7AEC65CCAAE5CB24D3D2C946270B9A649539484B21637C073B5C746D)
3.
审核或查询退款订单。
**同意退款** ：如果开发者同意退款，可在 “退款金额“下输入可退款金额，点击“同意”。在弹窗中点击“确认”，即可完成退款。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/bc/v3/U13CghVHRXSE74ufwyoz-w/zh-cn_image_0000002628701736.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=ED5C65510C1685C15E744834762B2A4D3696EF7236F3A453F88C41E24B6F33D7)
**驳回退款** ：开发者不同意退款，可点击“驳回”，输入驳回原因，点击“确认”。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/62/v3/x8J8-IQ8Q-WBj1fxPRAAxg/zh-cn_image_0000002659100967.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=7C29E67237328542C2A3F57F5841308D99FE1FB912AE5517EA3DA2B3E3A5A761)
**退款详情页面审核退款** ：开发者也可以在退款详情页面审核退款，输入退款金额后选择“同意”或“驳回”，点击提交，完成审核。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/2a/v3/yDAKKhWGQ5SDu3IfDO43yg/zh-cn_image_0000002628861616.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=17B3602561CC28C54812C3BD17FD488CDDC3715E18E3148BD85F40B1AE08B9D8)
**查询退款订单** ：点击“已完成”页签，开发者可以查看所有已处理的退款订单。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ac/v3/5q-lPEeRTsublHxUH4n-2Q/zh-cn_image_0000002659220929.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=15F46185A4B4EB1F9CBCE785F30C749F141A7F81D23FB2B715DD5096F90336A4)
退款订单状态如下：
| **序号** | **退款订单状态** | **说明** |
| --- | --- | --- |
| 1 | 申请已拒绝 | 开发者驳回退款订单。 |
| 2 | 申请已通过 | 开发者同意退款订单。 |
| 3 | 退款成功 | 开发者同意退款，且华为操作退款成功。 |
| 4 | 退款失败 | 开发者同意退款，且华为操作退款失败。 |
| 5 | 超期未处理 | 开发者未按规定时间处理退款订单时，退款订单由华为运营进行审核。 |
#### 用户申请退款
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e0/v3/PXuiG-jnQmqGCVdd2QPKlg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=66C2A623C00DC0437DAEB21C0120A3383E43F792F73517D77A2BBFB395E2E13E)
-
生态应用订单退款最低系统版本要求为6.16.10（检查版本可参考以下路径“系统设置-华为账号-付款与账单-更多设置-关于”）。
-
退款申请后到退款完成非实时，一般从发起申请退款到完成需要7个工作日左右。
若用户购买应用内数字商品后需要申请退款，可选择某笔订单后根据页面指引，提交退款信息。开发者审核完成后，用户可收到退款金额。
用户可按照以下步骤申请订单退款：
1.
在“手机设置 > 华为账号 > 付款与账单 > 购买记录”中点击待退款的订单，跳转至详情页面，点击“对订单有疑问”。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9d/v3/kWK6imlVR72u6dxQ-BaUGg/zh-cn_image_0000002628701738.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=B8EE21D81D61DC47256AA7CE41F43006F25A9E40466DCDB1F3889F1E62FBF307) ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d7/v3/Ds159beSR5iS74F8tS2JgA/zh-cn_image_0000002659100969.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=AC926546F69E7109495516BF4EDC1FE870835D3E0AFA2391B411C8780D612558)
2.
在“对订单有疑问”页面，点击“申请退款”，选择退款原因后，提交退款申请，提交后等待应用审核。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1a/v3/xz6aQrTdTESY1XVJfkQufg/zh-cn_image_0000002628861618.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=E85BD15123DF268120CEFE67EE242E19DC4FB6577744917F853E5546542A19A8) ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6c/v3/lwp9W8ETRBuADC16Ty_SHw/zh-cn_image_0000002659220931.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=E25C69A74448DD0E9F8779F8E2EE0D218D33869BB6A58AF1E1A24E67570EF841)
用户提交退款后，可点击“查看退款记录”，在“退款记录”查看所有退款订单的退款状态。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/da/v3/EaU01f6aQ1-Vm9hqw3BPFA/zh-cn_image_0000002628701740.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=E6D8C89097006C6C479C977973FFABB5DF5D474BEC9F6E162E0F2C9D4F769F75) ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ed/v3/GNrbXq7lRWemW4Pnjyxsqg/zh-cn_image_0000002659100971.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=C6B209F1030405562E2D9B89274004B089C704F82CC5AD80967091561F04A0B8)
#### 应用内接入退款入口
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9a/v3/NaEXkaPYTZCQA5Z6J9UoIQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=DA4B0C754DC64224097FB32496CF4574273968ECE56059F6B1AC734B312B8BBC)
-
仅支持非游戏类应用接入。
-
该退款入口仅支持应用本身所产生的订单的退款。
**拉起退款**
用户发起退款后，应用客户端向IAP Kit发送 [createRefundRequest](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap) 请求拉起退款页面，请求中需携带待退款的订单号（purchaseOrderId）。
**代码示例**
```typescript
import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
@Entry
@Component
struct Index {
  /**
   * 拉起退款界面
   */
  createRefundRequest(context: common.UIAbilityContext) {
    // 调用iap.createRefundRequest拉起退款，传入context和purchaseOrderId
    let purchaseOrderId = '';
    iap.createRefundRequest(context, purchaseOrderId).then(() => {
      // 退款成功
      console.info('Succeeded in creating refund request.');
      // ...
    }).catch((err: BusinessError) => {
      // 退款失败
      console.error(`Failed to create refund request. Code is ${err.code}, message is ${err.message}`);
      // ...
    });
  }
  build() {}
}
```