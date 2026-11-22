import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class ContinuousLocationExample {
    private locationCallback: (location: geoLocationManager.Location) => void;
    private locationErrorCallback: (errCode: geoLocationManager.LocationError) => void;
    
    constructor() {
        this.locationCallback = (location: geoLocationManager.Location): void => {
            console.info('位置更新: ' + JSON.stringify(location));
        };
        
        this.locationErrorCallback = (errCode: geoLocationManager.LocationError): void => {
            console.error('定位错误: ' + JSON.stringify(errCode));
            
            switch (errCode) {
                case geoLocationManager.LocationError.LOCATING_FAILED_LOCATION_PERMISSION_DENIED:
                    console.error('位置权限被拒绝');
                    break;
                case geoLocationManager.LocationError.LOCATING_FAILED_LOCATION_SWITCH_OFF:
                    console.error('位置开关关闭');
                    break;
                case geoLocationManager.LocationError.LOCATING_FAILED_INTERNET_ACCESS_FAILURE:
                    console.error('网络访问失败');
                    break;
                default:
                    console.error('定位失败: ' + errCode);
            }
        };
    }
    
    startContinuousLocation(): void {
        try {
            let locationEnabled = geoLocationManager.isLocationEnabled();
            if (!locationEnabled) {
                console.error('位置服务未开启');
                return;
            }
        } catch (err) {
            console.error('检查位置开关失败: ' + JSON.stringify(err));
            return;
        }
        
        let request: geoLocationManager.ContinuousLocationRequest = {
            'interval': 1,
            'locationScenario': geoLocationManager.UserActivityScenario.NAVIGATION
        };
        
        try {
            geoLocationManager.on('locationChange', request, this.locationCallback);
            console.info('持续定位已开启');
            
            geoLocationManager.on('locationError', this.locationErrorCallback);
            console.info('错误订阅已开启');
        } catch (err) {
            console.error('开启持续定位失败: ' + JSON.stringify(err));
        }
    }
    
    stopContinuousLocation(): void {
        try {
            geoLocationManager.off('locationChange', this.locationCallback);
            console.info('持续定位已取消');
            
            geoLocationManager.off('locationError', this.locationErrorCallback);
            console.info('错误订阅已取消');
        } catch (err) {
            console.error('取消持续定位失败: ' + JSON.stringify(err));
        }
    }
    
    startLocationWithDifferentScenario(scenario: geoLocationManager.UserActivityScenario): void {
        let request: geoLocationManager.ContinuousLocationRequest = {
            'interval': 1,
            'locationScenario': scenario
        };
        
        try {
            geoLocationManager.on('locationChange', request, this.locationCallback);
            console.info('持续定位已开启，场景: ' + scenario);
        } catch (err) {
            console.error('开启持续定位失败: ' + JSON.stringify(err));
        }
    }
}

export default ContinuousLocationExample;