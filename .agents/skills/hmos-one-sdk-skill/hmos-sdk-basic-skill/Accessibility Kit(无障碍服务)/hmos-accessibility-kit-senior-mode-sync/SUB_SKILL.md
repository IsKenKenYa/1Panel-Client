---
name: hmos-accessibility-kit-senior-mode-sync
description: 同步应用内关怀模式与系统设置状态，支持查询/设置/监听关怀模式开关，适用于长辈关怀应用、无障碍服务场景，API版本26.0.0+
---

# 应用内关怀模式与系统设置同步技能

## 功能描述

本技能提供应用内关怀模式与设备"设置"中应用管理页面关怀模式状态的同步功能。支持查询、设置和监听关怀模式开关状态，确保应用内关怀模式与系统设置保持一致，为长辈用户提供统一的关怀体验。

**核心能力**：
- 查询系统关怀模式状态
- 设置应用关怀模式状态并同步到系统
- 监听系统关怀模式状态变化
- 自动同步应用内UI与系统设置

**适用范围**：HarmonyOS API版本26.0.0及以上，适用于需要提供长辈关怀模式的应用。

## 使用场景

### 触发词
- "长辈关怀模式"
- "关怀模式同步"
- "Senior Mode"
- "应用内关怀模式"
- "无障碍关怀模式"

### 能做
- 查询设备"设置"中应用管理页面的关怀模式开关状态
- 设置应用内关怀模式状态并同步到系统"设置"
- 监听系统关怀模式状态变化并自动更新应用内UI
- 在应用启动时自动同步关怀模式状态
- 在用户切换应用内关怀模式时同步更新系统设置

### 绝不做
- 不处理其他应用的关怀模式设置
- 不修改系统全局关怀模式设置
- 不在API版本低于26.0.0的环境中使用
- 不在没有权限的情况下强制修改关怀模式状态

### 补充
- 本技能仅适用于应用自身的关怀模式管理
- 需要用户在系统"设置"中授予关怀模式权限
- API版本要求：26.0.0及以上
- 必须在主线程中调用相关API

## 调用规范和规则

### 输入约束
- 无特殊输入参数限制
- 状态值必须为boolean类型（true/false）
- 监听回调函数必须为Callback<boolean>类型

### 执行约束
- 所有API调用必须在UI线程执行
- 建议在组件生命周期方法中注册/取消监听
- 避免频繁调用setSeniorModeStateForSelf，建议用户主动触发
- 监听回调应在组件销毁时取消注册

### 内容约束
- 禁止在后台线程调用关怀模式API
- 禁止在应用启动前调用监听API
- 禁止在回调函数中执行耗时操作
- 禁止使用未验证的状态值调用setSeniorModeStateForSelf

### 降级约束
- API版本低于26.0.0：提示用户升级系统版本，使用应用内独立关怀模式设置
- 权限不足：提示用户前往系统设置授权
- 监听注册失败：使用定时查询方式作为降级方案（建议间隔5秒）

## 调用流程和步骤

### 步骤1：导入模块

**前置校验**：
1. 检查API版本是否≥26.0.0
2. 检查是否已导入AccessibilityKit模块

**代码示例**：
```typescript
import accessibility from '@ohos.accessibility';
```

### 步骤2：应用启动时查询关怀模式状态

**场景描述**：应用启动时，查询系统设置中的关怀模式开关状态，并同步到应用内UI。

**代码示例**：
```typescript
@Entry
@Component
struct SeniorModePage {
  @State seniorModeState: boolean = false;
  
  async aboutToAppear(): Promise<void> {
    try {
      // 查询系统设置中的关怀模式状态
      this.seniorModeState = await accessibility.getSeniorModeStateForSelf();
      console.info(`Initial senior mode state: ${this.seniorModeState}`);
      
      // 根据状态更新UI
      this.updateSeniorModeUI(this.seniorModeState);
    } catch (error) {
      console.error(`Failed to get senior mode state: ${error.message}`);
      // 降级处理：使用默认关闭状态
      this.seniorModeState = false;
    }
  }
  
  updateSeniorModeUI(state: boolean): void {
    // 更新UI显示逻辑
    // 例如：调整字体大小、图标尺寸、布局等
  }
  
  build() {
    Column() {
      // UI内容
    }
  }
}
```

### 步骤3：监听系统关怀模式状态变化

**场景描述**：注册监听器，当用户在系统设置中切换关怀模式时，自动更新应用内状态。

**代码示例**：
```typescript
@Entry
@Component
struct SeniorModePage {
  @State seniorModeState: boolean = false;
  
  // 定义监听回调函数
  seniorModeCallback = (state: boolean): void => {
    console.info(`Senior mode state changed: ${state}`);
    this.seniorModeState = state;
    this.updateSeniorModeUI(state);
  }
  
  aboutToAppear(): void {
    // 注册监听
    accessibility.onSeniorModeStateChangeForSelf(this.seniorModeCallback);
  }
  
  aboutToDisappear(): void {
    // 取消监听，避免内存泄漏
    accessibility.offSeniorModeStateChangeForSelf(this.seniorModeCallback);
  }
  
  updateSeniorModeUI(state: boolean): void {
    // 根据状态更新关怀模式UI
  }
  
  build() {
    Column() {
      // UI内容
    }
  }
}
```

### 步骤4：用户手动切换关怀模式

**场景描述**：用户在应用内切换关怀模式开关，同步更新到系统设置。

**代码示例**：
```typescript
@Entry
@Component
struct SeniorModePage {
  @State seniorModeState: boolean = false;
  
  async toggleSeniorMode(isOn: boolean): Promise<void> {
    try {
      // 防止重复设置
      if (isOn === this.seniorModeState) {
        console.info(`Senior mode state unchanged: ${isOn}`);
        return;
      }
      
      // 更新本地状态
      this.seniorModeState = isOn;
      
      // 同步到系统设置
      await accessibility.setSeniorModeStateForSelf(isOn);
      console.info(`Senior mode set to: ${isOn}`);
      
      // 更新UI
      this.updateSeniorModeUI(isOn);
    } catch (error) {
      console.error(`Failed to set senior mode: ${error.message}`);
      // 回滚状态
      this.seniorModeState = !isOn;
      // 提示用户
      this.showErrorMessage('关怀模式设置失败，请检查系统权限');
    }
  }
  
  updateSeniorModeUI(state: boolean): void {
    // 更新UI逻辑
  }
  
  showErrorMessage(message: string): void {
    // 显示错误提示
  }
  
  build() {
    Column() {
      Row() {
        Text('长辈关怀模式')
          .fontSize(18)
        Toggle({ type: ToggleType.Switch, isOn: this.seniorModeState })
          .onChange(async (isOn: boolean) => {
            await this.toggleSeniorMode(isOn);
          })
      }
    }
  }
}
```

### 步骤5：错误处理和降级方案

**场景描述**：处理API调用失败、权限不足等异常情况。

**代码示例**：
```typescript
async aboutToAppear(): Promise<void> {
  try {
    // 尝试获取关怀模式状态
    this.seniorModeState = await accessibility.getSeniorModeStateForSelf();
  } catch (error) {
    // 错误处理
    const errorCode = error.code;
    
    switch (errorCode) {
      case 401:
        // 参数错误
        console.error('Parameter error in getSeniorModeStateForSelf');
        break;
      case 201:
        // 权限不足
        console.error('Permission denied for senior mode');
        this.showPermissionDialog();
        break;
      default:
        // 其他错误，使用降级方案
        console.error(`Unknown error: ${error.message}`);
        this.useFallbackMode();
        break;
    }
    
    // 降级：使用默认关闭状态
    this.seniorModeState = false;
  }
}

// 降级方案：定时查询关怀模式状态
useFallbackMode(): void {
  // 每5秒查询一次关怀模式状态
  setInterval(async () => {
    try {
      const state = await accessibility.getSeniorModeStateForSelf();
      if (state !== this.seniorModeState) {
        this.seniorModeState = state;
        this.updateSeniorModeUI(state);
      }
    } catch (error) {
      console.error('Fallback query failed');
    }
  }, 5000);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。参数类型不正确或参数缺失 | 检查参数类型，确保为boolean类型；检查参数是否完整 |
| 201 | 权限不足。应用未获得关怀模式设置权限 | 引导用户前往系统设置授予关怀模式权限 |
| 202 | API版本不支持。当前系统版本低于API 26.0.0 | 提示用户升级系统版本，或使用应用内独立关怀模式设置 |
| 203 | 系统服务异常。关怀模式服务不可用 | 等待一段时间后重试，或使用降级方案 |

## 编译和修复问题

### 依赖声明

**模块导入**：
```typescript
import accessibility from '@ohos.accessibility';
```

**模块说明**：从API version 26.0.0开始，accessibility模块提供关怀模式相关接口。

### 环境要求
- HarmonyOS API版本：26.0.0及以上
- DevEco Studio版本：建议使用最新版本
- ArkTS语言支持：需启用ArkTS语法

### 常见编译问题

**问题1：API不存在错误**
```
Error: 'getSeniorModeStateForSelf' is not defined
```
**解决方法**：
- 检查API版本配置，确保目标API版本≥26.0.0
- 在build-profile.json5中设置正确的compileSdkVersion
- 确认已正确导入accessibility模块

**问题2：类型错误**
```
Error: Type 'boolean' is not assignable to type 'Promise<boolean>'
```
**解决方法**：
- 确保使用await关键字调用Promise类型API
- 检查async/await语法使用是否正确

**问题3：监听回调类型错误**
```
Error: Argument type '() => void' is not assignable to parameter type 'Callback<boolean>'
```
**解决方法**：
- 确保回调函数参数类型为Callback<boolean>
- 修改回调函数定义：`callback = (data: boolean) => { ... }`

## 常见问题与解决方法

### Q1：应用启动时关怀模式状态不正确
**原因**：可能是系统设置中的关怀模式状态与应用内状态不同步。
**解决方法**：
- 在aboutToAppear中调用getSeniorModeStateForSelf查询系统状态
- 根据查询结果更新应用内UI
- 注册监听器监听系统状态变化

### Q2：监听器未触发
**原因**：监听器注册失败或回调函数定义错误。
**解决方法**：
- 确保监听器在aboutToAppear中注册
- 检查回调函数类型是否正确（Callback<boolean>）
- 确认系统设置中关怀模式确实发生变化

### Q3：设置关怀模式失败
**原因**：权限不足或API调用时机错误。
**解决方法**：
- 检查应用是否有关怀模式设置权限
- 引导用户前往系统设置授权
- 确保API调用在主线程执行
- 使用try-catch捕获异常并提示用户

### Q4：API版本不支持
**原因**：当前系统API版本低于26.0.0。
**解决方法**：
- 提示用户升级系统版本
- 使用应用内独立关怀模式设置作为降级方案
- 在代码中添加API版本检查逻辑

### Q5：内存泄漏
**原因**：监听器未在组件销毁时取消注册。
**解决方法**：
- 在aboutToDisappear中调用offSeniorModeStateChangeForSelf取消监听
- 确保回调函数引用一致（注册和取消使用同一个回调函数对象）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "seniorModeState": "boolean",
  "syncedWithSystem": "boolean",
  "apiUsed": [
    "accessibility.getSeniorModeStateForSelf",
    "accessibility.setSeniorModeStateForSelf",
    "accessibility.onSeniorModeStateChangeForSelf",
    "accessibility.offSeniorModeStateChangeForSelf"
  ]
}
```

**状态说明**：
- `success`：关怀模式同步成功
- `failed`：关怀模式同步失败，需要检查错误信息
- `fallback`：使用降级方案，定时查询状态

## 参考文档

- [应用内关怀模式与系统设置同步开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-senior-mode-description)
- [@ohos.accessibility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)

## 完整示例代码

- [ArkTS完整示例](assets/senior_mode_example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试关怀模式查询](tests/test_get_senior_mode.ets)：验证查询系统关怀模式状态
- [测试关怀模式设置](tests/test_set_senior_mode.ets)：验证设置应用内关怀模式状态
- [测试关怀模式监听](tests/test_listen_senior_mode.ets)：验证监听系统关怀模式变化

### 边界测试用例
- [测试API版本检查](tests/test_api_version.ets)：验证API版本26.0.0检查逻辑
- [测试权限处理](tests/test_permission.ets)：验证权限不足时的降级处理

### 异常测试用例
- [测试错误处理](tests/test_error_handling.ets)：验证各种错误码的处理逻辑
- [测试降级方案](tests/test_fallback.ets)：验证定时查询降级方案的有效性