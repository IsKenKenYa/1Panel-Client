// {{name}}ArkUIX.ets — 六件套③：ArkUI-X 桥接实现（@arkui-x.bridge → 原生侧，Android/iOS 分支）
// 基于ArkUI-X SDK @arkui-x.bridge.d.ts（createBridge + callMethod）；对齐 docs CameraArkUIX 范式。
import Bridge from '@arkui-x.bridge';
import { {{interfaceName}} } from '../interface/{{interfaceName}}';

export class {{name}}ArkUIX implements {{interfaceName}} {
  private static instance: {{name}}ArkUIX;
  private static bridgeImpl: Bridge.BridgeObject;

  public static getInstance(): {{name}}ArkUIX {
    if (!{{name}}ArkUIX.instance) {
      {{name}}ArkUIX.instance = new {{name}}ArkUIX();
      {{name}}ArkUIX.bridgeImpl = Bridge.createBridge('{{bridgeName}}');
    }
    return {{name}}ArkUIX.instance;
  }

{{methodForwards}}
}
