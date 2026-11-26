import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

export function hostText(key: string): string {
  return HarmonyNativeBridge.instance.text(key);
}

export function hostString(record: Map<string, Object | null>, key: string): string {
  const value = record.get(key);
  if (value === null || value === undefined) {
    return '—';
  }
  return `${value}`;
}

@Component
export struct HarmonyHostValueRow {
  @Prop label: string = '';
  @Prop content: string = '';

  build() {
    Row({ space: 12 }) {
      Text(this.label)
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .layoutWeight(1)
      Text(this.content)
        .fontSize(16)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.End)
        .layoutWeight(1)
        .copyOption(CopyOptions.InApp)
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}

@Component
export struct HarmonyHostLinkRow {
  @Prop label: string = '';
  @Prop detail: string = '';
  @Prop symbol: Resource = $r('sys.symbol.externaldrive');
  onOpen: () => void = (): void => {};

  build() {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        SymbolGlyph(this.symbol)
          .fontSize(24)
          .fontColor([$r('sys.color.icon_primary')])
        Column({ space: 2 }) {
          Text(this.label)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
          if (this.detail.length > 0) {
            Text(this.detail)
              .fontSize(14)
              .fontColor($r('sys.color.font_secondary'))
              .maxLines(2)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([$r('sys.color.icon_secondary')])
      }
      .width('100%')
      .constraintSize({ minHeight: 64 })
      .padding(16)
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .buttonStyle(ButtonStyleMode.TEXTUAL)
    .accessibilityText(this.label)
    .onClick(this.onOpen)
  }
}

@Component
export struct HarmonyHostFailure {
  @Prop message: string = '';
  onRetry: () => void = (): void => {};

  build() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
        .fontSize(40)
        .fontColor([$r('sys.color.icon_secondary')])
      Text(this.message)
        .fontSize(16)
        .fontColor($r('sys.color.font_primary'))
        .copyOption(CopyOptions.InApp)
      Button(hostText('commonRetry'))
        .height(48)
        .onClick(this.onRetry)
    }
    .width('100%')
    .padding(24)
  }
}
