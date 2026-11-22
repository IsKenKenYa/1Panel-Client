---
name: hmos-share-kit-knock-share-group
description: 实现碰一碰分享邀请组队功能，支持单向发送能力配置和组队链接处理，适用于游戏组队、社交邀请场景
---

# 碰一碰分享邀请组队技能

## 功能描述

本技能实现HarmonyOS碰一碰分享邀请组队功能，允许用户通过碰一碰设备快速邀请好友加入组队房间。支持以下核心能力：

- 注册碰一碰分享事件监听
- 配置单向发送能力（避免双向邀请冲突）
- 设置分享预览卡片
- 处理组队邀请链接
- 异常场景终止分享

适用于游戏组队、社交邀请、多人协作等场景。

## 使用场景

### 触发词
- "碰一碰邀请组队"
- "knock share group"
- "邀请好友加入组队"
- "碰一碰分享组队链接"
- "组队邀请"

### 能做
- 实现碰一碰设备轻贴触发组队邀请
- 配置单向发送能力避免组队冲突
- 生成带预览图的分享卡片
- 处理接收到的组队邀请链接
- 在异常情况下终止分享流程

### 绝不做
- 不支持多设备同时组队邀请（仅支持点对点）
- 不处理组队业务逻辑（仅提供分享通道）
- 不支持Tablet设备的碰一碰分享
- 不替代组队服务器功能

### 补充
- 需要在组队房间界面注册碰一碰事件
- 双方都在组队房间时需要配置单向发送能力
- API版本要求：HarmonyOS 5.0.0(12)及以上
- 仅支持Stage模型应用

## 调用规范和规则

### 输入约束
- 组队链接：必须是有效的URL格式，长度不超过2048字符
- 预览图文件：支持JPEG/PNG格式，文件大小不超过5MB
- windowId：必须是当前应用窗口的有效ID
- 标题/描述：标题不超过50字符，描述不超过200字符

### 执行约束
- 碰一碰事件注册：必须在UI组件生命周期内注册和注销
- 事件监听时长：建议不超过应用前台运行时间
- API调用频次：不超过系统限制（通常为5秒内1次）
- 分享数据准备：必须在回调触发时立即准备数据

### 内容约束
- 禁止生成：涉及用户隐私的敏感信息、违反法律法规的内容
- 禁止操作：使用高危函数（eval、exec等）、硬编码敏感信息
- 禁止配置：无效的windowId、不存在的文件路径

### 降级约束
- 网络失败：提示用户检查网络连接，可降级为手动分享
- 碰一碰失败：提示用户重新尝试或使用其他分享方式
- 权限不足：引导用户检查应用权限设置
- 双向冲突：提示用户一方退出当前应用后重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持碰一碰分享功能（非Tablet设备）
2. 验证应用是否运行在Stage模型下
3. 确认API版本是否满足要求（HarmonyOS 5.0.0(12)+）
4. 检查必要权限是否已申请

**参数准备**：
```typescript
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';

let capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
  windowId: 999, // 实际使用时替换为正确的windowId
  sendOnly: true // 设置为仅发送模式，避免双向邀请冲突
};
```

### 步骤2：注册碰一碰事件监听

**示例代码**：
```typescript
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';

@Component
export default struct GroupInviteComponent {
  aboutToAppear(): void {
    let capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
      windowId: 999, // 替换为正确的windowId
      sendOnly: true // 单向发送配置
    };
    
    harmonyShare.on('knockShare', capabilityRegistry, (sharableTarget: harmonyShare.SharableTarget) => {
      try {
        let uiContext: UIContext = this.getUIContext();
        let contextFaker: Context = uiContext.getHostContext() as Context;
        let filePath = contextFaker.filesDir + '/exampleKnock1.jpg'; // 替换为实际预览图路径
        
        let shareData: systemShare.SharedData = new systemShare.SharedData({
          utd: utd.UniformDataType.HYPERLINK,
          content: 'https://sharekitdemo.drcn.agconnect.link/ZB3p', // 替换为实际组队链接
          thumbnailUri: fileUri.getUriFromPath(filePath),
          title: '碰一碰分享卡片标题',
          description: '碰一碰分享卡片描述'
        });
        
        sharableTarget.share(shareData);
      } catch (error) {
        console.error('Share failed:', error);
        sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
      }
    });
  }
  
  aboutToDisappear(): void {
    let capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
      windowId: 999 // 替换为正确的windowId
    };
    harmonyShare.off('knockShare', capabilityRegistry);
  }
  
  build() {
    Column() {
      Text('邀请好友加入组队')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
    }
  }
}
```

### 步骤3：处理组队邀请链接

**示例代码**：
```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    try {
      windowStage.loadContent('pages/Index');
    } catch (error) {
      console.error(`onWindowStageCreate error. Code: ${error?.code}, message: ${error?.message}`);
    }
  }
  
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('EntryAbility onCreate invoked. uri: ', want.uri);
    // 解析组队链接，提取房间信息
    if (want.uri) {
      this.handleGroupInvite(want.uri);
    }
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('EntryAbility onNewWant invoked. uri: ', want.uri);
    // 处理新的组队邀请
    if (want.uri) {
      this.handleGroupInvite(want.uri);
    }
  }
  
  private handleGroupInvite(uri: string): void {
    // 解析组队链接参数
    const params = new URLSearchParams(uri.split('?')[1]);
    const roomId = params.get('roomId');
    const inviterId = params.get('inviterId');
    
    // TODO: 调用组队业务逻辑，加入房间
    console.info(`Group invite received: roomId=${roomId}, inviterId=${inviterId}`);
  }
}
```

### 步骤4：异常处理和终止分享

**示例代码**：
```typescript
import { harmonyShare } from '@kit.ShareKit';

harmonyShare.on('knockShare', capabilityRegistry, async (sharableTarget: harmonyShare.SharableTarget) => {
  try {
    // 检查是否可以分享
    const canShare = await this.checkShareCondition();
    if (!canShare) {
      await sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
      console.warn('Share rejected: no content available');
      return;
    }
    
    // 准备分享数据
    const shareData = await this.prepareShareData();
    await sharableTarget.share(shareData);
    
  } catch (error) {
    console.error('Share error:', error);
    
    // 根据错误类型选择拒绝原因
    if (error.code === 'NO_NETWORK') {
      await sharableTarget.reject(harmonyShare.SharableErrorCode.NO_INTERNET_ERROR);
    } else if (error.code === 'DOWNLOAD_FAILED') {
      await sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR);
    } else {
      await sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    }
  }
});
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，windowId无效或分享数据格式错误 | 检查windowId是否正确，验证分享数据格式 |
| NO_CONTENT_ERROR (1) | 无内容可分享 | 确保组队链接有效，预览图文件存在 |
| NO_INTERNET_ERROR (2) | 无网络连接 | 提示用户检查网络，可降级为本地分享 |
| DOWNLOAD_ERROR (3) | 下载失败 | 检查网络连接，确保资源可访问 |
| 801 | 设备不支持碰一碰分享 | Tablet设备不支持，提示用户使用其他分享方式 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "^5.0.0",
    "@kit.ArkData": "^5.0.0",
    "@kit.CoreFileKit": "^5.0.0",
    "@kit.AbilityKit": "^5.0.0",
    "@kit.ArkUI": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0.0(12)及以上
- DevEco Studio：3.1及以上
- 设备类型：手机（不支持Tablet）
- 应用模型：Stage模型

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ShareKit'
```
**解决方法**：检查HarmonyOS SDK版本，确保使用5.0.0及以上版本，在module.json5中添加依赖声明。

**问题2：windowId无效**
```
Error: Parameter error. Invalid windowId
```
**解决方法**：通过`window.getLastWindow(this.context)`获取正确的windowId，不要使用硬编码值。

**问题3：碰一碰事件无响应**
```
碰一碰后回调未触发
```
**解决方法**：
- 检查设备是否为Tablet（Tablet不支持）
- 确认应用是否在前台运行
- 验证windowId是否正确绑定到当前窗口

**问题4：双向分享冲突**
```
双方都设置sendOnly导致分享失败
```
**解决方法**：确保只有一方设置sendOnly=true，另一方设置为false或默认值。

## 常见问题与解决方法

### Q1：碰一碰分享在Tablet设备上不工作
**原因**：Tablet设备不支持碰一碰分享功能，API在Tablet上无效果。
**解决方法**：
- 检测设备类型，在Tablet上提示用户使用其他分享方式
- 使用`deviceInfo.deviceType`判断设备类型
- 提供备选分享方案（如二维码、链接分享）

### Q2：双方都在组队房间时碰一碰失败
**原因**：双方都设置了sendOnly=true，系统会拦截双向分享并提示"请任意一方退出当前应用后再试"。
**解决方法**：
- 仅设置邀请方的sendOnly=true
- 接收方不设置sendOnly或设置为false
- 在UI上明确提示用户当前的分享状态

### Q3：预览图显示失败
**原因**：预览图文件不存在、路径错误或文件格式不支持。
**解决方法**：
- 确保预览图文件真实存在于沙箱目录
- 使用`fileUri.getUriFromPath()`正确转换路径
- 验证文件格式为JPEG/PNG
- 检查文件大小不超过5MB

### Q4：组队链接解析失败
**原因**：链接格式不符合规范或参数缺失。
**解决方法**：
- 使用URLSearchParams标准方法解析链接
- 验证链接包含必要的参数（roomId、inviterId等）
- 处理链接缺失参数的降级场景

### Q5：应用冷启动时无法接收组队邀请
**原因**：冷启动时onCreate会被调用，但需要正确处理want.uri参数。
**解决方法**：
- 在onCreate中检查want.uri是否存在
- 保存组队邀请信息到应用状态
- 在UI加载完成后处理组队逻辑

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "function": "碰一碰分享邀请组队",
  "shareMethod": "knockShare",
  "shareContent": {
    "type": "HYPERLINK",
    "link": "组队邀请链接",
    "previewImage": "预览图URI"
  },
  "sendOnly": true,
  "apiUsed": [
    "harmonyShare.on('knockShare')",
    "harmonyShare.off('knockShare')",
    "SharableTarget.share()",
    "SharableTarget.reject()",
    "UIAbility.onCreate()",
    "UIAbility.onNewWant()"
  ],
  "deviceSupport": {
    "phone": true,
    "tablet": false,
    "minApiVersion": "5.0.0(12)"
  }
}
```

## 参考文档

- [API开发指南：邀请组队](references/knock-share-between-phones-group.md)
- [API参考：harmonyShare模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-harmony-share)
- [API参考：UIAbility生命周期](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiability)
- [开发指南：设置分享预览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/knock-share-between-phones-content)
- [开发指南：异常场景终止分享](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/knock-share-between-phones-content)

## 完整示例代码

- [ArkTS示例：组队邀请发送端](assets/group_invite_sender.ets)
- [ArkTS示例：组队邀请接收端](assets/group_invite_receiver.ets)
- [配置文件示例：权限配置](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试：成功注册碰一碰事件并分享组队链接](tests/test_positive_knock_share.ts)
- [测试：成功接收组队邀请链接并解析参数](tests/test_positive_receive_invite.ts)
- [测试：成功配置单向发送避免冲突](tests/test_positive_send_only.ts)

### 边界测试用例
- [测试：预览图文件大小接近上限（5MB）](tests/test_boundary_preview_size.ts)
- [测试：组队链接长度接近上限（2048字符）](tests/test_boundary_link_length.ts)
- [测试：标题/描述字符数接近上限](tests/test_boundary_text_length.ts)

### 异常测试用例
- [测试：windowId无效导致注册失败](tests/test_exception_invalid_windowid.ts)
- [测试：预览图文件不存在](tests/test_exception_missing_preview.ts)
- [测试：无网络导致分享失败](tests/test_exception_no_network.ts)
- [测试：Tablet设备不支持碰一碰](tests/test_exception_tablet_device.ts)
- [测试：双向sendOnly导致冲突](tests/test_exception_dual_sendonly.ts)