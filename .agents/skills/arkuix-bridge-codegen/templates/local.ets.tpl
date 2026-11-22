// {{name}}Local.ets — 六件套②：HarmonyOS 端实现（直调 @ohos.*，一码三平台之 OH 分支）
// 由 arkuix-bridge-codegen 生成（对齐 ArkUI-X docs《跨平台Bridge最佳实践》CameraLocal 范式）；
// 方法体为源工程调用实现的迁移（原语句平铺保留，参数/返回值接线待补——见方法内 TODO）；
// 增量再生成时本文件已存在则保留开发者版本不覆盖（如需重新迁移请先删除本文件）。
import Bridge from '@arkui-x.bridge';
import { {{interfaceName}} } from '../interface/{{interfaceName}}';
{{localImports}}

export class {{name}}Local implements {{interfaceName}} {
  private static instance: {{name}}Local;

  public static getInstance(): {{name}}Local {
    if (!{{name}}Local.instance) {
      {{name}}Local.instance = new {{name}}Local();
    }
    return {{name}}Local.instance;
  }

{{methodBodies}}
}
