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
    new CaseItem('B07 开关标签页', 'pages/B07CheckedAndTabs'),
    new CaseItem('B08 复选框页一', 'pages/B08Checkbox'),
    new CaseItem('B09 收藏页', 'pages/B09FavoriteIcon'),
    new CaseItem('B10 折线图页', 'pages/B10LineChart'),
    new CaseItem('B11 仪表盘页', 'pages/B11Dashboard'),
    new CaseItem('B13 卡片页', 'pages/B13FocusCard'),
    new CaseItem('B16 搜索页', 'pages/B16DefaultFocus'),
    new CaseItem('B20 质检页', 'pages/B20HoverText'),
    new CaseItem('B23 主题页', 'pages/B23ThemeList')
  ];

  build() {
    Column() {
      Text('Accessibility Demo（API 10）')
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
