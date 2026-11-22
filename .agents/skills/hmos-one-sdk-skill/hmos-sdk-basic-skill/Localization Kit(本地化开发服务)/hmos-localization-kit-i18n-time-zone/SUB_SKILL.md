---
name: hmos-localization-kit-i18n-time-zone
description: 获取和管理HarmonyOS时区对象，支持遍历时区列表、获取时区偏移量、获取时区跳变时间点和偏移量，适用于双时钟应用、时区选择器、时区信息查询场景，API version 7+可用，时区跳变功能需API version 20+
---

# 时区技能

## 功能描述

本技能提供HarmonyOS时区相关的能力，包括获取时区对象、遍历时区列表、获取时区偏移量、获取时区跳变时间点和偏移量等。支持通过时区ID、城市ID或地理坐标创建时区对象，并可以获取时区的本地化名称和偏移量信息。从API version 20开始，还支持获取时区跳变规则和跳变时间点，用于处理夏令时切换场景。

**核心能力**：
- 获取特定时区对象（通过时区ID、城市ID或地理坐标）
- 遍历系统支持的时区列表和城市列表
- 获取时区的偏移量（固定偏移量和实际偏移量）
- 获取时区的本地化名称
- 获取时区跳变信息（时间点、跳变前后偏移量）

**适用范围**：
- API version 7+：基础时区功能
- API version 10+：根据地理坐标获取时区
- API version 20+：时区跳变规则查询

**限制条件**：
- 时区ID必须是系统支持的合法时区ID
- 城市ID必须是系统支持的时区城市ID
- 地理坐标经度范围[-180, 179.9)，纬度范围[-90, 89.9)
- 时区偏移量单位为毫秒

**典型场景**：
- 双时钟应用：同时显示多个时区的时间
- 时区选择器：展示时区列表供用户选择
- 时区信息查询：获取特定时区的详细信息
- 夏令时提醒：获取时区跳变时间点

## 使用场景

### 触发词
- "获取时区"
- "遍历时区列表"
- "获取时区偏移量"
- "时区跳变"
- "双时钟应用"
- "时区选择器"
- "根据城市获取时区"
- "根据坐标获取时区"

### 能做
- 通过时区ID获取时区对象及其详细信息
- 通过城市ID创建时区对象
- 通过地理坐标获取所在时区对象数组
- 获取系统支持的时区ID列表和城市ID列表
- 获取时区的本地化名称（支持多语言）
- 获取时区的固定偏移量和实际偏移量（包含夏令时）
- 获取时区的跳变时间点和跳变前后偏移量（API 20+）
- 将时区跳变时间点格式化为可读字符串

### 绝不做
- 不处理时区之外的国际化功能（如语言、地区、日历等）
- 不直接修改系统时区设置
- 不处理时区转换计算（需配合Calendar API使用）
- 不支持创建自定义时区
- 不处理历史时区数据查询（仅支持未来跳变点）

### 补充
- 时区跳变功能仅支持API version 20+，低版本应用无法使用
- 时区偏移量单位为毫秒，需要转换为小时时除以3600000
- 地理坐标获取时区可能返回多个时区对象（边界区域）
- 某些时区无夏令时，跳变查询返回值为0

## 调用规范和规则

### 输入约束
- 时区ID：必须是系统支持的时区ID，格式如'Asia/Shanghai'、'America/Sao_Paulo'
- 城市ID：必须是系统支持的时区城市ID，如'Shanghai'、'Auckland'
- 地理坐标：经度范围[-180, 179.9)，纬度范围[-90, 89.9)，精度为小数
- locale参数：合法的区域ID字符串，如'zh-CN'、'en-US'
- 时间戳：从1970年1月1日开始的毫秒数

### 执行约束
- API调用无频次限制
- 最大时区列表长度：系统支持约25个时区城市ID，数百个时区ID
- 时区跳变查询：仅返回下一个跳变点，不返回历史跳变
- 建议在异步任务中处理时区列表遍历

### 内容约束
- 禁止使用硬编码时区偏移量（应通过API获取）
- 禁止假设时区偏移量固定不变（夏令时会改变）
- 禁止直接使用时区跳变时间戳作为展示文本（需格式化）
- 代码必须包含参数合法性校验
- 必须处理API异常（参数错误、不支持时区等）

### 降级约束
- 无效时区ID：提示用户选择系统支持的时区ID
- 无效城市ID：提示用户选择系统支持的城市ID
- 无效地理坐标：返回空数组并提示用户修正坐标
- API version不足：提示用户升级API版本或使用基础功能
- 时区跳变查询失败：提示该时区可能无夏令时

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API version是否满足需求（基础功能7+，地理坐标10+，跳变20+）
2. 校验时区ID/城市ID是否合法（通过getAvailableIDs或getAvailableZoneCityIDs验证）
3. 校验地理坐标范围（经度[-180, 179.9)，纬度[-90, 89.9)）
4. 校验locale参数格式（符合区域ID规范）

**参数准备**：
```typescript
// ArkTS示例 - 准备时区相关参数
import { i18n } from '@kit.LocalizationKit';

// 时区ID参数
const timezoneId: string = 'America/Sao_Paulo';

// 城市ID参数
const cityId: string = 'Auckland';

// 地理坐标参数
const longitude: number = -43.1;  // 西经43.1度
const latitude: number = -22.5;   // 南纬22.5度

// locale参数
const locale: string = 'zh-Hans';

// 时间戳参数
const timestamp: number = new Date().getTime();
```

### 步骤2：获取时区对象

**示例代码**：
```typescript
// 导入必要模块
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

// 通过时区ID获取时区对象
function getTimezoneById(zoneID: string): i18n.TimeZone | null {
  try {
    // 校验时区ID是否为空
    if (!zoneID || zoneID.trim() === '') {
      console.error('时区ID不能为空');
      return null;
    }
    
    // 获取时区对象
    const timezone: i18n.TimeZone = i18n.getTimeZone(zoneID);
    
    // 验证时区对象是否有效
    const id: string = timezone.getID();
    console.info(`成功获取时区对象，ID: ${id}`);
    
    return timezone;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`获取时区对象失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    return null;
  }
}

// 通过城市ID获取时区对象
function getTimezoneByCity(cityID: string): i18n.TimeZone | null {
  try {
    // 校验城市ID是否为空
    if (!cityID || cityID.trim() === '') {
      console.error('城市ID不能为空');
      return null;
    }
    
    // 获取时区对象
    const timezone: i18n.TimeZone = i18n.TimeZone.getTimezoneFromCity(cityID);
    
    // 验证时区对象
    const id: string = timezone.getID();
    console.info(`成功获取时区对象，城市: ${cityID}, 时区ID: ${id}`);
    
    return timezone;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`通过城市获取时区失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    return null;
  }
}

// 通过地理坐标获取时区对象数组
function getTimezonesByLocation(longitude: number, latitude: number): Array<i18n.TimeZone> {
  try {
    // 校验坐标范围
    if (longitude < -180 || longitude >= 180) {
      console.error(`经度超出范围，有效范围: [-180, 179.9)，当前值: ${longitude}`);
      return [];
    }
    if (latitude < -90 || latitude >= 90) {
      console.error(`纬度超出范围，有效范围: [-90, 89.9)，当前值: ${latitude}`);
      return [];
    }
    
    // 获取时区对象数组
    const timezoneArray: Array<i18n.TimeZone> = i18n.TimeZone.getTimezonesByLocation(longitude, latitude);
    
    console.info(`成功获取${timezoneArray.length}个时区对象`);
    return timezoneArray;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`通过坐标获取时区失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    return [];
  }
}

// 使用示例
const timezone1 = getTimezoneById('America/Sao_Paulo');
const timezone2 = getTimezoneByCity('Auckland');
const timezoneArray = getTimezonesByLocation(-43.1, -22.5);
```

### 步骤3：获取时区信息

**示例代码**：
```typescript
// 获取时区基本信息
function getTimezoneInfo(timezone: i18n.TimeZone, locale: string): object {
  try {
    // 获取时区ID
    const timezoneId: string = timezone.getID();
    
    // 获取时区本地化名称
    const displayName: string = timezone.getDisplayName(locale, false);
    
    // 获取固定偏移量（不包含夏令时）
    const rawOffset: number = timezone.getRawOffset();
    
    // 获取实际偏移量（包含夏令时）
    const currentTimestamp: number = new Date().getTime();
    const offset: number = timezone.getOffset(currentTimestamp);
    
    // 转换偏移量为小时
    const rawOffsetHours: number = rawOffset / 3600000;
    const offsetHours: number = offset / 3600000;
    
    console.info(`时区ID: ${timezoneId}`);
    console.info(`本地化名称: ${displayName}`);
    console.info(`固定偏移量: ${rawOffset}ms (${rawOffsetHours}小时)`);
    console.info(`当前偏移量: ${offset}ms (${offsetHours}小时)`);
    
    return {
      id: timezoneId,
      displayName: displayName,
      rawOffset: rawOffset,
      rawOffsetHours: rawOffsetHours,
      offset: offset,
      offsetHours: offsetHours,
      has DST: offset !== rawOffset
    };
  } catch (error) {
    console.error(`获取时区信息失败: ${error}`);
    return {};
  }
}

// 遍历时区城市列表
function listTimezoneCities(locale: string): Array<object> {
  try {
    // 获取系统支持的城市ID列表
    const cityIDs: Array<string> = i18n.TimeZone.getAvailableZoneCityIDs();
    
    const timezoneList: Array<object> = [];
    
    for (let i = 0; i < cityIDs.length; i++) {
      const cityId: string = cityIDs[i];
      
      // 获取城市本地化名称
      const cityDisplayName: string = i18n.TimeZone.getCityDisplayName(cityId, locale);
      
      // 获取对应时区对象
      const timezone: i18n.TimeZone = i18n.TimeZone.getTimezoneFromCity(cityId);
      
      // 获取当前时间偏移量
      const timestamp: number = new Date().getTime();
      const offset: number = timezone.getOffset(timestamp);
      const offsetHours: number = offset / 3600000;
      
      timezoneList.push({
        cityId: cityId,
        cityDisplayName: cityDisplayName,
        timezoneId: timezone.getID(),
        offset: offset,
        offsetHours: offsetHours
      });
    }
    
    console.info(`成功获取${timezoneList.length}个时区城市信息`);
    return timezoneList;
  } catch (error) {
    console.error(`遍历时区城市列表失败: ${error}`);
    return [];
  }
}

// 使用示例
const timezone = i18n.getTimeZone('America/Sao_Paulo');
const info = getTimezoneInfo(timezone, 'zh-Hans');
const cities = listTimezoneCities('zh-CN');
```

### 步骤4：获取时区跳变信息（API 20+）

**示例代码**：
```typescript
// 获取时区跳变信息
function getTimezoneTransition(timezoneId: string, fromDate: Date): object | null {
  try {
    // 校验API version（需要API 20+）
    // 注：实际项目中需要检查设备API version
    
    // 获取时区对象
    const timezone: i18n.TimeZone = i18n.getTimeZone(timezoneId);
    
    // 获取时区跳变规则
    const zoneRules: i18n.ZoneRules = timezone.getZoneRules();
    
    // 获取指定时间后的下一个跳变对象
    const timestamp: number = fromDate.getTime();
    const zoneOffsetTransition: i18n.ZoneOffsetTransition = zoneRules.nextTransition(timestamp);
    
    // 获取跳变时间点
    const transitionTime: number = zoneOffsetTransition.getMilliseconds();
    
    // 获取跳变前后偏移量
    const offsetBefore: number = zoneOffsetTransition.getOffsetBefore();
    const offsetAfter: number = zoneOffsetTransition.getOffsetAfter();
    
    // 转换为小时
    const offsetBeforeHours: number = offsetBefore / 3600000;
    const offsetAfterHours: number = offsetAfter / 3600000;
    
    // 如果跳变时间为0，说明该时区无夏令时
    if (transitionTime === 0) {
      console.info(`时区 ${timezoneId} 无夏令时跳变`);
      return {
        hasTransition: false,
        timezoneId: timezoneId
      };
    }
    
    // 格式化跳变时间
    const dateTimeFormat: Intl.DateTimeFormat = new Intl.DateTimeFormat('zh-CN', {
      timeZone: timezoneId,
      dateStyle: 'long',
      timeStyle: 'long',
      hour12: false
    });
    const formattedTime: string = dateTimeFormat.format(new Date(transitionTime));
    
    console.info(`时区跳变时间: ${formattedTime}`);
    console.info(`跳变前偏移量: ${offsetBeforeHours}小时`);
    console.info(`跳变后偏移量: ${offsetAfterHours}小时`);
    
    return {
      hasTransition: true,
      timezoneId: timezoneId,
      transitionTime: transitionTime,
      formattedTime: formattedTime,
      offsetBefore: offsetBefore,
      offsetBeforeHours: offsetBeforeHours,
      offsetAfter: offsetAfter,
      offsetAfterHours: offsetAfterHours
    };
  } catch (error) {
    console.error(`获取时区跳变信息失败: ${error}`);
    return null;
  }
}

// 使用示例
const transition = getTimezoneTransition('America/Tijuana', new Date(2025, 4, 13));
```

### 步骤5：双时钟应用示例

**示例代码**：
```typescript
// 双时钟应用：显示多个时区的当前时间
function displayMultiClockApp(preferredTimezoneIds: Array<string>): void {
  try {
    // 获取系统locale
    const locale: Intl.Locale = i18n.System.getSystemLocaleInstance();
    
    // 创建日历对象
    const calendar: i18n.Calendar = i18n.getCalendar(locale.toString());
    
    console.info('=== 多时区时钟 ===');
    
    for (let i = 0; i < preferredTimezoneIds.length; i++) {
      const timezoneId: string = preferredTimezoneIds[i];
      
      // 设置日历的时区
      calendar.setTimeZone(timezoneId);
      
      // 获取年月日时分秒
      const year: number = calendar.get('year');
      const month: number = calendar.get('month') + 1;  // 月份从0开始
      const day: number = calendar.get('date');
      const hour: number = calendar.get('hour');
      const minute: number = calendar.get('minute');
      const second: number = calendar.get('second');
      
      // 格式化显示
      const timeStr: string = `${year}-${month}-${day} ${hour}:${minute}:${second}`;
      
      // 获取时区本地化名称
      const timezone: i18n.TimeZone = i18n.getTimeZone(timezoneId);
      const timezoneName: string = timezone.getDisplayName(locale.toString(), false);
      
      console.info(`${timezoneName}: ${timeStr}`);
    }
  } catch (error) {
    console.error(`显示多时区时钟失败: ${error}`);
  }
}

// 使用示例
const preferredTimezones = ['Asia/Shanghai', 'America/New_York', 'Europe/London'];
displayMultiClockApp(preferredTimezones);
```

### 步骤6：错误处理

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

// 综合错误处理示例
function safeGetTimezone(zoneID: string): i18n.TimeZone | null {
  try {
    // 参数校验
    if (!zoneID) {
      throw new Error('时区ID不能为空');
    }
    
    // 获取可用时区ID列表进行验证
    const availableIDs: Array<string> = i18n.TimeZone.getAvailableIDs();
    if (!availableIDs.includes(zoneID)) {
      console.warn(`时区ID ${zoneID} 可能不在系统支持列表中，但仍尝试获取`);
    }
    
    // 获取时区对象
    const timezone: i18n.TimeZone = i18n.getTimeZone(zoneID);
    return timezone;
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('参数错误：时区ID格式不正确或必填参数缺失');
        // 降级方案：使用系统默认时区
        return i18n.getTimeZone();
        
      case 890001:
        console.error('无效参数：时区ID验证失败');
        // 降级方案：提示用户选择有效时区
        console.info('请使用以下时区ID之一:', i18n.TimeZone.getAvailableIDs().slice(0, 5));
        return null;
        
      default:
        console.error(`未知错误: ${err.code}, ${err.message}`);
        return null;
    }
  }
}

// 使用示例
const tz1 = safeGetTimezone('Asia/Shanghai');  // 正常
const tz2 = safeGetTimezone('Invalid/Zone');   // 触发错误处理
const tz3 = safeGetTimezone('');               // 触发参数校验错误
```

### 步骤7：降级处理

**示例代码**：
```typescript
// 降级处理：不支持时区的处理方案
function handleUnsupportedTimezone(cityId: string): i18n.TimeZone {
  try {
    // 尝试通过城市ID获取时区
    const timezone: i18n.TimeZone = i18n.TimeZone.getTimezoneFromCity(cityId);
    return timezone;
  } catch (error) {
    console.warn(`城市ID ${cityId} 不支持，使用降级方案`);
    
    // 降级方案1：尝试使用时区ID
    try {
      const timezoneId: string = convertCityToTimezoneId(cityId);
      return i18n.getTimeZone(timezoneId);
    } catch (e) {
      console.warn('降级方案1失败');
    }
    
    // 降级方案2：使用系统默认时区
    console.info('使用系统默认时区');
    return i18n.getTimeZone();
  }
}

// 城市ID到时区ID的映射（示例）
function convertCityToTimezoneId(cityId: string): string {
  const cityToTimezoneMap: Record<string, string> = {
    'Beijing': 'Asia/Shanghai',
    'New York': 'America/New_York',
    'London': 'Europe/London',
    'Tokyo': 'Asia/Tokyo',
    'Sydney': 'Australia/Sydney'
  };
  
  return cityToTimezoneMap[cityId] || '';
}

// 使用示例
const timezone = handleUnsupportedTimezone('UnknownCity');
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误 | 检查参数是否为空、参数类型是否正确 |
| 890001 | 无效参数。可能原因：参数验证失败 | 检查时区ID/城市ID是否在系统支持列表中 |
| - | 时区ID不存在 | 使用getAvailableIDs获取支持的时区ID列表 |
| - | 城市ID不存在 | 使用getAvailableZoneCityIDs获取支持的城市ID列表 |
| - | 地理坐标超出范围 | 确保经度[-180, 179.9)，纬度[-90, 89.9) |
| - | API version不足 | 检查设备API version，时区跳变需API 20+ |

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "最新版本"
  }
}
```

**导入语句**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 环境要求
- HarmonyOS API version 7+：基础时区功能
- HarmonyOS API version 10+：地理坐标获取时区
- HarmonyOS API version 20+：时区跳变规则查询
- DevEco Studio: 最新版本

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**：
1. 检查项目API version是否满足要求（至少7+）
2. 在oh-package.json5中添加依赖声明
3. 运行`ohpm install`安装依赖

**问题2：API不存在**
```
Error: Property 'getZoneRules' does not exist on type 'TimeZone'
```
**解决方法**：
1. 检查设备API version是否满足20+
2. 使用条件编译或版本检查
```typescript
// API version检查示例
if (canIUse('SystemCapability.Global.I18n.TimeZone.ZoneRules')) {
  const zoneRules = timezone.getZoneRules();
}
```

**问题3：参数类型错误**
```
Error: Argument of type 'string' is not assignable to parameter of type 'number'
```
**解决方法**：
1. 检查参数类型定义
2. 确保时间戳为number类型（毫秒）
3. 使用`new Date().getTime()`获取时间戳

**问题4：时区跳变返回值为0**
```
zoneOffsetTransition.getMilliseconds() returns 0
```
**解决方法**：
1. 检查时区是否支持夏令时（如'Asia/Shanghai'无夏令时）
2. 使用支持夏令时的时区（如'America/Tijuana'）
3. 处理返回值为0的情况，提示用户该时区无跳变

## 常见问题与解决方法

### Q1：如何判断时区是否支持夏令时？
**原因**：不同时区有不同的夏令时规则，某些时区无夏令时
**解决方法**：
- 比较固定偏移量和实际偏移量：如果`getOffset() !== getRawOffset()`，则当前处于夏令时
- 查询时区跳变：如果`getMilliseconds() === 0`，则该时区无夏令时跳变
```typescript
function hasDaylightSavingTime(timezone: i18n.TimeZone): boolean {
  const rawOffset = timezone.getRawOffset();
  const currentOffset = timezone.getOffset(new Date().getTime());
  return currentOffset !== rawOffset;
}
```

### Q2：如何将偏移量毫秒转换为小时？
**原因**：API返回偏移量单位为毫秒，展示时需要小时
**解决方法**：
- 使用公式：`offsetHours = offset / 3600000`
- 格式化显示：`GMT${offsetHours >= 0 ? '+' : ''}${offsetHours}`
```typescript
function formatOffset(offset: number): string {
  const hours = offset / 3600000;
  return `GMT${hours >= 0 ? '+' : ''}${hours}`;
}
```

### Q3：如何获取用户当前所在时区？
**原因**：用户可能在不同地区，需要自动获取本地时区
**解决方法**：
- 使用系统默认时区：`i18n.getTimeZone()`
- 使用地理坐标获取时区：`i18n.TimeZone.getTimezonesByLocation(longitude, latitude)`
- 使用设备定位服务获取坐标

### Q4：如何处理时区列表过长的问题？
**原因**：系统支持数百个时区ID，直接展示用户体验差
**解决方法**：
- 使用城市ID列表：约25个主要城市，更简洁
- 提供搜索功能：允许用户输入城市名或时区ID
- 分组展示：按地区或国家分组
```typescript
// 使用城市列表代替时区列表
const cityIDs = i18n.TimeZone.getAvailableZoneCityIDs();  // 约25个
const timezoneIDs = i18n.TimeZone.getAvailableIDs();      // 数百个
```

### Q5：如何确保时区信息的实时性？
**原因**：夏令时切换会导致时区偏移量变化
**解决方法**：
- 使用`getOffset(date)`获取指定时间的偏移量
- 定期刷新时区信息（每小时或每天）
- 监听系统时间变化事件
```typescript
// 获取指定时间的偏移量
const futureDate = new Date('2025-11-02');
const futureOffset = timezone.getOffset(futureDate.getTime());
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "timezoneId": "America/Sao_Paulo",
  "displayName": "巴西利亚标准时间",
  "rawOffset": -10800000,
  "rawOffsetHours": -3,
  "currentOffset": -10800000,
  "currentOffsetHours": -3,
  "hasDST": false,
  "transitionInfo": {
    "hasTransition": false,
    "nextTransition": null
  },
  "apiUsed": [
    "i18n.getTimeZone",
    "TimeZone.getID",
    "TimeZone.getDisplayName",
    "TimeZone.getRawOffset",
    "TimeZone.getOffset",
    "TimeZone.getAvailableZoneCityIDs",
    "TimeZone.getCityDisplayName",
    "TimeZone.getTimezoneFromCity"
  ],
  "apiVersion": {
    "minimum": 7,
    "recommended": 20
  }
}
```

## 参考文档

- [时区开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-time-zone)
- [夏令时跳变说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-dst-transition)
- [国际化I18n API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)

## 完整示例代码

- [ArkTS基础示例](assets/timezone_basic_example.ets) - 时区基本功能示例
- [ArkTS跳变示例](assets/timezone_transition_example.ets) - 时区跳变查询示例（API 20+）
- [ArkTS双时钟应用](assets/multi_clock_app_example.ets) - 双时钟应用完整示例
- [配置文件示例](assets/timezone_config.json) - 时区配置文件示例

## 测试用例

### 正向测试用例
- [通过时区ID获取对象](tests/test_positive.ets#testGetTimezoneById) - 测试合法时区ID获取时区对象
- [通过城市ID获取对象](tests/test_positive.ets#testGetTimezoneByCity) - 测试合法城市ID获取时区对象
- [通过坐标获取时区数组](tests/test_positive.ets#testGetTimezonesByLocation) - 测试合法坐标获取时区数组
- [获取时区偏移量](tests/test_positive.ets#testGetTimezoneOffset) - 测试获取固定偏移量和实际偏移量
- [遍历时区城市列表](tests/test_positive.ets#testListTimezoneCities) - 测试遍历所有城市时区信息
- [获取时区跳变信息](tests/test_positive.ets#testGetTimezoneTransition) - 测试获取夏令时跳变时间（API 20+）

### 边界测试用例
- [坐标边界值](tests/test_boundary.ets#testCoordinateBoundary) - 测试经纬度边界值（-180, 179.9, -90, 89.9）
- [无夏令时时区](tests/test_boundary.ets#testNoDSTTimezone) - 测试无夏令时时区的跳变查询（返回0）
- [系统默认时区](tests/test_boundary.ets#testDefaultTimezone) - 测试不传参数获取系统默认时区
- [历史时间跳变查询](tests/test_boundary.ets#testHistoricalTransition) - 测试查询过去时间的跳变点

### 异常测试用例
- [无效时区ID](tests/test_exception.ets#testInvalidTimezoneId) - 测试不存在的时区ID错误处理
- [无效城市ID](tests/test_exception.ets#testInvalidCityId) - 测试不支持的城市ID错误处理
- [坐标超出范围](tests/test_exception.ets#testCoordinateOutOfRange) - 测试超出范围的坐标错误处理
- [参数类型错误](tests/test_exception.ets#testParameterTypeError) - 测试错误的参数类型处理
- [空参数](tests/test_exception.ets#testEmptyParameter) - 测试空字符串或null参数处理
- [API version不足](tests/test_exception.ets#testApiVersionInsufficient) - 测试低API version调用高版本API的处理