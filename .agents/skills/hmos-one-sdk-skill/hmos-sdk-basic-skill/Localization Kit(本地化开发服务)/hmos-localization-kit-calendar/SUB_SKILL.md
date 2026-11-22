---
name: hmos-localization-kit-calendar
description: 设置日历和历法,支持公历/农历/伊斯兰历等多种历法类型,提供日期时间设置、时区管理、周末判断、日期计算能力,适用于国际化应用开发、日期转换、节假日判断场景
---

# 设置日历和历法技能

## 功能描述

本技能提供 HarmonyOS 日历和历法设置能力,使用 i18n.Calendar 类实现不同地区用户的历法需求。支持多种历法类型(公历、农历、伊斯兰历、希伯来历等),提供完整的日期时间管理功能,包括时区设置、周起始日配置、周末判断、日期加减运算和相差天数计算。基于 CLDR 国际化数据库实现,确保不同地区的历法规则准确性。

## 使用场景

### 触发词
- "设置日历" - 创建和配置日历对象
- "设置历法" - 指定历法类型(农历、公历等)
- "获取农历日期" - 将公历转换为农历
- "判断周末" - 判断指定日期是否为周末
- "日期计算" - 在日历上进行日期加减运算
- "日历设置" - 配置日历参数(时区、周起始日等)

### 能做
- 创建指定历法类型的日历对象(支持12种历法)
- 设置日历的时间日期(Date对象或时间戳)
- 设置和获取日历时区
- 配置一周起始日和一年第一周的最小天数
- 获取日历字段值(年、月、日、时、分、秒等)
- 获取历法的本地化名称
- 判断指定日期是否为周末
- 在日历字段上进行加减操作
- 计算日历与指定日期相差的天数
- 获取日历的时间戳

### 绝不做
- 不处理超出支持历法类型的请求(仅支持12种历法)
- 不进行跨历法的日期比较(不同历法规则不同)
- 不修改系统全局日历设置(仅操作当前日历对象)
- 不处理非法的日期参数(月份从0开始,需明确说明)
- 不执行与时区无关的日期计算

### 补充
- 月份参数从0开始计数(0表示一月,11表示十二月)
- 支持的历法类型:buddhist(佛历)、chinese(农历)、coptic(科普特历)、ethiopic(埃塞俄比亚历)、hebrew(希伯来历)、gregory(公历)、indian(印度历)、islamic_civil(伊斯兰希吉来历)、islamic_tbla(伊斯兰天文历)、islamic_umalqura(伊斯兰历乌姆库拉)、japanese(日本历)、persian(波斯历)
- API version 8开始支持,部分接口从API version 11+支持
- 元服务从API version 12开始支持

## 调用规范和规则

### 输入约束
- locale参数:必须是合法的区域ID字符串(如zh-Hans-CN)
- 历法类型:必须是支持的12种历法之一
- 日期参数:Date对象的月份从0开始(0=一月)
- 时间戳:必须是有效的Unix时间戳(毫秒)
- 时区ID:必须是合法的时区ID(如Asia/Shanghai)
- 周起始日:取值范围1-7(1=周日,7=周六)
- 第一周最小天数:正整数

### 执行约束
- API调用模式:同步调用
- 时区设置:必须在设置日期前完成
- 参数校验:自动校验参数合法性
- 错误处理:捕获BusinessError异常
- API版本检查:检查接口支持的API版本

### 内容约束
- 禁止推测:禁止使用不存在的API或参数
- 禁止硬编码:不应对返回格式进行硬编码
- 禁止跨历法:不跨历法类型进行日期比较
- 数据准确性:基于CLDR数据库,版本迭代可能调整结果
- 界面展示:返回值仅适用于界面展示场景

### 降级约束
- 参数错误:捕获401错误码,提示参数类型或必填参数问题
- 验证失败:捕获890001错误码,提示参数验证失败
- 历法不支持:提示用户使用支持的历法类型列表
- 时区无效:提示用户使用合法的时区ID

## 调用流程和步骤

### 步骤1:导入模块和准备参数

**前置校验**:
1. 确认API version >= 8(基础接口)
2. 确认元服务API version >= 12(如需在元服务中使用)
3. 确认历法类型在支持列表中
4. 确认locale参数格式正确

**参数准备**:
```typescript
// 导入必要模块
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义日历参数
const locale = 'zh-Hans-CN';  // 区域ID
const calendarType = 'chinese'; // 历法类型(农历)
```

### 步骤2:创建日历对象

**示例代码**:
```typescript
try {
  // 创建农历日历对象
  let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'chinese');
  
  // 创建公历日历对象
  let gregoryCalendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
  
  console.log('日历对象创建成功');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`创建日历对象失败, 错误码: ${err.code}, 消息: ${err.message}`);
}
```

### 步骤3:设置日期和时间

**设置Date对象**:
```typescript
try {
  let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
  
  // 使用Date对象设置日期(注意:月份从0开始)
  let date: Date = new Date(2023, 6, 25, 8, 0, 0); // 2023年7月25日 08:00:00
  calendar.setTime(date);
  
  // 使用时间戳设置日期
  calendar.setTime(10540800000); // Unix时间戳(毫秒)
  
  // 使用set方法直接设置年月日时分秒
  calendar.set(2023, 6, 25, 8, 0, 0); // 月份从0开始
  
  console.log('日期设置完成');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`设置日期失败, 错误码: ${err.code}, 消息: ${err.message}`);
}
```

### 步骤4:设置时区和获取信息

**时区操作**:
```typescript
try {
  let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
  
  // 设置时区
  calendar.setTimeZone('Asia/Shanghai');
  
  // 获取时区
  let timezone: string = calendar.getTimeZone();
  console.log(`当前时区: ${timezone}`); // Asia/Shanghai
  
  // 获取周起始日
  let firstDayOfWeek: number = calendar.getFirstDayOfWeek();
  console.log(`周起始日: ${firstDayOfWeek}`); // 1(周日)
  
  // 设置周起始日
  calendar.setFirstDayOfWeek(2); // 设置为周二
  
  // 获取一年中第一周的最小天数
  let minimalDays: number = calendar.getMinimalDaysInFirstWeek();
  console.log(`第一周最小天数: ${minimalDays}`); // 1
  
  // 设置第一周最小天数
  calendar.setMinimalDaysInFirstWeek(3);
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`时区操作失败, 错误码: ${err.code}, 消息: ${err.message}`);
}
```

### 步骤5:获取日历字段和名称

**获取字段值**:
```typescript
try {
  let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
  calendar.set(2023, 6, 25, 8, 0, 0);
  
  // 获取日历字段
  let year: number = calendar.get('year');
  let month: number = calendar.get('month'); // 注意:返回值从0开始
  let date: number = calendar.get('date');
  let hour: number = calendar.get('hour_of_day');
  let minute: number = calendar.get('minute');
  let second: number = calendar.get('second');
  
  console.log(`${year}年${month+1}月${date}日 ${hour}:${minute}:${second}`);
  
  // 获取日历本地化名称
  let calendarName: string = calendar.getDisplayName('zh-Hans');
  console.log(`历法名称: ${calendarName}`); // 公历
  
  // 获取时间戳
  let timestamp: number = calendar.getTimeInMillis();
  console.log(`时间戳: ${timestamp}`);
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`获取字段失败, 错误码: ${err.code}, 消息: ${err.message}`);
}
```

### 步骤6:判断周末和日期计算

**周末判断和日期运算**:
```typescript
try {
  let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
  calendar.set(2023, 9, 15, 8, 0, 0); // 2023年10月15日
  
  // 判断当前日期是否为周末
  let isWeekend: boolean = calendar.isWeekend();
  console.log(`是否为周末: ${isWeekend}`); // true
  
  // 判断指定日期是否为周末
  let testDate: Date = new Date(2023, 9, 16, 9, 0, 0);
  let isTestWeekend: boolean = calendar.isWeekend(testDate);
  console.log(`测试日期是否为周末: ${isTestWeekend}`);
  
  // 日期加减操作
  calendar.set(2023, 10, 15);
  calendar.add('date', 2); // 增加2天
  let newDate: number = calendar.get('date');
  console.log(`新日期: ${newDate}`); // 17
  
  // 比较相差天数
  calendar.set(2023, 10, 15);
  let compareDate: Date = new Date(2023, 10, 18);
  let daysDiff: number = calendar.compareDays(compareDate);
  console.log(`相差天数: ${daysDiff}`); // -3(负数表示指定时间更早)
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`日期计算失败, 错误码: ${err.code}, 消息: ${err.message}`);
}
```

### 步骤7:农历日期获取示例

**公历转农历**:
```typescript
try {
  // 创建农历日历对象
  let chineseCalendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'chinese');
  
  // 设置公历日期(2023年7月25日)
  chineseCalendar.setTime(new Date(2023, 6, 25, 8, 0, 0));
  
  // 获取农历年月日
  let yearChinese: number = chineseCalendar.get('year');
  let monthChinese: number = chineseCalendar.get('month');
  let dayChinese: number = chineseCalendar.get('date');
  
  console.log(`农历: ${yearChinese}年(干支纪年) ${monthChinese+1}月 ${dayChinese}日`);
  // 输出: 农历: 40年(干支纪年,范围1-60) 6月 8日
  
  // 判断是否为闰月
  let isLeapMonth: number = chineseCalendar.get('is_leap_month');
  console.log(`是否闰月: ${isLeapMonth}`);
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`农历转换失败, 错误码: ${err.code}, 消息: ${err.message}`);
}
```

### 步骤8:错误处理和降级方案

**错误处理代码**:
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

// 错误处理和降级方案
async function setupCalendarWithFallback(
  locale: string,
  calendarType: string
): Promise<i18n.Calendar | null> {
  try {
    // 尝试创建指定历法的日历
    let calendar: i18n.Calendar = i18n.getCalendar(locale, calendarType);
    console.log(`${calendarType}历法创建成功`);
    return calendar;
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    
    // 处理不同错误码
    switch (err.code) {
      case 401:
        console.error('参数错误: 必填参数未指定或参数类型错误');
        // 降级: 使用默认公历
        return i18n.getCalendar(locale, 'gregory');
        
      case 890001:
        console.error('参数验证失败: locale或历法类型无效');
        // 降级: 使用系统默认区域和公历
        return i18n.getCalendar('zh-Hans', 'gregory');
        
      default:
        console.error(`未知错误: ${err.message}`);
        return null;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误。可能原因: 1.必填参数未指定; 2.参数类型错误。 | 检查所有必填参数是否已提供,检查参数类型是否正确(Date、number、string等)。 |
| 890001 | Invalid parameter. 参数无效。可能原因: 参数验证失败。 | 验证locale格式是否正确(如zh-Hans-CN),验证历法类型是否在支持列表中,验证时区ID是否合法。 |
| 3301100 | 系统内部错误 | 重试操作,检查系统日志,联系技术支持。 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "API version 8+"
  }
}
```

### 环境要求
- HarmonyOS API version >= 8(基础接口)
- HarmonyOS API version >= 11(add、getTimeInMillis、compareDays接口)
- HarmonyOS API version >= 12(元服务支持)
- 开发环境: DevEco Studio 3.1+
- 运行环境: HarmonyOS设备或模拟器

### 常见编译问题

**问题1:导入模块失败**
```
Cannot find module '@kit.LocalizationKit' or its corresponding type declarations.
```
**解决方法**: 确保项目API version >= 8,在build-profile.json5中配置正确的compileSdkVersion。

**问题2:API版本不支持**
```
Property 'add' does not exist on type 'Calendar'.
```
**解决方法**: add方法从API version 11开始支持,升级项目API version或检查接口文档。

**问题3:月份参数错误**
```
设置日期为2023年12月,但实际显示为2023年11月。
```
**解决方法**: 月份参数从0开始计数,12月应该传入11而不是12。

## 常见问题与解决方法

### Q1:如何选择合适的历法类型?
**原因**: 不同地区使用不同的历法,需要根据用户区域选择。
**解决方法**:
- 中国用户: 使用chinese(农历)或gregory(公历)
- 伊斯兰地区: 使用islamic_civil、islamic_tbla或islamic_umalqura
- 日本用户: 使用japanese(日本历)
- 泰国、柬埔寨: 使用buddhist(佛历)
- 其他地区: 默认使用gregory(公历)

### Q2:月份参数为什么从0开始?
**原因**: JavaScript Date对象的月份从0开始,Calendar API保持一致。
**解决方法**:
- 设置月份时: 1月传0,12月传11
- 获取月份时: 返回值0表示1月,11表示12月
- 显示月份时: 需要将返回值+1

### Q3:如何处理闰月?
**原因**: 农历等历法存在闰月,需要特殊处理。
**解决方法**:
- 使用get('is_leap_month')判断是否为闰月
- 农历月份命名: 正月、二月、闰二月、三月...
- 注意闰月不影响公历日期转换

### Q4:不同历法的年份范围如何?
**原因**: 不同历法的年份计算方式不同。
**解决方法**:
- 公历: 正常年份(如2023)
- 农历: 干支纪年(范围1-60,40表示癸卯年)
- 佛历: 比公历多543年(佛历2566 = 公历2023)
- 伊斯兰历: 比公历少约580年

### Q5:compareDays返回值如何理解?
**原因**: compareDays返回正值或负值,需要理解含义。
**解决方法**:
- 正值: 日历对象时间更早,指定时间更晚
- 负值: 指定时间更早,日历对象时间更晚
- 0: 两个时间相差不足一天
- 精度: 按毫秒级精度,不足一天按一天计

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "calendarCreated": true,
  "calendarType": "chinese",
  "locale": "zh-Hans-CN",
  "currentDate": {
    "year": 2023,
    "month": 7,
    "date": 25,
    "hour": 8,
    "minute": 0,
    "second": 0
  },
  "timezone": "Asia/Shanghai",
  "firstDayOfWeek": 1,
  "minimalDaysInFirstWeek": 3,
  "calendarName": "农历",
  "isWeekend": false,
  "timestamp": 1690276800000,
  "apiUsed": [
    "i18n.getCalendar",
    "calendar.setTime",
    "calendar.set",
    "calendar.setTimeZone",
    "calendar.getTimeZone",
    "calendar.getFirstDayOfWeek",
    "calendar.setFirstDayOfWeek",
    "calendar.getMinimalDaysInFirstWeek",
    "calendar.setMinimalDaysInFirstWeek",
    "calendar.get",
    "calendar.getDisplayName",
    "calendar.isWeekend",
    "calendar.add",
    "calendar.compareDays",
    "calendar.getTimeInMillis"
  ]
}
```

## 参考文档

- [API开发指南 - 设置日历和历法](references/i18n-calendar-guide.md)
- [API参考说明 - i18n模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)

## 完整示例代码

- [ArkTS示例 - 公历操作](assets/gregory-calendar-example.ets)
- [ArkTS示例 - 农历转换](assets/chinese-calendar-example.ets)
- [ArkTS示例 - 日期计算](assets/calendar-calculation-example.ets)
- [配置文件示例](assets/calendar-config.json)

## 测试用例

### 正向测试用例
- [公历日历创建和基本操作](tests/test_gregory_calendar.ts): 测试公历日历的创建、日期设置、字段获取
- [农历日期转换](tests/test_chinese_calendar.ts): 测试公历转农历功能,验证干支纪年
- [时区和周起始日配置](tests/test_calendar_config.ts): 测试时区设置、周起始日配置功能

### 边界测试用例
- [极端日期测试](tests/test_calendar_boundary.ts): 测试公元前日期、远未来日期的处理
- [闰月和特殊月份](tests/test_calendar_special_months.ts): 测试农历闰月、闰年等特殊情况
- [跨时区日期计算](tests/test_calendar_timezone.ts): 测试跨时区的日期运算准确性

### 异常测试用例
- [无效历法类型](tests/test_invalid_calendar_type.ts): 测试传入不支持的历法类型的错误处理
- [非法日期参数](tests/test_invalid_date_params.ts): 测试非法月份、日期参数的错误处理
- [错误时区ID](tests/test_invalid_timezone.ts): 测试非法时区ID的降级处理

## 支持的历法类型详细说明

| 历法类型 | 中文名称 | 适用地区 | 年份特点 |
|---------|---------|---------|---------|
| buddhist | 佛历 | 泰国、柬埔寨、老挝 | 比公历多543年 |
| chinese | 农历 | 中国、台湾、新加坡 | 干支纪年(1-60循环) |
| coptic | 科普特历 | 埃塞俄比亚、埃及 | 比公历少约284年 |
| ethiopic | 埃塞俄比亚历 | 埃塞俄比亚 | 比公历少约8年 |
| hebrew | 希伯来历 |以色列 | 从公元前3761年开始计算 |
| gregory | 公历 | 全球通用 | 标准公元纪年 |
| indian | 印度历 | 印度 | 比公历少约78年 |
| islamic_civil | 伊斯兰希吉来历 | 伊斯兰国家 | 比公历少约580年 |
| islamic_tbla | 伊斯兰天文历 | 伊斯兰国家 | 天文算法计算 |
| islamic_umalqura | 伊斯兰历(乌姆库拉) | 沙特阿拉伯 | 官方历法 |
| japanese | 日本历 | 日本 | 基于年号纪年 |
| persian | 波斯历 | 伊朗、阿富汗 | 比公历少约621年 |

## 日历字段属性说明

| 属性名称 | 说明 | 取值范围 |
|---------|------|---------|
| era | 纪元 | 0或1(公元前/后) |
| year | 年 | 根据历法类型 |
| month | 月 | 0-11(注意从0开始) |
| date | 日 | 1-31 |
| hour | 挂钟小时 | 0-11 |
| hour_of_day | 一天中的小时 | 0-23 |
| minute | 分 | 0-59 |
| second | 秒 | 0-59 |
| millisecond | 毫秒 | 0-999 |
| week_of_year | 一年中的周 | 1-53 |
| week_of_month | 一月中的周 | 1-5 |
| day_of_year | 一年中的天 | 1-366 |
| day_of_week | 一周中的天 | 1-7 |
| zone_offset | 时区偏移 | 毫秒数 |
| dst_offset | 夏令时偏移 | 毫秒数 |
| is_leap_month | 是否闰月 | 0或1 |
| extended_year | 扩展年份 | 支持负数 |