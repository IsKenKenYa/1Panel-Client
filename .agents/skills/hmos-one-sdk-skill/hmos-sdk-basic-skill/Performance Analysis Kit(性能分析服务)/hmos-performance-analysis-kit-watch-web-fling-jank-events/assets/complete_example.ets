// EntryAbility.ets - 应用入口，添加事件观察者
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { webIdToUrlMap } from '../pages/ArkWebPage';
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', 'EntryAbility onCreate');
    
    // 添加ArkWeb抛滑丢帧事件观察者
    this.setupWebJankWatcher();
  }
  
  private setupWebJankWatcher(): void {
    try {
      const holder = hiAppEvent.addWatcher({
        // 观察者名称，用于标识不同的观察者
        name: 'webJankWatcher',
        // 订阅过滤条件，订阅ArkWeb抛滑丢帧事件
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.SCROLL_ARKWEB_FLING_JANK]
          }
        ],
        // 实时回调函数，事件触发时自动调用
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          this.handleWebJankEvent(domain, appEventGroups);
        }
      });
      
      if (holder === null) {
        hilog.error(0x0000, 'testTag', 'Failed to add watcher, holder is null');
      } else {
        hilog.info(0x0000, 'testTag', 'Successfully added web jank watcher');
      }
    } catch (error) {
      hilog.error(0x0000, 'testTag', `Error adding watcher: ${JSON.stringify(error)}`);
    }
  }
  
  private handleWebJankEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 输出事件基本信息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
        
        // 获取丢帧详情参数
        const startTime = eventInfo.params['start_time'];
        const duration = eventInfo.params['duration'];
        const webId = eventInfo.params['web_id'];
        const maxAppFrameTime = eventInfo.params['max_app_frame_time'];
        
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.start_time=${startTime}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.duration=${duration}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.web_id=${webId}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.max_app_frame_time=${maxAppFrameTime}`);
        
        // 通过web_id查询对应的URL
        const currentUrl = webIdToUrlMap.get(webId);
        hilog.info(0x0000, 'testTag', `HiAppEvent get currentUrl=${currentUrl || 'Unknown URL'}`);
        
        // 可以根据业务需求进行进一步处理，例如：
        // 1. 记录丢帧事件到本地数据库
        // 2. 发送告警通知
        // 3. 触发性能优化逻辑
      }
    }
  }
  
  destroy(): void {
    hilog.info(0x0000, 'testTag', 'EntryAbility destroy');
  }
}

// ArkWebPage.ets - Web组件页面，维护web_id映射
import web_webview from '@ohos.web.webview';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';

// 全局映射表：web_id -> URL
export const webIdToUrlMap = new Map<number, string>();

@Entry
@Component
struct ArkWebPage {
  controller = new web_webview.WebviewController();
  @State message: string = 'Web页面监控';
  
  build() {
    Column() {
      // 标题
      Text(this.message)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })
      
      // Web组件
      Web({ src: 'https://www.baidu.com', controller: this.controller })
        .width('100%')
        .height('80%')
        .onPageBegin((event) => {
          if (event) {
            const newUrl = event.url;
            const webId = this.controller.getWebId();
            
            // 更新映射关系
            webIdToUrlMap.set(webId, newUrl);
            hilog.info(0x0000, 'testTag', `Web page loaded: webId=${webId}, url=${newUrl}`);
          }
        })
        .onPageEnd(() => {
          hilog.info(0x0000, 'testTag', 'Web page load completed');
          
          // 模拟丢帧场景：每2s阻塞主线程200ms
          this.simulateJankScenario();
        })
        .javaScriptAccess(true)
        .domStorageAccess(true)
      
      // 返回按钮
      Button('返回主页')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .height('100%')
  }
  
  private simulateJankScenario(): void {
    // 仅用于测试：定期阻塞主线程模拟丢帧
    setInterval(() => {
      const endTime = Date.now() + 200;
      while (Date.now() < endTime) {
        // 模拟耗时操作
      }
    }, 2000);
  }
}

// Index.ets - 主页面，跳转到Web页面
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('ArkWeb丢帧监控演示')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })
      
      Button('打开Web页面测试丢帧')
        .width('80%')
        .height(60)
        .margin({ top: 30 })
        .backgroundColor('#0D9FFB')
        .onClick(() => {
          router.pushUrl({ url: 'pages/ArkWebPage' });
        })
      
      Text('说明：')
        .fontSize(16)
        .margin({ top: 20 })
      
      Text('1. 点击按钮打开Web页面')
        .fontSize(14)
        .margin({ top: 10 })
      
      Text('2. 快速滑动页面触发丢帧')
        .fontSize(14)
        .margin({ top: 5 })
      
      Text('3. 系统自动捕获丢帧事件并输出日志')
        .fontSize(14)
        .margin({ top: 5 })
      
      Text('4. 在DevEco Studio Log窗口查看事件数据')
        .fontSize(14)
        .margin({ top: 5 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

// 配置文件：main_pages.json
{
  "src": [
    "pages/Index",
    "pages/ArkWebPage"
  ]
}

// 配置文件：module.json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}