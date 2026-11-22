---
name: hmos-intents-kit-share-contact
description: 通过意图框架共享联系人信息到分享推荐区，支持Share Kit分享联系人数据，适用于系统推荐场景、社交分享场景
---

# 共享联系人信息到分享推荐区技能

## 功能描述

本技能实现通过意图框架服务（Intents Kit）将目标应用的联系人信息共享到系统分享推荐区。应用可以构造包含联系人昵称、头像、电话号码等信息的意图数据，通过调用`insightIntent.shareIntent()`接口共享给系统，系统将在合适的时机在系统入口推荐给用户。

**核心能力**：
- 构造联系人意图数据结构
- 共享联系人信息到系统推荐区
- 支持自定义联系人属性（昵称、头像、电话等）
- 支持意图标识符生成（UUID）

**适用场景**：
- 社交应用推荐联系人
- 通讯录应用分享联系人
- 即时通讯应用推荐好友
- 目标应用处理分享内容场景

**技术特点**：
- API版本：4.0.0(10)起支持
- 异步调用：支持Promise和Callback两种方式
- 系统能力：SystemCapability.AI.InsightIntent
- 元服务支持：5.0.0(12)起支持元服务

## 使用场景

### 触发词
- "共享联系人到推荐区"
- "分享联系人信息"
- "推荐联系人"
- "Share Kit联系人分享"
- "意图框架分享联系人"

### 能做
- 将联系人信息共享到系统分享推荐区
- 构造完整的联系人意图数据结构
- 生成唯一的意图标识符
- 设置联系人的基本信息（昵称、头像、电话等）
- 配置分享参数（bundleName、moduleName、abilityName）

### 绝不做
- 不处理非联系人类型的意图共享（如音乐、视频等）
- 不直接跳转到目标应用（需要用户点击推荐卡片）
- 不修改系统推荐算法或推荐策略
- 不处理联系人权限申请（需要应用自行申请）

### 补充
- 需要申请意图框架白名单才能使用
- 每个应用每天最多共享20次意图
- 每次共享数据量最多50KB
- 所有应用每天共享总次数上限为3000次
- 建议积攒一定量的数据后一次全部共享并控制共享次数

## 调用规范和规则

### 输入约束
- 联系人数据完整性：必须包含entityId、entityName、name等必要字段
- 标识符生成：必须使用UUID或时间戳生成唯一identifier
- 时间戳格式：executedStartTime和executedEndTime为毫秒级时间戳
- bundleName：必须与应用包名一致
- abilityName：必须与module.json5中配置的ability名称一致
- action：固定值'ohos.want.action.sendData'，不可修改

### 执行约束
- 最大共享次数：每个应用每天最多20次
- 单次数据量：最多50KB
- 总共享次数：所有应用每天最多3000次
- 调用模式：异步调用，支持Promise和Callback
- 网络要求：需要网络连接

### 内容约束
- 禁止共享虚假或无效的联系人信息
- 禁止频繁重复共享相同联系人
- 禁止使用硬编码的敏感信息
- 禁止在未获取权限的情况下共享联系人数据
- 必须使用合法的bundleName和abilityName

### 降级约束
- 网络失败：记录日志并提示用户检查网络连接
- 超过次数限制：缓存数据并延迟到第二天重试
- 数据量过大：分批共享或压缩数据
- 服务异常：捕获错误码并提示用户稍后重试
- 权限不足：引导用户申请必要权限

## 调用流程和步骤

### 步骤1：准备阶段

**前置条件**：
1. 已申请意图框架白名单（参见[Intents Kit接入流程](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-access-flow)）
2. 已配置应用的bundleName和abilityName
3. 已导入必要的模块
4. 已获取UIContext和Context

**参数准备**：
```typescript
import BuildProfile from 'BuildProfile';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { insightIntent } from '@kit.IntentsKit';
import common from '@kit.AbilityKit';

let uiContext: UIContext = this.getUIContext();
let context: Context = uiContext.getHostContext() as Context;
```

### 步骤2：构造联系人意图数据

**数据结构定义**：
```typescript
const intent: insightIntent.InsightIntent = {
  intentName: 'SendMessage', // 意图名称，根据实际业务定义
  intentVersion: '1.0', // 意图版本，当前为'1.0'
  identifier: util.generateRandomUUID(), // 意图标识符，使用UUID生成
  
  intentActionInfo: { // 意图执行信息
    actionMode: 'EXECUTED', // 动作模式：EXECUTED表示已执行
    executedTimeSlots: { // 实际发生时间段
      executedStartTime: new Date().getTime(),
      executedEndTime: new Date().getTime(),
    }
  },
  
  intentEntityInfo: { // 意图实体信息
    entityId: 'this-is-id', // 实体ID，联系人的唯一标识
    entityName: 'Contact', // 实体名称，固定为'Contact'
    name: 'Nickname', // 联系人昵称
    icon: 'data:image/png;base64,...', // 联系人头像（Base64编码）
    phoneNumbers: [], // 联系人电话号码数组
    
    extras: { // 扩展信息
      shareParams: {
        bundleName: BuildProfile.BUNDLE_NAME, // 应用包名
        moduleName: 'entry', // 应用模块名，根据实际填写
        abilityName: 'SampleContactAbility', // 应用ability名，根据实际填写
        action: 'ohos.want.action.sendData', // 标识分享，不可修改
      }
    }
  }
};
```

**参数说明**：
- `intentName`：意图名称，根据业务场景定义
- `intentVersion`：意图版本，当前为'1.0'
- `identifier`：意图标识符，使用`util.generateRandomUUID()`生成
- `actionMode`：动作模式，EXECUTED表示已执行，PREDICTED表示预测将执行
- `entityId`：实体ID，联系人的唯一标识符
- `entityName`：实体名称，联系人场景固定为'Contact'
- `name`：联系人昵称
- `icon`：联系人头像，Base64编码格式
- `phoneNumbers`：联系人电话号码数组
- `shareParams`：分享参数，包含bundleName、moduleName、abilityName、action

### 步骤3：调用API共享数据

**Promise方式**：
```typescript
async function shareContactIntent(context: common.BaseContext, intent: insightIntent.InsightIntent): Promise<void> {
  try {
    await insightIntent.shareIntent(context, [intent]);
    console.info('shareIntent succeed');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`shareIntent failed. Code: ${error.code}. message: ${error.message}`);
    throw error;
  }
}
```

**Callback方式**：
```typescript
function shareContactIntentCallback(context: common.BaseContext, intent: insightIntent.InsightIntent): void {
  insightIntent.shareIntent(context, [intent], (error) => {
    if (error?.code) {
      console.error(`shareIntent failed. Code: ${error.code}. message: ${error.message}`);
      return;
    }
    console.info('shareIntent succeed');
  });
}
```

### 步骤4：错误处理

**错误码处理**：
```typescript
try {
  await insightIntent.shareIntent(context, [intent]);
  console.info('shareIntent succeed');
} catch (err) {
  const error = err as BusinessError;
  
  switch (error.code) {
    case 401:
      console.error('参数校验失败，请检查参数格式');
      break;
    case 1000101101:
      console.error('应用未注册InsightIntent，请先申请白名单');
      break;
    case 1000101104:
      console.error('共享次数超过限制，每个应用每天最多20次');
      // 缓存数据，延迟到第二天重试
      cacheIntentData(intent);
      break;
    case 1000101105:
      console.error('单次共享数据量超过50KB限制');
      // 压缩或精简数据
      break;
    case 1000101106:
      console.error('所有应用共享总次数超过3000次上限');
      // 延迟重试
      break;
    case 1000101201:
      console.error('服务异常，请稍后重试');
      break;
    default:
      console.error(`未知错误: ${error.message}`);
  }
}
```

### 步骤5：降级处理

**缓存机制**：
```typescript
import preferences from '@ohos.data.preferences';

async function cacheIntentData(intent: insightIntent.InsightIntent): Promise<void> {
  try {
    // 获取Preferences实例
    const preferencesInstance = await preferences.getPreferences(context, 'intent_cache');
    
    // 缓存意图数据
    const cacheKey = `intent_${Date.now()}`;
    await preferencesInstance.put(cacheKey, JSON.stringify(intent));
    
    // 异步保存到磁盘
    await preferencesInstance.flush();
    console.info('Intent data cached successfully');
  } catch (error) {
    console.error('Failed to cache intent data:', error);
  }
}

async function retryCachedIntents(): Promise<void> {
  try {
    const preferencesInstance = await preferences.getPreferences(context, 'intent_cache');
    // 获取所有缓存的意图数据并重试
    const allKeys = await preferencesInstance.getAll();
    // ... 重试逻辑
  } catch (error) {
    console.error('Failed to retry cached intents:', error);
  }
}
```

**延迟重试**：
```typescript
async function delayedRetry(intent: insightIntent.InsightIntent, delayMs: number): Promise<void> {
  setTimeout(async () => {
    try {
      await insightIntent.shareIntent(context, [intent]);
      console.info('Delayed retry succeeded');
    } catch (error) {
      console.error('Delayed retry failed:', error);
    }
  }, delayMs);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数校验失败 | 检查参数格式、类型是否正确，确保必填字段都已填写 |
| 1000101101 | 应用未注册InsightIntent | 申请意图框架白名单，参见[Intents Kit接入流程](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-access-flow) |
| 1000101104 | 共享次数超过限制 | 缓存数据延迟到第二天重试，或优化共享策略减少共享次数 |
| 1000101105 | 单次共享数据量超过限制 | 压缩数据或精简不必要字段，确保单次数据量小于50KB |
| 1000101106 | 所有应用共享总次数超过上限 | 延迟重试或调整共享时间避开高峰期 |
| 1000101201 | 服务异常 | 检查网络连接，稍后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "module": {
    "dependencies": {
      "@kit.IntentsKit": "latest",
      "@kit.ArkTS": "latest",
      "@kit.BasicServicesKit": "latest"
    }
  }
}
```

### 环境要求
- HarmonyOS SDK版本：4.0.0(10)及以上
- DevEco Studio版本：3.1及以上
- ArkTS语言支持：ES2015+

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.IntentsKit' or its corresponding type declarations.
```
**解决方法**：
- 检查HarmonyOS SDK版本是否为4.0.0(10)及以上
- 在`build-profile.json5`中配置正确的SDK版本
- 清理项目并重新编译：`Build > Clean Project`

**问题2：BuildProfile未定义**
```
Error: Cannot find name 'BuildProfile'.
```
**解决方法**：
- 确保在模块的`build-profile.json5`中配置了正确的bundleName
- 导入BuildProfile：`import BuildProfile from 'BuildProfile';`
- 重新编译项目

**问题3：util.generateRandomUUID未定义**
```
Error: Property 'generateRandomUUID' does not exist on type 'typeof util'.
```
**解决方法**：
- 检查@kit.ArkTS版本
- 使用替代方案：`util.generateRandomUUID(true)`或手动生成UUID

**问题4：权限不足**
```
Error: Permission denied: Need permission ohos.permission.INTERNET
```
**解决方法**：
- 在`module.json5`中添加网络权限：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

## 常见问题与解决方法

### Q1：如何申请意图框架白名单？
**原因**：意图框架服务需要白名单权限才能使用
**解决方法**：
- 参见[Intents Kit接入流程](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-access-flow)申请白名单
- 联系华为开发者联盟提交申请
- 提供应用包名、应用ID等必要信息

### Q2：共享次数超过限制怎么办？
**原因**：每个应用每天最多共享20次，所有应用每天最多共享3000次
**解决方法**：
- 优化共享策略，积攒数据后一次性共享
- 实现本地缓存机制，延迟到第二天重试
- 检查是否有重复共享的情况

### Q3：单次数据量超过50KB如何处理？
**原因**：每次共享的数据量限制为50KB
**解决方法**：
- 压缩联系人数据，移除不必要字段
- 分批共享，将大数据拆分为多个小数据包
- 使用Base64编码优化图片数据

### Q4：共享后为什么看不到推荐？
**原因**：系统推荐受多种因素影响，包括用户习惯、时间段、推荐策略等
**解决方法**：
- 检查共享数据是否正确（日志输出）
- 确认intentActionInfo和intentEntityInfo字段完整
- 参见[习惯推荐-接入方案](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-habit-rec-access-programme)了解推荐机制
- 等待系统学习用户习惯

### Q5：如何获取UIContext和Context？
**原因**：调用shareIntent需要Context参数
**解决方法**：
- 在UIAbility中获取：
```typescript
let uiContext: UIContext = this.getUIContext();
let context: Context = uiContext.getHostContext() as Context;
```
- 或从AppStorage获取：
```typescript
let context = AppStorage.get<common.UIAbilityContext>("Context") as common.UIAbilityContext;
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "intentName": "SendMessage",
  "identifier": "uuid-generated-string",
  "sharedAt": "2026-07-02T12:00:00.000Z",
  "apiUsed": [
    "insightIntent.shareIntent()",
    "util.generateRandomUUID()"
  ],
  "message": "联系人信息已成功共享到推荐区"
}
```

## 参考文档

- [API开发指南：共享联系人信息到分享推荐区](references/share-intents-share.md)
- [API参考说明：insightIntent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/intents-arkts-api-insightintent)
- [Intents Kit接入流程](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-access-flow)
- [习惯推荐-接入方案](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-habit-rec-access-programme)

## 完整示例代码

- [ArkTS示例：共享联系人到推荐区](assets/share_contact_example.ets)

## 测试用例

### 正向测试用例
- [测试正常共享联系人信息](tests/test_positive.ts)：验证完整的联系人信息共享流程

### 边界测试用例
- [测试最大数据量限制](tests/test_boundary.ts)：验证50KB数据量限制

### 异常测试用例
- [测试参数校验失败](tests/test_exception.ts)：验证必填字段缺失、格式错误等异常场景
- [测试次数超限](tests/test_exception.ts)：验证共享次数超过限制的错误处理