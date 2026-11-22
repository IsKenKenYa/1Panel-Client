# 设备分档机制（通用基础设施）

**重要**: 设备分档是所有优化方案共享的通用机制，不属于任何特定优化方案。

## 机制说明

基于硬件信息（内存大小 + CPU 型号）进行基础分档，再结合动态性能信息（冷启动时延）进行降档调整，将设备分为 high / medium / low 三档。所有优化方案均可引用该分档结果调整策略参数。

## 分档原理说明

### 分档策略：硬件基础分档 + 冷启动动态调整

```
judgeDeviceLevel():
  1. 硬件基础分档
     ├── 内存 ≤ 8GB 或 CPU 型号包含 "8000" → LOW
     ├── 内存 > 8GB 且 CPU 型号不含 "8000" → HIGH
     └── 否则 → MEDIUM
  2. 冷启动降档调整（可选，需传入 launchTime）
     ├── launchTime > 3000ms → 降低一档
     └── launchTime ≤ 3000ms → 保持基础档位
```

### 硬件指标阈值

| 硬件指标 | 低端机 | 中端机 | 高端机 |
|---------|--------|--------|--------|
| 内存大小 | ≤ 8GB | / | > 8GB |
| CPU型号 | 麒麟8000及以下 | / | 麒麟8000以上 |
| 冷启动 | > 3s | 1.5s ~ 3s | < 1.5s |
| 一二级页面转场 | > 2.5s | 1s ~ 2.5s | < 1s |

### 数据来源

| 评估维度 | API | 说明 |
|----------|-----|------|
| 内存大小 | `hidebug.getSystemMemInfo().totalMem` | 返回 KB (bigint)，需 Number() 转换 |
| CPU 型号 | `deviceInfo.hardwareModel` | 如 "HL1CMSM"，结合 CPU 型号特征判断 |
| 冷启动耗时 | `Date.now()` 差值 | onCreate 到 onWindowStageCreate loadContent 完成 |

## 完整代码模板

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
// 机型分档：基于硬件信息（内存 + CPU型号）基础分档 + 冷启动时延动态调整
// 所有阈值均可由开发者根据实际应用场景调整

import { deviceInfo } from '@kit.BasicServicesKit';
import { hidebug } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

// ========== 分档阈值配置（开发者可自定义） ==========

export class TierConfig {
  // --- 内存阈值 (GB) ---
  memoryLowThreshold: number = 8;       // ≤ 8GB 归为低档

  // --- CPU 型号关键字（低档关键字列表） ---
  // 包含这些关键字的 CPU 型号归为低档
  lowEndCpuKeywords: string[] = ['8000'];

  // --- 冷启动时延阈值 (ms) ---
  // 应用进程启动到首页可交互的耗时
  coldStartDowngradeThreshold: number = 3000;  // > 3000ms 降低一档

  // --- 缓存过期时间 (ms) ---
  cacheExpireMs: number = 24 * 60 * 60 * 1000;  // 默认 24 小时
}

// ========== 设备分档等级 ==========

export class DeviceLevel {
  static readonly TIER_LOW: string = 'low';
  static readonly TIER_MEDIUM: string = 'medium';
  static readonly TIER_HIGH: string = 'high';
}

// ========== 硬件指标数据结构 ==========

export interface HardwareMetrics {
  /** 内存大小(单位：GB) */
  memorySizeGB: number;
  /** CPU型号（硬件版本号） */
  cpuModel: string;
}

// ========== 设备分档评估器（单例模式，文件缓存） ==========

export class DeviceLevelDecisionCenter {
  private static instance: DeviceLevelDecisionCenter | null = null;
  private constructor() {}

  static getInstance(): DeviceLevelDecisionCenter {
    if (!DeviceLevelDecisionCenter.instance) {
      DeviceLevelDecisionCenter.instance = new DeviceLevelDecisionCenter();
    }
    return DeviceLevelDecisionCenter.instance;
  }

  private config: TierConfig = new TierConfig();
  private context: common.UIAbilityContext | undefined;
  private cachedDeviceLevel: string = '';
  private measuredColdStart: number = -1;  // -1 表示未测量

  private static readonly CACHE_KEY: string = 'device_grade_cache';

  // 初始化应用上下文（在 UIAbility.onCreate 中调用）
  init(context: common.UIAbilityContext): void {
    this.context = context;
  }

  // 设置分档阈值配置（应用启动时调用一次即可）
  setTierConfig(config: TierConfig): void {
    this.config = config;
    this.cachedDeviceLevel = '';
  }

  // 设置冷启动耗时（应用首次启动后测量一次）
  // coldStartMs: 冷启动耗时 (ms)
  setLaunchTime(coldStartMs: number): void {
    this.measuredColdStart = coldStartMs;
    this.cachedDeviceLevel = '';
  }

  // ========== 硬件指标采集 ==========

  // 获取设备硬件指标
  private getHardwareMetrics(): HardwareMetrics | null {
    try {
      let memInfo: hidebug.SystemMemInfo = hidebug.getSystemMemInfo();
      let totalMemKB: number = Number(memInfo.totalMem);
      let totalMemGB: number = totalMemKB / (1024 * 1024);
      let cpuModel: string = deviceInfo.hardwareModel;
      return {
        memorySizeGB: totalMemGB,
        cpuModel: cpuModel,
      };
    } catch (e) {
      return null;
    }
  }

  // ========== 硬件基础分档 ==========

  // 根据硬件指标判断基础档位（不含冷启动调整）
  private judgeByHardware(metrics: HardwareMetrics): string {
    let isLowEnd: boolean = false;

    // 内存判断
    if (metrics.memorySizeGB <= this.config.memoryLowThreshold) {
      isLowEnd = true;
    }

    // CPU 型号判断
    for (let keyword of this.config.lowEndCpuKeywords) {
      if (metrics.cpuModel.includes(keyword)) {
        isLowEnd = true;
        break;
      }
    }

    return isLowEnd ? DeviceLevel.TIER_LOW : DeviceLevel.TIER_HIGH;
  }

  // ========== 冷启动动态调整 ==========

  // 根据冷启动耗时调整档位
  private adjustByLaunchTime(baseLevel: string): string {
    let launchTime: number = this.measuredColdStart;
    if (launchTime < 0) {
      return baseLevel;  // 未测量，不做调整
    }

    if (launchTime > this.config.coldStartDowngradeThreshold) {
      // 启动慢，降低一档
      if (baseLevel === DeviceLevel.TIER_HIGH) {
        return DeviceLevel.TIER_MEDIUM;
      } else if (baseLevel === DeviceLevel.TIER_MEDIUM) {
        return DeviceLevel.TIER_LOW;
      }
    }

    return baseLevel;
  }

  // ========== 文件缓存 ==========

  // 读取缓存中的分档结果
  private readCache(): string {
    try {
      if (!this.context) {
        return '';
      }
      let cachePath: string = this.context.cacheDir + '/' + DeviceLevelDecisionCenter.CACHE_KEY;
      if (!fileIo.accessSync(cachePath)) {
        return '';
      }
      let fd: number = fileIo.openSync(cachePath, fileIo.OpenMode.READ_ONLY).fd;
      let stat: fileIo.Stat = fileIo.fstatSync(fd);
      let buf: ArrayBuffer = new ArrayBuffer(Number(stat.size));
      let readLen: number = fileIo.readSync(fd, buf);
      fileIo.closeSync(fd);

      let decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      let content: string = decoder.decodeWithStream(new Uint8Array(buf, 0, readLen));
      let lines: string[] = content.split('\n');
      if (lines.length < 2) {
        return '';
      }
      let cachedLevel: string = lines[0];
      let cacheTime: number = Number(lines[1]);
      if (Date.now() - cacheTime > this.config.cacheExpireMs) {
        return '';  // 缓存过期
      }
      return cachedLevel;
    } catch (e) {
      return '';
    }
  }

  // 缓存分档结果到文件
  private writeCache(level: string): void {
    try {
      if (!this.context) {
        return;
      }
      let cachePath: string = this.context.cacheDir + '/' + DeviceLevelDecisionCenter.CACHE_KEY;
      let content: string = level + '\n' + Date.now().toString();
      let file: fileIo.File = fileIo.openSync(cachePath,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);
      let encoder: util.TextEncoder = util.TextEncoder.create('utf-8');
      let encoded: Uint8Array = encoder.encodeInto(content);
      let buf: ArrayBuffer = new ArrayBuffer(encoded.length);
      let view: Uint8Array = new Uint8Array(buf);
      for (let i = 0; i < encoded.length; i++) {
        view[i] = encoded[i];
      }
      fileIo.writeSync(file.fd, buf);
      fileIo.closeSync(file.fd);
    } catch (e) {
      // 缓存写入失败不影响分档结果
    }
  }

  // ========== 核心 API ==========

  // 获取设备分档（优先缓存 → 文件缓存 → 重新计算）
  static getDeviceLevel(): string {
    return DeviceLevelDecisionCenter.getInstance().getLevel(false);
  }

  // 实例方法：获取设备分档
  getLevel(forceRefresh: boolean = false): string {
    // 1. 内存缓存
    if (!forceRefresh && this.cachedDeviceLevel !== '') {
      return this.cachedDeviceLevel;
    }

    // 2. 文件缓存
    if (!forceRefresh) {
      let cached: string = this.readCache();
      if (cached !== '') {
        this.cachedDeviceLevel = cached;
        return cached;
      }
    }

    // 3. 采集硬件指标
    let metrics: HardwareMetrics | null = this.getHardwareMetrics();
    if (!metrics) {
      // 硬件信息获取失败，默认中档
      this.cachedDeviceLevel = DeviceLevel.TIER_MEDIUM;
      return this.cachedDeviceLevel;
    }

    // 4. 硬件基础分档
    let baseLevel: string = this.judgeByHardware(metrics);

    // 5. 冷启动动态调整
    let finalLevel: string = this.adjustByLaunchTime(baseLevel);

    // 6. 缓存结果
    this.cachedDeviceLevel = finalLevel;
    this.writeCache(finalLevel);

    return finalLevel;
  }
}
```

## 时延测量方法

```typescript
import { DeviceLevelDecisionCenter } from '../../utils/DeviceLevelDecisionCenter';

// 冷启动时延测量（在 EntryAbility 中）

// 1. onCreate 中记录起始时间
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  this.startTime = Date.now();

  // 初始化设备分档管理类
  let manager: DeviceLevelDecisionCenter = DeviceLevelDecisionCenter.getInstance();
  manager.init(this.context);
}

// 2. onWindowStageCreate 中计算冷启动耗时
onWindowStageCreate(windowStage: window.WindowStage): void {
  windowStage.loadContent('pages/Index', (err, data) => {
    if (err.code) {
      return;
    }

    // 计算冷启动耗时
    let launchTime: number = Date.now() - this.startTime;

    // 传入冷启动耗时，触发分档判断
    let manager: DeviceLevelDecisionCenter = DeviceLevelDecisionCenter.getInstance();
    manager.setLaunchTime(launchTime);

    // 获取设备分档（首次调用会计算并缓存）
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
  });
}
```

## 权限要求

- DDR 内存信息通过 `hidebug.getSystemMemInfo()` 获取（无需额外权限）
- CPU 型号通过 `deviceInfo.hardwareModel` 获取（无需额外权限）
- 文件缓存使用 `context.cacheDir`（应用私有目录，无需权限）

