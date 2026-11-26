import { ComponentContent, UIContext } from '@kit.ArkUI';
import { HarmonyNativeBridge } from './HarmonyNativeBridge';

/** 分栏右侧占位页的展示参数。 */
class HarmonySplitPlaceholderArgs {
  icon: Resource;
  hintKey: string;

  constructor(icon: Resource, hintKey: string) {
    this.icon = icon;
    this.hintKey = hintKey;
  }
}

@Component
struct HarmonySplitPlaceholderView {
  @StorageLink('harmonyNativeRefresh') private presentationRevision: number = 0;
  args: HarmonySplitPlaceholderArgs =
    new HarmonySplitPlaceholderArgs($r('sys.symbol.list_bullet'), 'commonSplitPlaceholderHint');

  build() {
    Column({ space: 12 }) {
      SymbolGlyph(this.args.icon)
        .fontSize(48)
        .fontColor([$r('sys.color.icon_tertiary')])
      Text(HarmonyNativeBridge.instance.text(this.args.hintKey))
        .fontSize(16)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
function harmonySplitPlaceholderBuilder(args: HarmonySplitPlaceholderArgs) {
  HarmonySplitPlaceholderView({ args: args })
}

/**
 * 分栏右侧的默认占位页。
 *
 * 官方 splitPlaceholder 要求传入 ComponentContent，占位页只做界面展示。
 * 每个分栏页持有自己的实例，在 build 阶段按当前 UIContext 创建节点。
 */
export class HarmonySplitPlaceholderContent {
  private readonly icon: Resource;
  private node: ComponentContent<HarmonySplitPlaceholderArgs> | null = null;

  constructor(icon: Resource) {
    this.icon = icon;
  }

  content(context: UIContext): ComponentContent<HarmonySplitPlaceholderArgs> {
    if (this.node === null) {
      this.node = new ComponentContent<HarmonySplitPlaceholderArgs>(
        context, wrapBuilder(harmonySplitPlaceholderBuilder),
        new HarmonySplitPlaceholderArgs(this.icon, 'commonSplitPlaceholderHint'),
      );
    }
    return this.node;
  }
}
