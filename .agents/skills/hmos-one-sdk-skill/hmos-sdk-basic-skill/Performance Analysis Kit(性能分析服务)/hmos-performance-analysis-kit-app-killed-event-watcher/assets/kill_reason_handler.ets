import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'KillReasonHandler';

export enum KillReasonCategory {
  MEMORY = 'memory',
  RESOURCE_LEAK = 'resource_leak',
  CPU_HIGHLOAD = 'cpu_highload',
  LIFECYCLE = 'lifecycle',
  USER_ACTION = 'user_action',
  OTHER = 'other'
}

export interface KillEventInfo {
  timestamp: number;
  reason: string;
  foreground: boolean;
  uniqueId?: string;
  bundleVersion?: string;
}

export function classifyKillReason(reason: string): KillReasonCategory {
  if (reason.includes('Memory') || reason.includes('OomKiller') || reason === 'SwapFull') {
    return KillReasonCategory.MEMORY;
  }
  
  if (reason.startsWith('ResourceLeak')) {
    return KillReasonCategory.RESOURCE_LEAK;
  }
  
  if (reason.includes('CPU') || reason.includes('Highload')) {
    return KillReasonCategory.CPU_HIGHLOAD;
  }
  
  if (reason.includes('Timeout') || reason.includes('Block')) {
    return KillReasonCategory.LIFECYCLE;
  }
  
  if (reason === 'UserRequest' || reason === 'Uninstall' || reason === 'KillApplication') {
    return KillReasonCategory.USER_ACTION;
  }
  
  return KillReasonCategory.OTHER;
}

export function getKillReasonDescription(reason: string): string {
  const descriptions: Record<string, string> = {
    'LowMemoryKill': '整机低内存触发，优先级由低到高终止应用',
    'SwapFull': 'Swap交换空间接近占满',
    'ResourceLeak(IonLeak)': '应用占用的Ion内存超标',
    'ResourceLeak(GpuRsLeak)': '应用的ArkUI组件在Render Service进程占用的GPU内存超标',
    'ResourceLeak(GpuLeak)': '应用在本进程占用的GPU内存超标',
    'ResourceLeak(AshmemLeak)': '应用占用的Ashmem内存超标',
    'ResourceLeak(CES)': 'CES注册超限',
    'ResourceLeak(PSSSoftLeak)': '后台应用内存占用超过检测阈值两倍',
    'ResourceLeak(PSSLeak)': '后台应用内存占用超过特定阈值',
    'ResourceLeak(VMALeak)': 'VMA泄漏',
    'ResourceLeak(FDLeak)': 'FD泄漏',
    'ResourceLeak(ThreadLeak)': '线程泄漏',
    'RssThresholdKiller': '应用的RSS占用超标',
    'OomKiller': '整机低内存，触发内核管控',
    'CPUHighload': '应用后台CPU高负载，系统自动终止',
    'ThreadBlock6S': '应用主线程卡死超时',
    'AppInputBlock': '用户输入响应超时',
    'LifecycleTimeout': '应用生命周期超时',
    'JsError': 'js层程序崩溃',
    'CppCrash': 'native层程序崩溃',
    'UserRequest': '最近任务上划或清理',
    'Uninstall': '应用卸载退出',
    'KillApplication': '应用主动退出'
  };
  
  return descriptions[reason] || '未知的终止原因';
}

export function getKillReasonSuggestion(reason: string): string {
  const category = classifyKillReason(reason);
  
  switch (category) {
    case KillReasonCategory.MEMORY:
      return '建议检查内存使用情况，优化内存分配策略，避免内存泄漏';
    case KillReasonCategory.RESOURCE_LEAK:
      const leakType = reason.replace('ResourceLeak(', '').replace(')', '');
      return `建议检查${leakType}资源使用情况，及时释放未使用的资源`;
    case KillReasonCategory.CPU_HIGHLOAD:
      return '建议优化CPU密集型任务，减少后台高负载操作';
    case KillReasonCategory.LIFECYCLE:
      return '建议优化生命周期响应速度，避免主线程阻塞';
    case KillReasonCategory.USER_ACTION:
      return '用户主动终止应用，无需特别处理';
    default:
      return '建议记录该终止原因，用于后续分析和优化';
  }
}

export function logKillEvent(eventInfo: KillEventInfo): void {
  const category = classifyKillReason(eventInfo.reason);
  const description = getKillReasonDescription(eventInfo.reason);
  const suggestion = getKillReasonSuggestion(eventInfo.reason);
  
  hilog.info(DOMAIN, TAG, `=== App Kill Event Log ===`);
  hilog.info(DOMAIN, TAG, `Category: ${category}`);
  hilog.info(DOMAIN, TAG, `Reason: ${eventInfo.reason}`);
  hilog.info(DOMAIN, TAG, `Description: ${description}`);
  hilog.info(DOMAIN, TAG, `Timestamp: ${eventInfo.timestamp}`);
  hilog.info(DOMAIN, TAG, `Foreground: ${eventInfo.foreground}`);
  
  if (eventInfo.uniqueId) {
    hilog.info(DOMAIN, TAG, `Unique ID: ${eventInfo.uniqueId}`);
  }
  
  if (eventInfo.bundleVersion) {
    hilog.info(DOMAIN, TAG, `Bundle Version: ${eventInfo.bundleVersion}`);
  }
  
  hilog.info(DOMAIN, TAG, `Suggestion: ${suggestion}`);
  hilog.info(DOMAIN, TAG, `========================`);
}

export function analyzeKillReasons(reasons: string[]): Record<KillReasonCategory, number> {
  const categoryCount: Record<KillReasonCategory, number> = {
    [KillReasonCategory.MEMORY]: 0,
    [KillReasonCategory.RESOURCE_LEAK]: 0,
    [KillReasonCategory.CPU_HIGHLOAD]: 0,
    [KillReasonCategory.LIFECYCLE]: 0,
    [KillReasonCategory.USER_ACTION]: 0,
    [KillReasonCategory.OTHER]: 0
  };
  
  for (const reason of reasons) {
    const category = classifyKillReason(reason);
    categoryCount[category]++;
  }
  
  return categoryCount;
}

export function getTopKillReasons(reasons: string[], topN: number = 5): string[] {
  const reasonCount: Record<string, number> = {};
  
  for (const reason of reasons) {
    reasonCount[reason] = (reasonCount[reason] || 0) + 1;
  }
  
  const sortedReasons = Object.entries(reasonCount)
    .sort((a, b) => b[1] - a[1])
    .slice(0, topN)
    .map(entry => entry[0]);
  
  return sortedReasons;
}