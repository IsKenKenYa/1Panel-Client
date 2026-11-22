# 撤回通知消息
---
# 撤回通知消息
当推送的通知消息内容有误或者存在违规情况时，可能会引起用户投诉或监管部门处罚等不良后果。Push Kit为您提供消息撤回功能，降低此类推送可能造成的影响。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b1/v3/tkaE22T_Sva6e0b5KBtVeA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105258Z&HW-CC-Expire=86400&HW-CC-Sign=1C871E7BEE5E7552FF725D1A778241524F9B792E3A53098D6B275178BF6DF553)
-
消息撤回仅支持使用token和notifyId撤回。
-
若要使用消息撤回功能，请确保您在推送消息时设置了notifyId字段。
-
消息撤回仅支持以下类型：
还未下发到端侧的消息。
已在终端展示但用户还未点击的消息。
-
消息撤回不会影响应用的通知角标。
#### 约束与限制
撤回通知消息能力支持Phone、Tablet、PC/2in1设备。并且从5.1.0(18)版本开始，新增支持Wearable设备；从5.1.1(19)版本开始，新增支持TV设备。
#### 开发步骤
1.
参考 [开发步骤](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Push Kit（推送服务）/推送场景化消息/推送通知消息/发送通知消息/push-send-alert.md) 章节进行消息推送，确保应用可正常收到通知消息。
2.
应用服务端调用REST API撤回通知消息，消息详情可参见 [消息撤回](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Push Kit（推送服务）/REST API/push-msg-revoke.md) ，请求示例如下：
```
// Request URL
POST "https://push-api.cloud.huawei.com/v1/[clientId]/messages:revoke"
// Request Header
Content-Type:application/json
Authorization:Bearer eyJr*****OiIx---****.eyJh*****iJodHR--***.QRod*****4Gp---****
push-type: 0
// Request Body
{
  "notifyId": 1234567,
  "token": [
    "pushToken1",
    "pushToken2",
    "pushToken3"
  ]
}
```
- [clientId]：请替换为您应用的Client ID，可参见[指导](https://developer.huawei.com/consumer/cn/doc/app/agc-help-view-app-info-0000002282674569)获取。
- Authorization：JWT格式字符串，可参见[Authorization](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Push Kit（推送服务）/REST API/push-msg-revoke.md)获取。
- push-type：0表示通知消息场景。
- notifyId：消息ID，消息的唯一标识，详情请参见[notifyId](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Push Kit（推送服务）/REST API/push-msg-revoke.md)。
- token：Push Token，可参见[获取Push Token](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Push Kit（推送服务）/开发准备/获取Push Token/push-get-token.md)获取。