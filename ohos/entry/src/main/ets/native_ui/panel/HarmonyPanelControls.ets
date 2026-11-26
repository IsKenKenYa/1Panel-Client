import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

@Component
export struct HarmonyPanelField {
  titleKey: string = '';
  @Prop fieldValue: string = '';
  multiline: boolean = false;
  secret: boolean = false;
  numeric: boolean = false;
  changed: (content: string) => void = (): void => {};

  build() {
    Column({ space: 8 }) {
      Text(HarmonyNativeBridge.instance.text(this.titleKey))
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
      if (this.multiline) {
        TextArea({ text: this.fieldValue })
          .fontSize(16)
          .constraintSize({ minHeight: 120 })
          .onChange((content: string): void => { this.changed(content); })
      } else {
        TextInput({ text: this.fieldValue })
          .fontSize(16)
          .height(48)
          .type(this.inputType())
          .onChange((content: string): void => { this.changed(content); })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  private inputType(): InputType {
    if (this.secret) return InputType.Password;
    if (this.numeric) return InputType.Number;
    return InputType.Normal;
  }
}

@Component
export struct HarmonyPanelValue {
  titleKey: string = '';
  content: string = '';

  build() {
    Row({ space: 12 }) {
      Text(HarmonyNativeBridge.instance.text(this.titleKey))
        .fontSize(16)
        .fontColor($r('sys.color.font_primary'))
      Text(this.content)
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.End)
        .layoutWeight(1)
        .copyOption(CopyOptions.InApp)
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }
}

@Component
export struct HarmonyPanelEntry {
  titleKey: string = '';
  subtitle: string = '';
  icon: Resource = $r('sys.symbol.gearshape');
  action: () => void = (): void => {};

  build() {
    Row({ space: 12 }) {
      SymbolGlyph(this.icon)
        .fontSize(24)
        .fontColor([$r('sys.color.icon_primary')])
      Column({ space: 2 }) {
        Text(HarmonyNativeBridge.instance.text(this.titleKey))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        if (this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(2)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('sys.color.icon_secondary')])
    }
    .padding(16)
    .constraintSize({ minHeight: 64 })
    .width('100%')
    .onClick((): void => { this.action(); })
    .accessibilityGroup(true)
    .accessibilityText(HarmonyNativeBridge.instance.text(this.titleKey))
  }
}
