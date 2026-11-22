---
name: hmos-share-kit-knock-share-pc-phones-sandbox
description: 实现手机与PC/2in1/Tablet碰一碰分享文件至应用沙箱,支持指定文件类型和数量限制,传输完成后通知目标应用接收文件列表,适用于快速文件传输、无缝预览编辑场景
---

# 分享内容直达应用界面技能

## 功能描述

本技能实现手机与PC/2in1/Tablet设备间的碰一碰分享功能,通过沙箱接收能力将文件快速传输至目标设备应用沙箱目录,传输完成后自动通知应用接收文件列表,实现无缝预览与编辑。

**核心能力**:
- 支持手机轻贴PC/2in1/Tablet设备屏幕触发文件传输
- 支持指定接收文件类型(通过UTD统一数据类型)
- 支持限制接收文件数量
- 文件保存至应用沙箱目录,保护数据安全
- 传输完成自动通知应用处理文件列表

**适用场景**:
- 手机快速向PC传输文件
- 文件预览与编辑场景
- 跨设备文件协作

**版本支持**:
- PC/2in1设备: 从6.0.0(20)版本开始支持
- Tablet设备: 从6.1.0(23)版本开始支持

## 使用场景

### 触发词
- "碰一碰分享到PC"
- "手机碰PC传文件"
- "沙箱接收分享"
- "应用沙箱接收文件"
- "PC碰一碰接收"

### 能做
- 注册沙箱接收事件监听,指定接收文件类型和数量
- 接收手机传输的文件并保存至应用沙箱目录
- 处理接收到的文件列表,实现预览或编辑功能
- 取消沙箱接收事件监听
- 拒绝不符合要求的文件接收

### 绝不做
- 不支持接收文本或链接类型数据(仅支持文件类型)
- 不支持超出指定数量限制的文件接收
- 不支持与华为分享默认逻辑冲突的类型匹配
- 不支持在非PC/2in1/Tablet设备上使用

### 补充
- 沙箱接收仅支持文件类型数据,文本类型保持原有接收逻辑
- 若类型不匹配,则跳过已注册的沙箱接口能力,采用华为分享默认逻辑
- 若数量不匹配,则通过系统弹窗提示用户异常
- 建议使用已存在的空文件夹作为接收目录,保护信息安全

## 调用规范和规则

### 输入约束
- 文件类型: 仅支持文件类型数据,文本类型不支持
- 文件数量: 必须指定最大接收数量(maxSupportedCount),仅允许设置大于0的整数
- 接收目录: 必须是真实存在的目录路径,建议使用空文件夹
- windowId: 必须是有效的窗口ID
- UTD类型: 必须使用合法的UniformDataType

### 执行约束
- 最大耗时: 文件传输时间取决于文件大小和网络状况
- 事件监听: 必须在窗口生命周期内注册和取消监听
- API调用频次: 无限制,但需合理管理监听事件
- 授权机制: Share Kit会在传输开始前获取目录授权,传输完成后自动撤销

### 内容约束
- 禁止使用不存在或无权限的目录路径
- 禁止在回调函数中执行耗时操作阻塞主线程
- 禁止忽略错误码处理
- 禁止使用无效的UTD类型

### 降级约束
- 类型不匹配: 自动采用华为分享默认逻辑接收
- 数量不匹配: 系统弹窗提示用户异常
- 目录不存在: 记录日志并提示用户检查配置
- 设备不支持: 返回错误码801,提示用户设备不支持

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查设备类型是否为PC/2in1/Tablet
2. 检查API版本是否满足要求(PC/2in1: 6.0.0(20)+, Tablet: 6.1.0(23)+)
3. 确认应用沙箱目录已创建并存在
4. 确认已获取有效的窗口ID

**参数准备**:
```typescript
// 导入必要模块
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { common } from '@kit.AbilityKit';

// 配置沙箱接收能力
let capabilityRegistry: harmonyShare.RecvCapabilityRegistry = {
  windowId: 999, // 替换为实际的窗口ID
  capabilities: [{
    utd: utd.UniformDataType.IMAGE, // 指定接收文件类型
    maxSupportedCount: 1 // 指定最大接收数量
  }]
};
```

### 步骤2: 注册沙箱接收事件

**示例代码**:
```typescript
aboutToAppear(): void {
  // 注册沙箱接收'dataReceive'监听事件
  harmonyShare.on('dataReceive', capabilityRegistry, (receivableTarget: harmonyShare.ReceivableTarget) => {
    let uiContext: UIContext = this.getUIContext();
    let context = uiContext.getHostContext() as common.UIAbilityContext;
    
    receivableTarget.receive(context.filesDir, {
      onDataReceived: (sharedData: systemShare.SharedData) => {
        let sharedRecords = sharedData.getRecords();
        sharedRecords.forEach((record: systemShare.SharedRecord) => {
          // 处理分享数据
          console.log('Received file:', record);
        });
      },
      onResult(resultCode: harmonyShare.ShareResultCode) {
        if (resultCode === harmonyShare.ShareResultCode.SHARE_SUCCESS) {
          console.log('File transfer completed successfully');
        } else {
          console.error('File transfer failed with code:', resultCode);
        }
      }
    });
  });
}
```

### 步骤3: 错误处理

**错误处理代码**:
```typescript
harmonyShare.on('dataReceive', capabilityRegistry, (receivableTarget: harmonyShare.ReceivableTarget) => {
  try {
    receivableTarget.receive(context.filesDir, {
      onDataReceived: (sharedData: systemShare.SharedData) => {
        try {
          let sharedRecords = sharedData.getRecords();
          // 处理文件逻辑
        } catch (error) {
          console.error('Failed to process received files:', error.message);
        }
      },
      onResult(resultCode: harmonyShare.ShareResultCode) {
        switch (resultCode) {
          case harmonyShare.ShareResultCode.SHARE_SUCCESS:
            console.info('Transfer succeeded');
            break;
          case harmonyShare.ShareResultCode.SEND_FAILED:
            console.error('Transfer failed: sender error');
            break;
          case harmonyShare.ShareResultCode.CANCEL_BY_SENDER:
            console.warn('Transfer cancelled by sender');
            break;
          case harmonyShare.ShareResultCode.CANCEL_BY_RECEIVER:
            console.warn('Transfer cancelled by receiver');
            break;
          default:
            console.error('Unknown error:', resultCode);
        }
      }
    });
  } catch (error) {
    console.error('Failed to receive files:', error.message);
    receivableTarget.reject(harmonyShare.ReceivableErrorCode.NO_RECEIVABLE_ERROR);
  }
});
```

### 步骤4: 拒绝接收处理

**拒绝接收代码**:
```typescript
harmonyShare.on('dataReceive', capabilityRegistry, (receivableTarget: harmonyShare.ReceivableTarget) => {
  // 业务逻辑判断,是否需要拒绝接收
  if (shouldRejectReceive) {
    receivableTarget.reject(harmonyShare.ReceivableErrorCode.NO_RECEIVABLE_ERROR);
    console.warn('Receive rejected: current cannot receive data');
    return;
  }
  
  // 正常接收逻辑
  receivableTarget.receive(context.filesDir, receiveCallback);
});
```

### 步骤5: 取消沙箱接收事件

**取消注册代码**:
```typescript
aboutToDisappear(): void {
  // 取消沙箱接收'dataReceive'监听事件
  harmonyShare.off('dataReceive', capabilityRegistry);
}
```

## 错误码说明

### 沙箱接收错误码 (ShareResultCode)

| 错误码 | 名称 | 值 | 说明 | 解决方法 |
|--------|------|-----|------|----------|
| SHARE_SUCCESS | 成功 | 0 | 沙箱接收成功 | 无需处理,继续业务逻辑 |
| SEND_FAILED | 发送失败 | 1 | 数据传输失败 | 检查网络连接,重试传输 |
| CANCEL_BY_SENDER | 发送端取消 | 2 | 发送端取消发送 | 通知用户发送端已取消 |
| CANCEL_BY_RECEIVER | 接收端取消 | 3 | 接收端取消接收 | 通知用户接收端已取消 |

### 拒绝接收错误码 (ReceivableErrorCode)

| 错误码 | 名称 | 值 | 说明 | 使用场景 |
|--------|------|-----|------|----------|
| NO_RECEIVABLE_ERROR | 无法接收 | 1 | 当前无法接收数据的场景 | 应用繁忙、资源不足、业务限制等 |

### 通用错误码

| 错误码ID | 说明 | 解决方法 |
|----------|------|----------|
| 401 | 参数错误 | 检查参数类型和必填项 |
| 801 | 设备不支持 | 该功能仅在PC/2in1设备上可用 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "^6.0.0",
    "@kit.ArkData": "^6.0.0",
    "@kit.AbilityKit": "^6.0.0"
  }
}
```

### 环境要求
- DevEco Studio: 4.0+
- HarmonyOS SDK: API 12+ (6.0.0)
- 设备类型: PC/2in1 (API 12+), Tablet (API 13+)
- 模型约束: 仅支持Stage模型

### 常见编译问题

**问题1: 找不到模块'@kit.ShareKit'**
```
Error: Cannot find module '@kit.ShareKit'
```
**解决方法**: 
- 检查HarmonyOS SDK版本是否>=6.0.0
- 在module.json5中添加依赖声明
- 同步项目依赖

**问题2: windowId参数无效**
```
Error: Invalid windowId
```
**解决方法**: 
- 确保在组件生命周期内获取正确的windowId
- 使用`this.getUIContext().getWindowId()`获取有效窗口ID

**问题3: 目录不存在**
```
Error: Directory does not exist
```
**解决方法**: 
- 在注册事件前先创建接收目录
- 使用`context.filesDir`确保目录存在且有权限

## 常见问题与解决方法

### Q1: 为什么接收不到文件?
**原因**: 
- windowId无效或未正确获取
- 目录不存在或无权限
- 文件类型不匹配
- 设备不支持(PC/2in1/Tablet以外)

**解决方法**:
- 检查windowId是否正确
- 确保接收目录存在且有读写权限
- 检查capabilities中utd类型是否与发送端一致
- 确认设备类型和API版本

### Q2: 文件传输完成后如何处理?
**原因**: 在onDataReceived回调中接收文件列表

**解决方法**:
```typescript
onDataReceived: (sharedData: systemShare.SharedData) => {
  let sharedRecords = sharedData.getRecords();
  sharedRecords.forEach((record: systemShare.SharedRecord) => {
    let filePath = record.getFilePath(); // 获取文件路径
    // 实现预览、编辑等业务逻辑
  });
}
```

### Q3: 如何拒绝本次接收?
**原因**: 业务逻辑需要拒绝接收

**解决方法**:
```typescript
receivableTarget.reject(harmonyShare.ReceivableErrorCode.NO_RECEIVABLE_ERROR);
```

### Q4: 如何区分不同设备类型?
**原因**: 不同设备类型API版本要求不同

**解决方法**:
- PC/2in1: API 12+ (6.0.0)
- Tablet: API 13+ (6.1.0)
- 其他设备: 返回错误码801

### Q5: 如何处理类型不匹配的情况?
**原因**: 发送端文件类型与接收端设置不匹配

**解决方法**:
- 类型不匹配时自动采用华为分享默认逻辑
- 在capabilities中正确设置utd类型
- 参考文档: [目标设备接收分享数据一步直达体验](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-access-one-step)

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "action": "knock_share_to_sandbox",
  "filesReceived": ["file1.jpg", "file2.png"],
  "saveDirectory": "/data/storage/el2/base/files/",
  "resultCode": 0,
  "apiUsed": [
    "harmonyShare.on('dataReceive')",
    "receivableTarget.receive()",
    "receivableTarget.reject()",
    "harmonyShare.off('dataReceive')"
  ]
}
```

## 参考文档

- [API开发指南](references/knock-share-pc-phones-sandbox.md)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-harmony-share)
- [目标设备接收分享数据一步直达体验](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-access-one-step)

## 完整示例代码

- [ArkTS示例: 注册沙箱接收并处理文件](assets/knock-share-sandbox-receive.ets)
- [ArkTS示例: 拒绝沙箱接收](assets/knock-share-sandbox-reject.ets)

## 测试用例

### 正向测试用例
- [接收单张图片文件](tests/test_receive_single_image.py): 测试接收单个图片文件并保存至沙箱
- [接收多个文件](tests/test_receive_multiple_files.py): 测试接收多个文件(数量<=maxSupportedCount)
- [取消注册监听](tests/test_unregister_listener.py): 测试正常取消注册沙箱接收监听

### 边界测试用例
- [接收文件数量达到上限](tests/test_max_count_limit.py): 测试接收文件数量等于maxSupportedCount
- [不同UTD类型文件](tests/test_different_utd_types.py): 测试接收不同类型文件(IMAGE, VIDEO, etc.)
- [空文件夹接收](tests/test_empty_folder.py): 测试使用空文件夹作为接收目录

### 异常测试用例
- [文件类型不匹配](tests/test_type_mismatch.py): 测试接收不符合utd类型的文件
- [文件数量超限](tests/test_count_exceed.py): 测试接收文件数量超过maxSupportedCount
- [目录不存在](tests/test_directory_not_exist.py): 测试接收目录不存在的情况
- [设备不支持](tests/test_unsupported_device.py): 测试在非PC/2in1/Tablet设备上调用