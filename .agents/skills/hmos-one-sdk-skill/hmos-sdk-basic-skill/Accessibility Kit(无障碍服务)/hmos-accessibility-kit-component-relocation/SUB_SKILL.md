---
name: hmos-accessibility-kit-component-relocation
description: 实现控件位置调整场景下的无障碍主动播报，支持拖拽过程中实时播报位置信息，确保视障用户听觉体验与视觉一致，适用于屏幕朗读优化场景
---

# 控件位置调整无障碍播报技能

## 功能描述

本技能实现控件位置调整场景下的无障碍主动播报功能。当控件被拖拽移动时，应用可调用主动播报接口实时播报即将移动到的位置，确保视障用户听到的信息与视觉看到的信息保持一致。

**核心能力**：
- 拖拽开始时播报控件被托起状态
- 拖拽过程中实时播报即将放置的位置信息
- 放置完成后播报最终位置信息
- 新位置播报会自动打断旧位置播报

## 使用场景

### 触发词
- "控件拖拽播报"
- "位置调整无障碍"
- "拖拽主动播报"
- "控件移动播报"
- "屏幕朗读拖拽场景"

### 能做
- 实现控件拖拽过程中的主动播报
- 提供实时的位置信息播报
- 确保播报内容与视觉体验一致
- 支持自定义播报文本内容
- 自动处理播报打断逻辑

### 绝不做
- 不处理非拖拽场景的无障碍播报
- 不替代系统级的无障碍服务
- 不处理控件焦点管理（请使用焦点设置技能）
- 不处理控件状态变化播报（请使用状态变化播报技能）

### 补充
- 仅适用于控件拖拽移动场景
- 需要配合拖拽手势事件使用
- 播报文本应简洁明确，便于视障用户理解

## 调用规范和规则

### 输入约束
- 播报文本长度：最大100字符
- 播报文本格式：建议使用"位置描述|控件名称"格式
- bundleName：必须为应用的bundle名称
- 触发时机：必须在拖拽事件回调中调用

### 执行约束
- 最大调用频次：每秒不超过5次（避免过度播报）
- 播报时机：拖拽开始、移动中、放置完成三个阶段
- 必须在主线程调用API

### 内容约束
- 禁止播报空文本
- 禁止播报包含特殊字符（如表情符号）
- 禁止在非拖拽场景调用播报
- 播报文本必须描述清晰的位置信息

### 降级约束
- API调用失败：记录日志并跳过播报，不影响拖拽功能
- 文本过长：自动截断至100字符
- 网络或系统异常：使用console提示用户

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查应用是否已导入AccessibilityKit模块
2. 验证当前是否处于拖拽场景
3. 确认bundleName配置正确
4. 准备播报文本内容

**参数准备**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

interface DragAccessibilityParams {
  bundleName: string;
  triggerAction: string;
  textAnnouncedForAccessibility: string;
}

const createEventInfo = (text: string): accessibility.EventInfo => {
  return {
    type: 'announceForAccessibility',
    bundleName: 'com.example.myapp',
    triggerAction: 'common',
    textAnnouncedForAccessibility: text
  };
};
```

### 步骤2：调用API播报

**示例代码**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

@Entry
@Component
struct DragComponent {
  private currentDragText: string = '';
  
  async announceDragPosition(text: string): Promise<void> {
    if (!text || text.trim().length === 0) {
      console.warn('[Accessibility] 播报文本为空，跳过播报');
      return;
    }
    
    if (text.length > 100) {
      text = text.substring(0, 100);
      console.warn('[Accessibility] 播报文本过长，已截断至100字符');
    }
    
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.samples.uiextensionandaccessibility',
      triggerAction: 'common',
      textAnnouncedForAccessibility: text
    };
    
    try {
      await accessibility.sendAccessibilityEvent(eventInfo);
      console.info(`[Accessibility] 播报成功: ${text}`);
      this.currentDragText = text;
    } catch (error) {
      console.error('[Accessibility] 播报失败:', error.message);
    }
  }
  
  build() {
    Column() {
      Button('可拖拽按钮')
        .accessibilityText('拖拽按钮')
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PanGesture({ fingers: 1 })
              .onActionStart(() => {
                this.announceDragPosition('华为专区已托起');
              })
              .onActionUpdate((event: GestureEvent) => {
                const newPosition = this.calculatePosition(event.offsetX, event.offsetY);
                this.announceDragPosition(`移动到${newPosition}`);
              })
              .onActionEnd(() => {
                this.announceDragPosition('已放置到华为手机服务区域');
              })
          )
        )
    }
  }
  
  private calculatePosition(offsetX: number, offsetY: number): string {
    if (offsetY < -50) {
      return '华为手机服务|华为官网上面';
    } else if (offsetY > 50) {
      return '华为手机服务|华为官网下面';
    } else {
      return '华为手机服务|华为官网旁边';
    }
  }
}
```

### 步骤3：错误处理

```typescript
async function safeAnnounce(eventInfo: accessibility.EventInfo): Promise<boolean> {
  try {
    if (!eventInfo.bundleName || eventInfo.bundleName.trim() === '') {
      console.error('[Accessibility] bundleName为空');
      return false;
    }
    
    if (!eventInfo.textAnnouncedForAccessibility || 
        eventInfo.textAnnouncedForAccessibility.trim() === '') {
      console.error('[Accessibility] 播报文本为空');
      return false;
    }
    
    await accessibility.sendAccessibilityEvent(eventInfo);
    return true;
  } catch (error) {
    const errorCode = error.code || 'UNKNOWN';
    const errorMsg = error.message || '未知错误';
    
    switch (errorCode) {
      case 'PERMISSION_DENIED':
        console.error('[Accessibility] 权限不足，请检查Accessibility权限');
        break;
      case 'SERVICE_UNAVAILABLE':
        console.error('[Accessibility] 无障碍服务不可用');
        break;
      case 'INVALID_PARAMETER':
        console.error('[Accessibility] 参数无效:', errorMsg);
        break;
      default:
        console.error('[Accessibility] 播报失败:', errorMsg);
    }
    
    return false;
  }
}
```

### 步骤4：降级处理

```typescript
class DragAccessibilityFallback {
  private announceQueue: string[] = [];
  private isAnnouncing: boolean = false;
  
  async announceWithFallback(text: string): Promise<void> {
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.example.app',
      triggerAction: 'common',
      textAnnouncedForAccessibility: text
    };
    
    const success = await this.safeAnnounce(eventInfo);
    
    if (!success) {
      this.addToQueue(text);
      this.processQueueFallback();
    }
  }
  
  private addToQueue(text: string): void {
    if (this.announceQueue.length < 5) {
      this.announceQueue.push(text);
    }
  }
  
  private async processQueueFallback(): Promise<void> {
    if (this.isAnnouncing || this.announceQueue.length === 0) {
      return;
    }
    
    this.isAnnouncing = true;
    const text = this.announceQueue.shift();
    
    console.warn('[Accessibility Fallback] 使用备用播报方式');
    console.info(`[Console Fallback] ${text}`);
    
    this.isAnnouncing = false;
    
    if (this.announceQueue.length > 0) {
      setTimeout(() => this.processQueueFallback(), 500);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| PERMISSION_DENIED | 缺少Accessibility权限 | 在module.json5中声明ohos.permission.ACCESSIBILITY权限 |
| SERVICE_UNAVAILABLE | 无障碍服务未启动 | 提示用户在系统设置中开启屏幕朗读功能 |
| INVALID_PARAMETER | EventInfo参数无效 | 检查bundleName和textAnnouncedForAccessibility是否正确 |
| TEXT_TOO_LONG | 播报文本过长 | 截断文本至100字符以内 |
| EMPTY_TEXT | 播报文本为空 | 确保textAnnouncedForAccessibility不为空 |
| CALL_FREQUENCY_LIMIT | 调用频次超限 | 降低调用频次，每秒不超过5次 |
| THREAD_ERROR | 非主线程调用 | 确保在UI主线程调用API |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccessibilityKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API Version：API 12及以上
- DevEco Studio：5.0及以上
- 无障碍服务：系统屏幕朗读功能已开启

### 常见编译问题

**问题1：找不到@kit.AccessibilityKit模块**
```
Error: Cannot find module '@kit.AccessibilityKit'
```
**解决方法**：确保HarmonyOS SDK版本为API 12及以上，检查module.json5中的依赖声明

**问题2：sendAccessibilityEvent未定义**
```
Error: Property 'sendAccessibilityEvent' does not exist on type 'accessibility'
```
**解决方法**：检查导入语句是否正确：`import { accessibility } from '@kit.AccessibilityKit'`

**问题3：EventInfo类型错误**
```
Error: Type 'EventInfo' is not assignable
```
**解决方法**：确保EventInfo对象包含必需字段：type、bundleName、triggerAction、textAnnouncedForAccessibility

**问题4：权限不足**
```
Error: Permission denied for accessibility event
```
**解决方法**：在module.json5中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESSIBILITY"
      }
    ]
  }
}
```

## 常见问题与解决方法

### Q1：播报文本应该包含哪些内容？
**原因**：播报文本需要简洁明确，便于视障用户快速理解
**解决方法**：
- 拖拽开始：播报"控件名称+已托起"
- 拖拽移动：播报"移动到+目标位置"
- 放置完成：播报"已放置到+最终位置"
- 使用"|"分隔位置层级信息

### Q2：如何避免过度播报？
**原因**：频繁调用播报会影响用户体验
**解决方法**：
- 限制调用频次（每秒最多5次）
- 只在关键位置变化时播报
- 使用节流机制控制播报频率
- 新播报自动打断旧播报

### Q3：拖拽过程中如何实时计算位置？
**原因**：需要根据拖拽偏移量判断当前位置
**解决方法**：
- 使用GestureEvent的offsetX和offsetY
- 定义位置区域阈值（如上下各50像素）
- 根据偏移量判断相对于目标的位置
- 返回清晰的相对位置描述

### Q4：播报失败如何处理？
**原因**：系统无障碍服务可能未启动或权限不足
**解决方法**：
- 检查系统设置中的屏幕朗读功能
- 验证应用权限配置
- 使用降级方案（console日志）
- 不影响拖拽功能正常使用

### Q5：如何处理多语言播报？
**原因**：应用可能需要支持多种语言的播报
**解决方法**：
- 根据系统语言设置动态生成播报文本
- 提供多语言的播报文本模板
- 使用国际化API获取当前语言
- 参考多语种场景技能实现

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "播报内容": "移动到华为手机服务|华为官网上面",
  "播报时机": "拖拽移动中",
  "apiUsed": [
    "accessibility.sendAccessibilityEvent"
  ],
  "eventInfo": {
    "type": "announceForAccessibility",
    "bundleName": "com.samples.uiextensionandaccessibility",
    "triggerAction": "common",
    "textAnnouncedForAccessibility": "移动到华为手机服务|华为官网上面"
  }
}
```

## 参考文档

- [控件位置调整场景开发指南](references/scenario-component-relocation.md)
- [提升屏幕朗读无障碍体验总览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/improve-screen-reader-experience)

## 完整示例代码

- [ArkTS拖拽播报完整示例](assets/drag-announce-example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [拖拽开始播报测试](tests/test_drag_start.py)：验证拖拽开始时正确播报托起状态
- [拖拽移动播报测试](tests/test_drag_move.py)：验证拖拽过程中实时播报位置信息
- [拖拽完成播报测试](tests/test_drag_end.py)：验证放置完成后播报最终位置

### 边界测试用例
- [播报文本长度测试](tests/test_text_length.py)：验证100字符长度限制
- [调用频次测试](tests/test_call_frequency.py)：验证每秒5次调用限制
- [位置计算测试](tests/test_position_calculation.py)：验证位置阈值计算准确性

### 异常测试用例
- [空文本播报测试](tests/test_empty_text.py)：验证空文本的降级处理
- [权限不足测试](tests/test_permission_denied.py)：验证权限缺失的错误处理
- [服务不可用测试](tests/test_service_unavailable.py)：验证无障碍服务未启动的降级方案