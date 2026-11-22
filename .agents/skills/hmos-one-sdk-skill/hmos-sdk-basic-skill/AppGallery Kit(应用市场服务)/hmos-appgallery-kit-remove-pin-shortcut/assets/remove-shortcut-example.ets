/**
 * 删除应用内快捷方式完整示例
 * 
 * 功能说明:
 * - 演示如何删除应用已创建的桌面快捷方式
 * - 包含标准删除和错误处理
 * - 提供完整的UI界面
 * 
 * 前置条件:
 * - HarmonyOS 6.1.1(24)及以上版本
 * - 真机调试(不支持模拟器)
 * - 应用已创建快捷方式并保存shortcutId
 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'RemovePinShortcut';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct RemoveShortcutExample {
  // 存储快捷方式ID (实际使用时需要先通过checkPinShortcutPermitted获取)
  private shortcutId: string = 'id_test1';
  
  // 状态变量
  @State message: string = '准备删除快捷方式';
  @State isDeleting: boolean = false;

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('快捷方式管理')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 });

      // 说明信息
      Text('本示例演示如何删除应用创建的桌面快捷方式')
        .fontSize(16)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .width('90%');

      // 快捷方式ID显示
      Row() {
        Text('快捷方式ID: ')
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Text(this.shortcutId)
          .fontSize(16)
          .fontColor('#007DFF');
      }
      .width('90%')
      .justifyContent(FlexAlign.Start);

      // 删除按钮
      Button(this.isDeleting ? '删除中...' : '删除快捷方式')
        .width('80%')
        .height(50)
        .fontSize(18)
        .enabled(!this.isDeleting)
        .onClick(() => this.removeShortcut());

      // 提示信息
      Text('提示: 删除快捷方式需要用户确认')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 10 });

      // 状态信息
      Text(this.message)
        .fontSize(16)
        .fontColor(this.getMessageColor())
        .margin({ top: 20 })
        .width('90%')
        .textAlign(TextAlign.Center);

      // 操作说明
      Column({ space: 10 }) {
        Text('操作说明:')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 30 });

        Text('1. 点击"删除快捷方式"按钮')
          .fontSize(14)
          .width('90%');

        Text('2. 系统弹出删除确认框')
          .fontSize(14)
          .width('90%');

        Text('3. 用户确认或取消删除操作')
          .fontSize(14)
          .width('90%');

        Text('4. 查看删除结果状态')
          .fontSize(14)
          .width('90%');
      }
      .width('90%')
      .alignItems(HorizontalAlign.Start);

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }

  /**
   * 删除快捷方式
   */
  private async removeShortcut(): Promise<void> {
    // 防止重复点击
    if (this.isDeleting) {
      return;
    }

    try {
      this.isDeleting = true;
      this.message = '正在删除快捷方式...';

      // 1. 获取UIAbility上下文
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      // 2. 参数校验
      if (!this.shortcutId || this.shortcutId.length === 0) {
        hilog.error(DOMAIN, TAG, 'shortcutId is required');
        this.message = '错误: 快捷方式ID不能为空';
        this.isDeleting = false;
        return;
      }

      if (this.shortcutId.length > 63) {
        hilog.error(DOMAIN, TAG, 'shortcutId length exceeds 63 bytes');
        this.message = '错误: 快捷方式ID长度不能超过63字节';
        this.isDeleting = false;
        return;
      }

      // 3. 调用删除接口
      hilog.info(DOMAIN, TAG, `Removing shortcut: ${this.shortcutId}`);
      
      await productViewManager.removePinShortcut(uiContext, this.shortcutId);
      
      // 4. 删除成功
      hilog.info(DOMAIN, TAG, 'removePinShortcut success.');
      this.message = '快捷方式删除成功!';
      this.isDeleting = false;
      
    } catch (error) {
      const err = error as BusinessError;
      this.isDeleting = false;
      this.handleRemoveError(err);
    }
  }

  /**
   * 处理删除错误
   */
  private handleRemoveError(error: BusinessError): void {
    let message: string = '删除失败';
    
    switch (error.code) {
      case 401:
        message = '参数错误: 请检查快捷方式ID是否正确';
        hilog.error(DOMAIN, TAG, 'Parameter error');
        break;
        
      case 1006620001:
        message = '系统内部错误: 请稍后重试';
        hilog.error(DOMAIN, TAG, 'System internal error');
        break;
        
      case 1006620006:
        message = '快捷方式不存在或已过期';
        hilog.warn(DOMAIN, TAG, 'Shortcut not verified or expired');
        break;
        
      case 1006620007:
        // 用户取消删除,不算错误
        message = '用户取消删除操作';
        hilog.info(DOMAIN, TAG, 'User refused to delete shortcut');
        this.message = message;
        return; // 正常返回
        
      default:
        message = `删除失败: ${error.message} (错误码: ${error.code})`;
        hilog.error(DOMAIN, TAG, `Unknown error: code=${error.code}, message=${error.message}`);
    }
    
    this.message = message;
  }

  /**
   * 根据消息内容获取颜色
   */
  private getMessageColor(): string {
    if (this.message.includes('成功') || this.message.includes('取消')) {
      return '#007DFF'; // 蓝色 - 成功或正常取消
    } else if (this.message.includes('错误') || this.message.includes('失败')) {
      return '#FF0000'; // 红色 - 错误
    } else if (this.message.includes('删除中')) {
      return '#FFA500'; // 橙色 - 进行中
    } else {
      return '#666666'; // 灰色 - 其他
    }
  }
}

/**
 * 使用示例:
 * 
 * 1. 在真机上运行应用
 * 2. 确保应用已创建快捷方式并保存shortcutId
 * 3. 点击"删除快捷方式"按钮
 * 4. 系统弹出确认框,用户确认或取消
 * 5. 查看删除结果
 * 
 * 注意事项:
 * - 不支持模拟器,必须使用真机
 * - shortcutId需要先通过checkPinShortcutPermitted接口获取
 * - 标准删除模式下会弹出系统确认框
 * - 用户取消删除不算错误(错误码1006620007)
 */