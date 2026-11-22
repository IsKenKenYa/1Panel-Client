import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 日历日期计算示例
 * 展示如何在日历上进行日期加减运算、相差天数计算等操作
 */

export class CalendarCalculationExample {
  private calendar: i18n.Calendar | null = null;

  /**
   * 创建日历对象
   */
  createCalendar(): void {
    try {
      this.calendar = i18n.getCalendar('zh-Hans', 'gregory');
      console.log('日历对象创建成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`创建日历失败: ${err.message}`);
    }
  }

  /**
   * 日期加减运算 - 年份
   */
  addYears(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置初始日期
      this.calendar.set(2023, 6, 25, 8, 0, 0);
      console.log('=== 年份加减运算 ===');
      console.log(`初始日期: ${this.calendar.get('year')}年${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);

      // 增加8年
      this.calendar.add('year', 8);
      const after8Years: number = this.calendar.get('year');
      console.log(`增加8年后: ${after8Years}年`);

      // 减少5年
      this.calendar.add('year', -5);
      const afterMinus5Years: number = this.calendar.get('year');
      console.log(`再减少5年后: ${afterMinus5Years}年`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`年份加减失败: ${err.message}`);
    }
  }

  /**
   * 日期加减运算 - 月份
   */
  addMonths(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置初始日期
      this.calendar.set(2023, 0, 15, 8, 0, 0); // 2023年1月15日
      console.log('=== 月份加减运算 ===');
      console.log(`初始日期: ${this.calendar.get('year')}年${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);

      // 增加13个月
      this.calendar.add('month', 13);
      const yearAfter: number = this.calendar.get('year');
      const monthAfter: number = this.calendar.get('month');
      const dateAfter: number = this.calendar.get('date');
      console.log(`增加13个月后: ${yearAfter}年${monthAfter + 1}月${dateAfter}日`);

      // 减少2个月
      this.calendar.add('month', -2);
      const yearFinal: number = this.calendar.get('year');
      const monthFinal: number = this.calendar.get('month');
      console.log(`再减少2个月后: ${yearFinal}年${monthFinal + 1}月`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`月份加减失败: ${err.message}`);
    }
  }

  /**
   * 日期加减运算 - 天数
   */
  addDays(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置初始日期
      this.calendar.set(2023, 10, 15, 8, 0, 0); // 2023年11月15日
      console.log('=== 天数加减运算 ===');
      console.log(`初始日期: ${this.calendar.get('year')}年${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);

      // 增加2天
      this.calendar.add('date', 2);
      const dayAfter2: number = this.calendar.get('date');
      console.log(`增加2天后: ${this.calendar.get('month') + 1}月${dayAfter2}日`);

      // 减少10天
      this.calendar.add('date', -10);
      const dayAfterMinus10: number = this.calendar.get('date');
      const monthAfterMinus10: number = this.calendar.get('month');
      console.log(`减少10天后: ${monthAfterMinus10 + 1}月${dayAfterMinus10}日`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`天数加减失败: ${err.message}`);
    }
  }

  /**
   * 日期加减运算 - 周
   */
  addWeeks(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置初始日期
      this.calendar.set(2023, 6, 25, 8, 0, 0); // 2023年7月25日
      const weekBefore: number = this.calendar.get('week_of_year');
      
      console.log('=== 周数加减运算 ===');
      console.log(`初始日期: ${this.calendar.get('year')}年${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);
      console.log(`初始周数: 第${weekBefore}周`);

      // 增加2周
      this.calendar.add('week_of_year', 2);
      const weekAfter2: number = this.calendar.get('week_of_year');
      console.log(`增加2周后: 第${weekAfter2}周`);
      console.log(`新日期: ${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`周数加减失败: ${err.message}`);
    }
  }

  /**
   * 日期加减运算 - 小时
   */
  addHours(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置初始时间
      this.calendar.set(2023, 6, 25, 14, 30, 0);
      console.log('=== 小时加减运算 ===');
      console.log(`初始时间: ${this.calendar.get('hour_of_day')}:${this.calendar.get('minute')}`);

      // 增加10小时
      this.calendar.add('hour_of_day', 10);
      const hourAfter10: number = this.calendar.get('hour_of_day');
      const dayAfter10: number = this.calendar.get('date');
      console.log(`增加10小时后: ${hourAfter10}时(${this.calendar.get('month') + 1}月${dayAfter10}日)`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`小时加减失败: ${err.message}`);
    }
  }

  /**
   * 比较相差天数
   */
  compareDaysDifference(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置基准日期
      this.calendar.set(2023, 10, 15, 8, 0, 0); // 2023年11月15日
      console.log('=== 相差天数计算 ===');
      console.log(`基准日期: ${this.calendar.get('year')}年${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);

      // 测试不同日期
      const testDates: Date[] = [
        new Date(2023, 10, 18),  // 11月18日(3天后)
        new Date(2023, 10, 10),  // 11月10日(5天前)
        new Date(2023, 11, 15),  // 12月15日(30天后)
        new Date(2023, 10, 15, 12, 0, 0) // 同一天中午(不足1天)
      ];

      for (const testDate of testDates) {
        const diffDays: number = this.calendar.compareDays(testDate);
        const direction: string = diffDays > 0 ? '后' : diffDays < 0 ? '前' : '同一';
        console.log(`${testDate.getMonth() + 1}月${testDate.getDate()}日: 相差${Math.abs(diffDays)}天${direction}`);
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`相差天数计算失败: ${err.message}`);
    }
  }

  /**
   * 复合日期计算示例
   */
  complexCalculation(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置初始日期: 2023年1月31日
      this.calendar.set(2023, 0, 31, 8, 0, 0);
      console.log('=== 复合日期计算示例 ===');
      console.log(`初始日期: ${this.calendar.get('year')}年${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);

      // 增加1个月(自动处理月末)
      this.calendar.add('month', 1);
      const after1Month: number = this.calendar.get('month');
      const dateAfter1Month: number = this.calendar.get('date');
      console.log(`增加1个月后: ${after1Month + 1}月${dateAfter1Month}日`);

      // 增加1年零2个月
      this.calendar.add('year', 1);
      this.calendar.add('month', 2);
      const yearFinal: number = this.calendar.get('year');
      const monthFinal: number = this.calendar.get('month');
      const dateFinal: number = this.calendar.get('date');
      console.log(`再增加1年2个月后: ${yearFinal}年${monthFinal + 1}月${dateFinal}日`);

      // 计算与初始日期相差天数
      const initialDate: Date = new Date(2023, 0, 31, 8, 0, 0);
      const totalDiff: number = this.calendar.compareDays(initialDate);
      console.log(`与初始日期相差: ${Math.abs(totalDiff)}天`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`复合计算失败: ${err.message}`);
    }
  }

  /**
   * 获取时间戳和转换
   */
  timestampOperations(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      // 设置日期
      this.calendar.set(2023, 6, 25, 8, 0, 0);
      console.log('=== 时间戳操作示例 ===');

      // 获取时间戳
      const timestamp: number = this.calendar.getTimeInMillis();
      console.log(`当前时间戳: ${timestamp}`);
      console.log(`对应日期: ${new Date(timestamp).toLocaleString()}`);

      // 使用时间戳创建新日历
      this.calendar.setTime(timestamp + 86400000); // 增加1天(24小时*60分*60秒*1000毫秒)
      console.log(`增加1天后的日期: ${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`时间戳操作失败: ${err.message}`);
    }
  }

  /**
   * 闰年和特殊月份处理
   */
  specialCases(): void {
    if (!this.calendar) {
      console.error('日历对象未创建');
      return;
    }

    try {
      console.log('=== 特殊情况处理 ===');

      // 测试闰年2月
      this.calendar.set(2024, 1, 28, 8, 0, 0); // 2024年2月28日(闰年)
      console.log(`闰年2月28日: ${this.calendar.get('month') + 1}月${this.calendar.get('date')}日`);
      
      this.calendar.add('date', 1);
      console.log(`增加1天: ${this.calendar.get('month') + 1}月${this.calendar.get('date')}日(2月29日)`);

      // 测试平年2月
      this.calendar.set(2023, 1, 28, 8, 0, 0); // 2023年2月28日(平年)
      this.calendar.add('date', 1);
      console.log(`平年2月28日增加1天: ${this.calendar.get('month') + 1}月${this.calendar.get('date')}日(进入3月)`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`特殊情况处理失败: ${err.message}`);
    }
  }

  /**
   * 运行完整示例
   */
  runFullExample(): void {
    console.log('=== 日历日期计算完整示例 ===');
    
    this.createCalendar();
    this.addYears();
    this.addMonths();
    this.addDays();
    this.addWeeks();
    this.addHours();
    this.compareDaysDifference();
    this.complexCalculation();
    this.timestampOperations();
    this.specialCases();
    
    console.log('=== 示例运行完成 ===');
  }
}

// 使用示例
const example = new CalendarCalculationExample();
example.runFullExample();