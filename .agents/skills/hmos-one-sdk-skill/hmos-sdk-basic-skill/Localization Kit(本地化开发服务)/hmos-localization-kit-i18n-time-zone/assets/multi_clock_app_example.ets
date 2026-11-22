/**
 * 双时钟应用完整示例
 * 展示如何实现一个显示多个时区时间的应用
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 时区时钟项数据结构
 */
interface ClockItem {
  timezoneId: string;
  timezoneName: string;
  cityDisplayName: string;
  currentTime: string;
  offsetHours: number;
  isDST: boolean;
}

/**
 * 时区管理器
 */
class TimezoneManager {
  private preferredTimezones: Array<string> = [];
  private locale: string = 'zh-Hans';
  
  /**
   * 构造函数
   * @param locale 区域ID
   */
  constructor(locale?: string) {
    if (locale) {
      this.locale = locale;
    } else {
      // 使用系统locale
      const systemLocale: Intl.Locale = i18n.System.getSystemLocaleInstance();
      this.locale = systemLocale.toString();
    }
  }
  
  /**
   * 添加偏好时区
   * @param timezoneId 时区ID
   */
  addPreferredTimezone(timezoneId: string): boolean {
    try {
      // 验证时区ID是否有效
      const timezone: i18n.TimeZone = i18n.getTimeZone(timezoneId);
      const id: string = timezone.getID();
      
      // 避免重复添加
      if (this.preferredTimezones.includes(id)) {
        console.warn(`时区 ${id} 已在列表中`);
        return false;
      }
      
      this.preferredTimezones.push(id);
      console.info(`成功添加时区 ${id}`);
      return true;
    } catch (error) {
      console.error(`添加时区失败: ${error}`);
      return false;
    }
  }
  
  /**
   * 移除偏好时区
   * @param timezoneId 时区ID
   */
  removePreferredTimezone(timezoneId: string): boolean {
    const index: number = this.preferredTimezones.indexOf(timezoneId);
    if (index !== -1) {
      this.preferredTimezones.splice(index, 1);
      console.info(`成功移除时区 ${timezoneId}`);
      return true;
    }
    console.warn(`时区 ${timezoneId} 不在列表中`);
    return false;
  }
  
  /**
   * 获取所有偏好时区
   */
  getPreferredTimezones(): Array<string> {
    return this.preferredTimezones.slice();
  }
  
  /**
   * 清空偏好时区列表
   */
  clearPreferredTimezones(): void {
    this.preferredTimezones = [];
    console.info('已清空偏好时区列表');
  }
  
  /**
   * 获取时钟显示数据
   */
  getClockDisplayData(): Array<ClockItem> {
    const clockItems: Array<ClockItem> = [];
    
    for (let i = 0; i < this.preferredTimezones.length; i++) {
      const timezoneId: string = this.preferredTimezones[i];
      const clockItem: ClockItem = this.createClockItem(timezoneId);
      clockItems.push(clockItem);
    }
    
    return clockItems;
  }
  
  /**
   * 创建时钟项
   * @param timezoneId 时区ID
   */
  private createClockItem(timezoneId: string): ClockItem {
    try {
      const timezone: i18n.TimeZone = i18n.getTimeZone(timezoneId);
      
      // 获取时区信息
      const timezoneName: string = timezone.getDisplayName(this.locale, false);
      const rawOffset: number = timezone.getRawOffset();
      const currentOffset: number = timezone.getOffset(new Date().getTime());
      const offsetHours: number = currentOffset / 3600000;
      const isDST: boolean = currentOffset !== rawOffset;
      
      // 获取当前时间
      const calendar: i18n.Calendar = i18n.getCalendar(this.locale);
      calendar.setTimeZone(timezoneId);
      
      const year: number = calendar.get('year');
      const month: number = calendar.get('month') + 1;
      const day: number = calendar.get('date');
      const hour: number = calendar.get('hour');
      const minute: number = calendar.get('minute');
      const second: number = calendar.get('second');
      
      const currentTime: string = `${year}-${month}-${day} ${hour}:${minute}:${second}`;
      
      // 尝试获取城市名称
      let cityDisplayName: string = timezoneId.split('/')[1] || timezoneId;
      try {
        const cityIDs: Array<string> = i18n.TimeZone.getAvailableZoneCityIDs();
        // 尝试匹配城市ID（简化逻辑）
        for (let i = 0; i < cityIDs.length; i++) {
          const cityId: string = cityIDs[i];
          const tz: i18n.TimeZone = i18n.TimeZone.getTimezoneFromCity(cityId);
          if (tz.getID() === timezoneId) {
            cityDisplayName = i18n.TimeZone.getCityDisplayName(cityId, this.locale);
            break;
          }
        }
      } catch (e) {
        // 如果找不到城市名称，使用时区ID
      }
      
      return {
        timezoneId: timezoneId,
        timezoneName: timezoneName,
        cityDisplayName: cityDisplayName,
        currentTime: currentTime,
        offsetHours: offsetHours,
        isDST: isDST
      };
    } catch (error) {
      console.error(`创建时钟项失败: ${error}`);
      return {
        timezoneId: timezoneId,
        timezoneName: '未知',
        cityDisplayName: '未知',
        currentTime: '未知',
        offsetHours: 0,
        isDST: false
      };
    }
  }
}

/**
 * 时区选择器
 */
class TimezoneSelector {
  private locale: string = 'zh-Hans';
  
  /**
   * 构造函数
   * @param locale 区域ID
   */
  constructor(locale?: string) {
    if (locale) {
      this.locale = locale;
    }
  }
  
  /**
   * 获取可用时区列表（按城市）
   */
  getAvailableTimezonesByCity(): Array<object> {
    try {
      const cityIDs: Array<string> = i18n.TimeZone.getAvailableZoneCityIDs();
      const timezoneList: Array<object> = [];
      
      for (let i = 0; i < cityIDs.length; i++) {
        const cityId: string = cityIDs[i];
        const cityDisplayName: string = i18n.TimeZone.getCityDisplayName(cityId, this.locale);
        const timezone: i18n.TimeZone = i18n.TimeZone.getTimezoneFromCity(cityId);
        const timezoneId: string = timezone.getID();
        const timezoneName: string = timezone.getDisplayName(this.locale, false);
        const offset: number = timezone.getOffset(new Date().getTime());
        const offsetHours: number = offset / 3600000;
        
        timezoneList.push({
          cityId: cityId,
          cityDisplayName: cityDisplayName,
          timezoneId: timezoneId,
          timezoneName: timezoneName,
          offsetHours: offsetHours,
          offsetStr: `GMT${offsetHours >= 0 ? '+' : ''}${offsetHours}`
        });
      }
      
      return timezoneList;
    } catch (error) {
      console.error(`获取时区列表失败: ${error}`);
      return [];
    }
  }
  
  /**
   * 搜索时区（按城市名）
   * @param searchText 搜索文本
   */
  searchTimezone(searchText: string): Array<object> {
    const allTimezones: Array<object> = this.getAvailableTimezonesByCity();
    
    if (!searchText || searchText.trim() === '') {
      return allTimezones;
    }
    
    const filtered: Array<object> = [];
    const keyword: string = searchText.toLowerCase();
    
    for (let i = 0; i < allTimezones.length; i++) {
      const item = allTimezones[i] as {
        cityDisplayName?: string;
        timezoneId?: string;
      };
      
      const cityName: string = (item.cityDisplayName || '').toLowerCase();
      const tzId: string = (item.timezoneId || '').toLowerCase();
      
      if (cityName.includes(keyword) || tzId.includes(keyword)) {
        filtered.push(item);
      }
    }
    
    return filtered;
  }
  
  /**
   * 根经纬度获取推荐时区
   * @param longitude 经度
   * @param latitude 纬度
   */
  getTimezoneByLocation(longitude: number, latitude: number): Array<object> {
    try {
      const timezoneArray: Array<i18n.TimeZone> = i18n.TimeZone.getTimezonesByLocation(longitude, latitude);
      const result: Array<object> = [];
      
      for (let i = 0; i < timezoneArray.length; i++) {
        const timezone: i18n.TimeZone = timezoneArray[i];
        const timezoneId: string = timezone.getID();
        const timezoneName: string = timezone.getDisplayName(this.locale, false);
        const offset: number = timezone.getOffset(new Date().getTime());
        const offsetHours: number = offset / 3600000;
        
        result.push({
          timezoneId: timezoneId,
          timezoneName: timezoneName,
          offsetHours: offsetHours,
          offsetStr: `GMT${offsetHours >= 0 ? '+' : ''}${offsetHours}`
        });
      }
      
      return result;
    } catch (error) {
      console.error(`根据坐标获取时区失败: ${error}`);
      return [];
    }
  }
}

/**
 * 双时钟应用主类
 */
class MultiClockApp {
  private timezoneManager: TimezoneManager;
  private timezoneSelector: TimezoneSelector;
  
  /**
   * 构造函数
   */
  constructor() {
    this.timezoneManager = new TimezoneManager();
    this.timezoneSelector = new TimezoneSelector();
  }
  
  /**
   * 初始化应用
   */
  initialize(): void {
    // 添加默认时区
    this.timezoneManager.addPreferredTimezone('Asia/Shanghai');
    this.timezoneManager.addPreferredTimezone('America/New_York');
    this.timezoneManager.addPreferredTimezone('Europe/London');
    
    console.info('双时钟应用初始化完成');
  }
  
  /**
   * 显示时钟
   */
  displayClocks(): void {
    const clockItems: Array<ClockItem> = this.timezoneManager.getClockDisplayData();
    
    console.info('\n=== 多时区时钟 ===');
    for (let i = 0; i < clockItems.length; i++) {
      const item: ClockItem = clockItems[i];
      console.info(`${item.cityDisplayName} (${item.timezoneName})`);
      console.info(`  时间: ${item.currentTime}`);
      console.info(`  偏移量: GMT${item.offsetHours >= 0 ? '+' : ''}${item.offsetHours}`);
      if (item.isDST) {
        console.info(`  当前处于夏令时`);
      }
    }
    console.info('==================\n');
  }
  
  /**
   * 添加新时区
   * @param timezoneId 时区ID
   */
  addTimezone(timezoneId: string): void {
    const success: boolean = this.timezoneManager.addPreferredTimezone(timezoneId);
    if (success) {
      console.info(`成功添加时区 ${timezoneId}`);
      this.displayClocks();
    } else {
      console.error(`添加时区 ${timezoneId} 失败`);
    }
  }
  
  /**
   * 移除时区
   * @param timezoneId 时区ID
   */
  removeTimezone(timezoneId: string): void {
    const success: boolean = this.timezoneManager.removePreferredTimezone(timezoneId);
    if (success) {
      console.info(`成功移除时区 ${timezoneId}`);
      this.displayClocks();
    } else {
      console.warn(`移除时区 ${timezoneId} 失败`);
    }
  }
  
  /**
   * 显示时区选择器
   */
  showTimezoneSelector(): void {
    const timezones: Array<object> = this.timezoneSelector.getAvailableTimezonesByCity();
    console.info('\n=== 时区选择器 ===');
    console.info(`可用时区数量: ${timezones.length}`);
    console.info('\n前10个时区:');
    for (let i = 0; i < Math.min(10, timezones.length); i++) {
      const item = timezones[i] as {
        cityDisplayName?: string;
        timezoneId?: string;
        offsetStr?: string;
      };
      console.info(`${i + 1}. ${item.cityDisplayName} [${item.timezoneId}] (${item.offsetStr})`);
    }
    console.info('==================\n');
  }
  
  /**
   * 搜索时区
   * @param keyword 搜索关键词
   */
  searchTimezone(keyword: string): void {
    const results: Array<object> = this.timezoneSelector.searchTimezone(keyword);
    console.info(`\n搜索 "${keyword}" 结果: ${results.length}个`);
    for (let i = 0; i < results.length; i++) {
      const item = results[i] as {
        cityDisplayName?: string;
        timezoneId?: string;
        offsetStr?: string;
      };
      console.info(`${i + 1}. ${item.cityDisplayName} [${item.timezoneId}] (${item.offsetStr})`);
    }
  }
}

/**
 * 主函数
 */
function main(): void {
  console.info('=== 双时钟应用示例 ===');
  
  // 创建应用实例
  const app = new MultiClockApp();
  
  // 初始化
  app.initialize();
  
  // 显示时钟
  app.displayClocks();
  
  // 添加新时区
  console.info('\n--- 添加东京时区 ---');
  app.addTimezone('Asia/Tokyo');
  
  // 移除时区
  console.info('\n--- 移除伦敦时区 ---');
  app.removeTimezone('Europe/London');
  
  // 显示时区选择器
  app.showTimezoneSelector();
  
  // 搜索时区
  console.info('\n--- 搜索时区 ---');
  app.searchTimezone('上海');
  app.searchTimezone('Tokyo');
  
  console.info('\n=== 示例执行完成 ===');
}

// 执行主函数
main();