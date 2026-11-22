import { RichEditor, RichEditorController, RichEditorOptions, RichEditorChangeValue } from '@ohos.arkui';

@Entry
@Component
struct RichEditorCrossDeviceBasic {
  controller: RichEditorController = new RichEditorController();
  options: RichEditorOptions = { controller: this.controller };

  build() {
    Column() {
      Column() {
        RichEditor(this.options)
          .onWillChange((value: RichEditorChangeValue) => {
            if (value?.replacedImageSpans[0]?.imageStyle?.objectFit != 0) {
              return true;
            }
            for (let item of value.replacedImageSpans) {
              this.controller.addImageSpan(item.valuePixelMap, {
                imageStyle: {
                  size: ['500px', '500px'],
                  layoutStyle: {
                    borderRadius: '10px'
                  }
                }
              });
            }
            return false;
          })
          .borderWidth(1)
          .borderColor(Color.Green)
          .width('100%')
          .height('100%')
      }
      .borderWidth(1)
      .borderColor(Color.Red)
      .width('100%')
      .height('70%')
    }
  }
}