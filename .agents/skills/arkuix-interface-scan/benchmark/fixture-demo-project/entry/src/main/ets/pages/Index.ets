// demo 采样：典型开源 OH 应用首页形态（@ohos.* + @hms.* 混合引用）
import router from '@ohos.router';
import { publish } from '@ohos.notificationManager';
import { getCurrentLocation } from '@ohos.geoLocationManager';
import { Push } from '@hms.push';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('demo sample')
    }
  }
}
