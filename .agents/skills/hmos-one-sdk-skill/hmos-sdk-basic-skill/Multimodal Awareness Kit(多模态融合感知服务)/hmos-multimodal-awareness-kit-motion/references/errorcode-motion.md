# 动作感知错误码
---
# 动作感知错误码
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/2b/v3/wEbFdY1oRAGplgRfXduqjA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093437Z&HW-CC-Expire=86400&HW-CC-Sign=12AB5C573180D46FD7D2FFFAB0B4CAEB3EB866EE04A8F3591C6E9CE1F4ABAEC5)
以下仅介绍本模块特有错误码，通用错误码请参考 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 说明文档。
#### 31500001 服务异常
**错误信息**
Service exception. Possible causes: 1. A system error, such as null pointer, container-related exception; 2. N-API invocation exception, invalid N-API status.
**错误描述**
当调用motion模块on、off、get接口时，若服务异常，会报此错误码。
**可能原因**
服务状态异常。
**处理步骤**
1. 定时重试操作，如间隔1s或者按照指数增长间隔重试。
2. 连续重试3次不可用则停止尝试，期间可优先尝试获取器件列表方式进一步获取设备可用性。
#### 31500002 订阅失败
**错误信息**
Subscription failed. Possible causes: 1. Callback registration failure; 2. Failed to bind native object to js wrapper; 3. N-API invocation exception, invalid N-API status; 4. IPC request exception.
**错误描述**
当调用motion模块on接口时，若订阅失败，会报此错误码。
**可能原因**
订阅异常。
**处理步骤**
1. 定时重试操作，如间隔1s或者按照指数增长间隔重试。
2. 连续重试3次不可用则停止尝试。
#### 31500003 取消订阅失败
**错误信息**
Unsubscription failed. Possible causes: 1. Callback failure; 2. N-API invocation exception, invalid N-API status; 3. IPC request exception.
**错误描述**
当调用motion模块off接口时，若取消订阅失败，会报此错误码。
**可能原因**
取消订阅异常。
**处理步骤**
1. 定时重试操作，如间隔1s或者按照指数增长间隔重试。
2. 连续重试3次不可用则停止尝试。