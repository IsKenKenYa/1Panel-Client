import batteryInfo from '@ohos.batteryInfo';

export function batteryPercent(): number {
  // ③等价桥接（已映射，第二文件）
  return batteryInfo.batterySOC;
}
