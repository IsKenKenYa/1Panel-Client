/**
 * 点注释动画示例
 * 功能: 设置点注释缩放动画和标题动画
 * API: PointAnnotation.setAnimation, PointAnnotation.startAnimation
 * API: PointAnnotation.setTitleAnimation, PointAnnotation.startTitleAnimation
 * 版本: 4.1.0(11)
 */

import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct PointAnnotationAnimation {
  private TAG = "PointAnnotationAnimation";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  private pointAnnotation?: map.PointAnnotation;

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
        await this.createPointAnnotationWithAnimation();
      } else {
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  /**
   * 创建点注释并设置动画
   */
  private async createPointAnnotationWithAnimation(): Promise<void> {
    let pointAnnotationOptions: mapCommon.PointAnnotationParams = {
      position: {
        latitude: 32.020750,
        longitude: 118.788765
      },
      titles: [{
        content: "南京夫子庙",
        fontSize: 15
      }],
      icon: "",
      showIcon: true,
      minZoom: 2,
      maxZoom: 20,
      visible: true
    };

    try {
      this.pointAnnotation = await this.mapController?.addPointAnnotation(pointAnnotationOptions);
      console.info(this.TAG, 'PointAnnotation created');
      
      // 设置缩放动画
      this.setupScaleAnimation();
      
      // 设置标题动画
      this.setupTitleAnimation();
    } catch (e) {
      console.error(this.TAG, `Failed to create pointAnnotation, code: ${e.code}, message: ${e.message}`);
    }
  }

  /**
   * 设置缩放动画
   */
  private setupScaleAnimation(): void {
    if (!this.pointAnnotation) {
      return;
    }

    // 创建缩放动画: 从1倍放大到3倍
    let animation: map.ScaleAnimation = new map.ScaleAnimation(1, 3, 1, 3);
    
    // 设置动画时长(单位: ms)
    animation.setDuration(3000);
    
    // 设置动画开始监听
    animation.on("animationStart", () => {
      console.info(this.TAG, "Scale animation started");
    });
    
    // 设置动画结束监听
    animation.on("animationEnd", () => {
      console.info(this.TAG, "Scale animation ended");
    });
    
    // 设置动画完成状态
    animation.setFillMode(map.AnimationFillMode.BACKWARDS);
    
    // 设置动画重复方式
    animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
    
    // 设置动画插值器(线性)
    animation.setInterpolator(Curve.Linear);
    
    // 设置动画重复次数
    animation.setRepeatCount(100);
    
    // 设置动画到点注释
    this.pointAnnotation.setAnimation(animation);
    
    // 启动动画
    this.pointAnnotation.startAnimation();
    
    console.info(this.TAG, "Scale animation configured and started");
  }

  /**
   * 设置标题动画
   */
  private setupTitleAnimation(): void {
    if (!this.pointAnnotation) {
      return;
    }

    // 创建字体大小动画: 从15变到45
    let animation: map.FontSizeAnimation = new map.FontSizeAnimation(15, 45);
    
    // 设置动画时长(单位: ms)
    animation.setDuration(3000);
    
    // 设置动画监听
    animation.on("animationStart", () => {
      console.info(this.TAG, "Title animation started");
    });
    
    animation.on("animationEnd", () => {
      console.info(this.TAG, "Title animation ended");
    });
    
    // 设置动画完成状态
    animation.setFillMode(map.AnimationFillMode.FORWARDS);
    
    // 设置动画重复方式
    animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
    
    // 设置动画插值器
    animation.setInterpolator(Curve.Linear);
    
    // 设置动画重复次数
    animation.setRepeatCount(100);
    
    // 设置标题动画到点注释
    this.pointAnnotation.setTitleAnimation(animation);
    
    // 启动标题动画
    this.pointAnnotation.startTitleAnimation();
    
    console.info(this.TAG, "Title animation configured and started");
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