/**
 * 点注释点击事件示例
 * 功能: 监听点注释点击事件
 * API: MapEventManager.on, MapEventManager.off
 * 版本: 4.1.0(11)
 */

import { MapComponent, mapCommon, map } from '@kit.BasicServicesKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct PointAnnotationClickEvent {
  private TAG = "PointAnnotationClickEvent";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  private pointAnnotation?: map.PointAnnotation;
  private clickCallback?: (pointAnnotation: map.PointAnnotation) => void;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 32.020750,
          longitude: 118.788765
        },
        zoom: 14
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        
        // 创建点注释
        await this.createPointAnnotation();
        
        // 设置点击事件监听
        this.setupClickEventListener();
      } else {
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  /**
   * 创建点注释
   */
  private async createPointAnnotation(): Promise<void> {
    let pointAnnotationOptions: mapCommon.PointAnnotationParams = {
      position: {
        latitude: 32.020750,
        longitude: 118.788765
      },
      titles: [{
        content: "南京夫子庙 - 点击查看详情",
        fontSize: 15
      }],
      icon: "",
      showIcon: true,
      visible: true
    };

    try {
      this.pointAnnotation = await this.mapController?.addPointAnnotation(pointAnnotationOptions);
      console.info(this.TAG, 'PointAnnotation created for click event test');
    } catch (e) {
      console.error(this.TAG, `Failed to create pointAnnotation, code: ${e.code}, message: ${e.message}`);
    }
  }

  /**
   * 设置点击事件监听
   */
  private setupClickEventListener(): void {
    if (!this.mapEventManager) {
      console.warn(this.TAG, 'MapEventManager not initialized');
      return;
    }

    // 定义点击事件回调函数
    this.clickCallback = (pointAnnotation: map.PointAnnotation) => {
      let annotationId = pointAnnotation.getId();
      console.info(this.TAG, `PointAnnotation clicked! ID: ${annotationId}`);
      
      // 获取点注释位置
      let position = pointAnnotation.getPosition();
      console.info(this.TAG, `Position: lat=${position.latitude}, lng=${position.longitude}`);
      
      // 获取点注释标题
      let titleText = pointAnnotation.getTitleText();
      console.info(this.TAG, `Title: ${titleText.content}`);
      
      // 可以在这里添加更多交互逻辑
      // 例如: 显示详情弹窗、导航到该位置等
      this.showAnnotationDetails(pointAnnotation);
    };

    // 注册点击事件监听
    this.mapEventManager.on("pointAnnotationClick", this.clickCallback);
    console.info(this.TAG, 'Click event listener registered');
  }

  /**
   * 显示点注释详情(示例逻辑)
   */
  private showAnnotationDetails(pointAnnotation: map.PointAnnotation): void {
    console.info(this.TAG, 'Showing annotation details...');
    
    // 这里可以添加UI交互逻辑
    // 例如: 显示AlertDialog、跳转到详情页面等
    // AlertDialog.show({
    //   title: '点注释详情',
    //   message: `ID: ${pointAnnotation.getId()}`,
    //   confirm: {
    //     value: '确定',
    //     action: () => {}
    //   }
    // });
  }

  /**
   * 取消点击事件监听(可选)
   */
  private removeClickEventListener(): void {
    if (!this.mapEventManager || !this.clickCallback) {
      return;
    }

    // 取消监听
    this.mapEventManager.off("pointAnnotationClick", this.clickCallback);
    console.info(this.TAG, 'Click event listener removed');
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('100%')
      }
      .width('100%')
    }
    .height('100%')
  }
}