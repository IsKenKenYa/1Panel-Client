---
name: hmos-localization-kit-dst-transition
description: 计算夏令时跳变前后时间差小时数，支持多种时区配置，适用于日历应用、时间调度、国际化时间处理场景
---

# 夏令时跳变技能

## 功能描述

本技能提供夏令时跳变时间计算能力。夏令时是一种为节约能源而规定的地方时间制度，在天亮早的夏季人为将时间调快一段时间。系统会配置夏令时跳变规则，当系统时间到达跳变点时，会自动实现跳变。

核心功能包括：
- 计算夏令时跳变前后挂钟时间之间相差的小时数
- 处理夏令时跳变带来的时间空缺和重复问题
- 支持多种时区和历法配置

夏令时跳入将导致一段时间空缺（例如1:59:59跳转到3:00:00），夏令时跳出将导致一段时间重复（例如3:59:59回退到3:00:00）。

## 使用场景

### 触发词
- "夏令时跳变"
- "计算夏令时小时数"
- "DST时间计算"
- "夏令时时间差"
- "处理夏令时跳变"

### 能做
- 计算指定时区夏令时跳变前后的小时数差值
- 计算特定日期范围内的挂钟时间差
- 验证夏令时跳变对时间的影响
- 支持多种历法和时区配置

### 绝不做
- 不直接修改系统时间或夏令时规则
- 不处理非夏令时相关的时间计算
- 不提供跨时区的实时时间同步功能
- 不处理历史夏令时规则变更查询

### 补充
- 系统已预配置夏令时跳变规则，应用无需手动配置
- 应用通过标准TS接口获取时间会自动同步显示夏令时时间
- 建议使用零时区标准时间（UTC/GMT）存储和传输时间数据，避免夏令时跳变导致的信息丢失

## 调用规范和规则

### 输入约束
- 时区ID：必须为合法的时区ID字符串（如"Europe/London"、"Asia/Shanghai"）
- 时间参数：年、月、日、时、分、秒数值必须为有效范围
- 月份计数：月份从0开始计数（0表示一月，11表示十二月）
- 时间范围：计算的时间跨度建议不超过一年，避免历法规则变更影响

### 执行约束
- 最大计算次数：单次调用建议不超过10个时区的时间差计算
- 时区数量：同时处理的时区不超过20个
- 计算精度：毫秒级精度，小时数计算结果为整数或浮点数

### 内容约束
- 禁止使用系统时间修改API
- 禁止硬编码特定日期的夏令时规则（应通过Calendar对象自动处理）
- 禁止忽略时区设置直接使用本地时间

### 降级约束
- 时区ID无效：提示用户使用合法时区ID，列出常用时区示例
- 时间参数超范围：提示正确的参数范围并拒绝执行
- 计算失败：返回错误信息并建议检查时间参数和时区配置

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证时区ID是否为合法字符串（如"Europe/London"）
2. 验证时间参数范围（年、月、日、时、分、秒）
3. 确认月份计数方式（从0开始）

**参数准备**：
```typescript
// 准备计算夏令时跳变小时的参数
interface DSTCalculationParams {
  locale: string;           // 区域ID，如 'zh-Hans'
  timezone: string;         // 时区ID，如 'Europe/London'
  startTime: {              // 夏令时开始前的参考时间
    year: number;
    month: number;          // 注意：月份从0开始
    day: number;
    hour: number;
    minute: number;
    second: number;
  };
  endTime: {                // 夏令时期间的参考时间
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
    second: number;
  };
}
```

### 步骤2：调用API计算时间差

**示例代码**：
```typescript
// 导入必要模块
import { i18n } from '@kit.LocalizationKit';

/**
 * 计算夏令时跳变前后挂钟时间之间相差的小时数
 * @param params 计算参数配置
 * @returns 相差的小时数（可能为23、25等非24小时）
 */
function calculateDSTHours(params: DSTCalculationParams): number {
  try {
    // 1. 获取指定区域和历法的日历对象
    let calendar: i18n.Calendar = i18n.getCalendar(params.locale);
    console.log(`获取日历对象成功，区域：${params.locale}`);
    
    // 2. 设置时区
    calendar.setTimeZone(params.timezone);
    console.log(`设置时区成功：${params.timezone}`);
    
    // 3. 设置起始时间（夏令时开始前的时间）
    calendar.set(
      params.startTime.year,
      params.startTime.month,
      params.startTime.day,
      params.startTime.hour,
      params.startTime.minute,
      params.startTime.second
    );
    let startTimeInMillis = calendar.getTimeInMillis();
    console.log(`起始时间戳：${startTimeInMillis}`);
    
    // 4. 设置结束时间（夏令时期间的时间）
    calendar.set(
      params.endTime.year,
      params.endTime.month,
      params.endTime.day,
      params.endTime.hour,
      params.endTime.minute,
      params.endTime.second
    );
    let endTimeInMillis = calendar.getTimeInMillis();
    console.log(`结束时间戳：${endTimeInMillis}`);
    
    // 5. 计算相差的小时数
    let hoursDiff = (endTimeInMillis - startTimeInMillis) / (3600 * 1000);
    console.log(`相差小时数：${hoursDiff}`);
    
    return hoursDiff;
  } catch (error) {
    console.error(`计算夏令时小时数失败：${error.message}`);
    throw error;
  }
}

// 使用示例
let params: DSTCalculationParams = {
  locale: 'zh-Hans',
  timezone: 'Europe/London',
  startTime: {
    year: 2021,
    month: 2,      // 3月（月份从0开始）
    day: 27,
    hour: 16,
    minute: 0,
    second: 0
  },
  endTime: {
    year: 2021,
    month: 2,      // 3月（月份从0开始）
    day: 28,
    hour: 16,
    minute: 0,
    second: 0
  }
};

try {
  let hours = calculateDSTHours(params);
  console.log(`2021年3月27日到3月28日的小时数：${hours}小时（正常应为24小时，夏令时跳变当天为23小时）`);
} catch (error) {
  console.error(`调用失败：${error}`);
}
```

### 步骤3：错误处理

```typescript
// 错误处理代码
import { BusinessError } from '@kit.BasicServicesKit';

function handleDSTCalculationWithErrorHandling(params: DSTCalculationParams): number {
  try {
    let calendar: i18n.Calendar = i18n.getCalendar(params.locale);
    calendar.setTimeZone(params.timezone);
    
    // 验证时区设置是否成功
    let actualTimezone = calendar.getTimeZone();
    if (actualTimezone !== params.timezone) {
      console.warn(`时区设置可能未生效，期望：${params.timezone}，实际：${actualTimezone}`);
    }
    
    calendar.set(
      params.startTime.year,
      params.startTime.month,
      params.startTime.day,
      params.startTime.hour,
      params.startTime.minute,
      params.startTime.second
    );
    let startTime = calendar.getTimeInMillis();
    
    calendar.set(
      params.endTime.year,
      params.endTime.month,
      params.endTime.day,
      params.endTime.hour,
      params.endTime.minute,
      params.endTime.second
    );
    let endTime = calendar.getTimeInMillis();
    
    let hours = (endTime - startTime) / (3600 * 1000);
    return hours;
    
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('参数错误：可能原因包括必填参数未指定、参数类型不正确');
        throw new Error('参数错误，请检查参数类型和必填项');
      case 890001:
        console.error('无效参数：参数验证失败');
        throw new Error('无效的时区ID或时间参数');
      default:
        console.error(`未知错误：错误码 ${err.code}，错误信息 ${err.message}`);
        throw new Error(`计算失败：${err.message}`);
    }
  }
}
```

### 步骤4：降级处理

```typescript
// 降级处理代码
function fallbackDSTCalculation(params: DSTCalculationParams): number | null {
  try {
    // 降级方案1：使用默认时区（系统时区）
    if (!params.timezone || params.timezone === '') {
      console.warn('时区ID为空，使用系统默认时区');
      let calendar: i18n.Calendar = i18n.getCalendar(params.locale);
      // 不设置时区，使用系统默认时区
      
      calendar.set(
        params.startTime.year,
        params.startTime.month,
        params.startTime.day,
        params.startTime.hour,
        params.startTime.minute,
        params.startTime.second
      );
      let startTime = calendar.getTimeInMillis();
      
      calendar.set(
        params.endTime.year,
        params.endTime.month,
        params.endTime.day,
        params.endTime.hour,
        params.endTime.minute,
        params.endTime.second
      );
      let endTime = calendar.getTimeInMillis();
      
      return (endTime - startTime) / (3600 * 1000);
    }
    
    // 降级方案2：时区无效时使用UTC时区
    let calendar: i18n.Calendar = i18n.getCalendar(params.locale);
    try {
      calendar.setTimeZone(params.timezone);
    } catch (timezoneError) {
      console.warn(`时区 ${params.timezone} 无效，使用UTC时区作为降级方案`);
      calendar.setTimeZone('UTC');
    }
    
    calendar.set(
      params.startTime.year,
      params.startTime.month,
      params.startTime.day,
      params.startTime.hour,
      params.startTime.minute,
      params.startTime.second
    );
    let startTime = calendar.getTimeInMillis();
    
    calendar.set(
      params.endTime.year,
      params.endTime.month,
      params.endTime.day,
      params.endTime.hour,
      params.endTime.minute,
      params.endTime.second
    );
    let endTime = calendar.getTimeInMillis();
    
    return (endTime - startTime) / (3600 * 1000);
    
  } catch (finalError) {
    // 最终降级：无法计算时返回null并提示用户
    console.error('降级处理失败，无法计算夏令时小时数');
    console.error(`建议：检查时间参数范围、确认时区ID合法性、使用UTC时间存储`);
    return null;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误，可能原因：必填参数未指定、参数类型不正确 | 检查参数类型和必填项，确保参数范围正确 |
| 890001 | Invalid parameter. 无效参数，参数验证失败 | 验证时区ID是否合法，检查时间参数范围 |
| 无效时区ID | 时区ID字符串格式不正确或不被系统支持 | 使用合法时区ID如"Europe/London"、"Asia/Shanghai"、"UTC" |
| 时间参数超范围 | 年、月、日、时、分、秒数值超出有效范围 | 检查月份（0-11）、日期（1-31）、小时（0-23）等范围 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "系统Kit，无需额外安装"
  }
}
```

### 环境要求
- HarmonyOS API version 8+（i18n.getCalendar、Calendar.setTimeZone）
- HarmonyOS API version 11+（Calendar.getTimeInMillis）
- 开发环境：DevEco Studio 3.1+

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**：确保项目API版本不低于8，在build-profile.json5中配置正确的compileSdkVersion

**问题2：getTimeInMillis方法不存在**
```
Error: Property 'getTimeInMillis' does not exist on type 'Calendar'
```
**解决方法**：getTimeInMillis从API version 11开始支持，确保compileSdkVersion不低于11

**问题3：时区设置不生效**
```
Warning: Timezone not applied correctly
```
**解决方法**：使用getTimeZone()验证时区设置，确保时区ID字符串格式正确（如"Europe/London"而非"Europe/London Time"）

## 常见问题与解决方法

### Q1：为什么计算结果是23小时而非24小时？
**原因**：夏令时开始当天，时钟向前调整1小时（例如从2:00跳到3:00），导致当天时间缩短为23小时
**解决方法**：这是正常现象，夏令时跳变当天的时间差会小于或大于24小时

### Q2：如何确定某个时区是否使用夏令时？
**原因**：不同国家和地区的夏令时规则不同
**解决方法**：通过Calendar对象的getTimeZone()和系统时区规则自动处理，无需手动判断。多数时区已预配置夏令时规则

### Q3：月份参数为什么从0开始计数？
**原因**：遵循JavaScript Date对象的惯例，月份从0开始计数（0=一月，11=十二月）
**解决方法**：调用set方法时，月份参数减1（例如设置3月时传入2）

### Q4：存储和传输时间数据时如何避免夏令时影响？
**原因**：本地时间受夏令时跳变影响，可能导致时间空缺或重复
**解决方法**：使用零时区标准时间（UTC或GMT）存储和传输时间数据，避免夏令时跳变导致的信息丢失或异常

### Q5：如何处理夏令时跳入导致的时间空缺？
**原因**：夏令时跳入时，时间从1:59:59跳转到3:00:00，2:00:00-2:59:59这段时间不存在
**解决方法**：使用UTC时间存储关键时间点，显示时通过Calendar对象自动转换为本地时间，避免空缺时间导致的数据异常

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "hoursDiff": 23,
  "timezone": "Europe/London",
  "startDate": "2021-03-27 16:00:00",
  "endDate": "2021-03-28 16:00:00",
  "description": "夏令时开始当天，时间缩短为23小时",
  "apiUsed": [
    "i18n.getCalendar",
    "Calendar.setTimeZone",
    "Calendar.set",
    "Calendar.getTimeInMillis",
    "Calendar.getTimeZone"
  ]
}
```

## 参考文档

- [夏令时跳变开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-dst-transition)
- [@ohos.i18n API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)

## 完整示例代码

- [ArkTS示例代码](assets/dst_transition_example.ets)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [计算伦敦夏令时跳变](tests/test_dst_positive.ets)：验证2021年3月27日到28日的23小时计算
- [计算纽约夏令时跳变](tests/test_dst_positive.ets)：验证不同时区的夏令时跳变计算

### 边界测试用例
- [夏令时结束当天计算](tests/test_dst_boundary.ets)：验证夏令时结束当天的时间差为25小时
- [跨年夏令时计算](tests/test_dst_boundary.ets)：验证跨年时间范围的夏令时影响

### 异常测试用例
- [无效时区ID测试](tests/test_dst_exception.ets)：验证时区ID格式错误的错误处理
- [时间参数超范围测试](tests/test_dst_exception.ets)：验证月份、日期等参数超出范围的错误处理