import { RichEditor, RichEditorController, RichEditorOptions, RichEditorChangeValue, PixelMap } from '@ohos.arkui';

@Entry
@Component
struct RichEditorErrorHandling {
  controller: RichEditorController = new RichEditorController();
  options: RichEditorOptions = { controller: this.controller };

  private handleImageFallback(pixelMap: PixelMap | undefined): void {
    if (!pixelMap) {
      console.warn('No image data, using default placeholder');
      return;
    }

    try {
      this.controller.addImageSpan(pixelMap, {
        imageStyle: {
          size: ['100px', '100px'],
          layoutStyle: {
            borderRadius: '5px'
          }
        }
      });
    } catch (error) {
      console.error('Failed to add image span:', error.message);
    }
  }

  build() {
    Column() {
      RichEditor(this.options)
        .onWillChange((value: RichEditorChangeValue) => {
          try {
            if (!value) {
              console.warn('Invalid RichEditorChangeValue received');
              return true;
            }

            if (!value.replacedImageSpans) {
              console.warn('No replacedImageSpans in RichEditorChangeValue');
              return true;
            }

            if (value.replacedImageSpans.length === 0) {
              console.warn('No image spans to process');
              return true;
            }

            if (value.replacedImageSpans[0]?.imageStyle?.objectFit != 0) {
              return true;
            }

            for (let item of value.replacedImageSpans) {
              if (!item.valuePixelMap) {
                console.error('Missing PixelMap data');
                continue;
              }

              try {
                this.controller.addImageSpan(item.valuePixelMap, {
                  imageStyle: {
                    size: ['500px', '500px'],
                    layoutStyle: {
                      borderRadius: '10px'
                    }
                  }
                });
              } catch (addError) {
                console.error('Error adding image span:', addError.message);
                this.handleImageFallback(item.valuePixelMap);
              }
            }
            return false;
          } catch (error) {
            console.error('Error processing cross-device image:', error.message);
            return true;
          }
        })
        .borderWidth(1)
        .borderColor(Color.Green)
        .width('100%')
        .height('100%')
    }
  }
}