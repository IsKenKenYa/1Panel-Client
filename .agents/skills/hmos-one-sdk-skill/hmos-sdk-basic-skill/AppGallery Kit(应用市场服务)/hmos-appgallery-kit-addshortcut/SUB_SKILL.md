---
name: hmos-appgallery-kit-addshortcut
description: 创建应用桌面快捷方式，支持静态资源和自定义资源两种方式，单个应用最多添加2个快捷方式，不支持模拟器，适用于快速访问应用功能和内容场景
---

# 添加桌面快捷方式技能

## 功能描述

本技能提供应用内快捷方式添加到桌面的完整实现方案。通过静态资源方式或自定义资源方式创建桌面快捷方式，向用户展示确认弹窗，用户确认后快捷方式将添加至桌面。

**两种实现方式**：
- **静态资源方式**：使用预先配置在shortcuts标签中的静态资源（label、icon），适用于常用固定功能（如创建新播放列表）
- **自定义资源方式**：使用应用沙箱中的自定义图标和文本，适用于特定临时内容（如添加最新新闻文章）

**核心能力**：
- 校验快捷方式添加权限
- 生成快捷方式校验token (tid)
- 创建桌面快捷方式并展示用户确认弹窗

## 使用场景

### 触发词
- "添加桌面快捷方式"
- "创建快捷方式"
- "应用加桌"
- "快捷方式加桌"
- "pin shortcut"
- "静态快捷方式"
- "自定义快捷方式"

### 能做
- 校验应用是否允许添加快捷方式
- 使用静态资源创建快捷方式（需预先配置shortcuts标签）
- 使用自定义资源创建快捷方式（支持动态图标和文本）
- 获取快捷方式校验结果和过期时间
- 创建快捷方式并展示用户确认弹窗

### 绝不做
- 不支持模拟器运行（仅支持真机调试）
- 不在用户未确认的情况下强制添加快捷方式
- 不处理超出限制数量（最多2个）的快捷方式请求
- 不创建与已存在shortcutId相同的快捷方式
- 不支持TV设备创建快捷方式（6.0.2(22)之前版本）

### 补充
- **设备支持**：Phone、Tablet、PC/2in1设备，TV设备从6.0.2(22)版本开始支持checkPinShortcutPermitted（返回错误码），requestNewPinShortcut无响应
- **数量限制**：单个应用最多可添加2个快捷方式
- **API版本**：起始版本5.0.2(14)
- **模型约束**：仅可在Stage模型下使用
- **tid有效期**：校验结果tid有过期时间(expired)，过期后需重新校验
- **加桌后失效**：快捷方式加桌成功后，原tid会失效，再次加桌需重新校验

## 调用规范和规则

### 输入约束
- **shortcutId长度**：不超过63字节
- **label长度**：不超过255个字符（自定义资源方式）
- **foregroundIcon大小**：不超过100KB（自定义资源方式）
- **foregroundIcon格式**：仅支持png和webp格式（自定义资源方式）
- **shortcutId唯一性**：不能与已存在的shortcutId重复
- **数量限制**：单个应用最多2个快捷方式

### 执行约束
- **调用顺序**：必须先调用checkPinShortcutPermitted校验，用户确认后再调用requestNewPinShortcut创建
- **tid时效性**：校验结果tid必须在有效期内使用，过期需重新校验
- **用户确认**：requestNewPinShortcut会弹出用户确认弹窗，不能绕过用户确认
- **推荐流程**：预先调用checkPinShortcutPermitted校验权限，用户点击加桌后再调用requestNewPinShortcut，避免连续调用两个接口

### 内容约束
- **禁止绕过校验**：不调用checkPinShortcutPermitted直接创建快捷方式
- **禁止伪造tid**：不使用非checkPinShortcutPermitted返回的tid
- **禁止强制加桌**：不处理用户拒绝加桌的情况（错误码1006620007）
- **参数一致性**：静态资源方式的参数必须与shortcuts标签配置保持一致

### 降级约束
- **设备不支持**：提示用户当前设备不支持添加快捷方式功能
- **数量已达上限**：提示用户快捷方式数量已达上限（最多2个），需删除现有快捷方式
- **校验失败**：提示用户快捷方式校验失败，无法添加
- **tid过期**：重新调用checkPinShortcutPermitted生成新的tid
- **用户拒绝**：提示用户已取消添加快捷方式操作

## 调用流程和步骤

### 流程图

```
[开始] -> [选择方式(静态/自定义)]
         ↓
[构造参数] -> [调用checkPinShortcutPermitted校验]
             ↓
[获取CheckShortcutResult] -> [保存tid和expired]
                             ↓
[展示添加入口给用户] -> [用户点击"添加"]
                        ↓
[调用requestNewPinShortcut创建] -> [用户确认弹窗]
                                    ↓
[用户同意/拒绝] -> [返回加桌结果]
                   ↓
[结束/异常处理]
```

### 步骤1：导入模块和准备环境

**导入必要模块**：
```typescript
import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**前置校验**：
1. 确认运行环境为真机（不支持模拟器）
2. 确认设备类型为Phone/Tablet/PC/2in1（TV设备从6.0.2(22)开始部分支持）
3. 确认API版本≥5.0.2(14)
4. 确认Stage模型环境

### 步骤2：选择快捷方式创建方式

**静态资源方式适用场景**：
- 功能固定不变（如创建新播放列表、打开设置页）
- 已在module.json5的shortcuts标签中预先配置
- 需要使用应用内置的静态资源图标和文本

**自定义资源方式适用场景**：
- 功能动态变化（如添加最新新闻文章、特定歌曲）
- 需要使用动态生成的图标和文本
- 图标存储在应用沙箱目录中

### 步骤3：以静态资源方式校验快捷方式

**参数准备**：
```typescript
const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
const shortcutId = "id_test1"; // 对应shortcuts标签中的shortcutId
const labelResName = "shortcut"; // 对应shortcuts标签中的label资源索引名称
const iconResName = "aa_icon"; // 对应shortcuts标签中的icon资源索引名称
const want: Want = { // 对应shortcuts标签中的want配置
  bundleName: "com.example.appgallery.kit.demo",
  moduleName: "entry",
  abilityName: "EntryAbility",
  parameters: {
    testKey: "testValue"
  }
};
```

**校验快捷方式**：
```typescript
try {
  let checkShortcutResult: productViewManager.CheckShortcutResult;
  productViewManager.checkPinShortcutPermitted(uiContext, shortcutId, want, labelResName, iconResName)
    .then((result: productViewManager.CheckShortcutResult) => {
      hilog.info(0x0001, 'TAG', `checkPinShortcutPermitted success result is ${JSON.stringify(result)}`);
      checkShortcutResult = result;
      // 保存tid用于后续创建快捷方式
      const tid = result.tid;
      const expired = result.expired; // tid过期时间(ms)
      const code = result.code; // 校验结果码，0表示成功
      const limit = result.limit; // 允许添加的快捷方式数量
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, 'TAG', `checkPinShortcutPermitted error. code is ${error.code}, message is ${error.message}`);
      // 根据错误码进行相应处理
      handleCheckError(error);
    })
} catch (err) {
  hilog.error(0x0001, 'TAG', `checkPinShortcutPermitted failed, code is ${err.code}, message is ${err.message}`);
}
```

### 步骤4：以自定义资源方式校验快捷方式

**参数准备**：
```typescript
const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
const shortcutId = `${Date.now()}`; // 快捷方式ID，建议使用时间戳保证唯一性
const want: Want = {
  bundleName: "com.example.appgallery.kit.demo",
  moduleName: "entry",
  abilityName: "EntryAbility",
  parameters: {
    testKey: "testValue"
  }
};
const label = "shortcut"; // 显示在桌面的文本
const foregroundIcon = uiContext.filesDir + "/icon.png"; // 图标沙箱路径
const backgroundIcon = ""; // 预留字段，当前只支持空字符串
```

**校验快捷方式**：
```typescript
try {
  let checkShortcutResult: productViewManager.CheckShortcutResult;
  productViewManager.checkPinShortcutPermitted(uiContext, shortcutId, want, label, foregroundIcon, backgroundIcon)
    .then((result: productViewManager.CheckShortcutResult) => {
      hilog.info(0x0001, 'TAG', `checkPinShortcutPermitted success result is ${JSON.stringify(result)}`);
      checkShortcutResult = result;
      // 保存tid和expired
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, 'TAG', `checkPinShortcutPermitted error. code is ${error.code}, message is ${error.message}`);
      handleCheckError(error);
    })
} catch (err) {
  hilog.error(0x0001, 'TAG', `checkPinShortcutPermitted failed, code is ${err.code}, message is ${err.message}`);
}
```

### 步骤5：创建快捷方式

**用户点击添加按钮后调用**：
```typescript
const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
const tid = checkShortcutResult.tid; // 从校验结果中获取

try {
  productViewManager.requestNewPinShortcut(uiContext, tid)
    .then(() => {
      hilog.info(0x0001, 'TAG', `requestNewPinShortcut success.`);
      // 快捷方式添加成功，原tid已失效
      showSuccessMessage();
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, 'TAG', `requestNewPinShortcut error. code is ${error.code}, message is ${error.message}`);
      handleRequestError(error);
    })
} catch (err) {
  hilog.error(0x0001, 'TAG', `requestNewPinShortcut failed, code is ${err.code}, message is ${err.message}`);
}
```

### 步骤6：错误处理

**校验错误处理函数**：
```typescript
function handleCheckError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      hilog.error(0x0001, 'TAG', 'Parameter error. Please check input parameters.');
      break;
    case 1006620001:
      hilog.error(0x0001, 'TAG', 'System internal error. Please try again later.');
      break;
    case 1006620002:
      hilog.error(0x0001, 'TAG', 'Request to service error. Network or service issue.');
      break;
    case 1006620003:
      hilog.error(0x0001, 'TAG', 'Shortcut id already exists. Use a different shortcutId.');
      break;
    case 1006620004:
      hilog.error(0x0001, 'TAG', 'The number of shortcuts has reached the maximum (2).');
      break;
    case 1006620005:
      hilog.error(0x0001, 'TAG', 'Shortcut verification failed. Invalid parameters.');
      break;
    default:
      hilog.error(0x0001, 'TAG', `Unknown error: ${error.message}`);
  }
}
```

**创建错误处理函数**：
```typescript
function handleRequestError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      hilog.error(0x0001, 'TAG', 'Parameter error. tid may be invalid.');
      break;
    case 1006620001:
      hilog.error(0x0001, 'TAG', 'System internal error.');
      break;
    case 1006620003:
      hilog.error(0x0001, 'TAG', 'Shortcut id already exists on desktop.');
      break;
    case 1006620004:
      hilog.error(0x0001, 'TAG', 'Maximum shortcuts reached (2).');
      break;
    case 1006620005:
      hilog.error(0x0001, 'TAG', 'Shortcut verification failed.');
      break;
    case 1006620006:
      hilog.error(0x0001, 'TAG', 'The shortcut is not verified or tid has expired. Re-check required.');
      // 需重新调用checkPinShortcutPermitted
      break;
    case 1006620007:
      hilog.error(0x0001, 'TAG', 'User refused to add shortcut.');
      // 用户拒绝，无需特殊处理
      break;
    default:
      hilog.error(0x0001, 'TAG', `Unknown error: ${error.message}`);
  }
}
```

### 步骤7：降级处理方案

**设备不支持降级**：
```typescript
function checkDeviceSupport(): boolean {
  // 检查设备类型和API版本
  const deviceType = getDeviceType(); // 自实现
  const apiVersion = getApiVersion(); // 自实现
  
  if (deviceType === 'TV') {
    if (apiVersion < '6.0.2(22)') {
      hilog.warn(0x0001, 'TAG', 'TV device not supported before 6.0.2(22)');
      return false;
    } else {
      hilog.warn(0x0001, 'TAG', 'TV device partially supported from 6.0.2(22)');
      return true; // 注意：TV上checkPinShortcutPermitted返回错误码，requestNewPinShortcut无响应
    }
  }
  
  if (deviceType !== 'Phone' && deviceType !== 'Tablet' && deviceType !== 'PC/2in1') {
    hilog.warn(0x0001, 'TAG', 'Device type not supported');
    return false;
  }
  
  return true;
}
```

**tid过期降级**：
```typescript
async function ensureValidTid(oldResult: productViewManager.CheckShortcutResult): Promise<string> {
  const currentTime = Date.now();
  const expiredTime = oldResult.expired;
  
  if (currentTime >= expiredTime) {
    hilog.warn(0x0001, 'TAG', 'Tid has expired, re-checking...');
    // 重新调用checkPinShortcutPermitted
    const newResult = await checkPinShortcutPermitted(...);
    return newResult.tid;
  }
  
  return oldResult.tid;
}
```

## 错误码说明

### checkPinShortcutPermitted错误码

| 错误码ID | 说明 | 解决方法 |
|---------|------|---------|
| 401 | 参数错误 | 检查参数类型、长度、格式是否符合要求 |
| 1006620001 | 系统内部错误 | 稍后重试，检查系统状态 |
| 1006620002 | 请求服务错误 | 检查网络连接，稍后重试 |
| 1006620003 | ShortcutId已存在 | 使用新的shortcutId，或删除已存在的快捷方式 |
| 1006620004 | 快捷方式数量已达上限 | 删除现有快捷方式，最多支持2个 |
| 1006620005 | 快捷方式校验失败 | 检查参数是否正确，静态方式需与shortcuts标签配置一致 |

### requestNewPinShortcut错误码

| 错误码ID | 说明 | 解决方法 |
|---------|------|---------|
| 401 | 参数错误 | 检查tid是否有效 |
| 1006620001 | 系统内部错误 | 稍后重试 |
| 1006620003 | ShortcutId已存在 | 快捷方式已在桌面，无需重复添加 |
| 1006620004 | 快捷方式数量已达上限 | 删除现有快捷方式 |
| 1006620005 | 快捷方式校验失败 | 重新校验 |
| 1006620006 | 快捷方式未校验或tid已过期 | 重新调用checkPinShortcutPermitted生成新tid |
| 1006620007 | 用户拒绝添加快捷方式 | 用户主动取消，无需处理 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": "^5.0.2",
    "@kit.AbilityKit": "^5.0.2",
    "@kit.BasicServicesKit": "^5.0.2",
    "@kit.PerformanceAnalysisKit": "^5.0.2"
  }
}
```

### 环境要求
- **HarmonyOS版本**：≥5.0.2(14)
- **设备类型**：Phone、Tablet、PC/2in1（TV从6.0.2(22)部分支持）
- **运行环境**：真机（不支持模拟器）
- **模型**：Stage模型

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AppGalleryKit'
```
**解决方法**：
- 确认HarmonyOS版本≥5.0.2(14)
- 检查oh-package.json5中是否声明依赖
- 执行ohpm install安装依赖

**问题2：API不存在**
```
Error: Property 'checkPinShortcutPermitted' does not exist on type 'productViewManager'
```
**解决方法**：
- 确认API版本≥5.0.2(14)，该接口起始版本为5.0.2(14)
- 更新SDK版本

**问题3：类型错误**
```
Error: Type 'UIAbilityContext' is not assignable to type 'common.UIAbilityContext'
```
**解决方法**：
- 使用正确的类型导入：`import type { common } from '@kit.AbilityKit'`
- 正确获取context：`this.getUIContext().getHostContext() as common.UIAbilityContext`

**问题4：设备不支持**
```
运行时报错：无法获取内容，请点击屏幕重试
```
**解决方法**：
- 确认使用真机调试，不支持模拟器
- 检查设备类型是否为Phone/Tablet/PC/2in1

**问题5：shortcuts标签配置错误**
```
静态资源方式校验失败，错误码1006620005
```
**解决方法**：
- 检查shortcutId、labelResName、iconResName与module.json5中shortcuts标签配置是否一致
- 参考[创建应用静态快捷方式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/typical-scenario-configuration)配置shortcuts标签

## 常见问题与解决方法

### Q1：快捷方式数量限制是多少？
**原因**：单个应用最多可添加2个快捷方式。
**解决方法**：
- 检查当前已添加的快捷方式数量
- 如已达上限，需删除现有快捷方式才能添加新的
- 校验结果CheckShortcutResult中的limit字段表示允许添加的数量

### Q2：tid过期时间如何处理？
**原因**：checkPinShortcutPermitted返回的tid有过期时间(expired字段)，单位为毫秒。
**解决方法**：
- 记录校验时间戳和expired值
- 在调用requestNewPinShortcut前检查tid是否过期
- 如过期，重新调用checkPinShortcutPermitted生成新tid

### Q3：快捷方式加桌成功后，再次加桌失败？
**原因**：快捷方式加桌成功后，原校验结果tid会失效。
**解决方法**：
- 每次添加快捷方式前重新校验生成新tid
- 不复用旧的tid值

### Q4：用户拒绝添加快捷方式如何处理？
**原因**：用户在确认弹窗中选择拒绝，返回错误码1006620007。
**解决方法**：
- 这是用户主动取消，不属于异常情况
- 提示用户"已取消添加快捷方式"
- 不强制重新添加，尊重用户选择

### Q5：TV设备是否支持？
**原因**：TV设备支持情况随版本变化。
**解决方法**：
- 6.0.2(22)之前版本：不支持TV设备
- 6.0.2(22)及之后版本：checkPinShortcutPermitted支持（返回错误码），requestNewPinShortcut无响应
- 建议TV设备不使用此功能

### Q6：静态资源方式和自定义资源方式的区别？
**原因**：两种方式适用场景不同，参数要求也不同。
**解决方法**：
- **静态资源方式**：适用于固定功能，需预先在module.json5配置shortcuts标签，参数需与配置一致
- **自定义资源方式**：适用于动态内容，使用沙箱图标和自定义文本，灵活性更高
- 根据实际需求选择合适的方式

### Q7：模拟器测试报错？
**原因**：应用市场推荐服务不支持模拟器。
**解决方法**：
- 使用真机调试
- 模拟器中会提示"无法获取内容，请点击屏幕重试"

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "shortcutId": "id_test1",
  "shortcutType": "static | custom",
  "tid": "xxx",
  "expired": 3600000,
  "code": 0,
  "limit": 2,
  "apiUsed": [
    "checkPinShortcutPermitted",
    "requestNewPinShortcut"
  ],
  "deviceType": "Phone | Tablet | PC/2in1",
  "apiVersion": "5.0.2(14)"
}
```

## 参考文档

- [添加桌面快捷方式开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/appgallery-productview-addshortcut)
- [productViewManager API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager)
- [创建应用静态快捷方式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/typical-scenario-configuration)
- [module.json5配置文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-error-code)

## 完整示例代码

### 静态资源方式完整示例
查看完整可编译示例：[静态资源方式示例](assets/example_static_shortcut.ets)

### 自定义资源方式完整示例
查看完整可编译示例：[自定义资源方式示例](assets/example_custom_shortcut.ets)

### 配置文件示例
查看shortcuts标签配置示例：[module.json5配置示例](assets/module_config.json)

## 测试用例

### 正向测试用例
- [静态资源方式创建快捷方式](tests/test_static_shortcut.py)：测试使用静态资源成功创建快捷方式
- [自定义资源方式创建快捷方式](tests/test_custom_shortcut.py)：测试使用自定义资源成功创建快捷方式
- [校验权限成功](tests/test_check_success.py)：测试校验快捷方式添加权限成功

### 边界测试用例
- [shortcutId最大长度](tests/test_shortcutid_max_length.py)：测试shortcutId长度为63字节边界值
- [label最大长度](tests/test_label_max_length.py)：测试label长度为255字符边界值（自定义方式）
- [图标文件最大大小](tests/test_icon_max_size.py)：测试foregroundIcon大小为100KB边界值
- [快捷方式数量上限](tests/test_shortcut_limit.py)：测试单个应用添加2个快捷方式

### 异常测试用例
- [参数错误](tests/test_parameter_error.py)：测试参数类型错误、长度超限等异常
- [shortcutId重复](tests/test_duplicate_shortcutid.py)：测试使用已存在的shortcutId
- [数量超限](tests/test_exceed_limit.py)：测试添加超过2个快捷方式
- [tid过期](tests/test_tid_expired.py)：测试使用过期的tid创建快捷方式
- [用户拒绝](tests/test_user_refuse.py)：测试用户拒绝添加快捷方式
- [设备不支持](tests/test_device_unsupported.py)：测试在不支持的设备上调用