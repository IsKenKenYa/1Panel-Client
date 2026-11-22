# @ohos.net.socket (Socket连接)
---
# @ohos.net.socket (Socket连接)
本模块提供利用Socket进行数据传输的能力，支持TCPSocket、UDPSocket、WebSocket和TLSSocket。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4d/v3/iLbb7RGORm6DR9OVajIkrw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=5FB3AEDA57B0ED6F38A15F2F75DA0EB132BEE5DD0E6E3F86788329EE96733FC2)
本模块首批接口从API version 7开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。
本模块API使用时建议放在worker线程或者taskpool中做网络操作，否则可能会导致UI线程卡顿。
#### 导入模块
```
import { socket } from '@kit.NetworkKit';
```
#### socket.constructUDPSocketInstance
constructUDPSocketInstance(): UDPSocket
创建一个UDPSocket对象。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [UDPSocket](#udpsocket) | 返回一个UDPSocket对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
```
#### UDPSocket
UDPSocket连接。在调用UDPSocket的方法前，需要先通过 [socket.constructUDPSocketInstance](#socketconstructudpsocketinstance) 创建UDPSocket对象。
#### bind
bind(address: NetAddress, callback: AsyncCallback<void>): void
绑定IP地址和端口，端口可以由用户指定或由系统随机分配。使用callback异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 是 | 本端地址信息，参考[NetAddress](#netaddress)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。成功返回空，失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',  // 本端地址
  port: 1234
}
udp.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
```
#### bind
bind(address: NetAddress): Promise<void>
绑定IP地址和端口，端口可以由用户指定或由系统随机分配。使用Promise异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 是 | 本端地址信息，参考[NetAddress](#netaddress)。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',  // 本端地址
  port: 8080
}
udp.bind(bindAddr).then(() => {
  console.info('bind success');
}).catch((err: BusinessError) => {
  console.error('bind fail');
});
```
#### send
send(options: UDPSendOptions, callback: AsyncCallback<void>): void
通过UDPSocket连接发送数据。使用callback异步回调。
发送数据前，需要先调用 [UDPSocket.bind()](#bind) 绑定IP地址和端口。该接口为耗时操作，请在Worker线程或taskpool线程调用该接口。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [UDPSendOptions](#udpsendoptions) | 是 | UDPSocket发送参数，参考[UDPSendOptions](#udpsendoptions)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。成功返回空，失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2301206 | Socks5 failed to connect to the proxy server. |
| 2301207 | Socks5 username or password is invalid. |
| 2301208 | Socks5 failed to connect to the remote server. |
| 2301209 | Socks5 failed to negotiate the authentication method. |
| 2301210 | Socks5 failed to send the message. |
| 2301211 | Socks5 failed to receive the message. |
| 2301212 | Socks5 serialization error. |
| 2301213 | Socks5 deserialization error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',  // 本端地址
  port: 1234
}
udp.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',  // 对端地址
  port: 8080
}
let sendOptions: socket.UDPSendOptions = {
  data: 'Hello, server!',
  address: netAddress
}
udp.send(sendOptions, (err: BusinessError) => {
  if (err) {
    console.error('send fail');
    return;
  }
  console.info('send success');
});
```
**示例（设置socket代理）：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',  // 本端地址
  port: 1234
}
udp.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',  // 对端地址
  port: 8080
}
let socks5Server: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let proxyOptions: socket.ProxyOptions = {
  type : 1,
  address: socks5Server,
  username: "xxx",
  password: "xxx"
}
let sendOptions: socket.UDPSendOptions = {
  data: 'Hello, server!',
  address: netAddress,
  proxy: proxyOptions,
}
udp.send(sendOptions, (err: BusinessError) => {
  if (err) {
    console.error('send fail');
    return;
  }
  console.info('send success');
});
```
#### send
send(options: UDPSendOptions): Promise<void>
通过UDPSocket连接发送数据。使用Promise异步回调。
发送数据前，需要先调用 [UDPSocket.bind()](#bind) 绑定IP地址和端口。该接口为耗时操作，请在Worker线程或taskpool线程调用该接口。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [UDPSendOptions](#udpsendoptions) | 是 | UDPSocket发送参数，参考[UDPSendOptions](#udpsendoptions)。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2301206 | Socks5 failed to connect to the proxy server. |
| 2301207 | Socks5 username or password is invalid. |
| 2301208 | Socks5 failed to connect to the remote server. |
| 2301209 | Socks5 failed to negotiate the authentication method. |
| 2301210 | Socks5 failed to send the message. |
| 2301211 | Socks5 failed to receive the message. |
| 2301212 | Socks5 serialization error. |
| 2301213 | Socks5 deserialization error. |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx', // 本端地址
  port: 8080
}
udp.bind(bindAddr).then(() => {
  console.info('bind success');
}).catch((err: BusinessError) => {
  console.error('bind fail');
  return;
});
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx', // 对端地址
  port: 8080
}
let sendOptions: socket.UDPSendOptions = {
  data: 'Hello, server!',
  address: netAddress
}
udp.send(sendOptions).then(() => {
  console.info('send success');
}).catch((err: BusinessError) => {
  console.error('send fail');
});
```
**示例（设置socket代理）：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx', // 本端地址
  port: 8080
}
udp.bind(bindAddr).then(() => {
  console.info('bind success');
}).catch((err: BusinessError) => {
  console.error('bind fail');
  return;
});
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx', // 对端地址
  port: 8080
}
let socks5Server: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let proxyOptions: socket.ProxyOptions = {
  type : 1,
  address: socks5Server,
  username: "xxx",
  password: "xxx"
}
let sendOptions: socket.UDPSendOptions = {
  data: 'Hello, server!',
  address: netAddress,
  proxy: proxyOptions,
}
udp.send(sendOptions).then(() => {
  console.info('send success');
}).catch((err: BusinessError) => {
  console.error('send fail');
});
```
#### close
close(callback: AsyncCallback<void>): void
关闭UDPSocket连接。使用callback异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<void> | 是 | 回调函数。关闭UDPSocket连接后触发回调函数。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
udp.close((err: BusinessError) => {
  if (err) {
    console.error('close fail');
    return;
  }
  console.info('close success');
})
```
#### close
close(): Promise<void>
关闭UDPSocket连接。使用Promise异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
udp.close().then(() => {
  console.info('close success');
}).catch((err: BusinessError) => {
  console.error('close fail');
});
```
#### getState
getState(callback: AsyncCallback<SocketStateBase>): void
获取UDPSocket状态。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c0/v3/3j4cbwV4S1yZ85BePZC6lw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=F07E58CCF3F873030861561131A1D3327D0B3E52673D673E9C79ACF1205BB3C2)
bind方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[SocketStateBase](#socketstatebase)> | 是 | 回调函数。成功返回UDPSocket状态信息，失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
udp.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.error('bind success');
  udp.getState((err: BusinessError, data: socket.SocketStateBase) => {
    if (err) {
      console.error('getState fail');
      return;
    }
    console.info('getState success:' + JSON.stringify(data));
  })
})
```
#### getState
getState(): Promise<SocketStateBase>
获取UDPSocket状态。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/94/v3/Pm3pn2FVT-eTSQEqyUzH-w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=AC53DF99702089E069BF803499C6486EA40E33C40BD547872D654C90711EDB11)
bind方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SocketStateBase](#socketstatebase)> | 以Promise形式返回获取UDPSocket状态的结果。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
udp.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
  udp.getState().then((data: socket.SocketStateBase) => {
    console.info('getState success:' + JSON.stringify(data));
  }).catch((err: BusinessError) => {
    console.error('getState fail' + JSON.stringify(err));
  });
});
```
#### setExtraOptions
setExtraOptions(options: UDPExtraOptions, callback: AsyncCallback<void>): void
设置UDPSocket连接的其他属性。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f4/v3/gc1_ypoyQ7KcmE-_pEXlYQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=6082B7C0C035B39470C641C8BFE0E546D224552EEE74202AB1C312C1F1DCAC48)
bind方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [UDPExtraOptions](#udpextraoptions) | 是 | UDPSocket连接的其他属性，参考[UDPExtraOptions](#udpextraoptions)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。成功返回空，失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
udp.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
  let udpextraoptions: socket.UDPExtraOptions = {
    receiveBufferSize: 8192,
    sendBufferSize: 8192,
    reuseAddress: false,
    socketTimeout: 6000,
    broadcast: true
  }
  udp.setExtraOptions(udpextraoptions, (err: BusinessError) => {
    if (err) {
      console.error('setExtraOptions fail');
      return;
    }
    console.info('setExtraOptions success');
  })
})
```
#### setExtraOptions
setExtraOptions(options: UDPExtraOptions): Promise<void>
设置UDPSocket连接的其他属性。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/3b/v3/AAL7BSm2Stq4DslNd_cV0g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=F48A7B36AB58BFEFD899A179970228650A276147A8A8124E6000DC410820A049)
bind方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [UDPExtraOptions](#udpextraoptions) | 是 | UDPSocket连接的其他属性，参考[UDPExtraOptions](#udpextraoptions)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
udp.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
  let udpextraoptions: socket.UDPExtraOptions = {
    receiveBufferSize: 8192,
    sendBufferSize: 8192,
    reuseAddress: false,
    socketTimeout: 6000,
    broadcast: true
  }
  udp.setExtraOptions(udpextraoptions).then(() => {
    console.info('setExtraOptions success');
  }).catch((err: BusinessError) => {
    console.error('setExtraOptions fail');
  });
})
```
#### getLocalAddress12+
getLocalAddress(): Promise<NetAddress>
获取UDP连接的本地Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f8/v3/rcbLU1YZSaChg1ZeG3e7mg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=FD34AF0B56BDA4A8BCA70B1CCE06F7D6CEE4E22C0148B0250E8CD3FC75682201)
bind方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
udp.bind(bindAddr).then(() => {
  console.info('bind success');
  udp.getLocalAddress().then((localAddress: socket.NetAddress) => {
        console.info("UDP_Socket get SUCCESS! Address：" + JSON.stringify(localAddress));
      }).catch((err: BusinessError) => {
        console.error("UDP_Socket get FAILED! Error: " + JSON.stringify(err));
      })
}).catch((err: BusinessError) => {
  console.error('bind fail');
});
```
#### on('message')
on(type: 'message', callback: Callback<SocketMessageInfo>): void
订阅UDPSocket连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 是 | 回调函数。返回订阅某类事件后UDPSocket连接成功的状态信息。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
udp.on('message', (value: socket.SocketMessageInfo) => {
  let messageView = '';
  let uint8Array = new Uint8Array(value.message);
  for (let i: number = 0; i < value.message.byteLength; i++) {
    let messages = uint8Array[i];
    let message = String.fromCharCode(messages);
    messageView += message;
  }
  console.info('on message message: ' + JSON.stringify(messageView));
  console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
});
```
#### off('message')
off(type: 'message', callback?: Callback<SocketMessageInfo>): void
取消订阅UDPSocket连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let messageView = '';
let callback = (value: socket.SocketMessageInfo) => {
  for (let i: number = 0; i < value.message.byteLength; i++) {
    let uint8Array = new Uint8Array(value.message)
    let messages = uint8Array[i]
    let message = String.fromCharCode(messages);
    messageView += message;
  }
  console.info('on message message: ' + JSON.stringify(messageView));
  console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
}
udp.on('message', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
udp.off('message', callback);
udp.off('message');
```
#### on('listening' | 'close')
on(type: 'listening' | 'close', callback: Callback<void>): void
订阅UDPSocket连接的数据包消息事件或关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。- 'listening'：数据包消息事件。- 'close'：关闭事件。 |
| callback | Callback<void> | 是 | 回调函数。UDPSocket连接的某类数据包消息事件或关闭事件发生变化后触发回调函数。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
udp.on('listening', () => {
  console.info("on listening success");
});
udp.on('close', () => {
  console.info("on close success");
});
```
#### off('listening' | 'close')
off(type: 'listening' | 'close', callback?: Callback<void>): void
取消订阅UDPSocket连接的数据包消息事件或关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅事件类型。- 'listening'：数据包消息事件。- 'close'：关闭事件。 |
| callback | Callback<void> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let callback1 = () => {
  console.info("on listening, success");
}
udp.on('listening', callback1);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
udp.off('listening', callback1);
udp.off('listening');
let callback2 = () => {
  console.info("on close, success");
}
udp.on('close', callback2);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
udp.off('close', callback2);
udp.off('close');
```
#### on('error')
on(type: 'error', callback: ErrorCallback): void
订阅UDPSocket连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 回调函数。UDPSocket连接发生error事件后触发回调函数。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
udp.on('error', (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err))
});
```
#### off('error')
off(type: 'error', callback?: ErrorCallback): void
取消订阅UDPSocket连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
let callback = (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err));
}
udp.on('error', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
udp.off('error', callback);
udp.off('error');
```
#### NetAddress
目标地址信息。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| address11+ | string | 否 | 否 | 本地绑定的ip地址。 |
| port | number | 否 | 否 | 端口号 ，范围0~65535。如果不指定系统随机分配端口。 |
| family | number | 否 | 否 | 网络协议类型，可选类型：- 1：IPv4。默认为1。- 2：IPv6。地址为IPV6类型，该字段必须被显式指定为2。- 3：Domain18+。地址为Domain类型，该字段必须被显式指定为3。当前仅支持[TCPSocket.connect](#connect)和[TLSSocket.connect](#connect9)。 |
#### ProxyOptions18+
Socket代理信息。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| type | [ProxyTypes](#proxytypes18) | 否 | 否 | 代理类型。 |
| address | [NetAddress](#netaddress) | 否 | 否 | 代理地址信息。 |
| username | string | 否 | 是 | 指定用户名，如果使用用户密码验证方式。 |
| password | string | 否 | 是 | 指定密码，如果使用用户密码验证方式。 |
#### ProxyTypes18+
Socket代理类型。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 值 | 说明 |
| --- | --- | --- |
| NONE | 0 | 不使用代理。 |
| SOCKS5 | 1 | 使用Socks5代理。 |
#### UDPSendOptions
UDPSocket发送参数。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| data | string | ArrayBuffer | 否 | 否 | 发送的数据。 |
| address | [NetAddress](#netaddress) | 否 | 否 | 目标地址信息。 |
| proxy18+ | [ProxyOptions](#proxyoptions18) | 否 | 是 | 使用的代理信息，默认不使用代理。 |
#### UDPExtraOptions
UDPSocket连接的其他属性。继承自 [ExtraOptionsBase](#extraoptionsbase) 。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| broadcast | boolean | 否 | 是 | 是否可以发送广播。true表示可发送广播，false表示不可发送广播。默认为false。 |
#### SocketMessageInfo11+
socket连接信息
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| message | ArrayBuffer | 否 | 否 | 接收的事件消息。 |
| remoteInfo | [SocketRemoteInfo](#socketremoteinfo) | 否 | 否 | socket连接信息。 |
#### SocketStateBase
Socket的状态信息。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| isBound | boolean | 否 | 否 | 是否绑定。true：绑定；false：不绑定。 |
| isClose | boolean | 否 | 否 | 是否关闭。true：关闭；false：打开。 |
| isConnected | boolean | 否 | 否 | 是否连接。true：连接；false：断开。 |
#### SocketRemoteInfo
Socket的连接信息。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| address | string | 否 | 否 | 本地绑定的ip地址。 |
| family | 'IPv4' | 'IPv6' | 否 | 否 | 网络协议类型，可选类型：- IPv4- IPv6默认为IPv4。 |
| port | number | 否 | 否 | 端口号，范围0~65535。 |
| size | number | 否 | 否 | 服务器响应信息的字节长度。 |
#### UDP 错误码说明
UDP 其余错误码映射形式为：2301000 + Linux内核错误码。
错误码的详细介绍参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
#### socket.constructMulticastSocketInstance11+
constructMulticastSocketInstance(): MulticastSocket
创建一个MulticastSocket对象。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [MulticastSocket](#multicastsocket11) | 返回一个MulticastSocket对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
```
#### MulticastSocket11+
MulticastSocket连接。在调用MulticastSocket的方法前，需要先通过 [socket.constructMulticastSocketInstance](#socketconstructmulticastsocketinstance11) 创建MulticastSocket对象。
#### addMembership11+
addMembership(multicastAddress: NetAddress, callback: AsyncCallback<void>): void
加入多播组。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/J5eC--dZTY2d5soNLvmQzw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=B3EA255019CA453A58E957875390DACB88659463DEE67FD199BC7A84BE01EA87)
多播使用的IP地址属于特定的范围（例如224.0.0.0到239.255.255.255）。
加入多播组后，既可以是发送端，也可以是接收端，相互之间以广播的形式传递数据，不区分客户端或服务端。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| multicastAddress | [NetAddress](#netaddress) | 是 | 目标地址信息，参考[NetAddress](#netaddress)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2301022 | Invalid argument. |
| 2301088 | Not a socket. |
| 2301098 | Address in use. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
let addr: socket.NetAddress = {
  address: '239.255.0.1',
  port: 8080
}
multicast.addMembership(addr, (err: Object) => {
  if (err) {
    console.error('add membership fail, err: ' + JSON.stringify(err));
    return;
  }
  console.info('add membership success');
})
```
#### addMembership11+
addMembership(multicastAddress: NetAddress): Promise<void>
加入多播组。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b4/v3/b3KmW8ioQoixhzR0JGKiuw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=2DBF7251C3717A42C68CCF2C24D2E486E2936CFD5113C56967492AFEE5EC0988)
多播使用的IP地址属于特定的范围（例如224.0.0.0到239.255.255.255）。
加入多播组后，既可以是发送端，也可以是接收端，相互之间以广播的形式传递数据，不区分客户端或服务端。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| multicastAddress | [NetAddress](#netaddress) | 是 | 目标地址信息，参考[NetAddress](#netaddress)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回MulticastSocket加入多播组的行为结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2301088 | Not a socket. |
| 2301098 | Address in use. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
let addr: socket.NetAddress = {
  address: '239.255.0.1',
  port: 8080
}
multicast.addMembership(addr).then(() => {
  console.info('addMembership success');
}).catch((err: Object) => {
  console.error('addMembership fail');
});
```
#### dropMembership11+
dropMembership(multicastAddress: NetAddress, callback: AsyncCallback<void>): void
退出多播组。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/01/v3/vUxlaYd2RM6AgwHZJxkaKg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=01437DF4E5FAB716421C3F350A9FD02D713D76F9FE0E2799869561A269789E83)
多播使用的IP地址属于特定的范围（例如224.0.0.0到239.255.255.255）。
从已加入的多播组中退出，必须在加入多播组 [addMembership](#addmembership11) 之后退出才有效。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| multicastAddress | [NetAddress](#netaddress) | 是 | 目标地址信息，参考[NetAddress](#netaddress)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2301088 | Not a socket. |
| 2301098 | Address in use. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
let addr: socket.NetAddress = {
  address: '239.255.0.1',
  port: 8080
}
multicast.dropMembership(addr, (err: Object) => {
  if (err) {
    console.error('drop membership fail, err: ' + JSON.stringify(err));
    return;
  }
  console.info('drop membership success');
})
```
#### dropMembership11+
dropMembership(multicastAddress: NetAddress): Promise<void>
退出多播组。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/8d/v3/nTFjy1_wSeKtgo8UuqkIxQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=D31304A43A5FAD58BF42079C8CC4F086E2893B6EE4F71F7767434B2560226E4D)
多播使用的IP地址属于特定的范围（例如224.0.0.0到239.255.255.255）。
从已加入的多播组中退出，必须在加入多播组 [addMembership](#addmembership11) 之后退出才有效。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| multicastAddress | [NetAddress](#netaddress) | 是 | 目标地址信息，参考[NetAddress](#netaddress)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回MulticastSocket加入多播组的执行结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2301088 | Not a socket. |
| 2301098 | Address in use. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
let addr: socket.NetAddress = {
  address: '239.255.0.1',
  port: 8080
}
multicast.dropMembership(addr).then(() => {
  console.info('drop membership success');
}).catch((err: Object) => {
  console.error('drop membership fail');
});
```
#### setMulticastTTL11+
setMulticastTTL(ttl: number, callback: AsyncCallback<void>): void
设置多播通信时数据包在网络传输过程中路由器最大跳数。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fc/v3/YCDAR7T6Q1O9LNmrJ1isEQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=CA5E183D7AE80766F26A3FE4DFE6FDED2911E2F8DDE07AFEF92E48D3F6532B4E)
用于限制数据包在网络中传输时能够经过的最大路由器跳数的字段，TTL (Time to live)。
范围为 0～255，默认值为 1 。
如果一个多播数据包的 TTL 值为 1，那么它只能被直接连接到发送者的主机接收。如果 TTL 被设置为一个较大的值，那么数据包就能够被传送到更远的网络范围内。
在调用 [addMembership](#addmembership11) 之后，调用此接口才有效。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| ttl | number | 是 | ttl设置数值，类型为数字number。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301022 | Invalid argument. |
| 2301088 | Not a socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
let ttl = 8
multicast.setMulticastTTL(ttl, (err: Object) => {
  if (err) {
    console.error('set ttl fail, err: ' + JSON.stringify(err));
    return;
  }
  console.info('set ttl success');
})
```
#### setMulticastTTL11+
setMulticastTTL(ttl: number): Promise<void>
设置多播通信时数据包在网络传输过程中路由器最大跳数。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/65/v3/SWKP5498QoKz-mqjWiJTkg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=0C0AAD5EA26E7A084430397D5F55687F77E056C75A3CD5203CCEC55016A63380)
用于限制数据包在网络中传输时能够经过的最大路由器跳数的字段，TTL (Time to live)。
范围为 0～255，默认值为 1 。
如果一个多播数据包的 TTL 值为 1，那么它只能被直接连接到发送者的主机接收。如果 TTL 被设置为一个较大的值，那么数据包就能够被传送到更远的网络范围内。
在调用 [addMembership](#addmembership11) 之后，调用此接口才有效。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| ttl | number | 是 | ttl设置数值，类型为数字Number。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回MulticastSocket设置TTL数值的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301022 | Invalid argument. |
| 2301088 | Not a socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
multicast.setMulticastTTL(8).then(() => {
  console.info('set ttl success');
}).catch((err: Object) => {
  console.error('set ttl failed');
});
```
#### getMulticastTTL11+
getMulticastTTL(callback: AsyncCallback<number>): void
获取数据包在网络传输过程中路由器最大跳数(TTL)的值。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6d/v3/1h3OxVO9Q4q01w2fLfBRKw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=F1516763D898AC70D0FE91D87AF943E578EE6A215F9746E6004557035DF403D8)
用于限制数据包在网络中传输时能够经过的最大路由器跳数的字段，TTL (Time to live)。
范围为 0～255，默认值为 1 。
如果一个多播数据包的 TTL 值为 1，那么它只能被直接连接到发送者的主机接收。如果 TTL 被设置为一个较大的值，那么数据包就能够被传送到更远的网络范围内。
在调用 [addMembership](#addmembership11) 之后，调用此接口才有效。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<number> | 是 | 回调函数。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301088 | Not a socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
multicast.getMulticastTTL((err: Object, value: Number) => {
  if (err) {
    console.error('set ttl fail, err: ' + JSON.stringify(err));
    return;
  }
  console.info('set ttl success, value: ' + JSON.stringify(value));
})
```
#### getMulticastTTL11+
getMulticastTTL(): Promise<number>
获取数据包在网络传输过程中路由器最大跳数(TTL)的值。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/39/v3/ubVH7J3OR4m57QkKKPcw3A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=1DB12E347D0F48AB0DDBEB1882DB26FB8A4D876C3B506F99F668F38B376E8C26)
用于限制数据包在网络中传输时能够经过的最大路由器跳数的字段，TTL (Time to live)。
范围为 0～255，默认值为 1 。
如果一个多播数据包的 TTL 值为 1，那么它只能被直接连接到发送者的主机接收。如果 TTL 被设置为一个较大的值，那么数据包就能够被传送到更远的网络范围内。
在调用 [addMembership](#addmembership11) 之后，调用此接口才有效。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<number> | 以Promise形式返回当前TTL数值。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301088 | Not a socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
multicast.getMulticastTTL().then((value: Number) => {
  console.info('ttl: ', JSON.stringify(value));
}).catch((err: Object) => {
  console.error('set ttl failed');
});
```
#### setLoopbackMode11+
setLoopbackMode(flag: boolean, callback: AsyncCallback<void>): void
设置多播通信中的环回模式标志位。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fd/v3/vPEahy-ORAysfsYbi0IbLA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=216D9329F69BDB94A543470D127F661213353D6468AB969EF20A0642F5CDA9E1)
用于设置环回模式，开启或关闭两种状态，默认为开启状态。
如果一个多播通信中环回模式设置值为 true，那么它允许主机在本地循环接收自己发送的多播数据包。如果为 false，则主机不会接收到自己发送的多播数据包。
在调用 [addMembership](#addmembership11) 之后，调用此接口才有效。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| flag | boolean | 是 | 是否开启环回模式。true表示环回模式开启，false表示环回模式关闭。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301088 | Not a socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
multicast.setLoopbackMode(false, (err: Object) => {
  if (err) {
    console.error('set loopback mode fail, err: ' + JSON.stringify(err));
    return;
  }
  console.info('set loopback mode success');
})
```
#### setLoopbackMode11+
setLoopbackMode(flag: boolean): Promise<void>
设置多播通信中的环回模式标志位。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/43/v3/EopxR7XWS7ScFJHBZIfXgA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=A906805C45C455CDBEF1480515DB09D23BD0C701C8C995D38407F55125024927)
用于设置环回模式，开启或关闭两种状态，默认为开启状态。
如果一个多播通信中环回模式设置值为 true，那么它允许主机在本地循环接收自己发送的多播数据包。如果为 false，则主机不会接收到自己发送的多播数据包。
在调用 [addMembership](#addmembership11) 之后，调用此接口才有效。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| flag | boolean | 是 | 是否开启环回模式。true表示环回模式开启，false表示环回模式关闭。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回MulticastSocket设置环回模式的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301088 | Not a socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
multicast.setLoopbackMode(false).then(() => {
  console.info('set loopback mode success');
}).catch((err: Object) => {
  console.error('set loopback mode failed');
});
```
#### getLoopbackMode11+
getLoopbackMode(callback: AsyncCallback<boolean>): void
获取多播通信中的环回模式状态。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c4/v3/FK5va-H_RDaC3tzIZf-Jiw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=BB550DAA3D5263B901F0E8CC152815A8BA18B56457473DB3FAFBD9CE15BDDAFC)
用于获取当前环回模式开启或关闭的状态。
如果获取的属性值为 true，表示环回模式是开启的状态，允许主机在本地循环接收自己发送的多播数据包。如果为 false，则表示环回模式是关闭的状态，主机不会接收到自己发送的多播数据包。
在调用 [addMembership](#addmembership11) 之后，调用此接口才有效。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<boolean> | 是 | 回调函数。返回值为环回模式状态，true表示环回模式开启，false表示环回模式关闭。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301088 | Not a socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
multicast.getLoopbackMode((err: Object, value: Boolean) => {
  if (err) {
    console.error('get loopback mode fail, err: ' + JSON.stringify(err));
    return;
  }
  console.info('get loopback mode success, value: ' + JSON.stringify(value));
})
```
#### getLoopbackMode11+
getLoopbackMode(): Promise<boolean>
获取多播通信中的环回模式状态。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/db/v3/jTtmyw-DSka_LWehrgW2RA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=DC83B0C97301E9E33A82070513FB7666735878863577A026EA782A5E948FF993)
用于获取当前环回模式开启或关闭的状态。
如果获取的属性值为 true，表示环回模式是开启的状态，允许主机在本地循环接收自己发送的多播数据包。如果为 false，则表示环回模式是关闭的状态，主机不会接收到自己发送的多播数据包。
在调用 [addMembership](#addmembership11) 之后，调用此接口才有效。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<boolean> | Promise对象。返回true表示环回模式开启，返回false表示环回模式关闭。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301088 | Not a socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
multicast.getLoopbackMode().then((value: Boolean) => {
  console.info('loopback mode: ', JSON.stringify(value));
}).catch((err: Object) => {
  console.error('get loopback mode failed');
});
```
#### socket.constructTCPSocketInstance
constructTCPSocketInstance(): TCPSocket
创建一个TCPSocket对象。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [TCPSocket](#tcpsocket) | 返回一个TCPSocket对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
```
#### TCPSocket
TCPSocket连接。在调用TCPSocket的方法前，需要先通过 [socket.constructTCPSocketInstance](#socketconstructtcpsocketinstance) 创建TCPSocket对象。
#### bind
bind(address: NetAddress, callback: AsyncCallback<void>): void
绑定IP地址和端口，端口可以指定为0由系统随机分配或由用户指定为其它非0端口。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/dc/v3/7KnPgeKsRwC42eTDRyP2Yw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=3FBD09C804CA25B822EE984B20E7102493948B58EF600C114C6BCEE61EC6430B)
bind方法如果因为端口冲突而执行失败，则会由系统随机分配端口号。
TCP客户端可先调用该接口(tcp.bind)显式绑定IP地址和端口号，再调用tcp.connect完成与服务端的连接；也可直接调用tcp.connect由系统自动绑定IP地址和端口号，完成与服务端的连接。
bind的IP为'localhost'或'127.0.0.1'时，只允许本地回环接口的连接，即服务端和客户端运行在同一台机器上。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 是 | 本端地址信息，参考[NetAddress](#netaddress)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败返回错误、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tcp.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
})
```
#### bind
bind(address: NetAddress): Promise<void>
绑定IP地址和端口，端口可以指定为0由系统随机分配或由用户指定为其它非0端口。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/54/v3/dPHciII8Sbe1NL5DVbLL-w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=B2CFCD821360416BF5638A38AACC0D49F0BCE6156E4E2EE20BF621A62758DA2B)
bind方法如果因为端口冲突而执行失败，则会由系统随机分配端口号。
TCP客户端可先调用该接口(tcp.bind)显式绑定IP地址和端口号，再调用tcp.connect完成与服务端的连接；也可直接调用tcp.connect由系统自动绑定IP地址和端口号，完成与服务端的连接。
bind的IP为'localhost'或'127.0.0.1'时，只允许本地回环接口的连接，即服务端和客户端运行在同一台机器上。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 是 | 本端地址信息，参考[NetAddress](#netaddress)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回TCPSocket绑定本机的IP地址和端口的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tcp.bind(bindAddr).then(() => {
  console.info('bind success');
}).catch((err: BusinessError) => {
  console.error('bind fail');
});
```
#### connect
connect(options: TCPConnectOptions, callback: AsyncCallback<void>): void
连接到指定的IP地址和端口。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b1/v3/kwc5zsdhTyyo06vD9Obcwg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=1B5FB772E521FAC5D1FC2C57EB56D4A83B292ABA0CAEF1303AF9D7F43AF0CC68)
在没有执行tcp.bind的情况下，也可以直接调用该接口完成与TCP服务端的连接
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPConnectOptions](#tcpconnectoptions) | 是 | TCPSocket连接的参数，参考[TCPConnectOptions](#tcpconnectoptions)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2301206 | Socks5 failed to connect to the proxy server. |
| 2301207 | Socks5 username or password is invalid. |
| 2301208 | Socks5 failed to connect to the remote server. |
| 2301209 | Socks5 failed to negotiate the authentication method. |
| 2301210 | Socks5 failed to send the message. |
| 2301211 | Socks5 failed to receive the message. |
| 2301212 | Socks5 serialization error. |
| 2301213 | Socks5 deserialization error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions, (err: BusinessError) => {
  if (err) {
    console.error('connect fail');
    return;
  }
  console.info('connect success');
})
```
**示例（设置socket代理）：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let socks5Server: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let proxyOptions: socket.ProxyOptions = {
  type : 1,
  address: socks5Server,
  username: "xxx",
  password: "xxx"
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000,
  proxy: proxyOptions,
}
tcp.connect(tcpconnectoptions, (err: BusinessError) => {
  if (err) {
    console.error('connect fail');
    return;
  }
  console.info('connect success');
})
```
#### connect
connect(options: TCPConnectOptions): Promise<void>
连接到指定的IP地址和端口。使用promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1e/v3/DFJCOb6HTDKqFQy33N_YCQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=2B6DBB52367EAB92417A94C74A3E3523A23EB73CD79E6E1ADD7A2E8DB417FB7C)
在没有执行tcp.bind的情况下，也可以直接调用该接口完成与TCP服务端的连接。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPConnectOptions](#tcpconnectoptions) | 是 | TCPSocket连接的参数，参考[TCPConnectOptions](#tcpconnectoptions)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回TCPSocket连接到指定的IP地址和端口的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2301206 | Socks5 failed to connect to the proxy server. |
| 2301207 | Socks5 username or password is invalid. |
| 2301208 | Socks5 failed to connect to the remote server. |
| 2301209 | Socks5 failed to negotiate the authentication method. |
| 2301210 | Socks5 failed to send the message. |
| 2301211 | Socks5 failed to receive the message. |
| 2301212 | Socks5 serialization error. |
| 2301213 | Socks5 deserialization error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions).then(() => {
  console.info('connect success')
}).catch((err: BusinessError) => {
  console.error('connect fail');
});
```
**示例（设置socket代理）：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let socks5Server: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let proxyOptions: socket.ProxyOptions = {
  type : 1,
  address: socks5Server,
  username: "xxx",
  password: "xxx"
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000,
  proxy: proxyOptions,
}
tcp.connect(tcpconnectoptions).then(() => {
  console.info('connect success')
}).catch((err: BusinessError) => {
  console.error('connect fail');
});
```
#### send
send(options: TCPSendOptions, callback: AsyncCallback<void>): void
通过TCPSocket连接发送数据。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/17/v3/Emxrn8Q3T--e4QzbbYnd1w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=ECBBC953B251726520FE5C4E3FB5FC42A76B1EE8CBAAA27AF15527B51A44A2E0)
connect方法调用成功后，才可调用此方法。该接口为耗时操作，请在Worker线程或taskpool线程调用该接口。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPSendOptions](#tcpsendoptions) | 是 | TCPSocket发送请求的参数，参考[TCPSendOptions](#tcpsendoptions)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions, () => {
  console.info('connect success');
  let tcpSendOptions: socket.TCPSendOptions = {
    data: 'Hello, server!'
  }
  tcp.send(tcpSendOptions, (err: BusinessError) => {
    if (err) {
      console.error('send fail');
      return;
    }
    console.info('send success');
  })
})
```
#### send
send(options: TCPSendOptions): Promise<void>
通过TCPSocket连接发送数据。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/98/v3/lVeB8RC7R3upxOaBriGn6g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=3AEF392CD578A88D3CB956EA09F37CF05DACC3B859D801A5A652B8224E861C9B)
connect方法调用成功后，才可调用此方法。该接口为耗时操作，请在Worker线程或taskpool线程调用该接口。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPSendOptions](#tcpsendoptions) | 是 | TCPSocket发送请求的参数，参考[TCPSendOptions](#tcpsendoptions)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions, () => {
  console.info('connect success');
  let tcpSendOptions: socket.TCPSendOptions = {
    data: 'Hello, server!'
  }
  tcp.send(tcpSendOptions).then(() => {
    console.info('send success');
  }).catch((err: BusinessError) => {
    console.error('send fail');
  });
})
```
#### close
close(callback: AsyncCallback<void>): void
关闭TCPSocket连接。使用callback异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<void> | 是 | 回调函数。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
tcp.close((err: BusinessError) => {
  if (err) {
    console.error('close fail');
    return;
  }
  console.info('close success');
})
```
#### close
close(): Promise<void>
关闭TCPSocket连接。使用Promise异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
tcp.close().then(() => {
  console.info('close success');
}).catch((err: BusinessError) => {
  console.error('close fail');
});
```
#### getRemoteAddress
getRemoteAddress(callback: AsyncCallback<NetAddress>): void
获取对端Socket地址。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/bf/v3/3UpP8n9ETqiVojsshzI0DA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=647506A07CE53E3A151C6213C5DADA8BC07D6F82BB354BC56417448733502162)
connect方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[NetAddress](#netaddress)> | 是 | 回调函数。成功时返回对端Socket地址，失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions, () => {
  console.info('connect success');
  tcp.getRemoteAddress((err: BusinessError, data: socket.NetAddress) => {
    if (err) {
      console.error('getRemoteAddressfail');
      return;
    }
    console.info('getRemoteAddresssuccess:' + JSON.stringify(data));
  })
});
```
#### getRemoteAddress
getRemoteAddress(): Promise<NetAddress>
获取对端Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/32/v3/dzy_9VnVSCqYOyYntKL9KA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=B8537F5E367C1FBECD36BFD7E3756F03DDE937910402B119BD63574AF86F3580)
connect方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取对端socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions).then(() => {
  console.info('connect success');
  tcp.getRemoteAddress().then(() => {
    console.info('getRemoteAddress success');
  }).catch((err: BusinessError) => {
    console.error('getRemoteAddressfail');
  });
}).catch((err: BusinessError) => {
  console.error('connect fail');
});
```
#### getState
getState(callback: AsyncCallback<SocketStateBase>): void
获取TCPSocket状态。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/39/v3/6TmeFVMVQ2Gb8B2Bm_dm8Q/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=0611EFBD8BA9772349F51E5FA21873D9E19380930A6A3A1DB36D2A68C7C7DCBE)
bind或connect方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[SocketStateBase](#socketstatebase)> | 是 | 回调函数。成功时获取TCPSocket状态，失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions, () => {
  console.info('connect success');
  tcp.getState((err: BusinessError, data: socket.SocketStateBase) => {
    if (err) {
      console.error('getState fail');
      return;
    }
    console.info('getState success:' + JSON.stringify(data));
  });
});
```
#### getState
getState(): Promise<SocketStateBase>
获取TCPSocket状态。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/90/v3/1tc5KfjMTMKYLBW0EdaXvg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=559E7F36D20A4711B8FDA9A03A63F7B8AA0FE4DB7E344F6244C9B774227E8FCF)
bind或connect方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SocketStateBase](#socketstatebase)> | 以Promise形式返回获取TCPSocket状态的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions).then(() => {
  console.info('connect success');
  tcp.getState().then(() => {
    console.info('getState success');
  }).catch((err: BusinessError) => {
    console.error('getState fail');
  });
}).catch((err: BusinessError) => {
  console.error('connect fail');
});
```
#### getSocketFd10+
getSocketFd(callback: AsyncCallback<number>): void
获取TCPSocket的文件描述符。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/25/v3/6p0nzktRT2KDVvQOgIa_8A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=36E7A493118AC0F0ED39737B10730EFCD05632EB95516BD681DB096AE7E6EAE5)
bind或connect方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<number> | 是 | 回调函数，当成功时，返回socket的文件描述符，失败时，返回undefined。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  // 绑定指定网络接口
}
tcp.bind(bindAddr)
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions)
tcp.getSocketFd((err: BusinessError, data: number) => {
  console.error("getSocketFd failed: " + err);
  console.info("socketFd: " + data);
})
```
#### getSocketFd10+
getSocketFd(): Promise<number>
获取TCPSocket的文件描述符。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/84/v3/BYB0bwPUSjqCTCn0_el66Q/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=A54C2F300B83EC6D0BBF780E93113940F99B7A1B3A36E28B71E6E43D19EFBD86)
bind或connect方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<number> | 以Promise形式返回socket的文件描述符。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let bindAddr: socket.NetAddress = {
    address: '192.168.xx.xxx',
  // 绑定指定网络接口
}
tcp.bind(bindAddr)
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions)
tcp.getSocketFd().then((data: number) => {
  console.info("socketFd: " + data);
})
```
#### setExtraOptions
setExtraOptions(options: TCPExtraOptions, callback: AsyncCallback<void>): void
设置TCPSocket连接的其他属性。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c3/v3/4fo_R_kUQ7KBYSm3A04LKQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=64D0AC7F97BEBE14D6C97EEDD10DFEF5C873CBE87976AA2FEE5F6513EC4508A9)
bind或connect方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPExtraOptions](#tcpextraoptions) | 是 | TCPSocket连接的其他属性，参考[TCPExtraOptions](#tcpextraoptions)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
interface SocketLinger {
  on: boolean;
  linger: number;
}
tcp.connect(tcpconnectoptions, () => {
  console.info('connect success');
  let tcpExtraOptions: socket.TCPExtraOptions = {
    keepAlive: true,
    OOBInline: true,
    TCPNoDelay: true,
    socketLinger: { on: true, linger: 10 } as SocketLinger,
    receiveBufferSize: 8192,
    sendBufferSize: 8192,
    reuseAddress: true,
    socketTimeout: 3000
  }
  tcp.setExtraOptions(tcpExtraOptions, (err: BusinessError) => {
    if (err) {
      console.error('setExtraOptions fail');
      return;
    }
    console.info('setExtraOptions success');
  });
});
```
#### setExtraOptions
setExtraOptions(options: TCPExtraOptions): Promise<void>
设置TCPSocket连接的其他属性。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/61/v3/KbcqXL20Q0ag1wcd9_pn-g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=70D69D922A8BFA15D875F5025F4ECE8CFC28B4F8629B5740D9347062762A6FA5)
bind或connect方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPExtraOptions](#tcpextraoptions) | 是 | TCPSocket连接的其他属性，参考[TCPExtraOptions](#tcpextraoptions)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
interface SocketLinger {
  on: boolean;
  linger: number;
}
tcp.connect(tcpconnectoptions, () => {
  console.info('connect success');
  let tcpExtraOptions: socket.TCPExtraOptions = {
    keepAlive: true,
    OOBInline: true,
    TCPNoDelay: true,
    socketLinger: { on: true, linger: 10 } as SocketLinger,
    receiveBufferSize: 8192,
    sendBufferSize: 8192,
    reuseAddress: true,
    socketTimeout: 3000
  }
  tcp.setExtraOptions(tcpExtraOptions).then(() => {
    console.info('setExtraOptions success');
  }).catch((err: BusinessError) => {
    console.error('setExtraOptions fail');
  });
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<NetAddress>
获取TCPSocket的本地Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/32/v3/c32_A6L1RS2DQkLI6XFGYg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=0D18962CAA905EFDEEFC3D222A497B2446A5B902869DBD1E65DD3CA32475E23D)
bind方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  family: 1,
  port: 8080
}
tcp.bind(bindAddr).then(() => {
  tcp.getLocalAddress().then((localAddress: socket.NetAddress) => {
    console.info("SUCCESS! Address:" + JSON.stringify(localAddress));
  }).catch((err: BusinessError) => {
    console.error("FAILED! Error:" + JSON.stringify(err));
  })
}).catch((err: BusinessError) => {
  console.error('bind fail');
});
```
#### on('message')
on(type: 'message', callback: Callback<SocketMessageInfo>): void
订阅TCPSocket连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 是 | 回调函数。返回TCPSocket连接信息。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
tcp.on('message', (value: socket.SocketMessageInfo) => {
  let messageView = '';
  let uint8Array = new Uint8Array(value.message) ;
  for (let i: number = 0; i < value.message.byteLength; i++) {
    let messages = uint8Array[i];
    let message = String.fromCharCode(messages);
    messageView += message;
  }
  console.info('on message message: ' + JSON.stringify(messageView));
  console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
});
```
#### off('message')
off(type: 'message', callback?: Callback<SocketMessageInfo>): void
取消订阅TCPSocket连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let messageView = '';
let callback = (value: socket.SocketMessageInfo) => {
  for (let i: number = 0; i < value.message.byteLength; i++) {
    let uint8Array = new Uint8Array(value.message)
    let messages = uint8Array[i]
    let message = String.fromCharCode(messages);
    messageView += message;
  }
  console.info('on message message: ' + JSON.stringify(messageView));
  console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
}
tcp.on('message', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tcp.off('message', callback);
tcp.off('message');
```
#### on('connect' | 'close')
on(type: 'connect' | 'close', callback: Callback<void>): void
订阅TCPSocket的连接事件或关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。- 'connect'：连接事件。- 'close'：关闭事件。 |
| callback | Callback<void> | 是 | 回调函数。TCPSocket的连接事件或关闭事件触发时调用回调函数。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
tcp.on('connect', () => {
  console.info("on connect success")
});
tcp.on('close', () => {
  console.info("on close success")
});
```
#### off('connect' | 'close')
off(type: 'connect' | 'close', callback?: Callback<void>): void
取消订阅TCPSocket的连接事件或关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。- 'connect'：连接事件。- 'close'：关闭事件。 |
| callback | Callback<void> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let callback1 = () => {
  console.info("on connect success");
}
tcp.on('connect', callback1);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tcp.off('connect', callback1);
tcp.off('connect');
let callback2 = () => {
  console.info("on close success");
}
tcp.on('close', callback2);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tcp.off('close', callback2);
tcp.off('close');
```
#### on('error')
on(type: 'error', callback: ErrorCallback): void
订阅TCPSocket连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 回调函数。TCPSocket连接订阅的某类error事件触发时调用回调函数。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
tcp.on('error', (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err))
});
```
#### off('error')
off(type: 'error', callback?: ErrorCallback): void
取消订阅TCPSocket连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let callback = (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err));
}
tcp.on('error', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tcp.off('error', callback);
tcp.off('error');
```
#### TCPConnectOptions
TCPSocket连接的参数。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 否 | 否 | 绑定的地址以及端口。 |
| timeout | number | 否 | 是 | 超时时间，单位毫秒（ms）。默认值为5000。 |
| proxy18+ | [ProxyOptions](#proxyoptions18) | 否 | 是 | 使用的代理信息，默认不使用代理。 |
#### TCPSendOptions
TCPSocket发送请求的参数。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| data | string| ArrayBuffer | 否 | 否 | 发送的数据。 |
| encoding | string | 否 | 是 | 字符编码(UTF-8，UTF-16BE，UTF-16LE，UTF-16，US-AECII，ISO-8859-1)，默认为UTF-8。 |
#### TCPExtraOptions
TCPSocket连接的其他属性。继承自 [ExtraOptionsBase](#extraoptionsbase) 。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| keepAlive | boolean | 否 | 是 | 是否保持连接。默认为false。true：保持连接；false：断开连接。 |
| OOBInline | boolean | 否 | 是 | 是否为OOB内联。默认为false。true：是OOB内联；false：不是OOB内联。 |
| TCPNoDelay | boolean | 否 | 是 | TCPSocket连接是否无时延。默认为false。true：无时延；false：有时延。 |
| socketLinger | {on:boolean, linger:number} | 否 | 是 | socket是否继续逗留。- on：是否逗留（true：逗留；false：不逗留）。- linger：逗留时长，单位毫秒（ms），取值范围为0~65535。当入参on设置为true时，才需要设置。 |
#### socket.constructTCPSocketServerInstance10+
constructTCPSocketServerInstance(): TCPSocketServer
创建一个TCPSocketServer对象。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [TCPSocketServer](#tcpsocketserver10) | 返回一个TCPSocketServer对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
```
#### TCPSocketServer10+
TCPSocketServer连接。在调用TCPSocketServer的方法前，需要先通过 [socket.constructTCPSocketServerInstance](#socketconstructtcpsocketserverinstance10) 创建TCPSocketServer对象。
#### listen10+
listen(address: NetAddress, callback: AsyncCallback<void>): void
绑定IP地址和端口，端口可以指定或由系统随机分配。监听并接受与此套接字建立的TCPSocket连接。该接口使用多线程并发处理客户端的数据。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f/v3/npZv3oUtR5SlLsuV33O2RA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=8A1D135702FEC2F78CC9FB33A3503D0CB2680B0D0E35F635EAD2FE3F9A246BB5)
服务端使用该方法完成bind，listen，accept操作，bind方法失败会由系统随机分配端口号。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 是 | 目标地址信息。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303109 | Bad file number. |
| 2303111 | Resource temporarily unavailable. Try again. |
| 2303198 | Address already in use. |
| 2303199 | Cannot assign requested address. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
})
```
#### listen10+
listen(address: NetAddress): Promise<void>
绑定IP地址和端口，端口可以指定或由系统随机分配。监听并接受与此套接字建立的TCPSocket连接。该接口使用多线程并发处理客户端的数据。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e8/v3/HTDtW4_MTfusB7KQxjxYNQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=7AADAD3DF30AA9EBAC353BD866B8EC93F4FE8132D16A75060D952654B9701181)
服务端使用该方法完成bind，listen，accept操作，bind方法失败会由系统随机分配端口号。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 是 | 目标地址信息。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303109 | Bad file number. |
| 2303111 | Resource temporarily unavailable. Try again. |
| 2303198 | Address already in use. |
| 2303199 | Cannot assign requested address. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr).then(() => {
  console.info('listen success');
}).catch((err: BusinessError) => {
  console.error('listen fail');
});
```
#### getState10+
getState(callback: AsyncCallback<SocketStateBase>): void
获取TCPSocketServer状态。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d8/v3/5SXhv0M4TT2QalLCbziw_A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=32D60B8F5838854122138BFBAB0EC864F89B2BB089F5F0E4775DDDBCD9009F44)
listen方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[SocketStateBase](#socketstatebase)> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
})
tcpServer.getState((err: BusinessError, data: socket.SocketStateBase) => {
  if (err) {
    console.error('getState fail');
    return;
  }
  console.info('getState success:' + JSON.stringify(data));
})
```
#### getState10+
getState(): Promise<SocketStateBase>
获取TCPSocketServer状态。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f1/v3/M_ZQdMkNQJu0w4NGTRjhAw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=0205A8F872DEDC1BB9F890F5222A24F745EBF6A44D7B8EEA1EDCE9DCF475334E)
listen方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SocketStateBase](#socketstatebase)> | 以Promise形式返回获取TCPSocket状态的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
})
tcpServer.getState().then((data: socket.SocketStateBase) => {
  console.info('getState success' + JSON.stringify(data));
}).catch((err: BusinessError) => {
  console.error('getState fail');
});
```
#### setExtraOptions10+
setExtraOptions(options: TCPExtraOptions, callback: AsyncCallback<void>): void
设置TCPSocketServer连接的其他属性。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/62/v3/wXAkwHcRTLGRG8PazOBVhQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=A7DD2E9DE9A39947760F5BE636B51DA691F14F542DC199DF9AD6E24C7043B14D)
listen方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPExtraOptions](#tcpextraoptions) | 是 | TCPSocketServer连接的其他属性。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
})
interface SocketLinger {
  on: boolean;
  linger: number;
}
let tcpExtraOptions: socket.TCPExtraOptions = {
  keepAlive: true,
  OOBInline: true,
  TCPNoDelay: true,
  socketLinger: { on: true, linger: 10 } as SocketLinger,
  receiveBufferSize: 8192,
  sendBufferSize: 8192,
  reuseAddress: true,
  socketTimeout: 3000
}
tcpServer.setExtraOptions(tcpExtraOptions, (err: BusinessError) => {
  if (err) {
    console.error('setExtraOptions fail');
    return;
  }
  console.info('setExtraOptions success');
});
```
#### setExtraOptions10+
setExtraOptions(options: TCPExtraOptions): Promise<void>
设置TCPSocketServer连接的其他属性。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/37/v3/syrGemjWQOqu3aSQp5UyAQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=7CFCFA1AF7C687426C2ECFFACCEB9404477DF5686FE628C05B8BA5EDC2718535)
listen方法调用成功后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPExtraOptions](#tcpextraoptions) | 是 | TCPSocketServer连接的其他属性。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
interface SocketLinger {
  on: boolean;
  linger: number;
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
})
let tcpExtraOptions: socket.TCPExtraOptions = {
  keepAlive: true,
  OOBInline: true,
  TCPNoDelay: true,
  socketLinger: { on: true, linger: 10 } as SocketLinger,
  receiveBufferSize: 8192,
  sendBufferSize: 8192,
  reuseAddress: true,
  socketTimeout: 3000
}
tcpServer.setExtraOptions(tcpExtraOptions).then(() => {
  console.info('setExtraOptions success');
}).catch((err: BusinessError) => {
  console.error('setExtraOptions fail');
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<NetAddress>
获取TCPSocketServer的本地Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/8b/v3/iBeLtyItTFu3GToKaqNfMg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=CA82D1302144E30AA79C2E125746AF29F3D59E67FFCE835C61A393CDFB2247F3)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr).then(() => {
  tcpServer.getLocalAddress().then((localAddress: socket.NetAddress) => {
    console.info("SUCCESS! Address:" + JSON.stringify(localAddress));
  }).catch((err: BusinessError) => {
    console.error("FerrorAILED! Error:" + JSON.stringify(err));
  })
}).catch((err: BusinessError) => {
  console.error('listen fail');
});
```
#### on('connect')10+
on(type: 'connect', callback: Callback<TCPSocketConnection>): void
订阅TCPSocketServer的连接事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/0e/v3/Zp9T8Me1TqSHFz9wJjOSSg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=17A404B7F218899F9E5E84F428831B8253A0A7654CFD7E639BB685C604EE58AC)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'connect'：连接事件。 |
| callback | Callback<[TCPSocketConnection](#tcpsocketconnection10)> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
  tcpServer.on('connect', (data: socket.TCPSocketConnection) => {
    console.info(JSON.stringify(data))
  });
})
```
#### off('connect')10+
off(type: 'connect', callback?: Callback<TCPSocketConnection>): void
取消订阅TCPSocketServer的连接事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'connect'：连接事件。 |
| callback | Callback<[TCPSocketConnection](#tcpsocketconnection10)> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
  let callback = (data: socket.TCPSocketConnection) => {
    console.info('on connect message: ' + JSON.stringify(data));
  }
  tcpServer.on('connect', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  tcpServer.off('connect', callback);
  tcpServer.off('connect');
})
```
#### on('error')10+
on(type: 'error', callback: ErrorCallback): void
订阅TCPSocketServer连接的error事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c1/v3/3WXtLCsoSr-Rtzt47YmPRQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=995A04D49718487D5EF25F67342753C44DEDD19AD1A8D761EA96F35BB3EB54E4)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
  tcpServer.on('error', (err: BusinessError) => {
    console.error("on error, err:" + JSON.stringify(err))
  });
})
```
#### off('error')10+
off(type: 'error', callback?: ErrorCallback): void
取消订阅TCPSocketServer连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address:  '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  if (err) {
    console.error("listen fail");
    return;
  }
  console.info("listen success");
  let callback = (err: BusinessError) => {
    console.error("on error, err:" + JSON.stringify(err));
  }
  tcpServer.on('error', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  tcpServer.off('error', callback);
  tcpServer.off('error');
})
```
#### close20+
close(): Promise<void>
TCPSocketServer停止监听并释放通过 [listen](#listen10) 方法绑定的端口。若多次调用 [listen](#listen10) 方法，再调用此方法时会释放TCPSocketServer的所有监听端口。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b6/v3/8L5o3rzQTNygiipxRNajTQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=7FD961B2B8F8CB86E0BE46D4F0440DD5368F7CCD9CB41B008FF126892B1A66C5)
该方法不会关闭已有连接。如需关闭，请调用 [TCPSocketConnection](#tcpsocketconnection10) 的 [close](#close10) 方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象，无返回结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080,
  family: 1
}
tcpServer.on('connect', (connection: socket.TCPSocketConnection) => {
  console.info("connection clientId: " + connection.clientId);
  // 逻辑处理
  tcpServer.close(); // 停止监听
  connection.close(); // 关闭当前连接
});
tcpServer.listen(listenAddr).then(() => {
  console.info('listen success');
}).catch((err: BusinessError) => {
  console.error('listen fail: ' + err.code);
});
```
#### TCPSocketConnection10+
TCPSocketConnection连接，即TCPSocket客户端与服务端的连接。在调用TCPSocketConnection的方法前，需要先获取TCPSocketConnection对象。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f6/v3/0yljsUSLRXK2y60OK8gz6A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=2CAF805308B57E1288F3A2D781D9210BC83C0C5C967FCE63D09CBD28F957BBC9)
客户端与服务端成功建立连接后，才能通过返回的TCPSocketConnection对象调用相应的接口。
**系统能力** ：SystemCapability.Communication.NetStack
#### 属性
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| clientId | number | 否 | 否 | 客户端与TCPSocketServer建立连接的id。 |
#### send10+
send(options: TCPSendOptions, callback: AsyncCallback<void>): void
通过TCPSocketConnection连接发送数据。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d8/v3/vTSAKqrfSsilAfclr5W3eg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=CDC426C05059B70A22D554F9479DEFBB3B79E1DA5A04A72BBC7692F7CA6422F9)
与客户端建立连接后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPSendOptions](#tcpsendoptions) | 是 | TCPSocketConnection发送请求的参数。 |
| callback | AsyncCallback<void> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  let tcpSendOption: socket.TCPSendOptions = {
    data: 'Hello, client!'
  }
  client.send(tcpSendOption, () => {
    console.info('send success');
  });
});
```
#### send10+
send(options: TCPSendOptions): Promise<void>
通过TCPSocketConnection连接发送数据。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4e/v3/lf9Rtk0RT7Kj62qZ-AWLEw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=E695174F60D5774BF6B4E2142043A9313F7FEAFF2CD5BDCB6BBC41B8CA8D1021)
与客户端建立连接后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPSendOptions](#tcpsendoptions) | 是 | TCPSocketConnection发送请求的参数。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  let tcpSendOption: socket.TCPSendOptions = {
    data: 'Hello, client!'
  }
  client.send(tcpSendOption).then(() => {
    console.info('send success');
  }).catch((err: BusinessError) => {
    console.error('send fail');
  });
});
```
#### close10+
close(callback: AsyncCallback<void>): void
关闭一个与TCPSocket建立的连接。使用callback异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<void> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.close((err: BusinessError) => {
    if (err) {
      console.error('close fail');
      return;
    }
    console.info('close success');
  });
});
```
#### close10+
close(): Promise<void>
关闭一个与TCPSocket建立的连接。使用Promise异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.close().then(() => {
    console.info('close success');
  }).catch((err: BusinessError) => {
    console.error('close fail');
  });
});
```
#### getRemoteAddress10+
getRemoteAddress(callback: AsyncCallback<NetAddress>): void
获取对端Socket地址。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/61/v3/YFoqheCxSv2QhuBp7jCD2A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=5503868D588D7FCB856EAE95DF50C5DFB099233EEE8DA8B004AE917DB81A4BD4)
与客户端建立连接后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[NetAddress](#netaddress)> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.getRemoteAddress((err: BusinessError, data: socket.NetAddress) => {
    if (err) {
      console.error('getRemoteAddress fail');
      return;
    }
    console.info('getRemoteAddress success:' + JSON.stringify(data));
  });
});
```
#### getRemoteAddress10+
getRemoteAddress(): Promise<NetAddress>
获取对端Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/29/v3/W3vLgJaDSiO4df5JJqi4tA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=2600BACDC5A476D00A2E6A3805B3A45E83D4C021D24CA90E3679B5E6D0B69AF2)
与客户端建立连接后，才可调用此方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取对端socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.getRemoteAddress().then(() => {
    console.info('getRemoteAddress success');
  }).catch((err: BusinessError) => {
    console.error('getRemoteAddress fail');
  });
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<NetAddress>
获取TCPSocketConnection连接的本地Socket地址。使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let listenAddr: socket.NetAddress = {
  address: "192.168.xx.xx",
  port: 8080,
  family: 1
}
tcpServer.listen(listenAddr, (err: BusinessError) => {
  let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
  let netAddress: socket.NetAddress = {
    address: "192.168.xx.xx",
    port: 8080
  }
  let options: socket.TCPConnectOptions = {
    address: netAddress,
    timeout: 6000
  }
  tcp.connect(options, (err: BusinessError) => {
    if (err) {
      console.error('connect fail');
      return;
    }
    console.info('connect success!');
  })
  tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
    client.getLocalAddress().then((localAddress: socket.NetAddress) => {
      console.info("Family IP Port: " + JSON.stringify(localAddress));
    }).catch((err: BusinessError) => {
      console.error('Error:' + JSON.stringify(err));
    });
  })
})
```
#### on('message')10+
on(type: 'message', callback: Callback<SocketMessageInfo>): void
订阅TCPSocketConnection连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.on('message', (value: socket.SocketMessageInfo) => {
    let messageView = '';
    let uint8Array = new Uint8Array(value.message);
    for (let i: number = 0; i < value.message.byteLength; i++) {
      let messages = uint8Array[i];
      let message = String.fromCharCode(messages);
      messageView += message;
    }
    console.info('on message message: ' + JSON.stringify(messageView));
    console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
  });
});
```
#### off('message')10+
off(type: 'message', callback?: Callback<SocketMessageInfo>): void
取消订阅TCPSocketConnection连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let callback = (value: socket.SocketMessageInfo) => {
  let messageView = '';
  for (let i: number = 0; i < value.message.byteLength; i++) {
    let uint8Array = new Uint8Array(value.message)
    let messages = uint8Array[i]
    let message = String.fromCharCode(messages);
    messageView += message;
  }
  console.info('on message message: ' + JSON.stringify(messageView));
  console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
}
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.on('message', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  client.off('message', callback);
  client.off('message');
});
```
#### on('close')10+
on(type: 'close', callback: Callback<void>): void
订阅TCPSocketConnection的关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'close'：关闭事件。 |
| callback | Callback<void> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.on('close', () => {
    console.info("on close success")
  });
});
```
#### off('close')10+
off(type: 'close', callback?: Callback<void>): void
取消订阅TCPSocketConnection的关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'close'：关闭事件。 |
| callback | Callback<void> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
let callback = () => {
  console.info("on close success");
}
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.on('close', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  client.off('close', callback);
  client.off('close');
});
```
#### on('error')10+
on(type: 'error', callback: ErrorCallback): void
订阅TCPSocketConnection连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.on('error', (err: BusinessError) => {
    console.error("on error, err:" + JSON.stringify(err))
  });
});
```
#### off('error')10+
off(type: 'error', callback?: ErrorCallback): void
取消订阅TCPSocketConnection连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let callback = (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err));
}
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  client.on('error', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  client.off('error', callback);
  client.off('error');
});
```
#### TCP 错误码说明
TCP 其余错误码映射形式为：2301000 + Linux内核错误码。
错误码的详细介绍参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
#### socket.constructLocalSocketInstance11+
constructLocalSocketInstance(): LocalSocket
创建一个LocalSocket对象。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [LocalSocket](#localsocket11) | 返回一个LocalSocket对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
```
#### LocalSocket11+
LocalSocket连接。在调用LocalSocket的方法前，需要先通过 [socket.constructLocalSocketInstance](#socketconstructlocalsocketinstance11) 创建LocalSocket对象。
#### bind11+
bind(address: LocalAddress): Promise<void>;
绑定本地套接字文件的路径。使用promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/65/v3/hY8DOHtjSIW64CqZDqdAuw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=9BC34B68568E0B97F801F956F3E04F57E2EA6F443A08791E221144C64F03F446)
bind方法可以使客户端确保有个明确的本地套接字路径，显式的绑定一个本地套接字文件。
bind方法在本地套接字通信中非必须。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [LocalAddress](#localaddress11) | 是 | 本端地址信息，参考[LocalAddress](#localaddress11)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301013 | Insufficient permissions. |
| 2301022 | Invalid argument. |
| 2301098 | Address already in use. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/29/v3/vXB7Pj6ZQiqVa9N7rslkQg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=50F9E4EAACB144992A45FB79E084F277B5D7CDAA814F146C298D6B1269E40322)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance()
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let address : socket.LocalAddress = {
  address: sandboxPath
}
client.bind(address).then(() => {
  console.info('bind success')
}).catch((err: Object) => {
  console.error('failed to bind: ' + JSON.stringify(err))
})
```
#### connect11+
connect(options: LocalConnectOptions): Promise<void>
连接到指定的套接字文件。使用promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/53/v3/hjfFAIYqQLC6hWvDGPJyyg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=ECBBAACB3498152D53A5F3DE94612BA7CAA3C7F47FDFAFA9C17658FC1F42E064)
在没有执行localsocket.bind的情况下，也可以直接调用该接口完成与LocalSocket服务端的连接。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [LocalConnectOptions](#localconnectoptions11) | 是 | LocalSocket连接的参数，参考[LocalConnectOptions](#localconnectoptions11)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回LocalSocket连接服务端的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301013 | Insufficient permissions. |
| 2301022 | Invalid argument. |
| 2301111 | Connection refused. |
| 2301099 | Cannot assign requested address. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/9tA2RnOxRE65f0smc04z3w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=E99C472220134E45B907C8BCCE6D6B81F3BFCD74A34B8A1C6273D0596795834A)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let localAddress : socket.LocalAddress = {
  address: sandboxPath
}
let connectOpt: socket.LocalConnectOptions = {
  address: localAddress,
  timeout: 6000
}
client.connect(connectOpt).then(() => {
  console.info('connect success')
}).catch((err: Object) => {
  console.error('connect fail: ' + JSON.stringify(err));
});
```
#### send11+
send(options: LocalSendOptions): Promise<void>
通过LocalSocket连接发送数据。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/7e/v3/hFsU3yKFTAK6KKaMekIu0w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=4E70277C93299B87F5630A27431FB0BF339283B3F52D20D08FCF927EBACD5A34)
connect方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [LocalSendOptions](#localsendoptions11) | 是 | LocalSocket发送请求的参数，参考[LocalSendOptions](#localsendoptions11)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301011 | Operation would block. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/40/v3/GFI4yChfQCyJS8eHHfvOkw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=656011E4650A451F1D4A28FEE892632C844FEE22A5E13AE538DA4C669C6E4A60)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance()
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let localAddress : socket.LocalAddress = {
  address: sandboxPath
}
let connectOpt: socket.LocalConnectOptions = {
  address: localAddress,
  timeout: 6000
}
client.connect(connectOpt).then(() => {
  console.info('connect success')
}).catch((err: Object) => {
  console.error('connect failed: ' + JSON.stringify(err))
})
let sendOpt: socket.LocalSendOptions = {
  data: 'Hello world!'
}
client.send(sendOpt).then(() => {
  console.info('send success')
}).catch((err: Object) => {
  console.error('send fail: ' + JSON.stringify(err))
})
```
#### close11+
close(): Promise<void>
关闭LocalSocket连接。使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2301009 | Bad file descriptor. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
client.close().then(() => {
  console.info('close success');
}).catch((err: Object) => {
  console.error('close fail: ' + JSON.stringify(err));
});
```
#### getState11+
getState(): Promise<SocketStateBase>
获取LocalSocket状态。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/03/v3/d8gw886DRO6WWcEOmfraLA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=A938512822924F4CBF961ACAA2A62BC03A5593F1A369F0EAB318AAD12F6B222E)
bind或connect方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SocketStateBase](#socketstatebase)> | 以Promise形式返回获取LocalSocket状态的结果。 |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a6/v3/Kx1_2RYyTk-Fukwldu53fg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=07E556817A64FED8FB94C84952C05F4A24FA274829C3DC0391BFD4D5CEA5260D)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let localAddress : socket.LocalAddress = {
  address: sandboxPath
}
let connectOpt: socket.LocalConnectOptions = {
  address: localAddress,
  timeout: 6000
}
client.connect(connectOpt).then(() => {
  console.info('connect success');
  client.getState().then(() => {
    console.info('getState success');
  }).catch((err: Object) => {
    console.error('getState fail: ' + JSON.stringify(err))
  });
}).catch((err: Object) => {
  console.error('connect fail: ' + JSON.stringify(err));
});
```
#### getSocketFd11+
getSocketFd(): Promise<number>
获取LocalSocket的文件描述符。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f8/v3/9d15ao6sT1WPIubBeNzKOQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=3D96F5D9C1B6B5A65021357C2B0649BCCE88F20E9FA17FE25006144134111593)
bind或connect方法调用成功后，才可调用此方法。
获取由系统内核分配的唯一文件描述符，用于标识当前使用的套接字。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<number> | 以Promise形式返回socket的文件描述符。 |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/94/v3/T6nZKTJXSv6mF0t1lkChmw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=907C00DD445EF6267FE54CA107EAAB5A879EA4C960B62F8E338E5DDA205B2251)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let localAddress : socket.LocalAddress = {
  address: sandboxPath
}
let connectOpt: socket.LocalConnectOptions = {
  address: localAddress,
  timeout: 6000
}
client.connect(connectOpt).then(() => {
  console.info('connect ok')
}).catch((err: Object) => {
  console.error('connect fail: ' + JSON.stringify(err))
})
client.getSocketFd().then((data: number) => {
  console.info("fd: " + data);
}).catch((err: Object) => {
  console.error("getSocketFd failed: " + JSON.stringify(err));
})
```
#### setExtraOptions11+
setExtraOptions(options: ExtraOptionsBase): Promise<void>
设置LocalSocket的套接字属性。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d4/v3/jCFfynP_QuGOmY_ZAnT-Yw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=CF127FB8D38EAF981EAE63DBEEADD8D4BB79ED6328197C77B75E99C099854AAE)
bind或connect方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [ExtraOptionsBase](#extraoptionsbase) | 是 | LocalSocket连接的其他属性，参考[ExtraOptionsBase](#extraoptionsbase)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回设置LocalSocket套接字属性的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301009 | Bad file descriptor. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a2/v3/rNXPvvnmQ2uZ6FQp1dZEeA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=A30C7967F2B3267BD259EA605B9D4750F7A0292427B147807C2F00BC4909196D)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let localAddress : socket.LocalAddress = {
  address: sandboxPath
}
let connectOpt: socket.LocalConnectOptions = {
  address: localAddress,
  timeout: 6000
}
client.connect(connectOpt).then(() => {
  console.info('connect success');
  let options: socket.ExtraOptionsBase = {
    receiveBufferSize: 8192,
    sendBufferSize: 8192,
    socketTimeout: 3000
  }
  client.setExtraOptions(options).then(() => {
    console.info('setExtraOptions success');
  }).catch((err: Object) => {
    console.error('setExtraOptions fail: ' + JSON.stringify(err));
  });
}).catch((err: Object) => {
  console.error('connect fail: ' + JSON.stringify(err));
});
```
#### getExtraOptions11+
getExtraOptions(): Promise<ExtraOptionsBase>;
获取LocalSocket的套接字属性。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/95/v3/5Br1Ycw7QEWEAxq_arf8bw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=75E710CDF320599F83265F54E629BE710A40E9A53AC8B3541909BDE1924222C2)
bind或connect方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[ExtraOptionsBase](#extraoptionsbase)> | 以Promise形式返回设置LocalSocket套接字的属性。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2301009 | Bad file descriptor. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/8c/v3/M_f386EGTEGhQviXzGj03g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=982F81DB7F487CE45987883E094C620183F9DD20BB4F738E7B44828EEAB28161)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let localAddress : socket.LocalAddress = {
  address: sandboxPath
}
let connectOpt: socket.LocalConnectOptions = {
  address: localAddress,
  timeout: 6000
}
client.connect(connectOpt).then(() => {
  console.info('connect success');
  client.getExtraOptions().then((options : socket.ExtraOptionsBase) => {
    console.info('options: ' + JSON.stringify(options));
  }).catch((err: Object) => {
    console.error('setExtraOptions fail: ' + JSON.stringify(err));
  });
}).catch((err: Object) => {
  console.error('connect fail: ' + JSON.stringify(err));
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<string>
获取LocalSocket的本地Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a8/v3/yug8kKOoTVCKg4b7-ha0Bg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=2E1065B32F50E3A85B1486F84545A41E31A3C7549F9A4BD657D3BB5928995057)
bind方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<string> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c6/v3/GAo4Hw8vQNyiv5CPgFbUhw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=B81E51524D3817D82426CD3AC92B9D1DCCD19281C00CA022C32A42B4F539459E)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { common } from '@kit.AbilityKit';
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let address : socket.LocalAddress = {
  address: sandboxPath
}
client.bind(address).then(() => {
  console.error('bind success');
  client.getLocalAddress().then((localPath: string) => {
    console.info("SUCCESS " + JSON.stringify(localPath));
  }).catch((err: BusinessError) => {
    console.error("FAIL " + JSON.stringify(err));
  })
}).catch((err: Object) => {
  console.error('failed to bind: ' + JSON.stringify(err));
})
```
#### on('message')11+
on(type: 'message', callback: Callback<LocalSocketMessageInfo>): void
订阅LocalSocket连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[LocalSocketMessageInfo](#localsocketmessageinfo11)> | 是 | 以callback的形式异步返回接收的消息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
client.on('message', (value: socket.LocalSocketMessageInfo) => {
  const uintArray = new Uint8Array(value.message)
  let messageView = '';
  for (let i = 0; i < uintArray.length; i++) {
    messageView += String.fromCharCode(uintArray[i]);
  }
  console.info('total: ' + JSON.stringify(value));
  console.info('message information: ' + messageView);
});
```
#### off('message')11+
off(type: 'message', callback?: Callback<LocalSocketMessageInfo>): void
取消订阅LocalSocket连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[LocalSocketMessageInfo](#localsocketmessageinfo11)> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let messageView = '';
let callback = (value: socket.LocalSocketMessageInfo) => {
  const uintArray = new Uint8Array(value.message)
  let messageView = '';
  for (let i = 0; i < uintArray.length; i++) {
    messageView += String.fromCharCode(uintArray[i]);
  }
  console.info('total: ' + JSON.stringify(value));
  console.info('message information: ' + messageView);
}
client.on('message', callback);
client.off('message');
```
#### on('connect')11+
on(type: 'connect', callback: Callback<void>): void
订阅LocalSocket的连接事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。 |
| callback | Callback<void> | 是 | 以callback的形式异步返回与服务端连接的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
client.on('connect', () => {
  console.info("on connect success")
});
```
#### off('connect')11+
off(type: 'connect', callback?: Callback<void>): void
取消订阅LocalSocket的连接事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'connect'：LocalSocket的connect事件。 |
| callback | Callback<void> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let callback = () => {
  console.info("on connect success");
}
client.on('connect', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
client.off('connect', callback);
client.off('connect');
```
#### on('close')11+
on(type: 'close', callback: Callback<void>): void
订阅LocalSocket的关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅LocalSocket的关闭事件。 |
| callback | Callback<void> | 是 | 以callback的形式异步返回关闭localsocket的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let callback = () => {
  console.info("on close success");
}
client.on('close', callback);
```
#### off('close')11+
off(type: 'close', callback?: Callback<void>): void
取消订阅LocalSocket的关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'close'：LocalSocket的关闭事件。 |
| callback | Callback<void> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let callback = () => {
  console.info("on close success");
}
client.on('close', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
client.off('close', callback);
client.off('close');
```
#### on('error')11+
on(type: 'error', callback: ErrorCallback): void
订阅LocalSocket连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅LocalSocket的error事件。 |
| callback | ErrorCallback | 是 | 以callback的形式异步返回出现错误的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
client.on('error', (err: Object) => {
  console.error("on error, err:" + JSON.stringify(err))
});
```
#### off('error')11+
off(type: 'error', callback?: ErrorCallback): void
取消订阅LocalSocket连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'error'：LocalSocket的error事件。 |
| callback | ErrorCallback | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
let callback = (err: Object) => {
  console.error("on error, err:" + JSON.stringify(err));
}
client.on('error', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
client.off('error', callback);
client.off('error');
```
#### LocalSocketMessageInfo11+
LocalSocket客户端与服务端通信时接收的数据。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| message | ArrayBuffer | 否 | 否 | 收到的消息数据。 |
| address | string | 否 | 否 | 使用的本地套接字路径。 |
| size | number | 否 | 否 | 数据长度。 |
#### LocalAddress11+
LocalSocket本地套接字文件路径信息，在传入套接字路径进行绑定时，会在此路径下创建套接字文件。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| address | string | 否 | 否 | 本地套接字路径。 |
#### LocalConnectOptions11+
LocalSocket客户端在连接服务端时传入的参数信息。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| address | [LocalAddress](#localaddress11) | 否 | 否 | 指定的本地套接字路径。 |
| timeout | number | 否 | 是 | 连接服务端的超时时间，单位为毫秒。默认值为0。需要应用手动设置一下，建议设置为5000。 |
#### LocalSendOptions11+
LocalSocket发送请求的参数。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| data | string | ArrayBuffer | 否 | 否 | 需要发送的数据。 |
| encoding | string | 否 | 是 | 字符编码。 |
#### ExtraOptionsBase
Socket套接字的基础属性。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| receiveBufferSize | number | 否 | 是 | 接收缓冲区大小（单位：Byte），取值范围0~262144，不设置或设置的值超过取值范围则会默认为8192。 |
| sendBufferSize | number | 否 | 是 | 发送缓冲区大小（单位：Byte），取值范围0~262144，不设置或设置的值超过取值范围则会默认为8192。 |
| reuseAddress | boolean | 否 | 是 | 是否重用地址。true：重用地址；false：不重用地址。 |
| socketTimeout | number | 否 | 是 | 套接字超时时间，单位毫秒（ms）。 |
#### socket.constructLocalSocketServerInstance11+
constructLocalSocketServerInstance(): LocalSocketServer
创建一个LocalSocketServer对象。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [LocalSocketServer](#localsocketserver11) | 返回一个LocalSocketServer对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
```
#### LocalSocketServer11+
LocalSocketServer类。在调用LocalSocketServer的方法前，需要先通过 [socket.constructLocalSocketServerInstance](#socketconstructlocalsocketserverinstance11) 创建LocalSocketServer对象。
#### listen11+
listen(address: LocalAddress): Promise<void>
绑定本地套接字文件，监听并接受与此套接字建立的LocalSocket连接。该接口使用多线程并发处理客户端的数据。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/df/v3/iPYtjD7NTQOWilQpfhbWcQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=22F9D04A797B708ED822BCFF65786435E87317DA4AC45E9DD8DF9A6BDD8C167E)
服务端使用该方法完成bind，listen，accept操作，传入套接字文件路径，调用此接口后会自动生成本地套接字文件。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [LocalAddress](#localaddress11) | 是 | 目标地址信息。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回执行结果， 成功返回空，失败返回错误码错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303109 | Bad file number. |
| 2301013 | Insufficient permissions. |
| 2301022 | Invalid argument. |
| 2301098 | Address already in use. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c3/v3/D7Fj-mPiR2aMyWsEU4qd2w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=7ECE6D0522C71D11FD0BC15660BA0330823923B0670B234A277F158F138AA0BE)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let addr: socket.LocalAddress = {
  address: sandboxPath
}
server.listen(addr).then(() => {
  console.info('listen success');
}).catch((err: Object) => {
  console.error('listen fail: ' + JSON.stringify(err));
});
```
#### getState11+
getState(): Promise<SocketStateBase>
获取LocalSocketServer状态。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/66/v3/QkeecS0STv2CeUWQ-oTi2w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=1A16FC408D14A6649FB7D1A913B84EFCFD0BA46FA5A919F9F550F30A896AC66F)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SocketStateBase](#socketstatebase)> | 以Promise形式返回获取LocalSocketServer状态的结果。 |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fd/v3/QnuipXh3T7GqAnEDenQcrw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=1AB973FA7FD5A120ADAAA60A39F6B8FE2B5D2D059958BB8BAB970491BCCCF457)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let listenAddr: socket.LocalAddress = {
  address: sandboxPath
}
server.listen(listenAddr).then(() => {
  console.info("listen success");
}).catch((err: Object) => {
  console.error("listen fail: " + JSON.stringify(err));
})
server.getState().then((data: socket.SocketStateBase) => {
  console.info('getState success: ' + JSON.stringify(data));
}).catch((err: Object) => {
  console.error('getState fail: ' + JSON.stringify(err));
});
```
#### setExtraOptions11+
setExtraOptions(options: ExtraOptionsBase): Promise<void>
设置LocalSocketServer连接的套接字属性。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/68/v3/E80AUt-JQVSiNnFZm7t-qg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=34C4BC8E08AA1166073FDCF91EAA80F745BB81D5A7830E2DEC9F718A0C01C074)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [ExtraOptionsBase](#extraoptionsbase) | 是 | LocalSocketServer连接的其他属性。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301009 | Bad file descriptor. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/5/v3/SeaNz9egQI2wA0SNLPdPsA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=5B031FB8035B263A5F853FBD97A31938D6101BA6C4767E7B8755A47C7F6B1506)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let listenAddr: socket.NetAddress = {
  address: sandboxPath
}
server.listen(listenAddr).then(() => {
  console.info("listen success");
}).catch((err: Object) => {
  console.error("listen fail: " + JSON.stringify(err));
})
let options: socket.ExtraOptionsBase = {
  receiveBufferSize: 8192,
  sendBufferSize: 8192,
  socketTimeout: 3000
}
server.setExtraOptions(options).then(() => {
  console.info('setExtraOptions success');
}).catch((err: Object) => {
  console.error('setExtraOptions fail: ' + JSON.stringify(err));
});
```
#### getExtraOptions11+
getExtraOptions(): Promise<ExtraOptionsBase>;
获取LocalSocketServer中连接的套接字的属性。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d9/v3/kKuoQ8lBTpeR5BAZxf-8Mg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=8FBFC075B6E7C6175369C850D6B8B2BCF30F7D6A2B2E0B7DE0078CC918590864)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[ExtraOptionsBase](#extraoptionsbase)> | 以Promise形式返回套接字的属性。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d6/v3/ezfnHqVfQKeiPspZuwv7Ug/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=5746353CD753238C872F0618B1DEEB5ECCEE6B7978BC96502F2E553FF1456E4F)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let listenAddr: socket.LocalAddress = {
  address: sandboxPath
}
server.listen(listenAddr).then(() => {
  console.info("listen success");
}).catch((err: Object) => {
  console.error("listen fail: " + JSON.stringify(err));
})
server.getExtraOptions().then((options: socket.ExtraOptionsBase) => {
  console.info('options: ' + JSON.stringify(options));
}).catch((err: Object) => {
  console.error('getExtraOptions fail: ' + JSON.stringify(err));
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<string>
获取LocalSocketServer中本地Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/3d/v3/YpernqkqTE6IsWwS2I4pxQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=53B93F4AE124CFE0DC0BEC32D99ED4AD6F1702ED94FAD12871E634CFF3BEDE96)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<string> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ed/v3/vmU085XrTviZL4hU-GL0cA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=8007634DE29E42C30B8846D7B3EFE1B7EE9042DD99DBB44E124DB5D0F844D1F5)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { common } from '@kit.AbilityKit';
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let listenAddr: socket.LocalAddress = {
  address: sandboxPath
}
server.listen(listenAddr).then(() => {
  console.info("listen success");
  server.getLocalAddress().then((localPath: string) => {
    console.info("SUCCESS " + JSON.stringify(localPath));
  }).catch((err: BusinessError) => {
    console.error("FAIL " + JSON.stringify(err));
  })
}).catch((err: Object) => {
  console.error("listen fail: " + JSON.stringify(err));
})
```
#### on('connect')11+
on(type: 'connect', callback: Callback<LocalSocketConnection>): void
订阅LocalSocketServer的连接事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6b/v3/3eQNboZkTTCU9nCp4w2Sqw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=624422BD618D39F6C926AF1775578F10BBD79217F83E5CB7CD1B311D86E12513)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'connect'：连接事件。 |
| callback | Callback<[LocalSocketConnection](#localsocketconnection11)> | 是 | 以callback的形式异步返回接收到客户端连接的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
server.on('connect', (connection: socket.LocalSocketConnection) => {
  if (connection) {
    console.info('accept a client')
  }
});
```
#### off('connect')11+
off(type: 'connect', callback?: Callback<LocalSocketConnection>): void
取消订阅LocalSocketServer的连接事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'connect'：LocalSocketServer的连接事件。 |
| callback | Callback<[LocalSocketConnection](#localsocketconnection11)> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let callback = (connection: socket.LocalSocketConnection) => {
  if (connection) {
    console.info('accept a client')
  }
}
server.on('connect', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
server.off('connect', callback);
server.off('connect');
```
#### on('error')11+
on(type: 'error', callback: ErrorCallback): void
订阅LocalSocketServer连接的error事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/42/v3/RjBp2L-hR1CfFpjR2Lxw7Q/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=0D350420AA86BD34A5E93E4BC652CCCF73D408C112E0EFFC197E49F9FDC125CE)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 以callback的形式异步返回出现错误的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
server.on('error', (err: Object) => {
  console.error("on error, err:" + JSON.stringify(err))
});
```
#### off('error')11+
off(type: 'error', callback?: ErrorCallback): void
取消订阅LocalSocketServer连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let callback = (err: Object) => {
  console.error("on error, err:" + JSON.stringify(err));
}
server.on('error', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
server.off('error', callback);
server.off('error');
```
#### close20+
close(): Promise<void>
LocalSocketServer停止监听并释放通过 [listen](#listen11) 方法绑定的监听端口。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/26/v3/KuLvLuP3QRq80Ej4z63now/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=BEE29E758B4EA37CD8BDD0F0308F0E0276A808B0547A0B3A49280EBA3DDB4325)
该方法不会关闭已有连接。如需关闭，请调用 [LocalSocketConnection](#localsocketconnection11) 的 [close](#close11-1) 方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象，无返回结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/df/v3/sSsZABLPSFe8746BHt2V-A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=EFF4EA92CA11A5A8892F1BDABD5C2C9C85BEE8AC9E45F22E007B6F1227CE59CA)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
let localserver: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let addr: socket.LocalAddress = {
  address: sandboxPath
}
localserver.on('connect', (connection: socket.LocalSocketConnection) => {
  console.info("connection clientId: " + connection.clientId);
  // 逻辑处理
  localserver.close(); // 停止监听
  connection.close(); // 关闭当前连接
});
localserver.listen(addr).then(() => {
  console.info('listen success');
}).catch((err: BusinessError) => {
  console.error('listen fail: ' + err.code);
});
```
#### LocalSocketConnection11+
LocalSocketConnection连接，即LocalSocket客户端与服务端的会话连接。在调用LocalSocketConnection的方法前，需要先获取LocalSocketConnection对象。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/2a/v3/9_6E21GsT_KLlu0QWruA4A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=475EFA84F298CE28DB458696784E4622103BB2EC436FC75BB73D8515F2DBB334)
客户端与服务端成功建立连接后，才能通过返回的LocalSocketConnection对象调用相应的接口。
**系统能力** ：SystemCapability.Communication.NetStack
#### 属性
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| clientId | number | 否 | 否 | 客户端与服务端建立的会话连接的id。 |
#### send11+
send(options: LocalSendOptions): Promise<void>
通过LocalSocketConnection连接对象发送数据。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6/v3/2EiC1TMPRUSzkkdErmGtaA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=5A9946F64E5CED420283A4805F58535DD9F6FE138A648C10A03EF4A41716998F)
服务端与客户端建立连接后，服务端通过connect事件回调得到LocalSocketConnection连接对象后，才可使用连接对象调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [LocalSendOptions](#localsendoptions11) | 是 | LocalSocketConnection发送请求的参数。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2301011 | Operation would block. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
server.on('connect', (connection: socket.LocalSocketConnection) => {
  let sendOptions: socket.LocalSendOptions = {
    data: 'Hello, client!'
  }
  connection.send(sendOptions).then(() => {
    console.info('send success');
  }).catch((err: Object) => {
    console.error('send fail: ' + JSON.stringify(err));
  });
});
```
#### close11+
close(): Promise<void>
关闭一个LocalSocket客户端与服务端建立的连接。使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2301009 | Bad file descriptor. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
server.on('connect', (connection: socket.LocalSocketConnection) => {
  connection.close().then(() => {
    console.info('close success');
  }).catch((err: Object) => {
    console.error('close fail: ' + JSON.stringify(err));
  });
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<string>
获取LocalSocketConnection连接中的本地Socket地址。使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<string> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ca/v3/iAwVydCgTXyK7ctQyNIbJA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=8AAB59A7E6C2CBB0DEA538C7730911D2335FA655A1CC40113E2A463CD3898889)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { common } from '@kit.AbilityKit';
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let localAddr: socket.LocalAddress = {
  address: sandboxPath
}
server.listen(localAddr).then(() => {
  console.info('listen success');
  let client: socket.LocalSocket = socket.constructLocalSocketInstance();
  let connectOpt: socket.LocalConnectOptions = {
    address: localAddr,
    timeout: 6000
  }
  client.connect(connectOpt).then(() => {
    server.getLocalAddress().then((localPath: string) => {
      console.info("success, localPath is" + JSON.stringify(localPath));
    }).catch((err: BusinessError) => {
      console.error("FAIL " + JSON.stringify(err));
    })
  }).catch((err: Object) => {
    console.error('connect fail: ' + JSON.stringify(err));
  });
});
```
#### on('message')11+
on(type: 'message', callback: Callback<LocalSocketMessageInfo>): void
订阅LocalSocketConnection连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[LocalSocketMessageInfo](#localsocketmessageinfo11)> | 是 | 以callback的形式异步返回接收到的来自客户端的消息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e8/v3/ZCVQxBZRSH2dpJByDCh9GA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=4465C78CE83A1CCBB92C56B479F1ABC58DCB0E7730FE7CAAC62D4AE6F6CAE003)
在本文档的示例中，通过this.context来获取UIAbilityContext，其中this代表继承自UIAbility的UIAbility实例。如需在页面中使用UIAbilityContext提供的能力，请参见 [获取UIAbility的上下文信息](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件基本用法/uiability-usage.md) 。
```
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';
let listenAddr: socket.LocalAddress = {
  address: sandboxPath
}
server.listen(listenAddr).then(() => {
  console.info("listen success");
}).catch((err: Object) => {
  console.error("listen fail: " + JSON.stringify(err));
});
server.on('connect', (connection: socket.LocalSocketConnection) => {
  connection.on('message', (value: socket.LocalSocketMessageInfo) => {
    const uintArray = new Uint8Array(value.message);
    let messageView = '';
    for (let i = 0; i < uintArray.length; i++) {
      messageView += String.fromCharCode(uintArray[i]);
    }
    console.info('total: ' + JSON.stringify(value));
    console.info('message information: ' + messageView);
  });
});
```
#### off('message')11+
off(type: 'message', callback?: Callback<LocalSocketMessageInfo>): void
取消订阅LocalSocketConnection连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[LocalSocketMessageInfo](#localsocketmessageinfo11)> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let callback = (value: socket.LocalSocketMessageInfo) => {
  const uintArray = new Uint8Array(value.message)
  let messageView = '';
  for (let i = 0; i < uintArray.length; i++) {
    messageView += String.fromCharCode(uintArray[i]);
  }
  console.info('total: ' + JSON.stringify(value));
  console.info('message information: ' + messageView);
}
server.on('connect', (connection: socket.LocalSocketConnection) => {
  connection.on('message', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  connection.off('message', callback);
  connection.off('message');
});
```
#### on('close')11+
on(type: 'close', callback: Callback<void>): void
订阅LocalSocketConnection的关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'close'：关闭事件。 |
| callback | Callback<void> | 是 | 以callback的形式异步返回会话关闭的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
server.on('connect', (connection: socket.LocalSocketConnection) => {
  connection.on('close', () => {
    console.info("on close success")
  });
});
```
#### off('close')11+
off(type: 'close', callback?: Callback<void>): void
取消订阅LocalSocketConnection的关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'close'：关闭事件。 |
| callback | Callback<void> | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
let callback = () => {
  console.info("on close success");
}
server.on('connect', (connection: socket.LocalSocketConnection) => {
  connection.on('close', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  connection.off('close', callback);
  connection.off('close');
});
```
#### on('error')11+
on(type: 'error', callback: ErrorCallback): void
订阅LocalSocketConnection连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 以callback的形式异步返回出现错误的结果。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
server.on('connect', (connection: socket.LocalSocketConnection) => {
  connection.on('error', (err: Object) => {
    console.error("on error, err:" + JSON.stringify(err))
  });
});
```
#### off('error')11+
off(type: 'error', callback?: ErrorCallback): void
取消订阅LocalSocketConnection连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 取消订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。可以指定传入on中的callback取消对应的订阅，也可以不指定callback清空所有订阅。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let callback = (err: Object) => {
  console.error("on error, err: " + JSON.stringify(err));
}
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
server.on('connect', (connection: socket.LocalSocketConnection) => {
  connection.on('error', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  connection.off('error', callback);
  connection.off('error');
});
```
#### LocalSocket 错误码说明
LocalSocket 错误码映射形式为：2301000 + Linux内核错误码。
错误码的详细介绍参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
#### socket.constructTLSSocketInstance9+
constructTLSSocketInstance(): TLSSocket
创建并返回一个TLSSocket对象。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值:**
| 类型 | 说明 |
| --- | --- |
| [TLSSocket](#tlssocket9) | 返回一个TLSSocket对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
```
#### socket.constructTLSSocketInstance12+
constructTLSSocketInstance(tcpSocket: TCPSocket): TLSSocket
将TCPSocket升级为TLSSocket，创建并返回一个TLSSocket对象。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b8/v3/oLYeNZzzSI-httfXP4B5nw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=3C95B202ECD78FE8733BFB2982629326A91516FE47E5ED0862A6559992F8EFD2)
需要确保TCPSocket已连接，并且当前已经没有传输数据，再调用constructTLSSocketInstance升级TLSSocket。当升级成功后，无需对TCPSocket对象调用close方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| tcpSocket | [TCPSocket](#tcpsocket) | 是 | 需要进行升级的TCPSocket对象。 |
**返回值:**
| 类型 | 说明 |
| --- | --- |
| [TLSSocket](#tlssocket9) | 返回一个TLSSocket对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2300002 | System internal error. |
| 2303601 | Invalid socket FD. |
| 2303602 | Socket is not connected. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tcpconnectoptions: socket.TCPConnectOptions = {
  address: netAddress,
  timeout: 6000
}
tcp.connect(tcpconnectoptions, (err: BusinessError) => {
  if (err) {
    console.error('connect fail');
    return;
  }
  console.info('connect success');
  // 确保TCPSocket已连接后，再升级TLSSocket
  let tls: socket.TLSSocket = socket.constructTLSSocketInstance(tcp);
})
```
#### TLSSocket9+
TLSSocket连接。在调用TLSSocket的方法前，需要先通过 [socket.constructTLSSocketInstance](#socketconstructtlssocketinstance9) 创建TLSSocket对象。
#### bind9+
bind(address: NetAddress, callback: AsyncCallback<void>): void
绑定IP地址和端口。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/34/v3/4p1brFCbQUaJtn3DWZaLIw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=E2F9EE30E599A24D4B646B0A921EBE838F32E0F01880D162CBAECF1604805957)
如果TLSSocket对象是通过TCPSocket对象升级创建的，可以不用执行bind方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 是 | 本端地址信息，参考[NetAddress](#netaddress)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。成功返回TLSSocket绑定本机的IP地址和端口的结果。失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2303198 | Address already in use. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
```
#### bind9+
bind(address: NetAddress): Promise<void>
绑定IP地址和端口。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1c/v3/QQvIJJ4xT1CKZFNitLauDQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=5ED45AA0FF587F48BA0653BB23C9160AABE79351A2DEEDDCB27B4644D2422827)
如果TLSSocket对象是通过TCPSocket对象升级创建的，可以不用执行bind方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 是 | 本端地址信息，参考[NetAddress](#netaddress)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回TLSSocket绑定本机的IP地址和端口的结果。失败返回错误码，错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2303198 | Address already in use. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr).then(() => {
  console.info('bind success');
}).catch((err: BusinessError) => {
  console.error('bind fail');
});
```
#### getState9+
getState(callback: AsyncCallback<SocketStateBase>): void
在TLSSocket的bind成功之后，获取TLSSocket状态。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[SocketStateBase](#socketstatebase)> | 是 | 回调函数。成功返回TLSSocket状态，失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
tls.getState((err: BusinessError, data: socket.SocketStateBase) => {
  if (err) {
    console.error('getState fail');
    return;
  }
  console.info('getState success:' + JSON.stringify(data));
});
```
#### getState9+
getState(): Promise<SocketStateBase>
在TLSSocket的bind成功之后，获取TLSSocket状态。使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SocketStateBase](#socketstatebase)> | 以Promise形式返回获取TLSSocket状态的结果。失败返回错误码，错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
tls.getState().then(() => {
  console.info('getState success');
}).catch((err: BusinessError) => {
  console.error('getState fail');
});
```
#### setExtraOptions9+
setExtraOptions(options: TCPExtraOptions, callback: AsyncCallback<void>): void
在TLSSocket的bind成功之后，设置TCPSocket连接的其他属性。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPExtraOptions](#tcpextraoptions) | 是 | TCPSocket连接的其他属性，参考[TCPExtraOptions](#tcpextraoptions)。 |
| callback | AsyncCallback<void> | 是 | 回调函数。成功返回设置TCPSocket连接的其他属性的结果，失败返回错误码、错误信息。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
interface SocketLinger {
  on: boolean;
  linger: number;
}
let tcpExtraOptions: socket.TCPExtraOptions = {
  keepAlive: true,
  OOBInline: true,
  TCPNoDelay: true,
  socketLinger: { on: true, linger: 10 } as SocketLinger,
  receiveBufferSize: 8192,
  sendBufferSize: 8192,
  reuseAddress: true,
  socketTimeout: 3000
}
tls.setExtraOptions(tcpExtraOptions, (err: BusinessError) => {
  if (err) {
    console.error('setExtraOptions fail');
    return;
  }
  console.info('setExtraOptions success');
});
```
#### setExtraOptions9+
setExtraOptions(options: TCPExtraOptions): Promise<void>
在TLSSocket的bind成功之后，设置TCPSocket连接的其他属性。使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPExtraOptions](#tcpextraoptions) | 是 | TCPSocket连接的其他属性，参考[TCPExtraOptions](#tcpextraoptions)。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
interface SocketLinger {
  on: boolean;
  linger: number;
}
let tcpExtraOptions: socket.TCPExtraOptions = {
  keepAlive: true,
  OOBInline: true,
  TCPNoDelay: true,
  socketLinger: { on: true, linger: 10 } as SocketLinger,
  receiveBufferSize: 8192,
  sendBufferSize: 8192,
  reuseAddress: true,
  socketTimeout: 3000
}
tls.setExtraOptions(tcpExtraOptions).then(() => {
  console.info('setExtraOptions success');
}).catch((err: BusinessError) => {
  console.error('setExtraOptions fail');
});
```
#### on('message')9+
on(type: 'message', callback: Callback<SocketMessageInfo>): void
订阅TLSSocket连接的接收消息事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1f/v3/9WODs_KFT8SS41UCsX91ng/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=F8498CB9B9B9444DB367D8FA33654EA1724BF7115CF214F79196D5092377AC1D)
bind方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 是 | 回调函数。TLSSocket连接订阅某类接受消息事件触发的调用函数，返回TLSSocket连接信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
  tls.on('message', (value: socket.SocketMessageInfo) => {
    let messageView = '';
    let uint8Array = new Uint8Array(value.message);
    for (let i: number = 0; i < value.message.byteLength; i++) {
      let messages = uint8Array[i];
      let message = String.fromCharCode(messages);
      messageView += message;
    }
    console.info('on message message: ' + JSON.stringify(messageView));
    console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
  });
});
```
#### off('message')9+
off(type: 'message', callback?: Callback<SocketMessageInfo>): void
取消订阅TLSSocket连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 否 | 回调函数。TLSSocket连接取消订阅某类接受消息事件触发的调用函数，返回TLSSocket连接信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let messageView = '';
let callback = (value: socket.SocketMessageInfo) => {
  for (let i: number = 0; i < value.message.byteLength; i++) {
    let uint8Array = new Uint8Array(value.message)
    let messages = uint8Array[i]
    let message = String.fromCharCode(messages);
    messageView += message;
  }
  console.info('on message message: ' + JSON.stringify(messageView));
  console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
}
tls.on('message', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tls.off('message', callback);
```
#### on('connect' | 'close')9+
on(type: 'connect' | 'close', callback: Callback<void>): void
订阅TLSSocket的连接事件或关闭事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/55/v3/lbZBazMqQ3yfOP2g_tFEFg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=A432EDB975F86A4E284488DF5DEBB404C2A3403E3F2680AABB95B0553389E86C)
bind方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。- 'connect'：连接事件。- 'close'：关闭事件。 |
| callback | Callback<void> | 是 | 回调函数。TLSSocket连接订阅某类事件触发的调用函数。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
  tls.on('connect', () => {
    console.info("on connect success")
  });
  tls.on('close', () => {
    console.info("on close success")
  });
});
```
#### off('connect' | 'close')9+
off(type: 'connect' | 'close', callback?: Callback<void>): void
取消订阅TLSSocket的连接事件或关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。- 'connect'：连接事件。- 'close'：关闭事件。 |
| callback | Callback<void> | 否 | 回调函数。TLSSocket连接订阅某类事件触发的调用函数。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let callback1 = () => {
  console.info("on connect success");
}
tls.on('connect', callback1);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tls.off('connect', callback1);
tls.off('connect');
let callback2 = () => {
  console.info("on close success");
}
tls.on('close', callback2);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tls.off('close', callback2);
```
#### on('error')9+
on(type: 'error', callback: ErrorCallback): void
订阅TLSSocket连接的error事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f1/v3/APKDjYUzSWezYQ0-0Q_gYw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=ABE02D519ADCB6EF087843C6680B8FBD11AF5666E0C4B9F66E4D3AFCC1A7E8CE)
bind方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 回调函数。TLSSocket连接订阅某类error事件触发的调用函数。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
  tls.on('error', (err: BusinessError) => {
    console.error("on error, err:" + JSON.stringify(err))
  });
});
```
#### off('error')9+
off(type: 'error', callback?: ErrorCallback): void
取消订阅TLSSocket连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。TLSSocket连接取消订阅某类error事件触发的调用函数。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let callback = (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err));
}
tls.on('error', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tls.off('error', callback);
```
#### connect9+
connect(options: TLSConnectOptions, callback: AsyncCallback<void>): void
在TLSSocket上bind成功之后，进行通信连接，并创建和初始化TLS会话，实现建立连接过程，启动与服务器的TLS/SSL握手，实现数据传输功能，使用callback异步回调。需要注意options入参下secureOptions内的ca在API11及之前的版本为必填项，需填入服务端的ca证书(用于认证校验服务端的数字证书)，证书内容以"-----BEGIN CERTIFICATE-----"开头，以"-----END CERTIFICATE-----"结尾，自API12开始，为非必填项。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TLSConnectOptions](#tlsconnectoptions9) | 是 | TLSSocket连接所需要的参数。 |
| callback | AsyncCallback<void> | 是 | 回调函数，成功无返回，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303104 | Interrupted system call. |
| 2303109 | Bad file number. |
| 2303111 | Resource temporarily unavailable. Try again. |
| 2303188 | Socket operation on non-socket. |
| 2303191 | Incorrect socket protocol type. |
| 2303198 | Address already in use. |
| 2303199 | Cannot assign requested address. |
| 2303210 | Connection timed out. |
| 2303501 | SSL is null. |
| 2303502 | An error occurred when reading data on the TLS socket. |
| 2303503 | An error occurred when writing data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
| 2301206 | Socks5 failed to connect to the proxy server. |
| 2301207 | Socks5 username or password is invalid. |
| 2301208 | Socks5 failed to connect to the remote server. |
| 2301209 | Socks5 failed to negotiate the authentication method. |
| 2301210 | Socks5 failed to send the message. |
| 2301211 | Socks5 failed to receive the message. |
| 2301212 | Socks5 serialization error. |
| 2301213 | Socks5 deserialization error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsTwoWay: socket.TLSSocket = socket.constructTLSSocketInstance();  // Two way authentication
let bindAddr: socket.NetAddress = {
    address: '192.168.xx.xxx',
  // 绑定指定网络接口
}
tlsTwoWay.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let twoWayNetAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let twoWaySecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: twoWayNetAddr,
  secureOptions: twoWaySecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsTwoWay.connect(tlsConnectOptions, (err: BusinessError) => {
  console.error("connect callback error" + err);
});
let tlsOneWay: socket.TLSSocket = socket.constructTLSSocketInstance(); // One way authentication
tlsOneWay.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let oneWayNetAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let oneWaySecureOptions: socket.TLSSecureOptions = {
  ca: ["xxxx", "xxxx"],
  cipherSuite: "AES256-SHA256"
}
let tlsOneWayConnectOptions: socket.TLSConnectOptions = {
  address: oneWayNetAddr,
  secureOptions: oneWaySecureOptions
}
tlsOneWay.connect(tlsOneWayConnectOptions, (err: BusinessError) => {
  console.error("connect callback error" + err);
});
```
**示例（设置socket代理）：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsTwoWay: socket.TLSSocket = socket.constructTLSSocketInstance();  // 双向认证
let bindAddr: socket.NetAddress = {
   address: '192.168.xx.xxx',
  // 绑定指定网络接口
}
tlsTwoWay.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let twoWayNetAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let socks5Server: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let twoWaySecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let proxyOptions: socket.ProxyOptions = {
  type : 1,
  address: socks5Server,
  username: "xxx",
  password: "xxx"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: twoWayNetAddr,
  secureOptions: twoWaySecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"],
  proxy: proxyOptions,
}
tlsTwoWay.connect(tlsConnectOptions, (err: BusinessError) => {
  console.error("connect callback error" + err);
});
let tlsOneWay: socket.TLSSocket = socket.constructTLSSocketInstance(); // 单向认证
tlsOneWay.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let oneWayNetAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let oneWaySecureOptions: socket.TLSSecureOptions = {
  ca: ["xxxx", "xxxx"],
  cipherSuite: "AES256-SHA256"
}
let oneWayProxyOptions: socket.ProxyOptions = {
  type : 1,
  address: socks5Server,
  username: "xxx",
  password: "xxx"
}
let tlsOneWayConnectOptions: socket.TLSConnectOptions = {
  address: oneWayNetAddr,
  secureOptions: oneWaySecureOptions,
  proxy: oneWayProxyOptions,
}
tlsOneWay.connect(tlsOneWayConnectOptions, (err: BusinessError) => {
  console.error("connect callback error" + err);
});
```
#### connect9+
connect(options: TLSConnectOptions): Promise<void>
在TLSSocket上bind成功之后，进行通信连接，并创建和初始化TLS会话，实现建立连接过程，启动与服务器的TLS/SSL握手，实现数据传输功能，该连接包括两种认证方式，单向认证与双向认证，使用Promise异步回调。需要注意options入参下secureOptions内的ca在API11及之前的版本为必填项，需填入服务端的ca证书(用于认证校验服务端的数字证书)，证书内容以"-----BEGIN CERTIFICATE-----"开头，以"-----END CERTIFICATE-----"结尾，自API12开始，为非必填项。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TLSConnectOptions](#tlsconnectoptions9) | 是 | 连接所需要的参数。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回，成功无返回，失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303104 | Interrupted system call. |
| 2303109 | Bad file number. |
| 2303111 | Resource temporarily unavailable. Try again. |
| 2303188 | Socket operation on non-socket. |
| 2303191 | Incorrect socket protocol type. |
| 2303198 | Address already in use. |
| 2303199 | Cannot assign requested address. |
| 2303210 | Connection timed out. |
| 2303501 | SSL is null. |
| 2303502 | An error occurred when reading data on the TLS socket. |
| 2303503 | An error occurred when writing data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
| 2301206 | Socks5 failed to connect to the proxy server. |
| 2301207 | Socks5 username or password is invalid. |
| 2301208 | Socks5 failed to connect to the remote server. |
| 2301209 | Socks5 failed to negotiate the authentication method. |
| 2301210 | Socks5 failed to send the message. |
| 2301211 | Socks5 failed to receive the message. |
| 2301212 | Socks5 serialization error. |
| 2301213 | Socks5 deserialization error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsTwoWay: socket.TLSSocket = socket.constructTLSSocketInstance();  // Two way authentication
let bindAddr: socket.NetAddress = {
   address: '192.168.xx.xxx',
  // 绑定指定网络接口
}
tlsTwoWay.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let twoWayNetAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let twoWaySecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: twoWayNetAddr,
  secureOptions: twoWaySecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsTwoWay.connect(tlsConnectOptions).then(() => {
  console.info("connect successfully");
}).catch((err: BusinessError) => {
  console.error("connect failed " + JSON.stringify(err));
});
let tlsOneWay: socket.TLSSocket = socket.constructTLSSocketInstance(); // One way authentication
tlsOneWay.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let oneWayNetAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let oneWaySecureOptions: socket.TLSSecureOptions = {
  ca: ["xxxx", "xxxx"],
  cipherSuite: "AES256-SHA256"
}
let tlsOneWayConnectOptions: socket.TLSConnectOptions = {
  address: oneWayNetAddr,
  secureOptions: oneWaySecureOptions
}
tlsOneWay.connect(tlsOneWayConnectOptions).then(() => {
  console.info("connect successfully");
}).catch((err: BusinessError) => {
  console.error("connect failed " + JSON.stringify(err));
});
```
**示例（设置socket代理）：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsTwoWay: socket.TLSSocket = socket.constructTLSSocketInstance();  // 双向认证
let bindAddr: socket.NetAddress = {
   address: '192.168.xx.xxx',
  // 绑定指定网络接口
}
tlsTwoWay.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let twoWayNetAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let socks5Server: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let twoWaySecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let proxyOptions: socket.ProxyOptions = {
  type : 1,
  address: socks5Server,
  username: "xxx",
  password: "xxx"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: twoWayNetAddr,
  secureOptions: twoWaySecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"],
  proxy: proxyOptions,
}
tlsTwoWay.connect(tlsConnectOptions).then(() => {
  console.info("connect successfully");
}).catch((err: BusinessError) => {
  console.error("connect failed " + JSON.stringify(err));
});
let tlsOneWay: socket.TLSSocket = socket.constructTLSSocketInstance(); // 单向认证
tlsOneWay.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
let oneWayNetAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let oneWaySecureOptions: socket.TLSSecureOptions = {
  ca: ["xxxx", "xxxx"],
  cipherSuite: "AES256-SHA256"
}
let oneWayProxyOptions: socket.ProxyOptions = {
  type : 1,
  address: socks5Server,
  username: "xxx",
  password: "xxx"
}
let tlsOneWayConnectOptions: socket.TLSConnectOptions = {
  address: oneWayNetAddr,
  secureOptions: oneWaySecureOptions,
  proxy: oneWayProxyOptions,
}
tlsOneWay.connect(tlsOneWayConnectOptions).then(() => {
  console.info("connect successfully");
}).catch((err: BusinessError) => {
  console.error("connect failed " + JSON.stringify(err));
});
```
#### getRemoteAddress9+
getRemoteAddress(callback: AsyncCallback<NetAddress>): void
在TLSSocket通信连接成功之后，获取对端Socket地址。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[NetAddress](#netaddress)> | 是 | 回调函数。成功返回对端的socket地址，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getRemoteAddress((err: BusinessError, data: socket.NetAddress) => {
  if (err) {
    console.error('getRemoteAddress fail');
    return;
  }
  console.info('getRemoteAddress success:' + JSON.stringify(data));
});
```
#### getRemoteAddress9+
getRemoteAddress(): Promise<NetAddress>
在TLSSocket通信连接成功之后，获取对端Socket地址。使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取对端socket地址的结果。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getRemoteAddress().then(() => {
  console.info('getRemoteAddress success');
}).catch((err: BusinessError) => {
  console.error('getRemoteAddress fail');
});
```
#### getCertificate9+
getCertificate(callback: AsyncCallback< [X509CertRawData](#x509certrawdata9) >): void
在TLSSocket通信连接成功之后，获取本地的数字证书，该接口只适用于双向认证时，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[X509CertRawData](#x509certrawdata9)> | 是 | 回调函数，成功返回本地的证书，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303504 | An error occurred when verifying the X.509 certificate. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getCertificate((err: BusinessError, data: socket.X509CertRawData) => {
  if (err) {
    console.error("getCertificate callback error = " + err);
  } else {
    console.info("getCertificate callback = " + data);
  }
});
```
#### getCertificate9+
getCertificate():Promise< [X509CertRawData](#x509certrawdata9) >
在TLSSocket通信连接之后，获取本地的数字证书，该接口只适用于双向认证时，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[X509CertRawData](#x509certrawdata9)> | 以Promise形式返回本地的数字证书的结果。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303504 | An error occurred when verifying the X.509 certificate. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getCertificate().then((data: socket.X509CertRawData) => {
  const decoder = util.TextDecoder.create();
  const str = decoder.decodeToString(data.data);
  console.info("getCertificate: " + str);
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### getRemoteCertificate9+
getRemoteCertificate(callback: AsyncCallback< [X509CertRawData](#x509certrawdata9) >): void
在TLSSocket通信连接成功之后，获取服务端的数字证书，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[X509CertRawData](#x509certrawdata9)> | 是 | 回调函数，返回服务端的证书。失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getRemoteCertificate((err: BusinessError, data: socket.X509CertRawData) => {
  if (err) {
    console.error("getRemoteCertificate callback error = " + err);
  } else {
    const decoder = util.TextDecoder.create();
    const str = decoder.decodeToString(data.data);
    console.info("getRemoteCertificate callback = " + str);
  }
});
```
#### getRemoteCertificate9+
getRemoteCertificate():Promise< [X509CertRawData](#x509certrawdata9) >
在TLSSocket通信连接成功之后，获取服务端的数字证书，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[X509CertRawData](#x509certrawdata9)> | 以Promise形式返回服务端的数字证书的结果。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getRemoteCertificate().then((data: socket.X509CertRawData) => {
  const decoder = util.TextDecoder.create();
  const str = decoder.decodeToString(data.data);
  console.info("getRemoteCertificate:" + str);
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### getProtocol9+
getProtocol(callback: AsyncCallback<string>): void
在TLSSocket通信连接成功之后，获取通信的协议版本，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<string> | 是 | 回调函数，返回通信的协议。失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303505 | An error occurred in the TLS system call. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getProtocol((err: BusinessError, data: string) => {
  if (err) {
    console.error("getProtocol callback error = " + err);
  } else {
    console.info("getProtocol callback = " + data);
  }
});
```
#### getProtocol9+
getProtocol():Promise<string>
在TLSSocket通信连接成功之后，获取通信的协议版本，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<string> | 以Promise形式返回通信的协议。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303505 | An error occurred in the TLS system call. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getProtocol().then((data: string) => {
  console.info(data);
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### getCipherSuite9+
getCipherSuite(callback: AsyncCallback<Array<string>>): void
在TLSSocket通信连接成功之后，获取通信双方协商后的加密套件，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<Array<string>> | 是 | 回调函数，返回通信双方支持的加密套件。失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303502 | An error occurred when reading data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getCipherSuite((err: BusinessError, data: Array<string>) => {
  if (err) {
    console.error("getCipherSuite callback error = " + err);
  } else {
    console.info("getCipherSuite callback = " + data);
  }
});
```
#### getCipherSuite9+
getCipherSuite(): Promise<Array<string>>
在TLSSocket通信连接成功之后，获取通信双方协商后的加密套件，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<Array<string>> | 以Promise形式返回通信双方支持的加密套件。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303502 | An error occurred when reading data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getCipherSuite().then((data: Array<string>) => {
  console.info('getCipherSuite success:' + JSON.stringify(data));
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### getSignatureAlgorithms9+
getSignatureAlgorithms(callback: AsyncCallback<Array<string>>): void
在TLSSocket通信连接成功之后，获取通信双方协商后签名算法，该接口只适配双向认证模式下，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<Array<string>> | 是 | 回调函数，返回双方支持的签名算法。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getSignatureAlgorithms((err: BusinessError, data: Array<string>) => {
  if (err) {
    console.error("getSignatureAlgorithms callback error = " + err);
  } else {
    console.info("getSignatureAlgorithms callback = " + data);
  }
});
```
#### getSignatureAlgorithms9+
getSignatureAlgorithms(): Promise<Array<string>>
在TLSSocket通信连接成功之后，获取通信双方协商后的签名算法，该接口只适配双向认证模式下，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<Array<string>> | 以Promise形式返回获取到的双方支持的签名算法。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getSignatureAlgorithms().then((data: Array<string>) => {
  console.info("getSignatureAlgorithms success" + data);
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<NetAddress>
获取TLSSocket的本地Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/90/v3/PbH-ajyHSUyCCrtGCixbDg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=3EC79871C4B5979F093EACD9F07340A6660F28A91132F18B9A36B20C25E9B73B)
在TLSSocketServer通信连接成功之后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.getLocalAddress().then((localAddress: socket.NetAddress) => {
  console.info("Get success: " + JSON.stringify(localAddress));
}).catch((err: BusinessError) => {
  console.error("Get failed, error: " + JSON.stringify(err));
})
```
#### getSocketFd16+
getSocketFd(): Promise<number>
获取TLSSocket的文件描述符。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/62/v3/3M_85a3oT6iUfTSaimx7-g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=FC12B5BB79DE7FAE5F2361DBBAE04ED7DBD1C4D85D31EC425094FFAF4F8760F2)
bind方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<number> | 以Promise形式返回socket的文件描述符。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
let bindAddr: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
tls.bind(bindAddr, (err: BusinessError) => {
  if (err) {
    console.error('bind fail');
    return;
  }
  console.info('bind success');
});
tls.getSocketFd().then((data: number) => {
  console.info("tls socket fd: " + data);
})
```
#### send9+
send(data: string | ArrayBuffer, callback: AsyncCallback<void>): void
在TLSSocket通信连接成功之后，向服务端发送消息，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| data | string | ArrayBuffer | 是 | 发送的数据内容。 |
| callback | AsyncCallback<void> | 是 | 回调函数,返回TLSSocket发送数据的结果。失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303503 | An error occurred when writing data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.send("xxxx", (err: BusinessError) => {
  if (err) {
    console.error("send callback error = " + err);
  } else {
    console.info("send success");
  }
});
```
#### send9+
send(data: string | ArrayBuffer): Promise<void>
在TLSSocket通信连接成功之后，向服务端发送消息，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| data | string | ArrayBuffer | 是 | 发送的数据内容。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303503 | An error occurred when writing data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回,返回TLSSocket发送数据的结果。失败返回错误码，错误信息。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.send("xxxx").then(() => {
  console.info("send success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### close9+
close(callback: AsyncCallback<void>): void
在TLSSocket通信连接成功之后，断开连接，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<void> | 是 | 回调函数,成功返回TLSSocket关闭连接的结果。失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.close((err: BusinessError) => {
  if (err) {
    console.error("close callback error = " + err);
  } else {
    console.info("close success");
  }
});
```
#### close9+
close(): Promise<void>
在TLSSocket通信连接成功之后，断开连接，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回,返回TLSSocket关闭连接的结果。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tls: socket.TLSSocket = socket.constructTLSSocketInstance();
tls.close().then(() => {
  console.info("close success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### TLSConnectOptions9+
TLS连接的操作。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| address | [NetAddress](#netaddress) | 否 | 否 | 网关地址。 |
| secureOptions | [TLSSecureOptions](#tlssecureoptions9) | 否 | 否 | TLS安全相关操作。 |
| ALPNProtocols | Array<string> | 否 | 是 | ALPN协议，支持["spdy/1", "http/1.1"]，默认为[]。 |
| skipRemoteValidation12+ | boolean | 否 | 是 | 是否跳过对服务端进行证书认证，默认为false。true：跳过对服务端进行证书认证；false：不跳过对服务端进行证书认证。 |
| proxy18+ | [ProxyOptions](#proxyoptions18) | 否 | 是 | 使用的代理信息，默认不使用代理。 |
| timeout22+ | number | 否 | 是 | 连接超时时间，单位：ms，默认为0。传入值需为0-4294967295范围内的整数。TLSSocket连接在超时后会失败。 |
#### TLSSecureOptions9+
TLS安全相关操作。当本地证书cert和私钥key不为空时，开启双向验证模式。cert和key其中一项为空时，开启单向验证模式。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| ca | string | Array<string> | 否 | 是 | 服务端的ca证书，用于认证校验服务端的数字证书。默认为系统预置CA证书12+。 |
| cert | string | 否 | 是 | 本地客户端的数字证书。 |
| key | string | 否 | 是 | 本地数字证书的私钥。 |
| password | string | 否 | 是 | 读取私钥的密码。 |
| protocols | [Protocol](#protocol9)|Array<[Protocol](#protocol9)> | 否 | 是 | TLS的协议版本，默认为"TLSv1.2"。 |
| useRemoteCipherPrefer | boolean | 否 | 是 | 优先使用对等方的密码套件。true：优先使用对等方的密码套件；false：不优先使用对等方的密码套件。 |
| signatureAlgorithms | string | 否 | 是 | 通信过程中的签名算法，默认为"" 。 |
| cipherSuite | string | 否 | 是 | 通信过程中的加密套件，默认为"" 。 |
| isBidirectionalAuthentication12+ | boolean | 否 | 是 | 用于设置双向认证，默认为false。true：设置双向认证；false：不设置双向认证。 |
#### Protocol9+
TLS通信的协议版本。
**系统能力** ：SystemCapability.Communication.NetStack
| 名称 | 值 | 说明 |
| --- | --- | --- |
| TLSv12 | "TLSv1.2" | 使用TLSv1.2协议通信。 |
| TLSv13 | "TLSv1.3" | 使用TLSv1.3协议通信。 |
#### X509CertRawData9+
type X509CertRawData = cert.EncodingBlob
存储证书的数据。
**系统能力** ：SystemCapability.Communication.NetStack
| 类型 | 说明 |
| --- | --- |
| cert.EncodingBlob | 提供证书编码blob类型。 |
#### socket.constructTLSSocketServerInstance10+
constructTLSSocketServerInstance(): TLSSocketServer
创建并返回一个TLSSocketServer对象。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值:**
| 类型 | 说明 |
| --- | --- |
| [TLSSocketServer](#tlssocketserver10) | 返回一个TLSSocketServer对象。 |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
```
#### TLSSocketServer10+
TLSSocketServer连接。在调用TLSSocketServer的方法前，需要先通过 [socket.constructTLSSocketServerInstance](#socketconstructtlssocketserverinstance10) 创建TLSSocketServer对象。
#### listen10+
listen(options: TLSConnectOptions, callback: AsyncCallback<void>): void
绑定IP地址和端口，在TLSSocketServer上bind成功之后，监听客户端的连接，创建和初始化TLS会话，实现建立连接过程，加载证书秘钥并验证，使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/66/v3/-ST75xRQTF6XSQWqG9MahQ/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=5C1B2A5BB55EFDEA950ED385D3BAD5385259474E4E1BB4F8C8980186CC526362)
IP地址设置为0.0.0.0时，可以监听本机所有地址。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TLSConnectOptions](#tlsconnectoptions9) | 是 | TLSSocketServer连接所需要的参数。 |
| callback | AsyncCallback<void> | 是 | 回调函数，成功返回空，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303109 | Bad file number. |
| 2303111 | Resource temporarily unavailable. Try again. |
| 2303198 | Address already in use. |
| 2303199 | Cannot assign requested address. |
| 2303501 | SSL is null. |
| 2303502 | An error occurred when reading data on the TLS socket. |
| 2303503 | An error occurred when writing data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"],
  skipRemoteValidation: false
}
tlsServer.listen(tlsConnectOptions, (err: BusinessError) => {
  console.error("listen callback error" + err);
});
```
#### listen10+
listen(options: TLSConnectOptions): Promise<void>
绑定IP地址和端口，在TLSSocketServer上bind成功之后，监听客户端的连接，并创建和初始化TLS会话，实现建立连接过程，加载证书秘钥并验证，使用Promise异步回调。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TLSConnectOptions](#tlsconnectoptions9) | 是 | 连接所需要的参数。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回，成功返回空，失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 201 | Permission denied. |
| 2300002 | System internal error. |
| 2303109 | Bad file number. |
| 2303111 | Resource temporarily unavailable. Try again. |
| 2303198 | Address already in use. |
| 2303199 | Cannot assign requested address. |
| 2303501 | SSL is null. |
| 2303502 | An error occurred when reading data on the TLS socket. |
| 2303503 | An error occurred when writing data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"],
  skipRemoteValidation: false
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
```
#### getState10+
getState(callback: AsyncCallback<SocketStateBase>): void
在TLSSocketServer的listen成功之后，获取TLSSocketServer状态。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b7/v3/E9RRVsREStiIieDFQE3_sg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=0299461CBA42334E1BEFDDDC1CDB594D4C5A1E3C5339D85A591579F2F427E9A6)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[SocketStateBase](#socketstatebase)> | 是 | 回调函数。成功返回TLSSocketServer状态，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
tlsServer.getState((err: BusinessError, data: socket.SocketStateBase) => {
  if (err) {
    console.error('getState fail');
    return;
  }
  console.info('getState success:' + JSON.stringify(data));
});
```
#### getState10+
getState(): Promise<SocketStateBase>
在TLSSocketServer的listen成功之后，获取TLSSocketServer状态。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/dd/v3/1rJkg6J8SY6JnZOFczYFzw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=7F125EB0528367A248547F78007121999752B0E4B47EED3EFE620FFC6CCC22A4)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SocketStateBase](#socketstatebase)> | 以Promise形式返回获取TLSSocketServer状态的结果。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
tlsServer.getState().then(() => {
  console.info('getState success');
}).catch((err: BusinessError) => {
  console.error('getState fail');
});
```
#### setExtraOptions10+
setExtraOptions(options: TCPExtraOptions, callback: AsyncCallback<void>): void
在TLSSocketServer的listen成功之后，设置TLSSocketServer连接的其他属性。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/48/v3/3A8kMJ0bRB-pRlVhqUNWUA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=23D325B41C5B8032882FD218C7CFAABD8FAB85709B84CDCB50008337D308AEC2)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPExtraOptions](#tcpextraoptions) | 是 | TLSSocketServer连接的其他属性。 |
| callback | AsyncCallback<void> | 是 | 回调函数。成功返回空，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
interface SocketLinger {
  on: boolean;
  linger: number;
}
let tcpExtraOptions: socket.TCPExtraOptions = {
  keepAlive: true,
  OOBInline: true,
  TCPNoDelay: true,
  socketLinger: { on: true, linger: 10 } as SocketLinger,
  receiveBufferSize: 8192,
  sendBufferSize: 8192,
  reuseAddress: true,
  socketTimeout: 3000
}
tlsServer.setExtraOptions(tcpExtraOptions, (err: BusinessError) => {
  if (err) {
    console.error('setExtraOptions fail');
    return;
  }
  console.info('setExtraOptions success');
});
```
#### setExtraOptions10+
setExtraOptions(options: TCPExtraOptions): Promise<void>
在TLSSocketServer的listen成功之后，设置TLSSocketServer连接的其他属性，使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f1/v3/ESFAkAw3So2KTfSZ-WO3mg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=410019DB2B01BF6E8C95A52BCC3A74646D1FEC81574B403F036A8642AA58FF71)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [TCPExtraOptions](#tcpextraoptions) | 是 | TLSSocketServer连接的其他属性。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回，成功返回空，失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
interface SocketLinger {
  on: boolean;
  linger: number;
}
let tcpExtraOptions: socket.TCPExtraOptions = {
  keepAlive: true,
  OOBInline: true,
  TCPNoDelay: true,
  socketLinger: { on: true, linger: 10 } as SocketLinger,
  receiveBufferSize: 8192,
  sendBufferSize: 8192,
  reuseAddress: true,
  socketTimeout: 3000
}
tlsServer.setExtraOptions(tcpExtraOptions).then(() => {
  console.info('setExtraOptions success');
}).catch((err: BusinessError) => {
  console.error('setExtraOptions fail');
});
```
#### getCertificate10+
getCertificate(callback: AsyncCallback< [X509CertRawData](#x509certrawdata9) >): void
在TLSSocketServer通信连接成功之后，获取本地的数字证书，使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/81/v3/qU4SsK1SQg2lzEpvhd6WkQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=95F5B72F68CF8B02FD1BDA0B41011BA998BDEE83CCB53437DE662FFC82448CAE)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[X509CertRawData](#x509certrawdata9)> | 是 | 回调函数，成功返回本地的证书，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303504 | An error occurred when verifying the X.509 certificate. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
tlsServer.getCertificate((err: BusinessError, data: socket.X509CertRawData) => {
  if (err) {
    console.error("getCertificate callback error = " + err);
  } else {
    const decoder = util.TextDecoder.create();
    const str = decoder.decodeToString(data.data);
    console.info("getCertificate callback: " + str);
  }
});
```
#### getCertificate10+
getCertificate():Promise< [X509CertRawData](#x509certrawdata9) >
在TLSSocketServer通信连接之后，获取本地的数字证书，使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/82/v3/1d0XSwohT3enW1dXVG5W6w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=95257476DE78A0AB2CF20405F0242B837D14CAFB53AEFBB722336CCA4125926F)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[X509CertRawData](#x509certrawdata9)> | 以Promise形式返回本地的数字证书的结果。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303504 | An error occurred when verifying the X.509 certificate. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
tlsServer.getCertificate().then((data: socket.X509CertRawData) => {
  const decoder = util.TextDecoder.create();
  const str = decoder.decodeToString(data.data);
  console.info("getCertificate: " + str);
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### getProtocol10+
getProtocol(callback: AsyncCallback<string>): void
在TLSSocketServer通信连接成功之后，获取通信的协议版本，使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6e/v3/5XL31ZpFQMCg5H5G850GeQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=DEEDE6995DE7281A71AE9BB7FC6C93D9E2ACD083BBFBB56268F36E5FF1E5CAAC)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<string> | 是 | 回调函数，返回通信的协议。失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303505 | An error occurred in the TLS system call. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
tlsServer.getProtocol((err: BusinessError, data: string) => {
  if (err) {
    console.error("getProtocol callback error = " + err);
  } else {
    console.info("getProtocol callback = " + data);
  }
});
```
#### getProtocol10+
getProtocol():Promise<string>
在TLSSocketServer通信连接成功之后，获取通信的协议版本，使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f3/v3/6w5-lF79Q5OF4Y_2oPGP6w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=B591434630635B536287E68BEE3AC4C650DCB83EC379924AA92B2030AB4936B9)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<string> | 以Promise形式返回通信的协议。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303505 | An error occurred in the TLS system call. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
tlsServer.getProtocol().then((data: string) => {
  console.info(data);
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<NetAddress>
获取TLSSocketServer的本地Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/15/v3/_fxMCdgQQPC4my1bVJ8_Qw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=914DD0FA6A3E4BB1383440365252889CD5E4770471946B646FA45F367DA39AC7)
在TLSSocketServer通信连接成功之后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
tlsServer.getLocalAddress().then((localAddress: socket.NetAddress) => {
  console.info("Get success: " + JSON.stringify(localAddress));
}).catch((err: BusinessError) => {
  console.error("Get failed, error: " + JSON.stringify(err));
})
```
#### on('connect')10+
on(type: 'connect', callback: Callback<TLSSocketConnection>): void
订阅TLSSocketServer的连接事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/bb/v3/Us8vjLYcTR2OFH0xqYBqPg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=D30658AB6037067226BA611797D6E7C7338A29C040CB9276E4BD862D7DA5493B)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'connect'：连接事件。 |
| callback | Callback<[TLSSocketConnection](#tlssocketconnection10)> | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
  tlsServer.on('connect', (data: socket.TLSSocketConnection) => {
    console.info(JSON.stringify(data));
  });
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
```
#### off('connect')10+
off(type: 'connect', callback?: Callback<TLSSocketConnection>): void
取消订阅TLSSocketServer的连接事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/28/v3/DzfoQXaqQK6MDCIAbyny_g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=34D5134158C8AB391D2F1EE2BF46530CB6D8AB9D40D9726C42AC8FF086CF1318)
listen方法调用成功后，才可调用此方法。
可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'connect'：连接事件。 |
| callback | Callback<[TLSSocketConnection](#tlssocketconnection10)> | 否 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
let callback = (data: socket.TLSSocketConnection) => {
  console.info('on connect message: ' + JSON.stringify(data));
}
tlsServer.on('connect', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tlsServer.off('connect', callback);
tlsServer.off('connect');
```
#### on('error')10+
on(type: 'error', callback: ErrorCallback): void
订阅TLSSocketServer连接的error事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4e/v3/DZAl8AXRTWOq0sa_A9c0BA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=52A7802D77810670763E8ABF76F5B185285D24D2F103E4C682F051A3DA846959)
listen方法调用成功后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
tlsServer.on('error', (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err))
});
```
#### off('error')10+
off(type: 'error', callback?: ErrorCallback): void
取消订阅TLSSocketServer连接的error事件。使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/20/v3/9VmlAqh8TamTl41iwYOoiw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=C980BC44B937473A83FF69A53656595CF71B85B059010D7E3FBA01620DC53E66)
listen方法调用成功后，才可调用此方法。
可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed: " + JSON.stringify(err));
});
let callback = (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err));
}
tlsServer.on('error', callback);
// 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
tlsServer.off('error', callback);
tlsServer.off('error');
```
#### close20+
close(): Promise<void>
TLSSocketServer停止监听并释放通过 [listen](#listen10-2) 方法绑定的端口。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ad/v3/vyY0FP1STM2zrE9oggI9Zg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=DD4C01D7174534302B3B0D611DA3C5223013E4CF87CA29C20241C10B0530950A)
该方法不会关闭已有连接。如需关闭，请调用 [TLSSocketConnection](#tlssocketconnection10) 的 [close](#close10-2) 方法。
**需要权限** ：ohos.permission.INTERNET
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象，无返回结果。 |
**错误码：**
以下错误码的详细介绍请参见 [Socket错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/错误码/errorcode-net-socket.md) 和 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.on('connect', (connection: socket.TLSSocketConnection) => {
  console.info("connection clientId: " + connection.clientId);
  // 逻辑处理
  tlsServer.close(); // 停止监听
  connection.close(); // 关闭当前连接
});
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("listen failed: " + err.code);
});
```
#### TLSSocketConnection10+
TLSSocketConnection连接，即TLSSocket客户端与服务端的连接。在调用TLSSocketConnection的方法前，需要先获取TLSSocketConnection对象。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/7d/v3/C6UKRzTVQq6uV88l8RAbMg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=C102A67888A1158335C2A7122649FB5427D63736E6A1275BB062D3B0B3797FFA)
客户端与服务端成功建立连接后，才能通过返回的TLSSocketConnection对象调用相应的接口。
**系统能力** ：SystemCapability.Communication.NetStack
#### 属性
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| clientId | number | 否 | 否 | 客户端与TLSSocketServer建立连接的id。 |
#### send10+
send(data: string | ArrayBuffer, callback: AsyncCallback<void>): void
在TLSSocketServer通信连接成功之后，向客户端发送消息，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| data | string | ArrayBuffer | 是 | TLSSocketServer发送数据所需要的参数。 |
| callback | AsyncCallback<void> | 是 | 回调函数，成功返回空，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303503 | An error occurred when writing data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.send('Hello, client!', (err: BusinessError) => {
    if (err) {
      console.error('send fail');
      return;
    }
    console.info('send success');
  });
});
```
#### send10+
send(data: string | ArrayBuffer): Promise<void>
在TLSSocketServer通信连接成功之后，向服务端发送消息，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| data | string | ArrayBuffer | 是 | TLSSocketServer发送数据所需要的参数。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回，成功返回空，失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303503 | An error occurred when writing data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.send('Hello, client!').then(() => {
    console.info('send success');
  }).catch((err: BusinessError) => {
    console.error('send fail');
  });
});
```
#### close10+
close(callback: AsyncCallback<void>): void
在与TLSSocketServer通信连接成功之后，断开连接，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<void> | 是 | 回调函数，成功返回空，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.close((err: BusinessError) => {
    if (err) {
      console.error('close fail');
      return;
    }
    console.info('close success');
  });
});
```
#### close10+
close(): Promise<void>
在与TLSSocketServer通信连接成功之后，断开连接，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 以Promise形式返回，成功返回空。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303505 | An error occurred in the TLS system call. |
| 2303506 | Failed to close the TLS connection. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.close().then(() => {
    console.info('close success');
  }).catch((err: BusinessError) => {
    console.error('close fail');
  });
});
```
#### getRemoteAddress10+
getRemoteAddress(callback: AsyncCallback<NetAddress>): void
在TLSSocketServer通信连接成功之后，获取对端Socket地址。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[NetAddress](#netaddress)> | 是 | 回调函数。成功返回对端的socket地址，失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getRemoteAddress((err: BusinessError, data: socket.NetAddress) => {
    if (err) {
      console.error('getRemoteAddress fail');
      return;
    }
    console.info('getRemoteAddress success:' + JSON.stringify(data));
  });
});
```
#### getRemoteAddress10+
getRemoteAddress(): Promise<NetAddress>
在TLSSocketServer通信连接成功之后，获取对端Socket地址。使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取对端socket地址的结果。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303188 | Socket operation on non-socket. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getRemoteAddress().then((data: socket.NetAddress) => {
    console.info('getRemoteAddress success:' + JSON.stringify(data));
  }).catch((err: BusinessError) => {
    console.error("failed" + err);
  });
});
```
#### getRemoteCertificate10+
getRemoteCertificate(callback: AsyncCallback< [X509CertRawData](#x509certrawdata9) >): void
在TLSSocketServer通信连接成功之后，获取对端的数字证书，该接口只适用于客户端向服务端发送证书时，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<[X509CertRawData](#x509certrawdata9)> | 是 | 回调函数，返回对端的证书。失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getRemoteCertificate((err: BusinessError, data: socket.X509CertRawData) => {
    if (err) {
      console.error("getRemoteCertificate callback error: " + err);
    } else {
      const decoder = util.TextDecoder.create();
      const str = decoder.decodeToString(data.data);
      console.info("getRemoteCertificate callback: " + str);
    }
  });
});
```
#### getRemoteCertificate10+
getRemoteCertificate():Promise< [X509CertRawData](#x509certrawdata9) >
在TLSSocketServer通信连接成功之后，获取对端的数字证书，该接口只适用于客户端向服务端发送证书时，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[X509CertRawData](#x509certrawdata9)> | 以Promise形式返回对端的数字证书的结果。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getRemoteCertificate().then((data: socket.X509CertRawData) => {
    const decoder = util.TextDecoder.create();
    const str = decoder.decodeToString(data.data);
    console.info("getRemoteCertificate success: " + str);
  }).catch((err: BusinessError) => {
    console.error("failed" + err);
  });
});
```
#### getCipherSuite10+
getCipherSuite(callback: AsyncCallback<Array<string>>): void
在TLSSocketServer通信连接成功之后，获取通信双方协商后的加密套件，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<Array<string>> | 是 | 回调函数，返回通信双方支持的加密套件。失败返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2303502 | An error occurred when reading data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getCipherSuite((err: BusinessError, data: Array<string>) => {
    if (err) {
      console.error("getCipherSuite callback error = " + err);
    } else {
      console.info("getCipherSuite callback = " + data);
    }
  });
});
```
#### getCipherSuite10+
getCipherSuite(): Promise<Array<string>>
在TLSSocketServer通信连接成功之后，获取通信双方协商后的加密套件，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<Array<string>> | 以Promise形式返回通信双方支持的加密套件。失败返回错误码，错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2303502 | An error occurred when reading data on the TLS socket. |
| 2303505 | An error occurred in the TLS system call. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getCipherSuite().then((data: Array<string>) => {
    console.info('getCipherSuite success:' + JSON.stringify(data));
  }).catch((err: BusinessError) => {
    console.error("failed" + err);
  });
});
```
#### getSignatureAlgorithms10+
getSignatureAlgorithms(callback: AsyncCallback<Array<string>>): void
在TLSSocketServer通信连接成功之后，获取通信双方协商后签名算法，使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<Array<string>> | 是 | 回调函数，返回双方支持的签名算法。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
| 2303501 | SSL is null. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getSignatureAlgorithms((err: BusinessError, data: Array<string>) => {
    if (err) {
      console.error("getSignatureAlgorithms callback error = " + err);
    } else {
      console.info("getSignatureAlgorithms callback = " + data);
    }
  });
});
```
#### getSignatureAlgorithms10+
getSignatureAlgorithms(): Promise<Array<string>>
在TLSSocketServer通信连接成功之后，获取通信双方协商后的签名算法，使用Promise异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<Array<string>> | 以Promise形式返回获取到的双方支持的签名算法。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2303501 | SSL is null. |
| 2300002 | System internal error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getSignatureAlgorithms().then((data: Array<string>) => {
    console.info("getSignatureAlgorithms success" + data);
  }).catch((err: BusinessError) => {
    console.error("failed" + err);
  });
});
```
#### getLocalAddress12+
getLocalAddress(): Promise<NetAddress>
获取TLSSocketConnection连接的本地Socket地址。使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/37/v3/VXyIftDeSQmWoUnwrQ93KQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093303Z&HW-CC-Expire=86400&HW-CC-Sign=60B9BCDF79FF83CD7D505FD72E9168D64CEA89F8EDDD35A977B61759707AD868)
在TLSSocketServer通信连接成功之后，才可调用此方法。
**系统能力** ：SystemCapability.Communication.NetStack
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[NetAddress](#netaddress)> | 以Promise形式返回获取本地socket地址的结果。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 2300002 | System internal error. |
| 2301009 | Bad file descriptor. |
| 2303188 | Socket operation on non-socket. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.getLocalAddress().then((localAddress: socket.NetAddress) => {
    console.info("Family IP Port: " + JSON.stringify(localAddress));
  }).catch((err: BusinessError) => {
    console.error("TLS Client Get Family IP Port failed, error: " + JSON.stringify(err));
  })
});
```
#### on('message')10+
on(type: 'message', callback: Callback<SocketMessageInfo>): void
订阅TLSSocketConnection连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 是 | 回调函数。成功时返回TLSSocketConnection连接信息，失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.on('message', (value: socket.SocketMessageInfo) => {
    let messageView = '';
    let uint8Array = new Uint8Array(value.message);
    for (let i: number = 0; i < value.message.byteLength; i++) {
      let messages = uint8Array[i];
      let message = String.fromCharCode(messages);
      messageView += message;
    }
    console.info('on message message: ' + JSON.stringify(messageView));
    console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
  });
});
```
#### off('message')10+
off(type: 'message', callback?: Callback<SocketMessageInfo>): void
取消订阅TLSSocketConnection连接的接收消息事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'message'：接收消息事件。 |
| callback | Callback<[SocketMessageInfo](#socketmessageinfo11)> | 否 | 回调函数。成功时返回TLSSocketConnection连接信息，失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
let callback = (value: socket.SocketMessageInfo) => {
  let messageView = '';
  for (let i: number = 0; i < value.message.byteLength; i++) {
    let uint8Array = new Uint8Array(value.message)
    let messages = uint8Array[i]
    let message = String.fromCharCode(messages);
    messageView += message;
  }
  console.info('on message message: ' + JSON.stringify(messageView));
  console.info('remoteInfo: ' + JSON.stringify(value.remoteInfo));
}
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.on('message', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  client.off('message', callback);
  client.off('message');
});
```
#### on('close')10+
on(type: 'close', callback: Callback<void>): void
订阅TLSSocketConnection的关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'close'：关闭事件。 |
| callback | Callback<void> | 是 | 回调函数。成功时返回空，失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.on('close', () => {
    console.info("on close success")
  });
});
```
#### off('close')10+
off(type: 'close', callback?: Callback<void>): void
取消订阅TLSSocketConnection的关闭事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'close'：关闭事件。 |
| callback | Callback<void> | 否 | 回调函数。成功时返回空，失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
let callback = () => {
  console.info("on close success");
}
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.on('close', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  client.off('close', callback);
  client.off('close');
});
```
#### on('error')10+
on(type: 'error', callback: ErrorCallback): void
订阅TLSSocketConnection连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 是 | 回调函数。成功时返回空，失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.on('error', (err: BusinessError) => {
    console.error("on error, err:" + JSON.stringify(err))
  });
});
```
#### off('error')10+
off(type: 'error', callback?: ErrorCallback): void
取消订阅TLSSocketConnection连接的error事件。使用callback异步回调。
**系统能力** ：SystemCapability.Communication.NetStack
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 订阅的事件类型。'error'：error事件。 |
| callback | ErrorCallback | 否 | 回调函数。成功时返回空，失败时返回错误码、错误信息。 |
**错误码：**
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |
**示例：**
```
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
let netAddress: socket.NetAddress = {
  address: '192.168.xx.xxx',
  port: 8080
}
let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",
  cert: "xxxx",
  ca: ["xxxx"],
  password: "xxxx",
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
}
let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
}
tlsServer.listen(tlsConnectOptions).then(() => {
  console.info("listen callback success");
}).catch((err: BusinessError) => {
  console.error("failed" + err);
});
let callback = (err: BusinessError) => {
  console.error("on error, err:" + JSON.stringify(err));
}
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  client.on('error', callback);
  // 可以指定传入on中的callback取消一个订阅，也可以不指定callback清空所有订阅。
  client.off('error', callback);
  client.off('error');
});
```