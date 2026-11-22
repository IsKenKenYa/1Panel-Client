/**
 * 示例2：列表项多元素组合播报
 * 功能：将列表项中的标题、描述、时长、图标组合为一个焦点
 * 适用场景：视频列表、音乐列表、直播列表等
 */

@Entry
@Component
export struct ListItemGroupExample {
  title: string = '列表项组合播报示例';
  
  build() {
    NavDestination() {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center,
      }) {
        Column() {
          // 列表项1：视频卡片
          ListItemComponent({
            title: 'Video card',
            subtitle: 'provided with options',
            duration: '1:23 hrs',
            color: '#ffdee5ff'
          })
          
          // 列表项2：音乐卡片
          ListItemComponent({
            title: 'Music card',
            subtitle: 'sound feedback available',
            duration: '2:75 min',
            color: '#92e1ffd8'
          })
          
          // 列表项3：直播卡片
          ListItemComponent({
            title: 'Live card',
            subtitle: 'health support on request',
            duration: '10:55',
            color: '#fff3deff'
          })
          
          // 列表项4：播放卡片
          ListItemComponent({
            title: 'Play card',
            subtitle: 'play station tournament',
            duration: '5:12 hrs',
            color: '#92e1ffd8'
          })
          
          // 列表项5：影院卡片
          ListItemComponent({
            title: 'Theater card',
            subtitle: 'ticket on concert',
            duration: '2:75 min',
            color: '#ffdee5ff'
          })
        }
      }
    }.title(this.title)
  }
}

/**
 * 列表项组件定义
 * 将标题、副标题、时长、箭头图标组合为一个焦点
 */
@Component
export struct ListItemComponent {
  @Prop title: string = 'Video card';
  @Prop subtitle: string = 'provided with additional options';
  @Prop duration: string = '1:23 hr';
  @Prop color: ResourceColor = "#80FAFAFA";
  
  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.SpaceBetween,
    }) {
      // 左侧：标题和副标题
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
      
      // 中间：时长信息
      Column() {
        Text(this.duration)
          .fontSize(20)
          .fontWeight(FontWeight.Normal)
          .textAlign(TextAlign.Center)
          .padding({ left: 10, right: 10 })
      }
      
      // 右侧：箭头图标
      Column() {
        Image($r("sys.media.ohos_ic_public_arrow_right"))
          .width(28)
          .height(28)
          .fillColor(Color.Gray)
          .alt('详情') // 图片无障碍文本
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
    .accessibilityGroup(true) // 核心设置：将标题、描述、时长、图标合并为单个对象
    .accessibilityLevel("yes") // 确保可被屏幕朗读识别
    // 播报效果：自动拼接为 "Video card, provided with additional options, 1:23 hr"
    .margin({ top: 10 })
  }
}

/**
 * 使用说明：
 * 1. accessibilityGroup(true)：将整个Flex布局中的元素组合为一个整体
 * 2. 屏幕朗读选中时会自动拼接播报：
 *    "Video card, provided with additional options, 1:23 hr"
 * 3. 图片的alt属性("详情")也会被拼接在播报内容中
 * 4. 适用于各类列表场景：视频列表、音乐列表、直播列表等
 */