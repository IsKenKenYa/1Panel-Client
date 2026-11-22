import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function formatDateWithIntl(): Promise<void> {
  try {
    const locale = i18n.System.getSystemLocaleInstance();
    const localeId = locale.toString();
    
    const now = new Date();
    
    const dateTimeFormat = new Intl.DateTimeFormat(localeId);
    const formattedDate = dateTimeFormat.format(now);
    console.info(`Formatted date (default): ${formattedDate}`);
    
    const fullFormatter = new Intl.DateTimeFormat(localeId, { dateStyle: 'full', timeStyle: 'medium' });
    const fullFormattedDate = fullFormatter.format(now);
    console.info(`Formatted date (full): ${fullFormattedDate}`);
    
    const shortFormatter = new Intl.DateTimeFormat(localeId, { dateStyle: 'short', timeStyle: 'short' });
    const shortFormattedDate = shortFormatter.format(now);
    console.info(`Formatted date (short): ${shortFormattedDate}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to format date with Intl, error code: ${err.code}, message: ${err.message}`);
  }
}

async function formatDateWithSkeleton(): Promise<void> {
  try {
    const locale = i18n.System.getSystemLocaleInstance();
    
    const now = new Date();
    
    const yMdFormatter = i18n.getSimpleDateTimeFormatBySkeleton('yMd', locale);
    const yMdFormattedDate = yMdFormatter.format(now);
    console.info(`Formatted date (yMd): ${yMdFormattedDate}`);
    
    const yMMMdFormatter = i18n.getSimpleDateTimeFormatBySkeleton('yMMMd', locale);
    const yMMMdFormattedDate = yMMMdFormatter.format(now);
    console.info(`Formatted date (yMMMd): ${yMMMdFormattedDate}`);
    
    const EMMMdFormatter = i18n.getSimpleDateTimeFormatBySkeleton('EMMMd', locale);
    const EMMMdFormattedDate = EMMMdFormatter.format(now);
    console.info(`Formatted date (EMMMd): ${EMMMdFormattedDate}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to format date with skeleton, error code: ${err.code}, message: ${err.message}`);
  }
}

async function formatNumberWithIntl(): Promise<void> {
  try {
    const locale = i18n.System.getSystemLocaleInstance();
    const localeId = locale.toString();
    
    const numberFormat = new Intl.NumberFormat(localeId);
    const formattedNumber = numberFormat.format(1234567.89);
    console.info(`Formatted number: ${formattedNumber}`);
    
    const currencyFormatter = new Intl.NumberFormat(localeId, { style: 'currency', currency: 'CNY' });
    const formattedCurrency = currencyFormatter.format(1234567.89);
    console.info(`Formatted currency: ${formattedCurrency}`);
    
    const percentFormatter = new Intl.NumberFormat(localeId, { style: 'percent' });
    const formattedPercent = percentFormatter.format(0.1234);
    console.info(`Formatted percent: ${formattedPercent}`);
    
    const scientificFormatter = new Intl.NumberFormat(localeId, { notation: 'scientific' });
    const formattedScientific = scientificFormatter.format(1234567.89);
    console.info(`Formatted scientific: ${formattedScientific}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to format number with Intl, error code: ${err.code}, message: ${err.message}`);
  }
}

async function formatDateRange(): Promise<void> {
  try {
    const locale = i18n.System.getSystemLocaleInstance();
    const localeId = locale.toString();
    
    const startDate = new Date(2021, 11, 17, 3, 24, 0);
    const endDate = new Date(2021, 11, 18, 3, 24, 0);
    
    const formatter = new Intl.DateTimeFormat(localeId);
    const formattedRange = formatter.formatRange(startDate, endDate);
    console.info(`Formatted date range: ${formattedRange}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to format date range, error code: ${err.code}, message: ${err.message}`);
  }
}

export { formatDateWithIntl, formatDateWithSkeleton, formatNumberWithIntl, formatDateRange };