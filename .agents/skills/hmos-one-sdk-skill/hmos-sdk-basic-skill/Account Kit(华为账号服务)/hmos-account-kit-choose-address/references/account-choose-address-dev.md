# 获取收货地址
---
# 获取收货地址
#### 场景介绍
当应用需要获取用户收货地址时，可使用Account Kit提供的获取收货地址的能力，引导用户添加或选择已有的收货地址，并最终获取用户的收货地址。以下对Account Kit提供的获取收货地址能力进行介绍，获取收货地址功能还可使用场景化控件 [选择收货地址Button](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Scenario Fusion Kit（融合场景服务）/场景化Button/选择收货地址Button/scenario-fusion-button-ship-to.md) 进行实现。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/97/v3/xZ6jODRYShioz_8w1EDFqA/zh-cn_image_0000002628701546.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=4A920F3FD3C365FB3D97FCEEFB6FF883D0F62D25AC4AA1E9176E3CE774591389)
#### 约束与限制
1.
收货地址中的手机号信息仅支持输入中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）手机号、地址信息只支持填写中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）。
2.
获取收货地址的能力支持Phone、Tablet、PC/2in1设备。并且从26.0.0版本开始，新增支持TV、Car设备。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/53/v3/3xMpnoyiT4yGOwLS8Rs9TQ/zh-cn_image_0000002659100775.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=CF232A9BF4BCBF4EC96B3508240AF980EE4C49EBF1048675D231A9CF709D7EA7)
流程说明：
1.
用户需要使用收货地址时，应用程序调用选择收货地址API，打开华为账号收货地址管理页面。
2.
用户可以在收货地址管理页面添加新的收货地址或者选择已有收货地址，点击确认后，选择的收货地址将返回给应用。
#### 接口说明
获取收货地址关键接口如下表所示，具体API说明详见 [API参考](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-choose-address.md) 。
| 接口名 | 描述 |
| --- | --- |
| [chooseAddress](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-choose-address.md)(context:[common.Context](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-common.md)): Promise<[AddressInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-choose-address.md)> | 拉起收货地址管理页面并返回用户所选择的收货地址。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/89/v3/Wpsrkct0Sh6e_XDXwunbMg/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=356C66F8B1E5B20598517C9F5C40DA3988124EDEB3F2C46D7F71A51E45B044CB)
上述接口需在页面或自定义组件生命周期内调用。
#### 开发前提
在进行代码开发前，请先确认以下准备工作是否完成：
1、是否完成 [申请账号权限](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/开发准备/申请账号权限/account-config-permissions.md) ，未申请通过调用获取收货地址API，将返回 [1008100005 应用未申请对应permissions权限](D:/code/APIDevice/output/md_output/harmonyos-references/errorcode-account-kit.md) 错误码，无法获取收货地址。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f3/v3/Q58ijGsfRZyFzBCye-H3IQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=9BB725FF5E9E82C24B29E1383C1084DD0A7E2E3A15622F6C8757A1AB632FF7D3)
如果在权限申请前已完成“配置签名和指纹”，则需要重新 [申请调试Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278) ，并重新 [手动配置签名信息](D:/code/APIDevice/output/md_output/harmonyos-guides/编写与调试应用/配置调试签名/ide-signing.md) 。
2、是否完成 [配置签名和指纹](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/开发准备/配置签名和指纹/account-sign-fingerprints.md) 、 [配置Client ID](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/开发准备/配置Client ID/account-client-id.md) ，未配置调用获取收货地址API，将返回 [1008100004 应用指纹证书校验失败](D:/code/APIDevice/output/md_output/harmonyos-references/errorcode-account-kit.md) 错误码，无法获取收货地址。
#### 开发步骤
1.
导入 [shippingAddress](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-choose-address.md) 模块及相关公共模块。
```typescript
import { shippingAddress } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
调用 [chooseAddress](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-choose-address.md) 方法打开收货地址管理页面，引导用户添加或选择收货地址后，应用即可获取用户收货地址。
```
// 执行请求
try {
  // 此示例为代码片段，实际需在自定义组件实例中使用，并传入有效的Context上下文对象
  shippingAddress.chooseAddress(this.getUIContext().getHostContext())
    .then((data: shippingAddress.AddressInfo) => {
      hilog.info(0x0000, 'testTag', 'Succeeded in choosing address.');
      const userName: string = data.userName;
      const mobileNumber: string = data.mobileNumber;
      const countryCode: string = data.countryCode;
      const provinceName: string = data.provinceName;
      const cityName: string = data.cityName;
      const districtName: string = data.districtName;
      const streetName: string = data.streetName;
      const detailedAddress: string = data.detailedAddress;
      // 开发者处理获取的收货地址信息
      // ...
    }).catch((error: BusinessError) => {
    // ...
    dealAllError(error);
  });
} catch (error) {
  // ...
  dealAllError(error);
}
```
```typescript
// 错误处理
function dealAllError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `Failed to chooseAddress. Code: ${error.code}, message: ${error.message}`);
}
```