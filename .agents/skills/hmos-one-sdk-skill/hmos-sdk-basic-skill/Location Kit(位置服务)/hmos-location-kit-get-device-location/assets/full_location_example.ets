import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

interface LocationResult {
    latitude: number;
    longitude: number;
    altitude: number;
    accuracy: number;
    speed: number;
    direction: number;
    timeStamp: number;
}

class FullLocationExample {
    private context: common.UIAbilityContext;
    private locationCallback: (location: geoLocationManager.Location) => void | undefined;
    private isContinuousLocationRunning: boolean = false;
    
    constructor(context: common.UIAbilityContext) {
        this.context = context;
        this.isContinuousLocationRunning = false;
    }
    
    async checkAndRequestPermission(): Promise<boolean> {
        return true;
    }
    
    async checkLocationSwitch(): Promise<boolean> {
        try {
            let locationEnabled = geoLocationManager.isLocationEnabled();
            if (!locationEnabled) {
                console.error('位置服务未开启');
                return false;
            }
            return true;
        } catch (err) {
            console.error('检查位置开关失败: ' + JSON.stringify(err));
            return false;
        }
    }
    
    async getBestLocation(): Promise<LocationResult | undefined> {
        let hasPermission = await this.checkAndRequestPermission();
        if (!hasPermission) {
            console.error('位置权限不足');
            return undefined;
        }
        
        let switchEnabled = await this.checkLocationSwitch();
        if (!switchEnabled) {
            console.error('位置开关未开启');
            return undefined;
        }
        
        try {
            let cachedLocation = geoLocationManager.getLastLocation();
            let currentTime = Date.now();
            let locationAge = currentTime - cachedLocation.timeStamp;
            
            if (locationAge < 30000) {
                console.info('使用新鲜缓存位置');
                return {
                    latitude: cachedLocation.latitude,
                    longitude: cachedLocation.longitude,
                    altitude: cachedLocation.altitude,
                    accuracy: cachedLocation.accuracy,
                    speed: cachedLocation.speed,
                    direction: cachedLocation.direction,
                    timeStamp: cachedLocation.timeStamp
                };
            }
        } catch (cacheErr) {
            console.warn('无可用缓存位置');
        }
        
        return await this.getCurrentLocationFallback();
    }
    
    async getCurrentLocationFallback(): Promise<LocationResult | undefined> {
        let request: geoLocationManager.SingleLocationRequest = {
            'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
            'locatingTimeoutMs': 10000
        };
        
        try {
            let result = await geoLocationManager.getCurrentLocation(request);
            console.info('获取当前位置成功');
            return {
                latitude: result.latitude,
                longitude: result.longitude,
                altitude: result.altitude,
                accuracy: result.accuracy,
                speed: result.speed,
                direction: result.direction,
                timeStamp: result.timeStamp
            };
        } catch (error) {
            let businessError = error as BusinessError;
            console.error('定位失败: code=' + businessError.code);
            
            switch (businessError.code) {
                case 3301100:
                    console.error('位置开关关闭');
                    break;
                case 3301200:
                    console.warn('无法获取地理位置，尝试降级');
                    try {
                        let cachedLocation = geoLocationManager.getLastLocation();
                        console.info('降级使用缓存位置');
                        return {
                            latitude: cachedLocation.latitude,
                            longitude: cachedLocation.longitude,
                            altitude: cachedLocation.altitude,
                            accuracy: cachedLocation.accuracy,
                            speed: cachedLocation.speed,
                            direction: cachedLocation.direction,
                            timeStamp: cachedLocation.timeStamp
                        };
                    } catch (cacheErr) {
                        console.error('缓存位置也不可用');
                        return undefined;
                    }
                default:
                    console.error('未知错误: ' + businessError.code);
                    return undefined;
            }
        }
    }
    
    startContinuousLocationForNavigation(): void {
        if (this.isContinuousLocationRunning) {
            console.warn('持续定位已运行');
            return;
        }
        
        this.locationCallback = (location: geoLocationManager.Location): void => {
            console.info('导航位置更新: lat=' + location.latitude + 
                        ', lon=' + location.longitude + 
                        ', speed=' + location.speed + 'm/s' +
                        ', direction=' + location.direction + '°');
        };
        
        let request: geoLocationManager.ContinuousLocationRequest = {
            'interval': 1,
            'locationScenario': geoLocationManager.UserActivityScenario.NAVIGATION
        };
        
        try {
            geoLocationManager.on('locationChange', request, this.locationCallback);
            this.isContinuousLocationRunning = true;
            console.info('导航持续定位已开启');
        } catch (err) {
            console.error('开启导航持续定位失败: ' + JSON.stringify(err));
        }
    }
    
    startContinuousLocationForSport(): void {
        if (this.isContinuousLocationRunning) {
            console.warn('持续定位已运行');
            return;
        }
        
        this.locationCallback = (location: geoLocationManager.Location): void => {
            console.info('运动轨迹位置: lat=' + location.latitude + 
                        ', lon=' + location.longitude + 
                        ', speed=' + location.speed + 'm/s');
        };
        
        let request: geoLocationManager.ContinuousLocationRequest = {
            'interval': 2,
            'locationScenario': geoLocationManager.UserActivityScenario.SPORT
        };
        
        try {
            geoLocationManager.on('locationChange', request, this.locationCallback);
            this.isContinuousLocationRunning = true;
            console.info('运动持续定位已开启');
        } catch (err) {
            console.error('开启运动持续定位失败: ' + JSON.stringify(err));
        }
    }
    
    stopContinuousLocation(): void {
        if (!this.isContinuousLocationRunning) {
            console.warn('持续定位未运行');
            return;
        }
        
        if (this.locationCallback) {
            try {
                geoLocationManager.off('locationChange', this.locationCallback);
                this.isContinuousLocationRunning = false;
                this.locationCallback = undefined;
                console.info('持续定位已取消');
            } catch (err) {
                console.error('取消持续定位失败: ' + JSON.stringify(err));
            }
        }
    }
    
    async getQuickLocation(): Promise<LocationResult | undefined> {
        let request: geoLocationManager.SingleLocationRequest = {
            'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
            'locatingTimeoutMs': 5000
        };
        
        try {
            let result = await geoLocationManager.getCurrentLocation(request);
            return {
                latitude: result.latitude,
                longitude: result.longitude,
                altitude: result.altitude,
                accuracy: result.accuracy,
                speed: result.speed,
                direction: result.direction,
                timeStamp: result.timeStamp
            };
        } catch (error) {
            console.error('快速定位失败: ' + JSON.stringify(error));
            return undefined;
        }
    }
    
    async getAccurateLocation(): Promise<LocationResult | undefined> {
        let request: geoLocationManager.SingleLocationRequest = {
            'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_ACCURACY,
            'locatingTimeoutMs': 15000
        };
        
        try {
            let result = await geoLocationManager.getCurrentLocation(request);
            return {
                latitude: result.latitude,
                longitude: result.longitude,
                altitude: result.altitude,
                accuracy: result.accuracy,
                speed: result.speed,
                direction: result.direction,
                timeStamp: result.timeStamp
            };
        } catch (error) {
            console.error('精度定位失败: ' + JSON.stringify(error));
            return undefined;
        }
    }
}

export default FullLocationExample;