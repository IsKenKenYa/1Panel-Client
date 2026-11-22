import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want, WantAgent, wantAgent } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class LiveViewController {
  public static applicationContext: common.ApplicationContext;

  public static async isLiveViewEnabled(): Promise<boolean> {
    try {
      const isEnabled: boolean = await liveViewManager.isLiveViewEnabled();
      hilog.info(0x0000, 'LiveViewKit', '实况窗开关状态: %{public}s', isEnabled);
      return isEnabled;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'LiveViewKit', '校验实况窗开关失败: %{public}d %{public}s', e.code, e.message);
      return false;
    }
  }

  public static async buildWantAgent(page: string, liveViewId: number = -1): Promise<Want> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: LiveViewController.applicationContext.applicationInfo.name,
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

  public static async buildProgressLiveView(): Promise<liveViewManager.LiveView> {
    return {
      id: 106,
      event: 'DELIVERY',
      sequence: 1,
      isMute: false,
      liveViewData: {
        primary: {
          title: '骑手已接单',
          content: [
            { text: '距商家 ' },
            { text: '300 ', textColor: '#FF0A59F7' },
            { text: '米 | ' },
            { text: '3 ', textColor: '#FF0A59F7' },
            { text: '分钟到店' }
          ],
          keepTime: 0,
          clickAction: await LiveViewController.buildWantAgent('GuideCode'),
          layoutData: {
            layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PROGRESS,
            weatherInfo: {
              weatherType: liveViewManager.WeatherType.WEATHER_TYPE_LIGHT_RAIN,
              locationType: liveViewManager.WeatherLocationType.LOCATION_TYPE_LOCAL
            },
            progress: 40,
            color: '#FF317AF7',
            backgroundColor: '#f7819ae0',
            indicatorType: liveViewManager.IndicatorType.INDICATOR_TYPE_UP,
            indicatorIcon: 'icon_rider.png',
            lineType: liveViewManager.LineType.LINE_TYPE_DOTTED_LINE,
            nodeIcons: ['icon_order.png', 'icon_store_white.png', 'icon_finish.png']
          }
        },
        capsule: {
          type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
          status: 1,
          icon: 'icon_delivery.png',
          backgroundColor: '#FF308977',
          title: '外卖配送',
          content: '预计10分钟送达'
        }
      }
    };
  }

  public static async buildPickupLiveView(): Promise<liveViewManager.LiveView> {
    return {
      id: 105,
      event: 'PICK_UP',
      sequence: 1,
      isMute: false,
      liveViewData: {
        primary: {
          title: '餐品已备好',
          content: [
            { text: '请前往' },
            { text: ' XXX店 ', textColor: '#FF0A59F7' },
            { text: '取餐' }
          ],
          keepTime: 0,
          clickAction: await LiveViewController.buildWantAgent('GuideCode'),
          layoutData: {
            layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
            weatherInfo: {
              weatherType: liveViewManager.WeatherType.WEATHER_TYPE_HAZY,
              locationType: liveViewManager.WeatherLocationType.LOCATION_TYPE_LOCAL
            },
            title: '取餐码',
            content: '72988',
            underlineColor: '#FF0A59F7',
            descPic: 'coffee.png'
          }
        },
        capsule: {
          type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
          status: 1,
          icon: 'coffee.png',
          backgroundColor: '#FF308977',
          title: '待取餐',
          content: '取餐码：72988'
        }
      }
    };
  }

  public static async buildFlightLiveView(): Promise<liveViewManager.LiveView> {
    return {
      id: 103,
      event: 'FLIGHT',
      sequence: 1,
      isMute: false,
      liveViewData: {
        primary: {
          title: '计划出发',
          content: [
            { text: '登机口' },
            { text: '32', textColor: '#FF0A59F7' },
            { text: ' | 座位' },
            { text: ' 17H', textColor: '#FF0A59F7' }
          ],
          keepTime: 0,
          clickAction: await LiveViewController.buildWantAgent('GuideCode'),
          backgroundType: liveViewManager.BackgroundType.SYS_BACKGROUND_FLIGHT_SUNSET,
          layoutData: {
            layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_FLIGHT,
            weatherInfo: {
              weatherType: liveViewManager.WeatherType.WEATHER_TYPE_LIGHT_RAIN,
              locationType: liveViewManager.WeatherLocationType.LOCATION_TYPE_DESTINATION,
              highTemperature: 30,
              lowTemperature: -10
            },
            firstTitle: '09:00',
            firstContent: '上海虹桥',
            lastTitle: '14:20',
            lastContent: '汉口',
            spaceIcon: 'icon_plane.png',
            isHorizontalLineDisplayed: false,
            additionalText: '以上信息仅供参考'
          }
        },
        capsule: {
          type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
          status: 1,
          icon: 'icon_flight.png',
          backgroundColor: '#FF308977',
          title: '航班',
          content: 'CA1234'
        }
      }
    };
  }

  public static async buildScoreLiveView(): Promise<liveViewManager.LiveView> {
    return {
      id: 108,
      event: 'SCORE',
      sequence: 1,
      isMute: false,
      liveViewData: {
        primary: {
          title: '第四节比赛中',
          content: [
            { text: 'XX', textColor: '#FF0A59F7' },
            { text: ' VS ' },
            { text: 'XX', textColor: '#FF0A59F7' },
            { text: ' | ' },
            { text: '小组赛 第五场', textColor: '#FF0A59F7' }
          ],
          keepTime: 0,
          clickAction: await LiveViewController.buildWantAgent('GuideCode'),
          layoutData: {
            layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_SCORE,
            hostName: '队名 A',
            hostIcon: 'score_firefox.png',
            hostScore: '110',
            guestName: '队名 B',
            guestIcon: 'score_m.png',
            guestScore: '102',
            competitionDesc: [
              { text: '●', textColor: '#FFFF0000' },
              { text: 'Q4' }
            ],
            competitionTime: '02:16',
            isHorizontalLineDisplayed: true
          }
        },
        capsule: {
          type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
          status: 1,
          icon: 'score_icon.png',
          backgroundColor: '#FF308977',
          title: '110:102',
          content: '比赛中'
        }
      }
    };
  }

  public static async buildNavigationLiveView(): Promise<liveViewManager.LiveView> {
    return {
      id: 104,
      event: 'NAVIGATION',
      sequence: 1,
      isMute: false,
      liveViewData: {
        primary: {
          title: '178米后左转',
          content: [
            { text: '去往' },
            { text: ' xxx东路', textColor: '#FF0A59F7' }
          ],
          keepTime: 0,
          clickAction: await LiveViewController.buildWantAgent('GuideCode'),
          layoutData: {
            layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_NAVIGATION,
            currentNavigationIcon: 'arrow_left.png',
            navigationIcons: ['arrow_left.png', 'arrow_up.png', 'arrow_up.png', 'arrow_right.png']
          }
        },
        capsule: {
          type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
          status: 1,
          icon: 'nav_icon.png',
          backgroundColor: '#FF308977',
          title: '导航中',
          content: '178米后左转'
        }
      }
    };
  }

  public static async startLiveView(liveViewType: string): Promise<boolean> {
    if (!await LiveViewController.isLiveViewEnabled()) {
      hilog.warn(0x0000, 'LiveViewKit', '实况窗开关未开启，无法创建实况窗');
      return false;
    }

    try {
      let liveView: liveViewManager.LiveView;

      switch (liveViewType) {
        case 'PROGRESS':
          liveView = await LiveViewController.buildProgressLiveView();
          break;
        case 'PICKUP':
          liveView = await LiveViewController.buildPickupLiveView();
          break;
        case 'FLIGHT':
          liveView = await LiveViewController.buildFlightLiveView();
          break;
        case 'SCORE':
          liveView = await LiveViewController.buildScoreLiveView();
          break;
        case 'NAVIGATION':
          liveView = await LiveViewController.buildNavigationLiveView();
          break;
        default:
          hilog.error(0x0000, 'LiveViewKit', '不支持的实况窗类型: %{public}s', liveViewType);
          return false;
      }

      hilog.info(0x0000, 'LiveViewKit', '请求创建实况窗: %{public}s', JSON.stringify(liveView));
      const result = await liveViewManager.startLiveView(liveView);
      hilog.info(0x0000, 'LiveViewKit', '创建实况窗成功，结果: %{public}s', JSON.stringify(result));
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'LiveViewKit', '创建实况窗失败: %{public}d %{public}s', e.code, e.message);
      return false;
    }
  }

  public static async updateLiveView(liveViewId: number, sequence: number): Promise<boolean> {
    try {
      const activeLiveView = await liveViewManager.getActiveLiveView(liveViewId);
      activeLiveView.sequence = sequence;
      
      hilog.info(0x0000, 'LiveViewKit', '请求更新实况窗，ID: %{public}d，序列号: %{public}d', liveViewId, sequence);
      const result = await liveViewManager.updateLiveView(activeLiveView);
      hilog.info(0x0000, 'LiveViewKit', '更新实况窗成功，结果: %{public}s', JSON.stringify(result));
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'LiveViewKit', '更新实况窗失败: %{public}d %{public}s', e.code, e.message);
      return false;
    }
  }

  public static async stopLiveView(liveViewId: number, sequence: number): Promise<boolean> {
    try {
      const activeLiveView = await liveViewManager.getActiveLiveView(liveViewId);
      activeLiveView.sequence = sequence;
      activeLiveView.liveViewData.primary.keepTime = 600;
      
      hilog.info(0x0000, 'LiveViewKit', '请求结束实况窗，ID: %{public}d，序列号: %{public}d', liveViewId, sequence);
      const result = await liveViewManager.stopLiveView(activeLiveView);
      hilog.info(0x0000, 'LiveViewKit', '结束实况窗成功，结果: %{public}s', JSON.stringify(result));
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'LiveViewKit', '结束实况窗失败: %{public}d %{public}s', e.code, e.message);
      return false;
    }
  }
}