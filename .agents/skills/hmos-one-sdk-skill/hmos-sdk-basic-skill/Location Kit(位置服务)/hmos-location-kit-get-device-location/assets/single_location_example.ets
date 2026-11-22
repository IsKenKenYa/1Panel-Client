import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class SingleLocationExample {
    async getCurrentLocationWithCache(): Promise<void> {
        try {
            let locationEnabled = geoLocationManager.isLocationEnabled();
            if (!locationEnabled) {
                console.error('位置服务未开启');
                return;
            }
            
            try {
                let cachedLocation = geoLocationManager.getLastLocation();
                let currentTime = Date.now();
                let locationAge = currentTime - cachedLocation.timeStamp;
                
                if (locationAge < 60000) {
                    console.info('使用缓存位置: ' + JSON.stringify(cachedLocation));
                    return;
                }
                console.warn('缓存位置较旧，重新定位');
            } catch (cacheErr) {
                console.warn('无缓存位置，重新定位');
            }
            
            await this.getCurrentLocation();
        } catch (err) {
            console.error('检查位置开关失败: ' + JSON.stringify(err));
        }
    }
    
    async getCurrentLocation(): Promise<void> {
        let request: geoLocationManager.SingleLocationRequest = {
            'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
            'locatingTimeoutMs': 10000
        };
        
        try {
            geoLocationManager.getCurrentLocation(request).then((result) => {
                console.info('当前位置: ' + JSON.stringify(result));
            }).catch((error: BusinessError) => {
                console.error('定位失败: ' + JSON.stringify(error));
            });
        } catch (err) {
            console.error('调用定位API异常: ' + JSON.stringify(err));
        }
    }
    
    getCurrentLocationWithCallback(): void {
        let request: geoLocationManager.SingleLocationRequest = {
            'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_ACCURACY,
            'locatingTimeoutMs': 10000
        };
        
        let locationCallback = (err: BusinessError, location: geoLocationManager.Location): void => {
            if (err) {
                console.error('定位失败: ' + JSON.stringify(err));
                return;
            }
            console.info('当前位置: ' + JSON.stringify(location));
        };
        
        try {
            geoLocationManager.getCurrentLocation(request, locationCallback);
        } catch (err) {
            console.error('调用定位API异常: ' + JSON.stringify(err));
        }
    }
}

export default SingleLocationExample;