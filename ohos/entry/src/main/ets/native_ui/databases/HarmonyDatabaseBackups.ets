import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';
import { HarmonyDatabaseItem, harmonyDatabaseText } from './HarmonyDatabaseModels';

@Component
export struct HarmonyDatabaseBackups {
  @Prop itemData: Map<string, Object | null> = new Map<string, Object | null>();
  @State private records: Map<string, Object | null>[] = [];
  @State private currentPage: number = 1;
  @State private totalPages: number = 0;
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';
  @State private secretValue: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const args = new HarmonyDatabaseItem(this.itemData).request();
      args.set('page', this.currentPage);
      args.set('pageSize', 20);
      const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>('getHarmonyDatabaseBackups', args);
      this.records = result.get('items') as Array<Map<string, Object | null>>;
      this.totalPages = result.get('totalPages') as number;
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async mutate(method: string, record?: Map<string, Object | null>): Promise<void> {
    this.isSaving = true;
    this.errorMessage = '';
    try {
      const args = new HarmonyDatabaseItem(this.itemData).request();
      args.set('secret', this.secretValue);
      if (record !== undefined) {
        args.set('record', record);
      }
      await HarmonyNativeBridge.instance.invoke<Object | null>(method, args);
      this.getUIContext().getPromptAction().showToast({ message: harmonyDatabaseText('commonSaveSuccess') });
      await this.load();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isSaving = false;
    }
  }

  private confirm(record: Map<string, Object | null>, restore: boolean): void {
    this.getUIContext().showAlertDialog({
      title: harmonyDatabaseText(restore ? 'databaseBackupRestoreAction' : 'databaseBackupDeleteAction'),
      message: harmonyDatabaseText(restore ? 'databaseBackupRestoreConfirmMessage' : 'databaseBackupDeleteConfirmMessage'),
      primaryButton: { value: harmonyDatabaseText('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: harmonyDatabaseText('commonConfirm'),
        action: (): void => { this.mutate(restore ? 'restoreHarmonyDatabaseBackup' : 'deleteHarmonyDatabaseBackup', record); },
      },
    });
  }

  @Builder
  private recordMenu(record: Map<string, Object | null>) {
    Menu() {
      MenuItem({ content: harmonyDatabaseText('databaseBackupRestoreAction') })
        .onClick((): void => { this.confirm(record, true); })
      MenuItem({ content: harmonyDatabaseText('databaseBackupDeleteAction') })
        .onClick((): void => { this.confirm(record, false); })
    }
  }

  build() {
    Column({ space: 12 }) {
      TextInput({ text: this.secretValue, placeholder: harmonyDatabaseText('databaseBackupSecretLabel') })
        .type(InputType.Password).height(48)
        .onChange((content: string): void => { this.secretValue = content; })
      Button(harmonyDatabaseText('databaseBackupCreateAction')).height(48).width('100%')
        .enabled(!this.isSaving)
        .onClick((): void => { this.mutate('createHarmonyDatabaseBackup'); })
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).width('100%').fontSize(14)
      }
      if (this.isLoading) {
        LoadingProgress().width(48).height(48)
      } else if (this.records.length === 0) {
        Text(harmonyDatabaseText('databaseBackupEmpty')).padding(24)
      }
      List({ space: 12 }) {
        ForEach(this.records, (record: Map<string, Object | null>): void => {
          ListItem() {
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text(`${record.get('fileName') ?? record.get('name')}`).fontSize(16)
                  .fontWeight(FontWeight.Medium).maxLines(2)
                Text(`${record.get('status')} · ${record.get('size')} B`).fontSize(14)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                Text(`${record.get('createdAt') ?? ''}`).fontSize(14)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              }
              .layoutWeight(1).alignItems(HorizontalAlign.Start)
              Button() { SymbolGlyph($r('sys.symbol.more')).fontSize(22) }
                .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .accessibilityText(harmonyDatabaseText('commonMore'))
                .bindMenu(this.recordMenu(record), { systemMaterial: menuMaterial })
            }
            .width('100%').padding(16).borderRadius(16)
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
          }
        }, (record: Map<string, Object | null>): string => `${record.get('id')}`)
      }
      .width('100%').layoutWeight(1)
      if (this.totalPages > 1) {
        Row({ space: 16 }) {
          Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }
            .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .enabled(this.currentPage > 1 && !this.isLoading)
            .accessibilityText(harmonyDatabaseText('commonPreviousPage'))
            .onClick((): void => { this.currentPage--; this.load(); })
          Text(`${this.currentPage} / ${this.totalPages}`).layoutWeight(1).textAlign(TextAlign.Center)
          Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20) }
            .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .enabled(this.currentPage < this.totalPages && !this.isLoading)
            .accessibilityText(harmonyDatabaseText('commonNextPage'))
            .onClick((): void => { this.currentPage++; this.load(); })
        }
        .width('100%')
      }
    }
    .width('100%').height('100%').padding(16)
  }
}
