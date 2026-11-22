---
name: hmos-wear-engine-kit-device-notification
description: 向穿戴设备发送模板化通知+支持0-3个按钮+标题最大28字节内容最大400字节+适用于消息提醒、事件通知场景
---

# 穿戴设备模板化通知技能

## 功能描述

本技能提供从手机侧应用向穿戴设备发送模板化通知的能力,通知将按模板在穿戴设备上显示,支持穿戴设备收到通知后同步振动或响铃(跟随穿戴设备系统设置)。支持4种通知类型:无按钮、单按钮、双按钮、三按钮模板。

核心功能:
- 获取NotifyClient客户端对象
- 构造NotificationOptions配置参数
- 发送模板化通知到穿戴设备
- 接收设备侧操作反馈(按钮点击、通知删除等)

限制条件:
- 需申请消息通知权限(参见[申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply))
- 穿戴设备无需对应应用也可显示通知
- 穿戴设备需与华为运动健康App保持连接状态
- 穿戴设备振动/响铃需满足:已开启振动响铃、处于佩戴状态、未开启勿扰模式
- 通知自动弹出需满足:处于佩戴状态、未开启勿扰模式

## 使用场景

### 触发词
- "发送穿戴设备通知"
- "模板化通知"
- "向手表发送通知"
- "穿戴设备消息提醒"
- "通知穿戴设备"

### 能做
- 向已连接的穿戴设备发送模板化通知
- 支持0-3个按钮的通知模板
- 接收用户对通知的操作反馈(点击按钮、删除通知等)
- 在穿戴设备上显示自定义标题、内容和按钮
- 触发穿戴设备振动或响铃提示

### 绝不做
- 不处理非穿戴设备的通知发送
- 不支持自定义通知样式(仅支持模板化)
- 不处理通知权限申请流程(需提前完成)
- 不管理穿戴设备的连接状态(需提前查询)

### 补充
- 执行成功后穿戴设备会显示通知界面并可能振动响铃
- 穿戴设备侧无需对应应用即可显示模板化通知
- 可通过[getConnectedDevices](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)查询设备是否在线

## 调用规范和规则

### 输入约束
- 设备ID: 必须为有效的Device.randomId字符串
- 通知标题: 长度范围[1,28)字节
- 通知内容: 长度范围[1,400)字节  
- 按钮内容: 每个按钮长度范围[1,12)字节
- 按钮数量: 0-3个按钮
- 包名: 必须提供bundleName字段

### 执行约束
- 最大耗时: 10秒(API调用+网络传输)
- API调用频次: 无限制
- 必须先查询已连接设备列表
- 必须确认设备支持NOTIFICATION能力
- 必须申请消息通知权限

### 内容约束
- 禁止生成: 无效的通知类型、超出长度限制的内容
- 禁止使用: 未授权的设备ID、无效的按钮ID
- 参数校验: 必须校验title/text/buttons长度

### 降级约束
- 网络失败: 提示用户检查设备连接状态,建议调用getConnectedDevices验证
- 权限不足: 提示用户申请消息通知权限
- 设备离线: 提示用户在华为运动健康App中连接设备
- 内容过长: 自动截断或提示用户缩短内容

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 查询已连接设备列表(参见[已连接穿戴设备查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices))
2. 选择目标设备(参见[目标设备选择](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/we-device-selection))
3. 确认应用已申请消息通知权限
4. 确认穿戴设备与华为运动健康App处于连接状态

**参数准备**:
```typescript
import { wearEngine } from '@kit.WearEngine';

let targetDevice: wearEngine.Device;

async function prepareNotification(): Promise<void> {
  let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
  let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
  
  if (devices.length === 0) {
    throw new Error('No connected device found');
  }
  
  targetDevice = devices[0];
}
```

### 步骤2: 获取NotifyClient对象

**示例代码**:
```typescript
import { wearEngine } from '@kit.WearEngine';

let notifyClient: wearEngine.NotifyClient = wearEngine.getNotifyClient(this.getUIContext().getHostContext());
console.info('Succeeded in getting notify client');
```

### 步骤3: 构造NotificationOptions对象

**示例代码**:
```typescript
import { wearEngine } from '@kit.WearEngine';

function buildNotificationOptions(): wearEngine.NotificationOptions {
  let button1: wearEngine.NotificationButton = {
    buttonId: wearEngine.ButtonId.FIRST_BUTTON,
    content: 'button_1'
  };
  
  let button2: wearEngine.NotificationButton = {
    buttonId: wearEngine.ButtonId.SECOND_BUTTON,
    content: 'button_2'
  };
  
  let notification: wearEngine.Notification = {
    type: wearEngine.NotificationType.NOTIFICATION_WITH_TWO_BUTTONS,
    bundleName: 'com.example.myapp',
    title: 'Notification Title',
    text: 'This is notification content text',
    buttons: [button1, button2]
  };
  
  let options: wearEngine.NotificationOptions = {
    notification: notification,
    onAction: (feedback: wearEngine.NotificationFeedback) => {
      handleNotificationFeedback(feedback);
    }
  };
  
  return options;
}
```

### 步骤4: 发送模板化通知

**示例代码**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

async function sendNotification(): Promise<void> {
  try {
    let notifyClient: wearEngine.NotifyClient = wearEngine.getNotifyClient(this.getUIContext().getHostContext());
    let options: wearEngine.NotificationOptions = buildNotificationOptions();
    
    await notifyClient.notify(targetDevice.randomId, options);
    console.info('Succeeded in sending notification');
  } catch (error) {
    let businessError: BusinessError = error as BusinessError;
    console.error(`Failed to send notification. Code: ${businessError.code}, Message: ${businessError.message}`);
    handleNotificationError(businessError);
  }
}
```

### 步骤5: 处理设备侧反馈

**示例代码**:
```typescript
import { wearEngine } from '@kit.WearEngine';

function handleNotificationFeedback(feedback: wearEngine.NotificationFeedback): void {
  if (feedback.action) {
    switch (feedback.action) {
      case wearEngine.NotificationAction.FIRST_BUTTON_CLICKED:
        console.info('User clicked first button');
        break;
      case wearEngine.NotificationAction.SECOND_BUTTON_CLICKED:
        console.info('User clicked second button');
        break;
      case wearEngine.NotificationAction.THIRD_BUTTON_CLICKED:
        console.info('User clicked third button');
        break;
      case wearEngine.NotificationAction.NOTIFICATION_DELETED:
        console.info('User deleted notification');
        break;
      case wearEngine.NotificationAction.NOTIFICATION_SWITCHED_TO_BACKGROUND:
        console.info('Notification switched to background');
        break;
    }
  } else if (feedback.errorCode) {
    console.error(`Notification error on device: ${feedback.errorCode}`);
  }
}
```

### 步骤6: 错误处理

**示例代码**:
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

function handleNotificationError(error: BusinessError): void {
  switch (error.code) {
    case 1008500001:
      console.error('Network error. Check device connection.');
      break;
    case 1008500003:
      console.error('Device disconnected. Connect device in Huawei Health App.');
      break;
    case 1008500004:
      console.error('App has not applied for Wear Engine service.');
      break;
    case 1008500006:
      console.error('User privacy not agreed.');
      break;
    case 1008500010:
      console.error('Device ID is invalid.');
      break;
    case 401:
      console.error('Parameter error. Check notification content length.');
      break;
    default:
      console.error(`Unknown error: ${error.code}, ${error.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因:必填参数未指定、参数类型错误、参数校验失败 | 检查参数是否正确,特别是title/text/buttons长度限制 |
| 801 | 能力不支持 | 检查设备是否支持NOTIFICATION能力 |
| 1008500001 | 网络错误,网络不可用 | 检查网络连接,确认设备在线 |
| 1008500002 | 无设备绑定 | 在华为运动健康App中绑定穿戴设备 |
| 1008500003 | 设备断开连接 | 在华为运动健康App中重新连接设备 |
| 1008500004 | 应用未申请Wear Engine服务 | 申请接入Wear Engine服务并获取消息通知权限 |
| 1008500005 | HUAWEI ID未授权 | 授权HUAWEI ID |
| 1008500006 | 用户隐私未同意 | 同意用户隐私协议 |
| 1008500007 | 设备能力不支持 | 检查设备是否支持NOTIFICATION能力 |
| 1008500008 | 账号错误,用户未登录HUAWEI ID | 登录HUAWEI ID |
| 1008500009 | 账号错误,获取HUAWEI ID账号信息失败 | 重新登录HUAWEI ID |
| 1008500010 | 设备ID无效 | 检查device.randomId是否正确 |
| 1008509999 | 内部错误 | 提交问题单给华为技术支持 |

**通知反馈错误码**:
| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 255 | Wear Engine内部错误 | 通过在线提单提交问题 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.WearEngine": "HarmonyOS 5.0.0(12)+",
    "@kit.BasicServicesKit": "HarmonyOS 5.0.0(12)+"
  }
}
```

### 环境要求
- HarmonyOS API版本: 5.0.0(12)及以上
- 设备类型: Phone、Tablet(穿戴设备侧)
- 开发模型: Stage模型
- 系统能力: SystemCapability.Health.WearEngine

### 常见编译问题

**问题1: 导入wearEngine模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**: 确保项目API版本为5.0.0(12)及以上,在module.json5中声明syscap

**问题2: 类型定义错误**
```
Type 'wearEngine.Notification' is not defined
```
**解决方法**: 确保正确导入wearEngine模块,检查SDK版本

**问题3: Context获取失败**
```
Error: getUIContext().getHostContext() is not available
```
**解决方法**: 确保在UIAbility或UI组件上下文中调用

## 常见问题与解决方法

### Q1: 通知发送失败,提示设备未连接
**原因**: 穿戴设备未与华为运动健康App保持连接状态
**解决方法**:
- 在华为运动健康App"设备"界面检查设备是否在线
- 调用getConnectedDevices接口验证设备连接状态
- 提示用户重新连接设备

### Q2: 通知发送失败,提示权限不足
**原因**: 应用未申请消息通知权限
**解决方法**:
- 在开发者联盟申请接入Wear Engine服务
- 申请消息通知权限
- 参见[申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)

### Q3: 通知内容显示不完整
**原因**: 通知标题或内容超出长度限制
**解决方法**:
- 标题限制: [1,28)字节
- 内容限制: [1,400)字节
- 按钮内容限制: [1,12)字节
- 使用字节长度计算(非字符数)

### Q4: 穿戴设备未振动或响铃
**原因**: 穿戴设备振动/响铃条件未满足
**解决方法**:
- 确认穿戴设备已开启振动或响铃
- 确认穿戴设备处于佩戴状态
- 确认穿戴设备未开启勿扰模式

### Q5: 无法接收按钮点击反馈
**原因**: onAction回调函数未正确设置
**解决方法**:
- 在NotificationOptions中设置onAction回调
- 回调函数需处理NotificationFeedback参数
- 区分feedback.action和feedback.errorCode

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "notificationSent": true,
  "deviceRandomId": "target_device_random_id",
  "notificationType": "NOTIFICATION_WITH_TWO_BUTTONS",
  "title": "Notification Title",
  "text": "Notification content",
  "buttons": ["button_1", "button_2"],
  "apiUsed": [
    "wearEngine.getNotifyClient",
    "NotifyClient.notify",
    "NotificationOptions",
    "Notification",
    "NotificationButton"
  ]
}
```

## 参考文档

- [穿戴设备模板化通知开发指南](references/device_notification.md)
- [Wear Engine API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)
- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)
- [已连接穿戴设备查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices)
- [目标设备选择](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/we-device-selection)

## 完整示例代码

- [ArkTS完整示例](assets/notification_example.ets)

## 测试用例

### 正向测试用例
- [发送无按钮通知](tests/test_positive.py): 测试NOTIFICATION_WITHOUT_BUTTONS类型
- [发送单按钮通知](tests/test_positive.py): 测试NOTIFICATION_WITH_ONE_BUTTON类型
- [发送双按钮通知](tests/test_positive.py): 测试NOTIFICATION_WITH_TWO_BUTTONS类型
- [发送三按钮通知](tests/test_positive.py): 测试NOTIFICATION_WITH_THREE_BUTTONS类型

### 边界测试用例
- [标题长度边界测试](tests/test_boundary.py): 测试标题27字节(接近上限28)
- [内容长度边界测试](tests/test_boundary.py): 测试内容399字节(接近上限400)
- [按钮内容边界测试](tests/test_boundary.py): 测试按钮11字节(接近上限12)

### 异常测试用例
- [标题超长测试](tests/test_exception.py): 测试标题28字节(超出限制)
- [内容超长测试](tests/test_exception.py): 测试内容400字节(超出限制)
- [按钮超长测试](tests/test_exception.py): 测试按钮12字节(超出限制)
- [无效设备ID测试](tests/test_exception.py): 测试空或无效的randomId
- [设备未连接测试](tests/test_exception.py): 测试设备离线场景
- [权限不足测试](tests/test_exception.py): 测试未申请权限场景