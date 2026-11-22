---
name: hmos-share-kit-close-share-panel
description: 关闭分享详情页的分享面板，支持ERROR/BACK/CLOSE三种返回模式，适用于分享完成后关闭面板、返回分享面板或错误提示场景
---

# 分享详情页关闭分享面板技能

## 功能描述

从分享详情页返回分享面板或关闭分享面板，通过设置resultCode值为特定的ShareAbilityResultCode，以告知分享面板做出不同的处理。支持三种处理模式：

- **ERROR**：返回分享面板，并提示用户发生错误
- **BACK**：正常返回分享面板
- **CLOSE**：关闭分享面板

该功能仅适用于Stage模型下的ShareExtensionAbility场景。

## 使用场景

### 触发词
- "关闭分享面板"
- "返回分享面板"
- "分享完成关闭"
- "分享错误处理"

### 能做
- 通过terminateSelfWithResult接口关闭分享面板
- 控制分享面板的返回行为（返回/关闭）
- 在发生错误时返回分享面板并提示用户
- 在分享完成后关闭分享面板

### 绝不做
- 不适用于非ShareExtensionAbility场景
- 不处理分享内容的具体逻辑
- 不替代分享面板的UI配置

### 补充
- 仅在API version 5.0.0(12)及以上版本可用
- 仅支持Stage模型
- 需要继承ShareExtensionAbility实现分享详情页

## 调用规范和规则

### 输入约束
- resultCode必须为systemShare.ShareAbilityResultCode枚举值
- 可选传递message参数用于ERROR场景的toast提示
- 仅在ShareExtensionAbility的onSessionCreate回调中调用

### 执行约束
- 必须在ShareExtensionAbility生命周期内调用
- terminateSelfWithResult调用后立即结束当前session
- 不能在同一session中多次调用

### 内容约束
- 禁止使用非法的resultCode值
- 禁止在非ShareExtensionAbility场景调用
- 禁止跳过session参数直接调用

### 降级约束
- resultCode参数错误：使用默认BACK模式
- session不存在：使用terminateSelf关闭
- 版本不支持：提示用户升级API版本

## 调用流程和步骤

### 步骤1：导入相关模块

**前置校验**：
1. 确认项目使用Stage模型
2. 确认API version >= 5.0.0(12)
3. 确认已创建ShareExtensionAbility类

**模块导入**：
```typescript
import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
```

### 步骤2：实现ShareExtensionAbility

**创建分享详情页类**：
```typescript
export default class TestShareAbility extends ShareExtensionAbility {
  async onSessionCreate(want: Want, session: UIExtensionContentSession) {
    try {
      // 处理分享数据
      const sharedData = await systemShare.getSharedData(want);
      const records = sharedData.getRecords();
      
      // 处理分享内容逻辑
      // ...
      
      // 分享完成后关闭分享面板
      session.terminateSelfWithResult({
        resultCode: systemShare.ShareAbilityResultCode.CLOSE
      });
      
    } catch (error) {
      console.error('处理分享数据失败:', error);
      // 发生错误时返回分享面板并提示
      session.terminateSelfWithResult({
        resultCode: systemShare.ShareAbilityResultCode.ERROR
      });
    }
  }
}
```

### 步骤3：处理不同场景

**场景1：分享成功后关闭面板**：
```typescript
// 分享完成后直接关闭分享面板
session.terminateSelfWithResult({
  resultCode: systemShare.ShareAbilityResultCode.CLOSE
});
```

**场景2：返回分享面板继续选择**：
```typescript
// 用户取消分享或需要重新选择目标
session.terminateSelfWithResult({
  resultCode: systemShare.ShareAbilityResultCode.BACK
});
```

**场景3：发生错误提示用户**：
```typescript
// 处理分享内容时发生错误
session.terminateSelfWithResult({
  resultCode: systemShare.ShareAbilityResultCode.ERROR
});
// 如果同时传递message参数，将弹出toast提示
```

### 步骤4：错误处理

```typescript
try {
  // 处理分享逻辑
  await processShareData(sharedData);
  
  // 成功后关闭面板
  session.terminateSelfWithResult({
    resultCode: systemShare.ShareAbilityResultCode.CLOSE
  });
  
} catch (error) {
  console.error('分享处理失败:', error.code, error.message);
  
  // 根据错误类型选择处理方式
  if (error.code === 1003703001) {
    // 数据解析失败，返回分享面板提示用户
    session.terminateSelfWithResult({
      resultCode: systemShare.ShareAbilityResultCode.ERROR
    });
  } else {
    // 其他错误，正常返回分享面板
    session.terminateSelfWithResult({
      resultCode: systemShare.ShareAbilityResultCode.BACK
    });
  }
}
```

### 步骤5：降级处理

```typescript
// 版本检查降级方案
if (systemShare.ShareAbilityResultCode === undefined) {
  console.warn('当前API版本不支持ShareAbilityResultCode，使用terminateSelf关闭');
  session.terminateSelf();
  return;
}

// 参数校验降级方案
const resultCode = validateResultCode(userInputCode);
if (!resultCode) {
  console.warn('resultCode参数无效，使用默认BACK模式');
  session.terminateSelfWithResult({
    resultCode: 0 // BACK
  });
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查resultCode是否为有效枚举值 |
| 1003703001 | 解析数据失败 | 检查want参数是否包含有效的分享数据 |
| -1 | 分享处理发生错误 | 检查分享内容处理逻辑，使用ERROR模式提示用户 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AbilityKit": "^5.0.0",
    "@kit.ShareKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS API：>= 5.0.0(12)
- 开发模型：Stage模型
- 设备类型：支持ShareExtensionAbility的设备

### 常见编译问题

**问题1：ShareAbilityResultCode未定义**
```
TypeError: Cannot read property 'ShareAbilityResultCode' of undefined
```
**解决方法**：确认API版本>=5.0.0(12)，检查导入语句是否正确

**问题2：session不存在**
```
TypeError: session is undefined
```
**解决方法**：确保在onSessionCreate回调中调用，检查session参数传递

**问题3：terminateSelfWithResult调用失败**
```
BusinessError: Parameter error
```
**解决方法**：检查resultCode参数是否为有效枚举值，确认参数格式正确

## 常见问题与解决方法

### Q1：如何判断使用哪种resultCode模式？
**原因**：不同场景需要不同的返回方式
**解决方法**：
- 分享成功完成：使用CLOSE关闭面板
- 用户取消或需重新选择：使用BACK返回面板
- 处理过程中发生错误：使用ERROR提示用户

### Q2：ERROR模式如何显示提示信息？
**原因**：ERROR模式可以显示toast提示
**解决方法**：在terminateSelfWithResult中传递message参数，系统会自动显示toast提示

### Q3：可以在非onSessionCreate中调用吗？
**原因**：session生命周期限制
**解决方法**：必须在ShareExtensionAbility的生命周期回调中调用（onSessionCreate、onSessionDestroy等），确保session有效

### Q4：如何处理API版本不兼容？
**原因**：ShareAbilityResultCode从API 5.0.0(12)开始支持
**解决方法**：
- 检查systemShare.ShareAbilityResultCode是否存在
- 如果不存在，使用terminateSelf作为降级方案

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "resultCode": 1,
  "resultCodeName": "CLOSE",
  "apiUsed": [
    "ShareExtensionAbility",
    "UIExtensionContentSession.terminateSelfWithResult",
    "systemShare.ShareAbilityResultCode"
  ],
  "message": "分享面板已关闭"
}
```

## 参考文档

- [API开发指南 - 分享详情页关闭分享面板](share-sec-panel-back.md)
- [API参考说明 - systemShare](share-system-share.md)
- [API参考说明 - ShareExtensionAbility](js-apis-app-ability-shareextensionability.md)

## 完整示例代码

- [ArkTS示例 - 关闭分享面板](assets/close_share_panel_example.ets)

## 测试用例

### 正向测试用例
- [测试分享成功关闭面板](tests/test_close_success.ts)：验证分享成功后CLOSE模式关闭面板
- [测试返回分享面板](tests/test_back_panel.ts)：验证BACK模式返回分享面板

### 边界测试用例
- [测试多次调用](tests/test_multiple_calls.ts)：验证同一session多次调用terminateSelfWithResult的处理

### 异常测试用例
- [测试无效resultCode](tests/test_invalid_resultcode.ts)：验证非法resultCode的降级处理
- [测试错误场景](tests/test_error_scenario.ts)：验证ERROR模式的toast提示功能