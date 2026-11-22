import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct GeocodeExample {
  @State address: string = '北京市海淀区中关村';
  @State latitude: string = '';
  @State longitude: string = '';
  @State resultMessage: string = '';
  @State isLoading: boolean = false;

  build() {
    Column() {
      Text('地理编码示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      TextInput({ placeholder: '请输入地址' })
        .width('80%')
        .height(50)
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.address = value;
        });

      Button('开始地理编码')
        .width('80%')
        .height(50)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.performGeocode();
        });

      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 20 });
      }

      Text(this.resultMessage)
        .fontSize(16)
        .margin({ top: 20 })
        .width('80%');

      if (this.latitude && this.longitude) {
        Row() {
          Text(`纬度: ${this.latitude}`)
            .fontSize(16)
            .margin({ right: 20 });
          Text(`经度: ${this.longitude}`)
            .fontSize(16);
        }
        .margin({ top: 10 });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  async performGeocode(): Promise<void> {
    this.isLoading = true;
    this.resultMessage = '';
    this.latitude = '';
    this.longitude = '';

    try {
      if (!this.address || this.address.trim().length === 0) {
        this.resultMessage = '请输入有效的地址';
        this.isLoading = false;
        return;
      }

      if (this.address.length > 512) {
        this.resultMessage = '地址长度不能超过512字符';
        this.isLoading = false;
        return;
      }

      const params: site.GeocodeParams = {
        query: this.address.trim(),
        language: 'zh'
      };

      const result: site.GeocodeResult = await site.geocode(params);

      if (result && result.sites && result.sites.length > 0) {
        const firstSite = result.sites[0];
        this.latitude = firstSite.location?.latitude?.toString() || '';
        this.longitude = firstSite.location?.longitude?.toString() || '';
        this.resultMessage = `找到${result.sites.length}个结果:\n地址: ${firstSite.formatAddress || firstSite.name}`;
      } else {
        this.resultMessage = '未找到匹配的地址，请尝试修改地址描述';
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.resultMessage = `地理编码失败: ${this.getErrorMessage(err.code)}`;
    } finally {
      this.isLoading = false;
    }
  }

  getErrorMessage(code: number): string {
    switch (code) {
      case 401:
        return '参数错误，请检查地址格式';
      case 1002600001:
        return '系统内部错误，请稍后重试';
      case 1002600002:
        return '网络错误，请检查网络连接';
      case 1002600003:
        return '应用认证失败';
      case 1002600004:
        return '地图权限未启用';
      case 1002603001:
        return '未找到匹配地址';
      default:
        return `未知错误(${code})`;
    }
  }
}