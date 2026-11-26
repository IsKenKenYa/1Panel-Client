import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

interface HarmonyProtectedModule {
  moduleId: string;
  titleKey: string;
}

@Component
export struct HarmonyAppLockPage {
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private loadError: string = '';
  @State private lockEnabled: boolean = false;
  @State private lockOnOpen: boolean = true;
  @State private lockOnModule: boolean = true;
  @State private relockMinutes: number = 5;
  @State private supported: boolean = false;
  @State private supportReason: string = '';
  @State private sessionUnlocked: boolean = true;
  @State private protectedIds: string[] = [];
  @State private modules: HarmonyProtectedModule[] = [];
  @State private minuteOptions: number[] = [1, 5, 10, 30, 60];
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyAppLock');
      this.lockEnabled = result.get('enabled') as boolean;
      this.lockOnOpen = result.get('lockOnAppOpen') as boolean;
      this.lockOnModule = result.get('lockOnProtectedModule') as boolean;
      this.relockMinutes = result.get('relockAfterMinutes') as number;
      this.supported = result.get('supported') as boolean;
      this.supportReason = result.get('reason') as string | null ?? '';
      this.sessionUnlocked = result.get('unlocked') as boolean;
      this.protectedIds = result.get('protectedModuleIds') as string[];
      const moduleMaps = result.get('modules') as Map<string, string>[];
      this.modules = moduleMaps.map((module: Map<string, string>): HarmonyProtectedModule => ({
        moduleId: module.get('id') as string,
        titleKey: module.get('titleKey') as string,
      }));
      const options: number[] = [1, 5, 10, 30, 60];
      if (!options.includes(this.relockMinutes)) options.push(this.relockMinutes);
      this.minuteOptions = options.sort((first: number, second: number): number => first - second);
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async save(key: string, settingValue: boolean | number | string[]): Promise<void> {
    this.isSaving = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('key', key);
      args.set('value', settingValue);
      args.set('reason', this.text(key === 'enabled' ? 'appLockUnlockReasonEnable' : 'appLockUnlockReasonAppOpen'));
      args.set('failureMessage', this.text('appLockAuthFailed'));
      await this.bridge.invoke<Object | null>('updateHarmonyAppLock', args);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.isSaving = false;
    }
  }

  private toggleModule(moduleId: string, checked: boolean): void {
    const ids = this.protectedIds.filter((current: string): boolean => current !== moduleId);
    if (checked) ids.push(moduleId);
    this.save('protectedModuleIds', ids);
  }

  private minuteLabel(minutes: number): string {
    return this.text('appLockRelockAfterMinutesOption').replace('{minutes}', minutes.toString());
  }

  @Builder
  private sectionHeading(key: string) {
    Text(this.text(key)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private toggleRow(titleKey: string, descriptionKey: string, selected: boolean, settingKey: string,
    canChange: boolean) {
    ListItem() {
      Row({ space: 16 }) {
        Column({ space: 4 }) {
          Text(this.text(titleKey)).fontSize(16).fontColor($r('sys.color.font_primary'))
          Text(this.text(descriptionKey)).fontSize(14).fontColor($r('sys.color.font_secondary'))
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: selected })
          .enabled(canChange && !this.isSaving)
          .responseRegion({ x: -6, y: -14, width: 48, height: 48 })
          .accessibilityText(this.text(titleKey))
          .onChange((checked: boolean): void => { this.save(settingKey, checked); })
      }.constraintSize({ minHeight: 72 }).padding(16).width('100%')
    }.backgroundColor($r('sys.color.comp_background_primary'))
  }

  build() {
    NavDestination() {
      if (this.isLoading) {
        LoadingProgress().width(48).height(48)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }.padding(24)
      } else if (this.lockEnabled && !this.sessionUnlocked) {
        Column({ space: 16 }) {
          SymbolGlyph($r('sys.symbol.lock')).fontSize(48).fontColor([$r('sys.color.icon_primary')])
          Text(this.text('appLockTitle')).fontSize(20).fontColor($r('sys.color.font_primary'))
          Button(this.text('appLockUnlockAction')).height(48).enabled(!this.isSaving)
            .onClick((): void => { this.save('unlock', true); })
        }.width('100%').height('100%').justifyContent(FlexAlign.Center).padding(24)
      } else {
        List({ space: 16 }) {
          ListItemGroup() {
            ListItem() {
              Row({ space: 16 }) {
                SymbolGlyph($r('sys.symbol.touchid')).fontSize(24).fontColor([$r('sys.color.icon_primary')])
                Column({ space: 4 }) {
                  Text(this.text('appLockDeviceAuthStatus')).fontSize(16).fontColor($r('sys.color.font_primary'))
                  Text(this.supportReason.length > 0 ? this.supportReason :
                    this.text(this.supported ? 'appLockDeviceAuthSupported' : 'appLockDeviceAuthUnsupported'))
                    .fontSize(14).fontColor($r('sys.color.font_secondary'))
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }.padding(16).width('100%')
            }.backgroundColor($r('sys.color.comp_background_primary'))
            this.toggleRow('appLockEnable', 'appLockEnableDesc', this.lockEnabled, 'enabled',
              this.supported || this.lockEnabled)
            this.toggleRow('appLockLockOnAppOpen', 'appLockLockOnAppOpenDesc', this.lockOnOpen,
              'lockOnAppOpen', this.lockEnabled)
            this.toggleRow('appLockLockOnProtectedModule', 'appLockLockOnProtectedModuleDesc', this.lockOnModule,
              'lockOnProtectedModule', this.lockEnabled)
            ListItem() {
              Column({ space: 4 }) {
                Text(this.text('appLockRelockAfterMinutes')).fontSize(16).fontColor($r('sys.color.font_primary'))
                Select(this.minuteOptions.map((minutes: number): SelectOption => ({ value: this.minuteLabel(minutes) })))
                  .selected(this.minuteOptions.indexOf(this.relockMinutes)).value(this.minuteLabel(this.relockMinutes))
                  .height(48).enabled(this.lockEnabled && !this.isSaving)
                  .onSelect((index: number): void => { this.save('relockAfterMinutes', this.minuteOptions[index]); })
              }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
          ListItemGroup({ header: this.sectionHeading('appLockProtectedModules') }) {
            ListItem() {
              Row({ space: 8 }) {
                Button(this.text('appLockSelectAll')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .enabled(this.lockEnabled && this.lockOnModule && !this.isSaving)
                  .onClick((): void => {
                    this.save('protectedModuleIds', this.modules.map((module: HarmonyProtectedModule): string => module.moduleId));
                  })
                Button(this.text('appLockClearAll')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .enabled(this.lockEnabled && this.lockOnModule && !this.isSaving)
                  .onClick((): void => { this.save('protectedModuleIds', []); })
              }.padding({ left: 8, right: 8 }).width('100%')
            }.backgroundColor($r('sys.color.comp_background_primary'))
            ForEach(this.modules, (module: HarmonyProtectedModule): void => {
              ListItem() {
                Row({ space: 16 }) {
                  Text(this.text(module.titleKey)).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
                  Checkbox({ name: module.moduleId, group: 'harmony-protected-modules' })
                    .select(this.protectedIds.includes(module.moduleId))
                    .enabled(this.lockEnabled && this.lockOnModule && !this.isSaving)
                    .responseRegion({ x: -14, y: -14, width: 48, height: 48 })
                    .accessibilityText(this.text(module.titleKey))
                    .onChange((checked: boolean): void => { this.toggleModule(module.moduleId, checked); })
                }.padding({ left: 16, right: 8 }).width('100%').constraintSize({ minHeight: 56 })
              }.backgroundColor($r('sys.color.comp_background_primary'))
            }, (module: HarmonyProtectedModule): string => module.moduleId)
          }.borderRadius(16).clip(true)
        }.padding({ left: 16, right: 16, top: 16, bottom: 24 }).width('100%').height('100%')
      }
    }
    .title(this.text('appLockTitle'), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .onShown((): void => { this.load(); })
  }
}
