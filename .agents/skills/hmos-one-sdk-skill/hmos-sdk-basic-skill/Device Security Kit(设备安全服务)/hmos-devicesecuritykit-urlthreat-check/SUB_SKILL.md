---
name: hmos-devicesecuritykit-urlthreat-check
description: 检测URL是否为恶意网址，支持批量检测最多10个URL，适用于用户访问网址时的安全验证、钓鱼网站拦截场景
---

# URL检测技能

## 功能描述

本技能用于调用Device Security Kit的checkUrlThreat接口检测URL是否为恶意网址，并根据检测结果提示或拦截用户访问。支持检测钓鱼网站、恶意软件网站等多种威胁类型，帮助应用保护用户免受恶意网址侵害。

**核心能力**：
- URL威胁检测：检测URL是否为恶意网址
- 批量检测：单次请求支持检测最多10个URL
- 威胁分类：返回NORMAL、PHISHING、MALWARE、OTHERS四种威胁类型
- 端云协同：通过华为云端服务实时检测URL威胁

## 使用场景

### 触发词
- "URL检测"
- "检测网址是否安全"
- "检查恶意网址"
- "验证URL威胁"
- "拦截钓鱼网站"

### 能做
- 检测用户访问的URL是否为恶意网址
- 批量检测多个URL的安全状态（最多10个）
- 根据检测结果提示用户风险
- 拦截恶意网址访问
- 识别钓鱼网站、恶意软件网站等威胁类型

### 绝不做
- 不检测非URL格式的字符串
- 不执行URL访问或下载操作
- 不修改或存储URL内容
- 不处理超出频率限制的检测请求（每天最多1万次，并发最多5个）
- 不在UI线程中执行检测操作

### 补充
- 支持Phone、Tablet、PC/2in1设备，从5.1.0(18)版本开始支持Wearable设备
- 需要联网才能使用，涉及端云协同
- 需要在AppGallery Connect开通"安全检测服务"
- 每个应用在每个设备上每天最多调用1万次接口
- 每个设备最多支持5个并发调用

## 调用规范和规则

### 输入约束
- URL数量：单次请求最多10个URL
- URL长度：每个URL长度不大于4096字节
- URL格式：必须是有效的URL格式字符串
- 调用频次：每个应用在每个设备上每天最多1万次
- 并发限制：每个设备最多5个并发调用

### 执行约束
- 最大耗时：网络请求可能需要数秒，建议设置超时时间
- 线程要求：必须在非UI线程执行，避免阻塞UI线程
- 重试策略：网络异常时可延迟1-5秒重试
- 超频处理：超过频率限制时，需等待下一个统计周期

### 内容约束
- 禁止检测非法或敏感URL
- 禁止绕过频率限制进行检测
- 禁止在检测过程中修改URL内容
- 禁止将检测结果用于非安全防护目的

### 降级约束
- 网络失败：提示用户检查网络连接，延迟重试
- 服务不可用：跳过检测或使用本地缓存结果
- 频率超限：提示用户稍后再试，记录日志
- 权限不足：引导用户开通安全检测服务

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已在AppGallery Connect开通"安全检测服务"
2. 确认已申请并配置Profile文件
3. 确认设备已联网
4. 确认当前调用频次未超限
5. 确认URL格式有效且长度符合要求

**参数准备**：
```typescript
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "UrlThreatCheck";
const DOMAIN = 0x0000;

// 准备待检测的URL列表（最多10个）
const urlsToCheck: string[] = [
  'https://example1.com',
  'https://example2.com'
];
```

### 步骤2：调用API检测URL威胁

**示例代码**：
```typescript
async function checkUrlThreat(urls: string[]): Promise<safetyDetect.UrlCheckResponse> {
  // 参数校验
  if (!urls || urls.length === 0) {
    throw new Error('URL列表不能为空');
  }
  
  if (urls.length > 10) {
    throw new Error('单次请求最多检测10个URL');
  }
  
  // 校验URL长度
  for (const url of urls) {
    if (url.length > 4096) {
      throw new Error(`URL长度超过限制: ${url}`);
    }
  }
  
  // 构造请求参数
  const req: safetyDetect.UrlCheckRequest = {
    urls: urls
  };
  
  try {
    hilog.info(DOMAIN, TAG, '开始检测URL威胁，URL数量: %{public}d', urls.length);
    
    // 调用API检测
    const response: safetyDetect.UrlCheckResponse = await safetyDetect.checkUrlThreat(req);
    
    hilog.info(DOMAIN, TAG, 'URL检测完成，结果数量: %{public}d', response.results.length);
    
    return response;
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'URL检测失败: %{public}d %{public}s', e.code, e.message);
    throw e;
  }
}
```

### 步骤3：处理检测结果

**示例代码**：
```typescript
function handleThreatResults(response: safetyDetect.UrlCheckResponse): void {
  // 遍历检测结果
  for (const result of response.results) {
    const url = result.url;
    const threat = result.threat;
    
    switch (threat) {
      case safetyDetect.UrlThreatType.NORMAL:
        hilog.info(DOMAIN, TAG, 'URL安全: %{public}s', url);
        // 允许访问
        break;
        
      case safetyDetect.UrlThreatType.PHISHING:
        hilog.warn(DOMAIN, TAG, '钓鱼网站: %{public}s', url);
        // 拦截并提示用户
        showAlert('警告', '该网站可能是钓鱼网站，建议不要访问');
        break;
        
      case safetyDetect.UrlThreatType.MALWARE:
        hilog.warn(DOMAIN, TAG, '恶意软件网站: %{public}s', url);
        // 拦截并提示用户
        showAlert('警告', '该网站包含恶意软件，禁止访问');
        break;
        
      case safetyDetect.UrlThreatType.OTHERS:
        hilog.warn(DOMAIN, TAG, '其他威胁类型: %{public}s', url);
        // 根据业务策略处理
        showAlert('警告', '该网站存在安全风险，建议谨慎访问');
        break;
        
      default:
        hilog.info(DOMAIN, TAG, '未知威胁类型: %{public}d', threat);
    }
  }
}

function showAlert(title: string, message: string): void {
  // 实现弹窗提示逻辑
  console.log(`${title}: ${message}`);
}
```

### 步骤4：错误处理

**示例代码**：
```typescript
async function checkUrlThreatWithErrorHandling(urls: string[]): Promise<void> {
  try {
    const response = await checkUrlThreat(urls);
    handleThreatResults(response);
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    
    switch (e.code) {
      case 201:
        console.error('权限校验失败：未开通安全检测服务');
        // 引导用户开通服务
        break;
        
      case 401:
        console.error('参数错误：请检查URL格式和数量');
        // 校验参数
        break;
        
      case 801:
        console.error('API不支持：设备版本过低');
        // 提示用户升级系统
        break;
        
      case 1010800001:
        console.error('内部错误：请重试');
        // 延迟重试
        setTimeout(() => checkUrlThreatWithErrorHandling(urls), 1000);
        break;
        
      case 1010800002:
        console.error('网络异常：请检查网络连接');
        // 提示用户检查网络
        break;
        
      case 1010800003:
        console.error('访问云端服务器失败：请稍后重试');
        // 延迟重试
        setTimeout(() => checkUrlThreatWithErrorHandling(urls), 3000);
        break;
        
      case 1010800005:
        console.error('并发调用超限：请减少并发数量');
        // 延迟重试
        setTimeout(() => checkUrlThreatWithErrorHandling(urls), 1000);
        break;
        
      case 1010800006:
        console.error('调用频率超限：请明天再试');
        // 提示用户稍后再试
        break;
        
      case 1010800007:
        console.error('操作超时：请重试');
        // 重新发起请求
        setTimeout(() => checkUrlThreatWithErrorHandling(urls), 2000);
        break;
        
      case 1010800008:
        console.error('云服务流量超限：请延迟重试');
        // 指数退避重试
        setTimeout(() => checkUrlThreatWithErrorHandling(urls), 5000);
        break;
        
      default:
        console.error(`未知错误: ${e.code} - ${e.message}`);
    }
  }
}
```

### 步骤5：降级处理

**示例代码**：
```typescript
async function checkUrlThreatWithFallback(urls: string[]): Promise<void> {
  try {
    // 尝试调用在线检测
    const response = await checkUrlThreat(urls);
    handleThreatResults(response);
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    
    // 网络异常或服务不可用时的降级策略
    if (e.code === 1010800002 || e.code === 1010800003 || e.code === 1010800007) {
      console.warn('在线检测不可用，使用降级策略');
      
      // 降级策略1：使用本地黑名单检测
      const localThreatUrls = getLocalThreatUrls();
      const localResults = checkWithLocalBlacklist(urls, localThreatUrls);
      handleThreatResults(localResults);
      
      // 降级策略2：提示用户手动确认
      showManualConfirmationDialog(urls);
    } else {
      // 其他错误直接抛出
      throw err;
    }
  }
}

function getLocalThreatUrls(): string[] {
  // 从本地存储获取已知威胁URL列表
  return [
    'https://known-threat.com',
    'https://phishing-site.com'
  ];
}

function checkWithLocalBlacklist(urls: string[], threatUrls: string[]): safetyDetect.UrlCheckResponse {
  // 使用本地黑名单检测
  const results: safetyDetect.UrlCheckResult[] = urls.map(url => ({
    url: url,
    threat: threatUrls.includes(url) ? safetyDetect.UrlThreatType.OTHERS : safetyDetect.UrlThreatType.NORMAL
  }));
  
  return { results };
}

function showManualConfirmationDialog(urls: string[]): void {
  // 显示手动确认对话框
  console.log('无法自动检测URL安全性，请用户手动确认是否继续访问');
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 201 | 权限校验失败 | 应用hap未开通Device Security服务 | 在AppGallery Connect开通"安全检测服务"并重新申请Profile |
| 401 | 参数错误 | 1. 必填参数未指定<br>2. 参数类型错误<br>3. 参数校验失败 | 1. 检查URL列表是否为空<br>2. 检查URL数量是否超过10个<br>3. 检查URL长度是否超过4096字节 |
| 801 | API不支持 | 设备系统版本过低 | 提示用户升级系统到5.0.0(12)或更高版本 |
| 1010800001 | 内部错误 | 接口执行流程中调用系统其它接口出现异常 | 优先重试，若重试不成功则通过在线提单申请帮助 |
| 1010800002 | 设备网络异常 | 设备未联网 | 提示用户连接网络后重新发起请求 |
| 1010800003 | 访问云端服务器异常 | 云侧服务不稳定或异常 | 重新发起请求 |
| 1010800005 | 调用数量超过并行阈值 | 开发者应用或其他应用并发调用数量超出最大阈值（每个设备最多5个并发） | 延迟1秒后重试 |
| 1010800006 | 调用频率超过阈值 | 应用过多调用接口（每个应用每个设备每天最多1万次） | 等待下一个统计周期再调用 |
| 1010800007 | 操作超时 | 系统高负载或网络拥堵 | 重新发起请求 |
| 1010800008 | 云服务流量超过阈值 | 大范围设备同时调用云侧接口 | 延迟5秒重试，若再次失败则指数递增间隔重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.DeviceSecurityKit": ">=5.0.0(12)",
    "@kit.BasicServicesKit": ">=5.0.0(12)",
    "@kit.PerformanceAnalysisKit": ">=5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS版本：>=5.0.0(12)
- 设备类型：Phone、Tablet、PC/2in1，从5.1.0(18)版本开始支持Wearable
- 开发工具：DevEco Studio >= 4.0
- 网络要求：需要联网访问华为云端服务

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.DeviceSecurityKit'
```
**解决方法**：
1. 确认HarmonyOS SDK版本 >= 5.0.0(12)
2. 确认DevEco Studio版本 >= 4.0
3. 在build-profile.json5中配置正确的SDK版本

**问题2：类型定义错误**
```
Error: Property 'checkUrlThreat' does not exist on type 'typeof safetyDetect'
```
**解决方法**：
1. 确认已正确导入safetyDetect模块
2. 确认SDK版本支持该API（5.0.0(12)及以上）
3. 清理项目并重新编译：Build -> Clean Project

**问题3：权限配置错误**
```
Error: Permission denied (error code: 201)
```
**解决方法**：
1. 在AppGallery Connect开通"安全检测服务"
2. 重新申请Profile文件并配置到工程中
3. 确认应用签名配置正确

## 常见问题与解决方法

### Q1：如何开通安全检测服务？
**原因**：使用URL检测功能前需要开通服务
**解决方法**：
1. 登录AppGallery Connect网站
2. 选择项目并进入"开放能力管理"
3. 勾选"安全检测服务"并点击"保存"
4. 重新申请Profile文件并配置到工程

### Q2：URL检测频率超限怎么办？
**原因**：每个应用在每个设备上每天最多调用1万次接口
**解决方法**：
- 控制调用频率，避免频繁检测
- 使用缓存策略，避免重复检测相同URL
- 在非关键场景可以考虑降级处理
- 记录调用次数，接近限制时提前预警

### Q3：并发调用超限如何处理？
**原因**：每个设备最多支持5个并发调用
**解决方法**：
- 使用队列机制控制并发数量
- 延迟1秒后重试
- 避免同时发起多个检测请求

### Q4：网络异常时如何降级处理？
**原因**：URL检测依赖云端服务，需要联网
**解决方法**：
- 使用本地黑名单进行基础检测
- 提示用户手动确认URL安全性
- 记录待检测URL，网络恢复后重新检测

### Q5：如何在UI线程中安全调用？
**原因**：API涉及端云协同，不能在UI线程执行
**解决方法**：
```typescript
// 使用TaskPool在后台线程执行
import taskpool from '@ohos.taskpool';

@Concurrent
function checkUrlThreatTask(urls: string[]): Promise<safetyDetect.UrlCheckResponse> {
  return checkUrlThreat(urls);
}

// 在UI线程中调用
async function checkUrlThreatInUI(urls: string[]): Promise<void> {
  try {
    const response = await taskpool.execute(checkUrlThreatTask, urls);
    handleThreatResults(response);
  } catch (err) {
    console.error('检测失败:', err);
  }
}
```

### Q6：如何批量检测大量URL？
**原因**：单次请求最多检测10个URL
**解决方法**：
- 将URL列表分批处理，每批最多10个
- 使用并发控制避免超过并发限制
- 示例代码：
```typescript
async function batchCheckUrls(allUrls: string[]): Promise<safetyDetect.UrlCheckResponse[]> {
  const batchSize = 10;
  const results: safetyDetect.UrlCheckResponse[] = [];
  
  for (let i = 0; i < allUrls.length; i += batchSize) {
    const batch = allUrls.slice(i, i + batchSize);
    const response = await checkUrlThreat(batch);
    results.push(response);
    
    // 添加延迟避免频率超限
    if (i + batchSize < allUrls.length) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
  
  return results;
}
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "urlCount": 2,
  "results": [
    {
      "url": "https://example1.com",
      "threat": "NORMAL",
      "threatName": "未发现威胁"
    },
    {
      "url": "https://example2.com",
      "threat": "PHISHING",
      "threatName": "钓鱼网站"
    }
  ],
  "apiUsed": [
    "safetyDetect.checkUrlThreat"
  ],
  "timestamp": "2026-07-04T15:30:00.000Z"
}
```

## 参考文档

- [URL检测开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-urlthreat-check)
- [SafetyDetect API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-safetydetectenhanced-api)
- [SafetyDetect错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-arktsapi-errcode-safetydetect)
- [开通Device Security服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-activateservice)

## 完整示例代码

- [ArkTS完整示例](assets/url_threat_check_example.ets)
- [错误处理示例](assets/error_handling_example.ets)
- [降级处理示例](assets/fallback_example.ets)

## 测试用例

### 正向测试用例
- [检测单个安全URL](tests/test_positive.py)：检测正常的URL，验证返回NORMAL
- [检测单个恶意URL](tests/test_positive.py)：检测已知的恶意URL，验证返回威胁类型
- [批量检测URL](tests/test_positive.py)：批量检测多个URL（少于10个），验证返回结果数量正确

### 边界测试用例
- [检测10个URL](tests/test_boundary.py)：测试最大批量检测数量限制
- [检测超长URL](tests/test_boundary.py)：测试接近4096字节长度的URL
- [并发调用测试](tests/test_boundary.py)：测试5个并发调用的限制

### 异常测试用例
- [检测空URL列表](tests/test_exception.py)：测试空URL列表的错误处理
- [检测超过10个URL](tests/test_exception.py)：测试超过批量限制的错误处理
- [网络异常测试](tests/test_exception.py)：测试网络不可用时的错误处理
- [权限不足测试](tests/test_exception.py)：测试未开通服务时的错误处理
- [频率超限测试](tests/test_exception.py)：测试超过调用频率限制的错误处理