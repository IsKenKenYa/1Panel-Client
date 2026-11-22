# NetworkBoost_NetworkQosArray
---
# NetworkBoost_NetworkQosArray
#### 概述
网络质量变化的详细信息。
**起始版本：** 5.1.0(18)
**相关模块：**  [NetworkBoost](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
#### 汇总
#### 成员变量
| 名称 | 描述 |
| --- | --- |
| uint32_t[pathNum](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_qos_array) | 网络质量信息中的路径数量，取值范围 [1, 4]。 |
| [NetworkBoost_NetworkQos](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_qos)[networkQos](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_qos_array)[[NETBOOST_MAX_PATH_NUM](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)] | 多条路径的网络质量信息，每一项为一条路径的网络质量信息，取值范围 [0, pathNum-1]。 |
#### 结构体成员变量说明
#### networkQos
```
NetworkBoost_NetworkQos NetworkBoost_NetworkQosArray::networkQos[NETBOOST_MAX_PATH_NUM]
```
**描述**
多条路径的网络质量信息，每一项为一条路径的网络质量信息，取值范围 [0, pathNum-1]。
#### pathNum
```
uint32_t NetworkBoost_NetworkQosArray::pathNum
```
**描述**
网络质量信息中的路径数量，取值范围 [1, 4]。