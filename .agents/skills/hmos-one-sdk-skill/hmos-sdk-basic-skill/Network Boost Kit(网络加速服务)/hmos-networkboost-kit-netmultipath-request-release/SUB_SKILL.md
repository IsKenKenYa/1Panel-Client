---
name: hmos-networkboost-kit-netmultipath-request-release
description: 发起和释放多网并发请求，支持WiFi和蜂窝并发、主卡和副卡并发，并发组合由系统决定，最大配额限制，适用于网络加速、弱网优化场景
---

# 多网发起和释放技能

## 功能描述

本技能提供HarmonyOS多网并发请求和释放能力，允许应用根据业务需求和系统建议发起多网络加速请求，支持WiFi和蜂窝并发以及主卡和副卡并发。并发组合由系统决定，开发者不能指定。主要功能包括：

- 发起多网请求：通过`requestMultiPath`接口请求系统建立多网并发链路
- 释放多网请求：通过`releaseMultiPath`接口释放已建立的多网并发链路
- 监听多网状态：通过订阅`multiPathStateChange`事件获取多网状态变化信息
- 查询配额信息：通过`getMultiPathQuotaStats`接口查询多网配额使用情况

**关键限制**：
- 主卡和副卡并发需要开启智能切换上网卡开关，并依赖主卡和副卡驻留网络的频点
- 受限于硬件，部分设备不支持双卡场景下的多网并发
- 多网发起需要开启网络加速开关（设置->移动网络->网络加速->允许使用移动数据加速网络）
- 需要申请`ohos.permission.LINKTURBO`权限
- API版本要求：6.0.0(20)及以上

## 使用场景

### 触发词
- "发起多网请求"
- "请求多网并发"
- "释放多网"
- "多网加速"
- "WiFi蜂窝并发"
- "双卡并发"
- "网络加速"
- "弱网优化"

### 能做
- 发起多网并发请求，支持WiFi和蜂窝并发以及主卡和副卡并发
- 释放已建立的多网并发链路
- 监听多网状态变化（建立中、已建立、释放中、空闲）
- 查询多网配额使用情况（已使用次数、时长，剩余次数、时长）
- 订阅系统多网推荐信息

### 绝不做
- 不支持开发者指定并发组合（WiFi+蜂窝或主卡+副卡由系统决定）
- 不支持在不支持多网并发的设备上强制发起多网请求
- 不支持在未开启网络加速开关的情况下发起多网请求
- 不支持超出配额限制的多网请求
- 不支持在功耗限制或流量不足时发起多网请求

### 补充
- 如果要使用的传输协议接口不支持指定网络，则新发起的网络无法使用（如HTTP当前只支持默认网络传输，不支持指定网络）
- 多网请求可能因网络条件、功耗限制、配额耗尽等原因失败，需要处理失败场景
- 多网状态可能因系统策略（功耗、流量、用户操作等）被动释放，需监听状态变化
- 建议在业务流程开始时发起多网请求，在业务流程结束时释放多网请求
- 多网并发期间建议监听`multiPathStateChange`事件以获取状态变化通知

## 调用规范和规则

### 输入约束
- **权限要求**：必须申请`ohos.permission.LINKTURBO`权限
- **系统设置**：必须开启网络加速开关（设置->移动网络->网络加速->允许使用移动数据加速网络）
- **设备支持**：设备硬件需支持多网并发能力
- **API版本**：HarmonyOS 6.0.0(20)及以上
- **回调函数**：必须提供有效的回调函数接收多网请求结果

### 执行约束
- **最大请求次数**：受配额限制，可通过`getMultiPathQuotaStats`查询
- **最大并发时长**：受配额限制，可通过`getMultiPathQuotaStats`查询
- **请求频率限制**：避免频繁发起和释放多网请求（错误码1013620006）
- **业务生命周期**：建议在业务流程结束后及时释放多网，避免长时间占用资源

### 内容约束
- 禁止在后台长时间占用多网资源
- 禁止在多网请求失败后无限制重试
- 禁止忽略多网状态变化事件
- 禁止在多网已激活状态下重复发起请求

### 降级约束
- **网络条件不满足**：提示用户检查网络设置或设备支持情况
- **配额耗尽**：提示用户配额已用完，等待系统刷新配额
- **功耗限制**：提示用户当前功耗限制不允许发起多网，建议稍后重试
- **流量不足**：提示用户流量不足，无法发起多网请求
- **设备不支持**：提示用户当前设备不支持多网并发功能
- **权限不足**：引导用户授予`ohos.permission.LINKTURBO`权限

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备API版本是否≥6.0.0(20)
2. 检查是否已申请`ohos.permission.LINKTURBO`权限
3. 检查网络加速开关是否已开启
4. （可选）查询多网配额使用情况，确认有剩余配额

**权限申请**：
```typescript
// 在module.json5中声明权限
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO",
        "reason": "用于发起多网并发请求，提升网络性能",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**模块导入**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：查询配额（可选）

**示例代码**：
```typescript
/**
 * 查询多网配额使用情况
 * @returns 多网配额信息
 */
function checkMultiPathQuota(): netHandover.MultiPathQuota | null {
  try {
    const quota = netHandover.getMultiPathQuotaStats();
    console.info(`已使用次数: ${quota.used.count}, 已使用时长: ${quota.used.duration}秒`);
    console.info(`剩余次数: ${quota.remaining.count}, 剩余时长: ${quota.remaining.duration}秒`);
    
    // 检查是否有剩余配额
    if (quota.remaining.count <= 0) {
      console.warn('多网配额已用完，无法发起多网请求');
      return null;
    }
    
    return quota;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`查询配额失败: errCode=${error.code}, errMessage=${error.message}`);
    return null;
  }
}
```

### 步骤3：订阅多网状态变化（推荐）

**示例代码**：
```typescript
/**
 * 订阅多网状态变化事件
 */
function subscribeMultiPathState(): void {
  try {
    netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
      console.info(`多网状态变化: state=${data.multiPathState}, cause=${data.cause}`);
      console.info(`链路类型: ${data.pathType}, 链路状态: ${data.pathState}`);
      
      // 根据状态处理业务逻辑
      switch (data.multiPathState) {
        case netHandover.MultiPathState.MULTIPATH_CREATING:
          console.info('多网正在建立中...');
          break;
        case netHandover.MultiPathState.MULTIPATH_CREATED:
          console.info('多网已建立，可以开始使用');
          break;
        case netHandover.MultiPathState.MULTIPATH_RELEASING:
          console.info('多网正在释放中...');
          break;
        case netHandover.MultiPathState.MULTIPATH_IDLE:
          console.info('多网已释放，处于空闲状态');
          break;
      }
      
      // 根据状态变化原因处理
      handleMultiPathChangeCause(data.cause);
    });
    console.info('多网状态监听已启动');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`订阅多网状态失败: errCode=${error.code}, errMessage=${error.message}`);
  }
}

/**
 * 处理多网状态变化原因
 */
function handleMultiPathChangeCause(cause: netHandover.MultiPathChangeCause): void {
  switch (cause) {
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK:
      console.warn('网络原因导致多网释放');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA:
      console.warn('配额耗尽导致多网释放');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_POWER_CONSUMPTION:
      console.warn('功耗原因导致多网释放');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC:
      console.warn('流量不足导致多网释放');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER:
      console.warn('多网进入挂起状态，实际链路无法传输数据');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE:
      console.info('多网退出挂起状态，链路恢复正常');
      break;
  }
}
```

### 步骤4：发起多网请求

**示例代码**：
```typescript
/**
 * 发起多网请求
 * @returns Promise<boolean> 是否发起成功
 */
async function requestMultiPath(): Promise<boolean> {
  return new Promise((resolve) => {
    try {
      netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
        console.info(`多网请求结果: ${JSON.stringify(data)}`);
        
        // 检查请求结果
        if (data.result === netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
          console.info('多网请求成功');
          resolve(true);
        } else {
          handleMultiPathError(data.result);
          resolve(false);
        }
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`发起多网请求失败: errCode=${error.code}, errMessage=${error.message}`);
      handleRequestError(error.code);
      resolve(false);
    }
  });
}

/**
 * 处理多网请求错误结果
 */
function handleMultiPathError(result: netHandover.MultiPathErrorResult): void {
  switch (result) {
    case netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NETWORK_REFUSED:
      console.error('多网请求被网络拒绝');
      break;
    case netHandover.MultiPathErrorResult.MULTIPATH_ERROR_TIMEOUT:
      console.error('多网建立超时');
      break;
    case netHandover.MultiPathErrorResult.MULTIPATH_ERROR_LOCAL:
      console.error('多网建立过程中本地释放');
      break;
  }
}

/**
 * 处理请求异常错误码
 */
function handleRequestError(errorCode: number): void {
  switch (errorCode) {
    case 1013620000:
      console.error('多网功能没有使能');
      break;
    case 1013620001:
      console.error('多网已经激活或者是在激活的过程中');
      break;
    case 1013620002:
      console.error('应用多网请求已经达到上限');
      break;
    case 1013620003:
      console.error('功耗限制不允许发起多网');
      break;
    case 1013620004:
      console.error('限额耗尽');
      break;
    case 1013620005:
      console.error('多网请求场景的冲突');
      break;
    case 1013620006:
      console.error('多网发起太频繁');
      break;
    case 1013620007:
      console.error('没有合适的多网链路可用');
      break;
    case 1013620008:
      console.error('流量不足');
      break;
    case 1013620009:
      console.error('不支持并发');
      break;
  }
}
```

### 步骤5：业务流程执行

**示例代码**：
```typescript
/**
 * 使用多网并发执行业务流程
 */
async function executeBusinessWithMultiPath(): Promise<void> {
  // 1. 检查配额
  const quota = checkMultiPathQuota();
  if (!quota) {
    console.warn('配额不足，使用单网执行业务');
    await executeBusinessWithSinglePath();
    return;
  }
  
  // 2. 订阅多网状态变化
  subscribeMultiPathState();
  
  // 3. 发起多网请求
  const success = await requestMultiPath();
  if (!success) {
    console.warn('多网请求失败，使用单网执行业务');
    await executeBusinessWithSinglePath();
    return;
  }
  
  try {
    // 4. 执行业务逻辑（使用多网并发）
    console.info('开始执行业务流程（多网并发模式）');
    await performBusinessTasks();
    console.info('业务流程执行完成');
  } catch (err) {
    console.error('业务流程执行失败:', err);
  } finally {
    // 5. 释放多网资源
    await releaseMultiPath();
    
    // 6. 取消订阅多网状态变化
    unsubscribeMultiPathState();
  }
}

/**
 * 使用单网执行业务流程（降级方案）
 */
async function executeBusinessWithSinglePath(): Promise<void> {
  console.info('使用单网执行业务流程');
  await performBusinessTasks();
}

/**
 * 执行业务任务（示例）
 */
async function performBusinessTasks(): Promise<void> {
  // 在这里实现具体的业务逻辑
  // 注意：如果要使用的传输协议接口不支持指定网络，则新发起的网络无法使用
  // 例如：HTTP当前只支持默认网络传输，不支持指定网络
  
  // 模拟业务任务
  return new Promise((resolve) => {
    setTimeout(() => {
      console.info('业务任务执行完成');
      resolve();
    }, 2000);
  });
}
```

### 步骤6：释放多网请求

**示例代码**：
```typescript
/**
 * 释放多网请求
 */
async function releaseMultiPath(): Promise<void> {
  try {
    netHandover.releaseMultiPath();
    console.info('多网释放成功');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`释放多网失败: errCode=${error.code}, errMessage=${error.message}`);
    
    // 处理释放错误
    if (error.code === 1013620100) {
      console.warn('多网已经激活，但不是当前应用发起的');
    } else if (error.code === 1013620101) {
      console.warn('多网不在激活态');
    }
  }
}

/**
 * 取消订阅多网状态变化
 */
function unsubscribeMultiPathState(): void {
  try {
    netHandover.off('multiPathStateChange');
    console.info('已取消订阅多网状态变化');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`取消订阅失败: errCode=${error.code}, errMessage=${error.message}`);
  }
}
```

### 步骤7：订阅系统多网推荐（可选）

**示例代码**：
```typescript
/**
 * 订阅系统多网推荐信息
 */
function subscribeMultiPathRecommendation(): void {
  try {
    netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
      console.info(`系统多网推荐: action=${data.action}`);
      
      // 根据系统建议处理
      if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
        console.info('系统建议发起多网请求');
        // 可以在合适的时机调用 requestMultiPath()
      } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
        console.info('系统建议释放多网请求');
        // 可以在合适的时机调用 releaseMultiPath()
      }
    });
    console.info('多网推荐监听已启动');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`订阅多网推荐失败: errCode=${error.code}, errMessage=${error.message}`);
  }
}

/**
 * 取消订阅系统多网推荐
 */
function unsubscribeMultiPathRecommendation(): void {
  try {
    netHandover.off('multiPathRecommendation');
    console.info('已取消订阅多网推荐');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`取消订阅失败: errCode=${error.code}, errMessage=${error.message}`);
  }
}
```

### 步骤8：完整示例流程

**示例代码**：
```typescript
/**
 * 完整的多网并发使用示例
 */
async function completeMultiPathExample(): Promise<void> {
  console.info('=== 开始多网并发示例 ===');
  
  // 1. 检查配额
  const quota = checkMultiPathQuota();
  if (!quota || quota.remaining.count <= 0) {
    console.warn('配额不足或查询失败，无法使用多网并发');
    return;
  }
  
  // 2. 订阅系统推荐（可选）
  subscribeMultiPathRecommendation();
  
  // 3. 订阅多网状态变化
  subscribeMultiPathState();
  
  // 4. 发起多网请求
  const success = await requestMultiPath();
  if (!success) {
    console.error('多网请求失败');
    // 清理订阅
    unsubscribeMultiPathState();
    unsubscribeMultiPathRecommendation();
    return;
  }
  
  try {
    // 5. 执行业务逻辑
    await performBusinessTasks();
  } finally {
    // 6. 释放多网资源
    await releaseMultiPath();
    
    // 7. 取消订阅
    unsubscribeMultiPathState();
    unsubscribeMultiPathRecommendation();
    
    console.info('=== 多网并发示例结束 ===');
  }
}
```

## 错误码说明

### 通用错误码

| 错误码 | 说明 | 解决方法 |
|--------|------|---------|
| 201 | 权限校验失败 | 在module.json5中申请`ohos.permission.LINKTURBO`权限 |
| 401 | 参数检查失败 | 检查参数类型和格式是否正确 |
| 801 | 设备不支持该API | 检查设备API版本是否≥6.0.0(20) |

### 多网请求错误码

| 错误码 | 说明 | 解决方法 |
|--------|------|---------|
| 1013600001 | 内部处理异常（状态机异常、消息队列阻塞等） | 重试或稍后再试 |
| 1013600002 | 系统处理异常（IPC调用失败、网络管理服务启动失败） | 检查系统服务状态或重启应用 |
| 1013620000 | 多网功能没有使能 | 检查是否开启网络加速开关 |
| 1013620001 | 多网已经激活或正在激活中 | 无需重复请求，等待多网建立完成 |
| 1013620002 | 应用多网请求已达到上限 | 等待配额刷新或释放已占用的多网资源 |
| 1013620003 | 功耗限制不允许发起多网 | 等待功耗条件改善或提示用户稍后重试 |
| 1013620004 | 限额耗尽 | 等待配额刷新或提示用户配额已用完 |
| 1013620005 | 多网请求场景冲突 | 检查是否有其他业务占用多网资源 |
| 1013620006 | 多网发起太频繁 | 避免频繁请求，适当延迟后重试 |
| 1013620007 | 没有合适的多网链路可用 | 检查网络条件（WiFi、蜂窝网络）是否满足 |
| 1013620008 | 流量不足 | 提示用户流量不足或连接WiFi |
| 1013620009 | 不支持并发 | 检查设备是否支持多网并发 |

### 多网释放错误码

| 错误码 | 说明 | 解决方法 |
|--------|------|---------|
| 1013620100 | 多网已激活但不是当前应用发起的 | 无法释放其他应用发起的多网 |
| 1013620101 | 多网不在激活态 | 无需释放，多网已处于空闲状态 |

### 多网请求结果错误

| 错误结果 | 说明 | 解决方法 |
|---------|------|---------|
| MULTIPATH_ERROR_NETWORK_REFUSED | 多网请求被网络拒绝 | 检查网络条件或稍后重试 |
| MULTIPATH_ERROR_TIMEOUT | 多网建立超时 | 检查网络质量或稍后重试 |
| MULTIPATH_ERROR_LOCAL | 多网建立过程中本地释放 | 检查是否有本地操作中断了建立过程 |

### 多网状态变化原因

| 状态变化原因 | 说明 | 处理建议 |
|------------|------|---------|
| MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK | 网络原因释放多网 | 监听网络状态，网络恢复后重新发起 |
| MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED | 用户操作开关释放多网 | 提示用户网络加速开关被关闭 |
| MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA | 配额耗尽释放多网 | 提示用户配额已用完 |
| MULTIPATH_CHANGE_CAUSE_RELEASE_POWER_CONSUMPTION | 功耗原因释放多网 | 提示用户因功耗限制多网被释放 |
| MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC | 流量原因释放多网 | 提示用户流量不足 |
| MULTIPATH_CHANGE_CAUSE_RELEASE_CONFLICT | 场景冲突释放多网 | 检查是否有其他业务冲突 |
| MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING | 应用使用不规范被系统释放 | 避免长时间占用多网不释放 |
| MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_DEFAULT | 系统网络状态变化释放多网 | 监听网络状态变化 |
| MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER | 多网进入挂起状态 | 等待退出挂起或使用单网降级 |
| MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE | 多网退出挂起状态 | 可以继续使用多网 |

## 编译和修复问题

### 依赖声明

**module.json5配置**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["default", "tablet"],
    "pages": ["pages/Index"],
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "exported": true,
        "skills": [
          {
            "entities": ["entity.system.home"],
            "actions": ["action.system.home"]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO",
        "reason": "$string:linkturbo_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**oh-package.json5依赖**：
```json
{
  "dependencies": {
    "@kit.NetworkBoostKit": "latest",
    "@kit.BasicServicesKit": "latest"
  }
}
```

### 环境要求

- **HarmonyOS API版本**：6.0.0(20)及以上
- **DevEco Studio版本**：4.0及以上
- **设备能力**：支持多网并发（WiFi+蜂窝或主卡+副卡）
- **系统设置**：开启网络加速开关（设置->移动网络->网络加速->允许使用移动数据加速网络）

### 常见编译问题

**问题1：权限未声明**
```
Error: Permission denied: ohos.permission.LINKTURBO
```
**解决方法**：在`module.json5`的`requestPermissions`中添加权限声明

**问题2：API版本不匹配**
```
Error: API version mismatch. Required: 20, Current: 12
```
**解决方法**：检查`build-profile.json5`中的`compileSdkVersion`和`targetSdkVersion`是否≥20

**问题3：模块导入失败**
```
Error: Cannot find module '@kit.NetworkBoostKit'
```
**解决方法**：检查`oh-package.json5`中是否声明了依赖，并执行`ohpm install`

**问题4：设备不支持多网并发**
```
Error code: 1013620009, Error message: Not support concurrent
```
**解决方法**：检查设备是否支持多网并发功能，部分设备可能不支持双卡并发

**问题5：网络加速开关未开启**
```
Error code: 1013620000, Error message: MultiPath function not enabled
```
**解决方法**：引导用户开启网络加速开关（设置->移动网络->网络加速->允许使用移动数据加速网络）

## 常见问题与解决方法

### Q1：发起多网请求失败，错误码1013620007（没有合适的多网链路可用）

**原因**：
- WiFi和蜂窝网络同时不可用
- 主卡和副卡不满足并发条件（如插入同运营商卡）
- 设备硬件不支持双卡并发

**解决方法**：
- 检查WiFi和蜂窝网络是否可用
- 检查主卡和副卡是否为不同运营商
- 查询设备是否支持多网并发功能
- 提示用户检查网络设置

### Q2：多网请求成功，但实际网络速度没有提升

**原因**：
- 传输协议接口不支持指定网络（如HTTP只支持默认网络）
- 应用未使用新发起的网络进行数据传输
- 网络质量问题

**解决方法**：
- 确认使用的传输协议接口是否支持指定网络
- 使用支持指定网络的接口（如Socket）
- 监听多网状态变化，确认多网是否真正建立
- 检查网络质量

### Q3：多网请求成功后，被系统自动释放

**原因**：
- 配额耗尽（MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA）
- 功耗限制（MULTIPATH_CHANGE_CAUSE_RELEASE_POWER_CONSUMPTION）
- 流量不足（MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC）
- 用户关闭网络加速开关（MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED）
- 应用长时间占用多网不释放（MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING）

**解决方法**：
- 监听`multiPathStateChange`事件，及时感知多网释放
- 根据释放原因提示用户
- 避免长时间占用多网资源，业务结束后及时释放
- 在配额不足时使用单网降级方案

### Q4：如何判断设备是否支持多网并发？

**原因**：不同设备的多网并发能力可能不同

**解决方法**：
- 发起多网请求前，检查网络加速开关是否存在（设置->移动网络->网络加速）
- 发起多网请求，捕获错误码1013620009（不支持并发）
- 通过`getMultiPathQuotaStats`接口查询配额，如果接口可用则设备支持

### Q5：如何处理主卡和副卡并发？

**原因**：主卡和副卡并发需要特定条件

**解决方法**：
- 确保主卡和副卡为不同运营商
- 开启智能切换上网卡开关
- 检查主卡和副卡驻留网络的频点是否满足并发条件
- 捕获错误码1013620007，提示用户当前不满足主副卡并发条件

### Q6：多网请求的配额是如何计算的？

**原因**：配额包括次数和时长，限制应用的多网使用

**解决方法**：
- 使用`getMultiPathQuotaStats`接口查询配额使用情况
- 配额包括已使用次数、已使用时长、剩余次数、剩余时长
- 配额由系统管理，可能按天或其他周期刷新
- 在配额不足时，使用单网降级方案

### Q7：如何在后台使用多网并发？

**原因**：后台应用的多网使用可能受限制

**解决方法**：
- 多网并发主要用于前台应用的网络加速
- 后台应用长时间占用多网可能被系统释放（MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING）
- 应用切换到后台时，建议主动释放多网资源
- 应用回到前台时，根据业务需要重新发起多网请求

### Q8：如何优化多网并发的使用？

**原因**：不合理的使用可能导致配额浪费或用户体验下降

**解决方法**：
- 在业务流程开始时发起多网，业务结束时释放
- 监听系统多网推荐（`multiPathRecommendation`），按需发起或释放
- 避免频繁发起和释放多网（错误码1013620006）
- 使用支持指定网络的传输协议接口
- 监听多网状态变化，及时处理异常情况
- 在配额不足、功耗限制、流量不足时使用单网降级方案

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "multiPathRequested": true,
  "multiPathState": "MULTIPATH_CREATED",
  "quotaUsed": {
    "count": 1,
    "duration": 120
  },
  "quotaRemaining": {
    "count": 9,
    "duration": 1800
  },
  "apiUsed": [
    "netHandover.requestMultiPath",
    "netHandover.releaseMultiPath",
    "netHandover.on('multiPathStateChange')",
    "netHandover.off('multiPathStateChange')",
    "netHandover.getMultiPathQuotaStats"
  ],
  "warnings": [],
  "errors": []
}
```

## 参考文档

- [API开发指南：多网发起和释放](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-request-release)
- [API参考说明：netHandover模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-nethandover)

## 完整示例代码

- [ArkTS示例代码](assets/multipath_example.ets)
- [权限配置示例](assets/module.json5)
- [依赖配置示例](assets/oh-package.json5)

## 测试用例

### 正向测试用例
- [发起多网请求成功](tests/test_positive.ets)：正常发起多网并发请求并成功建立
- [释放多网成功](tests/test_positive.ets)：正常释放已建立的多网并发链路
- [监听状态变化](tests/test_positive.ets)：订阅多网状态变化并正确处理状态变更
- [查询配额信息](tests/test_positive.ets)：成功查询配额使用情况和剩余情况

### 边界测试用例
- [配额即将耗尽](tests/test_boundary.ets)：剩余配额为1时发起多网请求
- [多网已激活状态](tests/test_boundary.ets)：在多网已激活时重复发起请求
- [网络条件临界](tests/test_boundary.ets)：WiFi和蜂窝网络质量临界时发起请求
- [并发时长临界](tests/test_boundary.ets)：多网并发时长接近配额限制

### 异常测试用例
- [权限未授予](tests/test_exception.ets)：未申请LINKTURBO权限时发起请求
- [配额已耗尽](tests/test_exception.ets)：剩余配额为0时发起请求
- [网络不可用](tests/test_exception.ets)：WiFi和蜂窝网络均不可用时发起请求
- [设备不支持](tests/test_exception.ets)：在不支持多网并发的设备上发起请求
- [功耗限制](tests/test_exception.ets)：功耗限制导致无法发起多网请求
- [流量不足](tests/test_exception.ets)：流量不足导致无法发起多网请求
- [释放非当前应用多网](tests/test_exception.ets)：尝试释放其他应用发起的多网