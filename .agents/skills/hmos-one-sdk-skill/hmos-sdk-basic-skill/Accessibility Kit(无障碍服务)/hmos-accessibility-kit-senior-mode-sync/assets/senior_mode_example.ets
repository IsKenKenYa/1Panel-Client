/**
 * 应用内关怀模式与系统设置同步完整示例
 * API版本：26.0.0+
 * 功能：查询、设置、监听关怀模式状态
 */

import accessibility from '@ohos.accessibility';

@Entry
@Component
struct SeniorModeExample {
  @State seniorModeState: boolean = false;
  @State message: string = '关怀模式状态：未知';
  
  // 定义监听回调函数
  seniorModeCallback = (state: boolean): void => {
    console.info(`[SeniorMode] System state changed: ${state}`);
    this.seniorModeState = state;
    this.message = `关怀模式状态：${state ? '开启' : '关闭'}`;
    this.updateSeniorModeUI(state);
  }
  
  /**
   * 应用启动时初始化关怀模式状态
   */
  async aboutToAppear(): Promise<void> {
    console.info('[SeniorMode] aboutToAppear');
    
    try {
      // 1. 查询系统关怀模式状态
      this.seniorModeState = await accessibility.getSeniorModeStateForSelf();
      this.message = `关怀模式状态：${this.seniorModeState ? '开启' : '关闭'}`;
      console.info(`[SeniorMode] Initial state: ${this.seniorModeState}`);
      
      // 2. 注册监听，监听系统设置变化
      accessibility.onSeniorModeStateChangeForSelf(this.seniorModeCallback);
      console.info('[SeniorMode] Listener registered');
      
      // 3. 更新UI
      this.updateSeniorModeUI(this.seniorModeState);
    } catch (error) {
      console.error(`[SeniorMode] Init failed: ${JSON.stringify(error)}`);
      this.handleInitError(error);
    }
  }
  
  /**
   * 应用销毁时取消监听
   */
  aboutToDisappear(): void {
    console.info('[SeniorMode] aboutToDisappear');
    
    try {
      // 取消监听，避免内存泄漏
      accessibility.offSeniorModeStateChangeForSelf(this.seniorModeCallback);
      console.info('[SeniorMode] Listener unregistered');
    } catch (error) {
      console.error(`[SeniorMode] Unregister listener failed: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 切换关怀模式状态
   */
  async toggleSeniorMode(isOn: boolean): Promise<void> {
    console.info(`[SeniorMode] Toggle to: ${isOn}`);
    
    try {
      // 防止重复设置
      if (isOn === this.seniorModeState) {
        console.info('[SeniorMode] State unchanged, skip setting');
        return;
      }
      
      // 1. 更新本地状态
      this.seniorModeState = isOn;
      this.message = `正在设置关怀模式：${isOn ? '开启' : '关闭'}...`;
      
      // 2. 同步到系统设置
      await accessibility.setSeniorModeStateForSelf(isOn);
      console.info(`[SeniorMode] Set system state to: ${isOn}`);
      
      // 3. 更新UI和提示
      this.message = `关怀模式状态：${isOn ? '开启' : '关闭'}`;
      this.updateSeniorModeUI(isOn);
      this.showToast(`关怀模式已${isOn ? '开启' : '关闭'}`);
    } catch (error) {
      console.error(`[SeniorMode] Toggle failed: ${JSON.stringify(error)}`);
      this.handleToggleError(error, isOn);
    }
  }
  
  /**
   * 更新关怀模式UI
   */
  updateSeniorModeUI(state: boolean): void {
    console.info(`[SeniorMode] Update UI to: ${state}`);
    
    if (state) {
      // 开启关怀模式UI调整：
      // - 增大字体尺寸
      // - 增大图标尺寸
      // - 简化布局
      // - 提高对比度
    } else {
      // 关闭关怀模式，恢复标准UI
    }
  }
  
  /**
   * 显示Toast提示
   */
  showToast(message: string): void {
    console.info(`[SeniorMode] Toast: ${message}`);
    // 实际项目中使用prompt.showToast或自定义Toast组件
  }
  
  /**
   * 处理初始化错误
   */
  handleInitError(error: any): void {
    const errorCode = error.code || -1;
    
    switch (errorCode) {
      case 201:
        // 权限不足
        this.message = '权限不足，请前往系统设置授权';
        this.showPermissionDialog();
        break;
      case 202:
        // API版本不支持
        this.message = '系统版本过低，请升级至API 26.0.0以上';
        this.useFallbackMode();
        break;
      default:
        // 其他错误，使用降级方案
        this.message = '关怀模式初始化失败，使用降级方案';
        this.useFallbackMode();
        break;
    }
  }
  
  /**
   * 处理切换错误
   */
  handleToggleError(error: any, targetState: boolean): void {
    const errorCode = error.code || -1;
    
    // 回滚状态
    this.seniorModeState = !targetState;
    this.message = `关怀模式状态：${this.seniorModeState ? '开启' : '关闭'}`;
    
    switch (errorCode) {
      case 201:
        this.showToast('权限不足，无法设置关怀模式');
        break;
      case 203:
        this.showToast('系统服务异常，请稍后重试');
        break;
      default:
        this.showToast('关怀模式设置失败');
        break;
    }
  }
  
  /**
   * 显示权限授权对话框
   */
  showPermissionDialog(): void {
    console.info('[SeniorMode] Show permission dialog');
    // 实际项目中使用AlertDialog或自定义对话框
    // 提示用户前往系统设置授予关怀模式权限
  }
  
  /**
   * 降级方案：定时查询关怀模式状态
   */
  useFallbackMode(): void {
    console.info('[SeniorMode] Use fallback mode - polling every 5s');
    
    // 每5秒查询一次关怀模式状态
    const pollInterval = setInterval(async () => {
      try {
        const state = await accessibility.getSeniorModeStateForSelf();
        if (state !== this.seniorModeState) {
          console.info(`[SeniorMode] Polling detected change: ${state}`);
          this.seniorModeState = state;
          this.message = `关怀模式状态：${state ? '开启' : '关闭'}`;
          this.updateSeniorModeUI(state);
        }
      } catch (error) {
        console.error(`[SeniorMode] Polling failed: ${JSON.stringify(error)}`);
        // 查询失败，保持当前状态
      }
    }, 5000);
    
    // 注意：实际项目中需要在aboutToDisappear中清除定时器
    // 这里简化处理，实际需要保存intervalId并在销毁时clearInterval
  }
  
  build() {
    Column() {
      // 标题
      Text('应用内关怀模式与系统设置同步')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })
      
      // 状态提示
      Text(this.message)
        .fontSize(18)
        .margin({ bottom: 20 })
      
      // 关怀模式开关
      Row() {
        Text('长辈关怀模式')
          .fontSize(20)
          .margin({ right: 20 })
        
        Toggle({ type: ToggleType.Switch, isOn: this.seniorModeState })
          .selectedColor('#007DFF')
          .onChange(async (isOn: boolean) => {
            await this.toggleSeniorMode(isOn);
          })
      }
      .margin({ top: 30, bottom: 20 })
      
      // 说明文本
      Text('开启关怀模式后，系统设置中的关怀模式开关会同步更新')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 20 })
      
      // API版本说明
      Text('API版本要求：26.0.0及以上')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 10 })
      
      // 功能说明
      Column() {
        Text('功能说明：')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 30, bottom: 10 })
        
        Text('1. 应用启动时查询系统关怀模式状态')
          .fontSize(14)
          .margin({ bottom: 8 })
        
        Text('2. 监听系统设置中的关怀模式变化')
          .fontSize(14)
          .margin({ bottom: 8 })
        
        Text('3. 应用内切换关怀模式同步到系统设置')
          .fontSize(14)
          .margin({ bottom: 8 })
        
        Text('4. 支持权限不足和API版本不兼容的降级方案')
          .fontSize(14)
          .margin({ bottom: 8 })
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}