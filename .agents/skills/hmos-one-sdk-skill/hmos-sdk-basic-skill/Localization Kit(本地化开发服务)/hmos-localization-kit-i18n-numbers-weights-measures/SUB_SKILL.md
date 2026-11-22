---
name: hmos-localization-kit-i18n-numbers-weights-measures
description: 实现数字、货币和度量衡的国际化格式化与转换,支持不同区域和文化习惯的数字表示、货币符号、度量衡单位转换,最大支持32位整数范围,适用于国际化应用界面显示、数据处理场景
---

# 数字与度量衡国际化技能

## 功能描述

本技能提供HarmonyOS的数字、货币和度量衡国际化处理能力,包括:
- 数字格式化: 根据不同区域的习惯格式化数字显示(小数分隔符、千位分隔符等)
- 数字范围格式化: 格式化数字范围的显示方式
- 货币格式化: 将数字格式化为货币显示形式,包含货币符号和区域习惯
- 单位格式化: 将数字格式化为度量衡单位显示形式
- 度量衡转换: 将原始单位转换为目标单位并格式化显示

基于I18N国际化模块,确保应用界面符合用户所在地区的文化和习惯,避免因固定格式导致的理解歧义。

## 使用场景

### 触发词
- "数字格式化"
- "货币格式化"
- "单位转换"
- "度量衡转换"
- "国际化数字"
- "格式化数字"
- "i18n数字"
- "单位格式化"

### 能做
- 根据区域ID格式化数字显示(如1,000 vs 1.000)
- 格式化货币显示(如$1,000.00 vs ¥1,000.00)
- 格式化度量衡单位显示(如236.588 L vs 236.588 liters)
- 转换度量衡单位(如美制cup转换为公制liter)
- 支持long、short、narrow三种格式化风格
- 支持SI、US、UK三种度量体系

### 绝不做
- 不处理超出32位整数范围的数值
- 不处理无效的单位名称或度量体系
- 不处理无效的区域ID
- 不执行数学计算(仅做单位转换和格式化)
- 不替代Intl.NumberFormat的基础数字格式化功能

### 补充
- 本技能主要关注I18N模块的增强国际化能力
- 基础数字格式化请参考Intl.NumberFormat(ECMA 402标准)
- 度量衡转换需要明确源单位和目标单位的度量体系
- 格式化风格会影响显示效果的详细程度

## 调用规范和规则

### 输入约束
- 数值范围: 32位整数范围内(number类型)
- 单位名称: 合法的单位名称字符串(如'meter', 'inch', 'cup', 'liter')
- 度量体系: 必须为'SI'、'US'、'UK'之一
- 区域ID: 合法的区域ID字符串(如'zh-Hans-CN', 'en-US')
- 格式化风格: 可选,取值'long'、'short'、'narrow',默认'short'

### 执行约束
- 最大耗时: 单次调用不超过100ms
- API调用频次: 无限制
- 必须导入@kit.LocalizationKit模块

### 内容约束
- 禁止硬编码格式化结果
- 禁止使用未定义的单位名称
- 禁止使用未定义的度量体系
- 禁止推测或假想API参数

### 降级约束
- 网络失败: 使用系统默认区域ID
- 无效参数: 抛出错误码890001
- 单位转换失败: 提示用户检查单位名称和度量体系

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 验证数值是否在有效范围内
2. 验证区域ID是否合法
3. 验证单位名称和度量体系是否有效
4. 导入必要的模块

**参数准备**:
```typescript
// ArkTS示例
import { i18n } from '@kit.LocalizationKit';

// 定义源单位和目标单位
const fromUnit: i18n.UnitInfo = {
  unit: 'cup',        // 单位名称
  measureSystem: 'US' // 度量体系
};

const toUnit: i18n.UnitInfo = {
  unit: 'liter',      // 单位名称
  measureSystem: 'SI' // 度量体系
};

const value: number = 1000;        // 要转换的数值
const locale: string = 'en-US';    // 区域ID
const style: string = 'long';      // 格式化风格(可选)
```

### 步骤2: 调用API

**度量衡转换与格式化示例**:
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

try {
  // 定义单位信息
  let fromUnit: i18n.UnitInfo = { unit: 'cup', measureSystem: 'US' };
  let toUnit: i18n.UnitInfo = { unit: 'liter', measureSystem: 'SI' };
  
  // 执行单位转换并格式化
  // short风格: '236.588 L'
  let shortResult: string = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'en-US');
  console.log(`Short format: ${shortResult}`);
  
  // long风格: '236.588 liters'
  let longResult: string = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'en-US', 'long');
  console.log(`Long format: ${longResult}`);
  
  // narrow风格: '236.588L'
  let narrowResult: string = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'en-US', 'narrow');
  console.log(`Narrow format: ${narrowResult}`);
  
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Unit conversion failed, error code: ${err.code}, message: ${err.message}.`);
}
```

### 步骤3: 错误处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

// 完整的错误处理示例
async function convertUnitWithErrorHandling(
  fromUnit: i18n.UnitInfo,
  toUnit: i18n.UnitInfo,
  value: number,
  locale: string,
  style?: string
): Promise<string> {
  try {
    // 参数校验
    if (typeof value !== 'number' || isNaN(value)) {
      throw new Error('Invalid value: must be a valid number');
    }
    
    if (!fromUnit.unit || !fromUnit.measureSystem) {
      throw new Error('Invalid fromUnit: unit and measureSystem are required');
    }
    
    if (!toUnit.unit || !toUnit.measureSystem) {
      throw new Error('Invalid toUnit: unit and measureSystem are required');
    }
    
    if (!locale) {
      throw new Error('Invalid locale: locale is required');
    }
    
    // 度量体系校验
    const validSystems = ['SI', 'US', 'UK'];
    if (!validSystems.includes(fromUnit.measureSystem) || !validSystems.includes(toUnit.measureSystem)) {
      throw new Error('Invalid measureSystem: must be SI, US, or UK');
    }
    
    // 执行转换
    const result: string = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, style);
    return result;
    
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('Parameter error: Mandatory parameters missing or incorrect types');
        throw new Error('Invalid parameters provided');
        
      case 890001:
        console.error('Invalid parameter: Parameter verification failed');
        throw new Error('Parameter validation failed, check unit names and measure systems');
        
      default:
        console.error(`Unknown error: ${err.message}`);
        throw error;
    }
  }
}

// 使用示例
try {
  let result = await convertUnitWithErrorHandling(
    { unit: 'cup', measureSystem: 'US' },
    { unit: 'liter', measureSystem: 'SI' },
    1000,
    'zh-CN',
    'long'
  );
  console.log(`Conversion result: ${result}`);
} catch (error) {
  console.error(`Failed to convert: ${error.message}`);
}
```

### 步骤4: 降级处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

// 降级处理方案
function convertUnitWithFallback(
  fromUnit: i18n.UnitInfo,
  toUnit: i18n.UnitInfo,
  value: number,
  preferredLocale?: string
): string {
  const defaultLocale = 'en-US';  // 默认区域ID
  const locale = preferredLocale || defaultLocale;
  
  try {
    // 尝试使用用户指定的区域ID
    return i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, 'short');
    
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    
    if (err.code === 890001) {
      // 参数验证失败,尝试使用默认区域ID
      console.warn(`Locale '${locale}' failed, trying default locale '${defaultLocale}'`);
      try {
        return i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, defaultLocale, 'short');
      } catch (fallbackError) {
        // 最终降级: 返回原始数值
        console.error('All conversion attempts failed, returning original value');
        return value.toString();
      }
    }
    
    // 其他错误: 直接返回原始数值
    console.error(`Conversion error: ${err.message}`);
    return value.toString();
  }
}

// 使用示例
let result1 = convertUnitWithFallback(
  { unit: 'cup', measureSystem: 'US' },
  { unit: 'liter', measureSystem: 'SI' },
  1000,
  'zh-CN'
);
console.log(result1);  // 成功: '236.588 L' 或中文格式

let result2 = convertUnitWithFallback(
  { unit: 'invalid', measureSystem: 'US' },
  { unit: 'liter', measureSystem: 'SI' },
  1000,
  'zh-CN'
);
console.log(result2);  // 降级: '1000'
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误: 必填参数未指定或参数类型错误 | 检查所有必填参数是否已提供且类型正确 |
| 890001 | Invalid parameter. 无效参数: 参数验证失败 | 检查单位名称、度量体系、区域ID是否合法 |

**常见错误场景**:
- 单位名称无效: 使用未定义的单位名称(如'abc')
- 度量体系无效: 使用非'SI'/'US'/'UK'的值
- 区域ID无效: 使用非法的区域ID格式
- 参数缺失: 必填参数为null或undefined

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "HarmonyOS SDK"
  }
}
```

### 环境要求
- HarmonyOS API version: 9或更高版本(unitConvert从API 9开始)
- 开发环境: DevEco Studio 3.1或更高版本
- 运行环境: HarmonyOS设备或模拟器

### 常见编译问题

**问题1: 模块导入错误**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**: 
- 确保项目已安装HarmonyOS SDK
- 在DevEco Studio中检查SDK配置
- 确保API version >= 9

**问题2: API不存在错误**
```
Error: Property 'unitConvert' does not exist on type 'I18NUtil'
```
**解决方法**: 
- 确保使用的是i18n.I18NUtil.unitConvert(静态方法)
- 检查API version是否 >= 9
- 更新SDK到最新版本

**问题3: 类型错误**
```
Error: Type 'UnitInfo' is not defined
```
**解决方法**: 
- 确保正确导入i18n模块
- 使用i18n.UnitInfo类型声明
- 检查TypeScript配置

## 常见问题与解决方法

### Q1: 单位转换结果不符合预期
**原因**: 
- 单位名称拼写错误
- 度量体系选择错误
- 区域ID格式不正确

**解决方法**:
- 检查单位名称是否合法(如'cup', 'liter', 'meter')
- 确认度量体系是否匹配('SI'为公制, 'US'为美制, 'UK'为英制)
- 使用合法的区域ID格式(如'zh-Hans-CN', 'en-US')

### Q2: 格式化风格显示效果不同
**原因**: 不同风格参数影响显示详细程度

**解决方法**:
- long风格: 显示完整单位名称(如'236.588 liters')
- short风格: 显示单位缩写(如'236.588 L')
- narrow风格: 显示紧凑格式(如'236.588L')
- 根据UI需求选择合适的风格

### Q3: 不同区域显示的小数分隔符不同
**原因**: 不同文化习惯使用不同的分隔符

**解决方法**:
- 德语区域使用逗号作为小数分隔符(如'1.000'表示1)
- 英语区域使用点作为小数分隔符(如'1.000'表示一千)
- 根据用户区域ID自动适配,无需手动处理

### Q4: 如何处理货币格式化
**原因**: 货币格式化需要使用Intl.NumberFormat

**解决方法**:
- 本技能主要关注度量衡转换
- 货币格式化请使用Intl.NumberFormat,设置style为'currency'
- 参考ECMA 402标准的Intl.NumberFormat接口

### Q5: 转换精度问题
**原因**: 单位转换基于CLDR国际化数据库

**解决方法**:
- 转换精度由CLDR数据库决定
- 不同版本CLDR可能有细微差异
- 不要对转换结果进行硬编码或假设性判断
- 仅用于界面展示,不用于精确计算

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "conversionResult": "236.588 liters",
  "fromUnit": "cup",
  "fromSystem": "US",
  "toUnit": "liter",
  "toSystem": "SI",
  "value": 1000,
  "locale": "en-US",
  "style": "long",
  "apiUsed": [
    "i18n.I18NUtil.unitConvert"
  ]
}
```

## 参考文档

- [数字与度量衡国际化开发指南](references/i18n-numbers-weights-measures.md)
- [I18N API参考说明](references/js-apis-i18n.md)
- [区域ID与文化习惯划分](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-locale-culture)
- [ECMA 402 Intl.NumberFormat标准](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat)

## 完整示例代码

- [ArkTS完整示例](assets/i18n_unit_convert_example.ets)
- [错误处理示例](assets/i18n_error_handling.ets)
- [降级处理示例](assets/i18n_fallback.ets)

## 测试用例

### 正向测试用例
- [美制cup转公制liter](tests/test_positive.py): 验证基本单位转换功能
- [不同格式化风格测试](tests/test_positive.py): 验证long/short/narrow三种风格
- [不同区域ID测试](tests/test_positive.py): 验证en-US/zh-CN等区域格式化

### 边界测试用例
- [最大值测试](tests/test_boundary.py): 验证32位整数最大值处理
- [最小值测试](tests/test_boundary.py): 验证最小值处理
- [零值测试](tests/test_boundary.py): 验证零值转换

### 异常测试用例
- [无效单位名称测试](tests/test_exception.py): 验证错误码890001
- [无效度量体系测试](tests/test_exception.py): 验证参数校验失败
- [无效区域ID测试](tests/test_exception.py): 验证降级处理
- [缺失参数测试](tests/test_exception.py): 验证错误码401