import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

interface DeviceStatus {
  wearStatus: string;
  powerLevel: number;
  chargeStatus: string;
  storageSpace: number;
  powerMode: string;
  connectionStatus: string;
}

@Entry
@Component
struct CompleteMonitorExample {
  private targetDevice: wearEngine.Device | null = null;
  private callbacks: Map<string, (data: wearEngine.MonitorEventData) => void> = new Map();
  
  private @State deviceStatus: DeviceStatus = {
    wearStatus: '未查询',
    powerLevel: -1,
    chargeStatus: '未查询',
    storageSpace: -1,
    powerMode: '未查询',
    connectionStatus: '未查询'
  };
  
  private @State isMonitoring: boolean = false;
  private @State operationLogs: string[] = [];
  
  async aboutToAppear(): Promise<void> {
    await this.initialize();
  }
  
  async initialize(): Promise<void> {
    this.addLog('开始初始化...');
    
    try {
      this.addLog('获取设备列表...');
      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
      let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
      
      if (devices.length === 0) {
        this.addLog('错误: 未找到已连接设备');
        return;
      }
      
      this.targetDevice = devices[0];
      this.addLog(`已选择设备: ${this.targetDevice.name}`);
      
      this.addLog('检查设备Monitor能力...');
      let isMonitorSupported: boolean = await this.targetDevice.isWearEngineCapabilitySupported(
        wearEngine.WearEngineCapability.MONITOR
      );
      
      if (!isMonitorSupported) {
        this.addLog('错误: 设备不支持Monitor能力');
        return;
      }
      
      this.addLog('设备准备完成');
      
      await this.queryAllStatuses();
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.addLog(`初始化失败: Code=${businessError.code}, Message=${businessError.message}`);
    }
  }
  
  async queryAllStatuses(): Promise<void> {
    if (!this.targetDevice) {
      this.addLog('设备未准备好');
      return;
    }
    
    this.addLog('开始查询所有状态...');
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      this.addLog('查询佩戴状态...');
      let wearResult: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.WEAR_STATUS
      );
      this.deviceStatus.wearStatus = wearResult.code === 1 ? '佩戴中' : '未佩戴';
      this.addLog(`佩戴状态: ${this.deviceStatus.wearStatus}`);
      
      this.addLog('查询电量状态...');
      let powerResult: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.POWER_STATUS
      );
      this.deviceStatus.powerLevel = powerResult.code;
      this.addLog(`电量: ${this.deviceStatus.powerLevel}%`);
      
      this.addLog('查询充电状态...');
      let chargeResult: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.CHARGE_STATUS
      );
      this.deviceStatus.chargeStatus = this.getChargeStatusText(chargeResult.code);
      this.addLog(`充电状态: ${this.deviceStatus.chargeStatus}`);
      
      this.addLog('查询存储空间...');
      let storageResult: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.AVAILABLE_STORAGE_SPACE
      );
      this.deviceStatus.storageSpace = storageResult.code;
      let storageMB = (this.deviceStatus.storageSpace / 1024).toFixed(2);
      this.addLog(`可用存储: ${storageMB} MB`);
      
      this.addLog('查询设备模式...');
      let modeResult: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.POWER_MODE
      );
      this.deviceStatus.powerMode = this.getPowerModeText(modeResult.code);
      this.addLog(`设备模式: ${this.deviceStatus.powerMode}`);
      
      this.addLog('所有状态查询完成');
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.addLog(`查询失败: Code=${businessError.code}, Message=${businessError.message}`);
    }
  }
  
  async startMonitoring(): Promise<void> {
    if (!this.targetDevice) {
      this.addLog('设备未准备好');
      return;
    }
    
    this.addLog('开始订阅状态变化...');
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      this.callbacks.set('wear', (data: wearEngine.MonitorEventData) => {
        this.deviceStatus.wearStatus = data.data.code === 1 ? '佩戴中' : '未佩戴';
        this.addLog(`佩戴状态变化: ${this.deviceStatus.wearStatus}`);
      });
      
      this.callbacks.set('power', (data: wearEngine.MonitorEventData) => {
        this.deviceStatus.powerLevel = data.data.code;
        this.addLog(`电量降低: ${this.deviceStatus.powerLevel}%`);
      });
      
      this.callbacks.set('charge', (data: wearEngine.MonitorEventData) => {
        this.deviceStatus.chargeStatus = this.getChargeStatusText(data.data.code);
        this.addLog(`充电状态变化: ${this.deviceStatus.chargeStatus}`);
      });
      
      this.callbacks.set('connection', (data: wearEngine.MonitorEventData) => {
        this.deviceStatus.connectionStatus = this.getConnectionStatusText(data.data.code);
        this.addLog(`连接状态变化: ${this.deviceStatus.connectionStatus}`);
      });
      
      await monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
        this.callbacks.get('wear')
      );
      this.addLog('订阅佩戴状态成功');
      
      await monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
        this.callbacks.get('power')
      );
      this.addLog('订阅电量状态成功');
      
      await monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED,
        this.callbacks.get('charge')
      );
      this.addLog('订阅充电状态成功');
      
      await monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
        this.callbacks.get('connection')
      );
      this.addLog('订阅连接状态成功');
      
      this.isMonitoring = true;
      this.addLog('所有订阅完成,开始监控');
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.addLog(`订阅失败: Code=${businessError.code}, Message=${businessError.message}`);
    }
  }
  
  async stopMonitoring(): Promise<void> {
    if (!this.targetDevice) {
      this.addLog('设备未准备好');
      return;
    }
    
    this.addLog('开始取消订阅...');
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      for (let [key, callback] of this.callbacks) {
        let event: wearEngine.MonitorEvent;
        switch (key) {
          case 'wear':
            event = wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED;
            break;
          case 'power':
            event = wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED;
            break;
          case 'charge':
            event = wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED;
            break;
          case 'connection':
            event = wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED;
            break;
          default:
            continue;
        }
        
        await monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          event,
          callback
        );
        this.addLog(`取消${key}订阅成功`);
      }
      
      this.callbacks.clear();
      this.isMonitoring = false;
      this.addLog('所有订阅已取消');
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.addLog(`取消订阅失败: Code=${businessError.code}, Message=${businessError.message}`);
    }
  }
  
  getChargeStatusText(code: number): string {
    switch (code) {
      case 1:
        return '正在充电';
      case 2:
        return '未充电';
      case 3:
        return '电量已充满';
      default:
        return '未知状态';
    }
  }
  
  getPowerModeText(code: number): string {
    switch (code) {
      case -1:
        return '不支持模式切换';
      case 0:
        return '智能模式';
      case 1:
        return '超长续航模式';
      default:
        return '未知模式';
    }
  }
  
  getConnectionStatusText(code: number): string {
    switch (code) {
      case 2:
        return '连接成功';
      case 3:
        return '连接断开';
      case 5:
        return '设备解绑';
      default:
        return '未知状态';
    }
  }
  
  addLog(message: string): void {
    this.operationLogs.push(`${new Date().toLocaleTimeString()}: ${message}`);
    if (this.operationLogs.length > 10) {
      this.operationLogs.shift();
    }
  }
  
  build() {
    Scroll() {
      Column() {
        Text('完整状态监控示例')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        Column() {
          Text(`佩戴状态: ${this.deviceStatus.wearStatus}`)
            .fontSize(16)
          Text(`电量: ${this.deviceStatus.powerLevel}%`)
            .fontSize(16)
          Text(`充电状态: ${this.deviceStatus.chargeStatus}`)
            .fontSize(16)
          Text(`存储空间: ${(this.deviceStatus.storageSpace / 1024).toFixed(2)} MB`)
            .fontSize(16)
          Text(`设备模式: ${this.deviceStatus.powerMode}`)
            .fontSize(16)
          Text(`连接状态: ${this.deviceStatus.connectionStatus}`)
            .fontSize(16)
          Text(`监控状态: ${this.isMonitoring ? '正在监控' : '未监控'}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 10 })
        }
        .width('90%')
        .padding(10)
        .backgroundColor('#F0F0F0')
        .borderRadius(10)
        .margin({ bottom: 20 })
        
        Row() {
          Button('刷新状态')
            .width('45%')
            .onClick(() => this.queryAllStatuses())
          
          Button(this.isMonitoring ? '停止监控' : '开始监控')
            .width('45%')
            .onClick(() => this.isMonitoring ? this.stopMonitoring() : this.startMonitoring())
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 20 })
        
        Column() {
          Text('操作日志')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10 })
          
          ForEach(this.operationLogs, (log: string) => {
            Text(log)
              .fontSize(12)
              .margin({ bottom: 5 })
          })
        }
        .width('90%')
        .padding(10)
        .backgroundColor('#E8E8E8')
        .borderRadius(10)
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
  }
}