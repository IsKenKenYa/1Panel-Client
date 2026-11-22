---
name: hmos-localization-kit-i18n-calendar
description: 设置日历和历法，支持公历、农历、伊斯兰历等12种历法，提供日期时间设置、时区管理、周末判断、日期计算等能力，适用于国际化应用的日历处理场景
---

# 设置日历和历法技能

## 功能描述

本技能提供HarmonyOS国际化日历和历法设置能力，支持创建和操作多种历法的日历对象，包括公历、农历、伊斯兰历、希伯来历等12种历法。主要功能包括：

- 创建指定区域和历法的日历对象
- 设置和获取日期时间（年、月、日、时、分、秒）
- 设置和获取时区信息
- 配置周起始日和第一周最小天数
- 获取日历属性值（年、月、日等）
- 判断指定日期是否为周末
- 对日历属性进行加减运算
- 比较日期相差天数
- 获取日历名称的本地化翻译

支持的历法类型：buddhist（佛历）、chinese（农历）、coptic（科普特历）、ethiopic（埃塞俄比亚历）、hebrew（希伯来历）、gregory（公历）、indian（印度历）、islamic_civil（伊斯兰希吉来历）、islamic_tbla（伊斯兰天文历）、islamic_umalqura（伊斯兰历乌姆库拉）、japanese（日本历）、persian（波斯历）。

## 使用场景

### 触发词
- "设置日历"
- "创建日历对象"
- "获取农历日期"
- "日历历法"
- "公历转农历"
- "判断周末"
- "日历时区设置"
- "Calendar API"
- "i18n.Calendar"

### 能做
- 创建指定区域和历法的日历对象（支持12种历法）
- 设置日历的日期和时间（Date对象或时间戳）
- 设置和获取日历对象的时区
- 配置周起始日和一年中第一周的最小天数
- 获取日历的各种属性值（年、月、日、时、分、秒等）
- 判断指定日期在日历中是否为周末
- 对日历的日期字段进行加减操作
- 比较日历日期与指定日期相差的天数
- 获取日历名称在指定语言下的本地化翻译
- 公历日期与农历日期的转换

### 绝不做
- 不处理日历UI界面渲染和显示
- 不提供日历事件管理功能
- 不处理日历提醒和通知
- 不提供日历数据持久化存储
- 不处理非日历相关的国际化功能

### 补充
- 月份从0开始计数（0表示一月，11表示十二月）
- 周起始日：1代表周日，2代表周一，7代表周六
- 农历年份使用干支纪年（范围1-60），月份从0开始
- 不同历法的日期计算规则不同，需根据实际需求选择合适的历法
- 时区设置需使用合法的时区ID（如"Asia/Shanghai"）

## 调用规范和规则

### 输入约束
- 区域ID（locale）：必须是合法的区域ID字符串，格式为"语言-脚本-国家地区"（如"zh-Hans-CN"）
- 历法类型（type）：必须是支持的历法类型之一（buddhist, chinese, coptic, ethiopic, hebrew, gregory, indian, islamic_civil, islamic_tbla, islamic_umalqura, japanese, persian）
- 时区ID（timezone）：必须是合法的时区ID字符串（如"Asia/Shanghai"）
- 日期参数：Date对象或Unix时间戳（毫秒）
- 年月日参数：year（数字）、month（0-11）、date（1-31）、hour（0-23）、minute（0-59）、second（0-59）
- 周起始日：1-7（1=周日，7=周六）
- 第一周最小天数：正整数

### 执行约束
- 最大耗时：单个API调用不超过100ms
- API调用频次：无限制
- 内存占用：单个日历对象不超过1KB
- 线程安全：日历对象非线程安全，多线程环境需同步

### 内容约束
- 禁止使用硬编码的区域ID
- 禁止使用不支持的历法类型
- 禁止使用无效的时区ID
- 禁止对返回的日期格式进行硬编码假设
- 禁止忽略月份从0开始的规则

### 降级约束
- 区域ID无效：使用系统默认区域（zh-Hans-CN）
- 历法类型无效：使用区域默认历法（gregory）
- 时区ID无效：使用系统默认时区
- 日期计算失败：返回错误信息，不修改日历对象状态

## 调用流程和步骤

### 步骤1：导入模块

**前置校验**：
1. 确认项目已配置@kit.LocalizationKit依赖
2. 确认API version >= 8（Calendar接口从API version 8开始支持）
3. 确认设备支持国际化能力（SystemCapability.Global.I18n）

**导入模块**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：创建日历对象

**创建公历日历对象**：
```typescript
// 创建中国区域的公历日历对象
let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans-CN', 'gregory');

// 创建美国区域的公历日历对象（使用默认历法）
let calendarUS: i18n.Calendar = i18n.getCalendar('en-US');
```

**创建农历日历对象**：
```typescript
// 创建农历日历对象
let calendarChinese: i18n.Calendar = i18n.getCalendar('zh-Hans-CN', 'chinese');
```

**创建其他历法日历对象**：
```typescript
// 伊斯兰历
let calendarIslamic: i18n.Calendar = i18n.getCalendar('ar-SA', 'islamic_umalqura');

// 希伯来历
let calendarHebrew: i18n.Calendar = i18n.getCalendar('he-IL', 'hebrew');

// 日本历
let calendarJapanese: i18n.Calendar = i18n.getCalendar('ja-JP', 'japanese');
```

### 步骤3：设置日期和时间

**使用Date对象设置**：
```typescript
// 使用Date对象设置日期时间（注意：月份从0开始）
let date: Date = new Date(2023, 6, 25, 8, 0, 0); // 2023年7月25日 08:00:00
calendar.setTime(date);
```

**使用时间戳设置**：
```typescript
// 使用Unix时间戳设置（毫秒）
calendar.setTime(1690272000000);
```

**使用年月日时分秒设置**：
```typescript
// 设置日期时间（月份从0开始）
calendar.set(2023, 6, 25, 8, 0, 0); // 2023年7月25日 08:00:00

// 只设置年月日（时分秒使用当前时间）
calendar.set(2023, 6, 25);
```

### 步骤4：配置时区和周设置

**设置和获取时区**：
```typescript
// 设置时区
calendar.setTimeZone('Asia/Shanghai');

// 获取时区
let timezone: string = calendar.getTimeZone(); // 'Asia/Shanghai'
```

**设置和获取周起始日**：
```typescript
// 获取当前周起始日（1=周日，2=周一，...，7=周六）
let firstDayOfWeek: number = calendar.getFirstDayOfWeek();

// 设置周起始日（设置为周一）
calendar.setFirstDayOfWeek(2);
```

**设置和获取第一周最小天数**：
```typescript
// 获取一年中第一周的最小天数
let minimalDays: number = calendar.getMinimalDaysInFirstWeek();

// 设置第一周的最小天数为3天
calendar.setMinimalDaysInFirstWeek(3);
```

### 步骤5：获取日历属性

**获取日期时间属性**：
```typescript
// 获取年份
let year: number = calendar.get('year'); // 2023

// 获取月份（0-11，0表示一月）
let month: number = calendar.get('month'); // 6表示七月

// 获取日期
let day: number = calendar.get('date'); // 25

// 获取小时（挂钟小时）
let hour: number = calendar.get('hour'); // 8

// 获取小时（一天中的第几小时，0-23）
let hourOfDay: number = calendar.get('hour_of_day'); // 8

// 获取分钟
let minute: number = calendar.get('minute'); // 0

// 获取秒
let second: number = calendar.get('second'); // 0

// 获取星期几（1=周日，2=周一，...，7=周六）
let dayOfWeek: number = calendar.get('day_of_week'); // 3表示周二

// 获取一年中的第几天
let dayOfYear: number = calendar.get('day_of_year'); // 206

// 获取一年中的第几周
let weekOfYear: number = calendar.get('week_of_year'); // 30
```

**获取农历日期**（使用农历日历对象）：
```typescript
let calendarChinese: i18n.Calendar = i18n.getCalendar('zh-Hans-CN', 'chinese');
calendarChinese.setTime(new Date(2023, 6, 25, 8, 0, 0));

// 获取农历年（干支纪年，范围1-60）
let yearChinese: number = calendarChinese.get('year'); // 40

// 获取农历月（0-11，0表示正月）
let monthChinese: number = calendarChinese.get('month'); // 5表示六月

// 获取农历日
let dayChinese: number = calendarChinese.get('date'); // 8
```

### 步骤6：判断周末和日期计算

**判断是否为周末**：
```typescript
// 判断当前日期是否为周末
let isWeekend: boolean = calendar.isWeekend();

// 判断指定日期是否为周末
let date: Date = new Date(2023, 6, 29); // 2023年7月29日（周六）
isWeekend = calendar.isWeekend(date); // true
```

**日期加减运算**：
```typescript
// 设置初始日期
calendar.set(2023, 10, 15, 8, 0, 0); // 2023年11月15日

// 加2天
calendar.add('date', 2);
let day: number = calendar.get('date'); // 17

// 加1个月
calendar.add('month', 1);

// 减1年
calendar.add('year', -1);
```

**比较日期相差天数**：
```typescript
// 设置日历日期
calendar.set(2023, 10, 15); // 2023年11月15日

// 比较与指定日期相差的天数
let targetDate: Date = new Date(2023, 10, 18); // 2023年11月18日
let daysDifference: number = calendar.compareDays(targetDate); // -3（日历日期更早）
```

### 步骤7：获取日历名称

**获取日历名称本地化翻译**：
```typescript
// 获取日历名称在中文下的翻译
let calendarName: string = calendar.getDisplayName('zh-Hans-CN'); // '公历'

// 获取日历名称在英文下的翻译
let calendarNameEN: string = calendar.getDisplayName('en-US'); // 'Gregorian Calendar'

// 获取佛历名称
let calendarBuddhist: i18n.Calendar = i18n.getCalendar('zh-Hans-CN', 'buddhist');
let nameBuddhist: string = calendarBuddhist.getDisplayName('zh-Hans-CN'); // '佛历'
```

### 步骤8：错误处理

**完整错误处理示例**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

try {
  // 创建日历对象
  let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans-CN', 'gregory');
  
  // 设置日期
  calendar.set(2023, 6, 25, 8, 0, 0);
  
  // 执行日期运算
  calendar.add('date', 5);
  
  // 获取结果
  let newDate: number = calendar.get('date');
  console.log(`New date: ${newDate}`);
  
} catch (error) {
  let err: BusinessError = error as BusinessError;
  
  switch (err.code) {
    case 401:
      console.error('Parameter error: Mandatory parameters are left unspecified or parameter types are incorrect');
      break;
    case 890001:
      console.error('Invalid parameter: Parameter verification failed');
      break;
    default:
      console.error(`Unknown error: code=${err.code}, message=${err.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1.必填参数未指定；2.参数类型不正确 | 检查参数类型和必填参数是否正确传入 |
| 890001 | 参数无效。参数验证失败 | 检查区域ID、历法类型、时区ID等参数是否合法 |

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
- HarmonyOS API version >= 8
- 设备需支持国际化能力（SystemCapability.Global.I18n）
- 开发环境：DevEco Studio 3.1或更高版本

### 常见编译问题

**问题1：找不到@kit.LocalizationKit模块**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**：
- 确认项目API version >= 8
- 检查build-profile.json5中的compileSdkVersion是否正确
- 确认设备或模拟器支持国际化能力

**问题2：月份参数错误**
```
实际月份与预期不符
```
**解决方法**：
- 注意月份从0开始计数（0=一月，11=十二月）
- 使用Date对象时，new Date(2023, 6, 25)表示2023年7月25日

**问题3：农历年份理解错误**
```
农历年份不是预期的公历年份
```
**解决方法**：
- 农历年份使用干支纪年（范围1-60），不是公历年份
- 如需获取公历年份对应的农历年份，需使用干支纪年对照表

## 常见问题与解决方法

### Q1：如何判断一个日期是否为周末？
**原因**：不同国家和地区的周末定义不同，如中东地区周末为周五和周六。
**解决方法**：
- 使用`isWeekend()`方法判断日历对象当前日期是否为周末
- 使用`isWeekend(date)`方法判断指定日期是否为周末
- 日历对象会根据区域设置自动判断周末
```typescript
let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans-CN', 'gregory');
calendar.set(2023, 6, 29); // 2023年7月29日（周六）
let isWeekend: boolean = calendar.isWeekend(); // true
```

### Q2：如何获取公历日期对应的农历日期？
**原因**：农历是中国传统历法，与公历计算规则完全不同。
**解决方法**：
- 创建农历日历对象（type='chinese'）
- 将公历日期设置到农历日历对象
- 使用get()方法获取农历年月日
```typescript
let calendarChinese: i18n.Calendar = i18n.getCalendar('zh-Hans-CN', 'chinese');
calendarChinese.setTime(new Date(2023, 6, 25, 8, 0, 0));
let yearChinese: number = calendarChinese.get('year'); // 干支纪年
let monthChinese: number = calendarChinese.get('month'); // 农历月
let dayChinese: number = calendarChinese.get('date'); // 农历日
```

### Q3：如何处理时区问题？
**原因**：不同时区的日期时间不同，需要正确设置时区。
**解决方法**：
- 使用`setTimeZone(timezone)`设置时区
- 时区ID必须是合法的时区标识（如'Asia/Shanghai'）
- 不同时区的同一时刻，日期可能不同
```typescript
calendar.setTimeZone('Asia/Shanghai'); // 设置为北京时间
calendar.setTimeZone('America/New_York'); // 设置为纽约时间
```

### Q4：周起始日和第一周最小天数的作用是什么？
**原因**：不同国家和地区对周起始日和第一周的定义不同。
**解决方法**：
- 周起始日：使用`setFirstDayOfWeek()`设置，中国习惯周一为周起始日（值为2），美国习惯周日为周起始日（值为1）
- 第一周最小天数：使用`setMinimalDaysInFirstWeek()`设置，影响一年中第一周的归属计算
```typescript
// 设置周一为周起始日
calendar.setFirstDayOfWeek(2);

// 设置第一周至少包含3天
calendar.setMinimalDaysInFirstWeek(3);
```

### Q5：如何处理日期加减运算时的跨月、跨年问题？
**原因**：日期加减可能导致月份或年份变化。
**解决方法**：
- 使用`add(field, amount)`方法会自动处理跨月、跨年
- 支持的字段：year, month, date, hour, minute, second等
- amount可以为负数表示减法
```typescript
calendar.set(2023, 11, 31); // 2023年12月31日
calendar.add('date', 1); // 自动变为2024年1月1日
let newYear: number = calendar.get('year'); // 2024
let newMonth: number = calendar.get('month'); // 0（一月）
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "calendarCreated": true,
  "calendarType": "gregory",
  "locale": "zh-Hans-CN",
  "currentDate": {
    "year": 2023,
    "month": 6,
    "day": 25,
    "hour": 8,
    "minute": 0,
    "second": 0
  },
  "timezone": "Asia/Shanghai",
  "isWeekend": false,
  "apiUsed": [
    "i18n.getCalendar",
    "Calendar.setTime",
    "Calendar.set",
    "Calendar.get",
    "Calendar.setTimeZone",
    "Calendar.getTimeZone",
    "Calendar.isWeekend",
    "Calendar.add"
  ]
}
```

## 参考文档

- [API开发指南](references/i18n-calendar.md)
- [API参考说明](references/js-apis-i18n.md)

## 完整示例代码

- [ArkTS示例：公历日期操作](assets/calendar_gregory_example.ets)
- [ArkTS示例：农历日期转换](assets/calendar_chinese_example.ets)
- [ArkTS示例：日期计算与周末判断](assets/calendar_calculation_example.ets)
- [配置文件示例](assets/calendar_config.json)

## 测试用例

### 正向测试用例
- [创建公历日历对象并设置日期](tests/test_positive.ts)：验证公历日历创建和日期设置
- [创建农历日历对象并获取农历日期](tests/test_positive.ts)：验证农历日期转换
- [设置时区并获取时区](tests/test_positive.ts)：验证时区设置和获取
- [日期加减运算](tests/test_positive.ts)：验证日期计算功能

### 边界测试用例
- [月份边界测试（0和11）](tests/test_boundary.ts)：验证月份边界值处理
- [日期边界测试（1和31）](tests/test_boundary.ts)：验证日期边界值处理
- [跨年日期计算](tests/test_boundary.ts)：验证跨年日期加减
- [闰年闰月处理](tests/test_boundary.ts)：验证闰年和闰月处理

### 异常测试用例
- [无效区域ID测试](tests/test_exception.ts)：验证无效区域ID的错误处理
- [无效历法类型测试](tests/test_exception.ts)：验证无效历法类型的错误处理
- [无效时区ID测试](tests/test_exception.ts)：验证无效时区ID的错误处理
- [无效日期参数测试](tests/test_exception.ts)：验证无效日期参数的错误处理