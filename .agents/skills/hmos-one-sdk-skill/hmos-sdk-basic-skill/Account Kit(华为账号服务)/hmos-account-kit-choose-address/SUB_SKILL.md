---
name: hmos-account-kit-choose-address
description: 获取用户华为账号收货地址，支持中国境内地址信息，需企业开发者权限，适用于电商购物、物流配送场景
---

# 获取收货地址技能

## 功能描述

本技能用于获取华为账号用户绑定的收货地址信息。通过调用Account Kit的chooseAddress API，拉起收货地址管理页面，用户可选择或添加收货地址后，应用可获取完整的地址信息，包括收件人姓名、手机号、省市区、街道和详细地址等。

**关键特性**：
- 仅支持中国境内地址（不含港澳台）
- 仅支持企业开发者申请权限
- 支持Phone、Tablet、PC/2in1设备（26.0.0版本起支持TV、Car）
- 异步Promise调用模式
- Stage模型约束

## 使用场景

### 触发词
- "获取收货地址"
- "选择收货地址"
- "添加收货地址"
- "填写收货地址"
- "收货地址管理"

### 能做
- 拉起华为账号收货地址管理页面
- 获取用户选择的收货地址信息（姓名、手机号、地址等）
- 支持用户添加新的收货地址
- 支持用户选择已有的收货地址
- 获取完整的地址详情（省市区街道详细地址）

### 绝不做
- 不支持获取港澳台地区地址
- 不支持获取海外地址
- 不支持在半模态、弹出框、子窗口等非全页面组件中调用
- 不支持个人开发者使用（仅企业开发者）
- 不支持在FA模型下使用（仅Stage模型）
- 不支持座机号码和邮政编码的强制获取（可选字段，用户未设置时不返回）

### 补充
- 需用户已登录华为账号，否则返回1008100003错误码
- 需企业开发者提前申请"获取收货地址"权限，否则返回1008100005错误码
- 需配置应用指纹证书和Client ID，否则返回1008100004错误码
- 用户可取消操作，返回1008100006错误码，应用无需特殊处理

## 调用规范和规则

### 输入约束
- Context参数：必须传入有效的UIAbilityContext或UIExtensionContext
- 调用位置：必须在页面或自定义组件生命周期内调用
- 设备要求：Phone/Tablet/PC/2in1（TV/Car需API 26.0.0+）
- 账号要求：用户必须已登录华为账号

### 执行约束
- 最大耗时：无硬性限制，等待用户操作完成
- 调用频次：无硬性限制，但建议避免重复调用
- 执行环境：仅支持Stage模型

### 内容约束
- 禁止在非全页面组件中调用（半模态、弹出框、子窗口）
- 禁止使用UIExtensionContext在非全页面组件中调用
- 禁止绕过用户授权直接获取地址信息
- 禁止在FA模型下调用

### 降级约束
- 用户未登录：引导用户登录华为账号（调用LoginWithHuaweiIDRequest或引导到系统设置）
- 权限未申请：提示开发者申请企业权限
- 证书校验失败：检查Client ID配置和指纹证书
- 用户取消操作：应用无需特殊处理，可提示用户稍后再试
- 不支持账号类型：引导用户更换中国境内账号或使用其他方式获取地址

## 调用流程和步骤

### 步骤1：开发准备阶段

**前置校验**：
1. 确认开发者类型为企业开发者（个人开发者不可用）
2. 确认已在AGC申请"获取收货地址"权限并审核通过（权限申请指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-config-permissions）
3. 确认已配置应用指纹证书（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints）
4. 确认已配置Client ID（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id）
5. 确认应用使用Stage模型

**参数准备**：
```typescript
// ArkTS示例
import { shippingAddress } from '@kit.AccountKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 准备Context参数
// 注意：必须在自定义组件实例中获取UIContext，然后调用getHostContext()
const context: common.Context = this.getUIContext().getHostContext();
```

### 步骤2：调用API

**示例代码**：
```typescript
// 导入必要模块
import { shippingAddress } from '@kit.AccountKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 获取收货地址
async function chooseShippingAddress(context: common.Context): Promise<shippingAddress.AddressInfo | null> {
  try {
    // 拉起收货地址管理页面，等待用户选择或添加地址
    const addressInfo: shippingAddress.AddressInfo = await shippingAddress.chooseAddress(context);
    
    // 记录成功日志
    hilog.info(0x0000, 'ShippingAddress', 'Succeeded in choosing address.');
    
    // 获取地址详细信息
    const userName: string = addressInfo.userName;           // 用户名（长度2-20）
    const mobileNumber: string = addressInfo.mobileNumber;   // 手机号（长度2-20）
    const countryCode: string = addressInfo.countryCode;     // 国家码（长度1-256）
    const provinceName: string = addressInfo.provinceName;   // 省份（长度1-50）
    const cityName: string = addressInfo.cityName;           // 城市（长度1-50）
    const districtName: string = addressInfo.districtName;   // 地区（长度1-50）
    const streetName: string = addressInfo.streetName;       // 街道（长度1-50）
    const detailedAddress: string = addressInfo.detailedAddress; // 详细地址（长度1-50）
    
    // 可选字段：座机号码和邮政编码（用户未设置时不返回）
    const telNumber: string | undefined = addressInfo.telNumber;     // 座机号（可选）
    const zipCode: string | undefined = addressInfo.zipCode;         // 邮政编码（可选）
    
    // 返回地址信息
    return addressInfo;
  } catch (error) {
    // 错误处理
    const err = error as BusinessError;
    hilog.error(0x0000, 'ShippingAddress', `Failed to choose address. Code: ${err.code}, message: ${err.message}`);
    handleChooseAddressError(err);
    return null;
  }
}
```

### 步骤3：错误处理

**错误处理代码**：
```typescript
// 错误处理函数
function handleChooseAddressError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      // 参数错误：可能是context参数未传入或类型错误
      hilog.error(0x0000, 'ShippingAddress', 'Parameter error. Please check context parameter.');
      break;
      
    case 1008100001:
      // 内部错误
      hilog.error(0x0000, 'ShippingAddress', 'Internal error. Please restart device and retry.');
      break;
      
    case 1008100002:
      // 网络不可用
      hilog.error(0x0000, 'ShippingAddress', 'Network unavailable. Please check network connection.');
      break;
      
    case 1008100003:
      // 用户未登录华为账号
      hilog.error(0x0000, 'ShippingAddress', 'User not logged in. Please guide user to login.');
      // 降级方案：引导用户登录
      // 可调用LoginWithHuaweiIDRequest(forceLogin: true)或引导用户到系统设置登录
      break;
      
    case 1008100004:
      // 应用指纹证书校验失败
      hilog.error(0x0000, 'ShippingAddress', 'App fingerprint check failed. Check Client ID and fingerprint certificate.');
      // 降级方案：检查Client ID配置和AGC指纹证书配置
      break;
      
    case 1008100005:
      // 应用未申请对应permissions权限
      hilog.error(0x0000, 'ShippingAddress', 'App does not have required permissions. Please apply for permission in AGC.');
      // 降级方案：提示开发者申请企业权限
      break;
      
    case 1008100006:
      // 用户取消操作
      hilog.info(0x0000, 'ShippingAddress', 'User canceled the operation. No need to handle.');
      // 应用无需特殊处理，用户主动取消
      break;
      
    case 1008100007:
      // 已登录账号不支持收货地址管理服务（如海外账号）
      hilog.error(0x0000, 'ShippingAddress', 'Logged account does not support shipping address service.');
      // 降级方案：引导用户更换中国境内账号或使用其他方式获取地址
      break;
      
    default:
      hilog.error(0x0000, 'ShippingAddress', `Unknown error: ${error.code}, ${error.message}`);
      break;
  }
}
```

### 步骤4：完整示例代码

**在自定义组件中调用**：
```typescript
// 在页面或自定义组件中调用
@Entry
@Component
struct ShippingAddressPage {
  build() {
    Column() {
      Button('选择收货地址')
        .onClick(() => {
          // 在自定义组件实例中调用，必须使用this.getUIContext().getHostContext()
          this.chooseAddress();
        })
    }
  }
  
  // 选择收货地址方法
  private async chooseAddress(): Promise<void> {
    try {
      // 获取Context：必须在自定义组件实例中使用this.getUIContext().getHostContext()
      const context = this.getUIContext().getHostContext();
      
      // 调用chooseAddress API
      const addressInfo = await shippingAddress.chooseAddress(context);
      
      // 处理获取的地址信息
      console.log('收件人：' + addressInfo.userName);
      console.log('手机号：' + addressInfo.mobileNumber);
      console.log('地址：' + addressInfo.provinceName + addressInfo.cityName + 
                  addressInfo.districtName + addressInfo.streetName + addressInfo.detailedAddress);
      
      // 应用后续处理：提交订单、保存地址等
      // ...
      
    } catch (error) {
      const err = error as BusinessError;
      handleChooseAddressError(err);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | 参数错误 | context参数未传入或类型错误 | 检查context参数，确保传入有效的UIAbilityContext或UIExtensionContext |
| 1008100001 | 内部错误 | 华为账号服务器错误或其他内部错误 | 重启设备后重试；若无法解决，在线提单反馈 |
| 1008100002 | 网络不可用 | 网络未连接或连接不好 | 检查网络连接状态 |
| 1008100003 | 用户未登录华为账号 | 用户未事先登录华为账号 | 调用LoginWithHuaweiIDRequest(forceLogin: true)引导登录，或引导用户到系统设置登录 |
| 1008100004 | 应用指纹证书校验失败 | client_id配置错误或应用指纹证书未配置/配置错误 | 检查module.json5中的Client ID配置；检查AGC上的指纹证书配置 |
| 1008100005 | 应用未申请对应permissions权限 | 未申请获取收货地址权限 | 在AGC申请"获取收货地址"权限（仅企业开发者可申请） |
| 1008100006 | 用户未完成操作就退出 | 用户取消或关闭收货地址管理页面 | 应用无需特殊处理，用户主动取消 |
| 1008100007 | 已登录账号不支持收货地址管理服务 | 已登录账号为海外账号，不支持中国境内收货地址服务 | 引导用户更换中国境内账号或使用其他方式获取地址 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "HarmonyOS NEXT",
    "@kit.AbilityKit": "HarmonyOS NEXT",
    "@kit.PerformanceAnalysisKit": "HarmonyOS NEXT",
    "@kit.BasicServicesKit": "HarmonyOS NEXT"
  }
}
```

### 环境要求
- HarmonyOS NEXT（API 5.0.0(12)+）
- Stage模型应用
- DevEco Studio 5.0+
- 企业开发者账号

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：确保使用HarmonyOS NEXT SDK，在DevEco Studio中配置正确的SDK版本。

**问题2：Context参数类型错误**
```
Error: Type 'UIContext' is not assignable to type 'common.Context'
```
**解决方法**：必须调用`this.getUIContext().getHostContext()`获取正确的Context对象，不能直接使用UIContext。

**问题3：调用位置错误**
```
Error: Cannot call chooseAddress in non-full-screen component
```
**解决方法**：确保在页面或自定义组件生命周期内调用，不能在半模态、弹出框、子窗口等非全页面组件中调用。

## 常见问题与解决方法

### Q1：个人开发者可以使用此功能吗？
**原因**：获取收货地址权限仅支持企业开发者申请。
**解决方法**：
- 使用华为账号登录或静默登录实现基础登录功能
- 申请企业开发者资质后申请权限
- 使用场景化控件"选择收货地址Button"（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-fusion-button-ship-to）

### Q2：用户未登录时调用API返回1008100003错误码？
**原因**：用户未登录华为账号。
**解决方法**：
- 调用`LoginWithHuaweiIDRequest`接口，设置`forceLogin: true`拉起登录页面
- 引导用户到系统设置 > 华为账号中心登录账号
- 在调用chooseAddress前先判断用户登录状态

### Q3：调用API返回1008100004错误码（应用指纹证书校验失败）？
**原因**：Client ID配置错误或指纹证书未配置。
**解决方法**：
- 检查module type为entry的模块下的module.json5配置文件中的Client ID是否正确（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id）
- 在AGC中检查应用的指纹证书配置，确保已添加公钥指纹（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-overview）
- 如果权限申请后未重新配置签名，需重新申请调试Profile并手动配置签名（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing）

### Q4：调用API返回1008100005错误码（应用未申请对应permissions权限）？
**原因**：未在AGC申请"获取收货地址"权限。
**解决方法**：
- 在AppGallery Connect中申请"获取收货地址"权限（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-config-permissions）
- 确认开发者类型为企业开发者
- 权限申请通过后，等待25小时生效或修改versionCode触发生效

### Q5：调用API返回1008100007错误码（已登录账号不支持）？
**原因**：已登录账号为海外账号，不支持中国境内收货地址服务。
**解决方法**：
- 引导用户更换或注册一个中国境内（不含港澳台）的华为账号重新登录
- 使用其他方式获取收货地址

### Q6：用户取消操作返回1008100006错误码，需要特殊处理吗？
**原因**：用户未完成操作就主动取消或关闭了收货地址管理页面。
**解决方法**：
- 应用无需特殊处理
- 可提示用户稍后再试，或提供其他方式获取地址

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "addressInfo": {
    "userName": "用户姓名",
    "mobileNumber": "手机号码",
    "countryCode": "国家码",
    "provinceName": "省份名称",
    "cityName": "城市名称",
    "districtName": "地区名称",
    "streetName": "街道名称",
    "detailedAddress": "详细地址",
    "telNumber": "座机号码（可选）",
    "zipCode": "邮政编码（可选）"
  },
  "apiUsed": [
    "shippingAddress.chooseAddress",
    "shippingAddress.AddressInfo"
  ]
}
```

## 参考文档

- [获取收货地址开发指南](references/account-choose-address-dev.md)
- [shippingAddress API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-choose-address)
- [common.Context API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-common)
- [Account Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-error-code)
- [申请账号权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-config-permissions)
- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id)
- [选择收货地址Button场景化控件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-fusion-button-ship-to)

## 完整示例代码

- [ArkTS完整示例](assets/choose_address_example.ets)
- [错误处理示例](assets/error_handling_example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常获取收货地址](tests/test_positive.py)：用户已登录、权限已申请、配置正确，成功获取地址信息
- [添加新地址](tests/test_positive.py)：用户在管理页面添加新地址后成功获取

### 边界测试用例
- [用户未设置可选字段](tests/test_boundary.py)：座机号码和邮政编码未设置时不返回
- [最小字段长度](tests/test_boundary.py)：测试字段长度限制（如userName最小2字符）
- [最大字段长度](tests/test_boundary.py)：测试字段长度限制（如userName最大20字符）

### 异常测试用例
- [用户未登录](tests/test_exception.py)：返回1008100003错误码
- [权限未申请](tests/test_exception.py)：返回1008100005错误码
- [证书校验失败](tests/test_exception.py)：返回1008100004错误码
- [用户取消操作](tests/test_exception.py)：返回1008100006错误码
- [海外账号不支持](tests/test_exception.py)：返回1008100007错误码
- [网络不可用](tests/test_exception.py)：返回1008100002错误码
- [参数错误](tests/test_exception.py)：返回401错误码