@Component
export struct HarmonySslTextField {
  @Prop label: string = '';
  @Prop currentText: string = '';
  @Prop multiline: boolean = false;
  @Prop sensitive: boolean = false;
  @Prop editable: boolean = true;
  onTextChanged: (content: string) => void = (content: string): void => {};

  build() {
    Column({ space: 8 }) {
      Text(this.label).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width('100%')
      if (this.multiline) {
        TextArea({ text: this.currentText }).fontSize(16).height(148)
          .backgroundColor($r('sys.color.background_secondary'))
          .enabled(this.editable).onChange(this.onTextChanged)
          .accessibilityText(this.label)
      } else {
        TextInput({ text: this.currentText }).fontSize(16).height(48)
          .backgroundColor($r('sys.color.background_secondary'))
          .type(this.sensitive ? InputType.Password : InputType.Normal)
          .enabled(this.editable).onChange(this.onTextChanged)
          .accessibilityText(this.label)
      }
    }.width('100%')
  }
}

@Component
export struct HarmonySslSelectField {
  @Prop label: string = '';
  @Prop selectedText: string = '';
  @Prop choices: SelectOption[] = [];
  @Prop editable: boolean = true;
  onSelected: (index: number) => void = (index: number): void => {};

  build() {
    Column({ space: 8 }) {
      Text(this.label).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width('100%')
      Select(this.choices).value(this.selectedText).font({ size: 16 })
        .width('100%').height(48).enabled(this.editable)
        .onSelect((index: number): void => { this.onSelected(index); })
        .accessibilityText(this.label)
    }.width('100%')
  }
}

@Component
export struct HarmonySslToggleField {
  @Prop label: string = '';
  @Prop checked: boolean = false;
  onCheckedChanged: (checked: boolean) => void = (checked: boolean): void => {};

  build() {
    Row({ space: 12 }) {
      Text(this.label).fontSize(16).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.checked })
        .constraintSize({ minHeight: 48, minWidth: 48 })
        .onChange(this.onCheckedChanged).accessibilityText(this.label)
    }.width('100%').constraintSize({ minHeight: 48 })
  }
}
