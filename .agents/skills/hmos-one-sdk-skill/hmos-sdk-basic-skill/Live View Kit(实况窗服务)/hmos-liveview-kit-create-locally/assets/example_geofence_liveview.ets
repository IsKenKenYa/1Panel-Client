import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { Want, wantAgent } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class GeofenceLiveViewController {
  public static applicationContext: common.ApplicationContext;

  public static async checkGeofenceRights(): Promise<string> {
    try {
      if (!await liveViewManager.isLiveViewEnabled()) {
        hilog.warn(0x0000, 'LiveViewKit', '实况窗开关未开启');
        return '实况窗开关未开启，请在设置中开启';
      }

      if (!await liveViewManager.isGeofenceTriggerEnabled()) {
        hilog.warn(0x0000, 'LiveViewKit', '地理围栏开关未开启');
        return '地理围栏开关未开启，请在设置中开启';
      }

      if (!geoLocationManager.isLocationEnabled()) {
        hilog.warn(0x0000, 'LiveViewKit', 'GPS开关未开启');
        return 'GPS开关未开启，请在设置中开启';
      }

      return '';
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'LiveViewKit', '校验地理围栏权限失败: %{public}d %{public}s', e.code, e.message);
      return '校验地理围栏权限失败';
    }
  }

  public static async buildWantAgent(page: string, liveViewId: number = -1): Promise<Want> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: GeofenceLiveViewController.applicationContext.applicationInfo.name,
          abilityName: 'EntryAbility',
          parameters: {
            page: page,
            liveViewId: liveViewId
          }
        } as Want
      ],
      actionType: wantAgent.OperationType.START_ABILITIES,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    try {
      const agent: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);
      hilog.info(0x0000, 'LiveViewKit', '构建WantAgent成功');
      return agent;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'LiveViewKit', '构建WantAgent失败: %{public}d %{public}s', e.code, e.message);
      throw e as Error;
    }
  }

  public static async buildExpressLiveView(): Promise<liveViewManager.LiveView> {
    return {
      id: 11,
      event: 'EXPRESS',
      sequence: 1,
      isMute: false,
      liveViewData: {
        primary: {
          title: '快递已到达',
          content: [{ text: '请前往快递柜取件' }],
          keepTime: 0,
          clickAction: await GeofenceLiveViewController.buildWantAgent('Geofence'),
          extensionData: {
            type: liveViewManager.ExtensionType.EXTENSION_TYPE_ICON,
            pic: 'express.png',
            clickAction: await GeofenceLiveViewController.buildWantAgent('Geofence', 11)
          },
          layoutData: {
            layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
            title: '取件码',
            content: '12345',
            underlineColor: '#FF0A59F7',
            descPic: 'pick.png'
          }
        },
        capsule: {
          type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
          status: 1,
          icon: 'pick.png',
          backgroundColor: '#FF308977',
          title: '快递',
          content: '取件码：12345'
        }
      }
    };
  }

  public static async buildGeofenceTrigger(longitude: number, latitude: number): Promise<liveViewManager.Trigger> {
    return {
      type: liveViewManager.TriggerType.TRIGGER_TYPE_GEOFENCE,
      displayTime: 900,
      condition: {
        longitude: longitude,
        latitude: latitude,
        coordinateSystemType: liveViewManager.CoordinateSystemType.COORDINATE_TYPE_GCJ02,
        monitorEvent: liveViewManager.MonitorEvent.MONITOR_TYPE_ENTRY,
        radius: 500,
        delayTime: 0
      }
    };
  }

  public static async startLiveViewByTrigger(longitude: number, latitude: number): Promise<number> {
    const checkResult = await GeofenceLiveViewController.checkGeofenceRights();
    if (checkResult !== '') {
      hilog.error(0x0000, 'LiveViewKit', '地理围栏权限校验失败: %{public}s', checkResult);
      return -1;
    }

    try {
      const liveView = await GeofenceLiveViewController.buildExpressLiveView();
      const trigger = await GeofenceLiveViewController.buildGeofenceTrigger(longitude, latitude);

      hilog.info(0x0000, 'LiveViewKit', '注册地理围栏触发实况窗，位置: %{public}f, %{public}f', longitude, latitude);
      const result = await liveViewManager.startLiveViewByTrigger(liveView, trigger);
      hilog.info(0x0000, 'LiveViewKit', '注册成功，结果码: %{public}d', result.resultCode);
      return result.resultCode;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'LiveViewKit', '注册地理围栏触发实况窗失败: %{public}d %{public}s', e.code, e.message);
      return -1;
    }
  }
}