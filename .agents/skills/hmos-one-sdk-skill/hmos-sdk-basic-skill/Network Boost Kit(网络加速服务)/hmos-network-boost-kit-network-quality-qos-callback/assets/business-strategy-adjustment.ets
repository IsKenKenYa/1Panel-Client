import { netQuality } from '@kit.NetworkBoostKit';

/**
 * 业务策略类型枚举
 */
export enum BusinessType {
  VIDEO_STREAMING = 'video_streaming',
  LIVE_STREAMING = 'live_streaming',
  GAME = 'game',
  FILE_DOWNLOAD = 'file_download',
  VIDEO_CALL = 'video_call'
}

/**
 * 网络质量等级
 */
export enum NetworkQualityLevel {
  EXCELLENT = 'excellent',    // 优秀: > 10Mbps
  GOOD = 'good',              // 良好: 5-10Mbps
  NORMAL = 'normal',          // 一般: 1-5Mbps
  POOR = 'poor',              // 较差: 100Kbps-1Mbps
  BAD = 'bad'                 // 很差: < 100Kbps
}

/**
 * 业务策略建议
 */
export interface BusinessStrategy {
  qualityLevel: NetworkQualityLevel;
  bandwidth: number;           // Mbps
  latency: number;             // ms
  suggestions: string[];
  actions: string[];
}

/**
 * 业务策略调整器
 * 根据网络质量动态调整业务策略
 */
export class BusinessStrategyAdjuster {
  private currentStrategy: BusinessStrategy | null = null;
  private qosHistory: netQuality.NetworkQos[] = [];
  private readonly MAX_HISTORY_SIZE = 10;

  /**
   * 根据网络质量调整策略
   * @param qos 网络质量数据
   * @param businessType 业务类型
   * @returns 业务策略建议
   */
  adjustStrategy(qos: netQuality.NetworkQos, businessType: BusinessType): BusinessStrategy {
    // 记录历史数据
    this.addToHistory(qos);

    // 计算平均网络质量
    const avgQos = this.calculateAverageQos();

    // 评估网络质量等级
    const qualityLevel = this.evaluateQualityLevel(avgQos);

    // 根据业务类型和网络质量生成策略
    const strategy = this.generateStrategy(qualityLevel, avgQos, businessType);

    this.currentStrategy = strategy;
    return strategy;
  }

  /**
   * 添加到历史记录
   * @param qos 网络质量数据
   */
  private addToHistory(qos: netQuality.NetworkQos): void {
    this.qosHistory.push(qos);
    if (this.qosHistory.length > this.MAX_HISTORY_SIZE) {
      this.qosHistory.shift();
    }
  }

  /**
   * 计算平均网络质量
   * @returns 平均网络质量数据
   */
  private calculateAverageQos(): netQuality.NetworkQos {
    if (this.qosHistory.length === 0) {
      throw new Error('无历史网络质量数据');
    }

    const sum = this.qosHistory.reduce((acc, qos) => ({
      pathType: qos.pathType,
      linkUpBandwidth: acc.linkUpBandwidth + qos.linkUpBandwidth,
      linkDownBandwidth: acc.linkDownBandwidth + qos.linkDownBandwidth,
      linkUpRate: acc.linkUpRate + qos.linkUpRate,
      linkDownRate: acc.linkDownRate + qos.linkDownRate,
      rttMs: acc.rttMs + qos.rttMs,
      linkUpBufferDelayMs: acc.linkUpBufferDelayMs + qos.linkUpBufferDelayMs,
      linkUpBufferCongestionPercent: acc.linkUpBufferCongestionPercent + (qos.linkUpBufferCongestionPercent || 0)
    }), {
      pathType: this.qosHistory[0].pathType,
      linkUpBandwidth: 0,
      linkDownBandwidth: 0,
      linkUpRate: 0,
      linkDownRate: 0,
      rttMs: 0,
      linkUpBufferDelayMs: 0,
      linkUpBufferCongestionPercent: 0
    });

    const count = this.qosHistory.length;
    return {
      pathType: sum.pathType,
      linkUpBandwidth: sum.linkUpBandwidth / count,
      linkDownBandwidth: sum.linkDownBandwidth / count,
      linkUpRate: sum.linkUpRate / count,
      linkDownRate: sum.linkDownRate / count,
      rttMs: sum.rttMs / count,
      linkUpBufferDelayMs: sum.linkUpBufferDelayMs / count,
      linkUpBufferCongestionPercent: sum.linkUpBufferCongestionPercent / count
    };
  }

  /**
   * 评估网络质量等级
   * @param qos 网络质量数据
   * @returns 质量等级
   */
  private evaluateQualityLevel(qos: netQuality.NetworkQos): NetworkQualityLevel {
    const bandwidthMbps = qos.linkDownBandwidth / 1000000; // 转换为Mbps

    if (bandwidthMbps > 10) {
      return NetworkQualityLevel.EXCELLENT;
    } else if (bandwidthMbps > 5) {
      return NetworkQualityLevel.GOOD;
    } else if (bandwidthMbps > 1) {
      return NetworkQualityLevel.NORMAL;
    } else if (bandwidthMbps > 0.1) {
      return NetworkQualityLevel.POOR;
    } else {
      return NetworkQualityLevel.BAD;
    }
  }

  /**
   * 生成业务策略
   * @param qualityLevel 网络质量等级
   * @param qos 网络质量数据
   * @param businessType 业务类型
   * @returns 业务策略
   */
  private generateStrategy(
    qualityLevel: NetworkQualityLevel,
    qos: netQuality.NetworkQos,
    businessType: BusinessType
  ): BusinessStrategy {
    const bandwidthMbps = qos.linkDownBandwidth / 1000000;
    const latency = qos.rttMs;

    const strategy: BusinessStrategy = {
      qualityLevel,
      bandwidth: bandwidthMbps,
      latency,
      suggestions: [],
      actions: []
    };

    // 根据业务类型生成具体策略
    switch (businessType) {
      case BusinessType.VIDEO_STREAMING:
        this.generateVideoStreamingStrategy(strategy, qos);
        break;
      case BusinessType.LIVE_STREAMING:
        this.generateLiveStreamingStrategy(strategy, qos);
        break;
      case BusinessType.GAME:
        this.generateGameStrategy(strategy, qos);
        break;
      case BusinessType.FILE_DOWNLOAD:
        this.generateDownloadStrategy(strategy, qos);
        break;
      case BusinessType.VIDEO_CALL:
        this.generateVideoCallStrategy(strategy, qos);
        break;
    }

    return strategy;
  }

  /**
   * 视频点播策略
   */
  private generateVideoStreamingStrategy(strategy: BusinessStrategy, qos: netQuality.NetworkQos): void {
    switch (strategy.qualityLevel) {
      case NetworkQualityLevel.EXCELLENT:
        strategy.suggestions.push('网络状况优秀，可使用4K超清画质');
        strategy.actions.push('setVideoQuality:4K');
        strategy.actions.push('enableHDR:true');
        break;
      case NetworkQualityLevel.GOOD:
        strategy.suggestions.push('网络状况良好，建议使用1080P高清画质');
        strategy.actions.push('setVideoQuality:1080P');
        strategy.actions.push('enableHDR:true');
        break;
      case NetworkQualityLevel.NORMAL:
        strategy.suggestions.push('网络状况一般，建议使用720P标清画质');
        strategy.actions.push('setVideoQuality:720P');
        strategy.actions.push('enableHDR:false');
        break;
      case NetworkQualityLevel.POOR:
        strategy.suggestions.push('网络状况较差，建议使用480P画质');
        strategy.actions.push('setVideoQuality:480P');
        strategy.actions.push('enableHDR:false');
        strategy.actions.push('preload:false');
        break;
      case NetworkQualityLevel.BAD:
        strategy.suggestions.push('网络状况很差，建议降低到360P或暂停播放');
        strategy.actions.push('setVideoQuality:360P');
        strategy.actions.push('enableHDR:false');
        strategy.actions.push('preload:false');
        strategy.actions.push('suggestPause:true');
        break;
    }
  }

  /**
   * 直播策略
   */
  private generateLiveStreamingStrategy(strategy: BusinessStrategy, qos: netQuality.NetworkQos): void {
    if (qos.rttMs > 500) {
      strategy.suggestions.push('网络延迟较高，可能影响直播互动体验');
      strategy.actions.push('reduceLatency:true');
    }

    switch (strategy.qualityLevel) {
      case NetworkQualityLevel.EXCELLENT:
      case NetworkQualityLevel.GOOD:
        strategy.suggestions.push('网络状况良好，可使用高清直播');
        strategy.actions.push('setLiveQuality:high');
        strategy.actions.push('setBitrate:4000');
        break;
      case NetworkQualityLevel.NORMAL:
        strategy.suggestions.push('网络状况一般，建议使用标清直播');
        strategy.actions.push('setLiveQuality:medium');
        strategy.actions.push('setBitrate:2000');
        break;
      case NetworkQualityLevel.POOR:
      case NetworkQualityLevel.BAD:
        strategy.suggestions.push('网络状况较差，建议使用流畅直播');
        strategy.actions.push('setLiveQuality:low');
        strategy.actions.push('setBitrate:800');
        break;
    }
  }

  /**
   * 游戏策略
   */
  private generateGameStrategy(strategy: BusinessStrategy, qos: netQuality.NetworkQos): void {
    if (qos.rttMs > 100) {
      strategy.suggestions.push(`当前延迟${qos.rttMs}ms，较高，可能影响游戏体验`);
      strategy.actions.push('optimizeLatency:true');
    }

    if (qos.rttMs < 50) {
      strategy.suggestions.push('网络延迟很低，游戏体验极佳');
      strategy.actions.push('setGameMode:highPerformance');
    } else if (qos.rttMs < 100) {
      strategy.suggestions.push('网络延迟适中，游戏体验良好');
      strategy.actions.push('setGameMode:balanced');
    } else if (qos.rttMs < 200) {
      strategy.suggestions.push('网络延迟较高，建议优化游戏设置');
      strategy.actions.push('setGameMode:lowLatency');
      strategy.actions.push('reduceEffects:true');
    } else {
      strategy.suggestions.push('网络延迟过高，不建议进行实时对战游戏');
      strategy.actions.push('suggestOfflineMode:true');
    }
  }

  /**
   * 文件下载策略
   */
  private generateDownloadStrategy(strategy: BusinessStrategy, qos: netQuality.NetworkQos): void {
    const totalRate = (qos.linkUpRate + qos.linkDownRate) / 8000; // KB/s

    if (totalRate > 1000) { // > 1 MB/s
      strategy.suggestions.push('下载速度很快，可同时下载多个文件');
      strategy.actions.push('setConcurrentDownloads:3');
      strategy.actions.push('setDownloadSpeed:unlimited');
    } else if (totalRate > 500) {
      strategy.suggestions.push('下载速度良好，可正常下载');
      strategy.actions.push('setConcurrentDownloads:2');
      strategy.actions.push('setDownloadSpeed:unlimited');
    } else if (totalRate > 100) {
      strategy.suggestions.push('下载速度一般，建议减少并发');
      strategy.actions.push('setConcurrentDownloads:1');
      strategy.actions.push('setDownloadSpeed:unlimited');
    } else {
      strategy.suggestions.push('下载速度较慢，建议在WiFi环境下载');
      strategy.actions.push('setConcurrentDownloads:1');
      strategy.actions.push('setDownloadSpeed:limited');
      strategy.actions.push('suggestWiFi:true');
    }
  }

  /**
   * 视频通话策略
   */
  private generateVideoCallStrategy(strategy: BusinessStrategy, qos: netQuality.NetworkQos): void {
    if (qos.rttMs > 300) {
      strategy.suggestions.push('网络延迟较高，视频通话可能出现卡顿');
      strategy.actions.push('setVideoQuality:low');
      strategy.actions.push('setFrameRate:15');
    } else if (qos.rttMs > 150) {
      strategy.suggestions.push('网络延迟适中，建议使用标清视频');
      strategy.actions.push('setVideoQuality:medium');
      strategy.actions.push('setFrameRate:24');
    } else {
      strategy.suggestions.push('网络延迟较低，可使用高清视频');
      strategy.actions.push('setVideoQuality:high');
      strategy.actions.push('setFrameRate:30');
    }

    if (strategy.qualityLevel === NetworkQualityLevel.POOR || 
        strategy.qualityLevel === NetworkQualityLevel.BAD) {
      strategy.suggestions.push('网络质量较差，建议切换到语音通话');
      strategy.actions.push('suggestVoiceCall:true');
    }
  }

  /**
   * 获取当前策略
   */
  getCurrentStrategy(): BusinessStrategy | null {
    return this.currentStrategy;
  }

  /**
   * 清空历史记录
   */
  clearHistory(): void {
    this.qosHistory = [];
  }
}

/**
 * 使用示例
 */
export function exampleUsage(): void {
  const adjuster = new BusinessStrategyAdjuster();

  // 模拟接收到网络质量数据
  const mockQos: netQuality.NetworkQos = {
    pathType: netQuality.PathType.WIFI_PRIMARY,
    linkUpBandwidth: 5000000,   // 5 Mbps
    linkDownBandwidth: 20000000, // 20 Mbps
    linkUpRate: 3000000,         // 3 Mbps
    linkDownRate: 15000000,      // 15 Mbps
    rttMs: 50,
    linkUpBufferDelayMs: 10,
    linkUpBufferCongestionPercent: 5
  };

  // 根据网络质量调整视频点播策略
  const videoStrategy = adjuster.adjustStrategy(mockQos, BusinessType.VIDEO_STREAMING);
  console.info('视频点播策略:', JSON.stringify(videoStrategy, null, 2));

  // 根据网络质量调整游戏策略
  const gameStrategy = adjuster.adjustStrategy(mockQos, BusinessType.GAME);
  console.info('游戏策略:', JSON.stringify(gameStrategy, null, 2));
}