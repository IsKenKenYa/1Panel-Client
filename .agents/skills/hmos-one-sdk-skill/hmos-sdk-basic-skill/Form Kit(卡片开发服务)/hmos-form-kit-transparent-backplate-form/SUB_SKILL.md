---
name: hmos-form-kit-transparent-backplate-form
description: 实现ArkTS卡片背板透明显示能力，支持卡片背景透明和文字反色，需要申请开放能力并通过AppGallery Connect审核，适用于桌面美化、个性化卡片设计场景，API version 22开始支持
---

# 背板透明卡片开发技能

## 功能描述

本技能提供HarmonyOS ArkTS卡片背板透明显示的开发能力。从API version 22开始，Form Kit支持卡片背板元素透明显示，允许开发者创建具有透明背景的卡片，实现更丰富的UI设计效果。

核心能力包括：
- 卡片背景透明配置
- 卡片文字反色适配
- 开放能力申请流程
- 生命周期回调处理
- 卡片数据绑定和更新

**关键特性**：
- 非透明区域要求大于等于10%
- 支持系统推荐的文字反色显示
- 需通过AppGallery Connect申请开放能力
- 仅支持ArkTS卡片（JS卡片不支持）
- 适用于桌面、卡片中心等场景

## 使用场景

### 触发词
- "透明卡片"
- "背板透明"
- "卡片背景透明"
- "透明卡片开发"
- "ArkTS透明卡片"
- "卡片透明度"

### 能做
- 创建具有透明背景的ArkTS卡片
- 配置卡片透明度和文字反色
- 处理卡片生命周期回调（onAddForm、onUpdateForm等）
- 实现卡片数据绑定和动态更新
- 申请背板透明卡片开放能力
- 实现卡片点击交互事件

### 绝不做
- 不支持JS卡片背板透明（仅ArkTS卡片支持）
- 不允许大面积全透明（非透明区域必须>=10%）
- 不处理非卡片相关的UI开发
- 不涉及卡片内容的具体业务逻辑实现
- 不处理卡片尺寸和形状的配置（属于基础卡片开发）

### 补充
- 需要先申请开放能力才能使用背板透明功能
- 申请需要提供UI设计释义材料
- 审批时间1-3个工作日
- 示例效果请以真机运行为准，不支持DevEco Studio预览器
- 文字颜色建议使用系统推荐的反色值

## 调用规范和规则

### 输入约束
- 卡片配置：必须在form_config.json中配置transparencyEnabled为true
- 透明度限制：非透明区域必须大于等于10%
- 文件大小：卡片刷新数据总大小不超过10MB（API version 20+）
- 图片数量：刷新图片数量不超过20张（API version 20+），API version 19及之前最多5张
- 图片内存：每张图片限制内存2MB（API version 19及之前）

### 执行约束
- 最大耗时：FormExtensionAbility创建后10秒内无操作将被清理
- API调用频次：遵循Form Kit的标准调用频率限制
- 开放能力申请：必须通过AppGallery Connect审核流程
- 手动签名：应用调试或发布时需要进行手动签名

### 内容约束
- 禁止生成：大面积全透明的卡片设计
- 禁止操作：隐藏卡片显示或功能按钮的恶意设计
- 禁止使用：在JS卡片中配置transparencyEnabled（无效）
- 必须包含：申请开放能力时必须提供UI设计释义材料

### 降级约束
- 能力未申请：提示用户先申请开放能力，使用普通卡片作为替代方案
- 审批未通过：使用普通卡片设计，调整UI方案
- 系统不支持：API version < 22时，提示用户升级系统或使用普通卡片
- 图片超出限制：压缩图片或减少图片数量

## 调用流程和步骤

### 步骤1：申请开放能力

**前置条件**：
1. 已创建HarmonyOS项目
2. 已注册华为开发者账号
3. 已准备好UI设计释义材料

**申请流程**：
```
步骤1.1：登录AppGallery Connect
- 访问 https://developer.huawei.com/consumer/cn/
- 选择"开发与服务"

步骤1.2：选择项目和应用
- 在项目列表中找到您的项目
- 点击选择需开启开放能力的应用/元服务

步骤1.3：申请背板透明卡片能力
- 进入"开放能力管理"页面
- 点击背板透明卡片对应的申请按钮

步骤1.4：填写申请信息
- 申请原因（必填）：包括应用介绍、使用场景、申请用途，不超过256个字符
- 上传附件（必填）：提供卡片UI设计释义材料，支持文本、表格、图片、视频、压缩包格式，大小不超过500MB

步骤1.5：等待审批结果
- 原"申请"按钮变为"申请中"
- 1-3个工作日反馈申请结果
- 审批通过后，互动中心会发送通知

步骤1.6：启用能力
- 审批通过后，勾选背板透明卡片的能力开关
- 点击右上角"保存"
```

### 步骤2：配置卡片透明属性

**配置文件示例**：
```json
// entry/src/main/resources/base/profile/form_config.json
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
      "isDynamic": true,
      "isDefault": true,
      "updateEnabled": false,
      "scheduledUpdateTime": "10:30",
      "updateDuration": 1,
      "defaultDimension": "2*2",
      "transparencyEnabled": true,  // 关键配置：启用背板透明
      "supportDimensions": [
        "2*2"
      ]
    }
  ]
}
```

**配置说明**：
- `transparencyEnabled`: 必须设置为true才能启用背板透明
- `uiSyntax`: 必须为"arkts"，JS卡片不支持透明背板
- `isDynamic`: 建议设置为true，动态卡片支持更多交互能力

### 步骤3：实现卡片布局和文字反色

**卡片页面代码**：
```typescript
// entry/src/main/ets/widget/pages/WidgetCard.ets
import { postCardAction } from '@ohos.app.form.formBindingData';

const TAG: string = 'WidgetCard';

@Entry
@Component
export struct WidgetCard {
  readonly title: string = '已配置form_config为true三方透明卡片';
  readonly actionType: string = 'router';
  readonly abilityName: string = 'EntryAbility';
  readonly message: string = 'add detail';
  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';
  
  // 获取反色信息，系统会自动传入推荐的反色值
  @LocalStorageProp('textColor') @Watch('getTextColor') textColor: string = '#00ff00';
  
  build() {
    Row() {
      Column() {
        Text(this.title)
          .fontSize('20vp')
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)  // 使用系统推荐的反色值
      }
      .width(this.fullWidthPercent)
    }
    .height(this.fullHeightPercent)
    .backgroundColor(Color.Transparent)  // 设置背景为透明
    .onClick(() => {
      // 卡片点击事件处理
      postCardAction(this, {
        action: this.actionType,
        abilityName: this.abilityName,
        params: {
          message: this.message
        }
      });
    })
  }
  
  private getTextColor(): void {
    console.info(TAG, `this.textColor = ${this.textColor}`);
  }
}
```

**关键要点**：
- 使用`@LocalStorageProp`装饰器接收系统传入的反色值
- 设置`backgroundColor(Color.Transparent)`实现背景透明
- 使用`@Watch`监听颜色值变化

### 步骤4：实现FormExtensionAbility生命周期

**FormExtensionAbility代码**：
```typescript
// entry/src/main/ets/entryformability/EntryFormAbility.ets
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

const TAG: string = 'ServiceEntryFormAbility';

export default class EntryFormAbility extends FormExtensionAbility {
  // 卡片创建时回调
  onAddForm(want: Want) {
    console.info(TAG, 'onAddForm', JSON.stringify(want));
    let textColor: string = '#707070';
    let formData: Record<string, string> = {};
    
    if (want && want.parameters) {
      // 获取反色信息
      let testColorJsonStr = want.parameters[formInfo.FormParam.HOST_BG_INVERSE_COLOR_KEY] as TextColor;
      if (!testColorJsonStr) {
        console.error(TAG, `no host_bg_inverse_color in want parameters`);
      } else {
        textColor = testColorJsonStr.mTextColor;
        formData['textColor'] = textColor;
      }
    }
    
    return formBindingData.createFormBindingData(formData);
  }
  
  onCastToNormalForm(formId: string) {
    console.info(TAG, 'onCastToNormalForm', formId);
  }
  
  // 卡片更新时回调
  onUpdateForm(formId: string, wantParams?: Record<string, Object>) {
    console.info(TAG, 'onUpdateForm', JSON.stringify(wantParams));
    let textColor: string = '#707070';
    
    if (wantParams) {
      let testColorJsonStr = wantParams[formInfo.FormParam.HOST_BG_INVERSE_COLOR_KEY] as TextColor;
      console.info(TAG, `onUpdate typeof testColorJsonStr = ${JSON.stringify(testColorJsonStr)}`);
      
      // 获取反色信息
      if (!testColorJsonStr) {
        console.error(TAG, `no host_bg_inverse_color in wantParams parameters`);
        return;
      } else {
        textColor = testColorJsonStr.mTextColor;
      }
    }
    
    let formMsg: Record<string, string> = {
      'textColor': textColor
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(formMsg);
    formProvider.updateForm(formId, formData).then((succ) => {
      console.info(TAG, `succ = ${JSON.stringify(succ)}`);
    }).catch((fail: Error) => {
      console.info(TAG, `err = ${JSON.stringify(fail)}`);
    });
  }
  
  onFormEvent(formId: string, message: string) {
    console.info(TAG, 'onFormEvent', formId, message);
  }
  
  onRemoveForm(formId: string) {
    console.info(TAG, 'onRemoveForm', formId);
  }
  
  onAcquireFormState(want: Want) {
    return formInfo.FormState.READY;
  }
}

// 反色信息接口定义
interface TextColor {
  mTextColor: string;
  mWallpaperType: number;
}
```

**生命周期说明**：
- `onAddForm`: 卡片创建时触发，获取并返回初始反色值
- `onUpdateForm`: 卡片更新时触发，更新反色值
- `HOST_BG_INVERSE_COLOR_KEY`: 系统提供的反色值参数键

### 步骤5：应用签名和测试

**签名流程**：
```
步骤5.1：配置调试签名
- 在DevEco Studio中打开项目
- 选择"File > Project Structure > Project > Signing Configs"
- 勾选"Automatically generate signature"
- 配置签名信息

步骤5.2：运行测试
- 连接真机或模拟器
- 点击Run按钮运行应用
- 在卡片中心添加卡片到桌面
- 验证透明效果和文字反色
```

### 步骤6：错误处理和降级

**常见错误处理**：
```typescript
// 错误处理示例
try {
  let formData = formBindingData.createFormBindingData(data);
  formProvider.updateForm(formId, formData).then(() => {
    console.info('Form updated successfully');
  }).catch((error: BusinessError) => {
    // 错误码处理
    switch (error.code) {
      case 16501001:
        console.error('卡片ID不存在，请检查formId');
        break;
      case 16501003:
        console.error('当前应用无法操作此卡片');
        break;
      case 16500050:
        console.error('IPC连接错误，请检查数据大小');
        break;
      default:
        console.error(`更新失败: code ${error.code}, message ${error.message}`);
    }
  });
} catch (error) {
  console.error('创建FormBindingData失败:', error);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 16500050 | IPC连接错误 | 检查数据大小是否超出限制，减少传输数据量 |
| 16500060 | 服务连接错误 | 重试连接服务，或重启设备 |
| 16500100 | 获取配置信息失败 | 检查form_config.json配置是否正确 |
| 16501000 | 内部功能错误 | 系统内部错误，重启系统后重试 |
| 16501001 | 卡片ID不存在 | 检查卡片ID的有效性，确保卡片已添加 |
| 16501002 | 卡片数量达到上限 | 删除不必要的卡片后重新添加 |
| 16501003 | 无法操作指定卡片 | 检查卡片ID是否属于本应用 |
| 401 | 参数错误 | 检查必填参数是否传入，参数类型是否正确 |

**透明卡片特有错误**：
- 能力未申请：返回16501000，需先完成开放能力申请
- 审批未通过：无法使用透明功能，需重新申请或调整方案

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "系统Kit，无需额外安装",
    "@kit.AbilityKit": "系统Kit，无需额外安装",
    "@kit.BasicServicesKit": "系统Kit，无需额外安装"
  }
}
```

### 环境要求
- HarmonyOS API version >= 22（背板透明能力从API 22开始支持）
- DevEco Studio 3.1或更高版本
- 真机或模拟器支持卡片功能

### 常见编译问题

**问题1：transparencyEnabled配置不生效**
```
错误：卡片背景仍为非透明
原因：form_config.json配置错误或未申请开放能力
解决方法：
1. 检查transparencyEnabled是否设置为true
2. 确认已在AppGallery Connect申请并获批
3. 确认uiSyntax为"arkts"而非"js"
```

**问题2：文字反色不生效**
```
错误：文字颜色未随背景变化
原因：未正确获取HOST_BG_INVERSE_COLOR_KEY参数
解决方法：
1. 检查onAddForm和onUpdateForm是否正确获取反色参数
2. 确保使用@LocalStorageProp接收颜色值
3. 验证formBindingData是否正确传递textColor
```

**问题3：FormExtensionAbility被清理**
```
错误：卡片生命周期回调不触发
原因：FormExtensionAbility创建后10秒内无操作被清理
解决方法：
1. 在onAddForm中快速完成数据绑定
2. 避免在生命周期方法中执行耗时操作
3. 使用异步操作但不阻塞主流程
```

**问题4：开放能力申请失败**
```
错误：申请被驳回或长时间无反馈
原因：申请材料不完整或不符合规范
解决方法：
1. 提供详细的UI设计释义材料
2. 说明具体使用场景和申请用途
3. 确保非透明区域>=10%
4. 如超过3个工作日未反馈，联系客服
```

## 常见问题与解决方法

### Q1：如何确认开放能力已获批？
**原因**：需要验证申请状态
**解决方法**：
- 登录AppGallery Connect
- 进入"开放能力管理"页面
- 检查背板透明卡片的申请按钮状态
- 申请通过后按钮会变为置灰的"申请"

### Q2：卡片透明度可以自定义吗？
**原因**：开发者想控制透明程度
**解决方法**：
- 当前不支持自定义透明度
- 只能设置为完全透明（Color.Transparent）
- 必保证非透明区域>=10%

### Q3：文字颜色必须使用系统推荐值吗？
**原因**：想自定义文字颜色
**解决方法**：
- 建议使用系统推荐的反色值以保证可见性
- 系统会根据背景壁纸自动计算反色值
- 可通过mWallpaperType判断壁纸类型
- 自定义颜色可能导致在某些背景下不清晰

### Q4：卡片刷新时图片数量有限制吗？
**原因**：需要传递多张图片
**解决方法**：
- API version 20+：最多20张图片，总大小不超过10MB
- API version 19及之前：最多5张图片，每张不超过2MB
- 超出限制会导致图片显示异常
- 建议压缩图片或减少数量

### Q5：DevEco Studio预览器能看到透明效果吗？
**原因**：开发调试需要查看效果
**解决方法**：
- 当前不支持DevEco Studio预览器查看透明效果
- 必须在真机或模拟器上运行才能看到实际效果
- 建议使用真机调试以获得准确体验

### Q6：JS卡片能使用背板透明吗？
**原因**：项目中有JS卡片
**解决方法**：
- 背板透明仅支持ArkTS卡片
- JS卡片配置transparencyEnabled无效
- 需将卡片迁移到ArkTS实现
- 参考ArkTS卡片开发文档进行迁移

### Q7：卡片添加后看不到透明效果？
**原因**：实际效果不符合预期
**解决方法**：
- 确认已手动签名并正确运行应用
- 检查卡片中心是否正确添加卡片
- 验证桌面壁纸是否支持透明显示
- 检查transparencyEnabled配置是否为true
- 确认开放能力已获批并启用

## 输出结果报告

执行完成后将输出以下信息：

```json
{
  "status": "success",
  "skillName": "hmos-form-kit-transparent-backplate-form",
  "functionality": "背板透明卡片开发能力",
  "apiUsed": [
    "formBindingData.createFormBindingData",
    "FormExtensionAbility.onAddForm",
    "FormExtensionAbility.onUpdateForm",
    "formProvider.updateForm",
    "postCardAction",
    "@LocalStorageProp",
    "@Watch"
  ],
  "keyConfig": {
    "transparencyEnabled": true,
    "uiSyntax": "arkts",
    "backgroundColor": "Color.Transparent"
  },
  "capabilities": [
    "卡片背板透明显示",
    "文字反色自动适配",
    "卡片生命周期管理",
    "数据绑定和更新"
  ],
  "requirements": {
    "apiVersion": ">= 22",
    "cardType": "ArkTS卡片",
    "permission": "需申请开放能力",
    "transparentArea": ">= 10%"
  },
  "files": {
    "config": "form_config.json",
    "cardPage": "WidgetCard.ets",
    "formAbility": "EntryFormAbility.ets"
  }
}
```

## 参考文档

- [背板透明卡片开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-transparent-backplate-form-development)
- [创建ArkTS卡片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-creation)
- [配置ArkTS卡片的配置文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)
- [手动签名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)
- [@ohos.app.form.formBindingData (卡片数据绑定类)](references/js-apis-app-form-formbindingdata.md)
- [@ohos.app.form.FormExtensionAbility](references/js-apis-app-form-formextensionability.md)
- [@ohos.app.form.formProvider](references/js-apis-app-form-formprovider.md)
- [@ohos.app.form.formInfo](references/js-apis-app-form-forminfo.md)
- [卡片错误码](references/errorcode-form.md)
- [postCardAction](references/js-apis-postcardaction.md)

## 完整示例代码

- [卡片配置文件示例](assets/form_config.json)
- [卡片页面代码示例](assets/WidgetCard.ets)
- [FormExtensionAbility示例](assets/EntryFormAbility.ets)

## 测试用例

### 正向测试用例
- [创建透明卡片并验证背景透明](tests/test_positive_transparency.md)
- [验证文字反色功能](tests/test_positive_text_color.md)
- [验证卡片点击交互](tests/test_positive_interaction.md)

### 边界测试用例
- [测试非透明区域10%边界值](tests/test_boundary_transparency_area.md)
- [测试图片数量和大小限制](tests/test_boundary_image_limit.md)

### 异常测试用例
- [未申请开放能力时创建透明卡片](tests/test_exception_no_permission.md)
- [配置错误的transparencyEnabled值](tests/test_exception_invalid_config.md)
- [传递超出限制的图片数据](tests/test_exception_image_overflow.md)