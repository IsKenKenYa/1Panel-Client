---
name: hmos-push-kit-get-token
description: 获取Push Token，支持Phone/Tablet/PC/2in1/Wearable/TV设备，需开通推送服务，适用于应用启动获取Token、Token更新监听、删除Token场景
---

# 获取Push Token技能

## 功能描述

本技能提供HarmonyOS Push Kit的Token获取、删除和更新监听能力。Push Token标识每台设备上的每个应用，用于推送消息的唯一标识。支持获取Token、删除Token、监听Token更新三个核心功能，覆盖应用启动、Token失效、设备迁移等多种场景。

**核心能力**：
- 获取Push Token（getToken）
- 删除Push Token（deleteToken）
- 监听Token更新事件（pushService.on）

**设备支持**：
- 5.1.0(18)以前版本：Phone、Tablet、PC/2in1
- 5.1.0(18)版本：Phone、Tablet、PC/2in1、Wearable
- 5.1.1(19)及之后版本：Phone、Tablet、PC/2in1、Wearable、TV

**前置条件**：
- 已在AppGallery Connect平台开通推送服务
- 应用已正确配置签名和权限

## 使用场景

### 触发词
- "获取Push Token" - 应用启动时获取Token
- "申请推送Token" - 向Push Kit服务端请求Token
- "删除Push Token" - 清除应用的Push Token
- "监听Token更新" - 注册Token更新事件回调
- "Token失效处理" - Token变化时的更新处理

### 能做
- 在应用启动时获取Push Token并上报服务端
- 删除应用的Push Token及相关历史数据
- 监听设备跨地区迁移时的Token自动更新
- 处理Token获取失败的错误场景
- 实现Token变化的回调通知机制

### 绝不做
- 不使用Push Token跟踪标记用户
- 不固定判断Push Token长度（长度可能变化）
- 不频繁申请Push Token（建议每次启动时获取一次）
- 不在未开通推送服务时强制获取Token
- 不在云真机环境调试Push Token功能

### 补充
- Push Token长度为112字符
- Token会在应用卸载重装、恢复出厂设置、跨地区迁移时变化
- 建议在UIAbility的onCreate方法中获取Token
- Wearable设备支持Token更新监听（从5.1.0(18)开始）
- Phone/Tablet/PC/2in1设备支持Token更新监听（从6.1.0(23)开始）

## 调用规范和规则

### 输入约束
- 无参数输入（getToken/deleteToken）
- Token更新监听需提供UIAbility实例和回调函数
- 回调函数参数类型必须匹配（Callback<string>）

### 执行约束
- 最大耗时：5秒（网络请求超时）
- 最大调用频次：建议每次应用启动时调用一次
- 必须在UIAbility的onCreate/onDestroy生命周期方法中注册/解除监听
- 仅支持Stage模型应用

### 内容约束
- 禁止在未开通推送服务时调用getToken
- 禁止在云真机环境调试Token功能
- 禁止使用Token进行用户跟踪
- 禁止重复注册相同类型的回调（on('tokenUpdate')）
- 禁止在异步方法中调用receiveMessage（会影响消息接收）

### 降级约束
- 网络失败：提示用户检查网络连接并稍后重试
- 未开通服务：引导用户前往AppGallery Connect开通推送服务
- 设备不支持：提示用户使用支持的设备类型
- Token获取失败：记录错误日志并上报服务端，等待下次启动重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证应用已在AppGallery Connect开通推送服务
2. 验证应用签名配置正确（包含推送服务权限）
3. 验证设备类型支持Token获取功能
4. 验证网络连接正常

**参数准备**：
```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;
```

### 步骤2：获取Push Token

**示例代码**：
```typescript
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    pushService.getToken().then(token => {
      hilog.info(DOMAIN, 'testTag', 'Succeeded in getting push token.');
      this.reportTokenToServer(token);
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, 'testTag', 'Failed to get push token: %{public}d %{public}s', err.code, err.message);
      this.handleTokenError(err);
    });
  }

  private reportTokenToServer(token: string): void {
  }

  private handleTokenError(err: BusinessError): void {
    switch (err.code) {
      case 1000900010:
        hilog.error(DOMAIN, 'testTag', 'APP identity verification failed');
        break;
      case 1000900012:
        hilog.error(DOMAIN, 'testTag', 'Push service not activated');
        break;
      default:
        hilog.error(DOMAIN, 'testTag', 'Unknown error: %{public}d', err.code);
    }
  }
}
```

### 步骤3：删除Push Token

**示例代码**：
```typescript
async function deletePushToken(): Promise<void> {
  try {
    await pushService.deleteToken();
    hilog.info(DOMAIN, 'testTag', 'Succeeded in deleting push token.');
  } catch (err) {
    let e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, 'testTag', 'Failed to delete push token: %{public}d %{public}s', e.code, e.message);
  }
}
```

### 步骤4：监听Token更新

**示例代码**：
```typescript
export default class PushMessageAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const callBack = (data: string) => {
      try {
        hilog.info(DOMAIN, 'testTag', 'update token: %{public}s', data);
        this.reportTokenToServer(data);
      } catch (e) {
        let err: BusinessError = e as BusinessError;
        hilog.error(DOMAIN, 'testTag', 'Failed to update data: %{public}d %{public}s', err.code, err.message);
      }
    };

    try {
      pushService.on('tokenUpdate', this, callBack);
      hilog.info(DOMAIN, 'testTag', 'Register on success');
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Register on error: %{public}d %{public}s', err.code, err.message);
    }
  }

  onDestroy(): void {
    try {
      pushService.off('tokenUpdate');
      hilog.info(DOMAIN, 'testTag', 'Register off success');
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Register off error: %{public}d %{public}s', err.code, err.message);
    }
  }
}
```

### 步骤5：配置module.json5

**配置文件修改**：
在项目的src/main/module.json5文件的abilities模块中配置action：

```json
{
  "name": "PushMessageAbility",
  "srcEntry": "./ets/abilities/PushMessageAbility.ets",
  "description": "$string:PushMessageAbility_desc",
  "icon": "$media:layered_image",
  "label": "$string:PushMessageAbility_label",
  "startWindowIcon": "$media:startIcon",
  "startWindowBackground": "$color:start_window_background",
  "launchType": "singleton",
  "exported": false,
  "skills": [
    {
      "actions": [
        "com.app.action"
      ]
    },
    {
      "actions": [
        "action.ohos.push.listener"
      ]
    }
  ]
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1000900001 | 系统内部错误 | 重试操作，若无法解决请在线提单 |
| 1000900008 | 连接Push服务失败 | 重试操作，若无法解决请在线提单 |
| 1000900009 | Push服务内部错误 | 重试操作，若无法解决请在线提单 |
| 1000900010 | APP身份验证失败 | 检查应用配置和网络，确认已在AGC开通推送服务并重新申请Profile文件 |
| 1000900011 | 网络不可用 | 重连网络，确保网络正常可用 |
| 1000900012 | 未开通推送服务权益 | 在AppGallery Connect网站开通推送服务 |
| 1000900013 | 不允许跨区申请Token | 检查设备所在地与AGC数据处理位置是否匹配 |
| 1000900014 | 设备不支持申请Token | 使用支持的设备类型（Phone/Tablet/PC/2in1/Wearable/TV） |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {}
}
```

**Kit导入**：
- @kit.PushKit：推送服务核心Kit
- @kit.AbilityKit：应用框架Kit（UIAbility）
- @kit.PerformanceAnalysisKit：性能分析Kit（hilog）
- @kit.BasicServicesKit：基础服务Kit（BusinessError）

### 环境要求
- HarmonyOS SDK版本：>= 4.0.0(10)
- 推送服务支持：Stage模型应用
- 设备类型：Phone/Tablet/PC/2in1/Wearable/TV

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PushKit'
```
**解决方法**：确保HarmonyOS SDK版本>=4.0.0(10)，并在ohpm.json中添加依赖声明

**问题2：UIAbility生命周期方法调用错误**
```
Error: Cannot call pushService.on in async method
```
**解决方法**：确保在UIAbility的onCreate同步方法中调用pushService.on，不能在异步方法中调用

**问题3：重复注册回调**
```
Error: 1000900001 - System internal error
```
**解决方法**：检查是否重复调用pushService.on('tokenUpdate')，每个应用只能注册一次

## 常见问题与解决方法

### Q1：获取Token时返回1000900010错误
**原因**：APP身份验证失败
**解决方法**：
- 检查应用是否在AppGallery Connect上创建并选择HarmonyOS应用类型
- 确认已在AGC的"项目设置 > 开放能力管理"中启用推送服务
- 重新申请Profile文件并完成签名配置
- 检查网络连接是否正常
- 确认不支持云真机调试，使用真机调试

### Q2：Token长度发生变化
**原因**：Push Token长度不固定
**解决方法**：
- 不要固定判断Token长度（当前为112字符，可能变化）
- 使用动态长度存储和传输Token

### Q3：Token频繁变化
**原因**：设备跨地区迁移或应用重新安装
**解决方法**：
- 注册pushService.on('tokenUpdate')监听Token更新事件
- 在回调中及时上报新Token到服务端
- 在Wearable设备上注意跨地区迁移会触发Token更新

### Q4：设备不支持获取Token
**原因**：设备类型不支持或SDK版本不满足
**解决方法**：
- 确认设备类型：Phone/Tablet/PC/2in1/Wearable/TV
- 确认SDK版本：
  - Wearable支持：>= 5.1.0(18)
  - TV支持：>= 5.1.1(19)
  - 其他设备：>= 4.0.0(10)

### Q5：无法收到Token更新回调
**原因**：未配置action.ohos.push.listener
**解决方法**：
- 在module.json5的abilities模块中配置action.ohos.push.listener
- 确保仅有一个ability定义该action
- 若同时添加uris参数，则uris内容需为空

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "token": "112字符的Push Token",
  "deviceType": "Phone/Tablet/PC/2in1/Wearable/TV",
  "sdkVersion": "4.0.0(10)或更高版本",
  "apiUsed": [
    "pushService.getToken()",
    "pushService.deleteToken()",
    "pushService.on('tokenUpdate')",
    "pushService.off('tokenUpdate')"
  ],
  "timestamp": "2026-07-03T01:11:00Z"
}
```

## 参考文档

- [获取Push Token开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-get-token)
- [pushService API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-pushservice)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-error-code)
- [开通推送服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-config-setting)

## 完整示例代码

- [ArkTS示例：获取Token](assets/get_token_example.ets)
- [ArkTS示例：删除Token](assets/delete_token_example.ets)
- [ArkTS示例：监听Token更新](assets/token_update_listener.ets)
- [module.json5配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [应用启动获取Token](tests/test_get_token_positive.ets)：验证应用启动时成功获取Token
- [删除Token](tests/test_delete_token_positive.ets)：验证成功删除Token
- [监听Token更新](tests/test_token_update_positive.ets)：验证成功注册和接收Token更新回调

### 边界测试用例
- [多次获取Token](tests/test_get_token_boundary.ets)：验证多次调用getToken返回相同Token
- [Token长度验证](tests/test_token_length_boundary.ets)：验证Token长度为112字符
- [重复注册监听](tests/test_duplicate_register_boundary.ets)：验证重复注册on回调返回错误

### 异常测试用例
- [未开通服务获取Token](tests/test_get_token_without_service.ets)：验证未开通推送服务时返回1000900012错误
- [网络异常获取Token](tests/test_get_token_network_error.ets)：验证网络不可用时返回1000900011错误
- [设备不支持获取Token](tests/test_get_token_unsupported_device.ets)：验证不支持设备返回1000900014错误