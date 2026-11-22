---
name: hmos-form-kit-widget-configuration
description: 配置ArkTS卡片的配置文件，包括FormExtensionAbility配置和form_config.json配置，支持最多16个卡片配置，适用于卡片开发、卡片刷新、卡片管理等场景
---

# 配置ArkTS卡片配置文件技能

## 功能描述

本技能用于配置HarmonyOS ArkTS卡片的完整配置文件，包括：
- **FormExtensionAbility配置**：在module.json5中配置卡片扩展能力
- **卡片配置文件**：创建和配置form_config.json文件
- **独立卡片包配置**：配置独立卡片包的关联关系

卡片配置包含卡片的名称、尺寸、刷新方式、UI路径、渲染模式等完整信息，确保卡片能够正确显示和运行。

## 使用场景

### 触发词
- "配置卡片"
- "创建卡片配置文件"
- "配置ArkTS卡片"
- "form_config.json"
- "卡片配置"
- "FormExtensionAbility配置"

### 能做
- 配置FormExtensionAbility的metadata信息
- 创建完整的form_config.json配置文件
- 配置卡片的基本属性（名称、尺寸、描述等）
- 配置卡片的刷新方式（定时刷新、定点刷新）
- 配置卡片的渲染模式（全彩模式、单色模式、自动模式）
- 配置卡片的扩展属性（动态卡片、透明背板、模糊背板等）
- 配置独立卡片包的关联关系

### 绝不做
- 不处理卡片UI页面的开发（需要使用其他技能）
- 不处理卡片数据绑定的开发
- 不处理卡片生命周期回调的具体实现
- 不配置超过16个卡片（系统限制）

### 补充
- 卡片五元组（bundleName、moduleName、abilityName、formName、formDimension）必须保持一致，否则升级后卡片会被删除
- 五元组不建议使用资源文件导入配置，因为资源文件新增字段会导致ID变化
- FormExtensionAbility创建后10秒内无操作将会被清理
- 配置文件路径必须正确，否则卡片无法正常加载

## 调用规范和规则

### 输入约束
- 卡片名称最大长度：127字节
- 卡片展示名称最小长度：1字节，最大长度：30字节
- 卡片描述最大长度：255字节
- 卡片数量：最多16个
- 支持的尺寸：1x1、1x2、2x2、2x3、2x4、3x3、4x4、6x4（注意：2x3和3x3仅支持手表设备，1x1仅支持锁屏）

### 执行约束
- 配置文件必须使用UTF-8编码
- 配置文件路径格式：resources/base/profile/目录下
- FormExtensionAbility的metadata键名称必须为"ohos.extension.form"
- 配置文件中的src路径必须包含完整路径和文件后缀（如.ets）

### 内容约束
- 禁止配置超过16个卡片
- 禁止在五元组字段中使用资源文件导入
- 禁止配置不支持的尺寸组合
- 禁止使用eval、exec等高危函数

### 降级约束
- 配置文件路径错误：检查路径格式并重新配置
- 卡片数量超过限制：提示用户减少卡片数量至16个以内
- 尺寸配置错误：使用支持的尺寸重新配置

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认项目类型为Stage模型
2. 确认需要配置的卡片数量不超过16个
3. 确认卡片UI文件已创建完成
4. 确认卡片尺寸在支持范围内

**参数准备**：
```typescript
// 卡片配置参数示例
const widgetConfig = {
  name: 'widget',
  displayName: '$string:widget_display_name',
  description: '$string:widget_desc',
  src: './ets/widget/pages/WidgetCard.ets',
  uiSyntax: 'arkts',
  isDefault: true,
  updateEnabled: true,
  scheduledUpdateTime: '10:30',
  updateDuration: 1,
  defaultDimension: '2*2',
  supportDimensions: ['2*2'],
  isDynamic: true
};
```

### 步骤2：配置FormExtensionAbility

**在module.json5中配置FormExtensionAbility**：
```typescript
// module.json5配置示例
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "extensionAbilities": [
      {
        "name": "EntryFormAbility",
        "srcEntry": "./ets/entryformability/EntryFormAbility.ets",
        "label": "$string:EntryFormAbility_label",
        "description": "$string:EntryFormAbility_desc",
        "type": "form",
        "metadata": [
          {
            "name": "ohos.extension.form",
            "resource": "$profile:form_config"
          }
        ]
      }
    ],
    // 独立卡片包形态中使用，关联卡片包模块
    "formWidgetModule": "library"
  }
}
```

### 步骤3：创建卡片配置文件

**创建form_config.json文件**：
```json
{
  "forms": [
    {
      "name": "widget",
      "displayName": "$string:widget_display_name",
      "description": "$string:widget_desc",
      "src": "./ets/widget/pages/WidgetCard.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "renderingMode": "fullColor",
      "isDefault": true,
      "updateEnabled": true,
      "scheduledUpdateTime": "10:30",
      "updateDuration": 1,
      "defaultDimension": "2*2",
      "supportDimensions": [
        "2*2"
      ],
      "formConfigAbility": "ability://EntryAbility",
      "isDynamic": true,
      "metadata": []
    }
  ]
}
```

### 步骤4：配置独立卡片包（可选）

**独立卡片包的module.json5配置**：
```json
{
  "module": {
    "name": "library",
    "type": "shared",
    "description": "$string:shared_desc",
    "deviceTypes": [
      "phone"
    ],
    "deliveryWithInstall": true,
    // 关联应用包模块
    "formExtensionModule": "entry"
  }
}
```

### 步骤5：配置卡片扩展属性（可选）

**配置动态卡片、透明背板等**：
```json
{
  "forms": [
    {
      "name": "widget",
      // ... 其他基本配置
      "isDynamic": true,
      "transparencyEnabled": false,
      "enableBlurBackground": false,
      "fontScaleFollowSystem": true,
      "supportShapes": ["rect"],
      "dataProxyEnabled": false,
      "standby": {
        "isSupported": true,
        "isAdapted": false,
        "isPrivacySensitive": false
      }
    }
  ]
}
```

### 步骤6：错误处理

**常见配置错误处理**：
```typescript
// 配置文件验证函数
function validateWidgetConfig(config: any): boolean {
  // 验证卡片数量
  if (config.forms && config.forms.length > 16) {
    console.error('卡片数量超过限制（最多16个）');
    return false;
  }
  
  // 验证卡片名称长度
  for (let form of config.forms) {
    if (form.name.length > 127) {
      console.error(`卡片名称过长: ${form.name}`);
      return false;
    }
    
    // 验证尺寸配置
    const validDimensions = ['1*1', '1*2', '2*2', '2*4', '2*3', '3*3', '4*4', '6*4'];
    for (let dim of form.supportDimensions) {
      if (!validDimensions.includes(dim)) {
        console.error(`不支持的卡片尺寸: ${dim}`);
        return false;
      }
    }
  }
  
  return true;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| CONFIG_FILE_NOT_FOUND | 配置文件不存在 | 检查配置文件路径是否正确，确保文件在resources/base/profile/目录下 |
| INVALID_FORM_NAME | 卡片名称无效 | 检查卡片名称长度不超过127字节，不使用资源文件导入 |
| INVALID_DIMENSION | 卡片尺寸无效 | 使用支持的尺寸：1x1、1x2、2x2、2x4、2x3、3x3、4x4、6x4 |
| FORM_COUNT_EXCEEDED | 卡片数量超过限制 | 减少卡片数量至16个以内 |
| METADATA_CONFIG_ERROR | metadata配置错误 | 确保metadata键名称为"ohos.extension.form" |
| SRC_PATH_INVALID | UI文件路径无效 | 检查src路径格式，确保包含完整路径和.ets后缀 |
| FIVE_ELEMENT_CHANGED | 五元组改变 | 避免在五元组字段中使用资源文件导入，保持五元组一致 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "最新版本",
    "@kit.AbilityKit": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 9或以上
- DevEco Studio：3.0或以上
- 项目模型：Stage模型

### 常见编译问题

**问题1：配置文件路径错误**
```
Error: Cannot find profile:form_config
```
**解决方法**：确保form_config.json文件在resources/base/profile/目录下，且文件名为form_config.json

**问题2：卡片无法显示**
```
Error: FormExtensionAbility not found
```
**解决方法**：检查module.json5中的extensionAbilities配置，确保type为"form"且metadata配置正确

**问题3：五元组改变导致卡片消失**
```
卡片在升级后消失
```
**解决方法**：避免在五元组字段中使用资源文件导入，保持bundleName、moduleName、abilityName、formName、formDimension的一致性

## 常见问题与解决方法

### Q1：如何配置多个不同尺寸的卡片？
**原因**：需要在同一个form_config.json中配置多个卡片
**解决方法**：
- 在forms数组中添加多个卡片配置对象
- 每个卡片配置不同的尺寸和名称
- 确保卡片总数不超过16个

### Q2：如何配置卡片的刷新方式？
**原因**：卡片支持定时刷新和定点刷新两种方式
**解决方法**：
- **定时刷新**：设置updateDuration参数，单位为30分钟（如设置为1，表示30分钟刷新一次）
- **定点刷新**：设置scheduledUpdateTime参数，采用24小时制（如"10:30"）
- 两者同时配置时，定时刷新优先生效

### Q3：如何配置动态卡片和静态卡片？
**原因**：ArkTS卡片支持动态和静态两种模式
**解决方法**：
- **动态卡片**：设置isDynamic为true，支持完整的ArkTS能力
- **静态卡片**：设置isDynamic为false，性能更好但功能受限
- 默认值为true（动态卡片）

### Q4：如何配置卡片的渲染模式？
**原因**：卡片支持不同的色彩模式以适应不同场景
**解决方法**：
- **fullColor**：全彩模式，颜色和图片不可修改，适用于桌面
- **singleColor**：单色模式，颜色和图片可修改，适用于锁屏
- **autoColor**：自动模式，根据使用方确定模式，可添加到桌面或锁屏

### Q5：如何配置独立卡片包？
**原因**：独立卡片包需要配置应用包和卡片包的关联关系
**解决方法**：
- 在应用包的module.json5中配置formWidgetModule字段
- 在卡片包的module.json5中配置formExtensionModule字段
- 确保两个模块的关联关系正确

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "配置完成",
  "configFiles": [
    {
      "type": "module.json5",
      "path": "entry/src/main/module.json5",
      "configured": true
    },
    {
      "type": "form_config.json",
      "path": "entry/src/main/resources/base/profile/form_config.json",
      "configured": true,
      "formCount": 1
    }
  ],
  "widgetCount": 1,
  "supportDimensions": ["2*2"],
  "apiUsed": [
    "FormExtensionAbility",
    "Metadata"
  ],
  "nextSteps": [
    "创建卡片UI页面",
    "实现FormExtensionAbility生命周期回调",
    "配置卡片数据绑定"
  ]
}
```

## 参考文档

- [ArkTS卡片配置文件开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [Metadata API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bundlemanager-metadata)

## 完整示例代码

- [完整配置文件示例](assets/widget_config_example.json)
- [FormExtensionAbility实现示例](assets/form_extension_ability_example.ets)
- [独立卡片包配置示例](assets/independent_widget_package_example.json)

## 测试用例

### 正向测试用例
- [基本卡片配置测试](tests/test_basic_widget_config.json)：测试基本的卡片配置文件创建
- [多尺寸卡片配置测试](tests/test_multi_dimension_config.json)：测试配置多个不同尺寸的卡片
- [刷新配置测试](tests/test_refresh_config.json)：测试定时刷新和定点刷新配置

### 边界测试用例
- [最大卡片数量测试](tests/test_max_form_count.json)：测试配置16个卡片
- [最大名称长度测试](tests/test_max_name_length.json)：测试127字节长度的卡片名称
- [所有尺寸组合测试](tests/test_all_dimensions.json)：测试所有支持的尺寸组合

### 异常测试用例
- [超出卡片数量限制测试](tests/test_form_count_exceeded.json)：测试配置超过16个卡片
- [无效尺寸测试](tests/test_invalid_dimension.json)：测试不支持的尺寸配置
- [配置文件路径错误测试](tests/test_invalid_path.json)：测试错误的配置文件路径