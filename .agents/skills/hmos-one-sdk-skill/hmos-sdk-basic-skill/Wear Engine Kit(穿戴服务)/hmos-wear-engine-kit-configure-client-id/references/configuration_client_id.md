# 配置Client ID
---
# 配置Client ID
1.
登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 平台，在"开发与服务"中选择目标应用，获取"项目设置 > 常规 > 应用"的Client ID。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1c/v3/QXRK9wJ1QhK7OIB3tyDnwQ/zh-cn_image_0000002628701222.png?HW-CC-KV=V1&HW-CC-Date=20260701T104932Z&HW-CC-Expire=86400&HW-CC-Sign=93FE527810BB23F5F60F42CF1A3428600782F96CDFC59D4097FF1CBC8B773BA2)
2.
在工程中entry模块的module.json5文件中，新增metadata，配置name为client_id，value为上一步获取的Client ID的值，如下所示：
```
{
  "module": {
    "name": "xxxx",
    "type": "entry",
    "description": "xxxx",
    "mainElement": "xxxx",
    "deviceTypes": [],
    "pages": "xxxx",
    "abilities": [],
    "metadata": [
      // 配置如下信息
      {
        "name": "client_id",
        "value": "xxxxxx"
      }
    ]
  }
}
```