---
name: hmos-form-kit-open-formmanager
description: 在应用内拉起卡片管理页面添加卡片到桌面+支持指定卡片信息+API version 18+适用于应用内快速加桌场景
---

# 应用内拉起卡片管理加桌技能

## 功能描述

在应用内调用openFormManager接口拉起卡片管理页面,用户可在卡片管理页面点击"添加至桌面"按钮将ArkTS卡片添加到桌面。从API version 18开始,Form Kit提供在应用内将ArkTS卡片添加到桌面的能力,方便用户后续便捷查看信息或快速进入应用。

## 使用场景

### 触发词
- "应用内添加卡片到桌面"
- "拉起卡片管理页面"
- "在应用内请求卡片加桌"
- "openFormManager"
- "卡片加桌"

### 能做
- 在应用内拉起卡片管理页面
- 指定要添加的卡片信息(卡片名称、尺寸、模块名)
- 用户可选择添加卡片到桌面或负一屏
- 支持ArkTS卡片快速加桌体验

### 绝不做
- 不直接添加卡片到桌面(需要用户在管理页面手动点击)
- 不用于卡片信息查询
- 不用于卡片更新或删除操作
- 不支持跨应用添加卡片

### 补充
- 需要先创建ArkTS卡片才能使用此功能
- 卡片信息必须与form_config.json配置一致
- parameters参数不完整时会展示默认卡片

## 调用规范和规则

### 输入约束
- bundleName: 必填,卡片所属应用的包名
- abilityName: 必填,卡片所属的ability名称
- parameters.form_dimension: 可选,卡片尺寸(1/2/3/4)
- parameters.form_name: 可选,卡片名称
- parameters.module_name: 可选,卡片所属的模块名称

### 执行约束
- 最大耗时: 无限制(等待用户操作)
- 最大迭代次数: 1次
- API调用频次: 无限制

### 内容约束
- 禁止生成: 自动添加卡片的代码
- 禁止使用高危函数: 无
- 禁止操作: 修改卡片配置文件

### 降级约束
- 网络失败: 提示用户检查网络连接
- 参数错误: 展示默认卡片
- 卡片不存在: 提示用户先创建卡片

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 确认已创建ArkTS卡片
2. 确认卡片信息与form_config.json配置一致
3. 确认API version >= 18

**参数准备**:
```typescript
const want: Want = {
  bundleName: "com.samples.formmanagerdemo",
  abilityName: 'EntryFormAbility',
  parameters: {
    'ohos.extra.param.key.form_dimension': 2,
    'ohos.extra.param.key.form_name': 'widget',
    'ohos.extra.param.key.module_name': 'entry'
  },
};
```

### 步骤2: 调用API

**示例代码**:
```typescript
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  build() {
    Row() {
      Column() {
        Button($r('app.string.open_form_manager_button'))
          .onClick(() => {
            const want: Want = {
              bundleName: "com.samples.formmanagerdemo",
              abilityName: 'EntryFormAbility',
              parameters: {
                'ohos.extra.param.key.form_dimension': 2,
                'ohos.extra.param.key.form_name': 'widget',
                'ohos.extra.param.key.module_name': 'entry'
              },
            };
            try {
              formProvider.openFormManager(want);
            } catch (error) {
              promptAction.openToast({ message: (error as BusinessError).message });
              hilog.info(DOMAIN, 'testTag', 'catch error ', 'code:', (error as BusinessError).code, 'message:',
                (error as BusinessError).message);
            }
          })
          .margin({ top: 10, bottom: 10 })
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

**资源文件**:
```json
{
  "string": [
    {
      "name": "open_form_manager_button",
      "value": "添加应用卡片到桌面"
    }
  ]
}
```

### 步骤3: 错误处理

```typescript
try {
  formProvider.openFormManager(want);
} catch (error) {
  const businessError = error as BusinessError;
  switch (businessError.code) {
    case 16500050:
      console.error('IPC connection error');
      break;
    case 16500100:
      console.error('Failed to obtain the configuration information');
      break;
    case 16501000:
      console.error('An internal functional error occurred');
      break;
    default:
      console.error('Unknown error:', businessError.message);
  }
}
```

### 步骤4: 降级处理

```typescript
async function openFormManagerWithFallback(want: Want): Promise<void> {
  try {
    formProvider.openFormManager(want);
  } catch (error) {
    const businessError = error as BusinessError;
    if (businessError.code === 16500100) {
      promptAction.openToast({ 
        message: '配置信息获取失败,请检查卡片配置' 
      });
    } else {
      promptAction.openToast({ 
        message: '拉起卡片管理页面失败,请稍后重试' 
      });
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 16500050 | IPC connection error | 确认入参是否过长,检查IPC通信 |
| 16500100 | Failed to obtain the configuration information | 确认并验证卡片配置信息正确性 |
| 16501000 | An internal functional error occurred | 待系统重启后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "^18.0.0",
    "@kit.AbilityKit": "^18.0.0",
    "@kit.BasicServicesKit": "^18.0.0",
    "@kit.ArkUI": "^18.0.0",
    "@kit.PerformanceAnalysisKit": "^18.0.0"
  }
}
```

### 环境要求
- HarmonyOS API: >= version 18
- DevEco Studio: >= 4.0

### 常见编译问题

**问题1: API version不满足**
```
Error: API 'openFormManager' is not supported in API version < 18
```
**解决方法**: 在build-profile.json5中设置API version >= 18

**问题2: Want参数缺失**
```
Error: Mandatory parameters are left unspecified
```
**解决方法**: 确认Want参数包含bundleName和abilityName

## 常见问题与解决方法

### Q1: 点击按钮没有拉起卡片管理页面
**原因**: Want参数配置错误或卡片不存在
**解决方法**:
- 检查bundleName、abilityName是否正确
- 确认卡片已在form_config.json中配置
- 验证卡片信息与配置文件一致

### Q2: 拉起页面后显示的是默认卡片
**原因**: parameters参数不完整
**解决方法**:
- 补充完整的parameters参数
- 确认form_dimension、form_name、module_name正确

### Q3: 错误码16500100
**原因**: 卡片配置信息字段缺失或非法
**解决方法**:
- 检查form_config.json配置文件
- 验证所有必填字段是否配置正确

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "action": "拉起卡片管理页面",
  "cardInfo": {
    "bundleName": "com.samples.formmanagerdemo",
    "abilityName": "EntryFormAbility",
    "formName": "widget",
    "formDimension": 2,
    "moduleName": "entry"
  },
  "apiUsed": [
    "formProvider.openFormManager"
  ]
}
```

## 参考文档

- [应用内拉起卡片管理加桌开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-open-formmanager)
- [openFormManager API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [创建ArkTS卡片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-creation)
- [Want接口定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want)
- [卡片错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-form)

## 完整示例代码

- [ArkTS示例代码](assets/open_formmanager_example.ets)
- [配置文件示例](assets/form_config_example.json)
- [资源文件示例](assets/string.json)

## 测试用例

### 正向测试用例
- [正常拉起卡片管理页面](tests/test_positive.ets): 使用完整正确的参数
- [添加不同尺寸卡片](tests/test_positive.ets): 测试不同的form_dimension值

### 边界测试用例
- [最小参数测试](tests/test_boundary.ets): 只传入必填参数
- [默认卡片测试](tests/test_boundary.ets): parameters参数不完整

### 异常测试用例
- [参数错误测试](tests/test_exception.ets): bundleName或abilityName错误
- [卡片不存在测试](tests/test_exception.ets): 指定的卡片未创建
- [错误码测试](tests/test_exception.ets): 测试各类错误码场景