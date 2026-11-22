import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ReverseGeocodeExample {
  @State latitudeInput: string = '31.984410';
  @State longitudeInput: string = '118.766253';
  @State addressDescription: string = '';
  @State poiInfo: string = '';
  @State resultMessage: string = '';
  @State isLoading: boolean = false;

  build() {
    Column() {
      Text('逆地理编码示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      TextInput({ placeholder: '请输入纬度', text: this.latitudeInput })
        .width('80%')
        .height(50)
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.latitudeInput = value;
        });

      TextInput({ placeholder: '请输入经度', text: this.longitudeInput })
        .width('80%')
        .height(50)
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.longitudeInput = value;
        });

      Button('开始逆地理编码')
        .width('80%')
        .height(50)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.performReverseGeocode();
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

      if (this.addressDescription) {
        Text(`地址描述: ${this.addressDescription}`)
          .fontSize(16)
          .margin({ top: 10 })
          .width('80%');
      }

      if (this.poiInfo) {
        Text(this.poiInfo)
          .fontSize(14)
          .margin({ top: 10 })
          .width('80%');
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  async performReverseGeocode(): Promise<void> {
    this.isLoading = true;
    this.resultMessage = '';
    this.addressDescription = '';
    this.poiInfo = '';

    try {
      const latitude = parseFloat(this.latitudeInput);
      const longitude = parseFloat(this.longitudeInput);

      if (isNaN(latitude) || isNaN(longitude)) {
        this.resultMessage = '请输入有效的经纬度数值';
        this.isLoading = false;
        return;
      }

      if (latitude < -90 || latitude > 90) {
        this.resultMessage = '纬度必须在-90到90之间';
        this.isLoading = false;
        return;
      }

      if (longitude < -180 || longitude > 180) {
        this.resultMessage = '经度必须在-180到180之间';
        this.isLoading = false;
        return;
      }

      const params: site.ReverseGeocodeParams = {
        location: {
          latitude: latitude,
          longitude: longitude
        },
        language: 'zh',
        radius: 1000,
        isExtension: true,
        isNearbyAoi: true
      };

      const result: site.ReverseGeocodeResult = await site.reverseGeocode(params);

      this.addressDescription = result.addressDescription;

      if (result.pois && result.pois.length > 0) {
        this.poiInfo = `周边POI(${result.pois.length}个):\n`;
        result.pois.slice(0, 5).forEach((poi, index) => {
          this.poiInfo += `${index + 1}. ${poi.name} - ${poi.distance}米\n`;
        });
      }

      if (result.aois && result.aois.length > 0) {
        this.poiInfo += `\n周边AOI(${result.aois.length}个):\n`;
        result.aois.slice(0, 3).forEach((aoi, index) => {
          this.poiInfo += `${index + 1}. ${aoi.name}\n`;
        });
      }

      this.resultMessage = '逆地理编码成功';
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.resultMessage = `逆地理编码失败: ${this.getErrorMessage(err.code)}`;
    } finally {
      this.isLoading = false;
    }
  }

  getErrorMessage(code: number): string {
    switch (code) {
      case 401:
        return '参数错误，请检查经纬度格式';
      case 1002600001:
        return '系统内部错误，请稍后重试';
      case 1002600002:
        return '网络错误，请检查网络连接';
      case 1002600003:
        return '应用认证失败';
      case 1002600004:
        return '地图权限未启用';
      case 1002603001:
        return '该位置不在服务范围内';
      default:
        return `未知错误(${code})`;
    }
  }
}