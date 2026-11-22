# 取消网络请求（ArkTS）
---
# 取消网络请求（ArkTS）
在远场通信服务的框架中，没有明确指定任何request的情况下，通过调用session.cancel，可以取消所有正在进行的网络请求。当开发者需要取消特定的一个网络请求时，可以使用session.cancel方法，并传入需要取消的请求，以实现这一目标。这样，开发者们就能根据具体需求，灵活地管理和控制网络请求的执行。
#### 约束与限制
取消网络请求能力支持Phone、2in1、Tablet、Wearable设备。并且从5.1.1(19)开始，新增支持TV设备；从6.1.0(23)开始，新增支持Car设备。
#### 接口说明
具体API说明详见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Remote Communication Kit（远场通信服务）/ArkTS API/remote-communication-rcp.md) 。
| 接口名 | 描述 |
| --- | --- |
| cancel(requestToCancel?:[Request](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Remote Communication Kit（远场通信服务）/ArkTS API/remote-communication-rcp.md)|[Request](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Remote Communication Kit（远场通信服务）/ArkTS API/remote-communication-rcp.md)[]): void | - 取消指定网络请求：传入需要取消的请求，返回值为空。- 取消所有网络请求：无需传入参数，直接调用，返回值为空。 |
#### 使用示例
1.
导入模块。
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
创建会话并创建两个Request，分别发起请求，在请求完成后进行cancel操作。
-
```typescript
// 创建会话
const session = rcp.createSession();
// 创建request1、request2
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");
// 分别发起请求
session.fetch(request1).then((response: rcp.Response) => {
  console.info(`The response1 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request1 error code is ${err.code}, error data is ${err.data}`);
})
session.fetch(request2).then((response: rcp.Response) => {
  console.info(`The response2 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request2 error code is ${err.code}, error data is ${err.data}`);
})
// 单独取消Request1、request2
session.cancel(request1);
session.cancel(request2);
```
-
```typescript
// 创建会话
const session = rcp.createSession();
// 创建request1、request2
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");
// 分别发起请求
session.fetch(request1).then((response: rcp.Response) => {
  console.info(`The response1 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request1 error code is ${err.code}, error data is ${err.data}`);
})
session.fetch(request2).then((response: rcp.Response) => {
  console.info(`The response2 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request2 error code is ${err.code}, error data is ${err.data}`);
})
// 取消全部request
session.cancel();
```