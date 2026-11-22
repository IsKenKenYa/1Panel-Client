# NetworkBoost_MultiPathQuota
---
# NetworkBoost_MultiPathQuota
#### 概述
应用配额信息，包含应用已使用配额信息和剩余配额信息。
**起始版本：** 6.0.2(22)
**相关模块：**  [NetworkBoost](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
#### 汇总
#### 成员变量
| 名称 | 描述 |
| --- | --- |
| [NetworkBoost_MultiPathQuotaInfo](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_quotainfo)[used](#section159871228122717) | 应用已使用配额信息。 |
| [NetworkBoost_MultiPathQuotaInfo](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_quotainfo)[remaining](#section2054235172714) | 应用剩余使用配额信息。 |
#### 结构体成员变量说明
#### used
```
NetworkBoost_MultiPathQuotaInfo NetworkBoost_MultiPathQuota::used
```
**描述**
表明应用已使用配额信息。
#### remaining
```
NetworkBoost_MultiPathQuotaInfo NetworkBoost_MultiPathQuota::remaining
```
**描述**
应用剩余使用配额信息。