# 配置应用身份信息
---
# 配置应用身份信息
#### bundleName配置
在工程“AppScope/app.json5”下的 **bundleName** 需要与开发者在应用开发准备中 [创建应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-overview) 时的包名保持一致。
配置内容示例如下：
```json
{
  "app": {
    "bundleName": "com.huawei.***.***.demo",
  }
}
```
#### 配置应用身份信息
1.
登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 平台，在“开发与服务”中选择目标项目，通过“项目设置 > 常规 > 应用”获取目标应用的 **Client ID** 。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/02/v3/yV6l-XFkRA-u5WaZPnq0AQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105219Z&HW-CC-Expire=86400&HW-CC-Sign=6FB026E3A917C329CAF0CCEDDFDAC023E3F8C0D3927184C70A2B421DC96021F3)
-
下图中的APP ID可用于服务器API接口请求。
-
如果开发者应用的compatibleSdkVersion>=14，则接入IAP Kit不要求开发者 [添加公钥指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-overview) 以及配置应用身份信息。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/3/v3/LHRkixzfSkyCJyc1HwOpMQ/zh-cn_image_0000002628701720.png?HW-CC-KV=V1&HW-CC-Date=20260701T105219Z&HW-CC-Expire=86400&HW-CC-Sign=16C2F47CDE66B2831F27272202535806B912B97AC894BF0C2EEAD50EB9230577)
2.
在工程“entry/src/main/module.json5”的 **module** 节点增加如下 **client_id** 属性配置，用于IAP Kit接口的应用身份鉴权。
```json
{
  "module":{
    "type": "***",
    "name": "***",
    "description": "***",
    "mainElement": "***",
    "deviceTypes": [***],
    "metadata": [
      {
        "name": "client_id",
        "value": "***"
      }
    ]
  }
}
```