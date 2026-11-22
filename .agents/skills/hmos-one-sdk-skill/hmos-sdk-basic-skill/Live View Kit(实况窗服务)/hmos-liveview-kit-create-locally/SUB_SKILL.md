---
name: hmos-liveview-kit-create-locally
description: 构建本地实况窗，支持5种卡片模板（进度可视化、强调文本、左右文本、赛事比分、导航）及地理围栏触发提醒，仅限应用前台运行且已开通权益，适用于外卖配送、航班出行、排队取餐等13个场景
---

# 构建本地实况窗技能

## 功能描述

本技能提供HarmonyOS Live View Kit的本地实况窗创建能力，通过liveViewManager模块实现实况窗的完整生命周期管理（创建、更新、结束）。支持5种卡片模板样式：

1. **进度可视化模板**：适用于打车、外卖配送等场景，支持进度条、节点图标、天气动效背景
2. **强调文本模板**：适用于取餐、排队等场景，支持取餐码显示、天气动效背景
3. **左右文本模板**：适用于航班、高铁等场景，支持出发/到达信息、天气动效背景、夕阳/赏月氛围背景
4. **赛事比分模板**：适用于体育赛事场景，支持实时比分显示
5. **导航模板**：适用于导航场景，支持方向箭头显示

从API version 6.1.0(23)开始，新增支持基于地理位置的实况窗提醒（打卡、快递场景），通过地理围栏触发实况窗的自动创建或结束。

**技术特点**：
- 仅支持Phone和Tablet设备
- 仅可在Stage模型下使用
- 需应用在前台运行且已开通实况窗权益
- 支持实况胶囊形态（文本、计时器、进度三种类型）
- 支持锁屏沉浸实况窗大图样式（API version 5.0.0(12)开始）
- 支持计时器占位符（API version 5.0.0(12)开始）
- 支持天气动效背景（API version 6.0.0(20)开始）

## 使用场景

### 触发词
- "创建实况窗"
- "本地实况窗"
- "实况窗卡片"
- "外卖实况窗"
- "航班实况窗"
- "取餐实况窗"
- "排队实况窗"
- "赛事实况窗"
- "导航实况窗"
- "地理围栏实况窗"
- "快递实况窗"

### 能做
- 创建本地实况窗，配置5种模板样式
- 构建实况窗请求体（LiveView对象），配置固定区、辅助区、扩展区内容
- 配置实况胶囊形态（文本、计时器、进度三种类型）
- 配置点击跳转动作（WantAgent）
- 配置实况窗计时器和倒计时功能
- 配置天气动效背景和氛围背景
- 创建基于地理围栏触发的实况窗提醒
- 校验实况窗开关状态
- 处理实况窗创建、更新、结束的生命周期

### 绝不做
- 不创建服务端实况窗（需使用Push Kit）
- 不在应用后台时创建实况窗（仅限前台运行）
- 不创建未开通权益的场景实况窗
- 不在非Phone/Tablet设备上创建实况窗
- 不在FA模型下创建实况窗

### 补充
- **前提条件**：应用必须在前台运行，且用户已开启实况窗开关（设置>应用和元服务>应用名>实况窗）
- **权益申请**：需在AGC平台开通对应场景的实况窗权益，详见实况窗权益说明
- **推荐使用**：建议在本地创建实况窗后使用Push Kit更新或结束实况窗，避免依赖应用进程
- **频率限制**：实况窗创建频率限制为每秒1个，更新频率限制为每秒5个
- **版本要求**：基础功能起始版本4.1.0(11)，地理围栏触发功能起始版本6.1.0(23)

## 调用规范和规则

### 输入约束
- **实况窗ID**：范围[-2147483648, 2147483647]，由开发者生成，需唯一
- **序列号**：范围[0, 2147483647]，更新/结束时需大于当前序列号
- **标题长度**：固定区标题长度小于1024字符
- **内容长度**：固定区内容数组text字段总和小于1024字符，扩展区内容小于128字符
- **图片大小**：图片文件不大于30KB（PixelMap类型）
- **图片格式**：支持string（rawfile路径）或image.PixelMap类型
- **颜色格式**："#ARGB"16进制格式，长度为9（如#FF317AF7）
- **温度范围**：最低温度≥-95℃，最高温度≤58℃，且lowTemperature < highTemperature
- **进度值范围**：[0, 100]
- **节点图标数量**：进度条节点图标数组长度范围[2, 5]
- **实况窗存档时间**：范围[0, 3600]秒，默认0不保留

### 执行约束
- **最大耗时**：API调用建议在5秒内完成
- **调用频率**：创建频率≤每秒1个，更新频率≤每秒5个
- **必须校验**：创建前必须调用isLiveViewEnabled()校验实况窗开关状态
- **序列号规则**：更新和结束时，sequence必须大于当前实况窗的序列号

### 内容约束
- **禁止内容**：
  - 禁止使用null/undefined/空字符串/全为空格的字符串作为标题或内容
  - 禁止使用#000000或#FFFFFF作为实况胶囊背景色
  - 禁止使用GIF格式图片作为锁屏沉浸实况窗大图
- **textColor规则**：所有拥有textColor字段的对象仅能设置同一种颜色
- **event字段**：必须使用预定义的场景值（TAXI、DELIVERY、FLIGHT、TRAIN、QUEUE、PICK_UP、SCORE、RENT、TIMER、WORKOUT、NAVIGATION、EXPRESS、CHECKIN）
- **模板匹配**：layoutType必须与event场景匹配

### 降级约束
- **实况窗开关关闭**：提示用户开启实况窗开关，返回false
- **权益未开通**：提示开发者到AGC平台开通实况窗权益，抛出错误码1003500005
- **实况窗已存在**：更换实况窗ID重新创建，抛出错误码1003500006
- **实况窗不存在**：检查创建是否成功或实况窗是否已结束，抛出错误码1003500009
- **网络失败**：检查网络连接，抛出错误码1003500007
- **频率超限**：降低实况窗调用频率，抛出错误码1003500008
- **序列号错误**：修改序列号重新调用，抛出错误码1003500011

## 调用流程和步骤

### 步骤1：导入模块和校验开关

**前置校验**：
1. 导入liveViewManager模块：`import { liveViewManager } from '@kit.LiveViewKit'`
2. 导入必要依赖：`import { BusinessError } from '@kit.BasicServicesKit'`
3. 导入wantAgent模块：`import { Want, wantAgent } from '@kit.AbilityKit'`
4. 校验实况窗开关状态：调用`liveViewManager.isLiveViewEnabled()`

**示例代码**：
```typescript
import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want, wantAgent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class LiveViewController {
  // 校验实况窗开关是否打开
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
}
```

### 步骤2：构建WantAgent跳转动作

**参数准备**：
1. 获取应用上下文：通过globalThis获取ApplicationContext
2. 构造WantAgentInfo对象：配置bundleName、abilityName、parameters
3. 调用wantAgent.getWantAgent()获取WantAgent对象

**示例代码**：
```typescript
export class ContextUtil {
  public static applicationContext: common.ApplicationContext;
  
  // 构建点击跳转动作
  public static async buildWantAgent(page: string, liveViewId: number = -1): Promise<Want> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: ContextUtil.applicationContext.applicationInfo.name,
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
}
```

### 步骤3：构建实况窗请求体（LiveView对象）

**参数配置**（根据场景选择模板）：

#### 进度可视化模板示例（外卖配送场景）
```typescript
private static async buildProgressLiveView(): Promise<liveViewManager.LiveView> {
  return {
    id: 106, // 实况窗ID，开发者生成
    event: 'DELIVERY', // 即时配送场景
    sequence: 1, // 序列号
    isMute: false, // 铃声震动提醒
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
        clickAction: await ContextUtil.buildWantAgent('GuideCode'),
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
```

#### 强调文本模板示例（取餐场景）
```typescript
private static async buildPickupLiveView(): Promise<liveViewManager.LiveView> {
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
        clickAction: await ContextUtil.buildWantAgent('GuideCode'),
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
```

#### 左右文本模板示例（航班场景）
```typescript
private static async buildFlightLiveView(): Promise<liveViewManager.LiveView> {
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
        clickAction: await ContextUtil.buildWantAgent('GuideCode'),
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
```

#### 赛事比分模板示例
```typescript
private static async buildScoreLiveView(): Promise<liveViewManager.LiveView> {
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
        clickAction: await ContextUtil.buildWantAgent('GuideCode'),
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
```

#### 导航模板示例
```typescript
private static async buildNavigationLiveView(): Promise<liveViewManager.LiveView> {
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
        clickAction: await ContextUtil.buildWantAgent('GuideCode'),
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
```

### 步骤4：调用startLiveView创建实况窗

**API调用**：
```typescript
public async startLiveView(): Promise<boolean> {
  // 校验实况窗开关是否打开
  if (!await LiveViewController.isLiveViewEnabled()) {
    hilog.warn(0x0000, 'LiveViewKit', '实况窗开关未开启，无法创建实况窗');
    return false;
  }
  
  // 创建实况窗
  try {
    const liveView = await LiveViewController.buildDefaultView();
    if (!liveView) {
      hilog.warn(0x0000, 'LiveViewKit', '构建实况窗请求体失败');
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
```

### 步骤5：错误处理和降级处理

**错误处理代码**：
```typescript
// 错误处理和降级处理
public async handleLiveViewError(errorCode: number): Promise<void> {
  switch (errorCode) {
    case 1003500001: // 系统错误
      hilog.error(0x0000, 'LiveViewKit', '系统内部错误，请重试或提交问题反馈');
      // 降级：重试或提示用户稍后再试
      break;
      
    case 1003500004: // 实况窗开关关闭
      hilog.error(0x0000, 'LiveViewKit', '实况窗开关未开启');
      // 降级：提示用户开启实况窗开关（设置>应用和元服务>应用名>实况窗）
      break;
      
    case 1003500005: // 实况窗权益未申请
      hilog.error(0x0000, 'LiveViewKit', '实况窗权益未申请');
      // 降级：提示开发者到AGC平台开通实况窗权益
      break;
      
    case 1003500006: // 实况窗已存在
      hilog.error(0x0000, 'LiveViewKit', '实况窗ID已存在');
      // 降级：更换实况窗ID重新创建
      break;
      
    case 1003500007: // 无法连接服务器
      hilog.error(0x0000, 'LiveViewKit', '网络不可达');
      // 降级：检查网络连接
      break;
      
    case 1003500008: // 实况窗频度超过限制
      hilog.error(0x0000, 'LiveViewKit', '实况窗调用频率超限');
      // 降级：降低实况窗调用频率
      break;
      
    case 1003500009: // 实况窗不存在
      hilog.error(0x0000, 'LiveViewKit', '实况窗不存在或已结束');
      // 降级：检查实况窗是否创建成功
      break;
      
    case 401: // 参数错误
      hilog.error(0x0000, 'LiveViewKit', '参数错误，请检查参数类型和必填字段');
      // 降级：校验参数类型和必填字段
      break;
      
    default:
      hilog.error(0x0000, 'LiveViewKit', '未知错误: %{public}d', errorCode);
      break;
  }
}
```

### 步骤6：地理围栏触发实况窗（API version 6.1.0(23)）

**构建地理围栏触发实况窗**：
```typescript
import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';

export class GeofenceLiveViewController {
  // 构建实况窗请求体
  private static async buildExpressLiveView(): Promise<liveViewManager.LiveView> {
    return {
      id: 11,
      event: 'EXPRESS', // 快递场景
      sequence: 1,
      isMute: false,
      liveViewData: {
        primary: {
          title: '快递已到达',
          content: [{ text: '请前往快递柜取件' }],
          keepTime: 0,
          clickAction: await ContextUtil.buildWantAgent('Geofence'),
          extensionData: {
            type: liveViewManager.ExtensionType.EXTENSION_TYPE_ICON,
            pic: 'express.png',
            clickAction: await ContextUtil.buildWantAgent('Geofence', 11)
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
  
  // 构建地理围栏触发条件
  private static async buildGeofenceTrigger(longitude: number, latitude: number): Promise<liveViewManager.Trigger> {
    return {
      type: liveViewManager.TriggerType.TRIGGER_TYPE_GEOFENCE,
      displayTime: 900, // 显示时长
      condition: {
        longitude: longitude,
        latitude: latitude,
        coordinateSystemType: liveViewManager.CoordinateSystemType.COORDINATE_TYPE_GCJ02,
        monitorEvent: liveViewManager.MonitorEvent.MONITOR_TYPE_ENTRY, // 进入地理围栏触发
        radius: 500, // 地理围栏半径500米
        delayTime: 0 // 延迟触发时间
      }
    };
  }
  
  // 注册地理围栏触发实况窗
  public async startLiveViewByTrigger(longitude: number, latitude: number): Promise<number> {
    try {
      const liveView = await GeofenceLiveViewController.buildExpressLiveView();
      const trigger = await GeofenceLiveViewController.buildGeofenceTrigger(longitude, latitude);
      
      hilog.info(0x0000, 'LiveViewKit', '注册地理围栏触发实况窗');
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
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查必填参数是否填写、参数类型是否正确、参数校验是否通过 |
| 1003500001 | 系统内部错误 | 重试或通过在线提单提交问题反馈 |
| 1003500002 | 序列化或反序列化失败 | 重试或通过在线提单提交问题反馈 |
| 1003500003 | 连接服务失败 | 重试或通过在线提单提交问题反馈 |
| 1003500004 | 实况窗开关关闭 | 在设置>应用和元服务>应用名中开启实况窗开关 |
| 1003500005 | 实况窗权益未申请 | 到AGC平台开通实况窗权益，并确认event字段与权益场景匹配 |
| 1003500006 | 实况窗ID已存在 | 更换实况窗ID重新创建 |
| 1003500007 | 无法连接服务器 | 检查网络连接，确保设备已联网 |
| 1003500008 | 实况窗频度超过限制 | 降低实况窗调用频率（创建≤每秒1个，更新≤每秒5个） |
| 1003500009 | 实况窗不存在 | 检查实况窗是否创建成功，或实况窗是否已结束 |
| 1003500010 | 实况窗已结束 | 实况窗结束后在keepTime保留期内不可复用ID更新或结束 |
| 1003500011 | 实况窗序列号不正确 | 修改序列号，确保大于当前实况窗的序列号 |
| 1003500012 | 订阅次数超出限制 | 调整订阅次数（单个用户单应用最多2000个订阅） |
| 1003500013 | 无效的实况窗订阅场景 | 检查event参数是否正确 |
| 1003500014 | 实况窗提醒时间距当前过长 | 检查alertTime和startTime参数（距离当前时间≤30天） |
| 1003500015 | 实况窗订阅失败 | 重试或通过在线提单提交问题反馈 |
| 1003500016 | 请求频次超限 | 调整订阅频次 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LiveViewKit": "4.1.0(11)及以上",
    "@kit.BasicServicesKit": "4.1.0(11)及以上",
    "@kit.AbilityKit": "4.1.0(11)及以上",
    "@kit.PerformanceAnalysisKit": "4.1.0(11)及以上"
  }
}
```

### 环境要求
- HarmonyOS API version：≥4.1.0(11)
- 设备类型：仅支持Phone和Tablet
- 应用模型：仅支持Stage模型
- 权益申请：需在AGC平台开通对应场景的实况窗权益

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.LiveViewKit'
```
**解决方法**：确保HarmonyOS API version ≥ 4.1.0(11)，检查项目配置是否正确。

**问题2：实况窗开关校验失败**
```
Error: 1003500004 - LiveView is not enabled
```
**解决方法**：在设置>应用和元服务>应用名中开启实况窗开关。

**问题3：权益未申请**
```
Error: 1003500005 - The right of liveView is not enabled
```
**解决方法**：到AGC平台开通实况窗权益，并确保event字段与开通权益的场景匹配。

**问题4：参数类型错误**
```
Error: 401 - Parameter error
```
**解决方法**：检查参数类型是否正确，确保必填参数已填写，颜色格式为"#ARGB"16进制格式。

**问题5：实况窗ID冲突**
```
Error: 1003500006 - The liveView already exists
```
**解决方法**：更换实况窗ID重新创建，确保ID唯一。

## 常见问题与解决方法

### Q1：实况窗无法显示？
**原因**：
- 实况窗开关关闭
- 应用不在前台运行
- 权益未开通
- event字段与权益场景不匹配

**解决方法**：
- 检查实况窗开关状态：调用isLiveViewEnabled()
- 确保应用在前台运行
- 到AGC平台开通实况窗权益
- 确认event字段与开通权益的场景匹配

### Q2：实况窗创建失败？
**原因**：
- 参数错误
- 实况窗ID已存在
- 实况窗调用频率超限
- 网络不可达

**解决方法**：
- 检查参数类型和必填字段
- 更换实况窗ID重新创建
- 降低实况窗调用频率（创建≤每秒1个）
- 检查网络连接

### Q3：实况窗更新失败？
**原因**：
- 实况窗不存在或已结束
- 序列号错误
- 实况窗调用频率超限

**解决方法**：
- 检查实况窗是否创建成功
- 确保序列号大于当前实况窗的序列号
- 降低实况窗调用频率（更新≤每秒5个）

### Q4：如何配置天气动效背景？
**原因**：需要配置weatherInfo参数

**解决方法**：
- 设置weatherType：雨、雪天气支持动效背景
- 设置locationType：本地天气（LOCATION_TYPE_LOCAL）或目的地天气（LOCATION_TYPE_DESTINATION）
- 设置highTemperature和lowTemperature：展示温度信息
- 注意版本要求：目的地天气6.0.0(20)开始支持，本地天气6.0.2(22)开始支持

### Q5：如何配置计时器功能？
**原因**：需要配置timer参数

**解决方法**：
- 在LiveView对象中配置timer字段
- 设置time：计时器初始值（毫秒）
- 设置isCountdown：是否为倒计时
- 设置isPaused：是否暂停
- 在支持的字段中使用占位符${placeholder.timer}
- 注意版本要求：API version 5.0.0(12)开始支持

### Q6：地理围栏触发实况窗如何使用？
**原因**：需要使用startLiveViewByTrigger API

**解决方法**：
- 构建LiveView对象：配置实况窗内容
- 构建Trigger对象：配置地理围栏触发条件
- 调用startLiveViewByTrigger(liveView, trigger)
- 检查地理围栏开关状态：调用isGeofenceTriggerEnabled()
- 检查GPS开关状态：调用geoLocationManager.isLocationEnabled()
- 注意版本要求：API version 6.1.0(23)开始支持

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success/failed",
  "resultCode": 0,
  "message": "实况窗创建成功",
  "liveViewId": 106,
  "event": "DELIVERY",
  "sequence": 1,
  "apiUsed": [
    "liveViewManager.isLiveViewEnabled()",
    "liveViewManager.startLiveView()"
  ]
}
```

**结果码说明**：
- 0：成功
- 1：固定区更新/结束失败
- 2：辅助区更新/结束失败
- 3：扩展区更新/结束失败
- 4：实况胶囊更新/结束失败
- 5：外屏更新/结束失败

## 参考文档

- [构建本地实况窗开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/liveview-create-locally)
- [liveViewManager API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/liveview-liveviewmanager)
- [实况窗错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/liveview-error-code)
- [实况窗权益说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/liveview-rights)
- [实况窗SampleCode](https://gitcode.com/HarmonyOS_Samples/live-view-kit_-sample-code_-clientdemo_-arkts)

## 完整示例代码

- [进度可视化模板示例](assets/example_progress_liveview.ets)
- [强调文本模板示例](assets/example_pickup_liveview.ets)
- [左右文本模板示例](assets/example_flight_liveview.ets)
- [赛事比分模板示例](assets/example_score_liveview.ets)
- [导航模板示例](assets/example_navigation_liveview.ets)
- [地理围栏触发示例](assets/example_geofence_liveview.ets)
- [实况窗控制器完整示例](assets/example_liveview_controller.ets)

## 测试用例

### 正向测试用例
- [创建进度可视化模板实况窗](tests/test_progress_liveview.py)：测试外卖配送场景实况窗创建
- [创建强调文本模板实况窗](tests/test_pickup_liveview.py)：测试取餐场景实况窗创建
- [创建左右文本模板实况窗](tests/test_flight_liveview.py)：测试航班场景实况窗创建
- [创建赛事比分模板实况窗](tests/test_score_liveview.py)：测试赛事场景实况窗创建
- [创建导航模板实况窗](tests/test_navigation_liveview.py)：测试导航场景实况窗创建
- [创建地理围栏触发实况窗](tests/test_geofence_liveview.py)：测试快递场景地理围栏触发实况窗

### 边界测试用例
- [实况窗ID边界值测试](tests/test_liveview_id_boundary.py)：测试ID范围[-2147483648, 2147483647]
- [序列号边界值测试](tests/test_sequence_boundary.py)：测试序列号范围[0, 2147483647]
- [进度值边界值测试](tests/test_progress_boundary.py)：测试进度范围[0, 100]
- [温度边界值测试](tests/test_temperature_boundary.py)：测试温度范围[-95℃, 58℃]
- [文本长度边界值测试](tests/test_text_length_boundary.py)：测试标题和内容长度限制

### 异常测试用例
- [实况窗开关关闭异常](tests/test_liveview_disabled.py)：测试实况窗开关关闭时的处理
- [权益未申请异常](tests/test_rights_not_enabled.py)：测试权益未申请时的错误处理
- [参数错误异常](tests/test_parameter_error.py)：测试参数类型错误时的处理
- [实况窗ID冲突异常](tests/test_liveview_already_exists.py)：测试实况窗ID已存在时的处理
- [网络失败异常](tests/test_network_error.py)：测试网络不可达时的降级处理
- [频率超限异常](tests/test_rate_limit_exceeded.py)：测试调用频率超限时的处理