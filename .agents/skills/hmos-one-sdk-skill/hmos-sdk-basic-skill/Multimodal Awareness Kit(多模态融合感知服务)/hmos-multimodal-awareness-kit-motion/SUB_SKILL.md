---
name: hmos-multimodal-awareness-kit-motion
description: 获取用户操作手和握持手状态，支持订阅状态变化和获取最新状态，需要运动手势权限，适用于单手操作识别、握持姿态检测场景
---

# 获取用户动作开发指导技能

## 功能描述

本技能提供HarmonyOS多模态融合感知服务（Multimodal Awareness Kit）的动作感知能力，支持获取用户的操作手状态和握持手状态。通过订阅状态变化事件或主动查询，实时感知用户的手部操作状态，为应用提供手势识别和动作感知能力。

**核心能力**：
- **操作手状态感知**：识别用户当前是用左手还是右手操作设备屏幕（API version 15+）
- **握持手状态感知**：识别用户当前的握持姿态（左手/右手/双手/未握持）（API version 20+）
- **订阅模式**：实时监听状态变化，通过回调获取最新状态
- **查询模式**：主动获取当前最新的操作手状态

**技术特点**：
- 基于触控事件的智能识别
- 支持同步和异步调用
- 提供完整的状态枚举值
- 包含详细的错误处理机制

## 使用场景

### 触发词
- "获取操作手状态"
- "识别左右手操作"
- "获取握持手状态"
- "识别握持姿态"
- "订阅手部状态变化"
- "motion模块"
- "动作感知"

### 能做
- 订阅操作手状态变化，实时感知用户操作手变化
- 订阅握持手状态变化，实时感知设备握持姿态
- 取消订阅操作手或握持手状态变化
- 主动查询最新的操作手状态
- 处理权限申请和错误情况
- 提供完整的错误码处理和降级方案

### 绝不做
- 不处理与动作感知无关的功能
- 不替代应用层的权限申请流程（仅提供权限声明说明）
- 不处理设备不支持该功能的降级UI实现
- 不处理指关节操作、多指同时操作等不支持的场景

### 补充
- **设备要求**：此功能需要设备硬件支持，若设备不支持将返回801错误码
- **权限要求**：操作手需要`ohos.permission.ACTIVITY_MOTION`或`ohos.permission.DETECT_GESTURE`权限；握持手需要`ohos.permission.DETECT_GESTURE`权限
- **场景限制**：
  - 操作手：不包含距离屏幕边缘8mm内区域；窗口旋转、多指同时操作不支持
  - 握持手：设备需亮屏且解锁；保护壳厚度不超过3mm；需五指自然握持；不支持异常姿态识别
- **API版本**：操作手从API version 15开始支持，握持手从API version 20开始支持

## 调用规范和规则

### 输入约束
- **权限配置**：必须在module.json5中声明相应权限
  - 操作手：`ohos.permission.ACTIVITY_MOTION` 或 `ohos.permission.DETECT_GESTURE`
  - 握持手：`ohos.permission.DETECT_GESTURE`
- **设备能力**：设备必须支持动作感知硬件能力
- **用户授权**：user_grant权限需要用户手动授权
- **系统状态**：握持手功能需要设备亮屏且解锁

### 执行约束
- **订阅次数**：建议同一功能只订阅一次，避免重复订阅
- **回调处理**：回调函数必须正确处理错误情况
- **资源释放**：不再使用时应及时取消订阅
- **最大耗时**：API调用为同步或异步操作，通常在100ms内返回
- **错误重试**：服务异常时建议间隔1秒重试，最多重试3次

### 内容约束
- **禁止高危操作**：禁止在回调中执行耗时操作（超过100ms）
- **线程安全**：回调可能在非UI线程执行，需注意线程安全
- **内存管理**：避免在回调中创建大量对象导致内存泄漏
- **异常处理**：必须捕获并处理所有可能的异常

### 降级约束
- **权限不足**：提示用户授权，引导用户到设置页面
- **设备不支持**：返回801错误码，应用应提供功能降级或提示用户
- **服务异常**：间隔1秒重试，连续失败3次后停止尝试并记录日志
- **订阅失败**：重试订阅，失败后提示用户稍后再试
- **识别失败**：返回UNKNOWN_STATUS，应用应提供默认行为

## 调用流程和步骤

### 步骤1：准备阶段 - 配置权限

**前置校验**：
1. 检查module.json5文件是否已配置
2. 检查是否声明了所需权限
3. 确认目标设备支持动作感知能力

**权限配置示例**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACTIVITY_MOTION",
        "reason": "$string:motion_permission_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.DETECT_GESTURE",
        "reason": "$string:gesture_permission_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**字符串资源文件（string.json）**：
```json
{
  "string": [
    {
      "name": "motion_permission_reason",
      "value": "用于识别您的操作手，提供更好的单手操作体验"
    },
    {
      "name": "gesture_permission_reason",
      "value": "用于识别您的手势和握持姿态，提供更智能的交互体验"
    }
  ]
}
```

### 步骤2：订阅操作手状态变化

**完整示例代码**：
```typescript
import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义操作手状态枚举说明
const OperatingHandStatusDesc = {
  [motion.OperatingHandStatus.UNKNOWN_STATUS]: '未识别',
  [motion.OperatingHandStatus.LEFT_HAND_OPERATED]: '左手操作',
  [motion.OperatingHandStatus.RIGHT_HAND_OPERATED]: '右手操作'
};

// 定义回调函数
let operatingHandCallback: Callback<motion.OperatingHandStatus> = 
  (data: motion.OperatingHandStatus) => {
    console.info(`操作手状态变化: ${OperatingHandStatusDesc[data]}`);
    // 根据状态执行业务逻辑
    switch (data) {
      case motion.OperatingHandStatus.LEFT_HAND_OPERATED:
        console.info('检测到左手操作，调整UI布局');
        break;
      case motion.OperatingHandStatus.RIGHT_HAND_OPERATED:
        console.info('检测到右手操作，调整UI布局');
        break;
      case motion.OperatingHandStatus.UNKNOWN_STATUS:
        console.warn('未能识别操作手');
        break;
    }
  };

// 订阅操作手状态变化
try {
  motion.on('operatingHandChanged', operatingHandCallback);
  console.info('订阅操作手状态成功');
} catch (err) {
  let error = err as BusinessError;
  console.error(`订阅操作手状态失败，错误码: ${error.code}, 错误信息: ${error.message}`);
  
  // 错误处理
  switch (error.code) {
    case 201:
      console.error('权限不足，请申请ohos.permission.ACTIVITY_MOTION或ohos.permission.DETECT_GESTURE权限');
      break;
    case 801:
      console.error('当前设备不支持操作手识别功能');
      break;
    case 31500001:
      console.error('服务异常，请稍后重试');
      break;
    case 31500002:
      console.error('订阅失败，请重试');
      break;
    default:
      console.error(`未知错误: ${error.message}`);
  }
}
```

### 步骤3：获取最新操作手状态

**完整示例代码**：
```typescript
import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 获取最新操作手状态
function getLatestOperatingHandStatus(): motion.OperatingHandStatus | null {
  try {
    let status: motion.OperatingHandStatus = motion.getRecentOperatingHandStatus();
    console.info(`当前操作手状态: ${status}`);
    return status;
  } catch (err) {
    let error = err as BusinessError;
    console.error(`获取操作手状态失败，错误码: ${error.code}, 错误信息: ${error.message}`);
    
    // 错误处理
    switch (error.code) {
      case 201:
        console.error('权限不足');
        break;
      case 801:
        console.error('设备不支持');
        break;
      case 31500001:
        console.error('服务异常');
        break;
      default:
        console.error(`未知错误: ${error.message}`);
    }
    return null;
  }
}

// 使用示例
let latestStatus = getLatestOperatingHandStatus();
if (latestStatus !== null) {
  // 根据状态执行业务逻辑
  console.info(`当前操作手: ${OperatingHandStatusDesc[latestStatus]}`);
}
```

### 步骤4：取消订阅操作手状态

**完整示例代码**：
```typescript
import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消订阅所有操作手状态变化回调
try {
  motion.off('operatingHandChanged');
  console.info('取消订阅操作手状态成功');
} catch (err) {
  let error = err as BusinessError;
  console.error(`取消订阅失败，错误码: ${error.code}, 错误信息: ${error.message}`);
  
  // 错误处理
  switch (error.code) {
    case 201:
      console.error('权限不足');
      break;
    case 801:
      console.error('设备不支持');
      break;
    case 31500001:
      console.error('服务异常');
      break;
    case 31500003:
      console.error('取消订阅失败');
      break;
    default:
      console.error(`未知错误: ${error.message}`);
  }
}

// 取消订阅特定回调函数
// motion.off('operatingHandChanged', operatingHandCallback);
```

### 步骤5：订阅握持手状态变化（API version 20+）

**完整示例代码**：
```typescript
import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义握持手状态枚举说明
const HoldingHandStatusDesc = {
  [motion.HoldingHandStatus.NOT_HELD]: '未握持',
  [motion.HoldingHandStatus.LEFT_HAND_HELD]: '左手握持',
  [motion.HoldingHandStatus.RIGHT_HAND_HELD]: '右手握持',
  [motion.HoldingHandStatus.BOTH_HANDS_HELD]: '双手握持',
  [motion.HoldingHandStatus.UNKNOWN_STATUS]: '未识别'
};

// 定义回调函数
let holdingHandCallback: Callback<motion.HoldingHandStatus> = 
  (data: motion.HoldingHandStatus) => {
    console.info(`握持手状态变化: ${HoldingHandStatusDesc[data]}`);
    // 根据状态执行业务逻辑
    switch (data) {
      case motion.HoldingHandStatus.LEFT_HAND_HELD:
        console.info('检测到左手握持');
        break;
      case motion.HoldingHandStatus.RIGHT_HAND_HELD:
        console.info('检测到右手握持');
        break;
      case motion.HoldingHandStatus.BOTH_HANDS_HELD:
        console.info('检测到双手握持');
        break;
      case motion.HoldingHandStatus.NOT_HELD:
        console.info('设备未被握持');
        break;
      case motion.HoldingHandStatus.UNKNOWN_STATUS:
        console.warn('未能识别握持状态');
        break;
    }
  };

// 订阅握持手状态变化
try {
  motion.on('holdingHandChanged', holdingHandCallback);
  console.info('订阅握持手状态成功');
} catch (err) {
  let error = err as BusinessError;
  console.error(`订阅握持手状态失败，错误码: ${error.code}, 错误信息: ${error.message}`);
  
  // 错误处理
  switch (error.code) {
    case 201:
      console.error('权限不足，请申请ohos.permission.DETECT_GESTURE权限');
      break;
    case 801:
      console.error('当前设备不支持握持手识别功能');
      break;
    case 31500001:
      console.error('服务异常，请稍后重试');
      break;
    case 31500002:
      console.error('订阅失败，请重试');
      break;
    default:
      console.error(`未知错误: ${error.message}`);
  }
}
```

### 步骤6：取消订阅握持手状态

**完整示例代码**：
```typescript
import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消订阅所有握持手状态变化回调
try {
  motion.off('holdingHandChanged');
  console.info('取消订阅握持手状态成功');
} catch (err) {
  let error = err as BusinessError;
  console.error(`取消订阅失败，错误码: ${error.code}, 错误信息: ${error.message}`);
  
  // 错误处理
  switch (error.code) {
    case 201:
      console.error('权限不足');
      break;
    case 801:
      console.error('设备不支持');
      break;
    case 31500001:
      console.error('服务异常');
      break;
    case 31500003:
      console.error('取消订阅失败');
      break;
    default:
      console.error(`未知错误: ${error.message}`);
  }
}
```

### 步骤7：错误处理和降级方案

**完整错误处理示例**：
```typescript
import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

class MotionManager {
  private static instance: MotionManager;
  private operatingHandCallback: Callback<motion.OperatingHandStatus> | null = null;
  private holdingHandCallback: Callback<motion.HoldingHandStatus> | null = null;
  private retryCount: number = 0;
  private maxRetryCount: number = 3;
  
  static getInstance(): MotionManager {
    if (!MotionManager.instance) {
      MotionManager.instance = new MotionManager();
    }
    return MotionManager.instance;
  }
  
  // 订阅操作手状态（带重试机制）
  async subscribeOperatingHandWithRetry(
    callback: Callback<motion.OperatingHandStatus>
  ): Promise<boolean> {
    this.operatingHandCallback = callback;
    
    while (this.retryCount < this.maxRetryCount) {
      try {
        motion.on('operatingHandChanged', callback);
        console.info('订阅操作手状态成功');
        this.retryCount = 0;
        return true;
      } catch (err) {
        let error = err as BusinessError;
        console.error(`订阅失败，错误码: ${error.code}`);
        
        // 权限错误和设备不支持不需要重试
        if (error.code === 201 || error.code === 801) {
          return false;
        }
        
        // 服务异常，延迟重试
        this.retryCount++;
        if (this.retryCount < this.maxRetryCount) {
          console.info(`将在1秒后重试，当前重试次数: ${this.retryCount}`);
          await this.delay(1000);
        }
      }
    }
    
    console.error('订阅失败，已达最大重试次数');
    return false;
  }
  
  // 取消订阅操作手状态（带重试机制）
  async unsubscribeOperatingHandWithRetry(): Promise<boolean> {
    this.retryCount = 0;
    
    while (this.retryCount < this.maxRetryCount) {
      try {
        motion.off('operatingHandChanged');
        console.info('取消订阅操作手状态成功');
        this.operatingHandCallback = null;
        return true;
      } catch (err) {
        let error = err as BusinessError;
        console.error(`取消订阅失败，错误码: ${error.code}`);
        
        // 权限错误和设备不支持不需要重试
        if (error.code === 201 || error.code === 801) {
          return false;
        }
        
        // 服务异常，延迟重试
        this.retryCount++;
        if (this.retryCount < this.maxRetryCount) {
          console.info(`将在1秒后重试，当前重试次数: ${this.retryCount}`);
          await this.delay(1000);
        }
      }
    }
    
    console.error('取消订阅失败，已达最大重试次数');
    return false;
  }
  
  // 降级方案：使用默认值
  getFallbackOperatingHandStatus(): motion.OperatingHandStatus {
    console.warn('使用降级方案：返回未知状态');
    return motion.OperatingHandStatus.UNKNOWN_STATUS;
  }
  
  // 延迟函数
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// 使用示例
const motionManager = MotionManager.getInstance();
motionManager.subscribeOperatingHandWithRetry((status) => {
  console.info(`操作手状态: ${status}`);
});
```

## 错误码说明

| 错误码 | 错误名称 | 说明 | 解决方法 |
|-------|---------|------|---------|
| 201 | 权限不足 | 缺少必要权限 | 在module.json5中声明ohos.permission.ACTIVITY_MOTION或ohos.permission.DETECT_GESTURE权限，并引导用户授权 |
| 401 | 参数错误 | 参数验证失败 | 检查参数类型和格式是否正确 |
| 801 | 设备不支持 | 当前设备不支持此功能 | 提供功能降级或提示用户设备不支持 |
| 31500001 | 服务异常 | 系统错误或N-API调用异常 | 延迟1秒后重试，最多重试3次；记录日志并上报 |
| 31500002 | 订阅失败 | 回调注册失败或IPC请求异常 | 延迟1秒后重试订阅，最多重试3次 |
| 31500003 | 取消订阅失败 | 回调失败或IPC请求异常 | 延迟1秒后重试取消订阅，最多重试3次 |

**错误处理最佳实践**：
1. **权限错误(201)**：提示用户授权，引导用户到设置页面
2. **参数错误(401)**：检查代码逻辑，确保参数正确
3. **设备不支持(801)**：提供功能降级，隐藏相关功能或显示提示
4. **服务异常(31500001)**：延迟重试，记录日志
5. **订阅失败(31500002)**：延迟重试，超过重试次数后提示用户
6. **取消订阅失败(31500003)**：延迟重试，超过重试次数后记录日志

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MultimodalAwarenessKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：API version 15+（操作手功能），API version 20+（握持手功能）
- **DevEco Studio**：3.1.0或更高版本
- **开发语言**：ArkTS（TypeScript）
- **设备要求**：支持动作感知硬件的HarmonyOS设备

### 常见编译问题

**问题1：找不到@kit.MultimodalAwarenessKit模块**
```
Error: Cannot find module '@kit.MultimodalAwarenessKit'
```
**解决方法**：
1. 确保使用API version 15或更高版本的SDK
2. 在build-profile.json5中配置正确的compileSdkVersion
3. 同步项目依赖：File -> Sync and Refresh Project

**问题2：权限声明无效**
```
Error: Permission ohos.permission.ACTIVITY_MOTION is not granted
```
**解决方法**：
1. 检查module.json5中是否正确声明权限
2. user_grant权限需要运行时申请
3. 检查权限名称拼写是否正确

**问题3：API不存在**
```
Error: Property 'on' does not exist on type 'typeof motion'
```
**解决方法**：
1. 确认SDK版本是否支持该API
2. 操作手功能需要API version 15+
3. 握持手功能需要API version 20+
4. 在代码中添加API版本检查

**问题4：回调函数类型错误**
```
Error: Type 'Callback<OperatingHandStatus>' is not assignable to type 'Callback<HoldingHandStatus>'
```
**解决方法**：
1. 检查回调函数的参数类型是否正确
2. 操作手使用`Callback<motion.OperatingHandStatus>`
3. 握持手使用`Callback<motion.HoldingHandStatus>`

## 常见问题与解决方法

### Q1：订阅操作手状态后没有收到回调
**原因**：
- 设备不支持操作手识别功能
- 用户未进行屏幕操作
- 操作区域在屏幕边缘8mm范围内
- 权限未授予

**解决方法**：
1. 检查错误码是否为801（设备不支持）
2. 引导用户在屏幕中心区域进行操作
3. 检查权限是否已授予
4. 确认用户操作符合要求（非指关节操作、非多指同时操作）

### Q2：获取到的状态一直是UNKNOWN_STATUS
**原因**：
- 用户操作方式不符合要求
- 设备传感器异常
- 用户操作区域在边缘8mm范围内

**解决方法**：
1. 提示用户在屏幕中心区域操作
2. 确保用户使用手指（非指关节）操作
3. 避免多指同时操作
4. 检查设备是否支持该功能

### Q3：订阅握持手状态时报801错误
**原因**：
- 设备不支持握持手识别功能
- API版本低于20

**解决方法**：
1. 检查设备是否支持"智感握姿"功能（设置-系统中查看）
2. 确认API版本是否为20或更高
3. 提供降级方案或隐藏该功能

### Q4：订阅握持手状态后识别不准确
**原因**：
- 设备保护壳过厚
- 握持姿势不标准
- 戴着手套
- 设备处于异常姿态

**解决方法**：
1. 提示用户使用厚度不超过3mm的保护壳
2. 引导用户五指自然握持，确保掌心接触设备
3. 提示用户摘下手套
4. 确保设备屏幕朝向握持人
5. 避免同时接触其他物体

### Q5：如何处理运行时权限申请
**原因**：
- ohos.permission.ACTIVITY_MOTION和ohos.permission.DETECT_GESTURE是user_grant权限
- 需要用户手动授权

**解决方法**：
```typescript
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function requestPermission(
  context: common.UIAbilityContext,
  permission: Permissions
): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  try {
    const grantStatus = await atManager.checkAccessToken(
      context.applicationInfo.accessTokenId,
      permission
    );
    
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      return true;
    }
    
    // 申请权限
    const result = await atManager.requestPermissionsFromUser(context, [permission]);
    return result.authResults[0] === 0;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`权限申请失败: ${error.message}`);
    return false;
  }
}

// 使用示例
const hasPermission = await requestPermission(
  context,
  'ohos.permission.ACTIVITY_MOTION'
);
if (hasPermission) {
  // 订阅操作手状态
  motion.on('operatingHandChanged', callback);
} else {
  console.error('用户拒绝授权');
}
```

### Q6：如何判断设备是否支持该功能
**原因**：
- 不同设备硬件能力不同
- 需要在运行时判断设备支持情况

**解决方法**：
```typescript
import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

function checkDeviceSupport(): boolean {
  try {
    // 尝试获取操作手状态，如果设备不支持会抛出801错误
    const status = motion.getRecentOperatingHandStatus();
    return true;
  } catch (err) {
    const error = err as BusinessError;
    if (error.code === 801) {
      console.warn('当前设备不支持动作感知功能');
      return false;
    }
    // 其他错误可能是权限问题，设备可能支持
    return true;
  }
}

// 使用示例
if (checkDeviceSupport()) {
  // 设备支持，可以使用该功能
  motion.on('operatingHandChanged', callback);
} else {
  // 设备不支持，提供降级方案
  console.error('当前设备不支持动作感知功能');
}
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "action": "获取用户动作状态",
  "apiUsed": [
    "motion.on('operatingHandChanged')",
    "motion.off('operatingHandChanged')",
    "motion.getRecentOperatingHandStatus()",
    "motion.on('holdingHandChanged')",
    "motion.off('holdingHandChanged')"
  ],
  "permissions": [
    "ohos.permission.ACTIVITY_MOTION",
    "ohos.permission.DETECT_GESTURE"
  ],
  "apiVersion": {
    "operatingHand": "15+",
    "holdingHand": "20+"
  },
  "result": {
    "operatingHandStatus": "LEFT_HAND_OPERATED | RIGHT_HAND_OPERATED | UNKNOWN_STATUS",
    "holdingHandStatus": "NOT_HELD | LEFT_HAND_HELD | RIGHT_HAND_HELD | BOTH_HANDS_HELD | UNKNOWN_STATUS"
  }
}
```

## 参考文档

- [获取用户动作开发指导](references/motion-guidelines.md)
- [API参考说明 - @ohos.multimodalAwareness.motion](references/js-apis-awareness-motion.md)
- [错误码说明](references/errorcode-motion.md)
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)

## 完整示例代码

- [操作手状态订阅示例](assets/operating-hand-subscribe.ets)
- [握持手状态订阅示例](assets/holding-hand-subscribe.ets)
- [完整业务逻辑示例](assets/motion-manager.ets)
- [权限申请示例](assets/permission-request.ets)
- [module.json5配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [订阅操作手状态成功](tests/test_operating_hand_subscribe_success.ets)
- [获取最新操作手状态成功](tests/test_get_recent_status_success.ets)
- [取消订阅操作手状态成功](tests/test_operating_hand_unsubscribe_success.ets)
- [订阅握持手状态成功](tests/test_holding_hand_subscribe_success.ets)

### 边界测试用例
- [权限未授予时的处理](tests/test_permission_denied.ets)
- [设备不支持时的处理](tests/test_device_not_support.ets)
- [多次订阅同一回调](tests/test_multiple_subscribe.ets)
- [取消未订阅的事件](tests/test_unsubscribe_without_subscribe.ets)

### 异常测试用例
- [服务异常重试机制](tests/test_service_exception_retry.ets)
- [订阅失败重试机制](tests/test_subscribe_failed_retry.ets)
- [参数错误处理](tests/test_invalid_parameters.ets)
- [网络异常处理](tests/test_network_exception.ets)