---
name: hmos-appgallery-kit-get-shortcut
description: 查询应用已固定在桌面的快捷方式列表，支持Phone/Tablet/PC/2in1/TV设备，API版本6.1.1(24)及以上，适用于快捷方式管理、桌面整理场景
---

# 查询应用内快捷方式技能

## 功能描述

本技能提供查询当前应用已固定在桌面上的所有快捷方式列表的能力。用户可以在应用内查看已添加到桌面的快捷方式列表，快速找到特定的快捷方式，通过定期查看和管理这些快捷方式，确保桌面的整洁和高效。

## 使用场景

### 触发词
- "查询快捷方式"
- "获取桌面快捷方式"
- "查看已添加的快捷方式"
- "快捷方式列表"
- "PinShortcutInfo"

### 能做
- 查询当前应用已固定在桌面的所有快捷方式
- 获取快捷方式的详细信息
- 快捷方式管理和整理
- 验证快捷方式是否已添加到桌面

### 绝不做
- 不创建或添加快捷方式到桌面
- 不删除或移除桌面快捷方式
- 不修改快捷方式的属性
- 不支持模拟器环境

### 补充
- 仅支持真机调试，模拟器环境会提示无法获取内容
- API版本要求：6.1.1(24)及以上
- 设备支持：Phone、Tablet、PC/2in1、TV（TV需6.0.2(22)及以上版本）

## 调用规范和规则

### 输入约束
- 无需输入参数
- 需要应用上下文（UIAbilityContext）

### 执行约束
- 必须在真机环境执行
- 必须在Stage模型下使用
- 需要捕获异步异常
- API调用频次：无限制

### 内容约束
- 禁止在模拟器环境使用
- 禁止在FA模型下使用
- 返回结果为PinShortcutInfo数组

### 降级约束
- 网络失败：提示用户检查网络连接
- 模拟器环境：提示用户使用真机调试
- API版本不满足：提示用户升级系统版本

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备类型（Phone/Tablet/PC/2in1/TV）
2. 检查API版本（≥6.1.1(24))
3. 确认为真机环境

**参数准备**：
```typescript
// 导入必要模块
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'GetPinShortcutInfos';
```

### 步骤2：调用API

**示例代码**：
```typescript
@Entry
@Component
struct GetPinShortcutInfos {
  build() {
    Column() {
      Button("GetPinShortcutInfos")
        .onClick(() => {
          try {
            // 查询桌面快捷方式列表
            productViewManager.getPinShortcutInfos()
              .then((result: productViewManager.PinShortcutInfo[]) => {
                hilog.info(0x0001, TAG, `getPinShortcutInfos success.`);
                hilog.info(0x0001, TAG, `Shortcut count: ${result.length}`);
                // 处理查询结果
                for (let info of result) {
                  hilog.info(0x0001, TAG, `Shortcut info: ${JSON.stringify(info)}`);
                }
              })
              .catch((error: BusinessError) => {
                hilog.error(0x0001, TAG, `getPinShortcutInfos error. code is ${error.code}, message is ${error.message}`);
              })
          } catch (err) {
            hilog.error(0x0001, TAG, `getPinShortcutInfos failed, code is ${err.code}, message is ${err.message}`);
          }
        })
        .width('100%')
    }
    .margin(16)
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

### 步骤3：错误处理

```typescript
try {
  await productViewManager.getPinShortcutInfos();
} catch (error) {
  switch (error.code) {
    case 401:
      hilog.error(0x0001, TAG, 'Parameter error');
      break;
    case 1006620001:
      hilog.error(0x0001, TAG, 'System internal error');
      break;
    default:
      hilog.error(0x0001, TAG, `Unknown error: ${error.message}`);
  }
}
```

### 步骤4：降级处理

```typescript
async function getShortcutInfosFallback(): Promise<void> {
  try {
    // 尝试查询快捷方式
    const result = await productViewManager.getPinShortcutInfos();
    return result;
  } catch (error) {
    // 降级：提示用户手动检查桌面
    hilog.warn(0x0001, TAG, 'Failed to get shortcut infos, please check desktop manually');
    return [];
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查参数类型和格式 |
| 1006620001 | 系统内部错误 | 检查系统状态，重启应用 |
| - | 模拟器环境错误 | 使用真机调试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": "^6.1.1",
    "@kit.BasicServicesKit": "^6.1.1",
    "@kit.PerformanceAnalysisKit": "^6.1.1"
  }
}
```

### 环境要求
- HarmonyOS API版本：≥6.1.1(24)
- 设备类型：Phone/Tablet/PC/2in1/TV
- 模型：Stage模型
- 环境：真机调试

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.AppGalleryKit'
```
**解决方法**：确保HarmonyOS SDK版本≥6.1.1(24)，更新SDK和IDE

**问题2：模拟器运行失败**
```
Unable to get content
```
**解决方法**：切换到真机调试，模拟器不支持应用市场推荐服务

## 常见问题与解决方法

### Q1：模拟器环境无法使用该接口？
**原因**：应用市场推荐服务不支持模拟器
**解决方法**：
- 使用真机进行调试
- 确认设备类型为Phone/Tablet/PC/2in1/TV

### Q2：API调用返回空数组？
**原因**：应用尚未添加任何快捷方式到桌面
**解决方法**：
- 先使用requestNewPinShortcut添加快捷方式
- 检查桌面是否有应用的快捷方式图标

### Q3：如何在TV设备上使用？
**原因**：TV设备从6.0.2(22)版本开始支持
**解决方法**：
- 确认TV设备API版本≥6.0.2(22)
- 更新系统版本

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "shortcutCount": 3,
  "shortcuts": [
    {
      "shortcutId": "shortcut_1",
      "label": "快捷方式1",
      "iconPath": "/path/to/icon1.png"
    },
    {
      "shortcutId": "shortcut_2",
      "label": "快捷方式2",
      "iconPath": "/path/to/icon2.png"
    }
  ],
  "apiUsed": [
    "productViewManager.getPinShortcutInfos"
  ]
}
```

## 参考文档

- [查询应用内快捷方式开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/appgallery-productview-getshortcut)
- [productViewManager API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager)

## 完整示例代码

- [ArkTS示例代码](assets/example_arkts.ets)

## 测试用例

### 正向测试用例
- [真机环境查询快捷方式](tests/test_positive.py)：验证成功获取快捷方式列表

### 边界测试用例
- [空快捷方式列表](tests/test_boundary.py)：验证无快捷方式时的返回结果

### 异常测试用例
- [模拟器环境测试](tests/test_exception.py)：验证模拟器环境的错误提示
- [API版本不满足](tests/test_exception.py)：验证低版本系统的错误提示