import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct MultiPathStateChangeExample {
  @State message: string = '多网状态监听示例';
  @State stateLog: string = '';
  @State isSubscribed: boolean = false;

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text('多网状态日志:')
        .fontSize(16)
        .margin({ top: 30 });

      Text(this.stateLog)
        .fontSize(14)
        .margin({ top: 10 })
        .width('90%')
        .height(200)
        .backgroundColor('#f0f0f0')
        .padding(10);

      Row() {
        Button('订阅多网状态')
          .fontSize(18)
          .enabled(!this.isSubscribed)
          .onClick(() => {
            this.subscribeMultiPathState();
          })
          .margin({ right: 20 });

        Button('取消订阅')
          .fontSize(18)
          .enabled(this.isSubscribed)
          .onClick(() => {
            this.unsubscribeMultiPathState();
          });
      }
      .margin({ top: 20 });
    }
    .width('100%')
    .height('100%');
  }

  subscribeMultiPathState(): void {
    try {
      netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
        this.handleMultiPathStateChange(data);
      });
      this.isSubscribed = true;
      this.stateLog += '订阅多网状态监听成功\n';
      console.info('订阅多网状态监听成功');
    } catch (err) {
      const error = err as BusinessError;
      this.stateLog += '订阅失败: ' + error.message + '\n';
      console.error('订阅失败 errCode: ' + error.code + ', errMessage: ' + error.message);
    }
  }

  unsubscribeMultiPathState(): void {
    try {
      netHandover.off('multiPathStateChange');
      this.isSubscribed = false;
      this.stateLog += '取消订阅成功\n';
      console.info('取消订阅成功');
    } catch (err) {
      const error = err as BusinessError;
      this.stateLog += '取消订阅失败: ' + error.message + '\n';
      console.error('取消订阅失败 errCode: ' + error.code + ', errMessage: ' + error.message);
    }
  }

  handleMultiPathStateChange(data: netHandover.MultiPathStateInfo): void {
    try {
      const timestamp = new Date().toLocaleTimeString();
      let stateStr = `[${timestamp}] 多网状态变化:\n`;
      stateStr += `  状态: ${this.getMultiPathStateString(data.multiPathState)}\n`;
      stateStr += `  链路状态: ${this.getPathStateString(data.pathState)}\n`;
      stateStr += `  变化原因: ${this.getCauseString(data.cause)}\n`;
      stateStr += `  链路类型: ${data.pathType}\n`;
      stateStr += `  NetHandle: ${JSON.stringify(data.netHandle)}\n\n`;

      this.stateLog += stateStr;
      console.info('多网状态变化: ' + JSON.stringify(data));

      this.handleStateChangeAction(data);
    } catch (err) {
      this.stateLog += '处理回调异常: ' + (err as Error).message + '\n';
      console.error('处理回调异常: ' + (err as Error).message);
    }
  }

  handleStateChangeAction(data: netHandover.MultiPathStateInfo): void {
    switch (data.multiPathState) {
      case netHandover.MultiPathState.MULTIPATH_CREATED:
        this.stateLog += '多网已建立，可以开始使用多网链路传输数据\n';
        break;
      case netHandover.MultiPathState.MULTIPATH_RELEASING:
        this.stateLog += '多网正在释放，暂停数据传输\n';
        break;
    }

    if (data.cause === netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA) {
      this.stateLog += '配额耗尽，建议释放多网避免系统强制释放\n';
    }

    if (data.cause === netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER) {
      this.stateLog += '多网进入挂起状态，暂停数据传输\n';
    }
  }

  getMultiPathStateString(state: netHandover.MultiPathState): string {
    switch (state) {
      case netHandover.MultiPathState.MULTIPATH_IDLE:
        return '空闲';
      case netHandover.MultiPathState.MULTIPATH_CREATING:
        return '建立中';
      case netHandover.MultiPathState.MULTIPATH_CREATED:
        return '已建立';
      case netHandover.MultiPathState.MULTIPATH_RELEASING:
        return '释放中';
      default:
        return '未知';
    }
  }

  getPathStateString(state: netHandover.PathState): string {
    switch (state) {
      case netHandover.PathState.PATH_IDLE:
        return '空闲';
      case netHandover.PathState.PATH_CONNECTED:
        return '已连接';
      case netHandover.PathState.PATH_SUSPENDED:
        return '挂起';
      default:
        return '未知';
    }
  }

  getCauseString(cause: netHandover.MultiPathChangeCause): string {
    switch (cause) {
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_REQUEST_NORMAL:
        return '正常请求';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NORMAL:
        return '正常释放';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK:
        return '网络原因释放';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED:
        return '用户操作开关释放';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA:
        return '配额耗尽释放';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_POWER_CONSUMPTION:
        return '功耗原因释放';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC:
        return '流量不足释放';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_CONFLICT:
        return '场景冲突释放';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING:
        return '系统释放(使用不规范)';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_DEFAULT:
        return '系统状态变化释放';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER:
        return '进入挂起';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE:
        return '退出挂起';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_CONN_PROPERTIES_UPDATE:
        return '链路属性更新';
      default:
        return '未知原因';
    }
  }
}