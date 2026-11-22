import { NavDestination } from '@kit.ArkUI';

@Entry
@Component
export struct ListItemExample {
  build() {
    NavDestination() {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center,
      }) {
        Column() {
          ListItemComponent({
            title: 'Video card',
            subtitle: 'provided with options',
            time: '1:23 hrs',
            color: '#ffdee5ff'
          })
          ListItemComponent({
            title: 'Music card',
            subtitle: 'sound feedback available',
            time: '2:75 min',
            color: '#92e1ffd8'
          })
          ListItemComponent({
            title: 'Live card',
            subtitle: 'health support on request',
            time: '10:55',
            color: '#fff3deff'
          })
          ListItemComponent({
            title: 'Play card',
            subtitle: 'play station tournament',
            time: '5:12 hrs',
            color: '#92e1ffd8'
          })
          ListItemComponent({
            title: 'Theater card',
            subtitle: 'ticket on concert',
            time: '2:75 min',
            color: '#ffdee5ff'
          })
        }
      }
    }.title('列表播报示例')
  }
}

@Component
export struct ListItemComponent {
  title: string = 'Video card';
  subtitle: string = 'provided with additional options';
  time: string = '1:23 hr';
  color: ResourceColor = "#80FAFAFA";
  
  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.SpaceBetween,
    }) {
      Column() {
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .padding({ left: 20, right: 0 })
        
        Text(this.subtitle)
          .fontSize(14)
          .fontColor(Color.Gray)
          .fontWeight(FontWeight.Normal)
          .textAlign(TextAlign.Center)
          .padding({ left: 20, right: 0 })
      }
      
      Column() {
        Text(this.time)
          .fontSize(20)
          .fontWeight(FontWeight.Normal)
          .textAlign(TextAlign.Center)
          .padding({ left: 10, right: 10 })
      }
      
      Column() {
        Image($r("sys.media.ohos_ic_public_arrow_right"))
          .width(28)
          .height(28)
          .fillColor(Color.Gray)
      }
      .align(Alignment.End)
    }
    .width('90%')
    .height(75)
    .border({
      width: 1,
      color: '#FFC0C0C0',
      radius: 8,
      style: {
        top: BorderStyle.Solid,
      }
    })
    .backgroundColor(this.color)
    .accessibilityGroup(true)
    .accessibilityLevel("yes")
    .margin({ top: 10 })
  }
}