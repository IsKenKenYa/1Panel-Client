---
name: hmos-wear-engine-kit-request-authorization
description: 请求Wear Engine服务用户授权,支持申请和查询权限,需华为账号登录且已申请接入Wear Engine服务,适用于手机侧应用首次使用穿戴设备能力前的权限申请场景
---

# 请求用户授权技能

## 功能描述

本技能用于实现Wear Engine服务的用户授权功能,包括申请穿戴设备权限和查询已授权权限。Wear Engine的API需要用户授权才能正常访问,建议开发者在用户首次调用Wear Engine开放能力时执行权限申请操作。

**核心能力**:
- 申请用户穿戴设备权限:拉起华为账号登录和授权界面,由用户授权相应的数据访问权限
- 查询用户授权结果:查询已被用户授予的应用权限

**适用场景**:
- 手机侧应用首次使用Wear Engine能力前
- 需要访问穿戴设备用户状态、传感器数据等隐私数据
- 检查应用是否已获得必要权限

**权限类型**:
- USER_STATUS: 获取用户状态权限(如穿戴设备佩戴状态)
- MOTION_SENSOR: 获取运动传感器数据权限(如加速度传感器数据)
- HEALTH_SENSOR: 获取人体传感器数据权限(如心率传感器数据)
- DEVICE_IDENTIFIER: 获取已连接穿戴设备的序列号

## 使用场景

### 触发词
- "请求用户授权"
- "申请穿戴设备权限"
- "查询用户权限"
- "Wear Engine授权"
- "申请USER_STATUS权限"
- "检查授权状态"

### 能做
- 拉起华为账号登录和授权界面,申请穿戴设备权限
- 查询应用已获得的用户授权权限
- 处理用户授权/拒绝授权的结果
- 在首次使用Wear Engine能力前主动申请权限
- 判断是否需要重新申请权限

### 绝不做
- 未申请接入Wear Engine服务时申请权限(会返回错误码1008500004)
- 未登录华为账号时强制申请权限(会返回错误码1008500008)
- 申请未在接入服务中审批通过的权限
- 在不支持Wear Engine的设备上调用(非Phone/Tablet设备会返回错误码801)
- 在非Stage模型环境中使用

### 补充
- 用户可以自主选择授权的数据类型,可以只授权部分权限
- 如果申请的权限之前已经授予,不会再弹出授权页面,接口会返回已授权的权限
- 建议在请求用户授权前,先使用查询接口判断应用是否已有相关权限
- 申请权限前必须先完成接入Wear Engine服务的申请流程

## 调用规范和规则

### 输入约束
- **Context要求**: 必须提供包含connectServiceExtensionAbility方法的Context(如UIAbilityContext)
- **权限类型**: 只能申请已在Wear Engine服务接入申请中审批通过的权限类型
- **设备类型**: 仅支持Phone和Tablet设备,其他设备会返回错误码801
- **运行模型**: 仅支持Stage模型

### 执行约束
- **前置条件**: 
  - 必须已申请接入Wear Engine服务
  - 用户需登录华为账号(未登录会弹出登录界面)
- **调用时机**: 建议在首次使用Wear Engine能力前调用
- **用户交互**: 申请权限时会拉起授权界面,需要用户手动授权
- **网络要求**: 需要网络连接,网络不可用会返回错误码1008500001

### 内容约束
- **禁止操作**: 
  - 不能绕过用户授权流程直接访问数据
  - 不能申请未审批通过的权限
  - 不能在用户拒绝后频繁重复申请
- **权限范围**: 只能申请USER_STATUS、MOTION_SENSOR、HEALTH_SENSOR、DEVICE_IDENTIFIER四种权限
- **隐私保护**: 必须明确告知用户申请权限的用途

### 降级约束
- **用户拒绝授权**: 返回已授权的权限列表(可能为空),应用应提示用户必要权限未授予
- **网络失败**: 提示用户检查网络连接,建议提供离线提示或稍后重试选项
- **未登录账号**: 自动拉起登录界面,用户取消登录则返回错误码1008500008
- **未申请服务**: 提示开发者先申请接入Wear Engine服务(错误码1008500004)
- **设备不支持**: 在非Phone/Tablet设备上返回错误码801,应用应做兼容处理

## 调用流程和步骤

### 步骤1: 准备阶段 - 导入模块和获取客户端

**前置校验**:
1. 确认应用已申请接入Wear Engine服务
2. 确认当前设备类型为Phone或Tablet
3. 确认运行环境为Stage模型
4. 准备UIAbilityContext上下文对象

**参数准备**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

// 获取AuthClient对象
let authClient: wearEngine.AuthClient = wearEngine.getAuthClient(this.getUIContext().getHostContext());
```

### 步骤2: 申请用户授权

**示例代码**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

async function requestUserAuthorization(context: common.UIAbilityContext): Promise<void> {
  try {
    // 步骤1: 获取AuthClient对象
    let authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
    
    // 步骤2: 定义需要申请的权限
    let request: wearEngine.AuthorizationRequest = {
      permissions: [
        wearEngine.Permission.USER_STATUS,      // 用户状态权限
        wearEngine.Permission.HEALTH_SENSOR     // 健康传感器权限
      ]
    };
    
    // 步骤3: 请求用户授权
    const result = await authClient.requestAuthorization(request);
    
    console.info(`Succeeded in requesting authorization, authorized permissions: ${JSON.stringify(result.permissions)}`);
    
    // 步骤4: 检查授权结果
    if (result.permissions.length === 0) {
      console.warn('User denied all permissions');
      // 降级处理: 提示用户需要权限才能使用功能
    } else if (result.permissions.length < request.permissions.length) {
      console.warn('User only authorized partial permissions');
      // 降级处理: 提示用户部分权限未授予,部分功能可能受限
    } else {
      console.info('All permissions authorized');
      // 正常流程: 继续使用Wear Engine功能
    }
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to request authorization. Code: ${err.code}, Message: ${err.message}`);
    
    // 错误处理
    switch (err.code) {
      case 1008500001:
        console.error('Network error. Please check network connection.');
        break;
      case 1008500004:
        console.error('App has not applied for the Wear Engine service.');
        break;
      case 1008500006:
        console.error('User privacy is not agreed.');
        break;
      case 1008500008:
        console.error('User has not logged in with HUAWEI ID.');
        break;
      default:
        console.error('Unknown error occurred.');
    }
  }
}
```

### 步骤3: 查询已授权权限

**示例代码**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

async function queryUserAuthorization(context: common.UIAbilityContext): Promise<void> {
  try {
    // 步骤1: 获取AuthClient对象
    let authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
    
    // 步骤2: 查询已授权的权限
    const result = await authClient.getAuthorization();
    
    console.info(`Succeeded in getting authorized permissions: ${JSON.stringify(result.permissions)}`);
    
    // 步骤3: 判断是否包含所需权限
    const requiredPermissions = [wearEngine.Permission.USER_STATUS];
    const hasAllPermissions = requiredPermissions.every(perm => 
      result.permissions.includes(perm)
    );
    
    if (hasAllPermissions) {
      console.info('All required permissions are authorized');
      // 正常流程: 可以直接使用Wear Engine功能
    } else {
      console.warn('Missing some required permissions');
      // 需要申请权限: 调用requestAuthorization
      await requestUserAuthorization(context);
    }
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to get authorization. Code: ${err.code}, Message: ${err.message}`);
  }
}
```

### 步骤4: 完整示例 - 权限检查和申请流程

**示例代码**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export class WearEngineAuthHelper {
  private authClient: wearEngine.AuthClient | null = null;
  
  constructor(private context: common.UIAbilityContext) {}
  
  // 初始化AuthClient
  private initAuthClient(): void {
    if (!this.authClient) {
      this.authClient = wearEngine.getAuthClient(this.context);
    }
  }
  
  // 检查并申请权限
  async ensurePermissions(permissions: wearEngine.Permission[]): Promise<boolean> {
    this.initAuthClient();
    
    try {
      // 先查询已授权权限
      const authResult = await this.authClient!.getAuthorization();
      console.info(`Current authorized permissions: ${JSON.stringify(authResult.permissions)}`);
      
      // 检查是否已包含所需权限
      const missingPermissions = permissions.filter(perm => 
        !authResult.permissions.includes(perm)
      );
      
      if (missingPermissions.length === 0) {
        console.info('All permissions are already authorized');
        return true;
      }
      
      // 申请缺失的权限
      console.info(`Requesting missing permissions: ${JSON.stringify(missingPermissions)}`);
      const requestResult = await this.authClient!.requestAuthorization({
        permissions: missingPermissions
      });
      
      // 再次检查是否所有权限都已授予
      const allGranted = permissions.every(perm => 
        requestResult.permissions.includes(perm)
      );
      
      if (allGranted) {
        console.info('All permissions granted');
        return true;
      } else {
        console.warn('Some permissions were not granted');
        return false;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to ensure permissions. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }
  
  // 获取当前已授权权限
  async getCurrentPermissions(): Promise<wearEngine.Permission[]> {
    this.initAuthClient();
    
    try {
      const result = await this.authClient!.getAuthorization();
      return result.permissions;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to get current permissions. Code: ${err.code}, Message: ${err.message}`);
      return [];
    }
  }
}

// 使用示例
async function exampleUsage() {
  const helper = new WearEngineAuthHelper(this.getUIContext().getHostContext());
  
  // 确保拥有用户状态和健康传感器权限
  const success = await helper.ensurePermissions([
    wearEngine.Permission.USER_STATUS,
    wearEngine.Permission.HEALTH_SENSOR
  ]);
  
  if (success) {
    console.log('Permissions ready, can use Wear Engine features');
    // 继续使用其他Wear Engine API
  } else {
    console.log('Permissions not ready, please grant permissions');
    // 提示用户授权
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | 参数错误 | 必填参数未指定、参数类型错误、参数验证失败 | 检查参数类型和必填项,确保AuthorizationRequest.permissions数组不为空 |
| 801 | 能力不支持 | 当前设备不支持此系统能力 | 在非Phone/Tablet设备上调用会返回此错误,需做设备兼容处理 |
| 1008500001 | 网络错误 | 网络不可用 | 提示用户检查网络连接,稍后重试 |
| 1008500004 | 未申请服务 | 应用未申请接入Wear Engine服务 | 先在华为开发者平台申请接入Wear Engine服务 |
| 1008500006 | 用户隐私未同意 | 用户未同意隐私协议 | 拉起授权界面时需用户同意隐私协议 |
| 1008500007 | 设备能力不支持 | 设备不支持该能力 | 检查设备是否支持所需能力 |
| 1008500008 | 账号未登录 | 用户未登录华为账号 | 会自动拉起登录界面,用户取消登录则返回此错误 |
| 1008500009 | 获取账号信息失败 | 无法获取华为账号信息 | 提示用户重新登录华为账号 |
| 1008509999 | 内部错误 | 系统内部错误 | 记录日志并上报问题,建议用户稍后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "name": "wear-engine-example",
  "version": "1.0.0",
  "dependencies": {
    "@kit.WearEngine": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0",
    "@kit.AbilityKit": "^5.0.0"
  }
}
```

### 环境要求
- **HarmonyOS SDK**: 最低版本 5.0.0(12)
- **设备类型**: Phone、Tablet(其他设备返回错误码801)
- **运行模型**: Stage模型
- **系统能力**: SystemCapability.Health.WearEngine

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**: 
- 确保HarmonyOS SDK版本 >= 5.0.0(12)
- 检查module.json5中是否添加了依赖
- 运行`ohpm install`安装依赖

**问题2: Context类型错误**
```
Error: Parameter error. Incorrect parameter types.
```
**解决方法**: 
- 确保传入的context是UIAbilityContext类型
- 使用`this.getUIContext().getHostContext()`获取正确的Context
- 不要使用ApplicationContext或其他不支持的Context类型

**问题3: 权限配置缺失**
```
Error: App has not applied for the Wear Engine service.
```
**解决方法**: 
- 检查module.json5中是否配置了所需权限
- 确认已在华为开发者平台申请接入Wear Engine服务
- 确认申请的权限类型已在服务接入申请中审批通过

**问题4: 设备能力检查失败**
```
Error: Capability not supported.
```
**解决方法**: 
- 使用`canIUse('SystemCapability.Health.WearEngine')`检查设备是否支持
- 在不支持Wear Engine的设备上提供降级方案

## 常见问题与解决方法

### Q1: 用户拒绝授权后如何处理?
**原因**: 用户在授权界面点击拒绝或取消
**解决方法**:
- `requestAuthorization`会返回用户已授权的权限列表(可能为空数组)
- 检查返回的`result.permissions`数组长度
- 如果必要权限未授予,提示用户功能受限或引导用户到系统设置手动授权
- 避免频繁重复申请权限,以免骚扰用户

### Q2: 如何判断是否需要重新申请权限?
**原因**: 用户可能之前已授权部分权限
**解决方法**:
- 先调用`getAuthorization()`查询已授权权限
- 对比已授权权限和所需权限
- 只申请缺失的权限,避免重复弹出授权界面
- 参考"步骤4: 完整示例"中的`ensurePermissions`方法

### Q3: 为什么返回错误码1008500004?
**原因**: 应用未申请接入Wear Engine服务
**解决方法**:
- 在华为开发者平台申请接入Wear Engine服务
- 等待服务审批通过后再调用API
- 参考[申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)

### Q4: 设备不支持Wear Engine怎么办?
**原因**: 在非Phone/Tablet设备上调用API
**解决方法**:
- 使用`canIUse('SystemCapability.Health.WearEngine')`检查设备能力
- 在不支持Wear Engine的设备上隐藏相关功能入口
- 提供降级方案或提示用户更换设备

### Q5: 如何处理多设备场景?
**原因**: 用户可能绑定多个穿戴设备
**解决方法**:
- 权限是针对应用级别的,不是针对设备级别
- 申请一次权限后,可以访问所有已绑定设备的数据
- 使用`getConnectedDevices()`获取已绑定设备列表
- 每个设备的数据访问需要单独检查设备能力

### Q6: 用户未登录华为账号怎么办?
**原因**: Wear Engine服务依赖华为账号体系
**解决方法**:
- 调用`requestAuthorization`时会自动拉起登录界面
- 用户取消登录会返回错误码1008500008
- 提示用户需要登录华为账号才能使用功能
- 可以引导用户到系统设置中登录华为账号

## 输出结果报告

执行完成后输出以下信息:

```typescript
interface AuthorizationResult {
  // 授权状态
  status: 'success' | 'partial' | 'denied' | 'error';
  
  // 已授权的权限列表
  authorizedPermissions: wearEngine.Permission[];
  
  // 申请的权限列表
  requestedPermissions: wearEngine.Permission[];
  
  // 错误信息(如有)
  error?: {
    code: number;
    message: string;
  };
  
  // 使用的API列表
  apiUsed: string[];
}

// 示例输出
{
  status: 'success',
  authorizedPermissions: [
    wearEngine.Permission.USER_STATUS,
    wearEngine.Permission.HEALTH_SENSOR
  ],
  requestedPermissions: [
    wearEngine.Permission.USER_STATUS,
    wearEngine.Permission.HEALTH_SENSOR
  ],
  apiUsed: [
    'wearEngine.getAuthClient',
    'authClient.requestAuthorization'
  ]
}
```

## 参考文档

- [API开发指南 - 请求用户授权](references/request_user_authorization.md)
- [API参考文档 - wearEngine](references/wearengine_api.md)
- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)

## 完整示例代码

- [ArkTS示例 - 权限申请和查询](assets/wear_engine_auth_example.ets)
- [ArkTS示例 - 权限管理工具类](assets/wear_engine_auth_helper.ets)
- [配置示例 - module.json5权限配置](assets/module_config.json)

## 测试用例

### 正向测试用例
- [申请单个权限成功](tests/test_positive.ets): 测试申请USER_STATUS权限成功场景
- [申请多个权限成功](tests/test_positive.ets): 测试同时申请多个权限成功场景
- [查询已授权权限](tests/test_positive.ets): 测试查询已授权权限列表成功场景
- [重复申请权限](tests/test_positive.ets): 测试已授权权限不会重复弹出授权界面

### 边界测试用例
- [申请空权限列表](tests/test_boundary.ets): 测试申请空权限数组的边界情况
- [申请全部权限](tests/test_boundary.ets): 测试申请所有支持的权限类型
- [部分权限授权](tests/test_boundary.ets): 测试用户只授权部分权限的场景

### 异常测试用例
- [未登录华为账号](tests/test_exception.ets): 测试未登录账号时的错误处理
- [网络不可用](tests/test_exception.ets): 测试网络错误时的降级处理
- [未申请Wear Engine服务](tests/test_exception.ets): 测试未申请服务时的错误处理
- [不支持的设备类型](tests/test_exception.ets): 测试在非Phone/Tablet设备上的错误处理
- [参数错误](tests/test_exception.ets): 测试传入错误参数时的错误处理