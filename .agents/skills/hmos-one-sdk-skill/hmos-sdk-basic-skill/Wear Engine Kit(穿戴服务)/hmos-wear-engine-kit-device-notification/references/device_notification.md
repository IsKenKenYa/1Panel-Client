# 穿戴设备模板化通知
---
# 穿戴设备模板化通知
手机侧应用向穿戴设备发送通知，并在穿戴设备上按模板显示，支持穿戴设备收到通知后同步振动或响铃（跟随穿戴设备系统设置）。执行成功后，穿戴设备上会显示下图所示通知界面。
该接口无需用户授权，仅需要确保应用已申请消息通知权限（参见 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) ），否则接口将调用失败。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/bd/v3/6yAS1FHbS5aBf6rmm3rHbQ/zh-cn_image_0000002628861100.png?HW-CC-KV=V1&HW-CC-Date=20260701T104933Z&HW-CC-Expire=86400&HW-CC-Sign=B863C6B3C40BA962C0D5A58F72341E553071347CEBEDB3D3881FDB762C4E1BB3)
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b2/v3/eCMhKtOgTkyRo_VkeEBnzQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104933Z&HW-CC-Expire=86400&HW-CC-Sign=FC85EE7A1AF37F5E24E17159F249F91BD8EE888419605EB60205D93575B30A20)
-
穿戴设备侧无对应的应用也可以显示模板化通知。
-
请确保穿戴设备和华为运动健康App处于连接状态。用户可进入App“设备”界面查看设备是否在线。开发者可调用 [getConnectedDevices](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法了解设备是否在线，如果返回列表中不包含目标设备，则提醒用户重新连接该设备。
-
穿戴设备振动或响铃的条件：
1. 穿戴设备侧已开启振动或响铃；
2. 穿戴设备处于佩戴状态；
3. 穿戴设备未开启勿扰模式。
-
通知在穿戴设备上自动弹出通知的条件：
1. 穿戴设备处于佩戴状态；
2. 穿戴设备未开启勿扰模式。
#### 向穿戴设备侧发送通知
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/82/v3/Ssc_iA-tR4-Kyvh3AhdFAw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104933Z&HW-CC-Expire=86400&HW-CC-Sign=BFEC497686B513A829AFEC363E8E4FC2673D71FDEBE4CD81B415A5CBBA19C38A)
该接口的调用需要在开发者联盟申请消息通知权限（请参考 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) ）。
1.
参见 [已连接穿戴设备查询](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/应用开发/已连接穿戴设备查询/query_connected_devices.md) 章节，获取已连接设备列表。
2.
参见 [目标设备选择](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/应用开发/目标设备选择/we-device-selection.md) 章节，从已连接设备列表中选定需要通信的设备。
3.
调用 [wearEngine](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 中的 [getNotifyClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [NotifyClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
4.
定义 [NotificationOptions](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 配置参数类。
5.
调用 [notify](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，从手机上的应用发送通知到穿戴设备侧。
```typescript
// 步骤3 获取NotifyClient对象
let notifyClient: wearEngine.NotifyClient = wearEngine.getNotifyClient(this.getUIContext().getHostContext());
// 步骤4 构造NotificationOptions对象
let button1: wearEngine.NotificationButton = {
  buttonId: wearEngine.ButtonId.FIRST_BUTTON,
  // 按钮内容最大长度为12字节
  content: 'button_1'
}
let type1Notification: wearEngine.Notification = {
  type: wearEngine.NotificationType.NOTIFICATION_WITH_ONE_BUTTON,
  // 包名与标题的最大长度为28字节
  bundleName: 'bundleName',
  title: 'title',
  // 消息内容最大长度为400字节
  text: 'text',
  buttons: [button1]
}
let options: wearEngine.NotificationOptions = {
  notification: type1Notification,
  onAction: (feedback: wearEngine.NotificationFeedback) => {
    console.info(`one button notify get feedback is ${feedback.action ? feedback.action : feedback.errorCode}`);
  }
}
// 步骤5 发送模板化通知至设备侧
notifyClient.notify(targetDevice.randomId, options).then(result => {
  console.info(`Succeeded in sending notification.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to send notification. Code is ${error.code}, message is ${error.message}`);
})
```