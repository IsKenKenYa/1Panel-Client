---
name: hmos-service-collaboration-kit-richeditor-cross-device
description: 跨设备互通能力，在Tablet或PC/2in1设备上通过RichEditor右键菜单调用Phone的相机、扫描及图库功能，支持跨设备交互，需要双端登录同一华为账号并开启WLAN和蓝牙，适用于文档编辑、图片采集场景
---

# 跨设备互通（RichEditor控件）技能

## 功能描述

富文本控件RichEditor已集成跨设备互通能力。在Tablet或PC/2in1设备上，用户可通过其右键菜单调用Phone的相机、扫描及图库（访问图片）功能，实现跨设备交互。通过onWillChange属性可以处理从远端设备回传的照片，实现图片的自定义处理和展示。

## 使用场景

### 触发词
- "跨设备相机"
- "跨设备扫描"
- "跨设备图库"
- "RichEditor跨设备互通"
- "调用其他设备相机"

### 能做
- 在Tablet或PC/2in1设备上通过右键菜单调用Phone的相机功能拍照回传
- 在Tablet或PC/2in1设备上通过右键菜单调用Phone的扫描功能
- 在Tablet或PC/2in1设备上通过右键菜单调用Phone的图库功能访问图片
- 通过onWillChange回调处理回传的图片，自定义图片样式和布局
- 通过editMenuOptions属性自定义或关闭跨设备互通菜单项

### 绝不做
- 不支持同类型设备间的调用（PC调用PC、Tablet调用Tablet、Phone调用其他设备）
- 不支持未登录同一华为账号的设备间调用
- 不支持未开启WLAN或蓝牙的设备间调用
- 不支持HarmonyOS版本低于5的设备调用

### 补充
- PC/2in1设备可以调用Tablet和Phone设备
- Tablet设备可以调用Phone设备
- 建议双端设备接入同一个局域网，可提升唤醒相机的速度
- 需要远端设备具有相机能力

## 调用规范和规则

### 输入约束
- 本端设备类型：必须是Tablet或PC/2in1设备
- 本端设备系统：HarmonyOS版本必须为5及以上
- 远端设备类型：必须具有相机能力的Phone或Tablet设备
- 远端设备系统：HarmonyOS版本必须为5及以上
- 账号要求：双端设备必须登录同一华为账号
- 网络要求：双端设备必须打开WLAN和蓝牙开关

### 执行约束
- 调用策略：PC/2in1可以调用Tablet和Phone，Tablet可以调用Phone，同类型设备不可调用
- 图片处理：通过onWillChange回调处理回传图片，需要返回boolean值决定是否允许更改
- 菜单显示：右键菜单自动显示跨设备互通选项（相机、扫描、图库）

### 内容约束
- 禁止同类型设备间调用
- 禁止未满足设备限制条件的调用
- 禁止未满足账号限制条件的调用
- 禁止未满足网络限制条件的调用

### 降级约束
- 设备不满足条件：提示用户检查设备类型和系统版本
- 账号不满足条件：提示用户登录同一华为账号
- 网络不满足条件：提示用户开启WLAN和蓝牙，建议接入同一局域网
- 远端设备无响应：提示用户检查远端设备状态
- 图片处理失败：使用默认图片样式，记录错误日志

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查本端设备类型是否为Tablet或PC/2in1
2. 检查本端设备系统版本是否为HarmonyOS 5及以上
3. 检查双端设备是否登录同一华为账号
4. 检查双端设备是否开启WLAN和蓝牙

**参数准备**：
```typescript
import { RichEditor, RichEditorController, RichEditorOptions } from '@ohos.arkui';

@Entry
@Component
struct RichEditorCrossDevice {
  controller: RichEditorController = new RichEditorController();
  options: RichEditorOptions = { controller: this.controller };
  
  build() {
    Column() {
      RichEditor(this.options)
        .borderWidth(1)
        .borderColor(Color.Green)
        .width('100%')
        .height('100%')
    }
  }
}
```

### 步骤2：添加RichEditor组件并处理图片回传

**示例代码**：
```typescript
@Entry
@Component
struct RichEditorCrossDeviceExample {
  controller: RichEditorController = new RichEditorController();
  options: RichEditorOptions = { controller: this.controller };
  
  build() {
    Column() {
      Column() {
        RichEditor(this.options)
          .onWillChange((value: RichEditorChangeValue) => {
            if (value?.replacedImageSpans[0]?.imageStyle?.objectFit != 0) {
              return true;
            }
            for (let item of value.replacedImageSpans) {
              this.controller.addImageSpan(item.valuePixelMap, {
                imageStyle: {
                  size: ['500px', '500px'],
                  layoutStyle: {
                    borderRadius: '10px'
                  }
                }
              });
            }
            return false;
          })
          .borderWidth(1)
          .borderColor(Color.Green)
          .width('100%')
          .height('100%')
      }
      .borderWidth(1)
      .borderColor(Color.Red)
      .width('100%')
      .height('70%')
    }
  }
}
```

**说明**：
- `onWillChange`回调在组件执行增删操作前触发
- `RichEditorChangeValue`包含图文变化信息，包括`replacedImageSpans`数组
- `replacedImageSpans`包含回传图片的具体信息，包括`valuePixelMap`图片内容和`imageStyle`样式信息
- 通过`addImageSpan`方法添加图片，可自定义图片大小和布局样式
- 返回`true`允许组件执行添加内容操作，返回`false`阻止组件默认操作并手动处理

### 步骤3：关闭跨设备互通能力（可选）

**示例代码**：
```typescript
@Entry
@Component
struct RichEditorDisableCollaboration {
  controller: RichEditorController = new RichEditorController();
  options: RichEditorOptions = { controller: this.controller };
  
  build() {
    Column() {
      Column() {
        RichEditor(this.options)
          .editMenuOptions({
            onCreateMenu: (menuItems: Array<TextMenuItem>) => {
              if (menuItems.length === 0) {
                return menuItems;
              }
              let newMenuItems: TextMenuItem[] = [];
              menuItems.forEach((item, index) => {
                if (!item.id.equals(TextMenuItemId.COLLABORATION_SERVICE)) {
                  newMenuItems.push(item);
                }
              });
              return newMenuItems;
            },
            onMenuItemClick: (menuItem: TextMenuItem, textRange: TextRange) => {
              return false;
            }
          })
          .borderWidth(1)
          .borderColor(Color.Green)
          .width('100%')
          .height('100%')
      }
      .borderWidth(1)
      .borderColor(Color.Red)
      .width('100%')
      .height('70%')
    }
  }
}
```

**说明**：
- 通过`editMenuOptions`属性自定义菜单内容
- `onCreateMenu`回调用于过滤菜单项，移除`TextMenuItemId.COLLABORATION_SERVICE`跨设备互通菜单项
- `onMenuItemClick`回调处理菜单项点击事件
- 返回新的菜单项数组，不包含跨设备互通选项

### 步骤4：使用流程

**用户操作步骤**：
1. 在富文本区域右键，弹出菜单
2. 选择想要使用的能力（相机、扫描、图库）
3. 系统自动搜索并连接符合条件的远端设备
4. 远端设备响应并执行相应功能（拍照、扫描、选择图片）
5. 等待对端设备处理完成并回传结果
6. 图片回传后，触发`onWillChange`回调
7. 在光标后面嵌入处理后的图片

### 步骤5：错误处理

```typescript
@Entry
@Component
struct RichEditorWithErrorHandling {
  controller: RichEditorController = new RichEditorController();
  options: RichEditorOptions = { controller: this.controller };
  
  build() {
    Column() {
      RichEditor(this.options)
        .onWillChange((value: RichEditorChangeValue) => {
          try {
            if (!value || !value.replacedImageSpans) {
              console.warn('Invalid RichEditorChangeValue received');
              return true;
            }
            
            if (value.replacedImageSpans.length === 0) {
              console.warn('No image spans to process');
              return true;
            }
            
            if (value.replacedImageSpans[0]?.imageStyle?.objectFit != 0) {
              return true;
            }
            
            for (let item of value.replacedImageSpans) {
              if (!item.valuePixelMap) {
                console.error('Missing PixelMap data');
                continue;
              }
              
              this.controller.addImageSpan(item.valuePixelMap, {
                imageStyle: {
                  size: ['500px', '500px'],
                  layoutStyle: {
                    borderRadius: '10px'
                  }
                }
              });
            }
            return false;
          } catch (error) {
            console.error('Error processing cross-device image:', error.message);
            return true;
          }
        })
        .borderWidth(1)
        .borderColor(Color.Green)
        .width('100%')
        .height('100%')
    }
  }
}
```

### 步骤6：降级处理

```typescript
@Entry
@Component
struct RichEditorWithFallback {
  controller: RichEditorController = new RichEditorController();
  options: RichEditorOptions = { controller: this.controller };
  
  private handleImageFallback(pixelMap: PixelMap | undefined): void {
    if (!pixelMap) {
      console.warn('No image data, using default placeholder');
      return;
    }
    
    try {
      this.controller.addImageSpan(pixelMap, {
        imageStyle: {
          size: ['100px', '100px'],
          layoutStyle: {
            borderRadius: '5px'
          }
        }
      });
    } catch (error) {
      console.error('Failed to add image span:', error.message);
    }
  }
  
  build() {
    Column() {
      RichEditor(this.options)
        .onWillChange((value: RichEditorChangeValue) => {
          if (!value?.replacedImageSpans || value.replacedImageSpans.length === 0) {
            return true;
          }
          
          for (let item of value.replacedImageSpans) {
            this.handleImageFallback(item.valuePixelMap);
          }
          return false;
        })
        .borderWidth(1)
        .width('100%')
        .height('100%')
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| DEVICE_NOT_SUPPORTED | 本端设备类型不支持，必须是Tablet或PC/2in1设备 | 检查设备类型，使用支持的设备调用 |
| SYSTEM_VERSION_LOW | 系统版本低于HarmonyOS 5 | 更新系统版本至HarmonyOS 5及以上 |
| ACCOUNT_NOT_SAME | 双端设备未登录同一华为账号 | 在双端设备上登录同一华为账号 |
| NETWORK_NOT_READY | WLAN或蓝牙未开启 | 开启双端设备的WLAN和蓝牙开关 |
| REMOTE_DEVICE_NOT_FOUND | 未找到符合条件的远端设备 | 检查远端设备是否满足条件（具有相机能力的Phone或Tablet） |
| REMOTE_DEVICE_NO_RESPONSE | 远端设备无响应 | 检查远端设备状态，确保设备可用 |
| IMAGE_PROCESSING_FAILED | 图片处理失败 | 检查图片数据，使用降级处理方案 |
| PERMISSION_DENIED | 权限不足 | 检查相机、图库等权限配置 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@ohos.arkui": ">=5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0及以上
- DevEco Studio：3.1及以上
- 目标设备：Tablet或PC/2in1设备（本端），Phone或Tablet设备（远端）

### 常见编译问题

**问题1：导入RichEditor组件失败**
```
Error: Cannot find module '@ohos.arkui'
```
**解决方法**：检查项目依赖配置，确保已正确安装HarmonyOS SDK

**问题2：RichEditorController未定义**
```
Error: 'RichEditorController' is not defined
```
**解决方法**：检查导入语句，确保已导入RichEditorController类型

**问题3：onWillChange回调参数类型错误**
```
Error: Type 'RichEditorChangeValue' is not assignable to type 'Callback<any, boolean>'
```
**解决方法**：检查回调函数签名，确保返回boolean类型

**问题4：addImageSpan方法调用失败**
```
Error: Cannot read property 'addImageSpan' of undefined
```
**解决方法**：检查controller是否正确初始化并绑定到RichEditor组件

**问题5：TextMenuItemId未定义**
```
Error: 'TextMenuItemId' is not defined
```
**解决方法**：检查导入语句，确保已导入TextMenuItemId枚举类型

## 常见问题与解决方法

### Q1：右键菜单未显示跨设备互通选项
**原因**：设备不满足条件或组件配置错误
**解决方法**：
- 检查本端设备类型是否为Tablet或PC/2in1
- 检查系统版本是否为HarmonyOS 5及以上
- 检查是否已登录华为账号
- 检查是否开启WLAN和蓝牙
- 检查是否已通过editMenuOptions过滤菜单项

### Q2：无法连接到远端设备
**原因**：远端设备不满足条件或网络问题
**解决方法**：
- 检查远端设备是否为Phone或Tablet且具有相机能力
- 检查远端设备系统版本是否为HarmonyOS 5及以上
- 检查双端设备是否登录同一华为账号
- 检查双端设备是否开启WLAN和蓝牙
- 建议双端设备接入同一局域网提升连接速度

### Q3：图片回传后显示异常
**原因**：onWillChange回调处理逻辑错误
**解决方法**：
- 检查onWillChange回调是否正确处理replacedImageSpans
- 检查valuePixelMap数据是否有效
- 检查imageStyle配置是否正确
- 使用错误处理和降级方案

### Q4：如何自定义图片样式
**原因**：需要自定义图片大小和布局
**解决方法**：
- 在onWillChange回调中使用addImageSpan方法
- 配置imageStyle.size设置图片宽高
- 配置imageStyle.layoutStyle设置布局样式（如圆角）
- 返回false阻止默认操作，手动添加图片

### Q5：如何禁用跨设备互通功能
**原因**：不需要跨设备互通功能或需要自定义菜单
**解决方法**：
- 使用editMenuOptions属性自定义菜单
- 在onCreateMenu回调中过滤TextMenuItemId.COLLABORATION_SERVICE菜单项
- 返回不包含跨设备互通选项的菜单数组

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "cross-device-collaboration",
  "remoteDeviceType": "Phone",
  "remoteDeviceSystem": "HarmonyOS 5.0",
  "imageReceived": true,
  "imageProcessed": true,
  "imageStyle": {
    "size": ["500px", "500px"],
    "layoutStyle": {
      "borderRadius": "10px"
    }
  },
  "apiUsed": [
    "RichEditor",
    "RichEditorController",
    "RichEditorOptions",
    "onWillChange",
    "addImageSpan",
    "editMenuOptions"
  ]
}
```

## 参考文档

- [跨设备互通（RichEditor控件）开发指南](references/servicecollaboration-richeditor-title.md)
- [RichEditor API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-richeditor)

## 完整示例代码

- [ArkTS示例代码 - 跨设备互通基本用法](assets/richeditor-cross-device-basic.ets)
- [ArkTS示例代码 - 自定义图片处理](assets/richeditor-cross-device-custom.ets)
- [ArkTS示例代码 - 关闭跨设备互通](assets/richeditor-disable-collaboration.ets)
- [ArkTS示例代码 - 错误处理与降级](assets/richeditor-error-handling.ets)

## 测试用例

### 正向测试用例
- [测试设备条件满足时的跨设备调用](tests/test_positive_device_condition.py)：验证Tablet调用Phone相机的正常流程
- [测试图片回传和onWillChange处理](tests/test_positive_image_processing.py)：验证图片正确处理和显示
- [测试自定义图片样式](tests/test_positive_custom_style.py)：验证自定义图片大小和布局

### 边界测试用例
- [测试同类型设备调用限制](tests/test_boundary_same_device.py)：验证PC调用PC、Tablet调用Tablet的限制
- [测试系统版本边界](tests/test_boundary_system_version.py)：验证HarmonyOS 5边界条件
- [测试账号一致性边界](tests/test_boundary_account.py)：验证不同账号场景

### 异常测试用例
- [测试设备类型不满足](tests/test_exception_device_type.py)：验证非Tablet或PC/2in1设备调用失败
- [测试网络未准备好](tests/test_exception_network_not_ready.py)：验证WLAN或蓝牙未开启场景
- [测试远端设备无响应](tests/test_exception_remote_no_response.py)：验证远端设备不可用场景
- [测试图片数据处理失败](tests/test_exception_image_processing.py)：验证无效图片数据处理