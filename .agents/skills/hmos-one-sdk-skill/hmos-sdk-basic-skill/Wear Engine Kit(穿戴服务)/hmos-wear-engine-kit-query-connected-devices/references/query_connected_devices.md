# 已连接穿戴设备查询
---
# 已连接穿戴设备查询
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a1/v3/B4QGwJkkSmqBNS4gVf0bpQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104932Z&HW-CC-Expire=86400&HW-CC-Sign=5F41B7006865DA2780982DD219975693F8F21D0059B601CFEDD7AC89054A349F)
该接口的调用前，需要在开发者联盟申请设备基础信息权限（具体请参考 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) ）。
Wear Engine提供查询用户已连接的穿戴设备列表（即支持Wear Engine能力且与手机侧运动健康App处于连接状态的穿戴设备）的接口。
建议开发者在使用Wear Engine其他API接口前先实现该接口功能。
1.
应用调用 [wearEngine](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 中的 [getDeviceClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [DeviceClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
2.
调用 [getConnectedDevices](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，查询用户已连接的穿戴设备列表。
```typescript
// 在使用Wear Engine服务前，请导入WearEngine与相关模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
// 步骤1：获取DeviceClient对象
// this.getUIContext().getHostContext() 表示应用上下文Context对象
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
// 创建一个设备列表用于存储返回的设备
let deviceList: wearEngine.Device[] = [];
// 步骤2：调用getConnectedDevices方法，查询用户是否有已连接的穿戴设备
deviceClient.getConnectedDevices().then(devices => {
  // 处理返回的设备列表
  deviceList = devices;
  console.info(`Succeeded in getting deviceList, deviceList number is ${deviceList.length}`);
}).catch((error: BusinessError) => {
  // 处理调用失败时捕获到的异常
  console.error(`Failed to get deviceList. Code is ${error.code}, message is ${error.message}`);
});
```