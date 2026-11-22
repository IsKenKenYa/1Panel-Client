# @ohos.bluetooth.common (蓝牙common模块)
---
# @ohos.bluetooth.common (蓝牙common模块)
本模块提供了蓝牙公共接口和参数类型。首批接口包括在调用 [connection.pairDevice](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Connectivity Kit（短距通信服务）/ArkTS API/js-apis-bluetooth-connection.md) 时用于指定目标设备的MAC地址与地址类型的相关参数。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/95/v3/jQ4viFzdQCiES7fHFFWpYQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093250Z&HW-CC-Expire=86400&HW-CC-Sign=B815FB4D5B084CB74B6D5FCA66C6946F3ED83CEC2FC8D3704FD05A96FBF75E47)
本模块首批接口从API version 21开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。
#### 导入模块
```
import { common } from '@kit.ConnectivityKit';
```
#### BluetoothAddress
描述蓝牙设备地址信息的参数结构，包括地址与地址类型。
**系统能力** ：SystemCapability.Communication.Bluetooth.Core
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| address | string | 否 | 否 | 表示蓝牙设备的地址，例如："XX:XX:XX:XX:XX:XX"。 |
| addressType | [BluetoothAddressType](#bluetoothaddresstype) | 否 | 否 | 表示地址类型为蓝牙设备的实际MAC地址或虚拟MAC地址。 |
#### BluetoothAddressType
枚举，蓝牙设备的地址类型。蓝牙设备的实际MAC地址属于用户的隐私信息，在发现设备的过程中，蓝牙子系统会给每个蓝牙外设分配一个虚拟MAC地址，并保存该虚拟MAC地址和外设实际MAC地址的映射关系。
**系统能力** ：SystemCapability.Communication.Bluetooth.Core
| 名称 | 值 | 说明 |
| --- | --- | --- |
| VIRTUAL | 1 | 虚拟MAC地址类型。 |
| REAL | 2 | 实际MAC地址类型。 |