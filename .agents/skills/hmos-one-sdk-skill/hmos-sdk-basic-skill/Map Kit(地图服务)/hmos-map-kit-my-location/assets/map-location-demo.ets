import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError, AsyncCallback } from '@kit.BasicServicesKit';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { geoLocationManager } from '@kit.LocationKit';

@Entry
@Component
struct MapLocationDemo {
  private TAG = 'MapLocationDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: { latitude: 39.9, longitude: 116.4 },
        zoom: 10
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        
        console.info(this.TAG, 'Map initialized successfully');
        
        let hasPermission = await this.checkPermissions();
        if (!hasPermission) {
          this.requestPermissions();
          this.mapController?.setMyLocationControlsEnabled(true);
        }
        
        this.setupLocationButtonListener();
      } else {
        console.error(this.TAG, `Map init failed: ${err.code}, ${err.message}`);
      }
    };
  }

  async checkPermissions(): Promise<boolean> {
    const permissions: Permissions[] = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
    
    for (let permission of permissions) {
      let grantStatus = await this.checkAccessToken(permission);
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.mapController?.setMyLocationEnabled(true);
        this.mapController?.setMyLocationControlsEnabled(true);
        console.info(this.TAG, 'Location permission granted');
        return true;
      }
    }
    
    console.warn(this.TAG, 'Location permission not granted');
    return false;
  }

  async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager = abilityAccessCtrl.createAtManager();
    let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let tokenId = bundleInfo.appInfo.accessTokenId;
    return await atManager.checkAccessToken(tokenId, permission);
  }

  requestPermissions(): void {
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(
      this.getUIContext().getHostContext() as common.UIAbilityContext,
      ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION']
    ).then((data: PermissionRequestResult) => {
      if (data.authResults[0] === 0) {
        this.mapController?.setMyLocationEnabled(true);
        console.info(this.TAG, 'Location permission granted by user');
      } else {
        console.warn(this.TAG, 'Location permission denied by user');
      }
    }).catch((err: BusinessError) => {
      console.error(this.TAG, `Permission request failed: ${err.code}, ${err.message}`);
    });
  }

  setupLocationButtonListener(): void {
    let callback = () => {
      console.info(this.TAG, 'My location button clicked - custom handler');
      this.setCustomLocation();
    };
    
    this.mapEventManager?.on('myLocationButtonClick', callback);
  }

  async setCustomLocation(): Promise<void> {
    try {
      let location = await geoLocationManager.getCurrentLocation();
      this.mapController?.setMyLocation(location);
      console.info(this.TAG, `Location set: ${location.latitude}, ${location.longitude}`);
    } catch (error) {
      console.error(this.TAG, 'Failed to get location:', error);
    }
  }

  async customizeLocationIcon(): Promise<void> {
    let style: mapCommon.MyLocationStyle = {
      anchorU: 0.5,
      anchorV: 0.5,
      radiusFillColor: 0x66FF0000,
      icon: 'custom_location.png'
    };
    
    await this.mapController?.setMyLocationStyle(style);
    console.info(this.TAG, 'Location icon customized');
  }

  changeLocationLayerOrder(): void {
    this.mapController?.changeMyLocationLayerOrder(true);
    console.info(this.TAG, 'Location layer order changed');
  }

  hideLocationButton(): void {
    this.mapController?.setMyLocationControlsEnabled(false);
    console.info(this.TAG, 'Location button hidden');
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%');
      
      Column() {
        Button('自定义图标')
          .onClick(() => this.customizeLocationIcon());
        Button('改变图层顺序')
          .onClick(() => this.changeLocationLayerOrder());
        Button('隐藏位置按钮')
          .onClick(() => this.hideLocationButton());
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.End)
      .padding(10);
    }
    .height('100%');
  }
}