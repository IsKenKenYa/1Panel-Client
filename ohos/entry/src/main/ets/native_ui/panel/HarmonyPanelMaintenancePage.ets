import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge, sheetMaterial } from '../HarmonyNativeBridge';

interface HarmonyBackupAccount {
  id: number;
  name: string;
  type: string;
}

@Component
export struct HarmonyPanelMaintenancePage {
  @Prop section: string = 'snapshot';
  @State private loading: boolean = true;
  @State private busy: boolean = false;
  @State private loadError: string = '';
  @State private currentVersion: string = '';
  @State private releases: Array<Map<string, Object | null>> = [];
  @State private snapshots: Array<Map<string, Object | null>> = [];
  @State private accounts: HarmonyBackupAccount[] = [];
  @State private description: string = '';
  @State private importAccountIndex: number = -1;
  @State private importFiles: string[] = [];
  @State private importSelected: string[] = [];
  @State private importDescription: string = '';
  @State private importLoading: boolean = false;
  @State private importError: string = '';
  @State private selectedAccountIndex: number = 0;
  @State private editId: number = 0;
  @State private editDescription: string = '';
  @State private showCreateSheet: boolean = false;
  @State private showImportSheet: boolean = false;
  @State private showEditSheet: boolean = false;
  @State private confirmAction: string = '';
  @State private confirmId: number = 0;
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.load(); }

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      if (this.section === 'upgrade') {
        const result = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyPanelUpgrade');
        this.currentVersion = (result.get('version') as string | null) ?? '';
        const resultReleases = result.get('releases') as Array<Map<string, Object | null>> | null;
        this.releases = resultReleases ?? [];
      } else {
        const results = await this.bridge.invoke<Array<Map<string, Object | null>> | null>('getHarmonyPanelSnapshots');
        this.snapshots = results ?? [];
        const resultAccounts = await this.bridge.invoke<Array<Map<string, Object | null>> | null>(
          'getHarmonyPanelBackupAccounts');
        this.accounts = (resultAccounts ?? []).map((account: Map<string, Object | null>): HarmonyBackupAccount => {
          return {
            id: account.get('id') as number,
            name: account.get('name') as string,
            type: account.get('type') as string,
          };
        });
      }
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private menus(): NavigationMenuItem[] {
    const result: NavigationMenuItem[] = [{
      value: this.text('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      isEnabled: !this.loading && !this.busy,
      action: (): void => { this.load(); },
    }];
    if (this.section === 'snapshot') {
      result.push({
        value: this.text('snapshotCreate'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        isEnabled: !this.loading && !this.busy,
        action: (): void => { this.openCreate(); },
      });
      result.push({
        value: this.text('snapshotImport'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_down')),
        isEnabled: !this.loading && !this.busy,
        action: (): void => { this.openImport(); },
      });
    }
    return result;
  }

  private accountLabel(account: HarmonyBackupAccount): string {
    return `${account.name} (${account.type})`;
  }

  private selectedAccount(): HarmonyBackupAccount | null {
    if (this.accounts.length === 0) return null;
    return this.accounts[this.selectedAccountIndex] ?? null;
  }

  private openCreate(): void {
    this.description = '';
    this.selectedAccountIndex = 0;
    this.showCreateSheet = true;
  }

  private async perform(method: string, args: Map<string, Object | null>): Promise<void> {
    this.busy = true;
    try {
      await this.bridge.invoke<Object | null>(method, args);
      await this.load();
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private createSnapshot(): void {
    const account = this.selectedAccount();
    if (account === null) return;
    const args = new Map<string, Object | null>();
    if (this.description.length > 0) args.set('description', this.description);
    args.set('sourceAccountIDs', account.id.toString());
    args.set('downloadAccountID', account.id);
    this.showCreateSheet = false;
    this.perform('createHarmonyPanelSnapshot', args);
  }

  private openImport(): void {
    this.importAccountIndex = -1;
    this.importFiles = [];
    this.importSelected = [];
    this.importDescription = '';
    this.importLoading = false;
    this.importError = '';
    this.showImportSheet = true;
  }

  private async loadImportFiles(index: number): Promise<void> {
    this.importAccountIndex = index;
    this.importLoading = true;
    this.importFiles = [];
    this.importSelected = [];
    this.importError = '';
    const args = new Map<string, Object | null>();
    args.set('backupAccountID', this.accounts[index].id);
    try {
      const files = await this.bridge.invoke<string[]>('getHarmonyPanelSnapshotFiles', args);
      if (this.importAccountIndex === index) {
        const imported = this.snapshots.map((snapshot: Map<string, Object | null>): string =>
          `${snapshot.get('name') as string}.tar.gz`);
        this.importFiles = files.filter((file: string): boolean => !imported.includes(file));
      }
    } catch (error) {
      if (this.importAccountIndex === index) {
        this.importError = (error as Error).message;
      }
    } finally {
      if (this.importAccountIndex === index) this.importLoading = false;
    }
  }

  private importSnapshot(): void {
    if (this.importAccountIndex < 0 || this.importSelected.length === 0) return;
    const args = new Map<string, Object | null>();
    args.set('backupAccountID', this.accounts[this.importAccountIndex].id);
    args.set('names', this.importSelected);
    if (this.importDescription.trim().length > 0) args.set('description', this.importDescription.trim());
    this.showImportSheet = false;
    this.perform('importHarmonyPanelSnapshot', args);
  }

  private confirmSnapshotAction(action: string, id: number): void {
    this.confirmAction = action;
    this.confirmId = id;
    const titles = new Map<string, string>([
      ['recover', 'snapshotRecoverTitle'],
      ['rollback', 'snapshotRollbackTitle'],
      ['delete', 'snapshotDeleteTitle'],
    ]);
    const messages = new Map<string, string>([
      ['recover', 'snapshotRecoverConfirm'],
      ['rollback', 'snapshotRollbackConfirm'],
      ['delete', 'snapshotDeleteConfirm'],
    ]);
    this.getUIContext().showAlertDialog({
      title: this.text(titles.get(action) as string),
      message: this.text(messages.get(action) as string),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text(action === 'delete' ? 'commonDelete' : 'commonConfirm'),
        action: (): void => { this.runSnapshotAction(); },
      },
    });
  }

  private runSnapshotAction(): void {
    const args = new Map<string, Object | null>();
    args.set('id', this.confirmId);
    if (this.confirmAction === 'delete') {
      args.set('ids', [this.confirmId]);
      this.perform('deleteHarmonyPanelSnapshots', args);
    } else if (this.confirmAction === 'recover') {
      this.perform('recoverHarmonyPanelSnapshot', args);
    } else {
      this.perform('rollbackHarmonyPanelSnapshot', args);
    }
  }

  private editSnapshot(snapshot: Map<string, Object | null>): void {
    this.editId = snapshot.get('id') as number;
    this.editDescription = (snapshot.get('description') as string | null) ?? '';
    this.showEditSheet = true;
  }

  private saveSnapshotDescription(): void {
    const args = new Map<string, Object | null>();
    args.set('id', this.editId);
    args.set('description', this.editDescription);
    this.showEditSheet = false;
    this.perform('describeHarmonyPanelSnapshot', args);
  }

  private async openReleaseNotes(version: string): Promise<void> {
    this.busy = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('version', version);
      const notes = await this.bridge.invoke<string | null>('getHarmonyPanelReleaseNotes', args);
      this.getUIContext().showAlertDialog({
        title: this.text('upgradeNotesTitle').replace('{version}', version),
        message: notes ? notes : this.text('upgradeNotesEmpty'),
        primaryButton: { value: this.text('commonClose'), action: (): void => {} },
      });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private confirmUpgrade(version: string): void {
    const downgrade = this.isDowngrade(version);
    this.getUIContext().showAlertDialog({
      title: this.text(downgrade ? 'upgradeDowngradeConfirm' : 'upgradeConfirm'),
      message: this.text(downgrade ? 'upgradeDowngradeMessage' : 'upgradeConfirmMessage')
        .replace('{version}', version),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text(downgrade ? 'upgradeDowngradeButton' : 'upgradeButton'),
        action: (): void => {
          const args = new Map<string, Object | null>();
          args.set('version', version);
          this.perform('upgradeHarmonyPanel', args);
        },
      },
    });
  }

  private isDowngrade(version: string): boolean {
    const pattern = new RegExp('v?(\\d+)\\.(\\d+)\\.(\\d+)');
    const current = pattern.exec(this.currentVersion);
    const selected = pattern.exec(version);
    if (current === null || selected === null) return false;
    for (let index = 1; index <= 3; index++) {
      const difference = Number(selected[index]) - Number(current[index]);
      if (difference !== 0) return difference < 0;
    }
    return false;
  }

  @Builder
  private heading(key: string) {
    Text(this.text(key)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      .width('100%').padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private accountSheet() {
    Column({ space: 16 }) {
      if (this.accounts.length === 0) {
        Text(this.text('snapshotNoBackupAccountHint')).fontSize(16)
          .fontColor($r('sys.color.font_secondary')).width('100%')
      } else {
        TextArea({ text: this.description, placeholder: this.text('snapshotDescHint') })
          .height(96).maxLength(256).onChange((value: string): void => { this.description = value; })
        Select(this.accounts.map((account: HarmonyBackupAccount): SelectOption => ({ value: this.accountLabel(account) })))
          .selected(this.selectedAccountIndex).value(this.accountLabel(this.accounts[this.selectedAccountIndex]))
          .height(48).onSelect((index: number): void => { this.selectedAccountIndex = index; })
        Button(this.text('commonConfirm')).height(48).width('100%').enabled(!this.busy)
          .onClick((): void => { this.createSnapshot(); })
      }
    }.width('100%').padding(24)
  }

  @Builder
  private importSheet() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.accounts.length === 0) {
          Text(this.text('snapshotNoBackupAccountHint')).fontSize(16)
            .fontColor($r('sys.color.font_secondary'))
        } else {
          Select(this.accounts.map((account: HarmonyBackupAccount): SelectOption => ({
            value: this.accountLabel(account),
          }))).selected(this.importAccountIndex).height(48)
            .value(this.importAccountIndex < 0 ? this.text('snapshotBackupAccountLabel') :
              this.accountLabel(this.accounts[this.importAccountIndex]))
            .onSelect((index: number): void => { this.loadImportFiles(index); })
          if (this.importLoading) {
            LoadingProgress().width(48).height(48)
          } else if (this.importError.length > 0) {
            Text(this.importError).fontSize(14).fontColor($r('sys.color.font_secondary'))
            Button(this.text('commonRetry')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
              .onClick((): void => { this.loadImportFiles(this.importAccountIndex); })
          } else if (this.importAccountIndex >= 0 && this.importFiles.length === 0) {
            Text(this.text('commonEmpty')).fontSize(14).fontColor($r('sys.color.font_secondary'))
          } else {
            ForEach(this.importFiles, (file: string): void => {
              Row({ space: 12 }) {
                Text(file).fontSize(16).layoutWeight(1)
                Checkbox({ name: file, group: 'harmony-snapshot-import' })
                  .select(this.importSelected.includes(file))
                  .accessibilityText(file)
                  .onChange((checked: boolean): void => {
                    this.importSelected = checked ? this.importSelected.concat([file]) :
                      this.importSelected.filter((selected: string): boolean => selected !== file);
                  })
              }.width('100%').constraintSize({ minHeight: 48 })
            }, (file: string): string => file)
          }
          TextArea({ text: this.importDescription, placeholder: this.text('snapshotDescHint') })
            .height(96).maxLength(256).onChange((value: string): void => { this.importDescription = value; })
          Button(this.text('commonConfirm')).height(48).width('100%')
            .enabled(!this.busy && !this.importLoading && this.importSelected.length > 0)
            .onClick((): void => { this.importSnapshot(); })
        }
      }.width('100%').padding(24).alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private editSheet() {
    Column({ space: 16 }) {
      TextArea({ text: this.editDescription, placeholder: this.text('snapshotDescHint') })
        .height(96).maxLength(256).onChange((value: string): void => { this.editDescription = value; })
      Button(this.text('commonSave')).height(48).width('100%').enabled(!this.busy)
        .onClick((): void => { this.saveSnapshotDescription(); })
    }.width('100%').padding(24)
  }

  @Builder
  private snapshotList() {
    List({ space: 12 }) {
      if (this.snapshots.length === 0) {
        ListItemGroup() {
          ListItem() {
            Column({ space: 8 }) {
              Text(this.text('snapshotEmpty')).fontSize(16).fontColor($r('sys.color.font_secondary'))
              if (this.accounts.length > 0) {
                Button(this.text('snapshotCreate')).height(48).onClick((): void => { this.openCreate(); })
              }
              Button(this.text('snapshotImport')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick((): void => { this.openImport(); })
            }.width('100%').alignItems(HorizontalAlign.Center).padding(24)
          }.backgroundColor($r('sys.color.comp_background_primary'))
        }.borderRadius(16).clip(true)
      }
      ForEach(this.snapshots, (snapshot: Map<string, Object | null>): void => {
        ListItemGroup() {
          ListItem() {
            Column({ space: 8 }) {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.clock')).fontSize(22)
                  .fontColor([$r('sys.color.icon_primary')])
                Column({ space: 4 }) {
                  Text((snapshot.get('name') as string | null) ?? `Snapshot ${snapshot.get('id')}`)
                    .fontSize(16).fontColor($r('sys.color.font_primary'))
                  Text(`${this.text('snapshotCreatedAt')}: ${(snapshot.get('createdAt') as string | null) ?? '—'}`)
                    .fontSize(13).fontColor($r('sys.color.font_secondary'))
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              Text(`${this.text('snapshotDescription')}: ${(snapshot.get('description') as string | null) ?? '—'}`)
                .fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%').maxLines(2)
              Flex({ wrap: FlexWrap.Wrap }) {
                Button(this.text('snapshotRecover')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .enabled(!this.busy).onClick((): void => { this.confirmSnapshotAction('recover', snapshot.get('id') as number); })
                Button(this.text('snapshotRollback')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .enabled(!this.busy).onClick((): void => { this.confirmSnapshotAction('rollback', snapshot.get('id') as number); })
                Button(this.text('snapshotEditDesc')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .enabled(!this.busy).onClick((): void => { this.editSnapshot(snapshot); })
                Button(this.text('snapshotDelete')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .enabled(!this.busy).onClick((): void => { this.confirmSnapshotAction('delete', snapshot.get('id') as number); })
              }.width('100%')
            }.width('100%').padding(16)
          }.backgroundColor($r('sys.color.comp_background_primary'))
        }.borderRadius(16).clip(true)
      }, (snapshot: Map<string, Object | null>): string => (snapshot.get('id') as number).toString())
    }.width('100%').height('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
      .scrollBar(BarState.Auto)
  }

  @Builder
  private upgradeList() {
    List({ space: 12 }) {
      ListItemGroup({ header: this.heading('upgradeCurrentVersion') }) {
        ListItem() {
          Row({ space: 12 }) {
            Text(this.text('upgradeCurrentVersionLabel')).fontSize(16)
              .fontColor($r('sys.color.font_primary')).layoutWeight(1)
            Text(this.currentVersion.length > 0 ? this.currentVersion : '—').fontSize(14)
              .fontColor($r('sys.color.font_secondary'))
          }.width('100%').padding(16).constraintSize({ minHeight: 56 })
        }.backgroundColor($r('sys.color.comp_background_primary'))
      }.borderRadius(16).clip(true)
      ListItemGroup({ header: this.heading('upgradeAvailableVersions') }) {
        if (this.releases.length === 0) {
          ListItem() {
            Text(this.text('upgradeNoUpdates')).fontSize(16).fontColor($r('sys.color.font_secondary'))
              .width('100%').padding(16)
          }.backgroundColor($r('sys.color.comp_background_primary'))
        }
        ForEach(this.releases, (release: Map<string, Object | null>): void => {
          ListItem() {
            Column({ space: 8 }) {
              Row({ space: 12 }) {
                Text((release.get('version') as string | null) ?? '—').fontSize(16)
                  .fontColor($r('sys.color.font_primary')).layoutWeight(1)
                if (release.get('isLatest') === true) {
                  Text(this.text('upgradeLatest')).fontSize(13).fontColor($r('sys.color.font_secondary'))
                }
              }.width('100%')
              if (release.get('description')) {
                Text(release.get('description') as string).fontSize(14).fontColor($r('sys.color.font_secondary'))
                  .width('100%').maxLines(2)
              }
              Row({ space: 12 }) {
                Button(this.text('upgradeViewNotes')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .enabled(!this.busy).onClick((): void => { this.openReleaseNotes(release.get('version') as string); })
                Button(this.text(this.isDowngrade(release.get('version') as string) ?
                  'upgradeDowngradeButton' : 'upgradeButton')).height(48).enabled(!this.busy)
                  .onClick((): void => { this.confirmUpgrade(release.get('version') as string); })
              }.width('100%').justifyContent(FlexAlign.End)
            }.width('100%').padding(16)
          }.backgroundColor($r('sys.color.comp_background_primary'))
        }, (release: Map<string, Object | null>): string => (release.get('version') as string))
      }.borderRadius(16).clip(true)
    }.width('100%').height('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
      .scrollBar(BarState.Auto)
  }

  build() {
    NavDestination() {
      if (this.loading) {
        Column() { LoadingProgress().width(48).height(48) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }.padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.section === 'upgrade') {
        this.upgradeList()
      } else {
        this.snapshotList()
      }
    }
    .title(this.text(this.section === 'upgrade' ? 'upgradeTitle' : 'snapshotTitle'),
      { barStyle: BarStyle.STANDARD })
    .menus(this.menus())
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .bindSheet($$this.showCreateSheet, this.accountSheet, {
      height: SheetSize.MEDIUM, showClose: true, title: { title: this.text('snapshotCreate') },
      systemMaterial: sheetMaterial,
    })
    .bindSheet($$this.showImportSheet, this.importSheet, {
      height: SheetSize.LARGE, showClose: true, title: { title: this.text('snapshotImportTitle') },
      systemMaterial: sheetMaterial,
    })
    .bindSheet($$this.showEditSheet, this.editSheet, {
      height: SheetSize.MEDIUM, showClose: true, title: { title: this.text('snapshotEditDescTitle') },
      systemMaterial: sheetMaterial,
    })
    .onShown((): void => { this.load(); })
  }
}
