import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'MyLiveFormPage';
const ANIMATION_RECT_SIZE: number = 100;
const END_SCALE: number = 1.5;
const END_TRANSLATE: number = -300;

@Entry
@Component
struct MyLiveFormPage {
  @State columnScale: number = 1.0;
  @State columnTranslate: number = 0.0;
  private uiContext: UIContext | undefined = undefined;
  private storageForMyLiveFormPage: LocalStorage | undefined = undefined;
  private formId: string | undefined = undefined;
  private formRect: formInfo.Rect | undefined = undefined;
  private formBorderRadius: number | undefined = undefined;
  private liveFormContext: common.LiveFormExtensionContext | undefined = undefined;
  
  aboutToAppear(): void {
    this.uiContext = this.getUIContext();
    if (!this.uiContext) {
      hilog.error(DOMAIN, TAG, 'no uiContext');
      return;
    }
    this.initParams();
  }
  
  private initParams(): void {
    this.storageForMyLiveFormPage = this.uiContext?.getSharedLocalStorage();
    this.formId = this.storageForMyLiveFormPage?.get<string>('formId');
    this.formRect = this.storageForMyLiveFormPage?.get<formInfo.Rect>('formRect');
    this.formBorderRadius = this.storageForMyLiveFormPage?.get<number>('borderRadius');
    this.liveFormContext = this.storageForMyLiveFormPage?.get<common.LiveFormExtensionContext>('context');
  }
  
  private runAnimation(): void {
    this.uiContext?.animateTo({
      duration: 3500,
      curve: Curve.Ease
    }, () => {
      this.columnScale = END_SCALE;
      this.columnTranslate = END_TRANSLATE;
    });
  }
  
  private startAbilityByLiveForm(): void {
    try {
      this.liveFormContext?.startAbilityByLiveForm({
        bundleName: 'com.samples.formlivedemo',
        abilityName: 'EntryAbility',
      })
        .then(() => {
          hilog.info(DOMAIN, TAG, 'startAbilityByLiveForm succeed');
        })
        .catch((err: BusinessError) => {
          hilog.error(DOMAIN, TAG, 
            `startAbilityByLiveForm failed, code: ${err?.code}, message: ${err?.message}`);
        });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 
        `startAbilityByLiveForm failed, code: ${e?.code}, message: ${e?.message}`);
    }
  }
  
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(this.formRect ? this.formRect.width : 0)
        .height(this.formRect ? this.formRect.height : 0)
        .offset({
          x: this.formRect ? this.formRect.left : 0,
          y: this.formRect ? this.formRect.top : 0,
        })
        .borderRadius(this.formBorderRadius ? this.formBorderRadius : 0)
        .backgroundColor('#2875F5')
      
      Stack() {
        this.buildContent();
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      hilog.info(DOMAIN, TAG, 'MyLiveFormPage click to start ability');
      if (!this.liveFormContext) {
        hilog.info(DOMAIN, TAG, 'liveFormContext is empty');
        return;
      }
      this.startAbilityByLiveForm();
    })
  }
  
  @Builder
  buildContent() {
    Stack()
      .width(ANIMATION_RECT_SIZE)
      .height(ANIMATION_RECT_SIZE)
      .backgroundColor(Color.White)
      .scale({
        x: this.columnScale,
        y: this.columnScale,
      })
      .translate({
        y: this.columnTranslate
      })
      .onAppear(() => {
        this.runAnimation();
      })
    
    Button($r('app.string.button_cancel'))
      .backgroundColor(Color.Grey)
      .onClick(() => {
        if (!this.formId) {
          hilog.info(DOMAIN, TAG, 'formId is empty, cancel overflow failed');
          return;
        }
        hilog.info(DOMAIN, TAG, 'cancel overflow animation');
        formProvider.cancelOverflow(this.formId);
      })
  }
}