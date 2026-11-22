import { publish } from '@ohos.notificationManager';
import router from '@ohos.router';
import { getCurrentLocation } from '@ohos.geoLocationManager';
import { startVibration } from '@ohos.vibrator';
import { getAccountManager } from '@ohos.account.osAccount';
import { mockAndroidOnlyApi, mockIosOnlyApi } from '@ohos.mockSinglePlatform';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('benchmark fixture')
    }
  }
}
