import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 穿戴设备传感器获取完整示例
 * 功能：获取传感器列表、订阅传感器数据、取消订阅、设备断线重连处理
 */
@Entry
@Component
struct DeviceSensorExample {
  @State deviceList: wearEngine.Device[] = [];
  @State targetDevice: wearEngine.Device | null = null;
  @State sensorList: wearEngine.Sensor[] = [];
  @State subscribedSensors: Map<wearEngine.SensorType, (result: wearEngine.SensorResult) => void> = new Map();
  @State sensorDataHistory: string[] = [];
  @State connectionStatus: string = '未连接';
  
  private deviceClient: wearEngine.DeviceClient | null = null;
  private authClient: wearEngine.AuthClient | null = null;
  private sensorClient: wearEngine.SensorClient | null = null;
  private monitorClient: wearEngine.MonitorClient | null = null;

  aboutToAppear() {
    this.initClients();
  }

  aboutToDisappear() {
    this.cleanup();
  }

  /**
   * 初始化所有客户端
   */
  private async initClients() {
    try {
      this.deviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
      this.authClient = wearEngine.getAuthClient(this.getUIContext().getHostContext());
      this.sensorClient = wearEngine.getSensorClient(this.getUIContext().getHostContext());
      this.monitorClient = wearEngine.getMonitorClient(this.getUIContext().getHostContext());
      
      console.info('成功初始化所有客户端');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`初始化客户端失败. Code: ${err.code}, Message: ${err.message}`);
    }
  }

  /**
   * 步骤1：申请传感器权限
   */
  private async requestSensorPermission(): Promise<boolean> {
    if (!this.authClient) {
      console.error('AuthClient未初始化');
      return false;
    }

    try {
      // 先申请运动传感器权限
      let request: wearEngine.AuthorizationRequest = {
        permissions: [wearEngine.Permission.MOTION_SENSOR]
      };
      
      let response = await this.authClient.requestAuthorization(request);
      
      if (response.permissions.includes(wearEngine.Permission.MOTION_SENSOR)) {
        console.info('用户已授权运动传感器权限');
        return true;
      } else {
        console.error('用户未授权运动传感器权限');
        return false;
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`申请权限失败. Code: ${err.code}, Message: ${err.message}`);
      
      // 根据错误码提示用户
      if (err.code === 1008500006) {
        console.error('用户隐私协议未同意，请引导用户同意隐私协议');
      } else if (err.code === 1008500008) {
        console.error('用户未登录华为账号，请引导用户登录');
      }
      
      return false;
    }
  }

  /**
   * 步骤2：获取已连接设备列表
   */
  private async getConnectedDevices() {
    if (!this.deviceClient) {
      console.error('DeviceClient未初始化');
      return;
    }

    try {
      this.deviceList = await this.deviceClient.getConnectedDevices();
      console.info(`成功获取设备列表，共${this.deviceList.length}个设备`);
      
      if (this.deviceList.length > 0) {
        // 选择第一个设备作为目标设备
        this.targetDevice = this.deviceList[0];
        this.connectionStatus = '已连接';
        
        console.info(`目标设备: ${this.targetDevice.name}, ID: ${this.targetDevice.randomId}`);
        
        // 检查设备是否支持传感器能力
        let supportsSensor = await this.targetDevice.isWearEngineCapabilitySupported(wearEngine.WearEngineCapability.SENSOR);
        console.info(`设备是否支持传感器能力: ${supportsSensor}`);
        
        if (!supportsSensor) {
          console.error('设备不支持传感器能力');
          this.targetDevice = null;
        }
      } else {
        console.error('没有已连接的穿戴设备');
        this.connectionStatus = '未连接';
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取设备列表失败. Code: ${err.code}, Message: ${err.message}`);
      this.connectionStatus = '获取失败';
    }
  }

  /**
   * 步骤3：获取传感器列表
   */
  private async getSensorList() {
    if (!this.sensorClient || !this.targetDevice) {
      console.error('SensorClient或目标设备未初始化');
      return;
    }

    try {
      this.sensorList = await this.sensorClient.getSensorList(this.targetDevice.randomId);
      console.info(`成功获取传感器列表，共${this.sensorList.length}个传感器`);
      
      // 打印每个传感器的信息
      this.sensorList.forEach((sensor, idx) => {
        console.info(`传感器${idx}: 名称=${sensor.name}, ID=${sensor.id}, 类型=${sensor.type}, 采样周期=${sensor.accuracy}ms`);
      });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取传感器列表失败. Code: ${err.code}, Message: ${err.message}`);
    }
  }

  /**
   * 步骤4：订阅指定传感器数据
   */
  private async subscribeSensor(sensorType: wearEngine.SensorType) {
    if (!this.sensorClient || !this.targetDevice) {
      console.error('SensorClient或目标设备未初始化');
      return;
    }

    // 检查设备是否支持该传感器
    let hasSensor = this.sensorList.some(sensor => sensor.type === sensorType);
    if (!hasSensor) {
      console.error(`设备不支持${sensorType}传感器`);
      return;
    }

    // 定义回调函数（注意：必须保存同一个回调函数对象用于后续取消订阅）
    let sensorCallback = (sensorResult: wearEngine.SensorResult) => {
      this.handleSensorData(sensorType, sensorResult);
    };

    try {
      await this.sensorClient.subscribeSensor(this.targetDevice.randomId, sensorType, sensorCallback);
      
      // 保存回调函数用于取消订阅
      this.subscribedSensors.set(sensorType, sensorCallback);
      
      console.info(`成功订阅${sensorType}传感器数据`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`订阅传感器失败. Code: ${err.code}, Message: ${err.message}`);
      
      // 根据错误码处理
      if (err.code === 1008500012) {
        console.error('回调函数数量超限，请先取消其他订阅');
      }
    }
  }

  /**
   * 处理传感器数据
   */
  private handleSensorData(sensorType: wearEngine.SensorType, sensorResult: wearEngine.SensorResult) {
    // 检查是否有错误码
    if (sensorResult.errorCode) {
      this.handleSensorError(sensorResult.errorCode);
      return;
    }

    // 处理传感器数据
    if (sensorResult.data && sensorResult.data.length > 0) {
      sensorResult.data.forEach((sensorData, idx) => {
        let logMessage = `传感器类型: ${sensorData.sensorType}, 时间戳: ${sensorData.timestamp}, 数据长度: ${sensorData.data.length}`;
        
        // 处理多通道传感器数据
        if (sensorData.channel) {
          logMessage += `, 通道ID: ${sensorData.channel}`;
        }
        
        console.info(logMessage);
        
        // 添加到历史记录
        this.sensorDataHistory.push(`${new Date().toLocaleTimeString()}: ${sensorType} - 数据点数: ${sensorData.data.length}`);
        
        // 保持历史记录最多50条
        if (this.sensorDataHistory.length > 50) {
          this.sensorDataHistory.shift();
        }
      });
    }
  }

  /**
   * 处理传感器错误码
   */
  private handleSensorError(errorCode: number) {
    switch (errorCode) {
      case 300:  // DEVICE_NOT_BEING_WORN
        console.error('设备未佩戴，请佩戴设备');
        break;
      case 301:  // DEVICE_LEAD_OFF
        console.error('设备引线脱落，请检查ECG传感器引线');
        break;
      case 302:  // SENSOR_TURNED_OFF_MANUALLY
        console.error('传感器被手动关闭，请在设备上打开传感器');
        break;
      case 303:  // SENSOR_OCCUPIED
        console.error('传感器被占用，请等待其他应用释放传感器');
        break;
      case 304:  // SENSOR_NOT_SUPPORTED
        console.error('传感器不支持');
        break;
      default:
        console.error(`未知传感器错误码: ${errorCode}`);
    }
  }

  /**
   * 步骤5：取消订阅传感器
   */
  private async unsubscribeSensor(sensorType: wearEngine.SensorType) {
    if (!this.sensorClient || !this.targetDevice) {
      console.error('SensorClient或目标设备未初始化');
      return;
    }

    // 获取保存的回调函数
    let savedCallback = this.subscribedSensors.get(sensorType);
    if (!savedCallback) {
      console.error(`未找到${sensorType}传感器的订阅回调函数`);
      return;
    }

    try {
      // 使用保存的回调函数对象取消订阅（必须是同一个对象）
      await this.sensorClient.unsubscribeSensor(this.targetDevice.randomId, sensorType, savedCallback);
      
      // 移除保存的回调函数
      this.subscribedSensors.delete(sensorType);
      
      console.info(`成功取消订阅${sensorType}传感器数据`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`取消订阅失败. Code: ${err.code}, Message: ${err.message}`);
    }
  }

  /**
   * 步骤6：订阅设备连接状态变化（用于断线重连处理）
   */
  private async subscribeConnectionStatus() {
    if (!this.monitorClient || !this.targetDevice) {
      console.error('MonitorClient或目标设备未初始化');
      return;
    }

    let connectionCallback = (monitorEventData: wearEngine.MonitorEventData) => {
      if (monitorEventData.event === wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED) {
        let status = monitorEventData.data.code;
        
        switch (status) {
          case 2:  // 连接成功
            this.connectionStatus = '已连接';
            console.info('设备重新连接成功，重新订阅传感器');
            this.reconnectSensors();
            break;
          case 3:  // 连接断开
            this.connectionStatus = '已断开';
            console.warn('设备连接断开，传感器数据上报已停止');
            break;
          case 5:  // 设备解绑
            this.connectionStatus = '已解绑';
            console.warn('设备已解绑');
            break;
        }
      }
    };

    try {
      await this.monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
        connectionCallback
      );
      console.info('成功订阅设备连接状态变化事件');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`订阅连接状态失败. Code: ${err.code}, Message: ${err.message}`);
    }
  }

  /**
   * 断线重连后重新订阅所有传感器
   */
  private async reconnectSensors() {
    // 重新订阅之前订阅的所有传感器
    this.subscribedSensors.forEach(async (callback, sensorType) => {
      try {
        await this.sensorClient?.subscribeSensor(this.targetDevice!.randomId, sensorType, callback);
        console.info(`重新订阅${sensorType}传感器成功`);
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        console.error(`重新订阅${sensorType}传感器失败. Code: ${err.code}, Message: ${err.message}`);
      }
    });
  }

  /**
   * 清理所有订阅
   */
  private cleanup() {
    // 取消所有传感器订阅
    this.subscribedSensors.forEach(async (callback, sensorType) => {
      try {
        await this.sensorClient?.unsubscribeSensor(this.targetDevice!.randomId, sensorType, callback);
        console.info(`取消订阅${sensorType}传感器`);
      } catch (error) {
        console.error(`取消订阅失败: ${error}`);
      }
    });
    
    this.subscribedSensors.clear();
    this.sensorDataHistory = [];
  }

  build() {
    Column() {
      // 标题
      Text('穿戴设备传感器获取示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      // 设备信息
      Column() {
        Text(`设备连接状态: ${this.connectionStatus}`)
          .fontSize(16);
        if (this.targetDevice) {
          Text(`设备名称: ${this.targetDevice.name}`)
            .fontSize(14);
          Text(`设备型号: ${this.targetDevice.model}`)
            .fontSize(14);
        }
      }
      .margin({ bottom: 20 });

      // 操作按钮
      Row() {
        Button('申请权限')
          .onClick(() => this.requestSensorPermission())
          .width('30%');
        
        Button('获取设备')
          .onClick(() => this.getConnectedDevices())
          .width('30%');
        
        Button('获取传感器')
          .onClick(() => this.getSensorList())
          .width('30%');
      }
      .margin({ bottom: 10 });

      Row() {
        Button('订阅ACC')
          .onClick(() => this.subscribeSensor(wearEngine.SensorType.ACCELEROMETER))
          .width('25%');
        
        Button('订阅HR')
          .onClick(() => this.subscribeSensor(wearEngine.SensorType.HEART_RATE))
          .width('25%');
        
        Button('取消ACC')
          .onClick(() => this.unsubscribeSensor(wearEngine.SensorType.ACCELEROMETER))
          .width('25%');
        
        Button('取消HR')
          .onClick(() => this.unsubscribeSensor(wearEngine.SensorType.HEART_RATE))
          .width('25%');
      }
      .margin({ bottom: 10 });

      Button('订阅连接状态')
        .onClick(() => this.subscribeConnectionStatus())
        .width('100%')
        .margin({ bottom: 20 });

      // 传感器列表
      if (this.sensorList.length > 0) {
        Text('传感器列表:')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
        
        List() {
          ForEach(this.sensorList, (sensor: wearEngine.Sensor) => {
            ListItem() {
              Text(`${sensor.name} (ID: ${sensor.id}, 类型: ${sensor.type})`)
                .fontSize(14);
            }
          });
        }
        .height(150)
        .margin({ bottom: 20 });
      }

      // 传感器数据历史
      if (this.sensorDataHistory.length > 0) {
        Text('传感器数据历史:')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
        
        List() {
          ForEach(this.sensorDataHistory, (data: string) => {
            ListItem() {
              Text(data)
                .fontSize(12);
            }
          });
        }
        .height(200);
      }
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }
}