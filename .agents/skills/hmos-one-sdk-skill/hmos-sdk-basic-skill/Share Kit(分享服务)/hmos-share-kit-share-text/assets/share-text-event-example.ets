import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct ShareTextEventExample {
  private textContent: string = '这是一段文本内容';
  private shareController: systemShare.ShareController | null = null;

  build() {
    Column() {
      Button('分享文本（带事件监听）')
        .onClick(() => {
          this.shareTextWithEvents();
        })
        .width('80%')
        .height(50)
        .margin({ top: 20 });

      Button('取消事件监听')
        .onClick(() => {
          this.unregisterEvents();
        })
        .width('80%')
        .height(50)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  private shareTextWithEvents(): void {
    try {
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.TEXT,
        content: this.textContent,
        title: '文本标题',
        description: '文本描述'
      });

      this.shareController = new systemShare.ShareController(shareData);

      this.registerEvents();

      let uiContext: UIContext = this.getUIContext();
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      this.shareController.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      }).then(() => {
        console.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      });
    } catch (error) {
      console.error('Share text with events failed:', error);
    }
  }

  private registerEvents(): void {
    if (!this.shareController) {
      console.error('ShareController is null.');
      return;
    }

    this.shareController.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
      console.info('shareCompleted event triggered.');
      console.info('Share channel name:', result.targetAbilityInfo.name);
      this.handleShareCompleted(result);
    });

    this.shareController.on('dismiss', () => {
      console.info('Share panel closed (dismiss event triggered).');
      this.handlePanelDismiss();
    });
  }

  private unregisterEvents(): void {
    if (!this.shareController) {
      console.error('ShareController is null.');
      return;
    }

    this.shareController.off('shareCompleted');
    this.shareController.off('dismiss');
    console.info('Events unregistered.');
  }

  private handleShareCompleted(result: systemShare.ShareOperationResult): void {
    const channelName = result.targetAbilityInfo.name;
    console.info('User selected share channel:', channelName);

    if (channelName.startsWith('SystemShare_')) {
      console.info('System share operation:', channelName);
    } else {
      console.info('Third-party app share:', channelName);
    }

    this.logShareStatistics(channelName);
  }

  private handlePanelDismiss(): void {
    console.info('Share panel has been closed.');
    console.info('User may have completed share operation or canceled.');
  }

  private logShareStatistics(channelName: string): void {
    const statistics = {
      timestamp: new Date().toISOString(),
      channel: channelName,
      contentType: 'text'
    };
    console.info('Share statistics:', JSON.stringify(statistics));
  }
}