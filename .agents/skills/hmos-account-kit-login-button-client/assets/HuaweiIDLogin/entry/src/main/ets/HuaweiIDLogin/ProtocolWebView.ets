/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026-2026. All rights reserved.
 */
import { ConfigurationConstant } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN_ID: number = 0x0000;
const LOG_TAG: string = 'HuaweiIDLoginProtocolWebView';

@Entry
@Component
struct ProtocolWebView {
  @State private progress: number = 0;
  @StorageProp('colorMode')
  @Watch('onColorModeChanged')
  private colorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  private url: string = '';
  private controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, Object>;
    this.url = (params?.['protocolUrl'] ?? '') as string;
  }

  private getPageUrl(): string {
    if (this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT || !this.url) {
      return this.url;
    }
    const separator = this.url.includes('?') ? '&' : '?';
    return `${this.url}${separator}bgmode=black`;
  }

  private onColorModeChanged(): void {
    try {
      this.controller.loadUrl(this.getPageUrl());
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(DOMAIN_ID, LOG_TAG,
        `Failed to switch web color mode. code: ${businessError.code}, message: ${businessError.message}`);
    }
  }

  private goBack(): void {
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
      } else {
        this.getUIContext().getRouter().back();
      }
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(DOMAIN_ID, LOG_TAG,
        `Failed to go back. code: ${businessError.code}, message: ${businessError.message}`);
      this.getUIContext().getRouter().back();
    }
  }

  onBackPress(): boolean {
    this.goBack();
    return true;
  }

  build() {
    Column() {
      Button({ type: ButtonType.Normal }) {
        Image($r('app.media.hwid_next_ic_appback'))
          .width(40)
          .height(40)
          .fillColor($r('sys.color.ohos_id_color_titlebar_icon'))
          .matchTextDirection(true)
          .draggable(false)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .alignSelf(ItemAlign.Start)
      .margin({ top: 36, bottom: 12 })
      .onClick(() => {
        this.goBack();
      })

      Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
        .width('100%')
        .visibility(this.progress < 100 ? Visibility.Visible : Visibility.None)

      Web({
        src: this.getPageUrl(),
        controller: this.controller
      })
        .layoutWeight(1)
        .width('100%')
        .javaScriptAccess(true)
        .geolocationAccess(false)
        .fileAccess(false)
        .darkMode(WebDarkMode.Auto)
        .backgroundColor($r('sys.color.ohos_id_color_background'))
        .onProgressChange((event) => {
          this.progress = event?.newProgress ?? 0;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .padding({ left: 16, right: 16, bottom: 16 })
  }
}
