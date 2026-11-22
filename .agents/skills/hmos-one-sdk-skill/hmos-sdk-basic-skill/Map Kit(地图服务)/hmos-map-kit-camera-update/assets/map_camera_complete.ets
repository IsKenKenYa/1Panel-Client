/**
 * 完整地图页面示例
 * 综合演示地图相机移动的所有功能
 */

import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapCameraCompleteDemo {
  private TAG = "MapCameraCompleteDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;
  
  @State currentZoom: number = 10;
  @State animationDuration: number = 1000;
  @State targetLatitude: string = '39.9';
  @State targetLongitude: string = '116.4';
  @State targetZoom: string = '10';
  @State statusMessage: string = '就绪';

  aboutToAppear(): void {
    // 地图初始化参数
    this.mapOptions = {
      mapType: mapCommon.MapType.STANDARD,
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      },
      zoomControlsEnabled: true,
      compassControlsEnabled: true,
      scaleControlsEnabled: true
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = mapController.getEventManager();
        
        // 监听地图加载完成事件
        this.mapEventManager.on('mapLoad', () => {
          console.info(this.TAG, 'Map loaded');
          this.statusMessage = '地图加载完成';
          this.updateCurrentZoom();
        });
        
        // 监听相机变化事件
        this.mapEventManager.on('cameraChange', () => {
          this.updateCurrentZoom();
        });
        
        console.info(this.TAG, 'Map initialized');
        this.statusMessage = '地图初始化成功';
      } else {
        console.error(this.TAG, 'Map initialization failed');
        this.statusMessage = '地图初始化失败';
      }
    };
  }

  // 更新当前缩放级别显示
  private updateCurrentZoom(): void {
    if (this.mapController) {
      let position = this.mapController.getCameraPosition();
      this.currentZoom = position.zoom;
    }
  }

  // 移动到指定位置（非动画）
  private moveToTargetPosition(): void {
    try {
      let lat = parseFloat(this.targetLatitude);
      let lon = parseFloat(this.targetLongitude);
      let zoom = parseFloat(this.targetZoom);
      
      if (this.validateParameters(lat, lon, zoom)) {
        let cameraPosition: mapCommon.CameraPosition = {
          target: { latitude: lat, longitude: lon },
          zoom: zoom
        };
        let cameraUpdate = map.newCameraPosition(cameraPosition);
        this.mapController?.moveCamera(cameraUpdate);
        this.statusMessage = `立即移动到 (${lat}, ${lon}) 缩放${zoom}`;
        this.updateCurrentZoom();
      }
    } catch (error) {
      this.statusMessage = '参数解析失败';
      console.error(this.TAG, 'Parameter parsing failed:', error.message);
    }
  }

  // 动画移动到指定位置
  private animateToTargetPosition(): void {
    try {
      let lat = parseFloat(this.targetLatitude);
      let lon = parseFloat(this.targetLongitude);
      let zoom = parseFloat(this.targetZoom);
      
      if (this.validateParameters(lat, lon, zoom)) {
        let cameraPosition: mapCommon.CameraPosition = {
          target: { latitude: lat, longitude: lon },
          zoom: zoom
        };
        let cameraUpdate = map.newCameraPosition(cameraPosition);
        this.mapController?.animateCamera(cameraUpdate, this.animationDuration);
        this.statusMessage = `动画移动开始 (${this.animationDuration}ms)`;
      }
    } catch (error) {
      this.statusMessage = '参数解析失败';
    }
  }

  // 动画移动并返回结果
  private async animateToTargetWithStatus(): Promise<void> {
    try {
      let lat = parseFloat(this.targetLatitude);
      let lon = parseFloat(this.targetLongitude);
      let zoom = parseFloat(this.targetZoom);
      
      if (this.validateParameters(lat, lon, zoom)) {
        let cameraPosition: mapCommon.CameraPosition = {
          target: { latitude: lat, longitude: lon },
          zoom: zoom
        };
        let cameraUpdate = map.newCameraPosition(cameraPosition);
        
        this.statusMessage = '动画执行中...';
        let result = await this.mapController?.animateCameraStatus(cameraUpdate, this.animationDuration);
        
        if (result) {
          if (result.isFinished) {
            this.statusMessage = '动画完成';
            this.updateCurrentZoom();
          } else if (result.isCanceled) {
            this.statusMessage = '动画被取消';
          }
        }
      }
    } catch (error) {
      if (error.code === 401) {
        this.statusMessage = '错误：参数无效';
      } else {
        this.statusMessage = `错误：${error.message}`;
      }
    }
  }

  // 验证参数有效性
  private validateParameters(lat: number, lon: number, zoom: number): boolean {
    if (lat < -90 || lat > 90) {
      this.statusMessage = '错误：纬度范围 [-90, 90]';
      return false;
    }
    if (lon < -180 || lon >= 180) {
      this.statusMessage = '错误：经度范围 [-180, 180)';
      return false;
    }
    if (zoom < 2 || zoom > 20) {
      this.statusMessage = '错误：缩放范围 [2, 20]';
      return false;
    }
    return true;
  }

  // 放大一级
  private zoomIn(): void {
    let cameraUpdate = map.zoomIn();
    this.mapController?.animateCamera(cameraUpdate, 500);
    this.statusMessage = '放大一级';
  }

  // 缩小一级
  private zoomOut(): void {
    let cameraUpdate = map.zoomOut();
    this.mapController?.animateCamera(cameraUpdate, 500);
    this.statusMessage = '缩小一级';
  }

  // 设置缩放级别限制
  private setZoomLimits(): void {
    this.mapController?.setMinZoom(6);
    this.mapController?.setMaxZoom(16);
    this.statusMessage = '缩放限制：6-16';
  }

  // 设置相机边界（北京周边）
  private setBeijingBounds(): void {
    let bounds: mapCommon.LatLngBounds = {
      northeast: { latitude: 41.0, longitude: 117.5 },
      southwest: { latitude: 39.0, longitude: 115.5 }
    };
    this.mapController?.setLatLngBounds(bounds);
    this.statusMessage = '边界设置：北京周边';
  }

  // 停止动画
  private stopAnimation(): void {
    this.mapController?.stopAnimation();
    this.statusMessage = '动画已停止';
  }

  // 快速定位到预设位置
  private moveToPresetLocation(location: string): void {
    let positions: Record<string, mapCommon.CameraPosition> = {
      'beijing': { target: { latitude: 39.9, longitude: 116.4 }, zoom: 12 },
      'shanghai': { target: { latitude: 31.2, longitude: 121.5 }, zoom: 12 },
      'nanjing': { target: { latitude: 32.0, longitude: 118.8 }, zoom: 11 },
      'hangzhou': { target: { latitude: 30.2, longitude: 120.2 }, zoom: 11 }
    };
    
    let position = positions[location];
    if (position) {
      let cameraUpdate = map.newCameraPosition(position);
      this.mapController?.animateCamera(cameraUpdate, this.animationDuration);
      this.statusMessage = `移动到${location}`;
    }
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
      
      Column() {
        // 状态显示
        Text(`状态: ${this.statusMessage}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .padding(5)
          .backgroundColor('#F0F0F0')
          .width('100%')
        
        Text(`当前缩放级别: ${this.currentZoom.toFixed(1)}`)
          .fontSize(12)
          .margin(5)
        
        Divider().margin(5)
        
        // 自定义位置输入
        Text('自定义位置移动')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin(5)
        
        TextInput({ placeholder: '纬度 (默认39.9)', text: this.targetLatitude })
          .onChange((value) => this.targetLatitude = value)
          .width('90%')
          .height(35)
          .margin(3)
        
        TextInput({ placeholder: '经度 (默认116.4)', text: this.targetLongitude })
          .onChange((value) => this.targetLongitude = value)
          .width('90%')
          .height(35)
          .margin(3)
        
        TextInput({ placeholder: '缩放级别 (默认10)', text: this.targetZoom })
          .onChange((value) => this.targetZoom = value)
          .width('90%')
          .height(35)
          .margin(3)
        
        Row() {
          Button('立即移动')
            .onClick(() => this.moveToTargetPosition())
            .width('45%')
            .margin(5)
          
          Button('动画移动')
            .onClick(() => this.animateToTargetPosition())
            .width('45%')
            .margin(5)
        }
        
        Button('动画移动+结果')
          .onClick(() => this.animateToTargetWithStatus())
          .width('90%')
          .margin(5)
        
        Divider().margin(5)
        
        // 快速缩放控制
        Text('快速缩放控制')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin(5)
        
        Row() {
          Button('放大')
            .onClick(() => this.zoomIn())
            .width('45%')
            .margin(5)
          
          Button('缩小')
            .onClick(() => this.zoomOut())
            .width('45%')
            .margin(5)
        }
        
        Button('设置缩放限制(6-16)')
          .onClick(() => this.setZoomLimits())
          .width('90%')
          .margin(5)
        
        Divider().margin(5)
        
        // 预设位置
        Text('预设位置')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin(5)
        
        Row() {
          Button('北京')
            .onClick(() => this.moveToPresetLocation('beijing'))
            .width('22%')
            .margin(2)
          
          Button('上海')
            .onClick(() => this.moveToPresetLocation('shanghai'))
            .width('22%')
            .margin(2)
          
          Button('南京')
            .onClick(() => this.moveToPresetLocation('nanjing'))
            .width('22%')
            .margin(2)
          
          Button('杭州')
            .onClick(() => this.moveToPresetLocation('hangzhou'))
            .width('22%')
            .margin(2)
        }
        
        Divider().margin(5)
        
        // 其他控制
        Button('设置北京边界')
          .onClick(() => this.setBeijingBounds())
          .width('90%')
          .margin(5)
        
        Button('停止动画')
          .onClick(() => this.stopAnimation())
          .width('90%')
          .margin(5)
          .backgroundColor('#FF6B6B')
      }
      .width('30%')
      .height('100%')
      .position({ x: '70%', y: 0 })
      .backgroundColor('#FFFFFF')
      .padding(10)
    }
    .height('100%')
  }
}