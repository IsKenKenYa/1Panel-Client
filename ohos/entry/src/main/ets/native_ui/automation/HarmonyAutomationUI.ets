import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

export const automationMoreSymbol: Resource = $r('sys.symbol.more');
export const automationEditSymbol: Resource = $r('sys.symbol.square_and_pencil');
export const automationCopySymbol: Resource = $r('sys.symbol.doc');
export const automationScriptSymbol: Resource = $r('sys.symbol.doc');

@Component
export struct HarmonyAutomationTitle {
  @Prop label: string = '';
  @Prop showBack: boolean = true;
  /** 分栏时降为小标题字号，避免在窄栏内与图标争位。 */
  @Prop compact: boolean = false;
  onBack: () => void = (): void => {};

  build() {
    Row({ space: 8 }) {
      if (this.showBack) {
        Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .accessibilityText(automationText('commonBack')).onClick(this.onBack)
      }
      Text(this.label).fontSize(this.compact ? 16 : 20).fontWeight(FontWeight.Medium)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
    }.width('100%').height('100%').alignItems(VerticalAlign.Center)
  }
}

export function automationText(key: string): string {
  return HarmonyNativeBridge.instance.text(key);
}

export function automationString(record: Map<string, Object | null>, key: string): string {
  const content = record.get(key);
  return content === null || content === undefined ? '' : `${content}`;
}

export async function automationWrite(method: string, args?: Map<string, Object | null>): Promise<void> {
  const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null> | null>(method, args);
  if (result !== null && result.get('success') === false && result.get('cancelled') !== true) {
    throw new Error(automationString(result, 'error'));
  }
}
