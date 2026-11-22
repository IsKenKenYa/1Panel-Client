import { scanCore, scanBarcode, customScan } from '@kit.ScanKit';
import { display } from '@kit.ArkUI';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, abilityAccessCtrl, PermissionRequestResult } from '@kit.AbilityKit';

const TAG: string = '[customScanCallback]';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct CustomScanCallbackPage {
  @State userGrant: boolean = false;
  @State surfaceId: string = '';
  @State isShowBack: boolean = false;
  @State isFlashLightEnable: boolean = false;
  @State isSensorLight: boolean = false;
  @State cameraHeight: number = 640;
  @State cameraWidth: number = 360;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State zoomValue: number = 1;
  @State setZoomValue: number = 1;
  @State scaleValue: number = 1;
  @State pinchValue: number = 1;
  @State displayHeight: number = 0;
  @State displayWidth: number = 0;
  @State scanResult: Array<scanBarcode.ScanResult> = [];
  private mXComponentController: XComponentController = new XComponentController();

  private callback: AsyncCallback<scanBarcode.ScanResult[]> =
    (err: BusinessError, data: scanBarcode.ScanResult[]) => {
      if (err && err.code) {
        hilog.error(DOMAIN, TAG, `Failed to get ScanResult. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN, TAG, `Succeeded in getting ScanResult, result: ${JSON.stringify(data)}`);
      if (data.length) {
        this.scanResult = data;
        this.isShowBack = true;
        this.customScanStop();
      }
    };

  private frameCallback: AsyncCallback<customScan.ScanFrame> =
    (err: BusinessError, frameResult: customScan.ScanFrame) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `Failed to get ScanFrame. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN, TAG, `ScanFrame byteLength: ${frameResult.byteBuffer.byteLength}, width: ${frameResult.width}, height: ${frameResult.height}`);
    };

  async onPageShow() {
    await this.requestCameraPermission();
    if (!this.userGrant) {
      hilog.error(DOMAIN, TAG, 'Camera permission not granted.');
      return;
    }
    let options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    };
    this.setDisplay();
    try {
      customScan.init(options);
      hilog.info(DOMAIN, TAG, 'Succeeded in init customScan.');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to init customScan. Code: ${err.code}, message: ${err.message}`);
    }
  }

  onPageHide() {
    this.userGrant = false;
    this.isFlashLightEnable = false;
    this.isSensorLight = false;
    try {
      customScan.off('lightingFlash');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to off lightingFlash. Code: ${err.code}, message: ${err.message}`);
    }
    this.customScanStop();
    try {
      customScan.release().catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to release. Code: ${err.code}, message: ${err.message}`);
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to release. Code: ${err.code}, message: ${err.message}`);
    }
  }

  async reqPermissionsFromUser(): Promise<number[]> {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      const grantStatus: PermissionRequestResult =
        await atManager.requestPermissionsFromUser(context, ['ohos.permission.CAMERA']);
      return grantStatus.authResults;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to requestPermissionsFromUser. Code: ${err.code}, message: ${err.message}`);
      return [];
    }
  }

  async requestCameraPermission() {
    let grantStatus = await this.reqPermissionsFromUser();
    for (let i = 0; i < grantStatus.length; i++) {
      if (grantStatus[i] === 0) {
        hilog.info(DOMAIN, TAG, 'Succeeded in getting permissions.');
        this.userGrant = true;
        break;
      }
    }
  }

  setDisplay() {
    try {
      let displayClass = display.getDefaultDisplaySync();
      this.displayHeight = this.getUIContext().px2vp(displayClass.height);
      this.displayWidth = this.getUIContext().px2vp(displayClass.width);
      let maxLen: number = Math.max(this.displayWidth, this.displayHeight);
      let minLen: number = Math.min(this.displayWidth, this.displayHeight);
      const RATIO: number = 16 / 9;
      this.cameraHeight = maxLen;
      this.cameraWidth = maxLen / RATIO;
      this.offsetX = (minLen - this.cameraWidth) / 2;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to getDefaultDisplaySync. Code: ${err.code}, message: ${err.message}`);
    }
  }

  showScanResult(data: scanBarcode.ScanResult) {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: JSON.stringify(data),
        duration: 5000
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to showToast. Code: ${err.code}, message: ${err.message}`);
    }
  }

  initCamera() {
    this.isShowBack = false;
    this.scanResult = [];
    let viewControl: customScan.ViewControl = {
      width: this.cameraWidth,
      height: this.cameraHeight,
      surfaceId: this.surfaceId
    };
    try {
      customScan.start(viewControl, this.callback, this.frameCallback);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to start. Code: ${err.code}, message: ${err.message}`);
    }
  }

  customScanStop() {
    try {
      customScan.stop().catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to stop. Code: ${err.code}, message: ${err.message}`);
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to stop. Code: ${err.code}, message: ${err.message}`);
    }
  }

  triggerRescan() {
    try {
      customScan.rescan();
      hilog.info(DOMAIN, TAG, 'Succeeded in rescanning.');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to rescan. Code: ${err.code}, message: ${err.message}`);
    }
  }

  @Builder
  topTool() {
    Column() {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text('返回')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
      }.padding({ left: 24, right: 24, top: 40 })
      Column() {
        Text('扫描二维码/条形码')
        Text('对准二维码/条形码，即可自动扫描')
      }.margin({ left: 24, right: 24, top: 24 })
    }
    .height(146)
    .width('100%')
  }

  build() {
    Stack() {
      if (this.userGrant) {
        Column() {
          XComponent({
            id: 'componentId',
            type: XComponentType.SURFACE,
            controller: this.mXComponentController
          })
            .onLoad(() => {
              hilog.info(DOMAIN, TAG, 'Succeeded in loading, onLoad is called.');
              this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
              hilog.info(DOMAIN, TAG, `Succeeded in getting surfaceId: ${this.surfaceId}`);
              this.initCamera();
              customScan.on('lightingFlash', (err, isLightingFlash) => {
                if (err) {
                  hilog.error(DOMAIN, TAG, `Failed to on lightingFlash. Code: ${err.code}, message: ${err.message}`);
                  return;
                }
                if (isLightingFlash) {
                  this.isFlashLightEnable = true;
                } else {
                  try {
                    if (!customScan.getFlashLightStatus()) {
                      this.isFlashLightEnable = false;
                    }
                  } catch (err) {
                    hilog.error(DOMAIN, TAG, `Failed to getFlashLightStatus. Code: ${err.code}, message: ${err.message}`);
                  }
                }
                this.isSensorLight = isLightingFlash;
              });
            })
            .width(this.cameraWidth)
            .height(this.cameraHeight)
            .position({ x: this.offsetX, y: this.offsetY })
        }
        .height('100%')
        .width('100%')
      }
      Column() {
        this.topTool();
        Column() {
        }
        .layoutWeight(1)
        .width('100%')
        Column() {
          Row() {
            Button('FlashLight')
              .onClick(() => {
                let lightStatus: boolean = false;
                try {
                  lightStatus = customScan.getFlashLightStatus();
                } catch (err) {
                  hilog.error(DOMAIN, TAG, `Failed to getFlashLightStatus. Code: ${err.code}, message: ${err.message}`);
                }
                if (lightStatus) {
                  try {
                    customScan.closeFlashLight();
                    setTimeout(() => {
                      this.isFlashLightEnable = this.isSensorLight;
                    }, 200);
                  } catch (err) {
                    hilog.error(DOMAIN, TAG, `Failed to closeFlashLight. Code: ${err.code}, message: ${err.message}`);
                  }
                } else {
                  try {
                    customScan.openFlashLight();
                  } catch (err) {
                    hilog.error(DOMAIN, TAG, `Failed to openFlashLight. Code: ${err.code}, message: ${err.message}`);
                  }
                }
              })
              .visibility((this.userGrant && this.isFlashLightEnable) ? Visibility.Visible : Visibility.None)
            Button('Scan')
              .onClick(() => {
                this.initCamera();
              })
              .visibility(this.isShowBack ? Visibility.Visible : Visibility.None)
            Button('Rescan')
              .onClick(() => {
                this.triggerRescan();
              })
              .visibility(this.isShowBack ? Visibility.Visible : Visibility.None)
          }
          Row() {
            Button('缩放比例,当前比例:' + this.setZoomValue)
              .onClick(() => {
                if (!this.isShowBack) {
                  if (!this.zoomValue || this.zoomValue === this.setZoomValue) {
                    this.setZoomValue = this.customGetZoom();
                  } else {
                    this.customSetZoom(this.zoomValue);
                    setTimeout(() => {
                      if (!this.isShowBack) {
                        this.setZoomValue = this.customGetZoom();
                      }
                    }, 1000);
                  }
                }
              })
          }
          .margin({ top: 10, bottom: 10 })
          Row() {
            TextInput({ placeholder: '输入缩放倍数' })
              .type(InputType.Number)
              .borderWidth(1)
              .backgroundColor(Color.White)
              .onChange(value => {
                this.zoomValue = Number(value);
              })
          }
        }
        .width('50%')
        .height(180)
      }
      ForEach(this.scanResult, (item: scanBarcode.ScanResult) => {
        if (item.scanCodeRect) {
          Image($rawfile('scan_selected2.svg'))
            .width(40)
            .height(40)
            .markAnchor({ x: 20, y: 20 })
            .position({
              x: (item.scanCodeRect.left + item.scanCodeRect.right) / 2 + this.offsetX,
              y: (item.scanCodeRect.top + item.scanCodeRect.bottom) / 2 + this.offsetY
            })
            .onClick(() => {
              this.showScanResult(item);
            })
        }
      }, (item: scanBarcode.ScanResult) => '' + item.scanCodeRect?.left + item.scanCodeRect?.right + 'px');
    }
    .width('100%')
    .height('100%')
    .onClick((event: ClickEvent) => {
      if (this.isShowBack) {
        return;
      }
      let x1 = event.displayY / (this.displayHeight + 0.0);
      let y1 = 1.0 - event.displayX / (this.displayWidth + 0.0);
      try {
        customScan.setFocusPoint({ x: x1, y: y1 });
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Failed to setFocusPoint. Code: ${err.code}, message: ${err.message}`);
      }
      setTimeout(() => {
        try {
          customScan.resetFocus();
        } catch (err) {
          hilog.error(DOMAIN, TAG, `Failed to resetFocus. Code: ${err.code}, message: ${err.message}`);
        }
      }, 200);
    }).gesture(PinchGesture({ fingers: 2 })
      .onActionStart(() => {
        hilog.info(DOMAIN, TAG, 'Pinch start');
      })
      .onActionUpdate((event: GestureEvent) => {
        if (event) {
          this.scaleValue = event.scale;
        }
      })
      .onActionEnd(() => {
        if (this.isShowBack) {
          return;
        }
        try {
          let zoom = this.customGetZoom();
          this.pinchValue = this.scaleValue * zoom;
          this.customSetZoom(this.pinchValue);
        } catch (err) {
          hilog.error(DOMAIN, TAG, `Failed to set zoom. Code: ${err.code}, message: ${err.message}`);
        }
      }))
  }

  public customGetZoom(): number {
    let zoom = 1;
    try {
      zoom = customScan.getZoom();
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to getZoom. Code: ${err.code}, message: ${err.message}`);
    }
    return zoom;
  }

  public customSetZoom(pinchValue: number): void {
    try {
      customScan.setZoom(pinchValue);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to setZoom. Code: ${err.code}, message: ${err.message}`);
    }
  }
}
