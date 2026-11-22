/**
 * 获取分享结果完整示例
 * 
 * 本示例演示如何监听用户分享完成事件并获取分享渠道信息
 * 
 * API版本要求: 5.1.0(18)及以上
 * 模型约束: 仅支持Stage模型
 * 设备约束: 不支持TV设备
 */

import { common, UIContext } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ShareCompletedExample {
  private shareResultText: string = '等待分享...';

  build() {
    Column() {
      Text('获取分享结果示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      Text(this.shareResultText)
        .fontSize(16)
        .margin({ bottom: 20 });

      Button('发起分享并监听结果')
        .width('80%')
        .onClick(() => {
          this.shareWithListener();
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  /**
   * 发起分享并监听分享完成事件
   */
  private shareWithListener(): void {
    try {
      let data = this.createShareData();
      let controller = new systemShare.ShareController(data);
      
      this.registerShareListener(controller);
      this.showSharePanel(controller);
    } catch (error) {
      console.error('分享初始化失败:', error);
      this.shareResultText = '分享初始化失败';
    }
  }

  /**
   * 创建分享数据对象
   */
  private createShareData(): systemShare.SharedData {
    let data: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: 'Hello HarmonyOS'
    });

    console.info('分享数据已创建');
    return data;
  }

  /**
   * 注册分享完成监听事件
   */
  private registerShareListener(controller: systemShare.ShareController): void {
    controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
      let channelName = result.targetAbilityInfo.name;
      console.info('分享完成,渠道名称:', channelName);

      this.processShareResult(channelName);
    });

    controller.on('dismiss', () => {
      console.info('分享面板已关闭');
      this.shareResultText = '分享面板已关闭';
    });

    console.info('监听事件已注册');
  }

  /**
   * 处理分享结果
   */
  private processShareResult(channelName: string): void {
    if (channelName.startsWith('SystemShare_')) {
      let systemOperation = this.getSystemOperationDisplayName(channelName);
      this.shareResultText = `分享到系统操作: ${systemOperation}`;
      console.info('系统操作分享:', systemOperation);
    } else {
      this.shareResultText = `分享到第三方应用: ${channelName}`;
      console.info('第三方应用分享:', channelName);
    }
  }

  /**
   * 获取系统操作的显示名称
   */
  private getSystemOperationDisplayName(channelName: string): string {
    const operationMap: Record<string, string> = {
      'SystemShare_CopyToPasteboard': '复制',
      'SystemShare_SaveToMediaAsset': '保存至图库',
      'SystemShare_SaveAsFile': '另存为',
      'SystemShare_Print': '打印',
      'SystemShare_Superhub': '添加至中转站',
      'SystemShare_Collection': '小艺知识空间',
      'SystemShare_HarmonyShare': '华为分享',
      'SystemShare_Encrypt': '加密分享'
    };

    return operationMap[channelName] || channelName;
  }

  /**
   * 显示分享面板
   */
  private showSharePanel(controller: systemShare.ShareController): void {
    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      console.info('分享面板显示成功');
    }).catch((error: BusinessError) => {
      console.error(`分享面板显示失败: code=${error.code}, message=${error.message}`);
      this.shareResultText = `分享失败: ${error.message}`;
    });
  }
}