import { router } from '@kit.ArkUI';

class CaseItem {
  title: string;
  url: string;

  constructor(title: string, url: string) {
    this.title = title;
    this.url = url;
  }
}

@Entry
@Component
struct Index {
  private caseList: CaseItem[] = [
    new CaseItem('B01 设置页', 'pages/B01DefaultAdapt'),
    new CaseItem('B02 播放图标页', 'pages/B02PlayIcon'),
    new CaseItem('B03 提交订单页', 'pages/B03SubmitOrder'),
    new CaseItem('B04 全屏按钮页', 'pages/B04FullScreen'),
    new CaseItem('B05 日期页', 'pages/B05DateGroup'),
    new CaseItem('B06 页头页', 'pages/B06DecorHeader'),
    new CaseItem('B07 开关标签页', 'pages/B07CheckedAndTabs'),
    new CaseItem('B08 复选框页一', 'pages/B08Checkbox'),
    new CaseItem('B09 收藏页', 'pages/B09FavoriteIcon'),
    new CaseItem('B10 折线图页', 'pages/B10LineChart'),
    new CaseItem('B11 仪表盘页', 'pages/B11Dashboard'),
    new CaseItem('B12 播放器页', 'pages/Player'),
    new CaseItem('B13 卡片页', 'pages/B13FocusCard'),
    new CaseItem('B14 生日页', 'pages/B14Birthday'),
    new CaseItem('B15 订单按钮页', 'pages/B15OverrideQuery'),
    new CaseItem('B16 搜索页', 'pages/B16DefaultFocus'),
    new CaseItem('B17 注册页', 'pages/B17NextFocus'),
    new CaseItem('B18 会员卡页', 'pages/B18NextFocusChild'),
    new CaseItem('B19 流程页', 'pages/B19NextFocusSkipChild'),
    new CaseItem('B20 质检页', 'pages/B20HoverText'),
    new CaseItem('B21 点赞页', 'pages/B21IconAction'),
    new CaseItem('B22 商品页', 'pages/B22ProductCard'),
    new CaseItem('B23 主题页', 'pages/B23ThemeList')
  ];

  build() {
    Column() {
      Text('Accessibility Demo')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 12 })
      List({ space: 8 }) {
        ForEach(this.caseList, (item: CaseItem) => {
          ListItem() {
            Text(item.title)
              .fontSize(16)
              .width('100%')
              .padding(12)
              .borderRadius(8)
              .backgroundColor('#f1f3f5')
              .onClick(() => {
                router.pushUrl({ url: item.url });
              })
          }
        }, (item: CaseItem) => item.url)
      }
      .width('92%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
