---
name: hmos-form-kit-passive-refresh
description: 实现ArkTS卡片被动刷新,支持定时/定点/条件三种刷新方式,每日配额50次,适用于卡片内容自动更新场景
---

# ArkTS卡片被动刷新技能

## 功能描述

本技能实现ArkTS卡片被动刷新功能,支持三种刷新方式:
- **定时刷新**: 按固定时间间隔自动刷新卡片内容,通过updateDuration配置
- **定点刷新**: 在指定时间点自动刷新卡片内容,通过scheduledUpdateTime/multiScheduledUpdateTime配置
- **条件刷新**: 根据特定条件(如网络变化)触发刷新,通过conditionUpdate配置

刷新流程触发后,系统会调用FormExtensionAbility的onUpdateForm生命周期回调,在回调中使用formProvider.updateForm接口更新卡片数据。

## 使用场景

### 触发词
- "卡片定时刷新"
- "卡片定点刷新"
- "卡片条件刷新"
- "卡片被动刷新"
- "设置卡片刷新时间"
- "网络刷新卡片"

### 能做
- 配置卡片定时刷新(周期性刷新)
- 配置卡片定点刷新(固定时间点刷新)
- 配置卡片多定点刷新(多个时间点刷新)
- 配置卡片网络条件刷新
- 设置卡片下次刷新时间(最少5分钟)
- 在onUpdateForm回调中更新卡片内容
- 处理刷新配额限制(每日50次)

### 绝不做
- 不实现主动刷新(用户手动触发刷新)
- 不处理卡片代理刷新相关逻辑
- 不处理超过配额限制的刷新请求
- 不修改卡片其他配置(如尺寸、样式等)

### 补充
- 定时刷新配额:每张卡片每天最多50次
- 刷新次数在每天0点重置
- 定时刷新第一次会有最多30分钟偏差
- 定点刷新优先级低于定时刷新
- 条件刷新从API version 26.0.0开始生效
- 卡片不可见时刷新仅记录动作和数据,待可见时统一刷新

## 调用规范和规则

### 输入约束
- formId: 必须是有效的卡片ID,字符串格式
- 刷新时间: 定时刷新updateDuration单位为30分钟,定点刷新scheduledUpdateTime格式为HH:MM
- 刷新间隔: setFormNextRefreshTime最短5分钟
- 多定点刷新: multiScheduledUpdateTime最多24个时间点
- 配置文件: form_config.json必须符合JSON格式规范

### 执行约束
- 最大刷新频次: 每张卡片每日50次(定时刷新)
- 刷新时机: 卡片可见时触发刷新,不可见时仅记录
- 定时刷新偏差: 第一次刷新最多30分钟偏差
- API调用频次: 无限制,但受配额限制
- 执行模式: 异步回调(Promise或AsyncCallback)

### 内容约束
- 禁止使用高危函数: eval、exec等
- 禁止硬编码敏感信息: API密钥、密码等
- 禁止无限循环刷新: 必须遵守配额限制
- 刷新数据大小: API version 20+总大小不超过10MB,图片不超过20张
- 图片限制: API version 19及之前每张限制2MB,最多5张

### 降级约束
- 达到配额限制: 提示用户配额已用完,等待次日重置
- 网络失败: 保留上次刷新数据,等待下次刷新机会
- formId不存在: 记录错误日志,不执行刷新
- 配置文件错误: 使用默认配置或提示用户修正
- onUpdateForm未实现: 提示开发者必须实现该回调

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查卡片配置文件form_config.json是否存在
2. 验证updateEnabled字段是否为true(启用刷新)
3. 检查刷新配置(updateDuration/scheduledUpdateTime/conditionUpdate)是否正确
4. 确认FormExtensionAbility已正确继承并实现onUpdateForm回调
5. 验证formId是否有效且存在

**参数准备**:
```typescript
// ArkTS示例
import { formBindingData, FormExtensionAbility, formProvider, formInfo } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';

const TAG: string = 'PassiveRefreshFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;
const FIVE_MINUTE: number = 5; // 最短刷新间隔

export default class PassiveRefreshFormAbility extends FormExtensionAbility {
  // 卡片创建时的初始化
  onAddForm(want: Want): formBindingData.FormBindingData {
    let formData: Record<string, Object | string> = {
      'title': '初始标题',
      'content': '初始内容'
    };
    return formBindingData.createFormBindingData(formData);
  }

  // 卡片更新回调(核心刷新逻辑)
  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onUpdateForm triggered, formId: ${formId}`);
    // 步骤2将在此实现具体更新逻辑
  }
}
```

### 步骤2: 配置刷新方式

**方式A: 定时刷新配置**

在form_config.json中配置定时刷新:
```json
{
  "forms": [
    {
      "name": "TimedRefreshCard",
      "description": "$string:widget_desc",
      "src": "./ets/pages/WidgetCard.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "isDefault": true,
      "updateEnabled": true,  // 必须设置为true
      "updateDuration": 2,    // 刷新周期: 2*30分钟 = 1小时
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2"]
    }
  ]
}
```

**方式B: 定点刷新配置**

在form_config.json中配置定点刷新:
```json
{
  "forms": [
    {
      "name": "ScheduledRefreshCard",
      "description": "$string:widget_desc",
      "src": "./ets/pages/WidgetCard.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "isDefault": true,
      "updateEnabled": true,  // 必须设置为true
      "scheduledUpdateTime": "10:30",  // 单定点刷新
      "multiScheduledUpdateTime": "11:30,16:30",  // 多定点刷新(可选)
      "updateDuration": 0,  // 必须为0,否则定点刷新不生效
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2"]
    }
  ]
}
```

**方式C: 条件刷新配置**

在form_config.json中配置网络条件刷新:
```json
{
  "forms": [
    {
      "name": "ConditionRefreshCard",
      "description": "$string:widget_desc",
      "src": "./ets/pages/WidgetCard.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "isDefault": true,
      "updateEnabled": true,
      "conditionUpdate": ["network"],  // 网络刷新(API version 26.0.0+)
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2"]
    }
  ]
}
```

**方式D: 动态设置下次刷新时间**

通过API动态设置下次刷新时间:
```typescript
// 在onFormEvent或其他事件回调中设置下次刷新
onFormEvent(formId: string, message: string): void {
  hilog.info(DOMAIN_NUMBER, TAG, `onFormEvent: formId=${formId}, message=${message}`);
  
  try {
    // 设置5分钟后刷新
    formProvider.setFormNextRefreshTime(formId, FIVE_MINUTE, (err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN_NUMBER, TAG, 
          `setFormNextRefreshTime failed: code=${err.code}, message=${err.message}`);
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'setFormNextRefreshTime succeeded');
    });
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, 
      `setFormNextRefreshTime exception: ${(err as BusinessError).code}, ${(err as BusinessError).message}`);
  }
}
```

### 步骤3: 实现onUpdateForm回调

**核心更新逻辑**:
```typescript
onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
  hilog.info(DOMAIN_NUMBER, TAG, `onUpdateForm: formId=${formId}, wantParams=${JSON.stringify(wantParams)}`);
  
  try {
    // 1. 获取最新数据(示例:模拟获取数据)
    let latestData: Record<string, string> = {
      'title': '更新标题',
      'content': '更新内容',
      'updateTime': new Date().toLocaleTimeString()
    };
    
    // 2. 创建FormBindingData对象
    let formBindingDataObj: formBindingData.FormBindingData = 
      formBindingData.createFormBindingData(latestData);
    
    // 3. 调用updateForm更新卡片
    formProvider.updateForm(formId, formBindingDataObj).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'updateForm succeeded');
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `updateForm failed: code=${error.code}, message=${error.message}`);
      // 步骤4将在此实现错误处理
    });
    
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, 
      `onUpdateForm exception: ${(err as BusinessError).code}, ${(err as BusinessError).message}`);
  }
}
```

### 步骤4: 错误处理

**完整错误处理代码**:
```typescript
import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class PassiveRefreshFormAbility extends FormExtensionAbility {
  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    const TAG = 'PassiveRefreshFormAbility';
    const DOMAIN_NUMBER = 0xFF00;
    
    try {
      // 参数校验
      if (!formId || formId.trim().length === 0) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Invalid formId');
        return;
      }
      
      // 获取数据并更新
      let formData: Record<string, string> = {
        'title': '卡片标题',
        'content': '卡片内容'
      };
      
      let bindingData = formBindingData.createFormBindingData(formData);
      
      formProvider.updateForm(formId, bindingData, (error: BusinessError) => {
        if (error) {
          this.handleUpdateError(error, formId);
          return;
        }
        hilog.info(DOMAIN_NUMBER, TAG, `Form ${formId} updated successfully`);
      });
      
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN_NUMBER, TAG, 
        `onUpdateForm exception: code=${error.code}, message=${error.message}`);
      this.handleUpdateError(error, formId);
    }
  }
  
  // 错误处理函数
  private handleUpdateError(error: BusinessError, formId: string): void {
    switch (error.code) {
      case 16500050:  // IPC连接错误
        hilog.error(0xFF00, TAG, `IPC connection error for form ${formId}`);
        // 降级处理:记录错误,等待下次刷新
        break;
        
      case 16500060:  // 服务连接错误
        hilog.error(0xFF00, TAG, `Service connection error for form ${formId}`);
        // 降级处理:提示系统服务异常
        break;
        
      case 16501001:  // 卡片ID不存在
        hilog.error(0xFF00, TAG, `Form ${formId} does not exist`);
        // 降级处理:停止对该卡片的刷新
        break;
        
      case 16501002:  // 卡片数量超过上限
        hilog.error(0xFF00, TAG, `Too many forms, exceeded limit`);
        // 降级处理:提示用户清理卡片
        break;
        
      case 16501003:  // 当前应用无法操作此卡片
        hilog.error(0xFF00, TAG, `Cannot operate form ${formId} by current app`);
        // 降级处理:检查卡片归属权限
        break;
        
      case 401:  // 参数错误
        hilog.error(0xFF00, TAG, `Parameter error: ${error.message}`);
        // 降级处理:修正参数后重试
        break;
        
      default:
        hilog.error(0xFF00, TAG, 
          `Unknown error: code=${error.code}, message=${error.message}`);
        // 降级处理:记录错误日志
        break;
    }
  }
}
```

### 步骤5: 降级处理

**降级方案实现**:
```typescript
export default class PassiveRefreshFormAbility extends FormExtensionAbility {
  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    const TAG = 'PassiveRefreshFormAbility';
    const DOMAIN_NUMBER = 0xFF00;
    
    // 主流程:尝试更新卡片
    this.updateCardWithRetry(formId, 3);  // 最大重试3次
  }
  
  // 带重试机制的更新
  private updateCardWithRetry(formId: string, maxRetries: number): void {
    let retryCount = 0;
    
    const attemptUpdate = () => {
      try {
        let formData: Record<string, string> = {
          'title': '卡片标题',
          'content': '卡片内容',
          'retryCount': retryCount.toString()
        };
        
        let bindingData = formBindingData.createFormBindingData(formData);
        
        formProvider.updateForm(formId, bindingData).then(() => {
          hilog.info(0xFF00, TAG, `Form updated successfully on attempt ${retryCount}`);
        }).catch((error: BusinessError) => {
          retryCount++;
          
          if (retryCount < maxRetries) {
            hilog.warn(0xFF00, TAG, 
              `Update failed (attempt ${retryCount}), retrying...`);
            // 延迟1秒后重试
            setTimeout(attemptUpdate, 1000);
          } else {
            hilog.error(0xFF00, TAG, 
              `Update failed after ${maxRetries} attempts`);
            // 最终降级方案:使用缓存数据
            this.useFallbackData(formId);
          }
        });
        
      } catch (err) {
        retryCount++;
        if (retryCount < maxRetries) {
          setTimeout(attemptUpdate, 1000);
        } else {
          this.useFallbackData(formId);
        }
      }
    };
    
    attemptUpdate();
  }
  
  // 最终降级方案:使用缓存数据
  private useFallbackData(formId: string): void {
    hilog.warn(0xFF00, TAG, `Using fallback data for form ${formId}`);
    
    try {
      // 使用简单缓存数据
      let fallbackData: Record<string, string> = {
        'title': '缓存标题',
        'content': '数据暂时不可用',
        'error': 'true'
      };
      
      let bindingData = formBindingData.createFormBindingData(fallbackData);
      formProvider.updateForm(formId, bindingData);
      
    } catch (err) {
      hilog.error(0xFF00, TAG, 
        `Fallback update also failed: ${(err as BusinessError).message}`);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因:必填参数未指定、参数类型错误、参数验证失败 | 检查参数类型和取值范围,确保formId有效、刷新时间符合规范 |
| 16500050 | IPC连接错误 | 检查IPC连接状态,稍后重试或重启应用 |
| 16500060 | 服务连接错误 | 检查FormKit服务状态,重启设备或重新安装应用 |
| 16500100 | 无法获取配置信息 | 检查form_config.json配置文件格式和路径 |
| 16501000 | 内部功能错误 | 记录错误日志,联系技术支持 |
| 16501001 | 操作的卡片ID不存在 | 检查卡片是否已被删除,停止对该卡片刷新 |
| 16501002 | 卡片数量超过上限 | 提示用户清理卡片,最多支持16张卡片配置 |
| 16501003 | 当前应用无法操作此卡片 | 检查卡片归属权限,仅能操作本应用卡片 |
| 配额耗尽 | 每日定时刷新次数超过50次 | 等待次日0点配额重置,或使用定点刷新/条件刷新 |

## 编译和修复问题

### 依赖声明

**oh-package.json5依赖配置**:
```json
{
  "dependencies": {
    "@kit.FormKit": "^1.0.0",
    "@kit.AbilityKit": "^1.0.0",
    "@kit.PerformanceAnalysisKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

**module.json5配置**:
```json
{
  "module": {
    "extensionAbilities": [
      {
        "name": "PassiveRefreshFormAbility",
        "srcEntry": "./ets/passiverefreshformability/PassiveRefreshFormAbility.ets",
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

### 环境要求
- HarmonyOS API: API version 9+ (基础功能), API version 18+ (多定点刷新), API version 26.0.0+ (条件刷新)
- DevEco Studio: 3.1+
- ArkTS语法: Stage模型
- 设备类型: Phone、Tablet、Wearable等

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.FormKit'
```
**解决方法**: 
- 检查oh-package.json5中依赖配置
- 运行`ohpm install`安装依赖
- 确认HarmonyOS SDK版本支持FormKit

**问题2: onUpdateForm未触发**
```
Warning: onUpdateForm callback not implemented
```
**解决方法**:
- 确保FormExtensionAbility已继承并实现onUpdateForm
- 检查form_config.json中updateEnabled字段是否为true
- 验证刷新配置(updateDuration/scheduledUpdateTime)是否正确

**问题3: 刷新配额超限**
```
Error: Refresh quota exceeded for form
```
**解决方法**:
- 检查每日刷新次数是否超过50次
- 等待次日0点配额重置
- 使用定点刷新或条件刷新替代

**问题4: 配置文件格式错误**
```
Error: Invalid form_config.json format
```
**解决方法**:
- 检查JSON格式是否符合规范(字段类型、必填项)
- 验证updateDuration数值范围(自然数)
- 验证scheduledUpdateTime时间格式(HH:MM)

## 常见问题与解决方法

### Q1: 定时刷新不生效怎么办?
**原因**: 
- updateEnabled未设置为true
- updateDuration配置为0
- onUpdateForm回调未实现

**解决方法**:
- 在form_config.json中设置`updateEnabled: true`
- 配置`updateDuration: 1`或更大的值(单位为30分钟)
- 在FormExtensionAbility中实现onUpdateForm回调并调用updateForm

### Q2: 定点刷新不触发怎么办?
**原因**:
- updateDuration优先级高于scheduledUpdateTime
- updateDuration未设置为0
- 时间格式不正确

**解决方法**:
- 将`updateDuration: 0`以启用定点刷新
- 确保scheduledUpdateTime格式为HH:MM(如"10:30")
- 多定点刷新使用multiScheduledUpdateTime,多个时间用逗号分隔

### Q3: setFormNextRefreshTime调用失败怎么办?
**原因**:
- 刷新间隔小于5分钟
- formId无效
- 配额已耗尽

**解决方法**:
- 确保minute参数>=5(最小刷新间隔5分钟)
- 验证formId是否有效(卡片是否已创建)
- 检查当日刷新次数是否超过50次

### Q4: 网络条件刷新不生效怎么办?
**原因**:
- API版本低于26.0.0
- conditionUpdate未配置为["network"]
- 网络状态判定延迟

**解决方法**:
- 确认设备API版本>=26.0.0
- 在form_config.json中配置`conditionUpdate: ["network"]`
- 网络需连续断开10分钟后才判定为无网,下次联网才触发刷新

### Q5: 卡片不可见时刷新数据丢失怎么办?
**原因**:
- 卡片不可见时仅记录刷新动作和数据
- 待可见时才统一刷新布局

**解决方法**:
- 这是系统正常行为,无需特殊处理
- 确保onUpdateForm中正确保存刷新数据
- 卡片可见时系统会自动应用最新数据

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "formId": "卡片ID",
  "refreshType": "定时刷新/定点刷新/条件刷新/下次刷新",
  "refreshTime": "刷新时间或间隔",
  "updateResult": "更新成功/更新失败",
  "apiUsed": [
    "FormExtensionAbility.onUpdateForm",
    "formProvider.updateForm",
    "formProvider.setFormNextRefreshTime",
    "formBindingData.createFormBindingData"
  ],
  "quotaUsage": {
    "dailyLimit": 50,
    "usedCount": "已使用次数",
    "remaining": "剩余次数"
  },
  "errors": []
}
```

## 参考文档

- [API开发指南](references/arkts-ui-widget-passive-refresh.md)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [formProvider API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [卡片配置文件说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)
- [卡片生命周期管理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-lifecycle)
- [被动刷新概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-interaction-overview)

## 完整示例代码

- [ArkTS定时刷新示例](assets/timed_refresh_example.ets)
- [ArkTS定点刷新示例](assets/scheduled_refresh_example.ets)
- [ArkTS条件刷新示例](assets/condition_refresh_example.ets)
- [ArkTS完整FormExtensionAbility示例](assets/passive_refresh_ability.ets)
- [form_config.json配置示例](assets/form_config_examples.json)

## 测试用例

### 正向测试用例
- [test_timed_refresh_success](tests/test_timed_refresh.py): 测试定时刷新正常触发和更新
- [test_scheduled_refresh_success](tests/test_scheduled_refresh.py): 测试定点刷新正常触发和更新
- [test_multi_scheduled_refresh](tests/test_multi_scheduled.py): 测试多定点刷新多个时间点触发
- [test_next_refresh_time](tests/test_next_refresh.py): 测试setFormNextRefreshTime设置下次刷新
- [test_condition_network_refresh](tests/test_network_refresh.py): 测试网络条件刷新触发

### 边界测试用例
- [test_quota_limit](tests/test_quota_limit.py): 测试刷新配额达到50次上限
- [test_min_refresh_interval](tests/test_min_interval.py): 测试最小刷新间隔5分钟边界
- [test_max_multi_scheduled_times](tests/test_max_multi_scheduled.py): 测试多定点刷新最多24个时间点
- [test_update_duration_range](tests/test_update_duration.py): 测试updateDuration取值范围(自然数)
- [test_scheduled_update_time_format](tests/test_time_format.py): 测试定点刷新时间格式(HH:MM)

### 异常测试用例
- [test_invalid_formId](tests/test_invalid_formid.py): 测试无效卡片ID导致刷新失败
- [test_missing_onUpdateForm](tests/test_missing_callback.py): 测试未实现onUpdateForm回调
- [test_update_disabled](tests/test_update_disabled.py): 测试updateEnabled为false时刷新不触发
- [test_ipc_error](tests/test_ipc_error.py): 测试IPC连接错误处理
- [test_quota_exceeded](tests/test_quota_exceeded.py): 测试配额耗尽后的降级处理