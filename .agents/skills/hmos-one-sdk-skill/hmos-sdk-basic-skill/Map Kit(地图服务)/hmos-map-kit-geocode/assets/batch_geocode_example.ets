import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

class GeocodeService {
  private static readonly MAX_RETRIES = 3;
  private static readonly RETRY_DELAY = 1000;

  async geocodeWithRetry(
    address: string,
    language?: string,
    retries: number = GeocodeService.MAX_RETRIES
  ): Promise<site.GeocodeResult | null> {
    try {
      const params: site.GeocodeParams = {
        query: address,
        language: language || 'zh'
      };

      return await site.geocode(params);
    } catch (error) {
      const err: BusinessError = error as BusinessError;

      if (err.code === 1002600002 && retries > 0) {
        console.warn(`网络错误，${GeocodeService.RETRY_DELAY}ms后重试，剩余重试次数: ${retries}`);
        await this.delay(GeocodeService.RETRY_DELAY);
        return this.geocodeWithRetry(address, language, retries - 1);
      }

      if (err.code === 1002603001) {
        console.warn('未找到匹配地址');
        return null;
      }

      throw error;
    }
  }

  async batchGeocode(
    addresses: string[],
    language?: string,
    delayBetweenRequests: number = 200
  ): Promise<Map<string, site.GeocodeResult | null>> {
    const results = new Map<string, site.GeocodeResult | null>();

    for (const address of addresses) {
      try {
        const result = await this.geocodeWithRetry(address, language);
        results.set(address, result);

        if (addresses.indexOf(address) < addresses.length - 1) {
          await this.delay(delayBetweenRequests);
        }
      } catch (error) {
        console.error(`地址 "${address}" 编码失败:`, error);
        results.set(address, null);
      }
    }

    return results;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

@Entry
@Component
struct BatchGeocodeExample {
  @State addressList: string[] = [
    '北京市海淀区中关村',
    '上海市浦东新区陆家嘴',
    '广州市天河区珠江新城'
  ];
  @State results: string = '';
  @State isLoading: boolean = false;

  private geocodeService: GeocodeService = new GeocodeService();

  build() {
    Column() {
      Text('批量地理编码示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      List() {
        ForEach(this.addressList, (address: string, index: number) => {
          ListItem() {
            Row() {
              Text(`${index + 1}. ${address}`)
                .fontSize(16)
                .width('70%');
              
              Button('删除')
                .fontSize(14)
                .width('30%')
                .onClick(() => {
                  this.addressList.splice(index, 1);
                });
            }
            .width('80%')
            .height(50)
            .margin({ bottom: 5 });
          }
        });
      }
      .width('80%')
      .height(200);

      Row() {
        TextInput({ placeholder: '添加新地址' })
          .width('60%')
          .height(40)
          .margin({ right: 10 });
        
        Button('添加')
          .width('20%')
          .height(40)
          .onClick(() => {
            if (this.addressList.length < 10) {
              this.addressList.push('新地址');
            }
          });
      }
      .width('80%')
      .margin({ top: 10, bottom: 20 });

      Button('开始批量编码')
        .width('80%')
        .height(50)
        .enabled(!this.isLoading && this.addressList.length > 0)
        .onClick(() => {
          this.performBatchGeocode();
        });

      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 20 });
      }

      Text(this.results)
        .fontSize(14)
        .margin({ top: 20 })
        .width('80%');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start);
  }

  async performBatchGeocode(): Promise<void> {
    this.isLoading = true;
    this.results = '正在批量地理编码...';

    try {
      const resultMap = await this.geocodeService.batchGeocode(this.addressList, 'zh');

      this.results = '批量地理编码完成:\n\n';
      let successCount = 0;
      let failCount = 0;

      resultMap.forEach((result, address) => {
        if (result && result.sites && result.sites.length > 0) {
          const site = result.sites[0];
          this.results += `${address}: ${site.location?.latitude}, ${site.location?.longitude}\n`;
          successCount++;
        } else {
          this.results += `${address}: 失败\n`;
          failCount++;
        }
      });

      this.results += `\n成功: ${successCount}个，失败: ${failCount}个`;
    } catch (error) {
      this.results = `批量地理编码失败: ${error}`;
    } finally {
      this.isLoading = false;
    }
  }
}