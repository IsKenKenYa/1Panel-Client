# 删除设备标记状态
---
# 删除设备标记状态
#### 功能介绍
开发者应用的服务端可调用本接口删除设备标记状态，开发者无需先调用checkDeviceToken接口做验证。
#### 场景描述
开发者应用的服务端可调用本接口删除设备标记状态，开发者无需先调用checkDeviceToken接口做验证，删除后标记在云端失效。
#### 使用约束
无
#### 接口原型
| **承载协议** | HTTPS POST |
| --- | --- |
| **接口方向** | 开发者服务器->Device Security服务器 |
| **接口URL** | https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/delDeviceStatus |
| **数据格式** | 请求消息头：Content-Type：application/json;charset=utf-8响应消息：Content-Type: application/json;charset=utf-8 |
#### 请求参数
**Request Header**
| 参数 | 是否必选 | 参数类型 | 描述 |
| --- | --- | --- | --- |
| Content-Type | 否 | String | 取值为：application/json;charset=utf-8。 |
| Authorization | 是 | String | 服务账号令牌 |
| bundleName | 是 | String | 开发者APP包名 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/10/v3/CuFKdnnZRJWaPHIiHIGu-g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093228Z&HW-CC-Expire=86400&HW-CC-Sign=023EA644341EE177A79311053370D340B16ACC33A5D1D4E14ACB82B7DBF265AE)
Authorization格式：Bearer后面拼接空格，再拼接获取的鉴权信息。令牌生成 [示例代码](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/安全/Device Security Kit（设备安全服务）/开发准备/基于服务账号生成鉴权令牌/devicesecurity-deviceverify-token.md) 。
**Request Body**
| 参数 | 是否必选 | 参数类型 | 描述 |
| --- | --- | --- | --- |
| mode | 是 | Int | 设备标记状态的粒度。取值：1 ：应用级2 ：开发者级 |
| deviceToken | 是 | String | 客户端调用[getDeviceToken](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Device Security Kit（设备安全服务）/ArkTS API/devicesecurity-deviceverify-api.md)获取的设备临时标识。 |
| transactionId | 否 | String | 应用服务的唯一事务标识，关联业务上下文消息。 |
| timestamp | 是 | Long | 应用服务器上的UTC时间。单位，毫秒。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1f/v3/Mayt3l86RGiuTL-53D4bxQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093228Z&HW-CC-Expire=86400&HW-CC-Sign=D62AB3DC615D4D23AE6B07F41117F6AFCF814A9D73EAEE0F148AB4C6CB05BD10)
开发者在构造消息体时，消息体需要在外层包一层data结构，详情参考如下调用示例。
#### 请求示例
```json
POST /api/rms/v1/deviceVerify/delDeviceStatus HTTP/1.1
Host: xxx
Authorization: Bearer eyJr*****OiIx---****.eyJh*****iJodHR--***.QRod*****4Gp---****
bundleName: com.huawei.xxx
Content-Type: application/json;charset=utf-8
{"data":{ "mode":1, "deviceToken":"xxx", "transactionId":"ddc740b9-45bb-424a-bc50-64e8a813acab", "timestamp":1711072205525}}
```
#### 响应参数
**Response Body**
| **参数** | 是否必选 | 参数类型 | 描述 |
| --- | --- | --- | --- |
| bundleName | 否 | String | 从token中获取的bundleName，供开发者校验。 |
| errorCodes | 是 | String | 错误码。 |
#### 响应示例
```json
HTTP/1.1 200 OK
Content-Type: application/json;charset=utf-8
{"bundleName":"xxx","errorCodes":"OK"}
```
#### 错误码
以下错误码的详细介绍请参见 [REST API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Device Security Kit（设备安全服务）/REST API/devicesecurity-restapi-errcode.md) 。
| **错误码** | **描述** |
| --- | --- |
| OK | 请求处理成功。 |
| NotFound | 未找到设备的标记记录（设备身份验证成功，该设备未被标记过）。 |
| InvalidBundleName | bundleName缺失或不合法。 |
| InvalidDeviceToken | deviceToken缺失或不合法。 |
| DeviceTokenExpired | deviceToken过期。 |
| InvalidMode | Mode缺失或者非法。 |
| InvalidTimeStamp | timeStamp缺失或不合法。 |
| InternalServerError | 内部服务器错误。 |