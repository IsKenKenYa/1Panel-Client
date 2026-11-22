@Entry
@Component
struct B25PageTwo {
  @StorageLink('b25Content') content: string = '';

  build() {
    Column({ space: 24 }) {
      Text(`${this.content}`)
        .fontSize(50)
      Button('back')
        .onClick(() => {
          this.getUIContext().getRouter().back();
        })
    }
  }
}
