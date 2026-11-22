# 应用间消息通信
---
# 应用间消息通信
#### 约束与限制
- 使用该功能前，请确保对端设备侧已有对应的应用。
- 对端设备侧应用和穿戴设备应用必须同时处于已启动状态。
#### 穿戴侧应用检测对端设备侧应用是否安装
1.
参见 [已连接对端设备查询](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/穿戴侧应用开发/已连接对端设备查询/watch_query_connected_devices.md) 章节，从已连接设备列表中选定需要通信的对端设备。
2.
调用 [getP2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [P2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
3.
调用 [isRemoteAppInstalled](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，查看对端设备是否安装指定应用。
```typescript
// 将对端应用包名定义为remoteBundleName
let remoteBundleName: string = '';
// 步骤2 获取P2pClient对象
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
// 步骤3 查看是否安装指定的对端应用
p2pClient.isRemoteAppInstalled(targetDevice.randomId, remoteBundleName).then((isInstall) => {
  console.info(`Succeeded in checking remote app install, result is ${isInstall}.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to check remote app install. Code is ${error.code}, message is ${error.message}.`);
})
```
#### 穿戴侧应用发送点对点消息或文件到对端应用
消息长度大小的限制为4096字节。针对消息长度超过限制的情况可以采用发送文件（文件大小不超过100MB）的方式或进行消息分包控制。
穿戴侧实现发送消息和文件功能后，对端应用需要实现接收消息和文件的功能。
#### 发送点对点消息
1.
为了使用工具类构造消息体，请先导入所需模块。
```typescript
import { util } from '@kit.ArkTS';
```
2.
参见 [已连接对端设备查询](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/穿戴侧应用开发/已连接对端设备查询/watch_query_connected_devices.md) 章节，从已连接设备列表中选定需要通信的对端设备。
3.
构造对端应用参数 [P2pAppParam](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
4.
构造需要发送的消息 [P2pMessage](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
5.
调用 [getP2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [P2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
6.
调用 [sendMessage](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，从穿戴侧应用发送简短消息到对端应用。对端应用已注册监听消息接收后，即可收到穿戴侧应用发送的消息。
```typescript
// 步骤2 构造对端应用参数
let appInfo: wearEngine.AppInfo = {
  // 设置对端应用的应用信息：包名与指纹
  bundleName: '',
  fingerprint: ''
};
let appParam: wearEngine.P2pAppParam = {
  remoteApp: appInfo
};
// 设置需要发送的消息内容，长度限制为4096字节
let messageContent: string = 'this is message';
// 步骤3 构造消息结构体
let textEncoder: util.TextEncoder = new util.TextEncoder;
let message: wearEngine.P2pMessage = {
  content: textEncoder.encodeInto(messageContent)
};
// 步骤4 获取P2pClient对象
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
// 步骤5 发送消息
p2pClient.sendMessage(targetDevice.randomId, appParam, message).then((p2pResult) => {
  console.info(`Succeeded in sending message, result is ${p2pResult.code}.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to send message. Code is ${error.code}, message is ${error.message}.`);
});
```
#### 发送文件
1.
发送文件前需要打开文件描述符，请先导入模块。
```typescript
import { fileIo } from '@kit.CoreFileKit';
```
2.
参见 [已连接对端设备查询](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/穿戴侧应用开发/已连接对端设备查询/watch_query_connected_devices.md) 章节，从已连接设备列表中选定需要通信的对端设备。
3.
构造对端应用参数 [P2pAppParam](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
4.
根据文件路径filePath，构造需要发送的文件 [P2pFile](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
5.
调用 [getP2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [P2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
6.
调用 [transferFile](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，从穿戴侧应用发送文件到对端应用。
```typescript
// 步骤2 构造对端应用参数
let appInfo: wearEngine.AppInfo = {
  // 设置对端应用的应用信息：包名与指纹
  bundleName: '',
  fingerprint: ''
};
let appParam: wearEngine.P2pAppParam = {
  remoteApp: appInfo
};
let p2pfile: wearEngine.P2pFile | undefined;
try {
     // 步骤3 构造需要发送的文件
     p2pfile = {
     // 设置需要发送的文件路径，其中不能包含'..'
     file: fileIo.openSync('')
   };
   // 步骤4 获取P2pClient对象
   let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
   // 步骤5 发送指定文件至对端
   p2pClient.transferFile(targetDevice.randomId, appParam, p2pfile, (error: BusinessError,
     p2pResult: wearEngine.P2pResult) => {
     // callback处理逻辑
      if (error) {
         console.error(`Failed to transfer file. Code is ${error.code}, message is ${error.message}.`);
         return;
      }
      if (p2pResult.code) {
         if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
            console.info(`Succeeded in transferring file, the result is ${p2pResult.code}.`);
         } else {
            console.error(`Failed to transfer file, the error code is ${p2pResult.code}.`);
            return;
         }
      }
      if (p2pResult.progress) {
         console.info(`Succeeded in transfering file, the progress is ${p2pResult.progress}.`);
      }
   });
} catch(error) {
   console.error(`Failed to transferFile. Code is ${error.code}, message is ${error.message}.`);
} finally {
  // 确保文件被关闭
   if (p2pfile && p2pfile.file) {
     fileIo.close(p2pfile.file)
     .then(() => {
       console.info('File closed successfully.');
     })
     .catch((closeError: BusinessError) => {
       console.error(`Failed to close file. Code is ${closeError.code}, message is${closeError.message}.`);
     });
   }
};
```
#### 订阅接收对端应用发来的消息
1.
参见 [已连接对端设备查询](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/穿戴侧应用开发/已连接对端设备查询/watch_query_connected_devices.md) 章节，从已连接设备列表中选定需要通信的对端设备。
2.
调用 [getP2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [P2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
3.
构造对端应用参数 [P2pAppParam](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
4.
构造接收到对端传来消息后的回调函数 [Callback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/其他/js-apis-base.md) 。
5.
调用 [registerMessageReceiver](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，订阅监听消息接收事件。
```typescript
// 步骤2 获取P2pClient对象
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
// 步骤3 构造对端应用参数
let appInfo: wearEngine.AppInfo = {
  bundleName: '',
  fingerprint: ''
};
// 将对端应用参数类定义为appParam
let appParam: wearEngine.P2pAppParam = {
  remoteApp: appInfo
};
// 步骤4 构造回调函数
let callback = (p2pMessage: wearEngine.P2pMessage) => {
  console.info(`Succeeded in receiving message, the message is ${p2pMessage.content}.`);
};
// 步骤5 订阅监听消息接收事件
p2pClient.registerMessageReceiver(targetDevice.randomId, appParam, callback).then(() => {
  console.info(`Succeeded in registering message receiver.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to register message receiver. Code is ${error.code}, message is ${error.message}.`);
});
```
6.
调用 [unregisterMessageReceiver](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，穿戴侧应用取消接收对端应用发过来的消息，需要传入订阅监听时的同一个回调函数对象。
```typescript
p2pClient.unregisterMessageReceiver(targetDevice.randomId, appParam, callback).then(() => {
  console.info(`Succeeded in unregistering message receiver.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to unregister message receiver. Code is ${error.code}, message is ${error.message}.`);
});
```
#### 订阅接收对端应用发送来的文件
1.
参见 [已连接对端设备查询](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/穿戴侧应用开发/已连接对端设备查询/watch_query_connected_devices.md) 章节，从已连接设备列表中选定需要通信的对端设备。
2.
调用 [getP2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [P2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
3.
构造设备侧应用参数 [P2pAppParam](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
4.
构造接收到设备侧传来文件后的回调函数 [Callback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/其他/js-apis-base.md) 。
5.
调用 [registerFileReceiver](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，订阅监听文件接收事件。
```typescript
// 步骤2 获取P2pClient对象
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
// 步骤3 构造对端应用参数
let appInfo: wearEngine.AppInfo = {
  bundleName: '',
  fingerprint: ''
};
// 将对端应用参数类定义为appParam
let appParam: wearEngine.P2pAppParam = {
  remoteApp: appInfo
};
// 步骤4 构造回调函数
let callback = (p2pMessage: wearEngine.P2pFile) => {
  console.info(`Succeeded in receiving file.`);
};
// 步骤5 订阅监听文件接收事件
p2pClient.registerFileReceiver(targetDevice.randomId, appParam, callback).then(() => {
  console.info(`Succeeded in registering file receiver.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to register file receiver. Code is ${error.code}, message is ${error.message}.`);
});
```
6.
调用 [unregisterFileReceiver](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，穿戴侧应用取消接收对端应用发过来的文件，需要传入订阅监听时的同一个回调函数对象。
```typescript
p2pClient.unregisterFileReceiver(targetDevice.randomId, appParam, callback).then(() => {
  console.info(`Succeeded in unregistering file receiver.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to unregister file receiver. Code is ${error.code}, message is ${error.message}.`);
});
```
#### 对端应用通过startRemoteApp拉起穿戴侧应用
如果对端应用通过调用startRemoteApp方法拉起穿戴侧应用时，需要在穿戴侧配置需要拉起的页面。
1.
创建名为HiWearMainAbility.ets的文件，需继承UIAbility，重写onWindowStageCreate函数，配置要跳转的界面。
```typescript
// 必须继承UIAbility
import hilog from '@ohos.hilog';
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
/**
 * 对端应用通过startRemoteApp方法拉起穿戴侧应用的HiWearMainAbility
 */
export default class HiWearMainAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'HiWearMainAbility', '%{public}s', 'Ability onWindowStageCreate');
    // 配置要跳转的界面为”XXXPage”
    windowStage.loadContent('pages/XXXPage', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'HiWearMainAbility', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'HiWearMainAbility', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }
}
```
2.
在module.json5中的abilities中配置HiWearMainAbility。更多配置详情参考 [abilities标签](D:/code/APIDevice/output/md_output/harmonyos-guides/基础入门/开发基础知识/应用配置文件/module.json5配置文件/module-configuration-file.md) 。
- 配置name为HiWearMainAbility。
- 配置srcEntry为HiWearMainAbility.ets文件的路径。
- 配置startWindowIcon为标识当前UIAbility组件启动页面图标资源文件的索引。
-
```typescript
"module": {
  "name": "xxxx",
  "type": "entry",
  "description": "xxxx",
  "mainElement": "xxxx",
  "deviceTypes": [],
  "pages": "xxxx",
  "abilities": [
  {
  "name": "HiWearMainAbility",
  "srcEntry": "xxxx",
  "startWindowIcon": "xxxx", // 标识当前UIAbility组件启动页面图标资源文件的索引
  "startWindowBackground": "xxxx" // 标识当前UIAbility组件启动页面背景颜色资源文件的索引
  }],
  "metadata": []
  }
```
3.
在module.json5中的metadata中配置对端应用包名、待拉起的Ability名称，以及是否要等待穿戴侧完成订阅消息接收或者文件接收。
- 对端应用包名配置时，name为wearEngineRemoteAppNameList，value为具体的对端应用包名，如果存在多个应用包名，使用英文逗号隔开，value值最长不超过4KB；
- Ability名称配置时，name为wearEngineUIAbilityName，value为指定要拉起的UIAbility名称，不配置默认拉起HiWearMainAbility；
-
```typescript
"module": {
  "name": "xxxx",
  "type": "entry",
  "description": "xxxx",
  "mainElement": "xxxx",
  "deviceTypes": [],
  "pages": "xxxx",
  "abilities": [],
  "metadata": [ // 配置如下信息
      {
        "name": "wearEngineRemoteAppNameList",
        "value": "xxxx1,xxxx2,xxxx3"
      },
      {
        "name": "wearEngineUIAbilityName",
        "value": "xxxx"
      },
      {
        "name": "wearEngineAwaitRegisterReceiver",
        "value": "true"
      }
  ]}
```
#### 穿戴侧应用拉起对端设备侧应用
1.
参见 [已连接对端设备查询](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/穿戴侧应用开发/已连接对端设备查询/watch_query_connected_devices.md) 章节，从已连接设备列表中选定需要通信的对端设备。
2.
构造对端应用参数 [remoteAppInfo](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
3.
构造需要拉起对端应用的参数 [startConfig](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 。
4.
调用 [getP2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [P2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
5.
调用 [startRemoteApp](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，指定需要拉起对端侧应用包名和对端侧应用的服务类型与名称。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4b/v3/29YAMzmpT4CKyeKI2PfEZw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104933Z&HW-CC-Expire=86400&HW-CC-Sign=730645379E147D70E87D6AD2655E56E704AFB7DCDAEF7D1044FE4634FDCBFC8C)
该接口的调用需要在开发者联盟申请拉起已配对设备的指定应用权限（请参考 [申请接入Wear Engine服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/接入准备/申请接入Wear Engine服务/wearengine_apply.md) ）。
```typescript
// 步骤2 构造对端应用参数
let remoteAppInfo: wearEngine.AppInfo = {
  // 设置对端应用的应用信息：包名与指纹
  bundleName: 'xxx',
  fingerprint: 'xxx'
}
// 步骤3 构造需要拉起对端应用的组件类型
let startConfig: wearEngine.StartConfig = {
   entryType: wearEngine.EntryType.DISTRIBUTED_SERVICE,
   entryName: 'xxx'
 };
// 步骤4 获取P2pClient对象
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
// 步骤5 拉起对端指定应用
p2pClient.startRemoteApp(targetDevice.randomId, remoteAppInfo, startConfig).then((p2pResult) => {
  console.info(`Succeeded in starting remote app, result is ${p2pResult.code}.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to start remote app. Code is ${error.code}, message is ${error.message}.`);
})
```
#### 穿戴设备侧应用获取对端设备侧应用的版本号
1.
参见 [已连接穿戴设备查询](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/应用开发/已连接穿戴设备查询/query_connected_devices.md) 章节，获取已连接设备列表。
2.
调用wearEngine中的 [getP2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取 [P2pClient](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 对象。
3.
调用 [getRemoteAppVersion](D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md) 方法，获取指定设备对应的应用版本号。
```typescript
// 构造对端应用参数
let remoteBundleName: string = 'xxx';
// 步骤2 获取P2pClient对象
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
// 步骤3 获取指定设备应用对应的版本号
p2pClient.getRemoteAppVersion(targetDevice.randomId, remoteBundleName).then((version) => {
  console.info(`Succeeded in getting remote app version, version is ${version}.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to check get remote app version. Code is ${error.code}, message is ${error.message}.`);
})
```