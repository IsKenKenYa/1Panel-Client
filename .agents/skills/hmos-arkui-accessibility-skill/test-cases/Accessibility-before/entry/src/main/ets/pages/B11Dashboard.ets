@Entry
@Component
struct B11Dashboard {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Column({ space: 24 }) {
      Text('B11 自绘仪表盘')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Canvas(this.context)
        .width(320)
        .height(300)
        .backgroundColor('#f1f2f3')
        .onReady(() => {
          this.context.lineWidth = 14;
          this.context.strokeStyle = '#e0e0e0';
          this.context.beginPath();
          this.context.arc(160, 150, 100, Math.PI * 0.75, Math.PI * 2.25);
          this.context.stroke();
          this.context.lineWidth = 14;
          this.context.strokeStyle = '#007dfe';
          this.context.beginPath();
          this.context.arc(160, 150, 100, Math.PI * 0.75, Math.PI * 1.45);
          this.context.stroke();
          this.context.fillStyle = '#333333';
          this.context.font = '32px sans-serif';
          this.context.fillText('2450 rpm', 108, 165);
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
