# 订阅确认发货
---
# 订阅确认发货
#### 功能介绍
此接口用于确认购买的自动续期订阅商品已经发放权益。
#### 场景描述
开发者服务器收到IAP服务器关键事件通知后，调用订阅状态查询接口获取订阅的最新状态，再根据订阅状态发放权益，具体请参见 [确保权益发放](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/IAP Kit（应用内支付服务）/商品购买/自动续期订阅商品购买/权益发放/iap-delivering-subscriptions.md) 。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/01/v3/X0JzLvNGQAKd9jTxlqAzwQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093818Z&HW-CC-Expire=86400&HW-CC-Sign=DD924CE61A37691AD9FE8DAD0BDC8C998D22E3929B655A8390EC139E41C5F5D1)
一个购买订单号ID（purchaseOrderId）只可以发货一次，请勿重复发货。
#### 接口原型
| 承载协议 | HTTPS POST |
| --- | --- |
| 接口方向 | 开发者服务器 -> IAP服务器 |
| 接口URL | {rootUrl}/subscription/harmony/v1/application/purchase/shipped/confirm说明：rootUrl：具体请参见[站点信息](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-rest-common-statement.md)。 |
| 数据格式 | 请求消息：Content-Type: application/json;charset=UTF-8响应消息：Content-Type: application/json;charset=UTF-8 |
#### 请求参数
#### Request Header
| 参数 | 是否必选 | 参数类型 | 描述 |
| --- | --- | --- | --- |
| Content-Type | 是 | String | 取值为：application/json;charset=UTF-8 |
| Authorization | 是 | String | 认证信息，使用JWT进行鉴权，具体请参见[Authorization说明](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-jwt-description.md)。 |
#### Request Body
| 参数 | 是否必选 | 参数类型 | 描述 |
| --- | --- | --- | --- |
| purchaseOrderId | 是 | String | 具体一笔订单中对应的购买订单号ID。最大长度256。 |
| purchaseToken | 是 | String | 商品的购买Token，发起购买和查询订单信息均会返回。最大长度256。 |
#### 请求示例
更多语言及详细的代码示例，请参考 **[IAP Kit-Sample-ServerDemo](https://gitcode.com/HarmonyOS_Samples/iapkit-sample-serverdemo)** 。
```
POST /subscription/harmony/v1/application/purchase/shipped/confirm
Content-Type: application/json;charset=UTF-8
Authorization: Bearer ***.***.***
Accept: application/json
{
  "purchaseToken": "***.*.***",
  "purchaseOrderId": "***.***"
}
```
#### 响应参数
#### Response Header
| 参数 | 是否必选 | 参数类型 | 描述 |
| --- | --- | --- | --- |
| Content-Type | 是 | String | 取值为：application/json;charset=UTF-8 |
#### Response Body
| 参数 | 是否必选 | 参数类型 | 描述 |
| --- | --- | --- | --- |
| responseCode | 是 | String | 返回码。0：成功。其他：失败，具体请参见[错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/IAP Kit（应用内支付服务）/REST API/iap-server-error-code.md)。 |
| responseMessage | 否 | String | 响应描述。 |
#### 响应示例
```
HTTP/1.2 200 OK
Content-Type: application/json;charset=UTF-8
{
  "responseCode": "0"
}
```