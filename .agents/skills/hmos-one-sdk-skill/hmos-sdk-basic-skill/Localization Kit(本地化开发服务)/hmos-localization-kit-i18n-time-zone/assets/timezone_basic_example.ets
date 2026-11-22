/**
 * 时区基础功能示例
 * 展示如何获取时区对象、遍历时区列表、获取时区偏移量等基本功能
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 通过时区ID获取时区对象
 */
function getTimezoneById(zoneID: string): i18n.TimeZone | null {
  try {
    if (!zoneID || zoneID.trim() === '') {
      console.error('时区ID不能为空');
      return null;
    }
    
    const timezone: i18n.TimeZone = i18n.getTimeZone(zoneID);
    const id: string = timezone.getID();
    console.info(`成功获取时区对象，ID: ${id}`);
    
    return timezone;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`获取时区对象失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    return null;
  }
}

/**
 * 通过城市ID获取时区对象
 */
function getTimezoneByCity(cityID: string): i18n.TimeZone | null {
  try {
    if (!cityID || cityID.trim() === '') {
      console.error('城市ID不能为空');
      return null;
    }
    
    const timezone: i18n.TimeZone = i18n.TimeZone.getTimezoneFromCity(cityID);
    const id: string = timezone.getID();
    console.info(`成功获取时区对象，城市: ${cityID}, 时区ID: ${id}`);
    
    return timezone;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`通过城市获取时区失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    return null;
  }
}

/**
 * 通过地理坐标获取时区对象数组
 */
function getTimezonesByLocation(longitude: number, latitude: number): Array<i18n.TimeZone> {
  try {
    if (longitude < -180 || longitude >= 180) {
      console.error(`经度超出范围，有效范围: [-180, 179.9)，当前值: ${longitude}`);
      return [];
    }
    if (latitude < -90 || latitude >= 90) {
      console.error(`纬度超出范围，有效范围: [-90, 89.9)，当前值: ${latitude}`);
      return [];
    }
    
    const timezoneArray: Array<i18n.TimeZone> = i18n.TimeZone.getTimezonesByLocation(longitude, latitude);
    console.info(`成功获取${timezoneArray.length}个时区对象`);
    return timezoneArray;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`通过坐标获取时区失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    return [];
  }
}

/**
 * 获取时区基本信息
 */
function getTimezoneInfo(timezone: i18n.TimeZone, locale: string): object {
  try {
    const timezoneId: string = timezone.getID();
    const displayName: string = timezone.getDisplayName(locale, false);
    const rawOffset: number = timezone.getRawOffset();
    const currentTimestamp: number = new Date().getTime();
    const offset: number = timezone.getOffset(currentTimestamp);
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
      hasDST: offset !== rawOffset
    };
  } catch (error) {
    console.error(`获取时区信息失败: ${error}`);
    return {};
  }
}

/**
 * 遍历时区城市列表
 */
function listTimezoneCities(locale: string): Array<object> {
  try {
    const cityIDs: Array<string> = i18n.TimeZone.getAvailableZoneCityIDs();
    const timezoneList: Array<object> = [];
    
    for (let i = 0; i < cityIDs.length; i++) {
      const cityId: string = cityIDs[i];
      const cityDisplayName: string = i18n.TimeZone.getCityDisplayName(cityId, locale);
      const timezone: i18n.TimeZone = i18n.TimeZone.getTimezoneFromCity(cityId);
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

/**
 * 主函数 - 演示所有基础功能
 */
function main(): void {
  console.info('=== 时区基础功能示例 ===');
  
  // 示例1：通过时区ID获取时区对象
  console.info('\n--- 示例1：通过时区ID获取时区 ---');
  const timezone1 = getTimezoneById('America/Sao_Paulo');
  if (timezone1) {
    const info1 = getTimezoneInfo(timezone1, 'zh-Hans');
  }
  
  // 示例2：通过城市ID获取时区对象
  console.info('\n--- 示例2：通过城市ID获取时区 ---');
  const timezone2 = getTimezoneByCity('Auckland');
  if (timezone2) {
    const info2 = getTimezoneInfo(timezone2, 'zh-Hans');
  }
  
  // 示例3：通过地理坐标获取时区
  console.info('\n--- 示例3：通过地理坐标获取时区 ---');
  const timezoneArray = getTimezonesByLocation(-43.1, -22.5);
  if (timezoneArray.length > 0) {
    const info3 = getTimezoneInfo(timezoneArray[0], 'zh-Hans');
  }
  
  // 示例4：遍历时区城市列表
  console.info('\n--- 示例4：遍历时区城市列表 ---');
  const cities = listTimezoneCities('zh-CN');
  console.info(`前5个城市: ${JSON.stringify(cities.slice(0, 5))}`);
  
  // 示例5：获取所有时区ID
  console.info('\n--- 示例5：获取所有时区ID ---');
  const allTimezoneIds: Array<string> = i18n.TimeZone.getAvailableIDs();
  console.info(`系统支持${allTimezoneIds.length}个时区ID`);
  console.info(`前5个时区ID: ${allTimezoneIds.slice(0, 5).join(', ')}`);
  
  console.info('\n=== 示例执行完成 ===');
}

// 执行主函数
main();