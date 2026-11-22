/**
 * 流场图层完整示例
 * 本示例展示如何在HarmonyOS地图上添加流场图层，可视化显示风场数据
 * 
 * 功能：
 * 1. 添加流场图层到地图组件
 * 2. 配置粒子样式（数量、颜色、速度）
 * 3. 使用GRIB2格式的流场数据
 * 4. 动态更新粒子样式
 * 
 * API版本要求：6.0.0(20)及以上
 * 系统能力要求：SystemCapability.Map.Core.EnhancedOverlay
 */

import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

/**
 * 流场图层示例组件
 */
@Entry
@Component
struct MapFlowFieldOverlayDemo {
  private TAG = "MapFlowFieldOverlayDemo";
  private mapOption?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private fieldOverlay?: map.FlowFieldOverlay;

  /**
   * 组件即将出现时初始化
   */
  aboutToAppear(): void {
    // 初始化地图配置
    this.mapOption = {
      position: {
        target: {
          latitude: 31.984410259206815,  // 地图中心纬度
          longitude: 118.76625379397866  // 地图中心经度
        },
        zoom: 4  // 缩放级别
      },
      scaleControlsEnabled: true  // 显示比例尺
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info(this.TAG, 'Map initialized successfully');
        
        // 添加流场图层
        await this.addFlowFieldOverlay();
      } else {
        console.error(this.TAG, `Map initialization failed, code:${err.code}, message:${err.message}`);
      }
    };
  }

  /**
   * 添加流场图层
   */
  private async addFlowFieldOverlay(): Promise<void> {
    try {
      // 准备流场数据（GRIB2规范的JSON格式）
      const flowData = this.prepareFlowFieldData();
      
      // 验证数据格式
      if (!this.validateFlowFieldData(flowData)) {
        console.error(this.TAG, 'Invalid flow field data format');
        return;
      }

      // 构建流场参数
      const params: mapCommon.FlowFieldOverlayParams = {
        data: flowData,
        style: {
          count: 2000,         // 粒子数量
          color: 0xff0000ff,   // 粒子颜色（蓝色）
          maxSpeed: 100,       // 最大速度 m/s
          speedFactor: 1       // 速度因子
        }
      };

      // 添加流场图层
      this.fieldOverlay = await this.mapController?.addFlowFieldOverlay(params);
      console.info(this.TAG, 'Flow field overlay added successfully');
      
      // 获取当前样式验证
      const currentStyle = this.fieldOverlay?.getStyle();
      if (currentStyle) {
        console.info(this.TAG, `Particle count: ${currentStyle.count}`);
        console.info(this.TAG, `Particle color: ${currentStyle.color}`);
        console.info(this.TAG, `Max speed: ${currentStyle.maxSpeed}`);
        console.info(this.TAG, `Speed factor: ${currentStyle.speedFactor}`);
      }
      
    } catch (error: any) {
      this.handleAddFlowFieldError(error);
    }
  }

  /**
   * 准备流场数据
   * 数据格式：GRIB2规范的JSON，包含U方向（横向）和V方向（纵向）两个数据对象
   */
  private prepareFlowFieldData(): string {
    const flowFieldData = [
      {
        header: {
          parameterUnit: "m.s-1",        // 风速单位
          parameterNumber: 2,            // 2为U方向（横向）
          dx: 10,                        // 横向步长（经度）
          dy: 20,                        // 纵向步长（纬度）
          parameterNumberName: "U-component-wind",
          la2: -90,                      // 纬度范围终点
          la1: 90,                       // 纬度范围起点
          parameterCategory: 2,
          lo1: 0,                        // 经度范围起点
          lo2: 359.75,                   // 经度范围终点
          ny: 4,                         // 纵向格子数量
          nx: 4,                         // 横向格子数量
          numberPoints: 16               // 数据点数量
        },
        data: [2, 2, 2, 2, 2, 2, 2, 2, -10, -10, -1, -1, -1, -1, -3, 2]  // 横向速度数据
      },
      {
        header: {
          parameterUnit: "m.s-1",
          parameterNumber: 3,            // 3为V方向（纵向）
          dx: 4,
          dy: 4,
          parameterNumberName: "V-component-wind",
          la2: -90,
          la1: 90,
          parameterCategory: 2,
          lo1: 0,
          lo2: 359.75,
          ny: 4,
          nx: 4,
          numberPoints: 16
        },
        data: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -2, -3, -1]  // 纵向速度数据
      }
    ];
    
    return JSON.stringify(flowFieldData);
  }

  /**
   * 验证流场数据格式
   */
  private validateFlowFieldData(data: string): boolean {
    try {
      const parsedData = JSON.parse(data);
      
      // 检查是否为数组且包含两个对象
      if (!Array.isArray(parsedData) || parsedData.length !== 2) {
        return false;
      }
      
      // 检查每个对象的完整性
      for (const item of parsedData) {
        if (!item.header || !item.data) {
          return false;
        }
        
        // 检查data长度是否等于numberPoints
        if (!Array.isArray(item.data) || item.data.length !== item.header.numberPoints) {
          return false;
        }
        
        // 检查必需的header字段
        const requiredFields = ['parameterUnit', 'parameterNumber', 'dx', 'dy', 
                               'la1', 'la2', 'lo1', 'lo2', 'nx', 'ny', 'numberPoints'];
        for (const field of requiredFields) {
          if (item.header[field] === undefined) {
            return false;
          }
        }
      }
      
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 处理添加流场图层错误
   */
  private handleAddFlowFieldError(error: any): void {
    console.error(this.TAG, `Failed to add flow field overlay`);
    
    switch (error.code) {
      case 1022100001:
        console.error(this.TAG, 'Error: Operation object does not exist');
        console.error(this.TAG, 'Solution: Check mapController initialization');
        break;
      case 401:
        console.error(this.TAG, 'Error: Invalid input parameter');
        console.error(this.TAG, 'Solution: Check data format and style values');
        break;
      default:
        console.error(this.TAG, `Error code: ${error.code}, message: ${error.message}`);
        console.error(this.TAG, 'Solution: Check API version >= 6.0.0(20) and GRIB2 data format');
        break;
    }
  }

  /**
   * 更新粒子样式示例
   */
  private async updateFlowFieldStyle(): Promise<void> {
    if (!this.fieldOverlay) {
      console.error(this.TAG, 'Flow field overlay not initialized');
      return;
    }
    
    try {
      // 设置新的粒子样式
      const newStyle: mapCommon.ParticleStyle = {
        count: 3000,          // 增加粒子数量
        color: 0xff00ff00,    // 改为绿色
        maxSpeed: 80,         // 降低最大速度
        speedFactor: 0.8      // 降低速度因子
      };
      
      this.fieldOverlay.setStyle(newStyle);
      console.info(this.TAG, 'Flow field style updated successfully');
      
      // 获取并验证新样式
      const currentStyle = this.fieldOverlay.getStyle();
      console.info(this.TAG, 'Updated style:', JSON.stringify(currentStyle));
      
    } catch (error: any) {
      console.error(this.TAG, `Failed to update style: ${error.message}`);
    }
  }

  /**
   * 构建UI界面
   */
  build() {
    Stack() {
      Column() {
        // 地图组件
        MapComponent({ mapOptions: this.mapOption, mapCallback: this.callback })
          .width('100%')
          .height('100%');
      }
      .width('100%')
      
      // 控制按钮区域（可选）
      Column() {
        Button('更新样式')
          .onClick(() => {
            this.updateFlowFieldStyle();
          })
          .margin({ top: 10 })
      }
      .width('100%')
      .height('50')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .height('100%')
  }
}