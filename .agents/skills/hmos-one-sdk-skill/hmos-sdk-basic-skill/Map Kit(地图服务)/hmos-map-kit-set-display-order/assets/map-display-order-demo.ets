/**
 * 设置地图元素压盖顺序完整示例
 * 本示例演示如何使用setDisplayOrder方法设置地图元素的显示顺序
 * API版本要求：≥5.0.0(12)
 */

import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapDisplayOrderDemo {
  private TAG = 'MapDisplayOrderDemo';
  
  // 地图初始化参数
  private mapOptions?: mapCommon.MapOptions;
  
  // 地图控制器
  private mapController?: map.MapComponentController;
  
  // 地图初始化回调
  private callback?: AsyncCallback<map.MapComponentController>;
  
  // 地图事件管理器
  private mapEventManager?: map.MapEventManager;
  
  // 地图元素对象
  private marker?: map.Marker;
  private bubble?: map.Bubble;
  
  /**
   * 组件生命周期 - 组件即将出现
   */
  aboutToAppear(): void {
    console.info(this.TAG, 'aboutToAppear start');
    
    // 初始化地图参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.26625379397866
        },
        zoom: 10
      }
    };
    
    // 定义地图初始化回调函数
    this.callback = async (err, mapController) => {
      if (!err) {
        // 地图初始化成功，获取控制器
        this.mapController = mapController;
        console.info(this.TAG, 'Map initialized successfully');
        
        // 获取事件管理器
        this.mapEventManager = this.mapController.getEventManager();
        
        // 监听地图加载完成事件
        let mapLoadCallback = () => {
          console.info(this.TAG, 'Map loaded');
        };
        this.mapEventManager.on('mapLoad', mapLoadCallback);
        
        // 步骤1：设置地图元素显示顺序（推荐在添加元素前设置）
        this.setMapDisplayOrder();
        
        // 步骤2：添加地图元素
        await this.addMapElements();
        
      } else {
        // 地图初始化失败
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }
  
  /**
   * 设置地图元素显示顺序
   * 使用setDisplayOrder方法设置四类地图元素的压盖关系
   */
  private setMapDisplayOrder(): void {
    console.info(this.TAG, 'setMapDisplayOrder start');
    
    // 前置校验：检查mapController是否已初始化
    if (!this.mapController) {
      console.error(this.TAG, 'Map controller is not initialized');
      return;
    }
    
    try {
      // 定义地图元素显示顺序数组
      // 顺序含义：从底层到顶层排列，后面的元素会压盖前面的元素
      // OVERLAY(1) - 覆盖物（MapCircle、MapPolygon、MapPolyline、MapArc、ImageOverlay、TraceOverlay）
      // POI(2) - 底图POI
      // CUSTOM_POI(3) - 支持碰撞的覆盖物（PointAnnotation、Bubble）
      // MARKER(4) - 标记（Marker、ClusterOverlay）
      let mapElementTypeArr: Array<mapCommon.MapElementType> = [
        mapCommon.MapElementType.OVERLAY,      // 最底层
        mapCommon.MapElementType.POI,          // 第二层
        mapCommon.MapElementType.CUSTOM_POI,   // 第三层
        mapCommon.MapElementType.MARKER        // 最顶层
      ];
      
      // 调用setDisplayOrder方法设置显示顺序
      this.mapController.setDisplayOrder(mapElementTypeArr);
      console.info(this.TAG, 'Display order set: OVERLAY -> POI -> CUSTOM_POI -> MARKER');
      
    } catch (error) {
      // 错误处理
      console.error(this.TAG, `Failed to set display order, code: ${error.code}, message: ${error.message}`);
      
      // 根据错误码进行不同处理
      if (error.code === 401) {
        console.error(this.TAG, 'Invalid parameter: array length must be 4 and contain all MapElementType values');
      }
    }
  }
  
  /**
   * 添加地图元素
   * 添加Marker、Bubble、ImageOverlay等地图元素
   */
  private async addMapElements(): Promise<void> {
    console.info(this.TAG, 'addMapElements start');
    
    // 添加Marker
    await this.addMarker();
    
    // 添加Bubble
    await this.addBubble();
    
    // 添加ImageOverlay（覆盖物）
    await this.addImageOverlay();
  }
  
  /**
   * 添加Marker标记
   * MARKER类型元素，会显示在最顶层（根据setDisplayOrder设置）
   */
  private async addMarker(): Promise<void> {
    console.info(this.TAG, 'addMarker start');
    
    if (!this.mapController) {
      console.error(this.TAG, 'Map controller is not initialized');
      return;
    }
    
    // 定义Marker参数
    let markerOptions: mapCommon.MarkerOptions = {
      position: {
        latitude: 31.984410259206815,
        longitude: 118.26625379397866
      },
      rotation: 0,
      visible: true,
      zIndex: 0,
      alpha: 1,
      anchorU: 0.5,
      anchorV: 1,
      clickable: true,
      draggable: true,
      flat: false
    };
    
    try {
      // 添加Marker
      this.marker = await this.mapController.addMarker(markerOptions);
      console.info(this.TAG, 'Marker added successfully');
      
    } catch (error) {
      console.error(this.TAG, `Failed to add marker, code: ${error.code}, message: ${error.message}`);
    }
  }
  
  /**
   * 添加Bubble气泡
   * CUSTOM_POI类型元素，会显示在第三层（根据setDisplayOrder设置）
   */
  private async addBubble(): Promise<void> {
    console.info(this.TAG, 'addBubble start');
    
    if (!this.mapController) {
      console.error(this.TAG, 'Map controller is not initialized');
      return;
    }
    
    // 定义Bubble参数
    let bubbleOptions: mapCommon.BubbleParams = {
      // 气泡位置
      positions: [[{
        latitude: 32.384410259206815,
        longitude: 118.26625379397866
      }]],
      
      // 设置图标，必须提供4个方向的图标（左上右下）
      // 图标需存放在resources/rawfile目录
      icons: [
        'speed_limit_10.png',
        'speed_limit_20.png',
        'speed_limit_30.png',
        'speed_limit_40.png'
      ],
      
      // 定义气泡的显示属性，为true时在被碰撞后仍能显示
      forceVisible: true,
      
      // 定义气泡碰撞优先级，数值越大优先级越低
      priority: 3,
      
      // 定义气泡展示的最小层级
      minZoom: 2,
      
      // 定义气泡展示的最大层级
      maxZoom: 20,
      
      // 定义气泡是否可见
      visible: true,
      
      // 定义气泡叠加层级属性
      zIndex: 1
    };
    
    try {
      // 添加Bubble
      this.bubble = await this.mapController.addBubble(bubbleOptions);
      console.info(this.TAG, 'Bubble added successfully');
      
    } catch (error) {
      console.error(this.TAG, `Failed to add bubble, code: ${error.code}, message: ${error.message}`);
    }
  }
  
  /**
   * 添加ImageOverlay图片覆盖物
   * OVERLAY类型元素，会显示在最底层（根据setDisplayOrder设置）
   */
  private async addImageOverlay(): Promise<void> {
    console.info(this.TAG, 'addImageOverlay start');
    
    if (!this.mapController) {
      console.error(this.TAG, 'Map controller is not initialized');
      return;
    }
    
    // 定义ImageOverlay参数
    let imageOverlayParams: mapCommon.ImageOverlayParams = {
      // 覆盖物范围（西南角和东北角）
      bounds: {
        southwest: {
          latitude: 32,
          longitude: 118
        },
        northeast: {
          latitude: 32.4,
          longitude: 118.4
        }
      },
      
      // 覆盖物图片，需存放在resources/rawfile目录
      image: 'icon/icon.png',
      
      // 透明度
      transparency: 0.3,
      
      // 层级
      zIndex: 101,
      
      // 锚点
      anchorU: 0.5,
      anchorV: 0.5,
      
      // 是否可点击
      clickable: true,
      
      // 是否可见
      visible: true,
      
      // 方位角
      bearing: 0
    };
    
    try {
      // 添加ImageOverlay
      await this.mapController.addImageOverlay(imageOverlayParams);
      console.info(this.TAG, 'ImageOverlay added successfully');
      
    } catch (error) {
      console.error(this.TAG, `Failed to add imageOverlay, code: ${error.code}, message: ${error.message}`);
    }
  }
  
  /**
   * 测试：设置不同的显示顺序
   * 演示如何改变默认顺序，让MARKER显示在底层
   */
  private testCustomOrder(): void {
    console.info(this.TAG, 'testCustomOrder start');
    
    if (!this.mapController) {
      console.error(this.TAG, 'Map controller is not initialized');
      return;
    }
    
    try {
      // 自定义顺序：MARKER在底层，OVERLAY在顶层
      let customOrder: Array<mapCommon.MapElementType> = [
        mapCommon.MapElementType.MARKER,      // 最底层
        mapCommon.MapElementType.CUSTOM_POI,  // 第二层
        mapCommon.MapElementType.POI,         // 第三层
        mapCommon.MapElementType.OVERLAY      // 最顶层
      ];
      
      this.mapController.setDisplayOrder(customOrder);
      console.info(this.TAG, 'Custom display order set: MARKER -> CUSTOM_POI -> POI -> OVERLAY');
      
    } catch (error) {
      console.error(this.TAG, `Failed to set custom order, code: ${error.code}, message: ${error.message}`);
    }
  }
  
  /**
   * 构建UI界面
   */
  build() {
    Stack() {
      Column() {
        // 地图组件
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('100%')
      }
      .width('100%')
      .height('100%')
      
      // 测试按钮（可选）
      Column() {
        Button('测试自定义顺序')
          .onClick(() => {
            this.testCustomOrder();
          })
          .margin({ top: 20 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .height('100%')
  }
}