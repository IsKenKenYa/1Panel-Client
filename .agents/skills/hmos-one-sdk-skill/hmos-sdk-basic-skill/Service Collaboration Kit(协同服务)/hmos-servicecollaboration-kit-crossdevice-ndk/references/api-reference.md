# ServiceCollaboration
---
# ServiceCollaboration
#### 概述
提供ServiceCollaboration跨设备互通的相关NDK接口。
**系统能力：** SystemCapability.Collaboration.Service
**起始版本：** 5.0.0(12)
#### 汇总
#### 文件
| 名称 | 描述 |
| --- | --- |
| [service_collaboration_api.h](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/头文件/servicecollaboration-capi-h.md) | 跨设备互通的接口以及相关类型的定义。 |
#### 结构体
| 名称 | 描述 |
| --- | --- |
| struct[ServiceCollaboration_CollaborationDeviceInfo](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/servicecollaboration-collaborationdeviceinfo.md) | 跨设备互通获取的设备信息对象，包含设备的基本信息和能力类型。 |
| struct[ServiceCollaboration_CollaborationDeviceInfoSets](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/servicecollaboration-collaborationdeviceinfosets.md) | 通过[HMS_ServiceCollaboration_GetCollaborationDeviceInfos](#gaeffea1546cbe64aeba533e5b72bca7ba)获取的对端设备信息对象集合。 |
| struct[ServiceCollaboration_SelectInfo](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/servicecollaboration-selectinfo.md) | 使用[HMS_ServiceCollaboration_StartCollaboration](#section4531193410296)触发跨设备互通时，被选择的设备信息。 |
| struct[ServiceCollaborationCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/ServiceCollaborationCallback.md) | 传给[HMS_ServiceCollaboration_StartCollaboration](#section4531193410296)的回调方法。 |
#### 宏定义
| 名称 | 描述 |
| --- | --- |
| [COLLABORATIONDEVICEINFO_DEVICENETWORKID_MAXLENGTH](#ga22d10f5d68c518533857b4a3e5947647)65 | 设备network Id最大长度。 |
| [COLLABORATIONDEVICEINFO_DEVICENAME_MAXLENGTH](#section115253318501)128 | 设备名最大长度。 |
#### 类型定义
| 名称 | 描述 |
| --- | --- |
| typedef enum[ServiceCollaborationFilterType](#section16675437105618)[ServiceCollaborationFilterType](#ga1d033f8a2e87fab0e1e01cb1e9859243) | 跨设备互通能力类型枚举。 |
| typedef enum[ServiceCollaborationDataType](#section1467523718564)[ServiceCollaborationDataType](#ga3547eca8cf19ab049ffc992e5b712142) | 回传数据类型。 |
| typedef enum[ServiceCollaborationEventCode](#section967514377563)[ServiceCollaborationEventCode](#ga7ff0af9a33e5e5a3acfada94d422a60b) | 错误码枚举。 |
| typedef struct[ServiceCollaboration_CollaborationDeviceInfo](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/servicecollaboration-collaborationdeviceinfo.md)[ServiceCollaboration_CollaborationDeviceInfo](#ga36cefd0afb1105cdbc28b9460d5f336f) | 设备信息对象。 |
| typedef struct[ServiceCollaboration_CollaborationDeviceInfoSets](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/servicecollaboration-collaborationdeviceinfosets.md)[ServiceCollaboration_CollaborationDeviceInfoSets](#section121718545319) | 设备信息对象集合。 |
| typedef struct[ServiceCollaboration_SelectInfo](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/servicecollaboration-selectinfo.md)[ServiceCollaboration_SelectInfo](#section1871418518535) | 被选择的设备信息。 |
| typedef struct[ServiceCollaborationCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/ServiceCollaborationCallback.md)[ServiceCollaborationCallback](#section1958717716536) | 回调跨设备互通状态信息。 |
#### 枚举
| 名称 | 描述 |
| --- | --- |
| [ServiceCollaborationFilterType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/模块/servicecollaboration-capi-module.md){TAKE_PHOTO = 1,SCAN_DOCUMENT = 2,IMAGE_PICKER = 3} | 跨设备互通能力类型的枚举。 |
| [ServiceCollaborationDataType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/模块/servicecollaboration-capi-module.md){IMAGE = 1} | 回传数据类型。 |
| [ServiceCollaborationEventCode](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/模块/servicecollaboration-capi-module.md){LAST_DATA_BACK = 1001202000,PEER_CANCEL = 1001202001,NETWORK_ERROR = 1001202002,PEER_WIFI_NOT_OPEN = 1001202004,LOCAL_WIFI_NOT_OPEN = 1001202005,DATA_BACK_START = 1001202006,MIDDLE_DATA_BACK = 1001202007,TIMEOUT_AUTO_CANCEL = 1001202008,DATA_READ_FAILED = 1001202009,LINK_SHUTDOWN = 1001202011,REMOTE_HOTSPOT_CONFLICT = 1001202013,REMOTE_DISTRIBUTED_SERVICES_CONFLICT = 1001202014} | 错误码枚举。 |
#### 函数
| 名称 | 描述 |
| --- | --- |
| [ServiceCollaboration_CollaborationDeviceInfoSets](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/servicecollaboration-collaborationdeviceinfosets.md)*[HMS_ServiceCollaboration_GetCollaborationDeviceInfos](#gaeffea1546cbe64aeba533e5b72bca7ba)(uint32_t fileterNum,[ServiceCollaborationFilterType](#section16675437105618)serviceFileterTypes[]) | 获取支持相关能力的设备列表。 |
| uint32_t[HMS_ServiceCollaboration_StartCollaboration](#section4531193410296)(const[ServiceCollaboration_SelectInfo](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/servicecollaboration-selectinfo.md)* selectService,[ServiceCollaborationCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/C API/头文件和结构体/结构体/ServiceCollaborationCallback.md)* callback) | 拉起跨设备互通能力。 |
| int32_t[HMS_ServiceCollaboration_StopCollaboration](#section67211235132913)(uint32_t collaborationId) | 取消跨设备互通能力。 |
#### 宏定义说明
#### COLLABORATIONDEVICEINFO_DEVICENETWORKID_MAXLENGTH
```
#define COLLABORATIONDEVICEINFO_DEVICENETWORKID_MAXLENGTH   65
```
**描述**
设备network Id最大长度。
**起始版本：** 5.0.0(12)
#### COLLABORATIONDEVICEINFO_DEVICENAME_MAXLENGTH
```
#define COLLABORATIONDEVICEINFO_DEVICENAME_MAXLENGTH   128
```
**描述**
设备名最大长度。
**起始版本：** 5.0.0(12)
#### 类型定义说明
#### ServiceCollaboration_CollaborationDeviceInfo
```
typedef struct ServiceCollaboration_CollaborationDeviceInfo ServiceCollaboration_CollaborationDeviceInfo
```
**描述**
设备信息对象。
**起始版本：** 5.0.0(12)
#### ServiceCollaboration_CollaborationDeviceInfoSets
```
typedef struct ServiceCollaboration_CollaborationDeviceInfoSets ServiceCollaboration_CollaborationDeviceInfoSets
```
**描述**
设备信息对象集合。
**起始版本：** 5.0.0(12)
#### ServiceCollaboration_SelectInfo
```
typedef struct ServiceCollaboration_SelectInfo ServiceCollaboration_SelectInfo
```
**描述**
被选择的设备信息。
**起始版本：** 5.0.0(12)
#### ServiceCollaborationCallback
```
typedef struct ServiceCollaborationCallback ServiceCollaborationCallback
```
**描述**
回调跨设备互通状态信息。
**起始版本：** 5.0.0(12)
#### ServiceCollaborationFilterType
```
typedef enum ServiceCollaborationFilterType ServiceCollaborationFilterType
```
**描述**
跨设备互通能力类型的枚举。
**起始版本：** 5.0.0(12)
#### ServiceCollaborationDataType
```
typedef enum ServiceCollaborationDataType ServiceCollaborationDataType
```
**描述**
回传数据类型。
**起始版本：** 5.0.0(12)
#### ServiceCollaborationEventCode
```
typedef enum ServiceCollaborationEventCode ServiceCollaborationEventCode
```
**描述**
错误码枚举。
**起始版本：** 5.0.0(12)
#### 枚举定义说明
#### ServiceCollaborationFilterType
```
enum ServiceCollaborationFilterType
```
**描述**
跨设备互通能力类型枚举。
**起始版本：** 5.0.0(12)
| 枚举值 | 描述 |
| --- | --- |
| TAKE_PHOTO = 1 | 拍照。 |
| SCAN_DOCUMENT = 2 | 扫描。 |
| IMAGE_PICKER = 3 | 从图库中选择。 |
#### ServiceCollaborationDataType
```
enum ServiceCollaborationDataType
```
**描述**
回传数据类型。
**起始版本：** 5.0.0(12)
| 枚举值 | 描述 |
| --- | --- |
| IMAGE = 1 | 图片。 |
#### ServiceCollaborationEventCode
```
enum ServiceCollaborationEventCode
```
**描述**
错误码枚举。
**起始版本：** 5.0.0(12)
| 枚举值 | 描述 |
| --- | --- |
| LAST_DATA_BACK = 1001202000 | 已收到最后一个数据包。 |
| PEER_CANCEL = 1001202001 | 对端取消。 |
| NETWORK_ERROR = 1001202002 | 网络异常。 |
| PEER_WIFI_NOT_OPEN = 1001202004 | 对端WLAN未开启。 |
| LOCAL_WIFI_NOT_OPEN = 1001202005 | 本端WLAN未开启。 |
| DATA_BACK_START = 1001202006 | 开始回传数据。 |
| MIDDLE_DATA_BACK = 1001202007 | 收到中间数据。 |
| TIMEOUT_AUTO_CANCEL = 1001202008 | 接收数据超时取消。 |
| DATA_READ_FAILED = 1001202009 | 数据读取失败。 |
| LINK_SHUTDOWN = 1001202011 | 链路断开。 |
| REMOTE_HOTSPOT_CONFLICT = 1001202013 | 由于对端开启热点产生了链路冲突。**起始版本：**5.1.0(18) |
| REMOTE_DISTRIBUTED_SERVICES_CONFLICT = 1001202014 | 由于对端设备正在与其他设备进行互联而产生了链路冲突。**起始版本：**5.1.0(18) |
#### 函数说明
#### HMS_ServiceCollaboration_GetCollaborationDeviceInfos
```
ServiceCollaboration_CollaborationDeviceInfoSets* HMS_ServiceCollaboration_GetCollaborationDeviceInfos(
    uint32_t fileterNum, ServiceCollaborationFilterType serviceFileterTypes[]);
```
**描述**
获取支持相关能力的设备列表。
**起始版本：** 5.0.0(12)
**参数:**
| 名称 | 描述 |
| --- | --- |
| uint32_t fileterNum | 服务能力类型总数。 |
| [ServiceCollaborationFilterType](#section16675437105618)serviceFileterTypes[] | 具体需要的服务能力类型的数组。 |
**返回：**
返回 [ServiceCollaboration_CollaborationDeviceInfoSets](#section121718545319) ，设备信息对象集合。
#### HMS_ServiceCollaboration_StartCollaboration
```
uint32_t HMS_ServiceCollaboration_StartCollaboration(
    const ServiceCollaboration_SelectInfo* selectService, ServiceCollaborationCallback* callback);
```
**描述**
拉起跨设备互通能力。
**起始版本：** 5.0.0(12)
**参数:**
| 名称 | 描述 |
| --- | --- |
| const[ServiceCollaboration_SelectInfo](#section1871418518535)* selectService | 选择需要拉起的服务能力类型。 |
| [ServiceCollaborationCallback](#section1958717716536)* callback | 回调。 |
**返回：**
返回uint32_t的collaborationId，本次跨设备互通唯一标识。
#### HMS_ServiceCollaboration_StopCollaboration
```
int32_t HMS_ServiceCollaboration_StopCollaboration(uint32_t collaborationId);
```
**描述**
取消跨设备互通能力。
**起始版本：** 5.0.0(12)
**参数:**
| 名称 | 描述 |
| --- | --- |
| uint32_t collaborationId | 跨设备互通唯一标识。 |
**返回：**
返回stop结果，0为成功。