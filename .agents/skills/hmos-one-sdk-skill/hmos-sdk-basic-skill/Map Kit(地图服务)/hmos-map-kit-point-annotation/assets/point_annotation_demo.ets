/**
 * 点注释基础示例
 * 功能: 在地图指定位置添加点注释标识
 * API: MapComponentController.addPointAnnotation
 * 版本: 4.1.0(11)
 */

import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct PointAnnotationDemo {
  private TAG = "PointAnnotationDemo";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  private pointAnnotation?: map.PointAnnotation;

  aboutToAppear(): void {
    // 初始化地图参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 32.020750,
          longitude: 118.788765
        },
        zoom: 14
      }
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();

        // 创建点注释
        await this.createPointAnnotation();
      } else {
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  /**
   * 创建点注释
   */
  private async createPointAnnotation(): Promise<void> {
    // 准备点注释参数
    let pointAnnotationOptions: mapCommon.PointAnnotationParams = {
      // 必填: 点注释位置坐标(WGS84坐标系)
      position: {
        latitude: 32.020750,
        longitude: 118.788765
      },
      
      // 可选: 是否支持去重(与地图POI名称相同时)
      repeatable: true,
      
      // 可选: 碰撞规则(NAME/ALL/NONE)
      collisionRule: mapCommon.CollisionRule.NAME,
      
      // 必填: 标题数组(长度1-3)
      titles: [{
        content: "南京夫子庙",
        color: 0xFF000000,
        fontSize: 15,
        strokeColor: 0xFFFFFFFF,
        strokeWidth: 2,
        fontStyle: mapCommon.FontStyle.ITALIC
      }],
      
      // 可选: 图标(相对路径,文件在resources/rawfile目录)
      icon: "",
      
      // 可选: 是否展示图标
      showIcon: true,
      
      // 可选: 锚点位置
      anchorU: 0.5,
      anchorV: 1,
      
      // 可选: 碰撞后是否仍能显示
      forceVisible: false,
      
      // 可选: 碰撞优先级(数值越大优先级越低)
      priority: 3,
      
      // 可选: 显示层级范围
      minZoom: 2,
      maxZoom: 20,
      
      // 可选: 是否可见
      visible: true,
      
      // 可选: 叠加层级
      zIndex: 10
    };

    try {
      this.pointAnnotation = await this.mapController?.addPointAnnotation(pointAnnotationOptions);
      console.info(this.TAG, 'PointAnnotation created successfully');
      
      // 更新点注释属性
      this.updatePointAnnotation();
      
      // 设置点击事件监听
      this.setupClickEvent();
    } catch (e) {
      console.error(this.TAG, `Failed to create pointAnnotation, code: ${e.code}, message: ${e.message}`);
    }
  }

  /**
   * 更新点注释属性
   */
  private updatePointAnnotation(): void {
    if (!this.pointAnnotation) {
      console.warn(this.TAG, 'PointAnnotation not created');
      return;
    }

    // 设置显示层级为3~14级
    this.pointAnnotation.setZoom(3, 14);
    
    // 设置碰撞优先级为10
    this.pointAnnotation.setPriority(10);
    
    console.info(this.TAG, 'PointAnnotation properties updated');
  }

  /**
   * 设置点击事件监听
   */
  private setupClickEvent(): void {
    if (!this.mapEventManager) {
      console.warn(this.TAG, 'MapEventManager not initialized');
      return;
    }

    let callback = (pointAnnotation: map.PointAnnotation) => {
      console.info(this.TAG, `PointAnnotation clicked, id: ${pointAnnotation.getId()}`);
    };

    // 注册点击事件监听
    this.mapEventManager.on("pointAnnotationClick", callback);
    console.info(this.TAG, 'Click event listener registered');
  }

  build() {
    Stack() {
      Column() {
        // 地图组件
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('100%')
      }
      .width('100%')
    }
    .height('100%')
  }
}