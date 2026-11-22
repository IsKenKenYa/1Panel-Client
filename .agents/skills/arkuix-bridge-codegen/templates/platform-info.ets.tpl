// PlatformInfo.ets — 工程级平台判断件（六件套⑥分发器的共用依赖，每工程一份）
// 由 arkuix-bridge-codegen 生成；实现取自 ArkUI-X docs《跨平台Bridge最佳实践》PlatformInfo 原文。
// 已存在时保留开发者版本不覆盖（如需重置请先删除本文件）。
import deviceInfo from '@ohos.deviceInfo';

export enum PlatformTypeEnum {
  HARMONYOS = 'HarmonyOS Platform',
  ANDROID = 'Android Platform',
  IOS = 'iOS Platform',
  UNKNOWN = 'Unknown Platform',
}

export class PlatformInfo {
  static getPlatform(): PlatformTypeEnum {
    let osFullNameInfo: string = deviceInfo.osFullName;
    let platformName: string = osFullNameInfo.split(' ')[0];
    if (platformName.includes("OpenHarmony")) {
      return PlatformTypeEnum.HARMONYOS;
    } else if (platformName.includes("Android")) {
      return PlatformTypeEnum.ANDROID;
    } else if (platformName.includes('iOS')) {
      return PlatformTypeEnum.IOS;
    } else {
      return PlatformTypeEnum.UNKNOWN;
    }
  }
}
