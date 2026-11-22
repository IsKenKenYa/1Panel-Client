---
name: hmos-form-kit-standby-widget
description: 开发ArkTS待机屏保卡片，支持展示天气、日历等重要信息，仅支持2*2尺寸，需申请开放能力且遵循UX规范，适用于横屏充电锁屏待机场景
---

# ArkTS待机屏保卡片开发技能

## 功能描述

本技能用于开发在设备待机屏保界面（横屏充电锁屏状态）上显示的ArkTS卡片。待机屏保卡片用于展示天气、日历等重要信息，支持用户个性化定制，提供全场景、个性化的心灵陪伴体验。

**核心能力**：
- 在待机屏保界面展示2*2尺寸卡片
- 支持展示天气、日历、时钟等信息
- 支持用户个性化定制
- 遵循待机屏保UX设计规范
- 支持隐私敏感数据蒙层覆盖

**技术特点**：
- 从API version 23开始支持
- 默认为深色模式，不跟随系统
- 需申请待机屏保开放能力
- 仅支持2*2尺寸卡片
- 需使用手动签名并申请Profile

## 使用场景

### 触发词
- "待机屏保卡片"
- "横屏充电卡片"
- "standby widget"
- "待机显示卡片"
- "屏保卡片开发"

### 能做
- 开发支持待机屏保显示的ArkTS卡片
- 配置卡片在待机屏保界面展示属性
- 处理隐私敏感数据的蒙层覆盖
- 配置卡片适配待机屏保UX规范
- 申请待机屏保开放能力
- 创建待机屏保卡片UI界面

### 绝不做
- 不支持开发非2*2尺寸的待机屏保卡片
- 不处理桌面或锁屏上的普通卡片开发
- 不推荐展示用户个人隐私敏感数据
- 不处理非待机屏保场景的卡片需求
- 不绕过开放能力申请流程

### 补充
- 待机屏保界面默认为深色模式，不会跟随系统设置
- 需遵循待机屏保UX设计规范（参考设计指南）
- 应用调试或发布必须使用手动签名
- 折叠机需切换为外屏，支持帐篷模式显示
- 开启路径：设置>桌面和个性化>待机屏保设置

## 调用规范和规则

### 输入约束
- 卡片尺寸：必须为2*2尺寸，不支持其他尺寸
- API版本：最低API version 23
- 配置文件：form_config.json必须包含standby字段配置
- 开放能力：必须申请待机屏保开放能力并获批
- 签名方式：必须使用手动签名，不支持自动签名
- 数据隐私：不推荐展示用户个人隐私敏感数据

### 执行约束
- 开发流程：遵循创建卡片、配置standby字段、申请开放能力的标准流程
- 申请审批：开放能力申请需填写申请原因（最多512字符）并可能上传附件（最大500MB）
- UX规范：必须遵循待机屏保UX设计规范
- 配置要求：isSupported字段必须为true才可展示在待机屏保界面

### 内容约束
- 禁止配置非2*2尺寸的卡片用于待机屏保
- 禁止展示用户个人隐私敏感数据（建议isPrivacySensitive设为true）
- 禁止绕过开放能力申请流程直接开发
- 禁止使用自动签名发布应用
- 禁止违反待机屏保UX设计规范

### 降级约束
- 开放能力未获批：提示用户申请流程，引导填写申请表
- API版本不满足：提示最低版本要求，建议升级项目配置
- 尺寸配置错误：自动调整为2*2尺寸或提示用户修改
- 签名方式错误：提示必须使用手动签名，提供签名配置指导

## 调用流程和步骤

### 步骤1：准备阶段 - 申请开放能力

**前置校验**：
1. 确认项目API version ≥ 23
2. 确认使用手动签名方式
3. 确认已在AppGallery Connect创建HarmonyOS应用

**申请流程**：
1. 登录AppGallery Connect，选择"开发与服务"
2. 在项目列表中找到项目，选择需开启开放能力的应用/元服务
3. 在"开放能力管理"页面，点击待机屏保卡片对应的申请按钮
4. 填写申请信息：
   - **申请原因**（必填）：应用介绍、使用场景、申请用途，最多512字符
   - **上传附件**（选填）：卡片UI设计释义材料，最大500MB，支持文本、表格、图片、视频、压缩包
5. 点击"提交"完成申请
6. 等待审批，审批通过后"申请"按钮变为置灰，能力开关已勾选

**申请配置示例**：
```
申请原因示例：
"本应用为天气服务应用，需要在待机屏保界面展示实时天气信息、温度、空气质量等数据，为用户提供便捷的天气查询服务。待机屏保卡片将展示当前天气状况、未来24小时天气预报，帮助用户在待机状态下快速了解天气信息，提升用户体验和使用便利性。"

附件建议：
- 卡片UI设计稿（展示布局、配色、信息展示方式）
- 功能说明文档（说明卡片展示内容、更新频率、数据来源）
```

### 步骤2：创建ArkTS卡片

**创建卡片步骤**：

**方式一：共包方式创建卡片**
1. 在DevEco Studio中，右键entry目录
2. 选择【New】->【Service Widget】->【Dynamic Widget】
3. 选择模板，点击【Next】
4. 选择Language为ArkTS，Support dimension选择2*2，Default dimension选择2*2
5. 点击【Finish】完成创建

**方式二：独立包方式创建卡片**
1. 右键entry目录
2. 选择【New】->【Service Widget】->【Dynamic Widget(Standalone)】
3. 选择模板，点击【Next】
4. 配置卡片信息，点击【Finish】

**生成的关键文件**：
- `EntryFormAbility.ets` - 卡片生命周期管理文件
- `WidgetCard.ets` - 卡片页面文件
- `form_config.json` - 卡片配置文件

**卡片UI开发要点**：
```typescript
// WidgetCard.ets - 卡片页面示例
@Entry
@Component
struct WidgetCard {
  @State weatherData: string = '晴天 25°C';
  
  build() {
    Column() {
      // 待机屏保卡片建议使用深色主题
      Text(this.weatherData)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .margin({ top: 10 })
      
      Text('更新时间: 10:30')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ top: 5 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A1A') // 深色背景
  }
}
```

### 步骤3：配置待机屏保属性

**配置form_config.json文件**：
```json
{
  "forms": [
    {
      "name": "widget",
      "displayName": "$string:widget_display_name",
      "description": "$string:widget_desc",
      "src": "./ets/widget/pages/WidgetCard.ets",
      "uiSyntax": "arkts",
      "isDynamic": true,
      "isDefault": true,
      "updateEnabled": false,
      "scheduledUpdateTime": "10:30",
      "renderingMode": "autoColor",
      "updateDuration": 1,
      "defaultDimension": "2*2",
      "supportDimensions": [
        "2*2"
      ],
      "standby": {
        "isSupported": true,
        "isAdapted": true,
        "isPrivacySensitive": false
      }
    }
  ]
}
```

**standby字段说明**：
- **isSupported**：是否支持在待机屏保界面展示
  - `true`：支持展示（必须配置）
  - `false`：不支持展示
- **isAdapted**：是否适配待机屏保UX规范
  - `true`：已适配，系统会移除backgroundImage
  - `false`：未适配
- **isPrivacySensitive**：是否为隐私敏感卡片
  - `true`：隐私敏感，用户添加到待机屏保时会有蒙层覆盖
  - `false`：非隐私敏感，无蒙层覆盖

**配置建议**：
```json
// 天气卡片配置（非隐私敏感）
"standby": {
  "isSupported": true,
  "isAdapted": true,
  "isPrivacySensitive": false
}

// 日历待办卡片配置（隐私敏感）
"standby": {
  "isSupported": true,
  "isAdapted": true,
  "isPrivacySensitive": true
}
```

### 步骤4：配置module.json5

**FormExtensionAbility配置**：
```json
{
  "module": {
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
    ]
  }
}
```

### 步骤5：手动签名配置

**签名步骤**：
1. 参考[手动签名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)配置
2. 在申请Profile过程中：
   - 创建HarmonyOS应用（参考[创建HarmonyOS应用](https://developer.huawei.com/consumer/cn/doc/app/agc-help-create-app-0000002247955506))
   - 申请Profile（参考[申请Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278))
3. 配置签名信息到DevEco Studio项目

### 步骤6：测试和验证

**验证步骤**：
1. 编译并安装应用到设备
2. 进入设备待机屏保界面：
   - 插入充电器或开启"不充电可显示"开关
   - 设备横屏锁屏并与桌面夹角45°~90°稳定摆放
   - 折叠机需切换为外屏，支持帐篷模式
3. 在待机屏保界面长按或双指捏合进入编辑界面
4. 上滑列表，点击"+"进入卡片管理页面
5. 在卡片管理页面找到应用卡片并添加
6. 验证卡片显示效果、数据更新、隐私蒙层等功能

**验证要点**：
- 卡片是否正确显示在待机屏保界面
- 深色主题是否生效
- backgroundImage是否被移除（isAdapted=true时）
- 隐私蒙层是否正确覆盖（isPrivacySensitive=true时）
- 卡片数据更新是否正常

## 错误码说明

| 错误场景 | 说明 | 解决方法 |
|---------|------|---------|
| 开放能力未获批 | 申请待机屏保开放能力被拒绝 | 重新提交申请，完善申请原因和附件材料 |
| API版本过低 | 项目API version < 23 | 在build-profile.json5中升级compileSdkVersion至23+ |
| 尺寸配置错误 | 配置了非2*2尺寸 | 修改form_config.json，仅配置supportDimensions为["2*2"] |
| 签名方式错误 | 使用自动签名而非手动签名 | 参考[手动签名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)配置 |
| standby字段缺失 | form_config.json缺少standby配置 | 添加standby字段，配置isSupported=true |
| isSupported为false | 卡片不支持待机屏保显示 | 修改standby.isSupported为true |
| UX规范不符合 | 卡片UI违反待机屏保设计规范 | 参考[待机屏保UX设计指南](https://developer.huawei.com/consumer/cn/doc/design-guides/system-features-service-widget-0000002087671904)调整UI |
| 五元组改变 | 应用升级后卡片五元组变化 | 保持五元组一致性，避免卡片在屏幕上消失 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@ohos/hypium": "1.0.6"
  }
}
```

### 环境要求
- DevEco Studio：3.1或更高版本
- HarmonyOS SDK：API version 23或更高
- compileSdkVersion：23或更高
- targetSdkVersion：23或更高

### 常见编译问题

**问题1：API version不满足要求**
```
错误信息：API version 23 required for standby widget
```
**解决方法**：在build-profile.json5中配置：
```json
{
  "app": {
    "compileSdkVersion": 23,
    "compatibleSdkVersion": 23,
    "targetSdkVersion": 23
  }
}
```

**问题2：standby字段语法错误**
```
错误信息：Unknown field 'standby' in form_config.json
```
**解决方法**：确认API version ≥ 23，standby字段从API version 23开始支持

**问题3：卡片尺寸不支持**
```
错误信息：Standby widget only supports 2*2 dimension
```
**解决方法**：修改supportDimensions和defaultDimension为"2*2"

**问题4：开放能力未开通**
```
错误信息：Standby widget capability not enabled for this app
```
**解决方法**：在AppGallery Connect申请待机屏保开放能力并等待审批通过

**问题5：签名方式不支持**
```
错误信息：Automatic signing not supported for standby widget
```
**解决方法**：使用手动签名方式，参考[手动签名配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)

## 常见问题与解决方法

### Q1：如何申请待机屏保开放能力？
**原因**：待机屏保卡片展示在设备待机屏保界面，涉及数据隐私安全，需申请开放能力
**解决方法**：
- 登录AppGallery Connect
- 进入"开放能力管理"页面
- 点击待机屏保卡片申请按钮
- 填写申请原因（最多512字符）和可选附件（最大500MB）
- 提交申请并等待审批

### Q2：为什么只能使用2*2尺寸？
**原因**：待机屏保界面设计规范限制了卡片尺寸，仅支持2*2尺寸以保持界面美观和一致性
**解决方法**：
- 仅配置supportDimensions为["2*2"]
- 设计卡片UI时适配2*2尺寸布局
- 参考[待机屏保UX设计指南](https://developer.huawei.com/consumer/cn/doc/design-guides/system-features-service-widget-0000002087671904)

### Q3：isAdapted字段有什么作用？
**原因**：isAdapted标识卡片是否适配待机屏保UX规范
**解决方法**：
- 设置为true时，系统会移除卡片布局组件中的backgroundImage
- 建议适配待机屏保UX规范并设置为true
- 使用深色主题和简洁布局

### Q4：如何处理隐私敏感数据？
**原因**：待机屏保界面可能被他人看到，涉及隐私安全
**解决方法**：
- 不推荐展示用户个人隐私敏感数据
- 如必须展示，设置isPrivacySensitive为true
- 用户添加卡片到待机屏保时会有蒙层覆盖隐私内容
- 建议展示天气、日历等非敏感信息

### Q5：为什么必须使用手动签名？
**原因**：待机屏保开放能力需要严格的权限控制和隐私保护
**解决方法**：
- 使用手动签名方式配置项目
- 在申请Profile时创建HarmonyOS应用
- 参考[手动签名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)和[申请Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278)

### Q6：如何进入待机屏保界面测试？
**原因**：需要正确进入待机屏保界面才能验证卡片效果
**解决方法**：
- 插入充电器或开启"不充电可显示"开关
- 设备横屏锁屏并与桌面夹角45°~90°稳定摆放
- 折叠机需切换为外屏，支持帐篷模式
- 在待机屏保界面长按或双指捏合进入编辑界面

### Q7：卡片五元组改变后卡片消失怎么办？
**原因**：应用升级后五元组（bundleName、moduleName、abilityName、formName、formDimension）改变，系统会删除原卡片
**解决方法**：
- 保持五元组一致性，避免修改
- 不建议使用资源文件导入配置五元组
- 必须修改时，提示用户重新添加卡片

### Q8：待机屏保界面默认深色模式如何处理？
**原因**：待机屏保界面默认为深色模式，不跟随系统设置
**解决方法**：
- 设计卡片UI时使用深色主题
- 文字颜色使用白色或浅色（#FFFFFF、#CCCCCC等）
- 背景使用深色（#1A1A1A等）
- 图片和图标适配深色背景

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "capability": "待机屏保开放能力申请",
  "cardCreated": "已创建2*2尺寸ArkTS卡片",
  "standbyConfigured": "已配置standby字段（isSupported=true）",
  "signingMethod": "手动签名配置完成",
  "apiUsed": [
    "FormExtensionAbility",
    "form_config.json配置",
    "standby字段配置"
  ],
  "nextSteps": [
    "在AppGallery Connect申请待机屏保开放能力",
    "使用手动签名发布应用",
    "在设备待机屏保界面测试卡片效果"
  ]
}
```

## 参考文档

- [ArkTS待机屏保卡片开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-ui-standby-form-development)
- [创建ArkTS卡片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-creation)
- [配置ArkTS卡片的配置文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)
- [手动签名配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)
- [申请Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278)
- [创建HarmonyOS应用](https://developer.huawei.com/consumer/cn/doc/app/agc-help-create-app-0000002247955506)
- [待机屏保UX设计指南](https://developer.huawei.com/consumer/cn/doc/design-guides/system-features-service-widget-0000002087671904)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [formProvider API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)

## 完整示例代码

- [ArkTS卡片页面示例](assets/WidgetCard.ets)
- [form_config.json配置示例](assets/form_config.json)
- [module.json5配置示例](assets/module.json5)
- [开放能力申请示例](assets/capability_application.txt)

## 测试用例

### 正向测试用例
- [测试待机屏保卡片创建](tests/test_standby_widget_creation.py)：验证2*2尺寸卡片正确创建
- [测试standby配置](tests/test_standby_config.py)：验证standby字段配置正确
- [测试开放能力申请](tests/test_capability_application.py)：验证申请流程完成

### 边界测试用例
- [测试API版本边界](tests/test_api_version_boundary.py)：验证API version 23最低要求
- [测试申请原因长度](tests/test_application_reason_length.py)：验证512字符上限
- [测试附件大小](tests/test_attachment_size.py)：验证500MB上限

### 异常测试用例
- [测试开放能力未获批](tests/test_capability_not_approved.py)：验证未获批时的错误处理
- [测试尺寸配置错误](tests/test_dimension_error.py)：验证非2*2尺寸的错误提示
- [测试签名方式错误](tests/test_signing_error.py)：验证自动签名的错误提示