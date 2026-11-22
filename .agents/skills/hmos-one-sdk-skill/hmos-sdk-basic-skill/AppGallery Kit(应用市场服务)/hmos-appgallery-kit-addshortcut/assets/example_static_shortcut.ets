/**
 * 静态资源方式添加桌面快捷方式完整示例
 * 
 * 前提条件：
 * 1. 在module.json5中配置shortcuts标签
 * 2. 准备静态资源文件（label、icon）
 * 3. 使用真机调试（不支持模拟器）
 */

import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'StaticShortcut';
const DOMAIN = 0x0001;

@Entry
@Component
struct StaticShortcutExample {
  @State checkResult: productViewManager.CheckShortcutResult | null = null;
  @State tid: string = '';
  @State message: string = '';

  build() {
    Column({ space: 20 }) {
      Text('静态资源方式添加快捷方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40 });

      Button('1. 校验快捷方式权限')
        .width('80%')
        .onClick(() => {
          this.checkPinShortcutPermitted();
        });

      Button('2. 创建快捷方式')
        .width('80%')
        .enabled(this.checkResult !== null && this.tid !== '')
        .onClick(() => {
          this.requestNewPinShortcut();
        });

      Text(this.message)
        .fontSize(16)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  /**
   * 步骤1：校验快捷方式是否允许添加
   */
  async checkPinShortcutPermitted() {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      /**
       * 参数说明：
       * - shortcutId: 对应shortcuts标签中的shortcutId
       * - want: 对应shortcuts标签中的want配置
       * - labelResName: 对应shortcuts标签中的label资源索引名称
       * - iconResName: 对应shortcuts标签中的icon资源索引名称
       */
      const shortcutId = "id_test1";
      const labelResName = "shortcut";
      const iconResName = "aa_icon";
      
      const want: Want = {
        bundleName: "com.example.appgallery.kit.demo",
        moduleName: "entry",
        abilityName: "EntryAbility",
        parameters: {
          testKey: "testValue"
        }
      };

      hilog.info(DOMAIN, TAG, '开始校验快捷方式权限...');

      const result = await productViewManager.checkPinShortcutPermitted(
        uiContext,
        shortcutId,
        want,
        labelResName,
        iconResName
      );

      hilog.info(DOMAIN, TAG, `校验成功: ${JSON.stringify(result)}`);

      this.checkResult = result;
      this.tid = result.tid;
      this.message = `校验成功\n` +
        `tid: ${result.tid}\n` +
        `过期时间: ${result.expired}ms\n` +
        `结果码: ${result.code}\n` +
        `允许数量: ${result.limit}`;

    } catch (err) {
      hilog.error(DOMAIN, TAG, `校验失败: ${err.code}, ${err.message}`);
      this.message = `校验失败: ${err.message}`;
      this.handleCheckError(err as BusinessError);
    }
  }

  /**
   * 步骤2：创建快捷方式（用户点击后调用）
   */
  async requestNewPinShortcut() {
    if (!this.checkResult || !this.tid) {
      hilog.error(DOMAIN, TAG, '请先校验快捷方式权限');
      this.message = '请先校验快捷方式权限';
      return;
    }

    /**
     * 检查tid是否过期
     */
    const currentTime = Date.now();
    if (currentTime >= this.checkResult.expired) {
      hilog.warn(DOMAIN, TAG, 'tid已过期，请重新校验');
      this.message = 'tid已过期，请重新校验';
      await this.checkPinShortcutPermitted();
      return;
    }

    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const tid = this.tid;

      hilog.info(DOMAIN, TAG, '开始创建快捷方式...');

      await productViewManager.requestNewPinShortcut(uiContext, tid);

      hilog.info(DOMAIN, TAG, '快捷方式创建成功');
      this.message = '快捷方式创建成功';

      /**
       * 注意：加桌成功后，原tid会失效
       * 再次加桌需要重新校验生成新tid
       */
      this.checkResult = null;
      this.tid = '';

    } catch (err) {
      hilog.error(DOMAIN, TAG, `创建失败: ${err.code}, ${err.message}`);
      this.message = `创建失败: ${err.message}`;
      this.handleRequestError(err as BusinessError);
    }
  }

  /**
   * 处理校验错误
   */
  handleCheckError(error: BusinessError) {
    switch (error.code) {
      case 401:
        this.message = '参数错误，请检查参数类型和长度';
        break;
      case 1006620001:
        this.message = '系统内部错误，请稍后重试';
        break;
      case 1006620002:
        this.message = '请求服务错误，请检查网络';
        break;
      case 1006620003:
        this.message = 'shortcutId已存在，请使用新ID';
        break;
      case 1006620004:
        this.message = '快捷方式数量已达上限(最多2个)';
        break;
      case 1006620005:
        this.message = '校验失败，请检查参数与shortcuts配置是否一致';
        break;
      default:
        this.message = `未知错误: ${error.message}`;
    }
  }

  /**
   * 处理创建错误
   */
  handleRequestError(error: BusinessError) {
    switch (error.code) {
      case 401:
        this.message = '参数错误，tid无效';
        break;
      case 1006620001:
        this.message = '系统内部错误';
        break;
      case 1006620003:
        this.message = 'shortcutId已存在';
        break;
      case 1006620004:
        this.message = '快捷方式数量已达上限';
        break;
      case 1006620005:
        this.message = '校验失败';
        break;
      case 1006620006:
        this.message = 'tid已过期，请重新校验';
        this.checkResult = null;
        this.tid = '';
        break;
      case 1006620007:
        this.message = '用户已取消添加快捷方式';
        break;
      default:
        this.message = `未知错误: ${error.message}`;
    }
  }
}