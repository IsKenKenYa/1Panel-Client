---
name: hmos-share-kit-design-specification
description: 配置目标应用接入系统分享面板的设计规范，支持应用名称、图标、skills配置，适用于分享内容接收场景
---

# 目标应用设计规范技能

## 功能描述

本技能提供目标应用接入HarmonyOS系统分享面板的配置规范，包括应用名称、图标、skills配置，确保应用能够正确接收和处理分享内容。

## 使用场景

### 触发词
- "分享应用配置"
- "目标应用设计"
- "分享面板接入"
- "接收分享内容"
- "配置分享Ability"

### 能做
- 配置应用在分享面板中显示的名称和图标
- 配置UIAbility接收分享内容
- 配置UIExtensionAbility接收分享内容
- 设置skills的actions和uris
- 配置支持的分享内容类型

### 绝不做
- 不直接处理分享的数据内容
- 不实现分享功能（仅配置接收端）
- 不涉及UI界面的具体实现
- 不处理分享数据的业务逻辑

### 补充
- 本技能仅关注配置文件的设计规范
- 需要配合具体的Ability实现才能完整处理分享内容
- 支持配置多个Ability用于不同的分享场景

## 调用规范和规则

### 输入约束
- 配置文件：必须是module.json5格式
- 文件编码：UTF-8
- 配置项：必须包含abilities或extensionAbilities节点

### 执行约束
- 配置语法：必须符合JSON5规范
- 必填项：label、icon、skills、actions
- 最大耗时：5秒（配置文件编辑）

### 内容约束
- 禁止使用非标准action名称
- 禁止配置多个相同的Ability名称
- actions必须设置为"ohos.want.action.sendData"
- uris配置必须指定scheme和utd

### 降级约束
- 配置文件不存在：提示创建module.json5
- 配置项缺失：提示必填项并说明格式
- 语法错误：提供错误位置和修复建议

## 调用流程和步骤

### 步骤1：准备配置文件

**前置校验**：
1. 检查项目结构中是否存在src/main/module.json5
2. 确认应用已配置基本的abilities
3. 确认需要接收分享内容的Ability已创建

**参数准备**：
```json
{
  "abilityName": "TestUIAbility",
  "abilityLabel": "$string:EntryAbility_label",
  "abilityIcon": "$media:layered_image",
  "action": "ohos.want.action.sendData",
  "scheme": "file",
  "utd": "general.text",
  "maxFileSupported": 1
}
```

### 步骤2：配置UIAbility接收分享

**示例代码**：
```json5
// module.json5配置示例
{
  "module": {
    "abilities": [
      {
        "name": "TestUIAbility",
        "srcEntry": "./ets/entryability/TestUIAbility.ets",
        "label": "$string:EntryAbility_label",
        "icon": "$media:layered_image",
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
    ]
  }
}
```

**配置说明**：
- `name`: Ability类名，必须与代码中的类名一致
- `label`: Ability在分享面板中显示的名称，引用字符串资源
- `icon`: Ability在分享面板中显示的图标，引用图片资源
- `exported`: 必须设置为true，允许其他应用调用
- `skills.actions`: 必须包含"ohos.want.action.sendData"
- `skills.uris.scheme`: 数据协议，如"file"表示文件
- `skills.uris.utd`: 统一数据类型，如"general.text"表示文本
- `skills.uris.maxFileSupported`: 支持的最大文件数量

### 步骤3：配置UIExtensionAbility接收分享

**示例代码**：
```json5
// module.json5配置示例
{
  "module": {
    "extensionAbilities": [
      {
        "name": "TestShareAbility",
        "srcEntry": "./ets/abilities/TestShareAbility.ts",
        "type": "share",
        "exported": true,
        "label": "$string:xx_label",
        "icon": "$media:icon",
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
  }
}
```

**配置说明**：
- `type`: 必须设置为"share"，表示分享扩展
- 其他配置项与UIAbility类似

### 步骤4：配置常用数据类型

**支持的UTD类型**：
```json5
// 常用UTD类型配置示例
[
  {
    "scheme": "file",
    "utd": "general.text",
    "maxFileSupported": 10
  },
  {
    "scheme": "file",
    "utd": "general.image",
    "maxFileSupported": 9
  },
  {
    "scheme": "file",
    "utd": "general.video",
    "maxFileSupported": 1
  },
  {
    "scheme": "file",
    "utd": "general.audio",
    "maxFileSupported": 1
  }
]
```

### 步骤5：验证配置

**验证清单**：
1. 检查module.json5语法是否正确
2. 确认label和icon资源是否存在
3. 确认actions包含"ohos.want.action.sendData"
4. 确认exported设置为true
5. 确认uris配置了scheme和utd

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| CONFIG_ERROR | 配置文件语法错误 | 检查JSON5语法，确保括号、逗号等格式正确 |
| RESOURCE_NOT_FOUND | 资源引用错误 | 检查label和icon引用的资源是否存在 |
| ACTION_INVALID | action配置无效 | 确认actions包含"ohos.want.action.sendData" |
| URI_INVALID | uris配置无效 | 确认scheme和utd配置正确 |
| ABILITY_NOT_EXPORTED | Ability未导出 | 设置exported为true |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AbilityKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: API 9+
- DevEco Studio: 3.0+

### 常见编译问题

**问题1：Ability名称不匹配**
```
Error: Ability 'TestUIAbility' not found in module
```
**解决方法**：确保module.json5中的name与代码中的Ability类名一致

**问题2：资源引用错误**
```
Error: Resource not found: $string:EntryAbility_label
```
**解决方法**：检查resources/base/element/string.json中是否定义了对应资源

**问题3：exported未设置**
```
Error: Ability must be exported to receive shared content
```
**解决方法**：在module.json5中设置exported为true

## 常见问题与解决方法

### Q1：应用图标不显示在分享面板
**原因**：
- exported未设置为true
- actions未配置"ohos.want.action.sendData"
- uris配置不正确

**解决方法**：
- 确认exported为true
- 确认actions包含"ohos.want.action.sendData"
- 确认uris配置了支持的scheme和utd

### Q2：如何配置支持多种文件类型
**原因**：需要配置多个uris

**解决方法**：
```json5
"uris": [
  {
    "scheme": "file",
    "utd": "general.text",
    "maxFileSupported": 10
  },
  {
    "scheme": "file",
    "utd": "general.image",
    "maxFileSupported": 9
  }
]
```

### Q3：UIAbility和UIExtensionAbility的区别
**原因**：两种组件的使用场景不同

**解决方法**：
- UIAbility：独立的应用组件，会在任务视图中显示
- UIExtensionAbility：扩展组件，不会在任务视图中显示，适合轻量级分享处理
- 根据业务需求选择合适的组件类型

### Q4：如何限制分享文件数量
**原因**：需要控制资源使用

**解决方法**：
- 通过maxFileSupported字段设置最大文件数量
- 在Ability代码中检查实际接收的文件数量

## 输出结果报告

配置完成后输出以下信息：

```json
{
  "status": "success",
  "abilityName": "TestUIAbility",
  "abilityType": "UIAbility",
  "configuredActions": ["ohos.want.action.sendData"],
  "configuredUris": [
    {
      "scheme": "file",
      "utd": "general.text",
      "maxFileSupported": 1
    }
  ],
  "exported": true
}
```

## 参考文档

- [目标应用设计规范](references/share-design-specification.md)
- [UIAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiability)
- [UIExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiextensionability)
- [设计指南-分享方式区](https://developer.huawei.com/consumer/cn/doc/design-guides/share-0000001957076313#section132401520173711)

## 完整示例代码

- [UIAbility配置示例](assets/uiability_config.json5)
- [UIExtensionAbility配置示例](assets/uiextensionability_config.json5)
- [多类型支持配置示例](assets/multi_type_config.json5)

## 测试用例

### 正向测试用例
- [基本配置测试](tests/test_positive.py)：验证基本配置项正确
- [多类型支持测试](tests/test_positive.py)：验证支持多种数据类型
- [资源引用测试](tests/test_positive.py)：验证资源引用正确

### 边界测试用例
- [最大文件数测试](tests/test_boundary.py)：验证maxFileSupported边界值
- [资源大小测试](tests/test_boundary.py)：验证资源文件大小限制

### 异常测试用例
- [配置缺失测试](tests/test_exception.py)：验证必填项缺失的情况
- [语法错误测试](tests/test_exception.py)：验证JSON5语法错误
- [资源不存在测试](tests/test_exception.py)：验证资源引用不存在的情况