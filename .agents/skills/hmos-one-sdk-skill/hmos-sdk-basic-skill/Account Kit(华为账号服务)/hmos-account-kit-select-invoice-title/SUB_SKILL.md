---
name: hmos-account-kit-select-invoice-title
description: 打开发票抬头选择页面获取用户发票抬头信息，支持个人和企业抬头类型，仅支持手机设备，适用于发票开具、报销场景
---

# 获取发票抬头技能

## 功能描述

本技能提供HarmonyOS Account Kit发票助手能力，通过调用`selectInvoiceTitle`接口打开发票抬头选择页面，帮助用户快速选择或管理发票抬头。支持获取个人和企业发票抬头信息，包括抬头类型、名称、纳税人识别号、公司地址、电话、银行名称和银行账户等完整信息。

**核心能力**：
- 打开发票抬头选择页面
- 支持个人和企业两种抬头类型
- 返回完整的发票抬头信息
- 异步Promise回调处理

**限制条件**：
- 仅支持手机设备（Wearable、TV设备不支持）
- 用户需已登录华为账号
- 需配置应用签名和指纹
- 需配置Client ID
- 需在Stage模型下使用
- 必须在页面或自定义组件生命周期内调用
- 不支持在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext调用

## 使用场景

### 触发词
- "获取发票抬头"
- "选择发票抬头"
- "打开发票抬头页面"
- "发票助手"
- "发票抬头选择"

### 能做
- 打开发票抬头选择页面供用户选择
- 获取用户已保存的发票抬头信息
- 支持个人和企业两种抬头类型的获取
- 返回完整的发票抬头数据（类型、名称、纳税人识别号、地址、电话、银行信息）
- 引导用户添加新的发票抬头

### 绝不做
- 不支持在Wearable、TV设备上使用
- 不支持在非全页面组件中使用UIExtensionContext调用
- 不直接创建或修改发票抬头（需要用户在页面中操作）
- 不处理发票开具和报销的后续流程

### 补充
- 可使用场景化控件"选择发票抬头Button"作为替代实现方案
- 用户可在页面中管理发票抬头（新增、修改、删除）
- 需要系统支持SystemCapability.HuaweiID.InvoiceAssistant能力

## 调用规范和规则

### 输入约束
- Context上下文对象：必须提供有效的UIAbilityContext或UIExtensionContext
- 调用时机：必须在页面或自定义组件生命周期内调用
- 权限要求：已配置应用签名和指纹，已配置Client ID
- 用户状态：用户必须已登录华为账号

### 执行约束
- 最大耗时：无明确限制（依赖用户操作）
- 并发限制：避免频繁调用（错误码1010060004）
- 设备限制：仅手机设备支持
- 系统能力：需要SystemCapability.HuaweiID.InvoiceAssistant

### 内容约束
- 禁止在非全页面组件中使用UIExtensionContext调用
- 禁止在半模态、弹出框、子窗口中调用
- 禁止绕过用户交互直接获取发票抬头
- 禁止使用无效或过期的Context对象

### 降级约束
- 设备不支持：提示用户当前设备不支持该功能
- 用户未登录：引导用户登录华为账号
- 用户取消：返回用户取消错误，由应用层处理
- 网络错误：提示网络异常，建议稍后重试
- 应用未授权：提示应用配置错误，检查签名和指纹配置

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持发票助手能力
2. 验证用户是否已登录华为账号
3. 确认应用已配置签名和指纹
4. 确认应用已配置Client ID

**参数准备**：
```typescript
// 导入必要模块
import { invoiceAssistant } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

// 定义发票抬头数据类型接口
interface InvoiceTitleData {
  type: string;              // 抬头类型：'0'-个人，'1'-企业
  title: string;             // 抬头名称
  taxNumber: string;         // 纳税人识别号
  companyAddress: string;    // 公司地址
  telephone: string;         // 公司电话
  bankName: string;          // 银行名称
  bankAccount: string;       // 银行账户
}
```

### 步骤2：调用API

**示例代码**：
```typescript
/**
 * 获取发票抬头信息
 * @param context - 应用上下文对象
 * @returns Promise<InvoiceTitleData> - 发票抬头数据
 */
async function selectInvoiceTitle(context: common.Context): Promise<InvoiceTitleData> {
  // 检查设备是否支持发票助手能力
  if (!canIUse('SystemCapability.HuaweiID.InvoiceAssistant')) {
    throw new Error('当前设备不支持发票助手服务');
  }

  try {
    // 调用发票抬头选择接口
    const invoiceTitle = await invoiceAssistant.selectInvoiceTitle(context);
    
    hilog.info(0x0000, 'InvoiceTitle', '成功选择发票抬头');
    
    // 返回发票抬头数据
    return {
      type: invoiceTitle.type,
      title: invoiceTitle.title,
      taxNumber: invoiceTitle.taxNumber,
      companyAddress: invoiceTitle.companyAddress,
      telephone: invoiceTitle.telephone,
      bankName: invoiceTitle.bankName,
      bankAccount: invoiceTitle.bankAccount
    };
  } catch (error) {
    const businessError = error as BusinessError<Object>;
    hilog.error(0x0000, 'InvoiceTitle', 
      `选择发票抬头失败。错误码: ${businessError.code}, 错误信息: ${businessError.message}`);
    throw businessError;
  }
}

// 在UI组件中调用示例
@Entry
@Component
struct InvoiceTitlePage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  
  build() {
    Column() {
      Button('选择发票抬头')
        .onClick(async () => {
          try {
            const titleData = await selectInvoiceTitle(this.context);
            // 处理获取到的发票抬头数据
            this.handleInvoiceTitle(titleData);
          } catch (error) {
            // 错误处理
            this.handleError(error as BusinessError<Object>);
          }
        })
    }
  }
  
  private handleInvoiceTitle(data: InvoiceTitleData): void {
    hilog.info(0x0000, 'InvoiceTitle', 
      `发票抬头: ${data.title}, 类型: ${data.type === '0' ? '个人' : '企业'}`);
    // 开发者根据业务需求处理发票抬头数据
  }
  
  private handleError(error: BusinessError<Object>): void {
    // 详见错误处理章节
  }
}
```

### 步骤3：错误处理

```typescript
/**
 * 错误处理函数
 * @param error - 业务错误对象
 */
function handleInvoiceError(error: BusinessError<Object>): void {
  switch (error.code) {
    case 1010060001:
      hilog.warn(0x0000, 'InvoiceTitle', '用户取消选择发票抬头');
      // 提示用户取消操作
      break;
      
    case 1010060002:
      hilog.error(0x0000, 'InvoiceTitle', '系统内部错误');
      // 提示系统异常，稍后重试
      break;
      
    case 1010060003:
      hilog.error(0x0000, 'InvoiceTitle', '应用指纹证书校验失败');
      // 提示应用配置错误，检查签名和指纹配置
      break;
      
    case 1010060004:
      hilog.error(0x0000, 'InvoiceTitle', '接口访问过频');
      // 提示用户稍后重试
      break;
      
    case 1010060005:
      hilog.error(0x0000, 'InvoiceTitle', '网络连接错误');
      // 提示网络异常，检查网络连接
      break;
      
    case 1010060006:
      hilog.error(0x0000, 'InvoiceTitle', '用户未登录华为账号');
      // 引导用户登录华为账号
      break;
      
    case 1010060007:
      hilog.warn(0x0000, 'InvoiceTitle', '发票抬头信息已存在');
      // 提示抬头已存在，无需重复添加
      break;
      
    case 1010060008:
      hilog.error(0x0000, 'InvoiceTitle', '当前华为账号不支持发票助手服务');
      // 提示账号不支持该功能
      break;
      
    case 401:
      hilog.error(0x0000, 'InvoiceTitle', '参数错误');
      // 检查参数类型和有效性
      break;
      
    default:
      hilog.error(0x0000, 'InvoiceTitle', 
        `未知错误。错误码: ${error.code}, 错误信息: ${error.message}`);
      // 提示未知错误
  }
}
```

### 步骤4：降级处理

```typescript
/**
 * 降级处理：设备不支持或功能不可用时的替代方案
 */
async function selectInvoiceTitleWithFallback(context: common.Context): Promise<InvoiceTitleData | null> {
  try {
    // 尝试调用发票助手API
    return await selectInvoiceTitle(context);
  } catch (error) {
    const businessError = error as BusinessError<Object>;
    
    // 根据错误类型提供降级方案
    if (businessError.code === 1010060008 || !canIUse('SystemCapability.HuaweiID.InvoiceAssistant')) {
      // 设备或账号不支持，提供手动输入表单
      hilog.warn(0x0000, 'InvoiceTitle', '设备不支持发票助手，请手动输入发票抬头');
      return showManualInputForm(); // 显示手动输入表单
    } else if (businessError.code === 1010060006) {
      // 用户未登录，引导登录
      hilog.info(0x0000, 'InvoiceTitle', '请先登录华为账号');
      await promptUserLogin(); // 引导用户登录
      return null;
    } else if (businessError.code === 1010060001) {
      // 用户取消，返回null
      hilog.info(0x0000, 'InvoiceTitle', '用户取消选择');
      return null;
    } else {
      // 其他错误，记录日志并返回null
      hilog.error(0x0000, 'InvoiceTitle', `发生错误: ${businessError.message}`);
      return null;
    }
  }
}

/**
 * 手动输入表单降级方案（示意）
 */
function showManualInputForm(): InvoiceTitleData | null {
  // 返回null，由应用层显示手动输入表单
  // 开发者根据业务需求实现表单UI
  return null;
}

/**
 * 引导用户登录（示意）
 */
async function promptUserLogin(): Promise<void> {
  // 引导用户登录华为账号
  // 开发者根据业务需求实现登录流程
}
```

## 错误码说明

| 错误码 | 错误名称 | 说明 | 解决方法 |
|--------|---------|------|---------|
| 401 | PARAMETER_ERROR | 参数错误。可能原因：必填参数未指定、参数类型错误、参数验证失败 | 检查context参数是否有效，确保传入正确的Context对象 |
| 1010060001 | USER_CANCELED | 用户取消发票助手服务 | 用户主动取消，应用层可忽略或提示用户 |
| 1010060002 | SYSTEM_ERROR | 系统内部错误 | 提示用户系统异常，建议稍后重试 |
| 1010060003 | APP_NOT_AUTHORIZED | 应用指纹证书校验失败 | 检查应用签名和指纹配置是否正确 |
| 1010060004 | FREQUENT_CALLS | 接口访问过频 | 提示用户稍后重试，避免短时间内频繁调用 |
| 1010060005 | NETWORK_ERROR | 网络连接错误 | 提示用户检查网络连接，稍后重试 |
| 1010060006 | ACCOUNT_NOT_LOGGED_IN | 用户未登录华为账号 | 引导用户登录华为账号后重试 |
| 1010060007 | INVOICE_TITLE_EXISTS | 发票抬头信息已存在 | 提示用户抬头已存在，无需重复添加 |
| 1010060008 | UNSUPPORTED | 已登录的华为账号不支持发票助手服务 | 提示用户当前账号不支持该功能，提供手动输入表单 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**:
```json
{
  "name": "invoicetitleexample",
  "version": "1.0.0",
  "description": "发票抬头选择示例",
  "main": "",
  "author": "",
  "license": "",
  "dependencies": {
    "@kit.AccountKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0",
    "@kit.AbilityKit": "^5.0.0"
  }
}
```

**module.json5配置**:
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": [
      "phone"
    ],
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK版本：5.0.0(12)及以上
- 开发环境：DevEco Studio 5.0.0及以上
- 设备类型：仅支持手机（phone）
- Stage模型：必须使用Stage模型开发

### 常见编译问题

**问题1：找不到@kit.AccountKit模块**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：
1. 确保HarmonyOS SDK版本为5.0.0(12)及以上
2. 检查DevEco Studio版本是否支持新的Kit导入方式
3. 同步项目依赖：File -> Sync and Refresh Project

**问题2：canIUse函数未定义**
```
Error: 'canIUse' is not defined
```
**解决方法**：
```typescript
// 确保在UI组件中使用，canIUse是全局函数
// 或使用显式导入（如果需要）
import { canIUse } from '@kit.SdkVersion';
```

**问题3：Context类型错误**
```
Error: Type 'UIAbilityContext' is not assignable to type 'Context'
```
**解决方法**：
```typescript
// 使用正确的Context类型
import { common } from '@kit.AbilityKit';

// 在UI组件中获取Context
private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

// 或使用UIContext
private context: common.Context = this.getUIContext().getHostContext();
```

**问题4：设备类型不支持**
```
Error: The current device does not support the invoking of the selectInvoiceTitle interface.
```
**解决方法**：
1. 检查module.json5中的deviceTypes配置，仅支持"phone"
2. 使用canIUse检查设备能力后再调用API
3. 为不支持的设备提供降级方案（如手动输入表单）

## 常见问题与解决方法

### Q1：调用selectInvoiceTitle时提示"用户未登录华为账号"
**原因**：用户未登录华为账号或登录状态已过期
**解决方法**：
1. 引导用户登录华为账号
2. 使用华为账号服务接口检查登录状态
3. 登录成功后重新调用selectInvoiceTitle

### Q2：提示"应用指纹证书校验失败"
**原因**：应用的签名和指纹配置不正确
**解决方法**：
1. 检查应用签名配置是否正确
2. 确认已在华为开发者控制台配置应用指纹
3. 参考[配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)完成配置
4. 参考[配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id)完成Client ID配置

### Q3：在弹出框或半模态中调用失败
**原因**：API不支持在非全页面组件中使用UIExtensionContext调用
**解决方法**：
1. 确保在全页面UIAbilityContext中调用
2. 避免在弹出框、半模态、子窗口等非全页面组件中调用
3. 使用UIAbilityContext作为参数传递

### Q4：如何处理用户取消操作？
**原因**：用户主动取消选择发票抬头
**解决方法**：
1. 捕获错误码1010060001
2. 不视为错误，可选择忽略或提示用户已取消
3. 不执行后续发票处理流程

### Q5：获取到的发票抬头信息不完整
**原因**：个人抬头和企业抬头返回的字段不同
**解决方法**：
- 个人抬头：仅返回type、title，其他字段为空字符串
- 企业抬头：返回所有字段（type、title、taxNumber、companyAddress、telephone、bankName、bankAccount）
- 根据type字段判断抬头类型，处理相应数据

### Q6：接口访问过频错误
**原因**：短时间内频繁调用selectInvoiceTitle接口
**解决方法**：
1. 避免短时间内重复调用
2. 捕获错误码1010060004后，提示用户稍后重试
3. 设置合理的调用间隔（建议至少间隔几秒）

## 输出结果报告

执行完成后输出以下信息：

```typescript
interface InvoiceTitleResult {
  status: 'success' | 'failed' | 'canceled';
  errorCode?: number;
  errorMessage?: string;
  data?: {
    type: string;              // 抬头类型：'0'-个人，'1'-企业
    title: string;             // 抬头名称
    taxNumber: string;         // 纳税人识别号
    companyAddress: string;    // 公司地址
    telephone: string;         // 公司电话
    bankName: string;          // 银行名称
    bankAccount: string;       // 银行账户
  };
  apiUsed: string[];           // 使用的API列表
}

// 成功示例
{
  "status": "success",
  "data": {
    "type": "1",
    "title": "华为技术有限公司",
    "taxNumber": "91440300100000000X",
    "companyAddress": "深圳市龙岗区坂田华为基地",
    "telephone": "0755-12345678",
    "bankName": "中国建设银行深圳分行",
    "bankAccount": "1234567890123456789"
  },
  "apiUsed": [
    "invoiceAssistant.selectInvoiceTitle"
  ]
}

// 用户取消示例
{
  "status": "canceled",
  "errorCode": 1010060001,
  "errorMessage": "The operation was canceled by the user.",
  "apiUsed": [
    "invoiceAssistant.selectInvoiceTitle"
  ]
}

// 失败示例
{
  "status": "failed",
  "errorCode": 1010060006,
  "errorMessage": "The HUAWEI ID is not signed in.",
  "apiUsed": []
}
```

## 参考文档

- [API开发指南：获取发票抬头](references/account-select-invoice-title-guide.md)
- [API参考说明：invoiceAssistant](references/account-api-invoiceassistant-reference.md)
- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id)
- [选择发票抬头Button](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-fusion-button-invoice-title)

## 完整示例代码

- [ArkTS完整示例](assets/select_invoice_title_example.ets)
- [配置文件示例](assets/module.json5.example)

## 测试用例

### 正向测试用例
- [成功选择个人发票抬头](tests/test_positive.ets)：验证个人抬头数据完整性
- [成功选择企业发票抬头](tests/test_positive.ets)：验证企业抬头所有字段正确性

### 边界测试用例
- [设备能力检查](tests/test_boundary.ets)：验证canIUse检查逻辑
- [Context类型验证](tests/test_boundary.ets)：验证不同Context类型的兼容性

### 异常测试用例
- [用户取消操作](tests/test_exception.ets)：验证错误码1010060001处理
- [用户未登录](tests/test_exception.ets)：验证错误码1010060006处理
- [网络错误](tests/test_exception.ets)：验证错误码1010060005处理
- [应用未授权](tests/test_exception.ets)：验证错误码1010060003处理
- [参数错误](tests/test_exception.ets)：验证错误码401处理