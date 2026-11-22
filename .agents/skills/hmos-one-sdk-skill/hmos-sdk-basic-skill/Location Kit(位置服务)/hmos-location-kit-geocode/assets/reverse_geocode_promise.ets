import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function checkGeocoderService(): boolean {
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

async function reverseGeocodeWithPromise(
  latitude: number,
  longitude: number,
  maxItems: number = 1
): Promise<Array<geoLocationManager.GeoAddress> | null> {
  if (!checkGeocoderService()) {
    return null;
  }

  if (latitude < -90 || latitude > 90) {
    console.error('纬度参数错误，取值范围应为-90到90');
    return null;
  }

  if (longitude < -180 || longitude > 180) {
    console.error('经度参数错误，取值范围应为-180到180');
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
    
    addresses.forEach((address, index) => {
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
    });
    
    return addresses;
  } catch (error) {
    let businessError = error as BusinessError;
    console.error('逆地理编码失败: errCode=' + businessError.code + ', message=' + businessError.message);
    handleGeocodeError(businessError.code);
    return null;
  }
}

function handleGeocodeError(errorCode: number): string {
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
    default:
      errorMsg = '未知错误，错误码: ' + errorCode;
      break;
  }
  console.error('错误处理: ' + errorMsg);
  return errorMsg;
}

async function reverseGeocodeWithRetry(
  latitude: number,
  longitude: number,
  maxItems: number = 1,
  maxRetries: number = 3
): Promise<Array<geoLocationManager.GeoAddress> | null> {
  let retryCount = 0;
  
  while (retryCount < maxRetries) {
    const addresses = await reverseGeocodeWithPromise(latitude, longitude, maxItems);
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

export async function testReverseGeocodePromise(): Promise<void> {
  console.info('=== 测试逆地理编码(Promise方式) ===');
  
  const addresses = await reverseGeocodeWithPromise(31.12, 121.11, 1);
  if (addresses) {
    console.info('测试成功，获取到' + addresses.length + '个地址');
  } else {
    console.error('测试失败');
  }
  
  console.info('测试完成');
}