# ArkTS API错误码
---
# ArkTS API错误码
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ff/v3/A9DZpQ9ETGa3iF9K5SArFg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093921Z&HW-CC-Expire=86400&HW-CC-Sign=B7F72ABC01FD493B428340A0464DF7DCC689B1BC5D1596BD6C59601FB9050DCA)
以下仅介绍本模块特有错误码，通用错误码请参考 [通用错误码说明文档](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal) 。
#### 1003700001 数据记录超过上限
**错误信息**
The number of records exceeds the maximum.
**错误描述**
数据记录数量超过上限。
**可能原因**
数据记录数量超过限制，当前上限为500项。
**处理步骤**
对用户可选分享内容数量做限制。
#### 1003702001 数据记录格式非法/类型不支持
**错误信息**
Record types are not support.(The batch and multiple selection modes support { @link UDMF.File } type records only.)
**错误描述**
数据记录类型不支持。
**可能原因**
1. 传入了类型无法识别、不支持或不匹配的数据记录。
2. SharedRecord数据记录中，uri、content全部为空。
3. uri格式非法。
**处理步骤**
1. 检查数据类型是否为已预置的 [UniformDataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkData（方舟数据管理）/ArkTS API/js-apis-data-uniformtypedescriptor) 类型或者是已知的自定义类型。
2. 检查SharedRecord数据，uri、content是否全部为空。
3. 检查传入的uri字段格式。
#### 1003702002 跨进程传输数据量超过上限
**错误信息**
IPC data is oversized.
**错误描述**
跨进程传输数据超过上限200KB（包含want数据本身的字段）。
**可能原因**
1. 缩略图过大。
2. 文本内容过多。
**处理步骤**
1. 对SharedRecord中传入的缩略图二进制数据进行压缩处理。
2. 对用户可选文本内容做字数限制。
#### 1003703001 数据解析失败
**错误信息**
Parse data failed.
**错误描述**
分享数据关键信息通过want传递，非法want无法解析。
**可能原因**
调用 [getContactInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share) / [getSharedData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share) 接口时，输入参数格式非法，例如：解析字段不匹配（非分享类型数据）、解析字段不存在等。
**处理步骤**
1. 目标应用Ability中止本次分享数据处理。
2. 提示用户分享数据错误。