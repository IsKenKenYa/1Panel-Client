/**
 * 错误处理示例
 * 
 * 本示例演示如何处理分享过程中的各种错误情况
 * 
 * API版本要求: 5.1.0(18)及以上
 */

import { common, UIContext } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ErrorHandlingExample {
  private errorText: string = '';

  build() {
    Column() {
      Text('错误处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      Text(this.errorText)
        .fontSize(16)
        .margin({ bottom: 20 });

      Button('测试参数错误')
        .width('80%')
        .onClick(() => {
          this.testParameterError();
        })
        .margin({ bottom: 10 });

      Button('测试API版本兼容')
        .width('80%')
        .onClick(() => {
          this.testAPIVersionCompatibility();
        })
        .margin({ bottom: 10 });

      Button('正常分享流程')
        .width('80%')
        .onClick(() => {
          this.normalShareFlow();
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  /**
   * 测试参数错误场景
   */
  private testParameterError(): void {
    try {
      let data = new systemShare.SharedData({
        utd: utd.UniformDataType.PLAIN_TEXT
      });

      this.errorText = '参数错误测试: 缺少content字段';
      console.error('参数错误: SharedData缺少必需字段');
    } catch (error) {
      let err = error as BusinessError;
      this.handleError(err, '创建SharedData');
    }
  }

  /**
   * 测试API版本兼容性
   */
  private testAPIVersionCompatibility(): void {
    let controller = this.createTestController();

    if (this.checkAPIVersion(5.1)) {
      controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        this.errorText = `分享完成: ${result.targetAbilityInfo.name}`;
      });
      this.errorText = 'API版本5.1.0及以上,支持shareCompleted事件';
    } else {
      controller.on('dismiss', () => {
        this.errorText = 'API版本低于5.1.0,使用dismiss事件替代';
      });
      this.errorText = 'API版本低于5.1.0,仅支持dismiss事件';
    }
  }

  /**
   * 正常分享流程
   */
  private normalShareFlow(): void {
    try {
      let data = this.createValidShareData();
      let controller = new systemShare.ShareController(data);

      controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        this.errorText = `分享成功: ${result.targetAbilityInfo.name}`;
      });

      controller.on('dismiss', () => {
        this.errorText = '分享面板已关闭';
      });

      this.showSharePanel(controller);
    } catch (error) {
      let err = error as BusinessError;
      this.handleError(err, '分享流程');
    }
  }

  /**
   * 创建有效的分享数据
   */
  private createValidShareData(): systemShare.SharedData {
    return new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: 'Hello HarmonyOS'
    });
  }

  /**
   * 创建测试控制器
   */
  private createTestController(): systemShare.ShareController {
    let data = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: 'Test Content'
    });
    return new systemShare.ShareController(data);
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
      this.handleError(error, '显示分享面板');
    });
  }

  /**
   * 处理错误
   */
  private handleError(error: BusinessError, operation: string): void {
    let errorMessage = '';

    switch (error.code) {
      case 401:
        errorMessage = `参数错误(${operation}): 检查参数是否正确`;
        console.error(errorMessage);
        this.errorText = errorMessage;
        break;

      case 1003700001:
        errorMessage = `记录数量超限(${operation}): 最大支持500条`;
        console.error(errorMessage);
        this.errorText = errorMessage;
        break;

      case 1003702001:
        errorMessage = `记录类型不支持(${operation}): 批量模式仅支持FILE类型`;
        console.error(errorMessage);
        this.errorText = errorMessage;
        break;

      case 1003702002:
        errorMessage = `IPC数据超限(${operation}): 总数据不超过200KB`;
        console.error(errorMessage);
        this.errorText = errorMessage;
        break;

      default:
        errorMessage = `未知错误(${operation}): code=${error.code}, message=${error.message}`;
        console.error(errorMessage);
        this.errorText = errorMessage;
        break;
    }
  }

  /**
   * 检查API版本
   */
  private checkAPIVersion(requiredVersion: number): boolean {
    try {
      let canIUse = globalThis.canIUse;
      if (canIUse) {
        return canIUse(`SystemCapability.Collaboration.SystemShare@${requiredVersion}`);
      }
      return true;
    } catch (error) {
      console.warn('无法检查API版本,假设支持');
      return true;
    }
  }

  /**
   * 降级处理示例
   */
  private fallbackHandler(controller: systemShare.ShareController): void {
    console.warn('使用降级方案: 监听dismiss事件');
    
    controller.on('dismiss', () => {
      this.errorText = '降级方案: 分享面板已关闭,无法获取渠道信息';
    });

    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).catch((error: BusinessError) => {
      this.handleError(error, '降级处理');
    });
  }
}