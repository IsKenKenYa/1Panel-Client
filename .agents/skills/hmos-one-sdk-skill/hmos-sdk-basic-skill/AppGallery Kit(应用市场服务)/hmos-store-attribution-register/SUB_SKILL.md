---
name: hmos-store-attribution-register
description: 登记归因来源及转化事件，支持曝光/点击归因来源登记和转化事件登记，API版本≥5.0.0(12)，适用于媒体/分发平台登记广告归因、开发者登记转化事件场景
---

# 登记归因来源及转化技能

## 功能描述

本技能提供应用归因服务的登记功能，包括登记归因来源和登记转化事件两个核心能力。媒体/分发平台通过登记归因来源接口记录广告曝光/点击事件，开发者应用通过登记转化接口记录用户转化行为，系统自动在端侧完成归因计算。

**核心能力**：
- 登记归因来源：媒体/分发平台登记广告曝光或点击事件
- 登记转化事件：开发者应用登记用户转化行为
- 端侧归因计算：系统自动根据归因来源和转化事件进行归因计算

**技术特点**：
- 不依赖用户标识符的端侧归因能力
- 支持签名验证确保数据安全
- 支持多个归因监测平台
- 支持自定义业务场景和转化事件

**API版本要求**：API 5.0.0(12)及以上
**新增特性**：API 6.0.2(22)支持timestamp和serviceTag参数

## 使用场景

### 触发词
- "登记归因来源"
- "登记转化事件"
- "应用归因"
- "广告归因"
- "登记曝光事件"
- "登记点击事件"
- "Store Attribution"
- "attributionManager"

### 能做
- 为媒体/分发平台提供登记归因来源（曝光/点击）的能力
- 为开发者应用提供登记转化事件的能力
- 支持多个归因监测平台的归因结果回传
- 支持自定义业务场景和转化事件编码
- 支持设置转化事件时间和业务标签
- 支持签名验证确保数据来源可靠性

### 绝不做
- 不执行归因计算（由系统自动完成）
- 不提供归因结果查询功能
- 不处理非华为应用市场的应用归因
- 不支持API版本低于5.0.0(12)的设备

### 补充
- 需要在应用归因云侧注册广告生态伙伴角色并获取adTechId
- 需要生成签名（使用注册时提供的公钥对应的私钥）
- 开发者应用必须上架华为应用市场
- 归因来源登记和转化事件登记有时间限制（偏差不超过10分钟）

## 调用规范和规则

### 输入约束

**AdSourceInfo（归因来源信息）**：
- adTechId：长度固定为8个字符（必填）
- campaignId：API 6.0.2(22)前长度≤6字符，API 6.0.2(22)及以上长度≤9字符（必填）
- destinationId：长度≤64个字符（必填）
- sourceType：枚举值（0：曝光，1：点击）（必填）
- mmpIds：最多2个ID，每个ID长度固定为8个字符（可选）
- serviceTag：长度≤32个字符（可选）
- nonce：长度固定为32个字符，不带'-'（必填）
- timestamp：unix时间戳（毫秒），偏差不超过10分钟（必填）
- signature：长度≤800个字符（必填）

**AdTriggerInfo（转化事件信息）**：
- businessScene：取值范围[0,99]（可选）
- triggerData：标准转化事件[1,200]，自定义转化事件[501,600]（必填）
- timestamp：unix时间戳（毫秒），API 6.0.2(22)新增，偏差不超过10分钟（可选）
- serviceTag：长度≤32个字符，API 6.0.2(22)新增（可选）

### 执行约束
- 最大耗时：5秒
- 签名生成：必须使用注册时提供的公钥对应的私钥
- 同一adTechId下，同一nonce最多登记5次曝光和5次点击
- 登记归因来源：广告时间与当前时间偏差不超过10分钟
- 登记转化事件：调用时间与转化事件发生时间偏差默认不超过10分钟

### 内容约束
- 禁止使用虚假的adTechId
- 禁止使用错误的公私钥对生成签名
- 禁止使用过期的签名
- 禁止在非Stage模型下使用

### 降级约束
- 签名验证失败：检查签名生成规则和公私钥匹配
- 服务连接失败：提示安装应用市场客户端并重试
- 参数校验失败：检查参数格式和取值范围
- 网络错误：提示检查网络连接并重试
- 身份检查失败：检查应用是否上架华为应用市场，广告生态伙伴信息是否已注册

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认API版本≥5.0.0(12)
2. 确认已在应用归因云侧注册广告生态伙伴角色并获取adTechId
3. 确认已准备好签名所需的私钥
4. 确认应用已上架华为应用市场并获取appId
5. 确认设备已安装应用市场客户端

**参数准备**：
```typescript
// 导入必要模块
import { attributionManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

// 定义常量
const TAG: string = 'Attribution';
```

### 步骤2：登记归因来源

**示例代码**：
```typescript
async function registerAttributionSource(): Promise<void> {
  try {
    // 1. 准备归因来源参数
    const adTechId: string = '20****e8'; // 从应用归因云侧获取
    let campaignId: string = '';
    const osApiVersion: number = deviceInfo.sdkApiVersion;
    
    // 根据API版本设置campaignId长度限制
    if (osApiVersion >= 22) {
      campaignId = '1*******9'; // API 6.0.2(22)及以上：长度≤9字符
    } else {
      campaignId = '1****6'; // API 6.0.2(22)以下：长度≤6字符
    }
    
    // 2. 构造AdSourceInfo对象
    const adSourceInfo: attributionManager.AdSourceInfo = {
      adTechId: adTechId,
      campaignId: campaignId,
      destinationId: '10******', // 开发者应用appId，不带C
      sourceType: attributionManager.SourceType.IMPRESSION, // 曝光类型
      mmpIds: ['2f****5', '2f7***5'], // 归因监测平台ID（可选）
      serviceTag: '123***2', // 分发平台关注的业务信息（可选）
      nonce: util.generateRandomUUID().replace(/-/g, ''), // 生成32字符随机数
      timestamp: Date.now(), // 当前时间戳
      signature: 'MEQCIEQlmZ****zKBSE8QnhLTIHZZZ****ZpRqRxHss65Ko****JgJKjdrWdkL****juEx2RmFS7da****ZRVZ8RyMyUXg==' // 签名值
    };
    
    // 3. 调用登记归因来源接口
    await attributionManager.registerSource(adSourceInfo);
    hilog.info(0, TAG, 'Succeeded in registering source.');
    
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0, TAG, `registerSource failed. code: ${err.code}, message: ${err.message}`);
    handleAttributionError(err);
  }
}
```

### 步骤3：登记转化事件

**示例代码**：
```typescript
async function registerAttributionTrigger(): Promise<void> {
  try {
    // 1. 准备转化事件参数
    const adTriggerInfo: attributionManager.AdTriggerInfo = {
      businessScene: 5, // 业务场景值，范围[0,99]
      triggerData: 123 // 转化事件编码，标准事件[1,200]，自定义事件[501,600]
    };
    
    // 2. 根据API版本添加可选参数
    const osApiVersion: number = deviceInfo.sdkApiVersion;
    if (osApiVersion >= 22) {
      // API 6.0.2(22)新增参数
      adTriggerInfo.timestamp = Date.now(); // 转化事件发生时间
      adTriggerInfo.serviceTag = 'testServiceTag'; // 开发者关注的业务信息
    }
    
    // 3. 调用登记转化接口
    await attributionManager.registerTrigger(adTriggerInfo);
    hilog.info(0, TAG, 'Succeeded in registering trigger data.');
    
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0, TAG, `registerTrigger failed. code: ${err.code}, message: ${err.message}`);
    handleAttributionError(err);
  }
}
```

### 步骤4：错误处理

```typescript
function handleAttributionError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      hilog.error(0, TAG, 'Parameter error. Please check parameter format and value range.');
      break;
    case 1009300001:
      hilog.error(0, TAG, 'Service extension connection failed. Please install AppGallery client.');
      break;
    case 1009300002:
      hilog.error(0, TAG, 'System internal error. Please retry or contact support.');
      break;
    case 1009300003:
      hilog.error(0, TAG, 'Identity check error. Check if app is published on AppGallery and partner is registered.');
      break;
    case 1009300004:
      hilog.error(0, TAG, 'Signature verification failed. Check signature generation rule and key pair.');
      break;
    case 1009300101:
      hilog.error(0, TAG, 'Missing adTechId parameter.');
      break;
    case 1009300102:
      hilog.error(0, TAG, 'Missing campaignId parameter.');
      break;
    case 1009300103:
      hilog.error(0, TAG, 'Missing sourceId parameter.');
      break;
    case 1009300104:
      hilog.error(0, TAG, 'Missing destinationId parameter.');
      break;
    case 1009300105:
      hilog.error(0, TAG, 'Missing sourceType parameter.');
      break;
    case 1009300106:
      hilog.error(0, TAG, 'Missing nonce parameter.');
      break;
    case 1009300107:
      hilog.error(0, TAG, 'Missing timestamp parameter.');
      break;
    case 1009300108:
      hilog.error(0, TAG, 'Missing signature parameter.');
      break;
    case 1009300109:
      hilog.error(0, TAG, 'Missing triggerData parameter.');
      break;
    case 1009300119:
      hilog.error(0, TAG, 'Network error. Please check network connection.');
      break;
    default:
      hilog.error(0, TAG, `Unknown error. code: ${error.code}, message: ${error.message}`);
  }
}
```

### 步骤5：降级处理

```typescript
async function registerAttributionSourceWithFallback(): Promise<void> {
  try {
    // 尝试登记归因来源
    await registerAttributionSource();
  } catch (error) {
    const err = error as BusinessError;
    
    // 降级策略1：如果是网络错误，延迟重试
    if (err.code === 1009300119) {
      hilog.warn(0, TAG, 'Network error, retrying in 2 seconds...');
      await new Promise(resolve => setTimeout(resolve, 2000));
      try {
        await registerAttributionSource();
        return;
      } catch (retryError) {
        hilog.error(0, TAG, 'Retry failed, please check network and try again later.');
      }
    }
    
    // 降级策略2：如果是签名验证失败，提示检查配置
    if (err.code === 1009300004 || err.code === 1009300114) {
      hilog.error(0, TAG, 'Signature verification failed. Please check:');
      hilog.error(0, TAG, '1. Signature generation rule is correct');
      hilog.error(0, TAG, '2. Public-private key pair matches');
      hilog.error(0, TAG, '3. Signature string length ≤ 800 characters');
    }
    
    // 降级策略3：如果是服务连接失败，提示安装应用市场
    if (err.code === 1009300001) {
      hilog.error(0, TAG, 'AppGallery client not found. Please install AppGallery and try again.');
    }
    
    throw err;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查参数格式和取值范围 |
| 1009300001 | 服务扩展连接失败 | 安装应用市场客户端 |
| 1009300002 | 系统内部错误 | 重试或联系技术支持 |
| 1009300003 | 身份检查错误 | 检查应用是否上架华为应用市场，广告生态伙伴信息是否已注册 |
| 1009300004 | 签名验证失败 | 检查签名生成规则、公私钥匹配、签名长度≤800字符 |
| 1009300101 | 缺失adTechId参数 | 检查参数是否符合入参要求 |
| 1009300102 | 缺失campaignId参数 | 检查参数是否符合入参要求 |
| 1009300103 | 缺失sourceId参数 | 检查参数是否符合入参要求 |
| 1009300104 | 缺失destinationId参数 | 检查参数是否符合入参要求 |
| 1009300105 | 缺失sourceType参数 | 检查参数是否符合入参要求 |
| 1009300106 | 缺失nonce参数 | 检查参数是否符合入参要求 |
| 1009300107 | 缺失timestamp参数 | 检查参数是否符合入参要求 |
| 1009300108 | 缺失signature参数 | 检查参数是否符合入参要求 |
| 1009300109 | 缺失triggerData参数 | 检查参数是否符合入参要求 |
| 1009300114 | 测试环境签名校验失败 | 检查签名生成规则、公私钥匹配、签名长度 |
| 1009300119 | 网络错误 | 检查网络连接或重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": ">=5.0.0",
    "@kit.PerformanceAnalysisKit": ">=5.0.0",
    "@kit.BasicServicesKit": ">=5.0.0",
    "@kit.ArkTS": ">=5.0.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：≥5.0.0(12)
- 设备要求：必须安装应用市场客户端
- 开发环境：DevEco Studio 5.0.0及以上

### 常见编译问题

**问题1：找不到attributionManager模块**
```
Error: Cannot find module '@kit.AppGalleryKit' or its corresponding type declarations.
```
**解决方法**：
1. 确认项目API版本≥5.0.0(12)
2. 检查build-profile.json5中的compileSdkVersion配置
3. 同步项目依赖

**问题2：SourceType枚举找不到**
```
Error: Property 'SourceType' does not exist on type 'typeof attributionManager'.
```
**解决方法**：
1. 确认导入语句正确：`import { attributionManager } from '@kit.AppGalleryKit';`
2. 确认使用正确的枚举路径：`attributionManager.SourceType.IMPRESSION`

**问题3：签名生成失败**
```
Error: Signature generation failed.
```
**解决方法**：
1. 检查私钥格式是否正确
2. 确认签名生成规则符合文档要求
3. 参考归因来源签名计算规则文档生成签名

## 常见问题与解决方法

### Q1：如何获取adTechId？
**原因**：adTechId是在应用归因云侧注册角色时分配的
**解决方法**：
- 访问应用归因云侧管理平台
- 注册广告生态伙伴角色（媒体或分发平台）
- 注册成功后获取8字符长度的adTechId

### Q2：如何生成签名？
**原因**：登记归因来源需要签名验证
**解决方法**：
- 使用注册时提供的公钥对应的私钥
- 按照归因来源签名计算规则生成签名
- 确保签名长度≤800字符

### Q3：调用接口返回1009300003错误怎么办？
**原因**：身份检查失败
**解决方法**：
- 确认应用已上架华为应用市场
- 确认已在应用归因云侧注册广告生态伙伴信息
- 检查广告生态伙伴信息是否被删除

### Q4：同一nonce可以登记多少次？
**原因**：防止重复登记
**解决方法**：
- 同一adTechId下，同一nonce最多登记5次曝光和5次点击
- 建议每次广告请求生成新的nonce

### Q5：timestamp时间戳有什么限制？
**原因**：防止过期数据登记
**解决方法**：
- 登记归因来源时：广告时间与当前时间偏差不超过10分钟
- 登记转化事件时：调用时间与转化事件发生时间偏差默认不超过10分钟

### Q6：API 6.0.2(22)版本有什么新特性？
**原因**：API版本更新
**解决方法**：
- AdSourceInfo和AdTriggerInfo新增timestamp和serviceTag参数
- campaignId长度限制从6字符扩展到9字符
- 使用deviceInfo.sdkApiVersion判断API版本并适配

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "register_source/register_trigger",
  "apiUsed": [
    "attributionManager.registerSource",
    "attributionManager.registerTrigger"
  ],
  "apiVersion": ">=5.0.0(12)",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## 参考文档

- [API开发指南](references/store-attribution-developmentguide.md)
- [API参考说明](references/store-attributionmanager.md)
- [ArkTS API错误码](references/store-error-code.md)
- [管理归因角色](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/store-attribution-register)
- [归因来源签名计算规则](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/appgallery-attribution-appendix-triger)

## 完整示例代码

- [ArkTS示例：登记归因来源](assets/register_source_example.ets)
- [ArkTS示例：登记转化事件](assets/register_trigger_example.ets)
- [ArkTS示例：签名工具类](assets/sign_util.ets)

## 测试用例

### 正向测试用例
- [登记曝光类型归因来源](tests/test_positive.py)：正常登记曝光类型归因来源
- [登记点击类型归因来源](tests/test_positive.py)：正常登记点击类型归因来源
- [登记标准转化事件](tests/test_positive.py)：正常登记标准转化事件
- [登记自定义转化事件](tests/test_positive.py)：正常登记自定义转化事件

### 边界测试用例
- [campaignId长度边界测试](tests/test_boundary.py)：测试campaignId长度限制（API 6.0.2前≤6，后≤9）
- [nonce重复登记测试](tests/test_boundary.py)：测试同一nonce登记5次曝光和5次点击
- [timestamp时间偏差测试](tests/test_boundary.py)：测试时间偏差10分钟边界
- [serviceTag长度边界测试](tests/test_boundary.py)：测试serviceTag长度32字符限制

### 异常测试用例
- [参数缺失测试](tests/test_exception.py)：测试必填参数缺失情况
- [签名验证失败测试](tests/test_exception.py)：测试错误签名情况
- [身份检查失败测试](tests/test_exception.py)：测试应用未上架或未注册情况
- [网络异常测试](tests/test_exception.py)：测试网络错误情况