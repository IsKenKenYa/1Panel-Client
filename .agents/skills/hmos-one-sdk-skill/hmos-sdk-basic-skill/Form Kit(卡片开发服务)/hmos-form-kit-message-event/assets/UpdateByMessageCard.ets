// entry/src/main/ets/updatebymessage/pages/UpdateByMessageCard.ets
// 卡片页面完整示例：使用postCardAction触发message事件

let storageUpdateByMsg = new LocalStorage();

@Entry(storageUpdateByMsg)
@Component
struct UpdateByMessageCard {
  // 使用LocalStorageProp装饰器绑定数据字段
  // 字段名需与FormExtensionAbility中formBindingData字段对应
  @LocalStorageProp('title') title: ResourceStr = $r('app.string.default_title');
  @LocalStorageProp('detail') detail: ResourceStr = $r('app.string.DescriptionDefault');
  @LocalStorageProp('updateTime') updateTime: ResourceStr = '未更新';

  build() {
    Column() {
      // 标题和详情区域
      Column() {
        Text(this.title)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .margin({ top: '8%', left: '10%' })
        
        Text(this.detail)
          .fontColor('#FFFFFF')
          .opacity(0.6)
          .fontSize(12)
          .margin({ top: '5%', left: '10%' })
        
        Text(this.updateTime)
          .fontColor('#FFFFFF')
          .opacity(0.4)
          .fontSize(10)
          .margin({ top: '3%', left: '10%' })
      }
      .width('100%')
      .height('50%')
      .alignItems(HorizontalAlign.Start)

      // 按钮区域
      Row() {
        Button() {
          Text($r('app.string.update'))
            .fontColor('#45A6F4')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
        }
        .width(120)
        .height(32)
        .margin({ top: '30%', bottom: '10%' })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          // 触发message事件，传递自定义参数
          postCardAction(this, {
            action: 'message',
            params: {
              msgTest: 'messageEvent',
              timestamp: Date.now()
            }
          });
        })
      }
      .width('100%')
      .height('40%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundImage($r('app.media.CardEvent'))
    .backgroundImageSize(ImageSize.Cover)
  }
}