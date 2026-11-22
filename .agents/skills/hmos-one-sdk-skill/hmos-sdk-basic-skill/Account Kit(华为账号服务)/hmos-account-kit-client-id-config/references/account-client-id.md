# 配置Client ID
---
# 配置Client ID
#### 获取Client ID和APP ID
在 AppGallery Connect（简称AGC）的 [开发与服务](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html#/myProject) 中，选择对应的项目和对应的应用，在“常规 > 应用 ”下，找到 **应用** 的Client ID和APP ID。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/cd/v3/jRRvoOlvQl21TPqmkibd2w/zh-cn_image_0000002659220727.png?HW-CC-KV=V1&HW-CC-Date=20260701T105120Z&HW-CC-Expire=86400&HW-CC-Sign=F1FC4D5087DFF7E65CF5D00FFB4A92A7FD1723616411309F82C5BAC1074A9938)
#### 确认是否需要配置Client ID
如果上一步获取到的Client ID和APP ID相同，则无需配置Client ID，否则需要按下一步配置Client ID。
#### 配置Client ID
在工程中 **entry** 模块的module.json5文件中，新增metadata，配置name为client_id，value为上一步获取的Client ID的值，如下所示：
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/76/v3/VusBQYnaRCi-qnHQ25rPvg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105120Z&HW-CC-Expire=86400&HW-CC-Sign=A0F9A94BE7C87ED38FE68410F53D65064D5E27508D0AE8A25E69F073EFD44FC2)
1.若工程中存在多个模块，需要在"type"为"entry"模块中的module.json5文件配置应用的Client ID。
2.请确认获取的Client ID是 **应用** Client ID，错配成项目Client ID将导致接口调用报错。
```
"module": {
  "name": "entry",
  "type": "entry",
  "description": "<description>",
  "mainElement": "<mainElement>",
  "deviceTypes": [
  ],
  // ...
  "pages": "$profile:main_pages",
  // ...
  "metadata": [
    // 配置信息如下
    // ...
    {
      "name": "client_id",
      // 将上一步获取到的Client ID赋值给value，请注意不要使用其他方式设置value值
      "value": "xxxxx"
    }
  ]
}
```