import deviceInfo from '@ohos.deviceInfo';
import vibrator from '@ohos.vibrator';
import nonsense from '@ohos.nonsense';
import geo from '@ohos.geolocation';

export function deviceFingerprint(): string {
  // 迁移目标①：等价桥接（已映射）
  const udid: string = deviceInfo.udid;
  return udid;
}

export function callMystery(): void {
  // 迁移目标②：等价桥接（映射未收录，unmapped）
  nonsense.mysteryApi('arg0');
}

export function vibrate(): void {
  // 迁移目标③：降级桥接
  vibrator.startVibration({
    type: 'time',
    count: 1,
    effect: 'haptic.clock.timer'
  });
}

export function locate(): void {
  // 多实参提取口径覆盖
  geo.getCurrentLocation('high', (err, loc) => {
    console.log(loc.latitude);
  });
}

export function fingerprintAgain(): string {
  // 同接口二次引用（聚合：单套五件套）
  return deviceInfo.udid;
}
