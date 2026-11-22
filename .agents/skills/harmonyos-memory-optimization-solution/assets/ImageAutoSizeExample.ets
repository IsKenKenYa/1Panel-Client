// 以下示例展示从相册选择图片并使用 autoResize 进行降采样显示：

import { BusinessError } from "@kit.BasicServicesKit";
import { image } from "@kit.ImageKit";
import { fileIo } from "@kit.CoreFileKit";
import { photoAccessHelper } from "@kit.MediaLibraryKit";

@Component
export struct UseAutoResizeToDownsampleTheImageComponent {
  @State imageUrl: image.PixelMap | undefined = undefined;

  build() {
    NavDestination() {
      Column() {
        Image(this.imageUrl)
          .width(300)
          .height(200)
          .autoResize(true)

        Button('Select image').onClick(() => {
          try {
            // Select album images.
            let uris: Array<string> = [];
            let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
            PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
            PhotoSelectOptions.maxSelectNumber = 1;
            let photoPicker = new photoAccessHelper.PhotoViewPicker();
            photoPicker.select(PhotoSelectOptions).then((PhotoSelectResult: photoAccessHelper.PhotoSelectResult) => {
              uris = PhotoSelectResult.photoUris;
              let file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_ONLY);
              console.info('file fd: ' + file.fd);
              let buffer = new ArrayBuffer(4096);
              let readLen = fileIo.readSync(file.fd, buffer);
              console.info('readSync data to file succeed and buffer size is:' + readLen);
              const imageSource: image.ImageSource = image.createImageSource(file.fd);
              let decodingOptions: image.DecodingOptions = {
                editable: true,
                desiredPixelFormat: 3
              }
              imageSource.createPixelMap(decodingOptions).then((pixelMap: image.PixelMap) => {
                console.info('Succeeded in creating pixelMap object through image decoding parameters.');
                this.imageUrl = pixelMap;
              }).catch((error: BusinessError) => {
                console.error(`Failed to create pixelMap object through image decoding parameters, error.code ${error.code}, error.message ${error.message}`);
              })
            }).catch((err: BusinessError) => {
              console.error(`Invoke photoPicker.select failed, code is ${err.code}, message is ${err.message}`);
            })
          } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error('photoPicker failed with err: ' + JSON.stringify(err));
          }
        })
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor('#F1F3F5')
  }
}