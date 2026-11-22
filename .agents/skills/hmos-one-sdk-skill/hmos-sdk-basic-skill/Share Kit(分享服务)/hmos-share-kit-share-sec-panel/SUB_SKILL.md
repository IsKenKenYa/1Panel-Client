---
name: hmos-share-kit-share-sec-panel
description: 处理分享详情页接收的分享内容，支持文本、图片、视频、文件等数据类型，基于ShareExtensionAbility实现，适用于社交类应用和内容分享应用，支持意图框架联系人推荐
---

# 分享详情页处理分享内容技能

## 功能描述

本技能实现HarmonyOS分享详情页处理分享内容功能。通过ShareExtensionAbility构建接收分享内容的分享详情页，将应用显示到分享面板应用推荐区，便捷处理用户分享的文本、图片、视频、文件等数据。支持通过意图框架获取联系人推荐信息，实现直接分享到指定用户的功能。

**核心能力**：
- 解析系统传递的分享数据（SharedData）
- 处理多种数据类型（文本、图片、视频、文件等）
- 获取意图框架推荐的联系人信息
- 加载分享详情页UI界面
- 返回处理结果或关闭分享详情页

**技术基础**：
基于UIExtensionAbility界面嵌入能力，通过ShareExtensionAbility扩展组件实现，继承自UIExtensionAbility，提供onSessionCreate生命周期回调用于处理分享数据。

## 使用场景

### 触发词
- "分享详情页处理分享内容"
- "ShareExtensionAbility实现"
- "目标应用处理分享数据"
- "接收分享内容"
- "处理分享详情页"

### 能做
- 接收并解析系统分享面板传递的分享数据
- 处理文本、图片、视频、文件等多种数据类型
- 获取意图框架推荐的联系人信息（可选）
- 加载自定义分享详情页UI界面
- 返回处理结果给分享面板
- 关闭分享详情页界面

### 绝不做
- 不主动拉起系统分享面板（由分享方应用调用）
- 不创建分享数据（由分享方应用创建）
- 不处理超出Share Kit支持范围的数据类型
- 不直接操作宿主应用窗口（通过session对象操作）

### 补充
- 仅适用于Stage模型应用
- 需在module.json5中注册ShareExtensionAbility
- 需配置支持的UTD（统一数据类型）
- 社交类应用可选集成意图框架联系人推荐
- API version要求：ShareExtensionAbility (API 10+)，systemShare (API 11+)

## 调用规范和规则

### 输入约束
- want参数必须包含系统分享面板传递的分享数据
- SharedRecord数据记录最大500条
- 数据总大小不超过IPC传输上限200KB
- 缩略图图片大小限制32KB以下
- 支持的UTD类型需在module.json5中穷举声明

### 执行约束
- 必须在onSessionCreate回调中处理分享数据
- 获取分享数据后需调用session.loadContent加载页面
- 异步API调用需使用Promise或async/await
- 错误处理需捕获BusinessError异常
- 处理完成后需调用session.terminateSelf关闭页面

### 内容约束
- 禁止修改want参数中的固有字段
- 禁止在onCreate中处理分享数据（应在onSessionCreate中处理）
- 禁止使用session操作超出分享范围的UI界面
- 禁止硬编码文件路径（需使用系统传递的uri）
- 禁止直接返回给分享方应用（需通过session.terminateSelfWithResult）

### 降级约束
- 数据解析失败：调用session.terminateSelf关闭页面并记录错误
- 联系人信息获取失败：跳过联系人处理，继续处理分享数据
- 页面加载失败：捕获异常并记录错误日志，调用terminateSelf关闭
- 权限不足：提示用户权限不足并关闭页面
- 数据类型不支持：返回错误码并关闭页面

## 调用流程和步骤

### 步骤1：准备阶段 - 导入模块

**前置校验**：
1. 确认使用Stage模型开发
2. 确认已在module.json5中注册ShareExtensionAbility
3. 确认已配置支持的UTD类型

**模块导入**：
```typescript
import { Want, ShareExtensionAbility, UIExtensionContentSession } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
```

### 步骤2：创建ShareExtensionAbility类

**实现要点**：
继承ShareExtensionAbility，实现onSessionCreate生命周期回调

**示例代码**：
```typescript
export default class TestShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        data.getRecords().forEach((record: systemShare.SharedRecord) => {
          if (record.utd === utd.UniformDataType.PLAIN_TEXT) {
            console.info('Received text:', record.content);
          } else if (record.utd === utd.UniformDataType.IMAGE) {
            console.info('Received image uri:', record.uri);
          }
        });
        session.loadContent('pages/Index');
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getSharedData. Code: ${error.code}, message: ${error.message}`);
        session.terminateSelf();
      });
  }
}
```

### 步骤3：可选 - 获取联系人推荐信息

**适用场景**：
社交类应用集成意图框架，获取推荐联系人信息

**示例代码**：
```typescript
export default class TestShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    systemShare.getContactInfo(want)
      .then(async (contact: systemShare.ContactInfo) => {
        console.info('Contact type:', contact.contactType);
        console.info('Contact ID:', contact.contactId);
        
        let data = await systemShare.getSharedData(want);
        data.getRecords().forEach((record: systemShare.SharedRecord) => {
          console.info('Share to contact:', contact.contactId);
        });
        
        session.loadContent('pages/Index');
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getContactInfo. Code: ${error.code}, message: ${error.message}`);
        session.terminateSelf();
      });
  }
}
```

### 步骤4：错误处理

**错误捕获机制**：
```typescript
export default class TestShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    try {
      systemShare.getSharedData(want)
        .then((data: systemShare.SharedData) => {
          if (!data || data.getRecords().length === 0) {
            console.warn('No share data received');
            session.terminateSelf();
            return;
          }
          
          data.getRecords().forEach((record: systemShare.SharedRecord) => {
            try {
              this.processShareRecord(record);
            } catch (processError) {
              console.error('Process record error:', processError);
            }
          });
          
          session.loadContent('pages/Index');
        })
        .catch((error: BusinessError) => {
          this.handleShareError(error, session);
        });
    } catch (exceptionError) {
      console.error('Exception in onSessionCreate:', exceptionError);
      session.terminateSelf();
    }
  }
  
  private processShareRecord(record: systemShare.SharedRecord): void {
    if (!record.utd) {
      throw new Error('Missing UTD type');
    }
    console.info('Processing record with UTD:', record.utd);
  }
  
  private handleShareError(error: BusinessError, session: UIExtensionContentSession): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error:', error.message);
        break;
      case 1003703001:
        console.error('Parse data failed:', error.message);
        break;
      default:
        console.error('Unknown error:', error.code, error.message);
    }
    session.terminateSelf();
  }
}
```

### 步骤5：配置module.json5

**配置要点**：
注册ShareExtensionAbility，声明支持的UTD类型

**配置示例**：
```json
{
  "module": {
    "extensionAbilities": [
      {
        "name": "TestShareAbility",
        "srcEntry": "./ets/abilities/TestShareAbility.ts",
        "type": "share",
        "description": "Share extension ability",
        "exported": true,
        "label": "$string:share_ability_label",
        "icon": "$media:icon",
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
                "utd": "general.image",
                "maxFileSupported": 10
              },
              {
                "scheme": "file",
                "utd": "general.video",
                "maxFileSupported": 5
              }
            ]
          }
        ]
      }
    ]
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，必填参数未指定或参数类型不正确 | 检查want参数是否包含分享数据，确认参数类型正确 |
| 1003703001 | 数据解析失败 | 确认分享数据格式正确，检查数据是否超过限制 |
| 1003700001 | 数据记录超过最大数量（500条） | 减少分享数据记录数量 |
| 1003702002 | IPC数据超限（200KB） | 减少分享数据总大小，压缩图片缩略图 |
| 16000050 | 内部错误 | 检查系统日志，确认ShareExtensionAbility注册正确 |
| 201 | 权限不足（设置隐私窗口模式） | 申请ohos.permission.PRIVACY_WINDOW权限 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AbilityKit": "API 10+",
    "@kit.ShareKit": "API 11+",
    "@kit.ArkData": "API 10+",
    "@kit.BasicServicesKit": "API 10+"
  }
}
```

### 环境要求
- HarmonyOS SDK: API 11+ (4.1.0)
- 开发模型: Stage模型
- DevEco Studio: 3.1+

### 常见编译问题

**问题1：ShareExtensionAbility导入失败**
```
Error: Cannot find module '@kit.AbilityKit'
```
**解决方法**：确认SDK版本API 10+，在build-profile.json5中配置正确的compileSdkVersion

**问题2：systemShare导入失败**
```
Error: Cannot find module '@kit.ShareKit'
```
**解决方法**：systemShare模块需要API 11+，确认SDK版本和compileSdkVersion配置

**问题3：UTD类型未定义**
```
Error: Property 'UniformDataType' does not exist
```
**解决方法**：导入uniformTypeDescriptor模块：`import { uniformTypeDescriptor as utd } from '@kit.ArkData';`

**问题4：module.json5配置错误**
```
Error: Extension ability type 'share' is not supported
```
**解决方法**：确认SDK版本API 10+，检查extensionAbilities配置格式

## 常见问题与解决方法

### Q1：如何判断分享数据的类型？
**原因**：SharedRecord包含utd字段标识数据类型
**解决方法**：
- 使用record.utd判断数据类型（如utd.UniformDataType.PLAIN_TEXT）
- 参考@ohos.data.uniformTypeDescriptor获取支持的UTD类型
- 根据utd类型选择相应的处理逻辑

### Q2：如何处理多个分享数据记录？
**原因**：SharedData可能包含多条SharedRecord
**解决方法**：
- 使用data.getRecords()获取所有记录数组
- 遍历数组处理每条记录
- 注意maxFileSupported配置限制文件数量

### Q3：如何返回处理结果给分享方？
**原因**：需要将处理结果返回给分享面板和分享方应用
**解决方法**：
- 使用session.terminateSelfWithResult返回结果
- 构造AbilityResult对象，包含resultCode和want数据
- resultCode用于标识处理状态（如成功、失败、取消等）

### Q4：如何集成意图框架联系人推荐？
**原因**：社交类应用需要快速分享到推荐联系人
**解决方法**：
- 在意图框架中捐献联系人数据
- 使用systemShare.getContactInfo获取联系人信息
- 根据contactType和contactId处理分享逻辑

### Q5：如何处理文件类型分享数据？
**原因**：文件类型需要访问文件uri
**解决方法**：
- 使用record.uri获取文件URI
- 通过文件API访问文件内容
- 注意权限配置和文件路径处理

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "abilityName": "TestShareAbility",
  "processedRecords": 3,
  "supportedTypes": ["general.text", "general.image", "general.video"],
  "apiUsed": [
    "ShareExtensionAbility",
    "systemShare.getSharedData",
    "systemShare.getContactInfo",
    "UIExtensionContentSession.loadContent",
    "UIExtensionContentSession.terminateSelf"
  ],
  "errorCode": 0,
  "errorMessage": ""
}
```

## 参考文档

- [API开发指南：分享详情页处理分享内容](references/share-sec-panel-guide.md)
- [API参考：ShareExtensionAbility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-shareextensionability)
- [API参考：UIExtensionAbility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiextensionability)
- [API参考：UIExtensionContentSession](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiextensioncontentsession)
- [API参考：systemShare](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [设计指南：分享详情页面](https://developer.huawei.com/consumer/cn/doc/design-guides/share-0000001957076313)
- [开发指南：意图框架](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-introduction)
- [配置文件：module.json5配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file)

## 完整示例代码

- [ArkTS示例：ShareExtensionAbility实现](assets/ShareExtensionAbilityExample.ets)
- [ArkTS示例：联系人推荐集成](assets/ContactShareExample.ets)
- [配置文件：module.json5示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [处理文本分享数据](tests/test_text_share.py)：验证文本类型分享数据解析和处理
- [处理图片分享数据](tests/test_image_share.py)：验证图片类型分享数据URI获取
- [处理联系人推荐](tests/test_contact_recommend.py)：验证意图框架联系人信息获取

### 边界测试用例
- [多条分享记录处理](tests/test_multiple_records.py)：验证最多500条记录处理
- [大文件分享处理](tests/test_large_file.py)：验证文件大小限制处理
- [混合数据类型](tests/test_mixed_types.py)：验证文本+图片+文件混合类型处理

### 异常测试用例
- [参数缺失测试](tests/test_missing_params.py)：验证want参数缺失时的错误处理
- [数据解析失败测试](tests/test_parse_failure.py)：验证数据格式错误的降级处理
- [权限不足测试](tests/test_permission_denied.py)：验证隐私窗口权限缺失处理