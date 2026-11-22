---
name: hmos-accessibility-kit-modal-dialog-focus
description: 设置弹窗类控件的模态类型（模态/非模态），控制屏幕朗读模式下焦点行为，支持Popup/Menu/Dialog/bindSheet，适用于无障碍适配场景
---

# 弹窗类控件走焦场景技能

## 功能描述

本技能用于在HarmonyOS应用中实现弹窗类控件的无障碍走焦功能，通过设置弹窗的模态类型（模态/非模态）来控制屏幕朗读模式下的焦点行为。支持模态弹窗和非模态弹窗两种类型：

- **模态弹窗**：强交互形式，屏幕朗读模式下焦点自动聚焦到弹窗，弹窗关闭前无法聚焦到弹窗外节点
- **非模态弹窗**：弱交互形式，屏幕朗读模式下焦点默认聚焦到弹窗，允许聚焦到弹窗外节点

支持设置模态类型的弹窗控件包括：
- Popup
- Menu
- Dialog
- bindSheet

## 使用场景

### 触发词
- "弹窗无障碍适配"
- "设置弹窗模态类型"
- "弹窗走焦控制"
- "屏幕朗读弹窗焦点"
- "Accessibility Kit 弹窗"

### 能做
- 设置CustomDialogController的模态类型（isModal参数）
- 实现模态弹窗的焦点锁定功能
- 实现非模态弹窗的焦点控制功能
- 处理弹窗关闭时的焦点恢复
- 配置弹窗的关闭行为（onWillDismiss）
- 设置弹窗的显示位置和对齐方式（alignment）

### 绝不做
- 不处理非弹窗类控件的无障碍适配
- 不替代屏幕朗读服务的核心功能
- 不处理超出Accessibility Kit范围的请求
- 不创建非CustomDialog类型的弹窗实现

### 补充
- 模态弹窗适用于需要用户必须响应的场景（如重要提示、确认对话框）
- 非模态弹窗适用于信息提示场景（如Toast、轻量提示）
- 子窗形式的非模态弹窗只能通过不抬手走焦或触摸聚焦的方式聚焦到弹窗外节点

## 调用规范和规则

### 输入约束
- 弹窗标题长度：不超过50字符
- 弹窗内容长度：不超过200字符
- 弹窗尺寸：宽度最小200vp，高度最小150vp
- 按钮数量：最多2个按钮（primaryButton和secondaryButton）

### 执行约束
- 弹窗显示耗时：不超过1秒
- 弹窗关闭耗时：不超过0.5秒
- 最大弹窗数量：同时最多显示1个模态弹窗
- 焦点切换响应时间：不超过100毫秒

### 内容约束
- 禁止生成包含敏感信息的弹窗内容
- 禁止使用硬编码的弹窗ID
- 禁止创建无限循环的弹窗显示逻辑
- 禁止在弹窗内嵌套其他弹窗

### 降级约束
- CustomDialogController初始化失败：提示用户重新触发弹窗
- 弹窗显示失败：使用Toast替代方案
- 焦点控制失败：回退到系统默认焦点行为
- 权限不足：提示用户检查Accessibility Kit权限配置

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查Accessibility Kit是否已启用
2. 验证屏幕朗读服务是否已启动
3. 确认弹窗内容符合无障碍规范

**参数准备**：
```arkts
// ArkTS示例：定义弹窗参数
interface DialogParams {
  title: string;
  content: string;
  isModal: boolean;
  width: number;
  height: number;
  alignment: DialogAlignment;
}
```

### 步骤2：创建CustomDialogController

**示例代码**：
```arkts
// 导入必要模块
import { CustomDialogController, DialogAlignment, DismissDialogAction, DismissReason } from '@kit.ArkUI';

// 创建弹窗控制器
private createDialogController(isModal: boolean): CustomDialogController {
  return new CustomDialogController({
    builder: CustomDialogExample({
      controller: isModal ? this.modelDialogController : this.nonModelDialogController,
      isModal: isModal,
      cancel: () => {
        if (isModal) {
          this.modelDialogController.close();
        } else {
          this.nonModelDialogController.close();
        }
      }
    }),
    autoCancel: true,
    isModal: isModal, // 设置模态类型
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss();
      }
      if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss();
      }
    },
    showInSubWindow: true, // 子窗显示模式
    alignment: DialogAlignment.Center, // 弹窗居中显示
    width: 300,
    height: 250,
  })
}
```

### 步骤3：定义自定义弹窗内容

**示例代码**：
```arkts
@CustomDialog
struct CustomDialogExample {
  // 是否为模态对话框
  isModal?: boolean;
  // 对话框控制器
  controller?: CustomDialogController;
  // 关闭对话框的回调函数
  cancel: () => void = () => {};
  
  build() {
    Column() {
      // 显示对话框的标题
      Text(this.isModal ? '模态弹窗' : '非模态弹窗')
        .fontSize(30)
        .height(100)
      Text('测试节点1')
      Text('测试节点2')
      Text('测试节点3')
      // 关闭对话框按钮
      Button('关闭')
        .onClick(() => {
          this.cancel?.();
        })
        .margin(20)
    }
  }
}
```

### 步骤4：触发弹窗显示

**示例代码**：
```arkts
@Entry
@Component
export struct DialogExample {
  title: string = 'Dialog Example';
  // 模态对话框控制器
  private modelDialogController: CustomDialogController = this.createDialogController(true);
  // 非模态对话框控制器
  private nonModelDialogController: CustomDialogController = this.createDialogController(false);
  
  build() {
    NavDestination() {
      Scroll() {
        Column() {
          // 模态对话框按钮
          Button('模态dialog')
            .margin({ bottom: 5 })
            .onClick(() => {
              this.modelDialogController.open();
            })
          // 非模态对话框按钮
          Button('非模态dialog')
            .onClick(() => {
              this.nonModelDialogController.open();
            })
        }.margin({ bottom: 5 })
      }
    }.title(this.title)
  }
}
```

### 步骤5：错误处理

```arkts
// 错误处理代码
try {
  this.modelDialogController.open();
} catch (error) {
  switch (error.code) {
    case 'DIALOG_CONTROLLER_ERROR':
      console.error('弹窗控制器初始化失败');
      break;
    case 'ACCESSIBILITY_SERVICE_ERROR':
      console.error('无障碍服务未启用');
      break;
    default:
      console.error('未知错误:', error.message);
  }
}
```

### 步骤6：降级处理

```arkts
// 降级处理代码：使用Toast替代弹窗
async function showFallbackToast(message: string): Promise<void> {
  try {
    // 使用轻量级提示替代弹窗
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  } catch (error) {
    console.warn('降级提示显示失败');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| DIALOG_CONTROLLER_ERROR | CustomDialogController初始化失败 | 检查builder参数和controller配置 |
| ACCESSIBILITY_SERVICE_ERROR | 无障碍服务未启用 | 在系统设置中启用屏幕朗读服务 |
| FOCUS_CONTROL_ERROR | 焦点控制失败 | 检查isModal参数和showInSubWindow配置 |
| DIALOG_SHOW_ERROR | 弹窗显示失败 | 检查弹窗尺寸和alignment参数 |
| PERMISSION_ERROR | Accessibility Kit权限不足 | 在module.json5中声明无障碍权限 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ArkUI": "系统内置Kit"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 10及以上
- DevEco Studio：3.1及以上版本
- 屏幕朗读服务：需要在设备上启用

### 常见编译问题

**问题1：CustomDialogController未找到**
```
Error: Cannot find name 'CustomDialogController'
```
**解决方法**：导入@kit.ArkUI模块
```arkts
import { CustomDialogController } from '@kit.ArkUI';
```

**问题2：DialogAlignment未定义**
```
Error: Cannot find name 'DialogAlignment'
```
**解决方法**：导入DialogAlignment枚举
```arkts
import { DialogAlignment } from '@kit.ArkUI';
```

**问题3：@CustomDialog装饰器使用错误**
```
Error: @CustomDialog decorator must be used on struct
```
**解决方法**：确保@CustomDialog装饰器应用于struct定义
```arkts
@CustomDialog
struct CustomDialogExample {
  // ...
}
```

## 常见问题与解决方法

### Q1：模态弹窗无法锁定焦点
**原因**：isModal参数未正确设置或showInSubWindow未启用
**解决方法**：
- 确保isModal参数设置为true
- 启用showInSubWindow参数
- 检查屏幕朗读服务是否已启动

### Q2：非模态弹窗焦点无法移出
**原因**：弹窗以子窗形式显示，只能通过不抬手走焦或触摸聚焦
**解决方法**：
- 使用不抬手走焦方式（滑动焦点）
- 使用触摸聚焦方式（点击弹窗外区域）
- 或设置showInSubWindow为false

### Q3：弹窗关闭后焦点未恢复
**原因**：未正确处理onWillDismiss回调
**解决方法**：
- 在onWillDismiss中正确调用dismissDialogAction.dismiss()
- 在cancel回调中正确关闭弹窗控制器

### Q4：弹窗内容不符合无障碍规范
**原因**：弹窗内容缺少必要的无障碍属性
**解决方法**：
- 为Text组件添加accessibilityText属性
- 为Button组件添加accessibilityDescription属性
- 确保弹窗内容可被屏幕朗读服务识别

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "dialogType": "modal/nonModal",
  "focusBehavior": "焦点锁定/焦点可移出",
  "dialogSize": {
    "width": 300,
    "height": 250
  },
  "alignment": "DialogAlignment.Center",
  "apiUsed": [
    "CustomDialogController",
    "DialogAlignment",
    "DismissDialogAction",
    "DismissReason"
  ]
}
```

## 参考文档

- [原始开发指南](references/pop-up-controls-focus.md)
- [Popup API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ohos-arkui-advanced-popup)
- [Menu API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-menu)
- [Dialog API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ohos-arkui-advanced-dialog)
- [bindSheet API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-sheet-transition)

## 完整示例代码

- [ArkTS示例](assets/modal-dialog-example.ets)
- [配置文件示例](assets/dialog-config.json)

## 测试用例

### 正向测试用例
- [模态弹窗焦点锁定测试](tests/test_modal_dialog_focus.py)：验证模态弹窗的焦点锁定功能
- [非模态弹窗焦点控制测试](tests/test_nonmodal_dialog_focus.py)：验证非模态弹窗的焦点控制功能

### 边界测试用例
- [弹窗尺寸边界测试](tests/test_dialog_size_boundary.py)：测试弹窗的最小和最大尺寸
- [按钮数量边界测试](tests/test_button_count_boundary.py)：测试按钮数量的限制

### 异常测试用例
- [弹窗控制器初始化失败测试](tests/test_dialog_controller_error.py)：测试弹窗控制器初始化失败的处理
- [无障碍服务未启用测试](tests/test_accessibility_service_error.py)：测试无障碍服务未启用时的降级方案