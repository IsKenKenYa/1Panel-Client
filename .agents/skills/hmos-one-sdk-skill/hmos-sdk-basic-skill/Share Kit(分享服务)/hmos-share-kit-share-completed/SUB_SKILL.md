---
name: hmos-share-kit-share-completed
description: 监听用户分享完成事件并获取分享渠道信息，支持系统操作和第三方应用识别，适用于分享数据统计场景，API版本5.1.0(18)及以上
---

# 获取分享结果技能

## 功能描述

本技能用于实现HarmonyOS宿主应用获取用户分享操作结果的功能。通过注册shareCompleted事件监听，可以获取用户分享到的渠道信息，包括系统操作（复制、保存至图库、打印等）和第三方应用，适用于分享功能使用情况统计和数据分析场景。

**核心能力**：
- 监听用户完成分享事件
- 获取分享渠道名称（系统操作或第三方应用）
- 支持数据统计和分析

**技术特点**：
- 异步事件监听机制
- 返回分享渠道详细信息
- 仅支持Stage模型
- API版本要求：5.1.0(18)及以上

## 使用场景

### 触发词
- "获取分享结果"
- "监听分享完成"
- "统计分享渠道"
- "分享数据统计"
- "获取用户分享到了哪里"

### 能做
- 监听用户完成分享操作的事件
- 获取用户分享的具体渠道名称
- 统计用户分享到了哪些系统操作（复制、保存、打印等）
- 统计用户分享到了哪些第三方应用
- 用于数据分析和用户行为统计

### 绝不做
- 不在API版本低于5.1.0(18)的环境中使用
- 不在TV设备上使用（TV设备无效果）
- 不用于修改分享内容或干预分享流程
- 不直接执行分享操作（仅监听结果）

### 补充
- 渠道信息规则：系统操作有固定名称（参见ShareAbilityName），非系统操作采用'[bundleName]#[moduleName]#[abilityName]'格式
- 需要在分享面板显示前注册监听事件
- TV设备不支持此功能

## 调用规范和规则

### 输入约束
- 分享数据对象：必须包含至少一条有效的SharedRecord
- 数据类型：支持PLAIN_TEXT、TEXT、IMAGE、VIDEO、AUDIO、FILE等UDMF标准类型
- 数据大小：单条记录不超过IPC传输上限，总数据不超过200KB
- 记录数量：最多支持500条数据记录

### 执行约束
- 必须在分享面板显示前注册监听
- 监听事件名称必须为'shareCompleted'
- 回调函数必须接收ShareOperationResult类型参数
- API版本必须≥5.1.0(18)

### 内容约束
- 禁止修改ShareOperationResult返回值
- 禁止在回调函数中执行耗时操作
- 禁止阻塞分享面板关闭流程
- 必须正确处理异常情况

### 降级约束
- API版本低于5.1.0(18)：提示用户不支持此功能，使用dismiss事件监听替代
- TV设备：提示不支持，使用dismiss事件监听替代
- 获取渠道信息失败：记录错误日志，继续执行分享流程

## 调用流程和步骤

### 步骤1：准备阶段

**导入必要模块**：
```typescript
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
```

**前置校验**：
1. 检查API版本是否≥5.1.0(18)
2. 检查当前设备是否为TV（TV不支持）
3. 确认分享数据对象已正确构造

### 步骤2：构造分享数据

**创建SharedData对象**：
```typescript
let data: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.PLAIN_TEXT,
  content: 'Hello HarmonyOS'
});
```

**参数说明**：
- utd：统一数据类型，建议使用精准类型以匹配目标应用
- content：分享内容（文本、链接等）
- uri：文件URI（可选，与content至少有一个）

### 步骤3：创建ShareController并注册监听

**构建控制器**：
```typescript
let controller: systemShare.ShareController = new systemShare.ShareController(data);
```

**注册分享结果监听**：
```typescript
controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
  console.info('shareCompleted name:', result.targetAbilityInfo.name);
  
  if (result.targetAbilityInfo.name.startsWith('SystemShare_')) {
    console.info('系统操作:', result.targetAbilityInfo.name);
  } else {
    console.info('第三方应用:', result.targetAbilityInfo.name);
  }
});
```

### 步骤4：显示分享面板

**获取UIAbility上下文**：
```typescript
let uiContext: UIContext = this.getUIContext();
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
```

**启动分享面板**：
```typescript
controller.show(context, {
  previewMode: systemShare.SharePreviewMode.DEFAULT,
  selectionMode: systemShare.SelectionMode.SINGLE
}).then(() => {
  console.info('分享面板显示成功');
}).catch((error: BusinessError) => {
  console.error(`分享面板显示失败: code=${error.code}, message=${error.message}`);
});
```

### 步骤5：错误处理

**错误码处理示例**：
```typescript
try {
  await controller.show(context, options);
} catch (error) {
  let err = error as BusinessError;
  switch (err.code) {
    case 401:
      console.error('参数错误');
      break;
    case 1003702001:
      console.error('记录类型不支持');
      break;
    case 1003702002:
      console.error('IPC数据超限');
      break;
    default:
      console.error(`未知错误: ${err.code}, ${err.message}`);
  }
}
```

### 步骤6：降级处理

**API版本兼容处理**：
```typescript
function setupShareListener(controller: systemShare.ShareController) {
  if (canIUse('SystemCapability.Collaboration.SystemShare@5.1.0')) {
    controller.on('shareCompleted', (result) => {
      console.info('分享渠道:', result.targetAbilityInfo.name);
    });
  } else {
    controller.on('dismiss', () => {
      console.warn('当前API版本不支持获取分享结果，仅监听面板关闭');
    });
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查SharedData构造参数是否正确，确保utd和content/uri字段有效 |
| 1003700001 | 记录数量超过上限 | 减少数据记录数量，最大支持500条 |
| 1003702001 | 记录类型不支持 | 检查批量模式或多选模式下仅支持FILE类型 |
| 1003702002 | IPC数据超限 | 压缩分享数据大小，总数据不超过200KB |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "5.1.0(18)",
    "@kit.AbilityKit": "4.1.0(11)",
    "@kit.ArkData": "4.1.0(11)"
  }
}
```

### 环境要求
- HarmonyOS API版本：≥5.1.0(18)
- Stage模型：仅支持Stage模型
- 设备类型：不支持TV设备

### 常见编译问题

**问题1：API版本不匹配**
```
Property 'on' does not exist on type 'ShareController'
```
**解决方法**：确保项目配置的minAPIVersion≥5.1.0(18)，检查build-profile.json5中的compatibleSdkVersion配置

**问题2：类型定义缺失**
```
Cannot find name 'ShareOperationResult'
```
**解决方法**：更新SDK到最新版本，确保包含5.1.0(18)版本的API定义

**问题3：导入模块失败**
```
Cannot find module '@kit.ShareKit'
```
**解决方法**：检查oh_modules目录，运行`ohpm install`重新安装依赖

## 常见问题与解决方法

### Q1：如何区分系统操作和第三方应用？
**原因**：渠道名称格式不同
**解决方法**：
- 系统操作：名称以`SystemShare_`开头，如`SystemShare_CopyToPasteboard`
- 第三方应用：格式为`[bundleName]#[moduleName]#[abilityName]`

### Q2：TV设备上监听不生效？
**原因**：TV设备不支持shareCompleted事件
**解决方法**：
- TV设备使用dismiss事件监听面板关闭
- 提示用户当前设备不支持获取分享渠道

### Q3：API版本低于5.1.0如何处理？
**原因**：shareCompleted事件需要API版本5.1.0(18)及以上
**解决方法**：
- 使用dismiss事件监听面板关闭
- 提示用户升级系统版本以支持完整功能

### Q4：如何取消监听？
**原因**：需要移除已注册的监听事件
**解决方法**：
```typescript
controller.off('shareCompleted', callback);
// 或清空所有监听
controller.off('shareCompleted');
```

### Q5：分享数据记录数量限制？
**原因**：IPC传输和数据大小限制
**解决方法**：
- 最大支持500条数据记录
- 总数据大小不超过200KB
- 批量模式仅支持FILE类型记录

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "shareChannel": "SystemShare_CopyToPasteboard",
  "channelType": "system",
  "apiUsed": [
    "systemShare.SharedData",
    "systemShare.ShareController",
    "ShareController.on('shareCompleted')",
    "ShareController.show()"
  ],
  "apiVersion": "5.1.0(18)",
  "deviceSupport": true
}
```

## 参考文档

- [获取分享结果开发指南](references/share-share-completed.md)
- [systemShare API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [ShareAbilityName定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)

## 完整示例代码

- [ArkTS完整示例](assets/share-completed-example.ets)
- [数据统计示例](assets/share-statistics-example.ets)
- [错误处理示例](assets/error-handling-example.ets)

## 测试用例

### 正向测试用例
- [监听文本分享完成](tests/test_positive.py)：测试文本分享到系统操作的场景
- [监听文件分享完成](tests/test_positive.py)：测试文件分享到第三方应用的场景

### 边界测试用例
- [多记录分享](tests/test_boundary.py)：测试分享500条数据记录的场景
- [大数据分享](tests/test_boundary.py)：测试分享数据接近200KB的场景

### 异常测试用例
- [API版本不兼容](tests/test_exception.py)：测试API版本低于5.1.0的场景
- [TV设备测试](tests/test_exception.py)：测试在TV设备上的行为
- [参数错误](tests/test_exception.py)：测试构造SharedData参数缺失的场景