import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 农历日历操作示例
 * 展示如何将公历日期转换为农历日期,获取干支纪年、农历月日
 */

export class ChineseCalendarExample {
  private chineseCalendar: i18n.Calendar | null = null;
  private gregoryCalendar: i18n.Calendar | null = null;

  /**
   * 创建农历日历对象
   */
  createChineseCalendar(): void {
    try {
      // 创建农历日历对象
      this.chineseCalendar = i18n.getCalendar('zh-Hans', 'chinese');
      console.log('农历日历对象创建成功');

      // 创建公历日历对象用于对比
      this.gregoryCalendar = i18n.getCalendar('zh-Hans', 'gregory');
      console.log('公历日历对象创建成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`创建日历失败: ${err.message}`);
    }
  }

  /**
   * 公历转农历 - 基本转换
   */
  convertGregoryToChinese(): void {
    if (!this.chineseCalendar) {
      console.error('农历日历对象未创建');
      return;
    }

    try {
      // 设置公历日期: 2023年7月25日 08:00:00
      // 注意:月份从0开始,7月=6
      const gregoryDate: Date = new Date(2023, 6, 25, 8, 0, 0);
      this.chineseCalendar.setTime(gregoryDate);

      // 获取农历年月日
      const yearChinese: number = this.chineseCalendar.get('year');
      const monthChinese: number = this.chineseCalendar.get('month');
      const dayChinese: number = this.chineseCalendar.get('date');

      console.log('=== 公历转农历 ===');
      console.log(`公历: 2023年7月25日`);
      console.log(`农历: ${yearChinese}年(干支纪年) ${monthChinese + 1}月 ${dayChinese}日`);
      
      // 干支纪年说明
      this.printGanzhiYear(yearChinese);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`公历转农历失败: ${err.message}`);
    }
  }

  /**
   * 打印干支纪年信息
   */
  private printGanzhiYear(yearNumber: number): void {
    // 干支纪年范围1-60
    const ganzhiCycle = [
      '甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉',
      '甲戌', '乙亥', '丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未',
      '甲申', '乙酉', '丙戌', '丁亥', '戊子', '己丑', '庚寅', '辛卯', '壬辰', '癸巳',
      '甲午', '乙未', '丙申', '丁酉', '戊戌', '己亥', '庚子', '辛丑', '壬寅', '癸卯',
      '甲辰', '乙巳', '丙午', '丁未', '戊申', '己酉', '庚戌', '辛亥', '壬子', '癸丑',
      '甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉', '壬戌', '癸亥'
    ];

    const ganzhiName: string = ganzhiCycle[yearNumber - 1];
    console.log(`干支纪年: ${ganzhiName} (第${yearNumber}年,范围1-60)`);
  }

  /**
   * 判断是否为闰月
   */
  checkLeapMonth(): void {
    if (!this.chineseCalendar) {
      console.error('农历日历对象未创建');
      return;
    }

    try {
      // 设置多个日期测试闰月
      const testDates: Date[] = [
        new Date(2023, 6, 25),  // 2023年7月25日
        new Date(2020, 3, 25),  // 2020年4月25日(有闰四月)
        new Date(2017, 5, 25)   // 2017年6月25日(有闰六月)
      ];

      console.log('=== 闰月判断测试 ===');
      
      for (const testDate of testDates) {
        this.chineseCalendar.setTime(testDate);
        const isLeapMonth: number = this.chineseCalendar.get('is_leap_month');
        const monthChinese: number = this.chineseCalendar.get('month');
        
        console.log(`${testDate.getFullYear()}年${testDate.getMonth() + 1}月${testDate.getDate()}日`);
        console.log(`农历${monthChinese + 1}月, 是否闰月: ${isLeapMonth === 1 ? '是' : '否'}`);
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`闰月判断失败: ${err.message}`);
    }
  }

  /**
   * 获取农历日期详细信息
   */
  getChineseDateDetails(): void {
    if (!this.chineseCalendar) {
      console.error('农历日历对象未创建');
      return;
    }

    try {
      // 设置测试日期
      this.chineseCalendar.setTime(new Date(2023, 6, 25, 8, 0, 0));

      console.log('=== 农历日期详细信息 ===');

      // 获取年份相关信息
      const year: number = this.chineseCalendar.get('year');
      const extendedYear: number = this.chineseCalendar.get('extended_year');
      console.log(`干支纪年: ${year}`);
      console.log(`扩展年份: ${extendedYear}`);

      // 获取月日信息
      const month: number = this.chineseCalendar.get('month');
      const date: number = this.chineseCalendar.get('date');
      const isLeapMonth: number = this.chineseCalendar.get('is_leap_month');
      console.log(`农历月份: ${month + 1}月 ${isLeapMonth === 1 ? '(闰月)' : ''}`);
      console.log(`农历日期: ${date}日`);

      // 获取时间信息
      const hour: number = this.chineseCalendar.get('hour_of_day');
      const minute: number = this.chineseCalendar.get('minute');
      const second: number = this.chineseCalendar.get('second');
      console.log(`时辰: ${hour}时${minute}分${second}秒`);

      // 获取其他信息
      const dayOfYear: number = this.chineseCalendar.get('day_of_year');
      const dayOfWeek: number = this.chineseCalendar.get('day_of_week');
      console.log(`一年中的第${dayOfYear}天`);
      console.log(`星期${dayOfWeek} (1=周日)`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取农历详细信息失败: ${err.message}`);
    }
  }

  /**
   * 批量转换示例 - 重要节日
   */
  convertImportantDates(): void {
    if (!this.chineseCalendar) {
      console.error('农历日历对象未创建');
      return;
    }

    try {
      // 重要农历节日对应的公历日期
      const importantDates: { name: string; date: Date }[] = [
        { name: '春节', date: new Date(2023, 0, 22) },  // 2023年1月22日
        { name: '端午节', date: new Date(2023, 5, 22) }, // 2023年6月22日
        { name: '中秋节', date: new Date(2023, 8, 29) }, // 2023年9月29日
        { name: '重阳节', date: new Date(2023, 9, 23) }  // 2023年10月23日
      ];

      console.log('=== 重要节日农历日期 ===');

      for (const festival of importantDates) {
        this.chineseCalendar.setTime(festival.date);
        const month: number = this.chineseCalendar.get('month');
        const date: number = this.chineseCalendar.get('date');
        
        console.log(`${festival.name}: 农历${month + 1}月${date}日`);
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`节日转换失败: ${err.message}`);
    }
  }

  /**
   * 对比公历和农历
   */
  compareGregoryAndChinese(): void {
    if (!this.chineseCalendar || !this.gregoryCalendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置同一日期
      const testDate: Date = new Date(2023, 6, 25, 8, 0, 0);
      this.chineseCalendar.setTime(testDate);
      this.gregoryCalendar.setTime(testDate);

      console.log('=== 公历与农历对比 ===');
      console.log(`公历日期: ${this.gregoryCalendar.get('year')}年${this.gregoryCalendar.get('month') + 1}月${this.gregoryCalendar.get('date')}日`);
      console.log(`农历日期: ${this.chineseCalendar.get('year')}年(干支)${this.chineseCalendar.get('month') + 1}月${this.chineseCalendar.get('date')}日`);

      // 对比时间信息
      console.log(`公历时间: ${this.gregoryCalendar.get('hour_of_day')}:${this.gregoryCalendar.get('minute')}:${this.gregoryCalendar.get('second')}`);
      console.log(`农历时间: ${this.chineseCalendar.get('hour_of_day')}:${this.chineseCalendar.get('minute')}:${this.chineseCalendar.get('second')}`);

      // 对比星期
      console.log(`公历星期: ${this.gregoryCalendar.get('day_of_week')}`);
      console.log(`农历星期: ${this.chineseCalendar.get('day_of_week')}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`对比失败: ${err.message}`);
    }
  }

  /**
   * 获取农历本地化名称
   */
  getChineseCalendarDisplayName(): void {
    if (!this.chineseCalendar) {
      console.error('农历日历对象未创建');
      return;
    }

    try {
      const chineseName: string = this.chineseCalendar.getDisplayName('zh-Hans');
      const englishName: string = this.chineseCalendar.getDisplayName('en-US');
      
      console.log(`农历名称(中文): ${chineseName}`);
      console.log(`农历名称(英文): ${englishName}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取名称失败: ${err.message}`);
    }
  }

  /**
   * 运行完整示例
   */
  runFullExample(): void {
    console.log('=== 农历日历操作完整示例 ===');
    
    this.createChineseCalendar();
    this.convertGregoryToChinese();
    this.checkLeapMonth();
    this.getChineseDateDetails();
    this.convertImportantDates();
    this.compareGregoryAndChinese();
    this.getChineseCalendarDisplayName();
    
    console.log('=== 示例运行完成 ===');
  }
}

// 使用示例
const example = new ChineseCalendarExample();
example.runFullExample();