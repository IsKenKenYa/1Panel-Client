import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 公历日历操作示例
 * 展示如何创建公历日历、设置日期时间、配置时区和周起始日
 */

export class GregoryCalendarExample {
  private calendar: i18n.Calendar | null = null;

  /**
   * 创建公历日历对象
   */
  createGregoryCalendar(): void {
    try {
      // 创建简体中文区域、公历类型的日历
      this.calendar = i18n.getCalendar('zh-Hans', 'gregory');
      console.log('公历日历对象创建成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`创建日历失败: 错误码 ${err.code}, 消息 ${err.message}`);
    }
  }

  /**
   * 设置日期时间(Date对象)
   */
  setDateByDateObject(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 注意:月份从0开始,0=一月,11=十二月
      const date: Date = new Date(2023, 6, 25, 8, 0, 0);
      this.calendar.setTime(date);
      console.log('使用Date对象设置日期成功: 2023年7月25日 08:00:00');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`设置日期失败: ${err.message}`);
    }
  }

  /**
   * 设置日期时间(时间戳)
   */
  setDateByTimestamp(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // Unix时间戳(毫秒)
      this.calendar.setTime(1690276800000);
      console.log('使用时间戳设置日期成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`设置时间戳失败: ${err.message}`);
    }
  }

  /**
   * 直接设置年月日时分秒
   */
  setDateTimeDirectly(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 参数: year, month(从0开始), date, hour, minute, second
      this.calendar.set(2023, 6, 25, 14, 30, 0);
      console.log('直接设置日期时间: 2023年7月25日 14:30:00');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`设置日期时间失败: ${err.message}`);
    }
  }

  /**
   * 设置和获取时区
   */
  configureTimezone(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置时区
      this.calendar.setTimeZone('Asia/Shanghai');
      console.log('时区设置: Asia/Shanghai');

      // 获取时区
      const timezone: string = this.calendar.getTimeZone();
      console.log(`当前时区: ${timezone}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`时区操作失败: ${err.message}`);
    }
  }

  /**
   * 配置周起始日
   */
  configureFirstDayOfWeek(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 获取当前周起始日
      const currentFirstDay: number = this.calendar.getFirstDayOfWeek();
      console.log(`当前周起始日: ${currentFirstDay} (1=周日, 7=周六)');

      // 设置周起始日为周一
      this.calendar.setFirstDayOfWeek(2);
      console.log('周起始日已设置为周一(2)');

      const newFirstDay: number = this.calendar.getFirstDayOfWeek();
      console.log(`新的周起始日: ${newFirstDay}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`周起始日配置失败: ${err.message}`);
    }
  }

  /**
   * 配置一年中第一周的最小天数
   */
  configureMinimalDaysInFirstWeek(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 获取当前设置
      const currentMinimalDays: number = this.calendar.getMinimalDaysInFirstWeek();
      console.log(`当前第一周最小天数: ${currentMinimalDays}`);

      // 设置为3天(ISO 8601标准)
      this.calendar.setMinimalDaysInFirstWeek(3);
      console.log('第一周最小天数已设置为3');

      const newMinimalDays: number = this.calendar.getMinimalDaysInFirstWeek();
      console.log(`新的第一周最小天数: ${newMinimalDays}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`第一周最小天数配置失败: ${err.message}`);
    }
  }

  /**
   * 获取日历字段值
   */
  getCalendarFields(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置测试日期
      this.calendar.set(2023, 6, 25, 14, 30, 15);

      // 获取各个字段
      const year: number = this.calendar.get('year');
      const month: number = this.calendar.get('month'); // 注意:返回值从0开始
      const date: number = this.calendar.get('date');
      const hour: number = this.calendar.get('hour_of_day');
      const minute: number = this.calendar.get('minute');
      const second: number = this.calendar.get('second');
      const dayOfWeek: number = this.calendar.get('day_of_week');
      const weekOfYear: number = this.calendar.get('week_of_year');

      console.log(`日期: ${year}年${month + 1}月${date}日`);
      console.log(`时间: ${hour}:${minute}:${second}`);
      console.log(`星期: ${dayOfWeek} (1=周日, 7=周六)`);
      console.log(`一年中的第${weekOfYear}周`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取日历字段失败: ${err.message}`);
    }
  }

  /**
   * 获取日历本地化名称
   */
  getCalendarDisplayName(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 获取中文显示名称
      const chineseName: string = this.calendar.getDisplayName('zh-Hans');
      console.log(`历法名称(中文): ${chineseName}`);

      // 获取英文显示名称
      const englishName: string = this.calendar.getDisplayName('en-US');
      console.log(`历法名称(英文): ${englishName}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取历法名称失败: ${err.message}`);
    }
  }

  /**
   * 判断周末
   */
  checkWeekend(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置当前日期
      this.calendar.set(2023, 9, 15, 8, 0, 0); // 2023年10月15日(周日)

      // 判断当前日期是否为周末
      const isCurrentWeekend: boolean = this.calendar.isWeekend();
      console.log(`当前日期是否为周末: ${isCurrentWeekend}`);

      // 判断指定日期是否为周末
      const testDate: Date = new Date(2023, 9, 16, 9, 0, 0); // 2023年10月16日(周一)
      const isTestWeekend: boolean = this.calendar.isWeekend(testDate);
      console.log(`2023年10月16日是否为周末: ${isTestWeekend}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`周末判断失败: ${err.message}`);
    }
  }

  /**
   * 获取时间戳
   */
  getTimestamp(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      const timestamp: number = this.calendar.getTimeInMillis();
      console.log(`当前时间戳(毫秒): ${timestamp}`);
      console.log(`对应日期: ${new Date(timestamp).toLocaleString()}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取时间戳失败: ${err.message}`);
    }
  }

  /**
   * 运行完整示例
   */
  runFullExample(): void {
    console.log('=== 公历日历操作完整示例 ===');
    
    this.createGregoryCalendar();
    this.setDateByDateObject();
    this.configureTimezone();
    this.configureFirstDayOfWeek();
    this.configureMinimalDaysInFirstWeek();
    this.getCalendarFields();
    this.getCalendarDisplayName();
    this.checkWeekend();
    this.getTimestamp();
    
    console.log('=== 示例运行完成 ===');
  }
}

// 使用示例
const example = new GregoryCalendarExample();
example.runFullExample();