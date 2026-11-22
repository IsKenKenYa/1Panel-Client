# postCardAction
---
# postCardAction
用于卡片内部和提供方应用间的交互，当前支持router、message和call三种类型的事件，仅在卡片中可以调用。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/47/v3/J1RbrzkfRHaA2EEBJK43pw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092828Z&HW-CC-Expire=86400&HW-CC-Sign=B87A9889790AFE0CD5A75BDE584E19B3603A193972E373FEB3568AEBDC2B217F)
本接口从API version 9开始支持。
#### postCardAction
postCardAction(component: Object, action: Object): void
执行函数内部的交互，处理component和action对象的相关操作，不返回任何内容。
**卡片能力：** 从API version 9开始，该接口支持在ArkTS卡片中使用。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**模型约束：** 此接口仅可在Stage模型下使用。
**参数：**
| **参数名** | **类型** | **必填** | **说明** |
| --- | --- | --- | --- |
| component | Object | 是 | 当前自定义组件的实例，通常传入this。 |
| action | Object | 是 | action的具体描述，详情见下表。 |
action参数说明：
| **参数名** | **类型** | **必填** | **取值说明** |
| --- | --- | --- | --- |
| action | string | 是 | action的类型，支持三种预定义的类型：- router：跳转到提供方应用的指定UIAbility，只允许在点击事件中触发。- message：自定义消息，触发后会调用提供方FormExtensionAbility的[onFormEvent()](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-formextensionability.md)生命周期回调。- call：后台启动提供方应用。触发后会拉起提供方应用的指定UIAbility（仅支持launchType为singleton的[UIAbility](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/应用模型/应用组件/UIAbility组件/UIAbility组件启动模式/uiability-launch-type.md)，即启动模式为单实例的UIAbility），但不会调度到前台。提供方应用需要具备后台运行权限([ohos.permission.KEEP_BACKGROUND_RUNNING](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/安全/程序访问控制/应用权限管控/应用权限列表/开放权限（系统授权）/permissions-for-all.md))。 |
| bundleName | string | 否 | action为router / call 类型时跳转的包名。 |
| moduleName | string | 否 | action为router / call 类型时跳转的模块名。 |
| abilityName | string | 否 | action为router / call 类型时跳转的UIAbility名。 |
| uri11+ | string | 否 | action为router 类型时跳转的UIAbility的统一资源标识符。uri和abilityName同时存在时，abilityName优先。 |
| params | Object | 否 | 当前action携带的额外参数，内容使用JSON格式的键值对形式。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/82/v3/GNGovCkeRj-R1Z1iFUc-rg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092828Z&HW-CC-Expire=86400&HW-CC-Sign=111298F0BF01D3CCF94A0C58850B10ADE1B6C9E33235F54F3C3BE3271273C971)
"action"为"call" 类型时，"params"需填入参数'method'，且类型需为string类型，用于触发UIAbility中对应的方法。
**示例：**
```
Button('跳转')
  .width('40%')
  .height('20%')
  .onClick(() => {
    postCardAction(this, {
      action: 'router',
      bundleName: 'com.example.myapplication',
      abilityName: 'EntryAbility',
      params: {
        message: 'testForRouter' // 自定义要发送的message
      }
    });
  })
Button('拉至后台')
  .width('40%')
  .height('20%')
  .onClick(() => {
    postCardAction(this, {
      action: 'call',
      bundleName: 'com.example.myapplication',
      abilityName: 'EntryAbility',
      params: {
        method: 'fun', // 自定义调用的方法名，必填
        message: 'testForCall' // 自定义要发送的message
      }
    });
  })
Button('URI跳转')
  .width('40%')
  .height('20%')
  .onClick(() => {
    postCardAction(this, {
      action: 'router',
      uri: 'example://uri.ohos.com/link_page',
      params: {
        message: 'router msg for dynamic uri deeplink' // 自定义要发送的message
      }
    });
  })
```
**待跳转应用[module.json5](D:/code/APIDevice/output/md_output/harmonyos-guides/基础入门/开发基础知识/应用配置文件/module.json5配置文件/module-configuration-file.md)uris 配置示例：**
```json
"abilities": [
  {
    "skills": [
      {
        "uris": [
          {
            "scheme": "example",
            "host": "uri.ohos.com",
            "path": "link_page"
          }
        ]
      }
    ]
  }
]
```