import { pasteboard } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';

@Component
export struct HarmonyFileSecondaryPage {
  route: string = '';
  routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};
  @State private rows: Array<Map<string, Object | null>> = [];
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  @State private busy: boolean = false;
  @State private mode: string = '';
  @State private owner: string = '';
  @State private group: string = '';
  @State private recursive: boolean = false;
  @State private preview: string | null = null;
  @State private expireMinutes: string = '1440';
  @State private sharePassword: string = '';
  @State private shareLink: string = '';
  private page: number = 1;
  private hasMore: boolean = true;
  private wgetRefresh: number = -1;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.owner = this.string(this.routeArguments, 'user');
    this.group = this.string(this.routeArguments, 'group');
    this.load(true);
    if (this.route === '/files/wget') {
      this.wgetRefresh = setInterval((): void => {
        if (!this.loading && !this.busy) this.load(true);
      }, 3000);
    }
  }

  aboutToDisappear(): void {
    if (this.wgetRefresh !== -1) clearInterval(this.wgetRefresh);
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private string(item: Map<string, Object | null>, key: string): string {
    const value = item.get(key);
    return value === null || value === undefined ? '' : String(value);
  }

  private title(): string {
    switch (this.route) {
      case '/files/favorites': return this.text('filesFavorites');
      case '/files/mounts': return this.text('filesMounts');
      case '/files/recycle': return this.text('recycleBinTitle');
      case '/files/recycle-status': return this.text('recycleBinStatusTitle');
      case '/files/share': return this.text('fileShareTitle');
      case '/files/wget': return this.text('wgetTitle');
      case '/files/permission': return this.text('filesPermissionTitle');
      default: return this.text('fileHistoryTitleWith').replace('{path}', this.string(this.routeArguments, 'name'));
    }
  }

  private paged(): boolean {
    return this.route === '/files/favorites' || this.route === '/files/recycle' || this.route === '/files/history';
  }

  private async load(reset: boolean): Promise<void> {
    if (!reset && (!this.paged() || !this.hasMore || this.loading || this.errorMessage.length > 0)) return;
    if (reset) this.page = 1;
    this.loading = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('route', this.route);
      args.set('path', this.routeArguments.get('path') ?? null);
      args.set('page', this.page);
      const items = await this.bridge.invoke<Array<Map<string, Object | null>>>('getHarmonyFileSecondary', args);
      this.rows = reset ? items : this.rows.concat(items);
      this.page++;
      this.hasMore = items.length === 100;
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async operate(action: string, item: Map<string, Object | null> | null): Promise<void> {
    if (this.busy) return;
    this.busy = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('action', action);
      args.set('item', item);
      args.set('path', this.routeArguments.get('path') ?? null);
      args.set('mode', this.mode);
      args.set('user', this.owner);
      args.set('group', this.group);
      args.set('recursive', this.recursive);
      args.set('expireMinutes', this.expireMinutes);
      args.set('password', this.sharePassword);
      const content = await this.bridge.invoke<string | null>('operateHarmonyFileSecondary', args);
      if (action === 'preview-history') {
        this.preview = content ?? '';
      } else if (action === 'create-share') {
        this.shareLink = content as string;
        this.sharePassword = '';
      } else if (action === 'copy-share' && content !== null) {
        await this.copyLink(content);
      } else if (this.route === '/files/permission') {
        this.getUIContext().getPromptAction().showToast({ message: this.text('filePermissionUpdated') });
      } else {
        await this.load(true);
      }
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private async copyLink(link: string): Promise<void> {
    await pasteboard.getSystemPasteboard().setData(
      pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, link),
    );
    this.getUIContext().getPromptAction().showToast({ message: this.text('commonCopySuccess') });
  }

  private confirm(
    action: string, label: string, message: string, item: Map<string, Object | null> | null,
  ): void {
    this.getUIContext().showAlertDialog({
      title: label,
      message: message,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: label, action: (): void => { this.operate(action, item); } },
    });
  }

  private async open(item: Map<string, Object | null>): Promise<void> {
    if (this.route === '/files/history') {
      await this.operate('preview-history', item);
      return;
    }
    if (this.route === '/files/mounts') {
      const args = new Map<string, Object | null>();
      args.set('path', this.string(item, 'mountPoint'));
      await this.bridge.openNativePage('/files', args);
      return;
    }
    if (this.route !== '/files/favorites') return;
    const path = this.string(item, 'path');
    if (item.get('isDir') === true) {
      const args = new Map<string, Object | null>();
      args.set('path', path);
      await this.bridge.openNativePage('/files', args);
    } else {
      await this.bridge.openNativePage('/files/preview', item);
    }
  }

  private name(item: Map<string, Object | null>): string {
    switch (this.route) {
      case '/files/history': return this.string(item, 'createdAt');
      case '/files/mounts': return this.string(item, 'mountPoint');
      case '/files/share': return this.string(item, 'path');
      case '/files/wget': return this.string(item, 'name');
      default: return this.string(item, 'name');
    }
  }

  private description(item: Map<string, Object | null>): string {
    switch (this.route) {
      case '/files/history': return this.string(item, 'operation');
      case '/files/mounts': return this.string(item, 'device') + ' · ' + this.string(item, 'fsType');
      case '/files/wget': return this.wgetStatus(item) + ' · ' + this.string(item, 'percent') + '%';
      case '/files/share': return this.string(item, 'expiresAt');
      case '/files/recycle': return this.string(item, 'from');
      default: return this.string(item, 'path');
    }
  }

  private empty(): string {
    switch (this.route) {
      case '/files/history': return this.text('fileHistoryEmpty');
      case '/files/favorites': return this.text('filesFavoritesEmpty');
      case '/files/share': return this.text('fileShareEmpty');
      case '/files/recycle': return this.text('recycleBinEmpty');
      case '/files/wget': return this.text('wgetEmpty');
      default: return this.text('commonEmpty');
    }
  }

  private rowKey(item: Map<string, Object | null>): string {
    switch (this.route) {
      case '/files/history': return this.string(item, 'id');
      case '/files/recycle': return this.string(item, 'rName');
      case '/files/wget': return this.string(item, 'key');
      case '/files/mounts': return this.name(item);
      default: return this.string(item, 'path');
    }
  }

  private actions(item: Map<string, Object | null>): MenuElement[] {
    const deleteLabel = this.text('commonDelete');
    const deleteMessage = this.text('deleteCannotUndoMessage');
    switch (this.route) {
      case '/files/favorites':
        return [{ value: this.text('commonDelete'), action: (): void => { this.operate('unfavorite', item); } }];
      case '/files/recycle':
        return [
          { value: this.text('recycleBinRestore'), action: (): void => {
            this.confirm('restore-recycle', this.text('recycleBinRestore'),
              this.text('recycleBinRestoreSingleConfirm').replace('{name}', this.name(item)), item);
          } },
          { value: this.text('recycleBinDeletePermanently'), action: (): void => {
            this.confirm('delete-recycle', this.text('recycleBinDeletePermanently'),
              this.text('recycleBinDeletePermanentlySingleConfirm').replace('{name}', this.name(item)), item);
          } },
        ];
      case '/files/history':
        return [
          { value: this.text('filesPreviewTitle'), action: (): void => { this.operate('preview-history', item); } },
          { value: this.text('fileHistoryRestore'), action: (): void => {
            this.confirm('restore-history', this.text('fileHistoryRestore'), this.name(item), item);
          } },
          { value: deleteLabel, action: (): void => {
            this.confirm('delete-history', deleteLabel, deleteMessage, item);
          } },
        ];
      case '/files/share':
        return [
          { value: this.text('commonCopy'), action: (): void => { this.operate('copy-share', item); } },
          { value: deleteLabel, action: (): void => {
            this.confirm('delete-share', deleteLabel, deleteMessage, item);
          } },
        ];
      case '/files/wget':
        if (!this.wgetRunning(item)) return [];
        return [{ value: this.text('commonStop'), action: (): void => { this.operate('stop-wget', item); } }];
      default:
        return [];
    }
  }

  private wgetRunning(item: Map<string, Object | null>): boolean {
    const status = item.get('status');
    return status === 'Downloading' || status === 'Retrying';
  }

  private wgetStatus(item: Map<string, Object | null>): string {
    switch (item.get('status')) {
      case 'Success': return this.text('transferStatusCompleted');
      case 'Failed': return this.text('transferStatusFailed');
      case 'Canceled': return this.text('transferStatusCancelled');
      default: return this.text('transferStatusRunning');
    }
  }

  private userOptions(): MenuElement[] {
    const users = this.rows[0]?.get('users') as Array<Map<string, Object | null>> | undefined;
    return (users ?? []).map((item: Map<string, Object | null>): MenuElement => {
      const name = this.string(item, 'user');
      return { value: name, action: (): void => { this.owner = name; } };
    });
  }

  private groups(): MenuElement[] {
    const groups = this.rows[0]?.get('groups') as string[] | undefined;
    return (groups ?? []).map((name: string): MenuElement => {
      return { value: name, action: (): void => { this.group = name; } };
    });
  }

  @Builder
  private shareForm() {
    Column({ space: 12 }) {
      Text(this.string(this.routeArguments, 'path'))
        .fontSize(16)
        .fontColor($r('sys.color.font_secondary'))
      if (this.shareLink.length > 0) {
        Text(this.shareLink).copyOption(CopyOptions.LocalDevice)
        Button(this.text('commonCopy'))
          .height(48)
          .onClick((): void => { this.copyLink(this.shareLink); })
      } else {
        TextInput({
          text: this.expireMinutes,
          placeholder: this.text('settingsCacheExpiration') + ' (' + this.text('serverFormMinutes') + ')',
        })
          .height(48)
          .type(InputType.Number)
          .onChange((minutes: string): void => { this.expireMinutes = minutes; })
        TextInput({ text: this.sharePassword, placeholder: this.text('commonPassword') })
          .height(48)
          .type(InputType.Password)
          .onChange((password: string): void => { this.sharePassword = password; })
        Button(this.text('commonCreate'))
          .height(48)
          .enabled(!this.busy && this.expireMinutes.length > 0 && Number(this.expireMinutes) <= 10080)
          .onClick((): void => { this.operate('create-share', null); })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private permissions() {
    Column({ space: 12 }) {
      Text(this.string(this.routeArguments, 'path')).fontSize(16).fontColor($r('sys.color.font_secondary'))
      TextInput({ text: this.mode, placeholder: this.text('filePermissionMode') })
        .height(48)
        .onChange((value: string): void => { this.mode = value; })
      Button(this.text('filesPermissionChangeMode')).height(48)
        .enabled(!this.busy && /^[0-7]{3,4}$/.test(this.mode))
        .onClick((): void => { this.operate('change-mode', null); })
      Button(this.owner.length === 0 ? this.text('filesPermissionUserHint') : this.owner)
        .height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
        .bindMenu(this.userOptions(), { systemMaterial: menuMaterial })
      Button(this.group.length === 0 ? this.text('filesPermissionGroupHint') : this.group)
        .height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
        .bindMenu(this.groups(), { systemMaterial: menuMaterial })
      Button(this.text('filesPermissionChangeOwner')).height(48)
        .enabled(!this.busy && this.owner.length > 0 && this.group.length > 0)
        .onClick((): void => { this.operate('change-owner', null); })
      if (this.routeArguments.get('isDir') === true) {
        Row({ space: 8 }) {
          Text(this.text('filesPermissionRecursive')).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.recursive })
            .accessibilityText(this.text('filesPermissionRecursive'))
            .onChange((value: boolean): void => { this.recursive = value; })
        }.width('100%').constraintSize({ minHeight: 48 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private row(item: Map<string, Object | null>) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(this.name(item)).fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary')).maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.description(item).length > 0) {
          Text(this.description(item)).fontSize(14)
            .fontColor($r('sys.color.font_secondary')).maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        if (this.route === '/files/wget' && this.wgetRunning(item)) {
          Progress({ value: Number(item.get('percent')), total: 100, type: ProgressType.Linear }).width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ minHeight: 48 })
      .onClick((): void => { this.open(item); })
      if (this.actions(item).length > 0) {
        Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(22) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .accessibilityText(this.text('commonMore') + ' · ' + this.name(item))
          .bindMenu(this.actions(item), { systemMaterial: menuMaterial })
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .padding({ left: 16, right: 8, top: 6, bottom: 6 })
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        if (this.preview !== null) {
          Scroll() {
            Text(this.preview ?? '')
              .copyOption(CopyOptions.LocalDevice)
              .fontFamily('monospace')
              .width('100%')
              .padding(16)
          }.layoutWeight(1).width('100%').align(Alignment.TopStart)
          Button(this.text('commonClose')).height(48)
            .onClick((): void => { this.preview = null; })
        } else if (this.errorMessage.length > 0) {
          Text(this.errorMessage).fontColor($r('sys.color.font_secondary')).textAlign(TextAlign.Center)
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(true); })
        } else if (this.route === '/files/share' && this.string(this.routeArguments, 'path').length > 0) {
          this.shareForm()
        } else if (this.loading && this.rows.length === 0) {
          LoadingProgress().width(40).height(40)
        } else if (this.route === '/files/permission') {
          this.permissions()
        } else if (this.route === '/files/recycle-status' && this.rows.length > 0) {
          Text(this.text('commonStatus') + ' · ' +
            this.text(this.rows[0].get('status') === 'Enable' ? 'securityStatusEnabled' : 'securityStatusDisabled'))
            .fontSize(16).fontColor($r('sys.color.font_primary'))
        } else {
          if (this.route === '/files/recycle') {
            Row({ space: 8 }) {
              Button(this.text('recycleBinStatusTitle')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick((): void => { this.bridge.openNativePage('/files/recycle-status'); })
              Button(this.text('recycleBinClear')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .enabled(!this.busy && this.rows.length > 0)
                .onClick((): void => { this.confirm('clear-recycle', this.text('recycleBinClear'),
                  this.text('recycleBinClearConfirm'), null); })
            }
          }
          if (this.rows.length === 0) {
            Text(this.empty()).fontColor($r('sys.color.font_secondary')).padding(24)
          } else {
            List() {
              ForEach(this.rows, (item: Map<string, Object | null>): void => {
                ListItem() { this.row(item) }
              }, (item: Map<string, Object | null>): string => this.rowKey(item))
            }
            .width('100%')
            .layoutWeight(1)
            .borderRadius(16)
            .backgroundColor($r('sys.color.comp_background_primary'))
            .divider({ strokeWidth: 0.5, color: $r('sys.color.ohos_id_color_list_separator'), startMargin: 16 })
            .onReachEnd((): void => { this.load(false); })
          }
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    }
    .title(this.title(), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .onBackPressed((): boolean => {
      if (this.preview === null) return false;
      this.preview = null;
      return true;
    })
  }
}
