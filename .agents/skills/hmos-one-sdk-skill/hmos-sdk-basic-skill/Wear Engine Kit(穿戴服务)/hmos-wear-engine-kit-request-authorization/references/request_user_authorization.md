# 请求用户授权
---
# 请求用户授权
为保护用户隐私，Wear Engine的API需要用户授权才可以正常访问。建议开发者在用户首次调用Wear Engine开放能力的时候执行本章节操作。
#### 申请用户穿戴设备权限
应用拉起华为账号登录和授权界面，由用户授权相应的数据访问权限。用户可以自主选择授权的数据类型，可以只授权部分数据权限。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a6/v3/8M2Y_TaEROGiufwdWcFgjQ/zh-cn_image_0000002659100449.png?HW-CC-KV=V1&HW-CC-Date=20260701T104932Z&HW-CC-Expire=86400&HW-CC-Sign=1409B3561B21EC939695146F3D44EECD8FE51A0DAF163CEDCF0FC58EBBB4D79E)
1.
应用调用 [wearEngine](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 中的 [getAuthClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [AuthClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
2.
定义需要用户授权的权限请求类 [AuthorizationRequest](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
3.
调用 [requestAuthorization](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，向用户请求权限。执行成功后，会弹出授权界面，让用户选择授予权限（若未登录华为账号则会先弹出登录界面）。当用户允许后才能正常使用接口，否则会遇到错误码为201的提示。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/87/v3/ZAvCGVawQ9CflqlyLvyHOg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104932Z&HW-CC-Expire=86400&HW-CC-Sign=2A709681573DBF365F9BAF86688FD726CF619F3D2A563ADA23936339A8EAE8C2)
-
请确保向用户请求的权限已在 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) 中审批通过，否则会遇到错误码为1008500004的提示。
-
该功能可以多次调用，如果申请的权限之前已经授予了，不会再弹出授权页面，接口会返回已经授权的权限。
-
通过入参的 [AuthorizationRequest](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象，获取应用需要的权限。参见步骤3中 [权限说明](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) 了解应用所需请求的权限类型。
-
通过 [AuthorizationResponse](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象，返回用户的授权结果。
```
// 在使用Wear Engine服务前，请导入WearEngine与相关模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
// 步骤1：获取AuthClient对象
let authClient: wearEngine.AuthClient = wearEngine.getAuthClient(this.getUIContext().getHostContext());
// 步骤2：基于需要用户授权的权限定义权限请求类
let request: wearEngine.AuthorizationRequest = {
  permissions: [wearEngine.Permission.USER_STATUS]
}
// 步骤3：请求用户授权
authClient.requestAuthorization(request).then(result => {
  console.info(`Succeeded in requesting authorize, authorized permissions is ${result.permissions}`);
}).catch((error: BusinessError) => {
  console.error(`Failed to request authorize. Code is ${error.code}, message is ${error.message}`);
})
```
#### 查询用户授权结果
用于查询已被用户授予的应用权限。如果所需权限用户未授权，请参见上一节 [申请用户穿戴设备权限](#申请用户穿戴设备权限) 向用户请求权限。建议在请求用户授权前，先使用该接口查询应用是否已有相关权限。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/cb/v3/mmL7wnGrTeK-dfVhV21SxQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104932Z&HW-CC-Expire=86400&HW-CC-Sign=1B3DEBB7600A6D99A2B9D40B11BA804E5FC6D8F8D417107F4E6FCEF590B9D7A6)
请确保权限已在 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) 中审批通过，否则会遇到错误码为1008500004的提示。
1.
应用调用 [wearEngine](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 中的 [getAuthClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [AuthClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
2.
调用 [getAuthorization](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，查询用户已授权的权限。
```
// 在使用Wear Engine服务前，请导入WearEngine与相关模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
// 步骤1：获取AuthClient对象
let authClient: wearEngine.AuthClient = wearEngine.getAuthClient(this.getUIContext().getHostContext());
// 步骤2：调用API查询已授权权限
authClient.getAuthorization().then(result => {
  console.info(`Succeeded in getting authorized permissions, authorized permissions is ${result.permissions}`);
}).catch((error: BusinessError) => {
  console.error(`Failed to get authorized permissions. Code is ${error.code}, message is ${error.message}`);
})
```