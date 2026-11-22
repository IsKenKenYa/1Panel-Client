# 穿戴设备信息查询
---
# 穿戴设备信息查询
```typescript
// 在使用Wear Engine服务前，请导入WearEngine与相关模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
```
#### 查询穿戴设备是否支持某种WearEngine能力集
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a7/v3/VmnrhKKVQd6s1lygP6y_ng/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104932Z&HW-CC-Expire=86400&HW-CC-Sign=547C49605780C426520E55989A4BBC5F946E73DE93BE538561102BDC327FEB00)
该接口的调用需要在开发者联盟申请设备基础信息权限（请参考 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) ）。
通过 [Device](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象中的方法 [isWearEngineCapabilitySupported](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 查询穿戴设备是否支持某种WearEngine能力集。
1.
应用调用 [wearEngine](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 中的 [getDeviceClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [DeviceClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
```typescript
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
```
2.
调用 [getConnectedDevices](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取已连接的设备列表。
```typescript
let deviceList: wearEngine.Device[] = [];
deviceClient.getConnectedDevices().then(devices => {
  // 存储已连接的设备列表
  deviceList = devices;
  console.info(`Succeeded in getting deviceList, devices number is ${deviceList.length}`);
}).catch((error: BusinessError) => {
  // 处理调用失败时捕获到的异常
  console.error(`Failed to get deviceList. Code is ${error.code}, message is ${error.message}`);
});
```
3.
从设备列表中选取需要操作的设备。
4.
调用 [Device](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象中的 [isWearEngineCapabilitySupported](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 接口可查询该设备是否支持传入的WearEngine能力（true：支持；false：不支持），以P2P能力为例。
```typescript
if (deviceList.length > 0) {
  // 步骤3 从得到的设备列表中选取目标设备，并定义为device(假设数组中存在已连接设备且第一位即为目标设备)
  let targetDevice: wearEngine.Device = deviceList[0];
  // 步骤4 调用设备的方法查询是否支持某种WearEngine能力（以P2P为例）
  targetDevice.isWearEngineCapabilitySupported(wearEngine.WearEngineCapability.P2P_COMMUNICATION).then((isSupportP2P) => {
    console.info(`Succeeded in checking p2p capability, result is ${isSupportP2P}`);
  }).catch((error: BusinessError) => {
    console.error(`Failed to check p2p capability. Code is ${error.code}, message is ${error.message}`);
  });
}
```
#### 查询穿戴设备是否支持某种Device能力集
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/26/v3/VSaLb9ceTNW0p3ZtngfqpA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104932Z&HW-CC-Expire=86400&HW-CC-Sign=9300147135A8E645D4812AC8076EFFD2AB9A5DCE5DA97C9059418B257F6F453C)
该接口的调用需要在开发者联盟申请设备基础信息权限（请参考 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) ）。
通过 [Device](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象中的方法 [isDeviceCapabilitySupported](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 查询穿戴设备是否支持某种Device能力集。
1.
应用调用 [wearEngine](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 中的 [getDeviceClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [DeviceClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
```typescript
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
```
2.
调用 [getConnectedDevices](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取已连接的设备列表。
```typescript
let deviceList: wearEngine.Device[] = [];
deviceClient.getConnectedDevices().then(devices => {
  // 存储已连接的设备列表
  deviceList = devices;
  console.info(`Succeeded in getting deviceList, devices number is ${deviceList.length}`);
}).catch((error: BusinessError) => {
  // 处理调用失败时捕获到的异常
  console.error(`Failed to get deviceList. Code is ${error.code}, message is ${error.message}`);
});
```
3.
从设备列表中选取需要操作的设备。
4.
调用 [Device](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象中的 [isDeviceCapabilitySupported](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 接口可查询该设备是否支持传入的Device能力（true：支持；false：不支持）。
```typescript
if (deviceList.length > 0) {
  // 步骤3 从得到的设备列表中选取目标设备，并定义为device(假设数组中存在已连接设备且第一位即为目标设备)
  let targetDevice: wearEngine.Device = deviceList[0];
  // 步骤4 调用设备的方法查询是否支持某种Device能力（以是否支持应用安装为例）
  targetDevice.isDeviceCapabilitySupported(wearEngine.DeviceCapability.APP_INSTALLATION).then((isSupportInstall) => {
    console.info(`Succeeded in checking install app capability, result is ${isSupportInstall}`);
  }).catch((error: BusinessError) => {
    console.error(`Failed to check install app capability. Code is ${error.code}, message is ${error.message}`);
  });
}
```
#### 查询设备SN
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e5/v3/Lrj5YG-4QiiHtO-5hdIjiQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104932Z&HW-CC-Expire=86400&HW-CC-Sign=F8FD53E5856D9C6F982F2FFD89DBE3854E2C5A306C5EF83CFC56DE576F95B1F2)
该接口的调用需要在开发者联盟申请设备标识符权限（受限开放）并获得用户授权（请参考 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) ）。
通过 [Device](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象中的方法 [getSerialNumber](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 查询穿戴设备的SN。
1.
应用调用 [wearEngine](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 中的 [getDeviceClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [DeviceClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
```typescript
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
```
2.
调用 [getConnectedDevices](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取已连接的设备列表。
```typescript
let deviceList: wearEngine.Device[] = [];
deviceClient.getConnectedDevices().then(devices => {
  // 存储已连接的设备列表
  deviceList = devices;
  console.info(`Succeeded in getting deviceList, devices number is ${deviceList.length}`);
}).catch((error: BusinessError) => {
  // 处理调用失败时捕获到的异常
  console.error(`Failed to get deviceList. Code is ${error.code}, message is ${error.message}`);
});
```
3.
从设备列表中选取需要操作的设备。
4.
调用 [Device](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象中的方法 [getSerialNumber](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 查询穿戴设备的SN。
```typescript
if (deviceList.length > 0) {
  // 步骤3 从得到的设备列表中选取目标设备，并定义为device(假设数组中存在已连接设备且第一位即为目标设备)
  let targetDevice: wearEngine.Device = deviceList[0];
  // 步骤4 调用设备的方法查询SN
  targetDevice.getSerialNumber().then((sn) => {
    console.info(`Succeeded in getting device SN, result is ${sn}`);
  }).catch((error: BusinessError) => {
    console.error(`Failed to get device SN. Code is ${error.code}, message is ${error.message}`);
  });
}
```