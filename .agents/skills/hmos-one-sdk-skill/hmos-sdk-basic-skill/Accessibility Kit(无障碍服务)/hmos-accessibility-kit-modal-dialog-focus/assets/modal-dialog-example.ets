@Entry
@Component
export struct ModalDialogExample {
  title: string = 'Modal Dialog Example';
  private modelDialogController: CustomDialogController = this.createDialogController(true);
  private nonModelDialogController: CustomDialogController = this.createDialogController(false);

  private createDialogController(isModal: boolean): CustomDialogController {
    return new CustomDialogController({
      builder: CustomDialogExample({
        controller: isModal ? this.modelDialogController : this.nonModelDialogController,
        isModal: isModal,
        cancel: () => {
          if (isModal) {
            this.modelDialogController.close();
          } else {
            this.nonModelDialogController.close();
          }
        }
      }),
      autoCancel: true,
      isModal: isModal,
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
          dismissDialogAction.dismiss();
        }
        if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
          dismissDialogAction.dismiss();
        }
      },
      showInSubWindow: true,
      alignment: DialogAlignment.Center,
      width: 300,
      height: 250,
    })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Button('模态dialog')
            .margin({ bottom: 5 })
            .onClick(() => {
              this.modelDialogController.open();
            })
          Button('非模态dialog')
            .onClick(() => {
              this.nonModelDialogController.open();
            })
        }.margin({ bottom: 5 })
      }
    }.title(this.title)
  }
}

@CustomDialog
struct CustomDialogExample {
  isModal?: boolean;
  controller?: CustomDialogController;
  cancel: () => void = () => {};

  build() {
    Column() {
      Text(this.isModal ? '模态弹窗' : '非模态弹窗')
        .fontSize(30)
        .height(100)
        .accessibilityText(this.isModal ? '模态弹窗标题' : '非模态弹窗标题')
      Text('测试节点1')
        .accessibilityText('测试节点1')
      Text('测试节点2')
        .accessibilityText('测试节点2')
      Text('测试节点3')
        .accessibilityText('测试节点3')
      Button('关闭')
        .onClick(() => {
          this.cancel?.();
        })
        .margin(20)
        .accessibilityDescription('关闭弹窗按钮')
    }
  }
}