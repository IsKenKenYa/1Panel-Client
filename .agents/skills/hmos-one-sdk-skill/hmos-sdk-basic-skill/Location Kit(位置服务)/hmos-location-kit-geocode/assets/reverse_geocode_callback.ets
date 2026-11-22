import { geoLocationManager } from '@kit.LocationKit';

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

function reverseGeocodeWithCallback(
  latitude: number,
  longitude: number,
  maxItems: number = 1
): void {
  if (!checkGeocoderService()) {
    return;
  }

  if (latitude < -90 || latitude > 90) {
    console.error('纬度参数错误，取值范围应为-90到90');
    return;
  }

  if (longitude < -180 || longitude > 180) {
    console.error('经度参数错误，取值范围应为-180到180');
    return;
  }

  if (maxItems < 0) {
    console.error('maxItems参数错误，取值范围应大于等于0');
    return;
  }

  let reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
    latitude: latitude,
    longitude: longitude,
    maxItems: maxItems,
    locale: 'zh'
  };

  try {
    geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest, (err, data) => {
      if (err) {
        console.error('逆地理编码失败: err=' + JSON.stringify(err));
        handleGeocodeError(err.code);
        return;
      }
      if (data && data.length > 0) {
        console.info('逆地理编码成功，结果数量: ' + data.length);
        data.forEach((address, index) => {
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
      } else {
        console.warn('未查询到地址信息，请检查坐标是否有效');
      }
    });
  } catch (err) {
    console.error('逆地理编码调用异常: errCode=' + err.code + ', message=' + err.message);
    handleGeocodeError(err.code);
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

export function testReverseGeocodeCallback(): void {
  console.info('=== 测试逆地理编码(Callback方式) ===');
  
  reverseGeocodeWithCallback(31.12, 121.11, 1);
  
  console.info('测试完成');
}