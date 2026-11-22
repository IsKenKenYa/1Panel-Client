---
name: hmos-form-kit-lockscreen-widget
description: 开发锁屏界面显示卡片，支持1*1/1*2尺寸，仅手机/平板设备，API version 18+，需申请开放能力，适用于天气时钟快捷信息展示场景
---

# 锁屏卡片开发技能

## 功能描述

本技能提供HarmonyOS锁屏卡片开发能力，实现在设备锁屏界面上显示卡片，展示重要信息或快捷操作。锁屏卡片支持1*1和1*2两种尺寸，用户无需解锁即可获取关键资讯或执行常用功能，常用于展示天气、时钟等内容。

从API version 18开始，Form Kit提供锁屏卡片能力。开发者需要配置form_config.json文件，申请锁屏卡片开放能力，并遵循界面约束和安全规范。

## 使用场景

### 触发词
- "开发锁屏卡片"
- "锁屏卡片开发指导"
- "创建锁屏卡片"
- "配置锁屏卡片"
- "申请锁屏卡片开放能力"

### 能做
- 配置锁屏卡片的form_config.json文件
- 设置renderingMode和supportDimensions字段
- 申请锁屏卡片开放能力
- 开发支持1*1和1*2尺寸的锁屏卡片
- 实现锁屏卡片的添加、删除、移动功能

### 绝不做
- 开发大于1*2尺寸的锁屏卡片
- 在锁屏卡片展示涉及用户隐私敏感数据
- 在不支持锁屏卡片的设备(手表、车机等)上开发
- 使用API version 18以下的renderingMode配置方法
- 开发违背卡片内容设计规范的锁屏卡片

### 补充
- 锁屏卡片仅支持手机、平板设备
- 必须使用手动签名并申请开放能力
- 不推荐展示隐私敏感数据
- 需遵循卡片内容设计规范

## 调用规范和规则

### 输入约束
- 卡片尺寸：仅支持"1*1"或"1*2"
- renderingMode：仅支持"singleColor"或"autoColor"
- 设备类型：仅支持手机、平板
- API版本：必须>=API version 18

### 执行约束
- 最大开发周期：1-3个工作日(开放能力申请)
- 配置文件格式：JSON格式UTF-8编码
- 最大卡片数量：每个应用最多16个卡片
- 签名类型：必须使用手动签名

### 内容约束
- 禁止展示：隐私敏感数据、个人身份信息、金融账户信息
- 禁止配置：大于1*2的尺寸、fullColor渲染模式
- 禁止使用：自动签名、临时调试Profile
- 界面约束：遵循卡片内容设计规范

### 降级约束
- 开放能力申请失败：提示用户重新申请或联系华为客服
- 设备不支持：提示用户仅支持手机/平板设备
- 签名配置错误：引导用户使用手动签名流程
- API版本不匹配：提示用户升级API版本或使用兼容配置

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认设备类型为手机或平板
2. 确认API版本>=18
3. 确认已创建ArkTS卡片工程
4. 确认已安装DevEco Studio开发工具

**参数准备**：
```typescript
// 锁屏卡片配置参数
const lockscreenWidgetConfig = {
  name: "widget",
  displayName: "$string:widget_display_name",
  description: "$string:widget_desc",
  src: "./ets/widget/pages/WidgetCard.ets",
  uiSyntax: "arkts",
  isDynamic: true,
  isDefault: true,
  updateEnabled: false,
  scheduledUpdateTime: "10:30",
  renderingMode: "autoColor", // API version 18+
  updateDuration: 1,
  defaultDimension: "1*2",
  supportDimensions: ["1*2", "2*2"] // 必须包含1*1或1*2
};
```

### 步骤2：配置form_config.json

**示例代码**：
```typescript
// API version 18及以上版本的配置方法
// entry/src/main/resources/base/profile/form_config.json
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
      "renderingMode": "autoColor", // 必须配置为singleColor或autoColor
      "updateDuration": 1,
      "defaultDimension": "1*2",
      "supportDimensions": [
        "1*2",
        "2*2"
      ] // 必须包含"1*1"或"1*2"
    }
  ]
}
```

**注意事项**：
- renderingMode字段必须配置为"singleColor"或"autoColor"
- supportDimensions必须包含"1*1"或"1*2"
- API version 18之前使用metadata方式配置renderingMode(已废弃)

### 步骤3：申请开放能力

**申请流程**：
1. 登录AppGallery Connect平台
2. 创建HarmonyOS应用
3. 在"开放能力接入"页面申请锁屏卡片能力
4. 填写申请原因和上传附件(可选)
5. 等待1-3个工作日审批结果
6. 审批通过后勾选锁屏卡片能力开关并保存

**手动签名配置**：
```typescript
// 使用手动签名进行调试和发布
// 参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing
// 申请Profile：https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278
```

### 步骤4：开发卡片UI

**示例代码**：
```typescript
// WidgetCard.ets - 锁屏卡片UI实现
import { formBindingData, FormExtensionAbility } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

@Entry
@Component
struct WidgetCard {
  @LocalStorageProp('temperature') temperature: string = '20c';
  @LocalStorageProp('time') time: string = '12:00';

  build() {
    Column() {
      // 卡片内容，遵循锁屏卡片设计规范
      Text(this.temperature)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      Text(this.time)
        .fontSize(16)
    }
    .width('100%')
    .height('100%')
    .padding(10)
  }
}

// FormExtensionAbility实现
export default class LockScreenFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    console.info('LockScreenFormAbility onAddForm');
    let formData: Record<string, string> = {
      'temperature': '20c',
      'time': '12:00'
    };
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string) {
    console.info('LockScreenFormAbility onUpdateForm, formId:', formId);
    // 更新卡片数据逻辑
  }

  onRemoveForm(formId: string) {
    console.info('LockScreenFormAbility onRemoveForm, formId:', formId);
    // 清理卡片数据逻辑
  }
}
```

### 步骤5：错误处理

```typescript
// 错误处理代码
import { formProvider, formBindingData } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function updateLockScreenWidget(formId: string) {
  try {
    let formData: Record<string, string> = {
      'temperature': '25c',
      'time': '14:00'
    };
    let bindingData = formBindingData.createFormBindingData(formData);
    
    await formProvider.updateForm(formId, bindingData);
    console.info('锁屏卡片更新成功');
  } catch (error) {
    let err = error as BusinessError;
    console.error('锁屏卡片更新失败:', err.code, err.message);
    
    // 根据错误码处理
    switch (err.code) {
      case 1:
        console.error('卡片不存在');
        break;
      case 2:
        console.error('卡片ID无效');
        break;
      case 3:
        console.error('卡片数据格式错误');
        break;
      default:
        console.error('未知错误');
    }
  }
}
```

### 步骤6：降级处理

```typescript
// 降级处理代码
async function handleLockScreenWidgetFallback(deviceType: string, apiVersion: number) {
  // 设备不支持降级
  if (deviceType !== 'phone' && deviceType !== 'tablet') {
    console.warn('当前设备不支持锁屏卡片，仅支持手机和平板');
    return;
  }
  
  // API版本降级处理
  if (apiVersion < 18) {
    console.warn('API版本低于18，使用旧的renderingMode配置方式');
    // 使用metadata方式配置renderingMode
    // 注意：此方式已废弃，建议升级API版本
    return;
  }
  
  // 开放能力未申请降级
  console.warn('锁屏卡片开放能力未申请，请前往AppGallery Connect申请');
  // 引导用户申请开放能力
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1 | 卡片不存在 | 检查卡片ID是否正确，确认卡片是否已创建 |
| 2 | 卡片ID无效 | 验证卡片ID格式，确保为有效字符串 |
| 3 | 卡片数据格式错误 | 检查FormBindingData数据结构，确保符合规范 |
| 4 | 卡片尺寸不支持 | 锁屏卡片仅支持1*1和1*2尺寸，修改supportDimensions配置 |
| 5 | renderingMode配置错误 | 锁屏卡片仅支持singleColor和autoColor模式 |
| 6 | 设备不支持锁屏卡片 | 确认设备类型为手机或平板 |
| 7 | API版本不匹配 | 升级API版本至18以上或使用兼容配置 |
| 8 | 开放能力未申请 | 前往AppGallery Connect申请锁屏卡片开放能力 |
| 9 | 签名配置错误 | 使用手动签名方式进行调试和发布 |
| 10 | 卡片数量超限 | 每个应用最多支持16个卡片 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "latest",
    "@kit.AbilityKit": "latest"
  }
}
```

### 环境要求
- DevEco Studio: 4.0及以上版本
- HarmonyOS SDK: API version 18及以上
- 设备类型: 手机、平板
- Node.js: 14.19.1及以上

### 常见编译问题

**问题1：renderingMode配置错误**
```
Error: renderingMode must be 'singleColor' or 'autoColor' for lockscreen widget
```
**解决方法**：将form_config.json中的renderingMode字段修改为"singleColor"或"autoColor"

**问题2：supportDimensions尺寸错误**
```
Error: supportDimensions must contain '1*1' or '1*2' for lockscreen widget
```
**解决方法**：在supportDimensions数组中添加"1*1"或"1*2"尺寸

**问题3：开放能力未申请**
```
Error: Lockscreen widget capability not granted
```
**解决方法**：前往AppGallery Connect申请锁屏卡片开放能力，等待审批通过

**问题4：签名配置错误**
```
Error: Invalid signature profile for lockscreen widget
```
**解决方法**：使用手动签名方式，配置正确的Profile文件

**问题5：API版本不兼容**
```
Error: API version mismatch, lockscreen widget requires API 18+
```
**解决方法**：升级HarmonyOS SDK至API version 18及以上

## 常见问题与解决方法

### Q1：如何申请锁屏卡片开放能力？
**原因**：锁屏卡片需要华为审批才能使用
**解决方法**：
- 登录AppGallery Connect平台
- 在应用详情页找到"开放能力接入"
- 点击锁屏卡片对应的申请按钮
- 填写申请原因(必填，不超过256字符)
- 上传附件(可选，最大500MB)
- 等待1-3个工作日审批结果
- 审批通过后勾选能力开关并保存

### Q2：锁屏卡片支持哪些尺寸？
**原因**：锁屏界面空间限制
**解决方法**：
- 锁屏卡片仅支持1*1和1*2两种尺寸
- 1*1尺寸占用1个卡片添加位
- 1*2尺寸占用2个卡片添加位
- 在form_config.json中配置supportDimensions包含"1*1"或"1*2"

### Q3：renderingMode如何配置？
**原因**：API version 18配置方式变更
**解决方法**：
- API version 18及以上：直接配置renderingMode字段为"singleColor"或"autoColor"
- API version 18以下(已废弃)：使用metadata方式，value值"2"代表"singleColor"
- 推荐使用新版本配置方式，升级API至18以上

### Q4：为什么需要手动签名？
**原因**：锁屏卡片涉及用户隐私安全
**解决方法**：
- 锁屏卡片展示在锁屏界面，需要严格的安全审查
- 自动签名无法申请开放能力
- 必须使用手动签名并申请Profile
- 在AppGallery Connect创建应用并申请开放能力后才能调试和发布

### Q5：锁屏卡片可以展示哪些内容？
**原因**：界面设计和隐私安全约束
**解决方法**：
- 推荐展示：天气、时钟、运动健康等非敏感信息
- 不推荐展示：个人隐私数据、金融账户信息、身份认证信息
- 遵循卡片内容设计规范
- 参考：https://developer.huawei.com/consumer/cn/doc/design-guides/system-features-service-widget-0000002087671904

### Q6：如何处理设备不支持的情况？
**原因**：锁屏卡片仅支持手机和平板
**解决方法**：
- 在代码中检查设备类型
- 如果设备为手表、车机等不支持类型，提示用户
- 提供降级方案，如开发普通桌面卡片
- 使用设备类型判断API进行适配

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "widgetConfigured": true,
  "renderingMode": "autoColor",
  "supportDimensions": ["1*2", "2*2"],
  "capabilityApplied": true,
  "capabilityApproved": false,
  "deviceTypes": ["phone", "tablet"],
  "apiVersion": 18,
  "signatureType": "manual",
  "apiUsed": [
    "FormExtensionAbility.onAddForm",
    "FormExtensionAbility.onUpdateForm",
    "formBindingData.createFormBindingData",
    "formProvider.updateForm"
  ]
}
```

## 参考文档

- [锁屏卡片开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-lockscreen-form-development)
- [配置ArkTS卡片的配置文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [FormExtensionContext API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-formextensioncontext)
- [手动签名配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)
- [申请Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278)
- [创建HarmonyOS应用](https://developer.huawei.com/consumer/cn/doc/app/agc-help-create-app-0000002247955506)
- [卡片内容设计](https://developer.huawei.com/consumer/cn/doc/design-guides/system-features-service-widget-0000002087671904)

## 完整示例代码

- [ArkTS锁屏卡片示例](assets/lockscreen_widget_example.ets)
- [form_config.json配置示例](assets/lockscreen_form_config.json)
- [FormExtensionAbility完整实现](assets/lockscreen_form_extension.ets)
- [module.json5配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [创建1*2尺寸锁屏卡片](tests/test_positive.py)：验证成功创建锁屏卡片
- [配置autoColor渲染模式](tests/test_positive.py)：验证渲染模式配置正确
- [申请开放能力流程](tests/test_positive.py)：验证开放能力申请流程

### 边界测试用例
- [最小尺寸1*1卡片](tests/test_boundary.py)：验证1*1尺寸卡片创建
- [最大卡片数量限制](tests/test_boundary.py)：验证16个卡片数量限制
- [API version 18临界版本](tests/test_boundary.py)：验证API版本临界值

### 异常测试用例
- [尺寸不支持异常](tests/test_exception.py)：验证大于1*2尺寸的错误处理
- [设备不支持异常](tests/test_exception.py)：验证手表设备不支持的处理
- [开放能力未申请异常](tests/test_exception.py)：验证开放能力未申请的错误处理
- [签名配置错误异常](tests/test_exception.py)：验证自动签名的错误提示