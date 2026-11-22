import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

class GeocodeErrorHandler {
  private static readonly MAX_RETRIES = 3;
  private static readonly RETRY_DELAY = 1000;

  async geocodeWithErrorHandling(address: string): Promise<site.GeocodeResult | null> {
    let retryCount = 0;

    while (retryCount < GeocodeErrorHandler.MAX_RETRIES) {
      try {
        if (!address || address.trim().length === 0) {
          throw new Error('地址不能为空');
        }

        if (address.length > 512) {
          throw new Error('地址长度不能超过512字符');
        }

        const params: site.GeocodeParams = {
          query: address.trim(),
          language: 'zh'
        };

        const result = await site.geocode(params);

        if (result && result.sites && result.sites.length > 0) {
          return result;
        }

        return null;
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        
        if (err.code === 1002600002) {
          retryCount++;
          console.warn(`网络错误，重试次数: ${retryCount}/${GeocodeErrorHandler.MAX_RETRIES}`);
          
          if (retryCount < GeocodeErrorHandler.MAX_RETRIES) {
            await this.delay(GeocodeErrorHandler.RETRY_DELAY * retryCount);
            continue;
          }
          
          console.error('网络错误重试失败，请检查网络连接');
          throw new Error('网络连接失败，请检查网络后重试');
        }

        if (err.code === 1002603001) {
          console.warn('未找到匹配地址');
          return null;
        }

        if (err.code === 401) {
          console.error('参数错误');
          throw new Error('输入参数无效，请检查地址格式');
        }

        if (err.code === 1002600003) {
          console.error('认证失败');
          throw new Error('应用认证失败，请检查应用配置');
        }

        if (err.code === 1002600004) {
          console.error('权限不足');
          throw new Error('地图权限未启用，请在设置中开启');
        }

        console.error(`未知错误: ${err.code}, ${err.message}`);
        throw error;
      }
    }

    return null;
  }

  async reverseGeocodeWithErrorHandling(
    latitude: number,
    longitude: number
  ): Promise<site.ReverseGeocodeResult | null> {
    try {
      if (latitude < -90 || latitude > 90) {
        throw new Error('纬度必须在-90到90之间');
      }

      if (longitude < -180 || longitude > 180) {
        throw new Error('经度必须在-180到180之间');
      }

      const params: site.ReverseGeocodeParams = {
        location: { latitude, longitude },
        language: 'zh',
        radius: 1000,
        isExtension: true,
        isNearbyAoi: true
      };

      const result = await site.reverseGeocode(params);
      return result;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      switch (err.code) {
        case 401:
          throw new Error('经纬度参数无效');
        case 1002600002:
          throw new Error('网络连接失败');
        case 1002600003:
          throw new Error('应用认证失败');
        case 1002600004:
          throw new Error('地图权限未启用');
        case 1002603001:
          return null;
        default:
          throw new Error(`逆地理编码失败: ${err.message}`);
      }
    }
  }

  async geocodeWithFallback(address: string): Promise<{ latitude: number; longitude: number } | null> {
    try {
      const result = await this.geocodeWithErrorHandling(address);
      
      if (result && result.sites && result.sites[0].location) {
        return {
          latitude: result.sites[0].location.latitude,
          longitude: result.sites[0].location.longitude
        };
      }
      
      return null;
    } catch (error) {
      console.error('地理编码失败，使用降级方案:', error);
      
      return await this.fallbackGeocode(address);
    }
  }

  private async fallbackGeocode(address: string): Promise<{ latitude: number; longitude: number } | null> {
    console.warn('降级方案：建议用户手动输入或选择位置');
    return null;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

@Entry
@Component
struct ErrorHandlingExample {
  @State address: string = '';
  @State latitude: string = '';
  @State longitude: string = '';
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  private errorHandler: GeocodeErrorHandler = new GeocodeErrorHandler();

  build() {
    Column() {
      Text('错误处理示例')
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

      Button('地理编码（带错误处理）')
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

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
          .margin({ top: 20 })
          .width('80%');
      }

      if (this.latitude && this.longitude) {
        Column() {
          Text('地理编码成功')
            .fontSize(18)
            .fontColor(Color.Green)
            .margin({ bottom: 10 });
          
          Row() {
            Text(`纬度: ${this.latitude}`)
              .fontSize(16)
              .margin({ right: 20 });
            Text(`经度: ${this.longitude}`)
              .fontSize(16);
          }
        }
        .margin({ top: 20 });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  async performGeocode(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    this.latitude = '';
    this.longitude = '';

    try {
      const location = await this.errorHandler.geocodeWithFallback(this.address);
      
      if (location) {
        this.latitude = location.latitude.toString();
        this.longitude = location.longitude.toString();
      } else {
        this.errorMessage = '未找到匹配地址，建议用户手动选择位置';
      }
    } catch (error) {
      this.errorMessage = error.message || '地理编码失败';
    } finally {
      this.isLoading = false;
    }
  }
}