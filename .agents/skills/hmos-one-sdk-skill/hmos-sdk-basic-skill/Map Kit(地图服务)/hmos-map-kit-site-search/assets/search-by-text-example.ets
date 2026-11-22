import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SearchByTextExample {
  @State searchQuery: string = '故宫';
  @State searchResults: string = '';
  @State totalCount: number = 0;

  build() {
    Column() {
      Text('关键字搜索示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      TextInput({ placeholder: '请输入搜索关键字' })
        .width('80%')
        .height(40)
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.searchQuery = value;
        });

      Button('搜索')
        .width('80%')
        .height(40)
        .onClick(async () => {
          await this.performSearch();
        });

      Text(`搜索结果总数: ${this.totalCount}`)
        .fontSize(16)
        .margin({ top: 20 });

      Text(this.searchResults)
        .fontSize(14)
        .margin({ top: 10 })
        .maxLines(20);
    }
    .width('100%')
    .height('100%');
  }

  async performSearch(): Promise<void> {
    let params: site.SearchByTextParams = {
      query: this.searchQuery,
      location: {
        latitude: 39.9042,
        longitude: 116.4074
      },
      radius: 10000,
      language: 'zh',
      pageSize: 20,
      pageIndex: 1
    };

    try {
      const result = await site.searchByText(params);
      this.totalCount = result.totalCount;
      
      if (result.sites && result.sites.length > 0) {
        let output = '';
        result.sites.forEach((siteInfo, index) => {
          output += `地点 ${index + 1}:\n`;
          output += `  名称: ${siteInfo.name}\n`;
          output += `  地址: ${siteInfo.formatAddress}\n`;
          output += `  经纬度: (${siteInfo.location.latitude}, ${siteInfo.location.longitude})\n`;
          output += `  距离: ${siteInfo.distance} 米\n\n`;
        });
        this.searchResults = output;
      } else {
        this.searchResults = '未找到搜索结果';
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.searchResults = `搜索失败: 错误码 ${err.code}, 错误信息 ${err.message}`;
    }
  }
}