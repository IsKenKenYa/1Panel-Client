import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct NearbySearchExample {
  @State currentLat: number = 39.9042;
  @State currentLng: number = 116.4074;
  @State searchRadius: number = 5000;
  @State searchResults: string = '';
  @State totalCount: number = 0;

  build() {
    Column() {
      Text('周边搜索示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Row() {
        Text('经度:')
          .fontSize(16)
          .width('20%');
        TextInput({ placeholder: '116.4074' })
          .width('30%')
          .height(40)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.currentLng = parseFloat(value);
          });
      }
      .width('80%')
      .margin({ bottom: 10 });

      Row() {
        Text('纬度:')
          .fontSize(16)
          .width('20%');
        TextInput({ placeholder: '39.9042' })
          .width('30%')
          .height(40)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.currentLat = parseFloat(value);
          });
      }
      .width('80%')
      .margin({ bottom: 10 });

      Row() {
        Text('半径(米):')
          .fontSize(16)
          .width('20%');
        TextInput({ placeholder: '5000' })
          .width('30%')
          .height(40)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.searchRadius = parseInt(value);
          });
      }
      .width('80%')
      .margin({ bottom: 20 });

      Button('周边搜索')
        .width('80%')
        .height(40)
        .onClick(async () => {
          await this.performNearbySearch();
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

  async performNearbySearch(): Promise<void> {
    let params: site.NearbySearchParams = {
      location: {
        latitude: this.currentLat,
        longitude: this.currentLng
      },
      radius: this.searchRadius,
      poiTypes: ['RESTAURANT', 'HOTEL', 'SCENIC_SPOT'],
      language: 'zh',
      pageSize: 20,
      pageIndex: 1,
      sortRule: site.SortRule.DISTANCE
    };

    try {
      const result = await site.nearbySearch(params);
      this.totalCount = result.totalCount;
      
      if (result.sites && result.sites.length > 0) {
        let output = '';
        result.sites.forEach((siteInfo, index) => {
          output += `地点 ${index + 1}:\n`;
          output += `  名称: ${siteInfo.name}\n`;
          output += `  地址: ${siteInfo.formatAddress}\n`;
          output += `  距离: ${siteInfo.distance} 米\n\n`;
        });
        this.searchResults = output;
      } else {
        this.searchResults = '周边未找到相关地点';
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.searchResults = `搜索失败: 错误码 ${err.code}, 错误信息 ${err.message}`;
    }
  }
}