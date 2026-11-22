---
name: hmos-share-kit-process-share-content
description: 接收并处理来自分享面板的数据，支持文本/图片/文件等多种类型，需配置UTD数据类型过滤和分享能力，适用于接收分享内容进行数据处理的场景
---

# 应用内处理分享内容技能

## 功能描述

本技能用于实现HarmonyOS应用接收和处理来自系统分享面板的分享数据。目标应用可以通过UIAbility构建接收分享内容的界面，将应用显示到分享面板应用推荐区内，实现将分享内容传递到目标应用内进行处理。

核心功能包括：
- 从Want参数中解析分享数据
- 支持多种数据类型（文本、图片、文件等）
- 支持获取联系人信息（针对联系人分享场景）
- 通过UTD（统一数据类型）进行数据类型过滤

## 使用场景

### 触发词
- "处理分享内容"
- "接收分享数据"
- "应用内分享"
- "解析分享Want"
- "获取分享数据"

### 能做
- 从Want参数中解析出分享数据记录
- 获取分享数据的内容、URI、类型等信息
- 处理文本、图片、文件等多种分享类型
- 获取联系人信息（分享到联系人场景）
- 根据UTD类型过滤和处理特定类型的数据

### 绝不做
- 不直接拉起分享面板（需使用ShareController）
- 不处理超出应用声明支持的数据类型
- 不修改Want参数中的原始数据
- 不在没有配置分享能力的情况下处理分享

### 补充
- 必须在module.json5中配置支持分享的能力
- 需要声明支持的UTD数据类型
- 分享数据最大支持500条记录
- 数据总大小不超过IPC传输上限200KB

## 调用规范和规则

### 输入约束
- Want参数：必须包含有效的分享数据结构
- 数据记录数量：最大500条
- 数据总大小：不超过200KB（IPC传输上限）
- UTD类型：必须在module.json5中声明支持的类型

### 执行约束
- API调用模式：异步Promise调用
- 最大耗时：无明确限制，但建议在onCreate/onNewWant中快速处理
- 错误处理：必须捕获BusinessError异常
- 生命周期：在UIAbility的onCreate或onNewWant回调中处理

### 内容约束
- 禁止使用：未声明支持的UTD类型
- 禁止操作：直接修改Want参数数据
- 禁止跳过：UTD类型校验和错误处理
- 必须包含：完整的错误处理和降级方案

### 降级约束
- 数据解析失败：提示用户并关闭Ability
- 联系人获取失败：继续处理分享数据，忽略联系人信息
- 权限不足：提示用户并终止处理
- 数据超限：提示用户数据过大，建议减少分享内容

## 调用流程和步骤

### 步骤1：准备阶段 - 导入模块和配置

**导入必要模块**：
```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**配置文件准备（module.json5）**：
```json
{
  "abilities": [
    {
      "name": "TestUIAbility",
      "srcEntry": "./ets/entryability/TestUIAbility.ets",
      "description": "$string:EntryAbility_desc",
      "icon": "$media:layered_image",
      "label": "$string:EntryAbility_label",
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
            },
            {
              "scheme": "file",
              "utd": "general.png",
              "maxFileSupported": 1
            },
            {
              "scheme": "file",
              "utd": "general.jpeg",
              "maxFileSupported": 1
            }
          ]
        }
      ]
    }
  ]
}
```

**前置校验**：
1. 确认module.json5已配置分享能力
2. 确认声明的UTD类型覆盖预期接收的数据类型
3. 确认maxFileSupported配置合理

### 步骤2：实现UIAbility并处理分享数据

**基础示例代码**：
```typescript
export default class TestUIAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        const records = data.getRecords();
        console.info(`Received ${records.length} share records`);
        
        records.forEach((record: systemShare.SharedRecord) => {
          this.processShareRecord(record);
        });
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getSharedData. Code: ${error.code}, message: ${error.message}`);
        this.context.terminateSelf();
      });
  }
  
  private processShareRecord(record: systemShare.SharedRecord): void {
    console.info(`Processing record: utd=${record.utd}, title=${record.title}`);
    
    if (record.content) {
      console.info(`Content: ${record.content}`);
    }
    
    if (record.uri) {
      console.info(`URI: ${record.uri}`);
    }
    
    if (record.extraData) {
      console.info(`ExtraData: ${JSON.stringify(record.extraData)}`);
    }
  }
  
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        console.error(`Failed to load content. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      console.info('Succeeded in loading content');
    });
  }
}
```

### 步骤3：处理联系人分享场景

**获取联系人信息示例**：
```typescript
export default class ContactShareAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    systemShare.getContactInfo(want)
      .then(async (contact: systemShare.ContactInfo) => {
        console.info(`Contact type: ${contact.contactType}, ID: ${contact.contactId}`);
        
        const data = await systemShare.getSharedData(want);
        const records = data.getRecords();
        
        this.shareToContact(contact, records);
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getContactInfo. Code: ${error.code}, message: ${error.message}`);
        this.handleShareWithoutContact(want);
      });
  }
  
  private shareToContact(contact: systemShare.ContactInfo, records: systemShare.SharedRecord[]): void {
    console.info(`Sharing ${records.length} items to contact ${contact.contactId}`);
  }
  
  private async handleShareWithoutContact(want: Want): void {
    try {
      const data = await systemShare.getSharedData(want);
      data.getRecords().forEach((record) => {
        this.processShareRecord(record);
      });
    } catch (error) {
      console.error('Failed to handle share without contact');
      this.context.terminateSelf();
    }
  }
}
```

### 步骤4：处理热启动场景（onNewWant）

**onNewWant处理示例**：
```typescript
export default class MultiShareAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleShare(want);
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleShare(want);
  }
  
  private async handleShare(want: Want): void {
    try {
      const data = await systemShare.getSharedData(want);
      const records = data.getRecords();
      
      for (const record of records) {
        await this.processShareRecordAsync(record);
      }
      
      console.info('Share processing completed');
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`Share processing failed. Code: ${businessError.code}, message: ${businessError.message}`);
      this.context.terminateSelf();
    }
  }
  
  private async processShareRecordAsync(record: systemShare.SharedRecord): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(() => {
        console.info(`Processed record: ${record.utd}`);
        resolve();
      }, 100);
    });
  }
}
```

### 步骤5：错误处理和降级方案

**完整错误处理示例**：
```typescript
export default class RobustShareAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleShareWithFallback(want);
  }
  
  private async handleShareWithFallback(want: Want): void {
    try {
      const data = await systemShare.getSharedData(want);
      const records = data.getRecords();
      
      if (records.length === 0) {
        console.warn('No share records found');
        this.showToast('未收到分享内容');
        this.context.terminateSelf();
        return;
      }
      
      if (records.length > 100) {
        console.warn(`Too many records: ${records.length}`);
        this.showToast('分享内容过多，请减少分享数量');
        this.processFirstNRecords(records, 100);
      } else {
        await this.processAllRecords(records);
      }
      
    } catch (error) {
      const businessError = error as BusinessError;
      this.handleShareError(businessError);
    }
  }
  
  private handleShareError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error');
        this.showToast('分享数据格式错误');
        break;
      case 1003703001:
        console.error('Parse data failed');
        this.showToast('无法解析分享数据');
        break;
      default:
        console.error(`Unknown error: ${error.code}`);
        this.showToast(`处理分享失败: ${error.message}`);
    }
    
    this.context.terminateSelf();
  }
  
  private showToast(message: string): void {
    console.info(`Toast: ${message}`);
  }
  
  private processFirstNRecords(records: systemShare.SharedRecord[], max: number): void {
    const subset = records.slice(0, max);
    subset.forEach((record) => {
      this.processShareRecord(record);
    });
  }
  
  private async processAllRecords(records: systemShare.SharedRecord[]): Promise<void> {
    for (const record of records) {
      try {
        await this.processShareRecordAsync(record);
      } catch (error) {
        console.warn(`Failed to process record: ${record.utd}`);
      }
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，Want参数格式不正确 | 检查Want参数是否包含有效的分享数据结构 |
| 1003703001 | 解析数据失败，无法从Want中提取分享数据 | 检查分享数据是否符合规范，确保UTD类型正确 |
| 1003700001 | 记录数量超过最大值（500条） | 减少分享数据记录数量，建议单次分享不超过100条 |
| 1003702002 | IPC数据大小超限（200KB） | 压缩分享内容大小，减少缩略图等数据 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AbilityKit": "^1.0.0",
    "@kit.ShareKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 11及以上（4.1.0(11)）
- 开发工具：DevEco Studio 3.1及以上
- 模型约束：仅可在Stage模型下使用

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ShareKit'
```
**解决方法**：确保DevEco Studio版本支持HarmonyOS API 11，更新SDK版本

**问题2：UIAbility类型错误**
```
Error: Type 'UIAbility' is not defined
```
**解决方法**：正确导入UIAbility：`import { UIAbility } from '@kit.AbilityKit'`

**问题3：Want类型不匹配**
```
Error: Property 'getRecords' does not exist on type 'SharedData'
```
**解决方法**：确保使用正确的systemShare.SharedData类型，检查API版本

## 常见问题与解决方法

### Q1：如何判断用户分享的是哪种类型的数据？
**原因**：需要根据UTD类型进行判断
**解决方法**：
- 检查record.utd字段值
- 使用uniformTypeDescriptor模块定义的常量进行匹配
- 根据不同类型执行不同的处理逻辑

### Q2：如何处理多条分享记录？
**原因**：批量分享时会包含多条记录
**解决方法**：
- 使用data.getRecords()获取所有记录
- 根据selectionMode判断用户选择模式
- 单选模式：需要用户多选一
- 批量模式：处理全部记录

### Q3：为什么getContactInfo返回失败？
**原因**：仅当用户选择联系人分享时才有效
**解决方法**：
- 添加错误处理和降级方案
- 如果获取联系人失败，继续处理分享数据
- 使用try-catch捕获异常

### Q4：如何限制接收的数据类型？
**原因**：需要在配置文件中声明支持的类型
**解决方法**：
- 在module.json5的skills.uris中配置utd字段
- 精确配置支持的UTD类型（如general.text, general.png）
- 设置maxFileSupported限制文件数量

### Q5：分享数据过大怎么办？
**原因**：IPC传输上限200KB，超过会失败
**解决方法**：
- 压缩缩略图大小（32KB以下）
- 使用ImagePacker.packToData压缩图片
- 减少extraData字段内容
- 分批次处理大数据

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "processedRecords": 5,
  "recordTypes": ["general.text", "general.png"],
  "hasContactInfo": false,
  "apiUsed": [
    "systemShare.getSharedData",
    "SharedData.getRecords",
    "UIAbility.onCreate"
  ],
  "errors": []
}
```

## 参考文档

- [应用内处理分享内容开发指南](references/share-interface-description.md)
- [systemShare API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [UIAbility API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiability)
- [Want API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-ability-want)

## 完整示例代码

- [基础分享处理示例](assets/example_basic_share.ets)
- [联系人分享示例](assets/example_contact_share.ets)
- [完整错误处理示例](assets/example_robust_share.ets)
- [module.json5配置示例](assets/module_config.json)

## 测试用例

### 正向测试用例
- [测试接收文本分享](tests/test_receive_text_share.py)：验证文本类型分享数据处理
- [测试接收图片分享](tests/test_receive_image_share.py)：验证图片类型分享数据处理
- [测试接收多文件分享](tests/test_receive_multiple_files.py)：验证批量分享数据处理

### 边界测试用例
- [测试最大记录数量](tests/test_max_records.py)：验证500条记录边界处理
- [测试数据大小边界](tests/test_data_size_limit.py)：验证200KB数据大小边界
- [测试空分享数据](tests/test_empty_share.py)：验证空数据异常处理

### 异常测试用例
- [测试无效Want参数](tests/test_invalid_want.py)：验证参数错误处理
- [测试数据解析失败](tests/test_parse_failed.py)：验证解析失败降级方案
- [测试未配置分享能力](tests/test_unconfigured_ability.py)：验证配置缺失场景