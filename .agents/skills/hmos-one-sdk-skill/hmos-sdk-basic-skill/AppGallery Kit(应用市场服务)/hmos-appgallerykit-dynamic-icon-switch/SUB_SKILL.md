---
name: hmos-appgallerykit-dynamic-icon-switch
description: 实现应用图标动态切换功能，支持查询动态图标信息、切换动态图标、恢复默认图标三种操作，仅支持真机调试，适用于Phone/Tablet/PC/2in1/Wearable/TV设备
---

# 实现应用图标动态切换技能

## 功能描述

本技能提供HarmonyOS应用图标动态切换功能的完整实现方案，包含查询动态图标信息、切换动态图标、恢复默认图标三个核心功能。通过AppGallery Kit的appInfoManager模块，开发者可以实现应用的动态图标管理，为用户提供个性化的应用图标选择体验。

**核心功能**：
- 查询可选动态图标信息（iconUrl、iconId、enabled状态）
- 切换到指定的动态图标
- 恢复应用到默认图标

**技术特点**：
- 基于Promise异步回调机制
- 需要应用市场客户端支持
- 需在AGC上传审核动态图标
- 支持多设备类型

## 使用场景

### 触发词
- "查询动态图标"
- "切换应用图标"
- "恢复默认图标"
- "动态图标管理"
- "应用图标切换"

### 能做
- 查询应用在AGC配置的所有动态图标信息
- 根据iconId切换到指定的动态图标
- 禁用当前动态图标，恢复应用默认图标
- 提供完整的错误处理和用户提示

### 绝不做
- 不支持在模拟器上运行（必须真机调试）
- 不处理未在AGC上传审核的动态图标
- 不处理主题自定义图标冲突（需引导用户切换主题）
- 不支持在后台执行图标切换操作

### 补充
- **版本要求**：API 5.0.3(15)及以上
- **设备支持**：Phone、Tablet、PC/2in1（5.0.3+），Wearable（5.1.1(18)+），TV（5.1.1(19)+）
- **前置条件**：需要在AGC后台上传并审核动态图标
- **权限要求**：无需额外权限声明

## 调用规范和规则

### 输入约束
- iconId类型：string，必填，长度限制由AGC配置决定
- 查询操作：无需参数
- 切换操作：需要有效的iconId参数
- 恢复操作：无需参数

### 执行约束
- 最大耗时：单次API调用不超过5秒
- 并发限制：建议串行执行图标切换操作
- 重试策略：网络错误可重试，最多3次
- 调用时机：应用在前台运行时调用

### 内容约束
- 禁止在后台服务中调用图标切换API
- 禁止频繁切换图标（建议间隔>1秒）
- 禁止使用空字符串或无效iconId
- 禁止在主题自定义图标生效时强制切换

### 降级约束
- **网络失败**：提示用户检查网络，稍后重试
- **无动态图标数据**：引导用户在AGC上传图标
- **主题图标冲突**：提示用户切换至官方主题
- **服务连接失败**：提示安装应用市场客户端

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本：确保设备API版本 >= 5.0.3(15)
2. 检查设备类型：确认在支持设备列表中
3. 检查应用状态：确保应用在前台运行
4. 检查环境：确认使用真机调试（非模拟器）

**模块导入**：
```typescript
import { appInfoManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：查询动态图标信息

**功能说明**：查询应用在AGC配置的所有动态图标信息，返回图标列表。

**示例代码**：
```typescript
async function queryDynamicIcons(): Promise<appInfoManager.DynamicIconInfo[]> {
  try {
    const iconInfos: appInfoManager.DynamicIconInfo[] = 
      await appInfoManager.queryDynamicIcons();
    
    hilog.info(0, 'DynamicIcon', `Query succeeded, icon count: ${iconInfos.length}`);
    
    iconInfos.forEach((icon, index) => {
      hilog.info(0, 'DynamicIcon', 
        `Icon ${index}: id=${icon.iconId}, enabled=${icon.enabled}, url=${icon.iconUrl}`);
    });
    
    return iconInfos;
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0, 'DynamicIcon', 
      `Query failed, code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

**返回数据结构**：
```typescript
interface DynamicIconInfo {
  iconUrl: string;    // 动态图标链接
  iconId: string;     // 动态图标ID
  enabled: boolean;   // 是否正在使用
}
```

### 步骤3：切换动态图标

**功能说明**：根据iconId切换到指定的动态图标。

**示例代码**：
```typescript
async function switchDynamicIcon(iconId: string): Promise<void> {
  if (!iconId || iconId.trim() === '') {
    hilog.error(0, 'DynamicIcon', 'Invalid iconId: empty or null');
    throw new Error('Invalid iconId parameter');
  }

  try {
    await appInfoManager.selectDynamicIcon(iconId);
    hilog.info(0, 'DynamicIcon', `Switch succeeded, new iconId: ${iconId}`);
  } catch (error) {
    const err = error as BusinessError;
    
    if (err.code === 1006800013) {
      hilog.error(0, 'DynamicIcon', 
        'Switch failed: custom theme icon is active, please switch to official theme');
    } else {
      hilog.error(0, 'DynamicIcon', 
        `Switch failed, code: ${err.code}, message: ${err.message}`);
    }
    
    throw error;
  }
}
```

### 步骤4：恢复默认图标

**功能说明**：禁用当前动态图标，恢复应用默认图标。

**示例代码**：
```typescript
async function restoreDefaultIcon(): Promise<void> {
  try {
    await appInfoManager.disableDynamicIcon();
    hilog.info(0, 'DynamicIcon', 'Restore default icon succeeded');
  } catch (error) {
    const err = error as BusinessError;
    
    if (err.code === 1006800012) {
      hilog.warn(0, 'DynamicIcon', 'Already using default icon');
    } else {
      hilog.error(0, 'DynamicIcon', 
        `Restore failed, code: ${err.code}, message: ${err.message}`);
    }
    
    throw error;
  }
}
```

### 步骤5：错误处理

**完整错误处理示例**：
```typescript
import { appInfoManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

class DynamicIconManager {
  private readonly TAG = 'DynamicIconManager';

  async handleIconOperation(iconId?: string): Promise<void> {
    try {
      if (iconId) {
        await this.switchIcon(iconId);
      } else {
        await this.restoreDefault();
      }
    } catch (error) {
      const err = error as BusinessError;
      this.handleError(err);
    }
  }

  private async switchIcon(iconId: string): Promise<void> {
    try {
      await appInfoManager.selectDynamicIcon(iconId);
      hilog.info(0, this.TAG, `Icon switched to ${iconId}`);
    } catch (error) {
      throw error;
    }
  }

  private async restoreDefault(): Promise<void> {
    try {
      await appInfoManager.disableDynamicIcon();
      hilog.info(0, this.TAG, 'Default icon restored');
    } catch (error) {
      throw error;
    }
  }

  private handleError(error: BusinessError): void {
    switch (error.code) {
      case 1006800001:
        hilog.error(0, this.TAG, 'Service connection failed, please install AppGallery client');
        break;
      case 1006800009:
        hilog.error(0, this.TAG, 'System internal error, please retry or contact support');
        break;
      case 1006800010:
        hilog.error(0, this.TAG, 'No dynamic icon data, please upload icons in AGC');
        break;
      case 1006800011:
        hilog.error(0, this.TAG, 'Select dynamic icon failed, please contact support');
        break;
      case 1006800012:
        hilog.warn(0, this.TAG, 'Already using default icon');
        break;
      case 1006800013:
        hilog.error(0, this.TAG, 'Custom theme icon active, please switch to official theme');
        break;
      case 401:
        hilog.error(0, this.TAG, 'Parameter error, please check iconId');
        break;
      default:
        hilog.error(0, this.TAG, `Unknown error: ${error.code}, ${error.message}`);
    }
  }
}
```

### 步骤6：降级处理

**网络失败降级**：
```typescript
async function queryWithRetry(maxRetries = 3): Promise<appInfoManager.DynamicIconInfo[]> {
  let lastError: BusinessError | null = null;
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await appInfoManager.queryDynamicIcons();
    } catch (error) {
      lastError = error as BusinessError;
      hilog.warn(0, 'DynamicIcon', `Attempt ${i + 1} failed, retrying...`);
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
  
  hilog.error(0, 'DynamicIcon', 'All retries failed, using fallback');
  throw lastError;
}
```

**无数据降级**：
```typescript
async function querySafely(): Promise<appInfoManager.DynamicIconInfo[]> {
  try {
    const icons = await appInfoManager.queryDynamicIcons();
    return icons;
  } catch (error) {
    const err = error as BusinessError;
    if (err.code === 1006800010) {
      hilog.warn(0, 'DynamicIcon', 'No dynamic icon configured, returning empty array');
      return [];
    }
    throw error;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | 参数错误 | iconId为空或无效 | 检查iconId参数格式和有效性 |
| 1006800001 | 服务连接失败 | 未安装应用市场客户端 | 安装应用市场客户端后重试 |
| 1006800009 | 系统内部错误 | 系统内部异常 | 重试或通过在线提单提交问题 |
| 1006800010 | 无动态图标数据 | 未在AGC上传审核动态图标 | 在AGC后台上传并审核动态图标 |
| 1006800011 | 选择动态图标失败 | BMS使能动态图标失败 | 通过在线提单提交问题 |
| 1006800012 | 恢复默认图标失败 | 当前已经是默认图标 | 先切换动态图标，再调用恢复接口 |
| 1006800013 | 主题自定义图标冲突 | 设备使用的主题对应用有自定义图标 | 切换至官方主题后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": "^5.0.3",
    "@kit.PerformanceAnalysisKit": "^5.0.3",
    "@kit.BasicServicesKit": "^5.0.3"
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0.3(15)或更高版本
- DevEco Studio：4.0或更高版本
- 设备要求：真机调试（不支持模拟器）
- 应用市场客户端：需要安装最新版本

### 常见编译问题

**问题1：找不到@kit.AppGalleryKit模块**
```
Error: Cannot find module '@kit.AppGalleryKit'
```
**解决方法**：
1. 确认HarmonyOS SDK版本 >= 5.0.3(15)
2. 在build-profile.json5中配置正确的SDK版本
3. 同步项目依赖：File -> Sync Project with Gradle Files

**问题2：API版本不兼容**
```
Error: Property 'queryDynamicIcons' does not exist on type 'typeof appInfoManager'
```
**解决方法**：
1. 检查compileSdkVersion是否 >= 15
2. 在module.json5中声明最小API版本：
```json
{
  "module": {
    "minAPIVersion": 15
  }
}
```

**问题3：真机调试失败**
```
Error: Dynamic icon feature not supported on emulator
```
**解决方法**：
1. 使用真机设备进行调试
2. 确认设备系统版本 >= 5.0.3(15)
3. 检查设备类型是否在支持列表中

## 常见问题与解决方法

### Q1：查询动态图标返回空数组
**原因**：未在AGC后台上传审核动态图标
**解决方法**：
1. 登录AGC后台
2. 进入应用配置 -> 图标管理
3. 上传动态图标并提交审核
4. 审核通过后重新查询

### Q2：切换图标提示1006800013错误
**原因**：设备使用的主题对当前应用有自定义图标
**解决方法**：
1. 打开设置 -> 桌面和个性化
2. 切换至官方主题
3. 重新调用切换图标接口

### Q3：恢复默认图标提示1006800012错误
**原因**：当前已经使用默认图标，无需恢复
**解决方法**：
- 这是正常的提示，可以忽略
- 或在调用前先查询当前图标状态

### Q4：API调用返回1006800001错误
**原因**：未安装应用市场客户端或版本过低
**解决方法**：
1. 确认设备已安装应用市场客户端
2. 更新应用市场客户端到最新版本
3. 在应用市场登录华为账号

### Q5：模拟器上无法测试
**原因**：图标管理服务不支持模拟器
**解决方法**：
- 必须使用真机设备进行调试
- 确保设备系统版本和API版本符合要求

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "query/switch/restore",
  "iconCount": 3,
  "currentIconId": "icon_001",
  "enabled": true,
  "apiUsed": [
    "appInfoManager.queryDynamicIcons",
    "appInfoManager.selectDynamicIcon",
    "appInfoManager.disableDynamicIcon"
  ],
  "deviceInfo": {
    "apiVersion": "5.0.3(15)",
    "deviceType": "Phone"
  }
}
```

## 参考文档

- [API开发指南](references/appgallery-appinfo-use.md)
- [API参考说明](references/appgallery-appinfomanager.md)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-error-code)

## 完整示例代码

- [ArkTS完整示例](assets/dynamic-icon-manager.ets)
- [UI界面示例](assets/dynamic-icon-page.ets)

## 测试用例

### 正向测试用例
- [查询动态图标列表](tests/test_positive.ets) - 验证成功查询图标信息
- [切换动态图标](tests/test_positive.ets) - 验证成功切换图标
- [恢复默认图标](tests/test_positive.ets) - 验证成功恢复默认图标

### 边界测试用例
- [空iconId测试](tests/test_boundary.ets) - 验证空字符串参数处理
- [无效iconId测试](tests/test_boundary.ets) - 验证无效图标ID处理
- [重复切换测试](tests/test_boundary.ets) - 验证重复切换同一图标

### 异常测试用例
- [无网络测试](tests/test_exception.ets) - 验证网络异常处理
- [无图标数据测试](tests/test_exception.ets) - 验证未配置图标场景
- [主题冲突测试](tests/test_exception.ets) - 验证主题图标冲突处理