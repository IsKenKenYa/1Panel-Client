# 开票
---
# 开票
#### 用户申请开发票
从6.1.0（23）开始，支持开发票功能。若用户购买应用内数字商品后需要申请开发票，可选择需要申请开票的订单后根据页面指引，提交开发票信息。
用户可按照以下步骤：
1.
选择“手机设置 > 华为账号 > 付款与账单 > 发票中心”，点击“开发票”，在需要开发票的订单后，点击“下一步”，进入“开发票”页面。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1f/v3/KeGgzDW5S-KuGuqY9JO0fw/zh-cn_image_0000002628861620.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=0824E284774F99831719DD7B86BE05DBAF633C2EF80D1B0AE35D73923C656B57) ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/88/v3/nCLXxPl8Rfm1Q2o96daFzg/zh-cn_image_0000002659220933.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=EE395B39FDE838AF0F751B5A259C8B1887AE1F3B3DEF2445632F21BD279A3A06)
2.
在“开发票”页面，选择发票类型、抬头类型，输入发票抬头、税号和电子邮箱，然后提交开发票申请，提交后等待即可。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/49/v3/nuOD4TAjQQS9lVtmuizFLg/zh-cn_image_0000002628701742.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=87A0C5C78D34C2FA1C886A2374C82409ADE97C180824BA7A7BD046E7DA6CF2B1)
用户提交开发票申请后，返回“发票中心”页面，在“我的发票”中查看所有订单的开发票状态。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/63/v3/3IXcOayGRB6gs5nAMsnuXw/zh-cn_image_0000002659100973.png?HW-CC-KV=V1&HW-CC-Date=20260701T105222Z&HW-CC-Expire=86400&HW-CC-Sign=323A990D1EFC5098D405F433803B6C99C7690AD548452F4A6A57E394491A17E4)
#### 应用内接入开发票入口
**拉起开发票页面**
用户发起申请开发票后，应用客户端向IAP Kit发送 [showManagedInvoices](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/ArkTS API/iap-iap.md) 请求拉起开发票页面，请求中需携带待开发票的订单号（purchaseOrderId）。
**代码示例**
```typescript
import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
@Entry
@Component
struct IapTest {
  /**
   * 拉起开发票界面
   */
  showManagedInvoices() {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // 调用iap.showManagedInvoices拉起开发票页面，传入context和purchaseOrderId
    let purchaseOrderId = '';
    iap.showManagedInvoices(context, purchaseOrderId).then(() => {
      // 请求成功
      console.info('Succeeded in showing invoice page.');
      // ...
    }).catch((err: BusinessError) => {
      // 请求失败
      console.error(`Failed to show invoice page. Code is ${err.code}, message is ${err.message}`);
      // ...
    });
  }
  build() {
  }
}
```