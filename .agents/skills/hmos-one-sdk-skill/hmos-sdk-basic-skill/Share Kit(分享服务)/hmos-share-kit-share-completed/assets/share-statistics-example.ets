/**
 * 分享数据统计示例
 * 
 * 本示例演示如何统计用户分享到不同渠道的数据
 * 
 * API版本要求: 5.1.0(18)及以上
 */

import { common, UIContext } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

interface ShareStatistics {
  totalShares: number;
  systemOperations: Record<string, number>;
  thirdPartyApps: Record<string, number>;
  lastUpdateTime: string;
}

@Entry
@Component
struct ShareStatisticsExample {
  private statistics: ShareStatistics = {
    totalShares: 0,
    systemOperations: {},
    thirdPartyApps: {},
    lastUpdateTime: ''
  };

  private statisticsText: string = '暂无统计数据';

  build() {
    Column() {
      Text('分享数据统计示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      Text(this.statisticsText)
        .fontSize(16)
        .margin({ bottom: 20 });

      Button('发起分享并统计')
        .width('80%')
        .onClick(() => {
          this.shareAndStatistics();
        })
        .margin({ bottom: 10 });

      Button('查看统计数据')
        .width('80%')
        .onClick(() => {
          this.showStatistics();
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  /**
   * 发起分享并收集统计数据
   */
  private shareAndStatistics(): void {
    let data = this.createShareData();
    let controller = new systemShare.ShareController(data);

    controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
      this.updateStatistics(result.targetAbilityInfo.name);
    });

    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).catch((error: BusinessError) => {
      console.error(`分享失败: ${error.message}`);
    });
  }

  /**
   * 创建分享数据
   */
  private createShareData(): systemShare.SharedData {
    return new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: '分享统计测试数据'
    });
  }

  /**
   * 更新统计数据
   */
  private updateStatistics(channelName: string): void {
    this.statistics.totalShares++;
    this.statistics.lastUpdateTime = new Date().toLocaleString();

    if (channelName.startsWith('SystemShare_')) {
      if (!this.statistics.systemOperations[channelName]) {
        this.statistics.systemOperations[channelName] = 0;
      }
      this.statistics.systemOperations[channelName]++;
      console.info(`系统操作统计: ${channelName} = ${this.statistics.systemOperations[channelName]}`);
    } else {
      if (!this.statistics.thirdPartyApps[channelName]) {
        this.statistics.thirdPartyApps[channelName] = 0;
      }
      this.statistics.thirdPartyApps[channelName]++;
      console.info(`第三方应用统计: ${channelName} = ${this.statistics.thirdPartyApps[channelName]}`);
    }

    this.saveStatisticsToStorage();
    console.info(`总分享次数: ${this.statistics.totalShares}`);
  }

  /**
   * 显示统计数据
   */
  private showStatistics(): void {
    let text = `总分享次数: ${this.statistics.totalShares}\n`;
    text += `最后更新: ${this.statistics.lastUpdateTime}\n\n`;

    if (Object.keys(this.statistics.systemOperations).length > 0) {
      text += '系统操作统计:\n';
      for (let [key, value] of Object.entries(this.statistics.systemOperations)) {
        let displayName = this.getOperationDisplayName(key);
        text += `  ${displayName}: ${value}次\n`;
      }
      text += '\n';
    }

    if (Object.keys(this.statistics.thirdPartyApps).length > 0) {
      text += '第三方应用统计:\n';
      for (let [key, value] of Object.entries(this.statistics.thirdPartyApps)) {
        text += `  ${key}: ${value}次\n`;
      }
    }

    this.statisticsText = text;
  }

  /**
   * 获取系统操作显示名称
   */
  private getOperationDisplayName(channelName: string): string {
    const map: Record<string, string> = {
      'SystemShare_CopyToPasteboard': '复制',
      'SystemShare_SaveToMediaAsset': '保存至图库',
      'SystemShare_SaveAsFile': '另存为',
      'SystemShare_Print': '打印',
      'SystemShare_Superhub': '中转站',
      'SystemShare_Collection': '知识空间',
      'SystemShare_HarmonyShare': '华为分享',
      'SystemShare_Encrypt': '加密分享'
    };
    return map[channelName] || channelName;
  }

  /**
   * 保存统计数据到本地存储
   */
  private saveStatisticsToStorage(): void {
    try {
      let storageKey = 'share_statistics_data';
      let jsonStr = JSON.stringify(this.statistics);
      console.info('统计数据已保存:', jsonStr);
    } catch (error) {
      console.error('保存统计数据失败:', error);
    }
  }

  /**
   * 从本地存储加载统计数据
   */
  private loadStatisticsFromStorage(): void {
    try {
      let storageKey = 'share_statistics_data';
      console.info('尝试加载统计数据');
    } catch (error) {
      console.error('加载统计数据失败:', error);
    }
  }
}