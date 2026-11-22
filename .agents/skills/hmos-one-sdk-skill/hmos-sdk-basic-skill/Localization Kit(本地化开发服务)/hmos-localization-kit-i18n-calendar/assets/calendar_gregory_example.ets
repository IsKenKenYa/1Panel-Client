import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function gregoryCalendarExample(): void {
  try {
    let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
    calendar.setTime(new Date(2022, 5, 13, 8, 0, 0));
    calendar.setTime(10540800000);
    calendar.set(2022, 5, 13, 8, 0, 0);
    calendar.setTimeZone('Asia/Shanghai');
    let timezone = calendar.getTimeZone();
    console.log(`timezone = ${timezone}`);
    let firstDayOfWeek = calendar.getFirstDayOfWeek();
    console.log(`firstDayOfWeek = ${firstDayOfWeek}`);
    calendar.setFirstDayOfWeek(1);
    let minimalDaysInFirstWeek = calendar.getMinimalDaysInFirstWeek();
    console.log(`minimalDaysInFirstWeek = ${minimalDaysInFirstWeek}`);
    calendar.setMinimalDaysInFirstWeek(3);
    let year = calendar.get('year');
    console.log(`year = ${year}`);
    let calendarName = calendar.getDisplayName('zh-Hans');
    console.log(`calendarName = ${calendarName}`);
    let isWeekend = calendar.isWeekend(new Date(2023, 9, 15));
    console.log(`isWeekend = ${isWeekend}`);
    calendar.set(2023, 10, 15);
    calendar.add('date', 2);
    let day = calendar.get('date');
    console.log(`day = ${day}`);
    let daysDifference = calendar.compareDays(new Date(2023, 10, 15));
    console.log(`daysDifference = ${daysDifference}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Error: code=${err.code}, message=${err.message}`);
  }
}

export { gregoryCalendarExample };