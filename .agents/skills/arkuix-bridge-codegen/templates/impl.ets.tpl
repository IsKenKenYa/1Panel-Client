// {{name}}Impl.ets — 六件套⑥：平台分发器（一码三平台——业务码零平台感知）
// Android/iOS → ③{{name}}ArkUIX（桥接）；HarmonyOS/OpenHarmony → ②{{name}}Local（直调 @ohos.*）。
// 用法：业务调用点 `{{name}}Impl.getInterface().{{primaryMethod}}(...)` 替换原 @ohos.* 直调。
import { PlatformInfo, PlatformTypeEnum } from '../../utils/PlatformInfo';
import { {{interfaceName}} } from '../interface/{{interfaceName}}';
import { {{name}}ArkUIX } from '../utils/{{name}}ArkUIX';
import { {{name}}Local } from '../utils/{{name}}Local';

export class {{name}}Impl {
  public static getInterface(): {{interfaceName}} {
    const platform = PlatformInfo.getPlatform();
    if (platform === PlatformTypeEnum.ANDROID || platform === PlatformTypeEnum.IOS) {
      return {{name}}ArkUIX.getInstance();
    }
    return {{name}}Local.getInstance();
  }
}
