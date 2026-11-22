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

function geocodeWithCallback(
  addressDescription: string,
  maxItems: number = 1
): void {
  if (!checkGeocoderService()) {
    return;
  }

  if (!addressDescription || addressDescription.trim().length === 0) {
    console.error('地址描述不能为空');
    return;
  }

  if (addressDescription.length > 100) {
    console.error('地址描述过长，最大长度100字符，当前长度: ' + addressDescription.length);
    return;
  }

  if (maxItems < 0) {
    console.error('maxItems参数错误，取值范围应大于等于0');
    return;
  }

  let geocodeRequest: geoLocationManager.GeoCodeRequest = {
    description: addressDescription,
    maxItems: maxItems,
    locale: 'zh'
  };

  try {
    geoLocationManager.getAddressesFromLocationName(geocodeRequest, (err, data) => {
      if (err) {
        console.error('正地理编码失败: err=' + JSON.stringify(err));
        handleGeocodeError(err.code);
        return;
      }
      if (data && data.length > 0) {
        console.info('正地理编码成功，找到' + data.length + '个匹配地址');
        data.forEach((address, index) => {
          console.info(`匹配${index + 1}:`);
          console.info(`  经纬度: (${address.latitude}, ${address.longitude})`);
          if (address.placeName) {
            console.info(`  详细地址: ${address.placeName}`);
          }
          if (address.administrativeArea) {
            console.info(`  省份: ${address.administrativeArea}`);
          }
          if (address.locality) {
            console.info(`  城市: ${address.locality}`);
          }
        });
      } else {
        console.warn('未找到匹配地址，请检查地址描述是否准确');
      }
    });
  } catch (err) {
    console.error('正地理编码调用异常: errCode=' + err.code + ', message=' + err.message);
    handleGeocodeError(err.code);
  }
}

function geocodeWithRangeCallback(
  addressDescription: string,
  minLat: number,
  minLon: number,
  maxLat: number,
  maxLon: number,
  maxItems: number = 1
): void {
  if (!checkGeocoderService()) {
    return;
  }

  if (!addressDescription || addressDescription.trim().length === 0) {
    console.error('地址描述不能为空');
    return;
  }

  if (addressDescription.length > 100) {
    console.error('地址描述过长，最大长度100字符');
    return;
  }

  if (minLat < -90 || minLat > 90 || maxLat < -90 || maxLat > 90) {
    console.error('纬度参数错误，取值范围应为-90到90');
    return;
  }

  if (minLon < -180 || minLon > 180 || maxLon < -180 || maxLon > 180) {
    console.error('经度参数错误，取值范围应为-180到180');
    return;
  }

  if (minLat > maxLat || minLon > maxLon) {
    console.error('经纬度范围参数错误，最小值应小于最大值');
    return;
  }

  let geocodeRequest: geoLocationManager.GeoCodeRequest = {
    description: addressDescription,
    maxItems: maxItems,
    locale: 'zh',
    minLatitude: minLat,
    minLongitude: minLon,
    maxLatitude: maxLat,
    maxLongitude: maxLon
  };

  try {
    geoLocationManager.getAddressesFromLocationName(geocodeRequest, (err, data) => {
      if (err) {
        console.error('正地理编码失败: err=' + JSON.stringify(err));
        handleGeocodeError(err.code);
        return;
      }
      if (data && data.length > 0) {
        console.info('正地理编码成功，在指定范围内找到' + data.length + '个匹配地址');
        data.forEach((address, index) => {
          console.info(`匹配${index + 1}:`);
          console.info(`  经纬度: (${address.latitude}, ${address.longitude})`);
          if (address.placeName) {
            console.info(`  详细地址: ${address.placeName}`);
          }
        });
      } else {
        console.warn('在指定范围内未找到匹配地址');
      }
    });
  } catch (err) {
    console.error('正地理编码调用异常: errCode=' + err.code + ', message=' + err.message);
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

export function testGeocodeCallback(): void {
  console.info('=== 测试正地理编码(Callback方式) ===');
  
  geocodeWithCallback('上海市浦东新区陆家嘴', 1);
  
  console.info('=== 测试正地理编码(带范围限制) ===');
  geocodeWithRangeCallback('陆家嘴', 30.0, 120.0, 32.0, 122.0, 1);
  
  console.info('测试完成');
}