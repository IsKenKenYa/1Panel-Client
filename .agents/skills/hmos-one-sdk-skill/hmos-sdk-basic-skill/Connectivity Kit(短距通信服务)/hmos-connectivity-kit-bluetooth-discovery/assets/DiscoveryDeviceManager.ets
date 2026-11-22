import { connection } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 蓝牙设备发现管理器
 * 提供扫描周边蓝牙设备、设置扫描模式、查找已配对设备等功能
 */
export class DiscoveryDeviceManager {
  // 扫描结果上报回调函数（API version 18+，推荐使用）
  private onReceiveEventNew: (data: Array<connection.DiscoveryResult>) => void = 
    (data: Array<connection.DiscoveryResult>) => {
      console.info('Bluetooth device discovered (discoveryResult): ' + JSON.stringify(data));
      
      // 处理扫描到的设备信息
      for (let device of data) {
        console.info('Device details:');
        console.info('  Address: ' + device.deviceId);
        console.info('  Name: ' + device.deviceName);
        console.info('  RSSI: ' + device.rssi + ' dBm');
        console.info('  Device Class: ' + JSON.stringify(device.deviceClass));
      }
    };

  // 扫描结果上报回调函数（API version 10-17，备用）
  private onReceiveEventLegacy: (data: Array<string>) => void = 
    (data: Array<string>) => {
      console.info('Bluetooth device discovered (bluetoothDeviceFind): ' + JSON.stringify(data));
    };

  /**
   * 开始蓝牙设备扫描
   * 使用API version 18+的discoveryResult上报方式（推荐）
   * @returns void
   */
  public startDiscovery(): void {
    try {
      // 订阅扫描结果上报事件（推荐方式）
      connection.on('discoveryResult', this.onReceiveEventNew);
      console.info('Subscribed to discoveryResult event');
    } catch (err) {
      console.error('Failed to subscribe discoveryResult: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }

    try {
      // 判断本机设备是否正在进行扫描
      let isScanning = connection.isBluetoothDiscovering();
      
      if (!isScanning) {
        // 若当前不处于扫描过程，则开始扫描设备
        connection.startBluetoothDiscovery();
        console.info('Bluetooth discovery started successfully');
        
        // 扫描过程持续约12秒
        console.info('Discovery will run for approximately 12 seconds');
      } else {
        console.warn('Bluetooth discovery is already running, skipping start');
      }
    } catch (err) {
      console.error('Failed to start discovery: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      
      // 错误处理
      this.handleDiscoveryError(err as BusinessError);
    }
  }

  /**
   * 开始蓝牙设备扫描（使用旧版API）
   * 使用API version 10-17的bluetoothDeviceFind上报方式
   * @returns void
   */
  public startDiscoveryLegacy(): void {
    try {
      // 订阅扫描结果上报事件（旧版方式）
      connection.on('bluetoothDeviceFind', this.onReceiveEventLegacy);
      console.info('Subscribed to bluetoothDeviceFind event (legacy)');
    } catch (err) {
      console.error('Failed to subscribe bluetoothDeviceFind: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }

    try {
      // 判断本机设备是否正在进行扫描
      let isScanning = connection.isBluetoothDiscovering();
      
      if (!isScanning) {
        // 若当前不处于扫描过程，则开始扫描设备
        connection.startBluetoothDiscovery();
        console.info('Bluetooth discovery started (legacy mode)');
      } else {
        console.warn('Discovery already running');
      }
    } catch (err) {
      console.error('Failed to start discovery: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  /**
   * 停止蓝牙设备扫描
   * @returns void
   */
  public stopDiscovery(): void {
    try {
      // 判断本机设备是否正在进行扫描
      let isScanning = connection.isBluetoothDiscovering();
      
      if (isScanning) {
        // 若当前处于扫描过程，则停止扫描设备
        connection.stopBluetoothDiscovery();
        console.info('Bluetooth discovery stopped successfully');
      } else {
        console.info('Bluetooth discovery is not running');
      }

      // 取消订阅扫描上报结果
      connection.off('discoveryResult', this.onReceiveEventNew);
      console.info('Unsubscribed from discoveryResult event');
      
      // 如果使用了旧版API，也取消订阅
      // connection.off('bluetoothDeviceFind', this.onReceiveEventLegacy);
    } catch (err) {
      console.error('Failed to stop discovery: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  /**
   * 设置本机蓝牙扫描模式
   * @param mode 扫描模式
   * @param duration 可发现持续时间（毫秒，0表示持续可发现）
   * @returns void
   */
  public setScanMode(mode: connection.ScanMode, duration: number = 0): void {
    try {
      // 获取当前本机的扫描模式
      let currentMode: connection.ScanMode = connection.getBluetoothScanMode();
      console.info('Current scan mode: ' + currentMode);
      
      // 如果当前模式与目标模式不同，则设置新模式
      if (currentMode !== mode) {
        connection.setBluetoothScanMode(mode, duration);
        console.info('Scan mode set to: ' + mode);
        
        // 扫描模式说明
        this.logScanModeInfo(mode);
      } else {
        console.info('Scan mode already set to target mode: ' + mode);
      }
    } catch (err) {
      console.error('Failed to set scan mode: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  /**
   * 设置为可被发现和可被连接模式
   * @returns void
   */
  public setDiscoverableAndConnectable(): void {
    this.setScanMode(connection.ScanMode.SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE, 0);
  }

  /**
   * 获取当前扫描模式
   * @returns ScanMode 当前扫描模式
   */
  public getScanMode(): connection.ScanMode {
    try {
      let scanMode: connection.ScanMode = connection.getBluetoothScanMode();
      console.info('Current scan mode: ' + scanMode);
      this.logScanModeInfo(scanMode);
      return scanMode;
    } catch (err) {
      console.error('Failed to get scan mode: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      return connection.ScanMode.SCAN_MODE_NONE;
    }
  }

  /**
   * 查找已配对设备信息
   * @returns Array<string> 已配对设备地址列表
   */
  public getPairedDevices(): Array<string> {
    try {
      // 获取已配对设备信息
      let devices: Array<string> = connection.getPairedDevices();
      console.info('Paired devices count: ' + devices.length);
      console.info('Paired devices: ' + JSON.stringify(devices));
      
      // 注意：获取的设备地址为虚拟MAC地址
      // 已配对设备的虚拟地址不会变更
      // 未配对设备重启蓝牙后地址可能变更
      
      return devices;
    } catch (err) {
      console.error('Failed to get paired devices: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      return [];
    }
  }

  /**
   * 查询特定设备的配对状态
   * @param deviceId 设备地址
   * @returns BondState 配对状态
   */
  public getDevicePairState(deviceId: string): connection.BondState {
    try {
      let pairState: connection.BondState = connection.getPairState(deviceId);
      console.info('Device: ' + deviceId + ' pairState is ' + pairState);
      
      // 配对状态说明
      this.logBondStateInfo(pairState);
      
      return pairState;
    } catch (err) {
      console.error('Failed to get pair state: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      return connection.BondState.BOND_STATE_INVALID;
    }
  }

  /**
   * 检查特定设备是否已配对
   * @param deviceId 设备地址
   * @returns boolean 是否已配对
   */
  public isDevicePaired(deviceId: string): boolean {
    let pairState = this.getDevicePairState(deviceId);
    return pairState === connection.BondState.BOND_STATE_BONDED;
  }

  /**
   * 检查当前是否正在扫描
   * @returns boolean 是否正在扫描
   */
  public isDiscovering(): boolean {
    try {
      let isDiscovering = connection.isBluetoothDiscovering();
      console.info('Is discovering: ' + isDiscovering);
      return isDiscovering;
    } catch (err) {
      console.error('Failed to check discovering status: errCode: ' + 
        (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      return false;
    }
  }

  /**
   * 处理扫描错误
   * @param error BusinessError对象
   * @returns void
   */
  private handleDiscoveryError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('Permission denied. Please apply for ACCESS_BLUETOOTH permission.');
        // 提示用户申请权限
        break;
      case 401:
        console.error('Invalid parameter. Check parameter types and values.');
        break;
      case 801:
        console.error('Capability not supported. Device does not support this feature.');
        break;
      case 2900001:
        console.error('Service stopped. Bluetooth service is not running.');
        // 提示用户重启蓝牙或设备
        break;
      case 2900003:
        console.error('Bluetooth disabled. Please enable Bluetooth.');
        // 提示用户开启蓝牙
        break;
      case 2900099:
        console.error('Operation failed. Unknown error occurred.');
        // 提供降级方案
        this.fallbackToDeviceList();
        break;
      default:
        console.error('Unknown error: ' + error.code + ', message: ' + error.message);
    }
  }

  /**
   * 扫描失败时的降级方案
   * @returns void
   */
  private async fallbackToDeviceList(): Promise<void> {
    try {
      console.info('Fallback: Trying to get paired devices list');
      
      // 尝试获取已配对设备作为降级方案
      let devices = this.getPairedDevices();
      
      if (devices.length > 0) {
        console.info('Fallback successful: Found ' + devices.length + ' paired devices');
        console.info('You can directly connect to paired devices without scanning');
      } else {
        console.warn('No paired devices found. Please pair devices manually in system settings.');
      }
    } catch (err) {
      console.error('Fallback failed: ' + (err as BusinessError).message);
      console.warn('Please enable Bluetooth and scan devices manually.');
    }
  }

  /**
   * 输出扫描模式信息
   * @param mode 扫描模式
   * @returns void
   */
  private logScanModeInfo(mode: connection.ScanMode): void {
    switch (mode) {
      case connection.ScanMode.SCAN_MODE_NONE:
        console.info('Scan mode: Not discoverable, not connectable');
        break;
      case connection.ScanMode.SCAN_MODE_CONNECTABLE:
        console.info('Scan mode: Connectable only');
        break;
      case connection.ScanMode.SCAN_MODE_GENERAL_DISCOVERABLE:
        console.info('Scan mode: General discoverable');
        break;
      case connection.ScanMode.SCAN_MODE_LIMITED_DISCOVERABLE:
        console.info('Scan mode: Limited discoverable');
        break;
      case connection.ScanMode.SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE:
        console.info('Scan mode: Connectable and general discoverable (recommended for most cases)');
        break;
      case connection.ScanMode.SCAN_MODE_CONNECTABLE_LIMITED_DISCOVERABLE:
        console.info('Scan mode: Connectable and limited discoverable');
        break;
      default:
        console.info('Unknown scan mode: ' + mode);
    }
  }

  /**
   * 输出配对状态信息
   * @param state 配对状态
   * @returns void
   */
  private logBondStateInfo(state: connection.BondState): void {
    switch (state) {
      case connection.BondState.BOND_STATE_INVALID:
        console.info('Bond state: Not paired');
        break;
      case connection.BondState.BOND_STATE_BONDING:
        console.info('Bond state: Pairing in progress');
        break;
      case connection.BondState.BOND_STATE_BONDED:
        console.info('Bond state: Paired (ready for connection)');
        break;
      default:
        console.info('Unknown bond state: ' + state);
    }
  }
}

// 使用示例
let discoveryDeviceManager = new DiscoveryDeviceManager();

// 开始扫描（推荐方式）
discoveryDeviceManager.startDiscovery();

// 延迟12秒后停止扫描（模拟扫描完成）
setTimeout(() => {
  discoveryDeviceManager.stopDiscovery();
  
  // 获取已配对设备列表
  let pairedDevices = discoveryDeviceManager.getPairedDevices();
  console.info('Total paired devices: ' + pairedDevices.length);
  
  // 设置本机扫描模式为可发现可连接
  discoveryDeviceManager.setDiscoverableAndConnectable();
  
  // 获取当前扫描模式
  let currentMode = discoveryDeviceManager.getScanMode();
}, 12000);

export default discoveryDeviceManager as DiscoveryDeviceManager;