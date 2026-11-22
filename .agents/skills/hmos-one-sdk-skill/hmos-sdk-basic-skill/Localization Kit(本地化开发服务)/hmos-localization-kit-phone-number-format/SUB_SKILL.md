---
name: hmos-localization-kit-phone-number-format
description: 格式化电话号码，支持E164/INTERNATIONAL/NATIONAL/RFC3966/TYPING五种格式，适用于电话号码显示、拨号场景
---

# 电话号码格式化技能

## 功能描述

提供电话号码格式化能力，支持根据不同国家和地区的电话号码规范进行格式化显示。支持五种格式化类型：E164、INTERNATIONAL、NATIONAL、RFC3966、TYPING，可判断电话号码有效性并获取归属地信息。适用于通讯录、拨号器、短信应用等需要展示和处理电话号码的场景。

## 使用场景

### 触发词
- "电话号码格式化"
- "格式化手机号"
- "电话号码显示"
- "拨号格式化"
- "号码归属地"
- "验证电话号码"

### 能做
- 格式化电话号码为国际标准格式（E164、INTERNATIONAL、NATIONAL、RFC3966）
- 实时格式化拨号中的电话号码（TYPING）
- 判断电话号码是否有效
- 获取电话号码归属地信息

### 绝不做
- 不生成或创建新的电话号码
- 不发送短信或拨打电话
- 不修改系统通讯录数据
- 不处理非电话号码格式的文本

### 补充
- 需要提供正确的国家地区代码（如CN表示中国）
- 电话号码应为数字字符串，不包含特殊字符（支持星号作为掩码）
- TYPING类型专门用于拨号过程中的实时格式化

## 调用规范和规则

### 输入约束
- 国家地区代码：必须是有效的ISO 3166-1标准的两位字母代码（如CN、US、GB）
- 电话号码：字符串类型，支持数字和星号（*）掩码
- 格式化类型：必须是E164、INTERNATIONAL、NATIONAL、RFC3966、TYPING之一
- 语言代码：必须是有效的区域ID字符串（如zh-CN、en-GB）

### 执行约束
- 最大耗时：单次格式化操作不超过100ms
- 并发限制：无特殊限制
- API调用频次：无限制

### 内容约束
- 禁止使用硬编码的国家代码
- 禁止省略错误处理
- 禁止返回未经验证的格式化结果

### 降级约束
- 无效号码返回原始输入
- 不支持的国家代码返回原始输入
- 网络异常返回默认格式化结果

## 调用流程和步骤

### 步骤1：导入模块

```typescript
import { i18n } from '@kit.LocalizationKit';
```

### 步骤2：创建电话号码格式化对象

**基础用法**：
```typescript
// 创建中国地区的电话号码格式化对象（默认NATIONAL类型）
let phoneNumberFormat: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
```

**指定格式化类型**：
```typescript
// 创建E164格式的格式化对象
let e164Format: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'E164' });

// 创建INTERNATIONAL格式的格式化对象
let internationalFormat: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'INTERNATIONAL' });

// 创建NATIONAL格式的格式化对象
let nationalFormat: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'NATIONAL' });

// 创建RFC3966格式的格式化对象
let rfc3966Format: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'RFC3966' });

// 创建TYPING格式的格式化对象（用于拨号中的实时格式化）
let typingFormat: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'TYPING' });
```

### 步骤3：格式化电话号码

**基本格式化**：
```typescript
try {
  let phoneNumber: string = '158****2312';
  let formattedNumber: string = phoneNumberFormat.format(phoneNumber);
  console.log(`格式化后的号码: ${formattedNumber}`); // 输出: 158 **** 2312
} catch (error) {
  console.error(`格式化失败: ${error.message}`);
}
```

**不同格式化类型的输出示例**：
```typescript
let phoneNumber: string = '158****2312';

// E164格式：+86 158****2312
let e164Number: string = e164Format.format(phoneNumber);

// INTERNATIONAL格式：+86 158 **** 2312
let internationalNumber: string = internationalFormat.format(phoneNumber);

// NATIONAL格式：158 **** 2312
let nationalNumber: string = nationalFormat.format(phoneNumber);

// RFC3966格式：tel:+86-158-****-2312
let rfc3966Number: string = rfc3966Format.format(phoneNumber);
```

**拨号中的实时格式化（TYPING）**：
```typescript
let typingFormat: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'TYPING' });
let phoneNumber: string = '0755453';
let formatResult: string = '';

for (let i = 0; i < phoneNumber.length; i++) {
  formatResult += phoneNumber.charAt(i);
  formatResult = typingFormat.format(formatResult);
}
console.log(`实时格式化结果: ${formatResult}`); // 输出: 0755 453
```

### 步骤4：验证电话号码

```typescript
try {
  let phoneNumber: string = '158****2312';
  let isValid: boolean = phoneNumberFormat.isValidNumber(phoneNumber);
  
  if (isValid) {
    console.log('电话号码有效');
  } else {
    console.log('电话号码无效');
  }
} catch (error) {
  console.error(`验证失败: ${error.message}`);
}
```

### 步骤5：获取号码归属地

```typescript
try {
  let phoneNumber: string = '158****2312';
  let locale: string = 'zh-CN';
  let locationName: string = phoneNumberFormat.getLocationName(phoneNumber, locale);
  console.log(`号码归属地: ${locationName}`); // 输出: 陕西省西安市
  
  // 获取国际号码归属地
  let internationalNumber: string = '0039312****789';
  let internationalLocation: string = phoneNumberFormat.getLocationName(internationalNumber, 'zh-CN');
  console.log(`国际号码归属地: ${internationalLocation}`); // 输出: 意大利
} catch (error) {
  console.error(`获取归属地失败: ${error.message}`);
}
```

### 步骤6：完整示例（带错误处理）

```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class PhoneNumberFormatter {
  private formatter: i18n.PhoneNumberFormat;
  
  constructor(country: string, type?: 'E164' | 'INTERNATIONAL' | 'NATIONAL' | 'RFC3966' | 'TYPING') {
    try {
      if (type) {
        this.formatter = new i18n.PhoneNumberFormat(country, { type: type });
      } else {
        this.formatter = new i18n.PhoneNumberFormat(country);
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      throw new Error(`创建格式化对象失败: ${err.message}`);
    }
  }
  
  format(phoneNumber: string): string {
    try {
      return this.formatter.format(phoneNumber);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`格式化失败: ${err.message}`);
      return phoneNumber; // 降级返回原始号码
    }
  }
  
  isValid(phoneNumber: string): boolean {
    try {
      return this.formatter.isValidNumber(phoneNumber);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`验证失败: ${err.message}`);
      return false;
    }
  }
  
  getLocation(phoneNumber: string, locale: string): string {
    try {
      return this.formatter.getLocationName(phoneNumber, locale);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`获取归属地失败: ${err.message}`);
      return '';
    }
  }
}

// 使用示例
let formatter = new PhoneNumberFormatter('CN', 'NATIONAL');
let formattedNumber = formatter.format('158****2312');
let isValid = formatter.isValid('158****2312');
let location = formatter.getLocation('158****2312', 'zh-CN');
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数未指定或参数类型错误 | 检查参数类型和必填参数是否正确 |
| 890001 | 无效参数：参数验证失败 | 检查国家代码是否为有效的ISO 3166-1标准代码，电话号码格式是否正确 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": ">=1.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 8或更高版本
- DevEco Studio: 3.1或更高版本

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**：确保项目配置文件中已正确配置HarmonyOS SDK路径，并且API version >= 8

**问题2：类型定义错误**
```
Error: Property 'PhoneNumberFormat' does not exist on type 'typeof i18n'
```
**解决方法**：检查HarmonyOS SDK版本，PhoneNumberFormat从API version 8开始支持

**问题3：参数类型错误**
```
Error: Argument of type 'string' is not assignable to parameter of type 'PhoneNumberFormatOptions'
```
**解决方法**：确保options参数使用正确的对象格式：`{ type: 'E164' }`

## 常见问题与解决方法

### Q1：格式化后的电话号码与预期不符
**原因**：国家代码不正确或电话号码格式不规范
**解决方法**：
- 确认国家代码为有效的ISO 3166-1标准代码（如CN、US、GB）
- 确保电话号码只包含数字和星号（*）
- 检查电话号码长度是否符合该国规范

### Q2：TYPING类型格式化效果不理想
**原因**：TYPING类型需要逐字符调用
**解决方法**：
- 在用户输入过程中逐字符调用format方法
- 每次调用时传入完整的当前输入内容
- 示例代码参见"拨号中的实时格式化"部分

### Q3：获取归属地返回空字符串
**原因**：电话号码无效或不支持该地区
**解决方法**：
- 先使用isValidNumber验证号码有效性
- 检查电话号码是否需要添加国际区号前缀（如0039表示意大利）
- 确认locale参数为有效的区域ID

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "formattedNumber": "格式化后的电话号码",
  "isValid": true,
  "locationName": "号码归属地",
  "apiUsed": [
    "PhoneNumberFormat.constructor",
    "PhoneNumberFormat.format",
    "PhoneNumberFormat.isValidNumber",
    "PhoneNumberFormat.getLocationName"
  ]
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-phone-numbers)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)

## 完整示例代码

- [ArkTS示例](assets/phone_number_format_example.ets)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [中国手机号格式化测试](tests/test_positive.py)：验证中国手机号码的格式化功能
- [国际号码格式化测试](tests/test_positive.py)：验证国际电话号码的格式化功能

### 边界测试用例
- [空号码测试](tests/test_boundary.py)：验证空字符串和null值的处理
- [超长号码测试](tests/test_boundary.py)：验证超长电话号码的处理

### 异常测试用例
- [无效国家代码测试](tests/test_exception.py)：验证无效国家代码的错误处理
- [非法字符测试](tests/test_exception.py)：验证包含非法字符的电话号码处理