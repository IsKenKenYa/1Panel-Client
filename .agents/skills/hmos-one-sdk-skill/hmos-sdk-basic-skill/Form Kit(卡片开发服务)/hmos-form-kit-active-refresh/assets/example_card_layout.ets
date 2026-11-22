// entry/src/main/ets/updatebymessage/pages/UpdateByMessageCard.ets
// 单个卡片主动刷新完整示例 - 卡片布局实现

import { postCardAction } from '@kit.ArkUI';

let storageUpdateByMsg = new LocalStorage();

@Entry(storageUpdateByMsg)
@Component
struct UpdateByMessageCard {
  // 卡片数据绑定属性，与FormExtensionAbility返回的数据对应
  @LocalStorageProp('title') title: ResourceStr = $r('app.string.default_title');
  @LocalStorageProp('detail') detail: ResourceStr = $r('app.string.DescriptionDefault');
  @LocalStorageProp('temperature') temperature: ResourceStr = '22c';
  @LocalStorageProp('updateTime') updateTime: ResourceStr = '12:00';

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
        
        // 温度和时间信息
        Row() {
          Text(`Temperature: ${this.temperature}`)
            .fontColor('#FFFFFF')
            .opacity(0.7)
            .fontSize(11)
          
          Text(`Time: ${this.updateTime}`)
            .fontColor('#FFFFFF')
            .opacity(0.7)
            .fontSize(11)
            .margin({ left: '10%' })
        }
        .width('80%')
        .margin({ top: '5%', left: '10%' })
      }
      .width('100%')
      .height('50%')
      .alignItems(HorizontalAlign.Start)

      // 刷新按钮区域
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
          // 触发message事件，调用FormExtensionAbility的onFormEvent回调
          postCardAction(this, {
            action: 'message',
            params: {
              msgTest: 'messageEvent',
              actionType: 'refresh'
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

// 资源文件 string.json 示例
// entry/src/main/resources/base/element/string.json
/*
{
  "string": [
    {
      "name": "default_title",
      "value": "Weather Card"
    },
    {
      "name": "DescriptionDefault",
      "value": "Default weather information"
    },
    {
      "name": "update",
      "value": "Refresh"
    }
  ]
}
*/