import { wifiManager } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct WifiScanExample {
  @State scanResults: Array<wifiManager.WifiScanInfo> = [];
  @State message: string = '点击按钮开始扫描';
  @State isScanning: boolean = false;
  
  private scanStateCallback: (result: number) => void | null = null;
  
  aboutToAppear() {
    this.registerScanEvent();
  }
  
  aboutToDisappear() {
    this.unregisterScanEvent();
  }
  
  build() {
    Column() {
      Text(this.message)
        .fontSize(18)
        .margin(10)
      
      Button('扫描Wi-Fi')
        .width('80%')
        .margin(10)
        .enabled(!this.isScanning)
        .onClick(() => {
          this.startWifiScan();
        })
      
      if (this.scanResults.length > 0) {
        List() {
          ForEach(this.scanResults, (item: wifiManager.WifiScanInfo, index: number) => {
            ListItem() {
              WifiNetworkItem({ networkInfo: item })
            }
          }, (item: wifiManager.WifiScanInfo, index: number) => index.toString())
        }
        .width('90%')
        .height('60%')
        .margin(10)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
  }
  
  private registerScanEvent() {
    this.scanStateCallback = (result: number) => {
      if (result === 1) {
        this.message = '扫描成功';
        this.isScanning = false;
        this.getScanResults();
      } else {
        this.message = '扫描失败';
        this.isScanning = false;
      }
    };
    
    try {
      wifiManager.on('wifiScanStateChange', this.scanStateCallback);
      console.info('已注册扫描状态监听');
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`注册扫描事件失败: ${e.message}`);
    }
  }
  
  private unregisterScanEvent() {
    if (this.scanStateCallback) {
      try {
        wifiManager.off('wifiScanStateChange', this.scanStateCallback);
        console.info('已取消扫描状态监听');
      } catch (error) {
        let e: BusinessError = error as BusinessError;
        console.error(`取消注册失败: ${e.message}`);
      }
    }
  }
  
  private async startWifiScan() {
    try {
      let isWifiActive = wifiManager.isWifiActive();
      if (!isWifiActive) {
        this.message = 'WiFi未开启，请先打开WiFi';
        return;
      }
      
      this.message = '正在扫描...';
      this.isScanning = true;
      
      this.getScanResults();
      
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      this.message = `扫描失败: ${e.message}`;
      this.isScanning = false;
      this.handleError(e);
    }
  }
  
  private getScanResults() {
    try {
      let scanInfoList = wifiManager.getScanInfoList();
      this.scanResults = scanInfoList;
      
      if (scanInfoList.length === 0) {
        this.message = '当前无扫描结果';
      } else {
        this.message = `扫描到 ${scanInfoList.length} 个网络`;
      }
      
      console.info(`扫描结果数量: ${scanInfoList.length}`);
      
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`获取扫描结果失败: ${e.message}`);
      this.handleError(e);
    }
  }
  
  private handleError(error: BusinessError) {
    switch (error.code) {
      case 201:
        this.message = '权限不足，请授予WiFi信息获取权限';
        break;
      case 801:
        this.message = '系统不支持WiFi功能';
        break;
      case 2501000:
        this.message = 'WiFi操作失败，建议重启WiFi或设备';
        break;
      case 2501001:
        this.message = 'WiFi未开启，请打开WiFi开关';
        break;
      default:
        this.message = `错误: ${error.message}`;
    }
  }
}

@Component
struct WifiNetworkItem {
  @Prop networkInfo: wifiManager.WifiScanInfo;
  
  build() {
    Column() {
      Row() {
        Text(`SSID: ${this.networkInfo.ssid || '隐藏网络'}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('70%')
        
        Text(`信号: ${this.networkInfo.rssi} dBm`)
          .fontSize(14)
          .width('30%')
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      
      Row() {
        Text(`BSSID: ${this.networkInfo.bssid}`)
          .fontSize(12)
          .width('60%')
        
        Text(`频段: ${this.getBandText(this.networkInfo.band)}`)
          .fontSize(12)
          .width('40%')
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 5 })
      
      Row() {
        Text(`安全类型: ${this.getSecurityTypeText(this.networkInfo.securityType)}`)
          .fontSize(12)
          .width('50%')
        
        Text(`频率: ${this.networkInfo.frequency} MHz`)
          .fontSize(12)
          .width('50%')
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 5 })
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ top: 5, bottom: 5 })
    .shadow({ radius: 2, color: '#E0E0E0', offsetX: 0, offsetY: 1 })
  }
  
  private getBandText(band: number): string {
    switch (band) {
      case 1:
        return '2.4GHz';
      case 2:
        return '5GHz';
      case 3:
        return '6GHz';
      default:
        return '未知';
    }
  }
  
  private getSecurityTypeText(securityType: number): string {
    switch (securityType) {
      case 0:
        return '开放';
      case 1:
        return 'WEP';
      case 2:
        return 'PSK';
      case 3:
        return 'SAE';
      case 4:
        return 'EAP';
      case 5:
        return 'EAP-SIM';
      case 6:
        return 'EAP-AKA';
      case 7:
        return 'EAP-AKA\'';
      case 8:
        return 'WAPI-CERT';
      case 9:
        return 'WAPI-PSK';
      case 10:
        return 'OWE';
      default:
        return '未知';
    }
  }
}