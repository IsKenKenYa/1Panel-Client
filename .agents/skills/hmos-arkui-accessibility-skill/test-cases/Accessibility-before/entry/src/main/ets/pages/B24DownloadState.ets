@Entry
@Component
struct B24DownloadState {
  @State isDownloading: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text(this.isDownloading ? '文件已下载' : '下载文件')
        .onClick(() => {
          // 下载文件操作
        })

      Button('修改下载状态')
        .onClick(() => {
          this.isDownloading = this.isDownloading ? false : true;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
