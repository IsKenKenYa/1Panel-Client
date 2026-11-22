# 目标应用设计规范
---
# 目标应用设计规范
本章节主要介绍目标应用接入系统分享面板时，所涉及的设计规范要求。具体参见： [设计指南-分享方式区](https://developer.huawei.com/consumer/cn/doc/design-guides/share-0000001957076313#section132401520173711)
#### 应用名称和图标规范
当应用实现了用于接收分享内容的 [UIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 或者 [UIExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensionability.md) 后，可在配置文件（src/main/module.json5）的 [skills](D:/code/APIDevice/output/md_output/harmonyos-guides/基础入门/开发基础知识/应用配置文件/module.json5配置文件/module-configuration-file.md) 配置中注册。并配置actions为ohos.want.action.sendData。
当分享内容类型为应用所支持的类型时，应用图标将出现在分享面板的分享方式区内。
应用可以针对不同的ability，设置不同的名称和图标。
示例：
```json
"abilities": [
  {
    "name": "TestUIAbility",
    "srcEntry": "./ets/entryability/TestUIAbility.ets",
    "label": "$string:EntryAbility_label", // ability名称
    "icon": "$media:layered_image", // ability图标
    "description": "$string:EntryAbility_desc",
    "startWindowIcon": "$media:startIcon",
    "startWindowBackground": "$color:start_window_background",
    "exported": true,
    "skills": [
      {
        "actions": [
          "ohos.want.action.sendData"
        ],
        "uris": [
          {
            "scheme": "file",
            "utd": "general.text",
            "maxFileSupported": 1
          }
        ]
      }
    ]
  }
],
"extensionAbilities": [
  {
    "name": "TestShareAbility",
    "srcEntry": "./ets/abilities/TestShareAbility.ts",
    "type": "share", // 支持分享数据处理
    "exported": true,
    "label": "$string:xx_label", // ability名称
    "icon": "$media:icon", // ability图标
    "description": "$string:TestShareAbility_desc",
    "skills": [
      {
        "actions": [
          "ohos.want.action.sendData"
        ],
        "uris": [
          {
            "scheme": "file",
            "utd": "general.text",
            "maxFileSupported": 1
          }
        ]
      }
    ]
  }
]
```