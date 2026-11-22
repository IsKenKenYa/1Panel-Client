import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class GeocodeDemo {
  private static instance: GeocodeDemo;
  
  private constructor() {}
  
  static getInstance(): GeocodeDemo {
    if (!GeocodeDemo.instance) {
      GeocodeDemo.instance = new GeocodeDemo();
    }
    return GeocodeDemo.instance;
  }
  
  checkGeocoderService(): boolean {
    try {
      let isAvailable = geoLocationManager.isGeocoderAvailable();
      if (!isAvailable) {
        console.warn('地理编码服务不可用，请检查设备是否联网');
        return false;
      }
      console.info('地理编码服务可用');
      return true;
    } catch (err) {
      console.error('检查地理编码服务状态失败: errCode=' + err.code + ', message=' + err.message);
      return false;
    }
  }
  
  async reverseGeocode(
    latitude: number,
    longitude: number,
    maxItems: number = 1
  ): Promise<Array<geoLocationManager.GeoAddress> | null> {
    if (!this.checkGeocoderService()) {
      return null;
    }
    
    if (!this.validateCoordinates(latitude, longitude)) {
      return null;
    }
    
    if (maxItems < 0) {
      console.error('maxItems参数错误，取值范围应大于等于0');
      return null;
    }
    
    let reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
      latitude: latitude,
      longitude: longitude,
      maxItems: maxItems,
      locale: 'zh'
    };
    
    try {
      const addresses = await geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest);
      console.info('逆地理编码成功，结果数量: ' + addresses.length);
      return addresses;
    } catch (error) {
      let businessError = error as BusinessError;
      console.error('逆地理编码失败: errCode=' + businessError.code + ', message=' + businessError.message);
      this.handleGeocodeError(businessError.code);
      return null;
    }
  }
  
  async geocode(
    addressDescription: string,
    maxItems: number = 1,
    range?: {
      minLat: number;
      minLon: number;
      maxLat: number;
      maxLon: number;
    }
  ): Promise<Array<geoLocationManager.GeoAddress> | null> {
    if (!this.checkGeocoderService()) {
      return null;
    }
    
    if (!this.validateAddressDescription(addressDescription)) {
      return null;
    }
    
    if (maxItems < 0) {
      console.error('maxItems参数错误，取值范围应大于等于0');
      return null;
    }
    
    let geocodeRequest: geoLocationManager.GeoCodeRequest = {
      description: addressDescription,
      maxItems: maxItems,
      locale: 'zh'
    };
    
    if (range) {
      if (!this.validateCoordinates(range.minLat, range.minLon) ||
          !this.validateCoordinates(range.maxLat, range.maxLon)) {
        return null;
      }
      
      if (range.minLat > range.maxLat || range.minLon > range.maxLon) {
        console.error('经纬度范围参数错误，最小值应小于最大值');
        return null;
      }
      
      geocodeRequest.minLatitude = range.minLat;
      geocodeRequest.minLongitude = range.minLon;
      geocodeRequest.maxLatitude = range.maxLat;
      geocodeRequest.maxLongitude = range.maxLon;
    }
    
    try {
      const addresses = await geoLocationManager.getAddressesFromLocationName(geocodeRequest);
      console.info('正地理编码成功，找到' + addresses.length + '个匹配地址');
      return addresses;
    } catch (error) {
      let businessError = error as BusinessError;
      console.error('正地理编码失败: errCode=' + businessError.code + ', message=' + businessError.message);
      this.handleGeocodeError(businessError.code);
      return null;
    }
  }
  
  async geocodeWithRetry(
    addressDescription: string,
    maxItems: number = 1,
    maxRetries: number = 3
  ): Promise<Array<geoLocationManager.GeoAddress> | null> {
    let retryCount = 0;
    
    while (retryCount < maxRetries) {
      const addresses = await this.geocode(addressDescription, maxItems);
      if (addresses && addresses.length > 0) {
        return addresses;
      }
      
      retryCount++;
      console.warn(`第${retryCount}次尝试失败，正在重试...`);
      if (retryCount < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
    
    console.error('重试' + maxRetries + '次后仍然失败，请检查网络连接');
    return null;
  }
  
  private validateCoordinates(latitude: number, longitude: number): boolean {
    if (latitude < -90 || latitude > 90) {
      console.error('纬度参数错误，取值范围应为-90到90');
      return false;
    }
    
    if (longitude < -180 || longitude > 180) {
      console.error('经度参数错误，取值范围应为-180到180');
      return false;
    }
    
    return true;
  }
  
  private validateAddressDescription(description: string): boolean {
    if (!description || description.trim().length === 0) {
      console.error('地址描述不能为空');
      return false;
    }
    
    if (description.length > 100) {
      console.error('地址描述过长，最大长度100字符，当前长度: ' + description.length);
      return false;
    }
    
    return true;
  }
  
  private handleGeocodeError(errorCode: number): string {
    let errorMsg = '';
    switch (errorCode) {
      case 401:
        errorMsg = '参数错误，请检查参数类型和取值范围';
        break;
      case 801:
        errorMsg = '设备不支持地理编码功能，建议使用真机验证';
        break;
      case 3301000:
        errorMsg = '位置服务不可用，请检查位置服务是否正常';
        break;
      case 3301300:
        errorMsg = '逆地理编码查询失败，请检查网络连接或使用真机验证';
        break;
      case 3301400:
        errorMsg = '正地理编码查询失败，请检查地址描述参数或网络连接';
        break;
      default:
        errorMsg = '未知错误，错误码: ' + errorCode;
        break;
    }
    console.error('错误处理: ' + errorMsg);
    return errorMsg;
  }
  
  printAddressInfo(address: geoLocationManager.GeoAddress, index: number): void {
    console.info(`地址${index + 1}:`);
    console.info(`  经纬度: (${address.latitude}, ${address.longitude})`);
    if (address.countryName) {
      console.info(`  国家: ${address.countryName}`);
    }
    if (address.administrativeArea) {
      console.info(`  省份: ${address.administrativeArea}`);
    }
    if (address.locality) {
      console.info(`  城市: ${address.locality}`);
    }
    if (address.subLocality) {
      console.info(`  区县: ${address.subLocality}`);
    }
    if (address.roadName) {
      console.info(`  街道: ${address.roadName}`);
    }
    if (address.placeName) {
      console.info(`  详细地址: ${address.placeName}`);
    }
  }
}

export async function runDemo(): Promise<void> {
  console.info('=== 地理编码演示程序 ===');
  
  const demo = GeocodeDemo.getInstance();
  
  console.info('\n=== 测试1：逆地理编码 ===');
  const reverseAddresses = await demo.reverseGeocode(31.12, 121.11, 1);
  if (reverseAddresses) {
    reverseAddresses.forEach((addr, idx) => demo.printAddressInfo(addr, idx));
  }
  
  console.info('\n=== 测试2：正地理编码 ===');
  const geocodeAddresses = await demo.geocode('上海市浦东新区陆家嘴', 1);
  if (geocodeAddresses) {
    geocodeAddresses.forEach((addr, idx) => demo.printAddressInfo(addr, idx));
  }
  
  console.info('\n=== 测试3：正地理编码（带范围限制） ===');
  const geocodeRangeAddresses = await demo.geocode('陆家嘴', 1, {
    minLat: 30.0,
    minLon: 120.0,
    maxLat: 32.0,
    maxLon: 122.0
  });
  if (geocodeRangeAddresses) {
    geocodeRangeAddresses.forEach((addr, idx) => demo.printAddressInfo(addr, idx));
  }
  
  console.info('\n=== 测试4：正地理编码（带重试机制） ===');
  const geocodeRetryAddresses = await demo.geocodeWithRetry('上海市浦东新区', 1, 3);
  if (geocodeRetryAddresses) {
    geocodeRetryAddresses.forEach((addr, idx) => demo.printAddressInfo(addr, idx));
  }
  
  console.info('\n演示程序完成');
}