import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

export function computeText(key: string): string {
  return HarmonyNativeBridge.instance.text(key);
}

export function computeArguments(key: string, content: Object | null): Map<string, Object | null> {
  const args = new Map<string, Object | null>();
  args.set(key, content);
  return args;
}

export async function computeWrite(method: string, args: Map<string, Object | null>): Promise<Map<string, Object | null>> {
  const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>(method, args);
  if (result.has('success') && result.get('success') !== true) {
    throw new Error(result.get('error') as string);
  }
  return result;
}

@Component
export struct HarmonyComputeField {
  labelKey: string = '';
  @Link fieldText: string;
  inputType: InputType = InputType.Normal;
  disabled: boolean = false;

  build() {
    Column({ space: 8 }) {
      Text(computeText(this.labelKey))
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
      TextInput({ text: this.fieldText })
        .height(48)
        .fontSize(16)
        .type(this.inputType)
        .enabled(!this.disabled)
        .accessibilityText(computeText(this.labelKey))
        .onChange((content: string): void => { this.fieldText = content; })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct HarmonyComputeToggle {
  labelKey: string = '';
  @Link selected: boolean;

  build() {
    Row({ space: 12 }) {
      Text(computeText(this.labelKey)).fontSize(16).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.selected })
        .accessibilityText(computeText(this.labelKey))
        .onChange((enabled: boolean): void => { this.selected = enabled; })
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
  }
}

@Component
export struct HarmonyComputeInfo {
  labelKey: string = '';
  content: string = '';

  build() {
    Row({ space: 12 }) {
      Text(computeText(this.labelKey)).fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
      Text(this.content).fontSize(16).layoutWeight(1)
        .textAlign(TextAlign.End).copyOption(CopyOptions.InApp)
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
  }
}
