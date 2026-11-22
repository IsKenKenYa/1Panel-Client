---
name: hmos-appgallery-kit-add-desktop-shortcut
description: 创建桌面快捷方式，支持静态资源和自定义资源两种方式，最多添加2个快捷方式，适用于快速访问应用功能和内容场景
---

# 添加桌面快捷方式技能

## 功能描述

本技能提供应用内快捷方式添加至桌面的能力。通过静态资源方式（基于配置文件）或自定义资源方式（动态生成图标和标签），创建桌面快捷方式并向用户展示确认弹窗。用户确认后，快捷方式将添加至桌面，单个应用最多可添加2个快捷方式。

**适用场景**：
- 静态快捷方式：适用于常用固定功能，如创建新播放列表、打开特定页面
- 自定义快捷方式：适用于特定的、临时内容，如添加最新的新闻文章、特定歌曲

## 使用场景

### 触发词
- "添加桌面快捷方式"
- "创建快捷方式"
- "快捷方式加桌"
- "静态快捷方式"
- "自定义快捷方式"
- "应用快捷方式"

### 能做
- 以静态资源方式创建桌面快捷方式（基于shortcuts配置）
- 以自定义资源方式创建桌面快捷方式（动态生成图标和标签）
- 校验快捷方式是否允许加桌
- 弹出用户确认框，用户确认后添加快捷方式
- 查询快捷方式添加数量限制（最多2个）

### 绝不做
- 不支持模拟器运行（仅支持真机调试）
- 不支持在TV设备上创建快捷方式（TV返回错误码）
- 不绕过用户确认流程强制添加快捷方式
- 不添加超过2个快捷方式
- 不使用已过期或无效的tid创建快捷方式

### 补充
- 应用市场推荐服务从API版本5.0.2(14)开始支持快捷方式功能
- 支持设备类型：Phone、Tablet、PC/2in1（TV设备不支持）
- 快捷方式加桌成功后，原校验结果tid会失效，再次加桌需重新校验生成新的tid
- 推荐预先调用checkPinShortcutPermitted接口校验权限，避免无效操作

## 调用规范和规则

### 输入约束
- shortcutId：长度不超过63字节的字符串
- label（自定义资源方式）：长度不超过255个字符
- foregroundIcon（自定义资源方式）：图标最大不超过100KB，格式为png和webp
- backgroundIcon（自定义资源方式）：目前只支持传入空字符串
- labelResName/iconResName（静态资源方式）：必须与shortcuts配置文件保持一致
- want参数：必须包含bundleName、moduleName、abilityName

### 执行约束
- 最大耗时：checkPinShortcutPermitted和requestNewPinShortcut接口调用总耗时不超过10秒
- API调用频次：无特殊限制，但建议用户点击加桌后再调用requestNewPinShortcut
- 必须在用户点击添加快捷方式后才调用requestNewPinShortcut接口
- 必须先校验（checkPinShortcutPermitted）再创建（requestNewPinShortcut）

### 内容约束
- 禁止生成：不生成绕过用户确认流程的代码
- 禁止使用高危函数：无特殊高危函数限制
- 禁止操作：禁止使用过期tid、禁止伪造shortcutId

### 降级约束
- 网络失败：提示用户"网络异常，请稍后重试"
- 校验失败：提示用户具体失败原因（如快捷方式数量已达上限）
- 用户拒绝：提示用户"快捷方式添加取消"
- 设备不支持：提示用户"当前设备不支持此功能"

## 调用流程和步骤

### 步骤1：准备阶段（导入模块）

**前置校验**：
1. 确认设备类型支持快捷方式功能（Phone、Tablet、PC/2in1）
2. 确认API版本 >= 5.0.2(14)
3. 确认使用真机调试（不支持模拟器）

**导入必要模块**：
```typescript
import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：以静态资源方式创建快捷方式

**前提条件**：
- 需提前在module.json5配置文件中创建应用静态快捷方式（shortcuts标签）
- shortcutId、labelResName、iconResName、want参数需要与配置文件保持一致

**示例代码**：
```typescript
// 获取当前Page页面的上下文信息
const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

// 构造参数（对应shortcuts标签中的配置）
const shortcutId = "id_test1"; // 对应配置: "shortcutId": "id_test1"
const labelResName = "shortcut"; // 对应配置: "label": "$string:shortcut"
const iconResName = "aa_icon"; // 对应配置: "icon": "$media:aa_icon"
const want: Want = {
  bundleName: "com.example.appgallery.kit.demo",
  moduleName: "entry",
  abilityName: "EntryAbility",
  parameters: {
    testKey: "testValue"
  }
};

// 校验快捷方式是否允许加桌
try {
  let checkShortcutResult: productViewManager.CheckShortcutResult;
  productViewManager.checkPinShortcutPermitted(uiContext, shortcutId, want, labelResName, iconResName)
    .then((result: productViewManager.CheckShortcutResult) => {
      hilog.info(0x0001, 'TAG', `校验成功，结果: ${JSON.stringify(result)}`);
      checkShortcutResult = result;
      
      // 用户点击添加快捷方式后，调用创建接口
      const tid = checkShortcutResult.tid;
      productViewManager.requestNewPinShortcut(uiContext, tid)
        .then(() => {
          hilog.info(0x0001, 'TAG', `快捷方式创建成功`);
        }).catch((error: BusinessError) => {
          hilog.error(0x0001, 'TAG', `创建失败: ${error.code}, ${error.message}`);
        });
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, 'TAG', `校验失败: ${error.code}, ${error.message}`);
    });
} catch (err) {
  hilog.error(0x0001, 'TAG', `异常: ${err.code}, ${err.message}`);
}
```

### 步骤3：以自定义资源方式创建快捷方式

**适用场景**：
- 动态生成快捷方式图标和标签
- 适用于临时内容（如最新文章、特定歌曲）

**示例代码**：
```typescript
// 获取上下文
const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

// 构造参数（动态生成）
const shortcutId = `${Date.now()}`; // 动态生成唯一ID
const want: Want = {
  bundleName: "com.example.appgallery.kit.demo",
  moduleName: "entry",
  abilityName: "EntryAbility",
  parameters: {
    testKey: "testValue"
  }
};
const label = "shortcut"; // 显示在桌面的名称
const foregroundIcon = uiContext.filesDir + "/icon.png"; // 应用沙箱地址
const backgroundIcon = ""; // 当前不支持背景层图标

// 校验快捷方式是否允许加桌
try {
  let checkShortcutResult: productViewManager.CheckShortcutResult;
  productViewManager.checkPinShortcutPermitted(uiContext, shortcutId, want, label, foregroundIcon, backgroundIcon)
    .then((result: productViewManager.CheckShortcutResult) => {
      hilog.info(0x0001, 'TAG', `校验成功，结果: ${JSON.stringify(result)}`);
      checkShortcutResult = result;
      
      // 用户点击添加后，创建快捷方式
      const tid = checkShortcutResult.tid;
      productViewManager.requestNewPinShortcut(uiContext, tid)
        .then(() => {
          hilog.info(0x0001, 'TAG', `快捷方式创建成功`);
        }).catch((error: BusinessError) => {
          hilog.error(0x0001, 'TAG', `创建失败: ${error.code}, ${error.message}`);
        });
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, 'TAG', `校验失败: ${error.code}, ${error.message}`);
    });
} catch (err) {
  hilog.error(0x0001, 'TAG', `异常: ${err.code}, ${err.message}`);
}
```

### 步骤4：错误处理

**错误码处理**：
```typescript
try {
  await productViewManager.checkPinShortcutPermitted(...);
} catch (error) {
  switch (error.code) {
    case 401:
      hilog.error(0x0001, 'TAG', '参数错误，请检查输入参数');
      break;
    case 1006620001:
      hilog.error(0x0001, 'TAG', '系统内部错误');
      break;
    case 1006620002:
      hilog.error(0x0001, 'TAG', '请求服务错误');
      break;
    case 1006620003:
      hilog.error(0x0001, 'TAG', '快捷方式ID已存在');
      break;
    case 1006620004:
      hilog.error(0x0001, 'TAG', '快捷方式数量已达上限（最多2个）');
      break;
    case 1006620005:
      hilog.error(0x0001, 'TAG', '快捷方式校验失败');
      break;
    case 1006620006:
      hilog.error(0x0001, 'TAG', '快捷方式未校验或已过期，请重新校验');
      break;
    case 1006620007:
      hilog.error(0x0001, 'TAG', '用户拒绝添加快捷方式');
      break;
    default:
      hilog.error(0x0001, 'TAG', `未知错误: ${error.message}`);
  }
}
```

### 步骤5：降级处理

**网络失败降级**：
```typescript
productViewManager.checkPinShortcutPermitted(...)
  .catch((error: BusinessError) => {
    if (error.code === 1006620002) {
      // 网络失败降级方案：提示用户稍后重试
      AlertDialog.show({
        message: '网络异常，请检查网络连接后稍后重试'
      });
    }
  });
```

**设备不支持降级**：
```typescript
// 在调用前检查设备类型
const deviceType = device.deviceType;
if (deviceType !== 'phone' && deviceType !== 'tablet' && deviceType !== 'pc') {
  AlertDialog.show({
    message: '当前设备不支持快捷方式功能'
  });
  return;
}
```

**快捷方式数量已达上限降级**：
```typescript
productViewManager.checkPinShortcutPermitted(...)
  .then((result) => {
    if (result.code === 0 && result.limit === 0) {
      // 快捷方式数量已达上限
      AlertDialog.show({
        message: '快捷方式数量已达上限（最多2个），请先删除现有快捷方式'
      });
      return;
    }
    // 继续创建流程
  });
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查参数类型、长度、格式是否符合要求 |
| 1006620001 | 系统内部错误 | 重试或联系技术支持 |
| 1006620002 | 请求服务错误 | 检查网络连接，稍后重试 |
| 1006620003 | 快捷方式ID已存在 | 使用新的shortcutId或删除已存在的快捷方式 |
| 1006620004 | 快捷方式数量已达上限 | 删除现有快捷方式后再添加 |
| 1006620005 | 快捷方式校验失败 | 检查参数是否正确，重新校验 |
| 1006620006 | 快捷方式未校验或已过期 | 先调用checkPinShortcutPermitted重新校验 |
| 1006620007 | 用户拒绝添加快捷方式 | 提示用户确认是否添加 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": "5.0.2(14)及以上",
    "@kit.AbilityKit": "5.0.2(14)及以上",
    "@kit.PerformanceAnalysisKit": "5.0.2(14)及以上",
    "@kit.BasicServicesKit": "5.0.2(14)及以上"
  }
}
```

### 环境要求
- HarmonyOS API版本：5.0.2(14)及以上
- 设备类型：Phone、Tablet、PC/2in1
- 运行环境：真机（不支持模拟器）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AppGalleryKit'
```
**解决方法**：确保HarmonyOS API版本 >= 5.0.2(14)，检查项目配置文件中是否正确配置了Kit依赖

**问题2：类型定义错误**
```
Error: Property 'CheckShortcutResult' does not exist on type 'productViewManager'
```
**解决方法**：确保API版本 >= 5.0.2(14)，CheckShortcutResult类型从此版本开始提供

**问题3：真机调试失败**
```
提示：无法获取内容，请点击屏幕重试
```
**解决方法**：应用市场推荐服务不支持模拟器，请使用真机调试

## 常见问题与解决方法

### Q1：为什么在模拟器上无法创建快捷方式？
**原因**：应用市场推荐服务不支持模拟器运行
**解决方法**：
- 使用真机进行调试和测试
- 在真机上运行时功能可正常使用

### Q2：快捷方式创建后，tid为什么会失效？
**原因**：快捷方式加桌成功后，原校验结果tid会自动失效
**解决方法**：
- 再次添加快捷方式时，重新调用checkPinShortcutPermitted生成新的tid
- 每次创建快捷方式前都进行校验

### Q3：为什么推荐先校验再创建？
**原因**：预先校验可以确保用户有权限创建快捷方式，避免无效操作
**解决方法**：
- 在展示添加快捷方式入口前调用checkPinShortcutPermitted
- 用户点击添加后再调用requestNewPinShortcut
- 这样可以减少权限检查时间，提高操作流畅性

### Q4：最多可以添加多少个快捷方式？
**原因**：单个应用最多可添加2个快捷方式
**解决方法**：
- 查询checkShortcutResult.limit字段获取剩余可添加数量
- 达到上限时提示用户删除现有快捷方式

### Q5：TV设备是否支持快捷方式？
**原因**：TV设备不支持快捷方式功能（从6.0.2(22)开始，TV返回错误码）
**解决方法**：
- 调用前检查设备类型
- 在TV设备上禁用快捷方式功能或提示用户不支持

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success/failed",
  "shortcutId": "快捷方式ID",
  "shortcutType": "static/custom",
  "tid": "校验结果tid",
  "resultCode": "校验结果码（0表示成功）",
  "limit": "剩余可添加数量",
  "error": {
    "code": "错误码",
    "message": "错误信息"
  },
  "apiUsed": [
    "productViewManager.checkPinShortcutPermitted",
    "productViewManager.requestNewPinShortcut"
  ]
}
```

## 参考文档

- [API开发指南](references/appgallery-productview-addshortcut.md)
- [API参考说明](references/store-productviewmanager.md)
- [shortcuts配置文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file)

## 完整示例代码

- [静态资源方式示例](assets/static_shortcut_example.ets)
- [自定义资源方式示例](assets/custom_shortcut_example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [静态资源方式创建快捷方式](tests/test_static_shortcut_positive.ets)：正常创建静态快捷方式
- [自定义资源方式创建快捷方式](tests/test_custom_shortcut_positive.ets)：正常创建自定义快捷方式
- [用户确认后创建](tests/test_user_confirm_positive.ets)：模拟用户点击确认后创建

### 边界测试用例
- [快捷方式ID长度边界](tests/test_shortcutid_boundary.ets)：测试63字节长度边界
- [label长度边界](tests/test_label_boundary.ets)：测试255字符长度边界
- [图标文件大小边界](tests/test_icon_size_boundary.ets)：测试100KB大小边界

### 异常测试用例
- [快捷方式数量超限](tests/test_limit_exception.ets)：测试添加超过2个快捷方式
- [使用过期tid](tests/test_expired_tid_exception.ets)：测试使用过期tid创建
- [设备不支持](tests/test_device_unsupport_exception.ets)：测试在TV设备上创建
- [参数错误](tests/test_parameter_error_exception.ets)：测试缺少必填参数