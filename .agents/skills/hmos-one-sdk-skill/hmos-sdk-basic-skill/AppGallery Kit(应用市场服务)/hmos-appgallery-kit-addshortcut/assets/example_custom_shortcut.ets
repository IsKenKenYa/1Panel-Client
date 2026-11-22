/**
 * 自定义资源方式添加桌面快捷方式完整示例
 * 
 * 前提条件：
 * 1. 准备自定义图标文件（png或webp格式，最大100KB）
 * 2. 图标文件存储在应用沙箱目录（如filesDir）
 * 3. 使用真机调试（不支持模拟器）
 */

import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'CustomShortcut';
const DOMAIN = 0x0001;

@Entry
@Component
struct CustomShortcutExample {
  @State checkResult: productViewManager.CheckShortcutResult | null = null;
  @State tid: string = '';
  @State message: string = '';
  @State shortcutCount: number = 0;

  build() {
    Column({ space: 20 }) {
      Text('自定义资源方式添加快捷方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40 });

      Button('1. 准备图标文件')
        .width('80%')
        .onClick(() => {
          this.prepareIconFile();
        });

      Button('2. 校验快捷方式权限')
        .width('80%')
        .onClick(() => {
          this.checkPinShortcutPermitted();
        });

      Button('3. 创建快捷方式')
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
   * 步骤0：准备图标文件
   * 将图标文件复制到应用沙箱目录
   */
  prepareIconFile() {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const filesDir = uiContext.filesDir;
      const iconPath = filesDir + '/shortcut_icon.png';

      /**
       * 注意：这里需要您自行准备图标文件
       * 图标文件要求：
       * - 格式：png或webp
       * - 大小：不超过100KB
       * - 存储位置：应用沙箱目录（如filesDir）
       * 
       * 示例代码：假设您已将图标文件放在resources/rawfile目录
       * 这里演示如何将rawfile中的图标复制到沙箱目录
       */

      /**
       * 实际使用时，您可以：
       * 1. 从resources/rawfile复制图标文件到沙箱
       * 2. 动态生成图标文件（如截图、下载等）
       * 3. 使用已存在的图标文件
       */

      hilog.info(DOMAIN, TAG, `图标文件准备完成: ${iconPath}`);
      this.message = `图标文件准备完成\n路径: ${iconPath}`;

      /**
       * 验证文件是否存在
       */
      try {
        const stat = fileIo.statSync(iconPath);
        hilog.info(DOMAIN, TAG, `图标文件大小: ${stat.size} bytes`);
        if (stat.size > 100 * 1024) {
          hilog.warn(DOMAIN, TAG, '图标文件超过100KB，可能无法使用');
          this.message += '\n警告: 图标文件超过100KB';
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, '图标文件不存在，请先准备图标文件');
        this.message = '图标文件不存在，请先准备图标文件';
      }

    } catch (err) {
      hilog.error(DOMAIN, TAG, `准备图标文件失败: ${err.message}`);
      this.message = `准备图标文件失败: ${err.message}`;
    }
  }

  /**
   * 步骤1：校验快捷方式是否允许添加
   */
  async checkPinShortcutPermitted() {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      /**
       * 参数说明：
       * - shortcutId: 快捷方式ID，建议使用时间戳保证唯一性
       * - want: 点击快捷方式后拉起的Ability信息
       * - label: 显示在桌面的文本（不超过255字符）
       * - foregroundIcon: 图标文件沙箱路径（最大100KB，png或webp格式）
       * - backgroundIcon: 预留字段，当前只支持空字符串
       */
      const shortcutId = `shortcut_${Date.now()}`;
      const label = "我的快捷方式";
      const foregroundIcon = uiContext.filesDir + "/shortcut_icon.png";
      const backgroundIcon = "";

      const want: Want = {
        bundleName: "com.example.appgallery.kit.demo",
        moduleName: "entry",
        abilityName: "EntryAbility",
        parameters: {
          shortcutId: shortcutId,
          createTime: Date.now()
        }
      };

      hilog.info(DOMAIN, TAG, '开始校验快捷方式权限...');
      hilog.info(DOMAIN, TAG, `shortcutId: ${shortcutId}`);
      hilog.info(DOMAIN, TAG, `label: ${label}`);
      hilog.info(DOMAIN, TAG, `foregroundIcon: ${foregroundIcon}`);

      const result = await productViewManager.checkPinShortcutPermitted(
        uiContext,
        shortcutId,
        want,
        label,
        foregroundIcon,
        backgroundIcon
      );

      hilog.info(DOMAIN, TAG, `校验成功: ${JSON.stringify(result)}`);

      this.checkResult = result;
      this.tid = result.tid;
      this.shortcutCount = result.limit;
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
    const expiredTime = this.checkResult.expired;
    if (currentTime >= expiredTime) {
      hilog.warn(DOMAIN, TAG, 'tid已过期，请重新校验');
      this.message = 'tid已过期，请重新校验';
      await this.checkPinShortcutPermitted();
      return;
    }

    /**
     * 检查快捷方式数量是否已达上限
     */
    if (this.shortcutCount <= 0) {
      hilog.warn(DOMAIN, TAG, '快捷方式数量已达上限');
      this.message = '快捷方式数量已达上限(最多2个)';
      return;
    }

    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const tid = this.tid;

      hilog.info(DOMAIN, TAG, '开始创建快捷方式...');
      hilog.info(DOMAIN, TAG, `使用tid: ${tid}`);

      /**
       * 注意：调用此接口会弹出用户确认弹窗
       * 用户需要同意才能成功创建
       */
      await productViewManager.requestNewPinShortcut(uiContext, tid);

      hilog.info(DOMAIN, TAG, '快捷方式创建成功');
      this.message = '快捷方式创建成功';

      /**
       * 注意：加桌成功后，原tid会失效
       * 再次加桌需要重新校验生成新tid
       */
      this.checkResult = null;
      this.tid = '';
      this.shortcutCount--;

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
        this.message = '参数错误\n请检查：\n' +
          '- shortcutId长度≤63字节\n' +
          '- label长度≤255字符\n' +
          '- 图标大小≤100KB\n' +
          '- 图标格式为png/webp';
        break;
      case 1006620001:
        this.message = '系统内部错误，请稍后重试';
        break;
      case 1006620002:
        this.message = '请求服务错误，请检查网络连接';
        break;
      case 1006620003:
        this.message = 'shortcutId已存在，请使用新ID';
        break;
      case 1006620004:
        this.message = '快捷方式数量已达上限(最多2个)';
        this.shortcutCount = 0;
        break;
      case 1006620005:
        this.message = '校验失败，请检查参数是否正确';
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
        this.message = 'shortcutId已存在于桌面';
        break;
      case 1006620004:
        this.message = '快捷方式数量已达上限';
        this.shortcutCount = 0;
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