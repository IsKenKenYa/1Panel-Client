import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SearchByIdExample {
  @State siteId: string = '144129739873977856';
  @State siteDetails: string = '';

  build() {
    Column() {
      Text('地点详情查询示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      TextInput({ placeholder: '请输入地点ID' })
        .width('80%')
        .height(40)
        .onChange((value: string) => {
          this.siteId = value;
        });

      Button('查询详情')
        .width('80%')
        .height(40)
        .onClick(async () => {
          await this.getSiteDetails();
        });

      Text(this.siteDetails)
        .fontSize(14)
        .margin({ top: 20 })
        .maxLines(30);
    }
    .width('100%')
    .height('100%');
  }

  async getSiteDetails(): Promise<void> {
    let params: site.SearchByIdParams = {
      siteId: this.siteId,
      language: 'zh',
      isChildren: true
    };

    try {
      const result = await site.searchById(params);
      
      if (result.site) {
        let output = '';
        output += `地点详情:\n`;
        output += `名称: ${result.site.name}\n`;
        output += `地址: ${result.site.formatAddress}\n`;
        output += `经纬度: (${result.site.location.latitude}, ${result.site.location.longitude})\n`;
        output += `地点ID: ${result.site.siteId}\n`;
        
        if (result.site.poi) {
          output += `\nPOI信息:\n`;
          output += `类型: ${result.site.poi.poiTypes?.join(', ')}\n`;
          
          if (result.site.poi.phone) {
            output += `电话: ${result.site.poi.phone}\n`;
          }
          
          if (result.site.poi.rating) {
            output += `评分: ${result.site.poi.rating}\n`;
          }
          
          if (result.site.poi.websiteUrl) {
            output += `网站: ${result.site.poi.websiteUrl}\n`;
          }
          
          if (result.site.poi.openingHours) {
            output += `营业时间:\n`;
            result.site.poi.openingHours.texts?.forEach(text => {
              output += `  ${text}\n`;
            });
          }
          
          if (result.site.poi.businessStatus) {
            output += `营业状态: ${result.site.poi.businessStatus}\n`;
          }
        }
        
        this.siteDetails = output;
      } else {
        this.siteDetails = '未找到地点信息';
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.siteDetails = `查询失败: 错误码 ${err.code}, 错误信息 ${err.message}`;
    }
  }
}