@Entry
@Component
struct B10LineChart {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private data: number[] = [30, 58, 42, 80, 65, 92, 74];

  build() {
    Column({ space: 24 }) {
      Text('B10 Canvas 折线图')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Canvas(this.context)
        .width('90%')
        .height(260)
        .backgroundColor('#f1f2f3')
        .onReady(() => {
          this.context.lineWidth = 3;
          this.context.strokeStyle = '#007dfe';
          this.context.beginPath();
          for (let i = 0; i < this.data.length; i++) {
            let x: number = 24 + i * 44;
            let y: number = 230 - this.data[i] * 2;
            if (i === 0) {
              this.context.moveTo(x, y);
            } else {
              this.context.lineTo(x, y);
            }
          }
          this.context.stroke();
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
