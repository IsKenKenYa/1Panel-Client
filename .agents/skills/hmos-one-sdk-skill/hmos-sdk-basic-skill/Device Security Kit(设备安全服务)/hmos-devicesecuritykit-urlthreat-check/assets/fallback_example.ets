import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';

const TAG = "UrlThreatFallback";
const DOMAIN = 0x0000;

export class LocalThreatDatabase {
  private static readonly PREF_KEY = 'threat_urls';
  private static readonly THREAT_URLS = [
    'malware-site.com',
    'phishing-site.com',
    'known-threat.net'
  ];
  
  private localThreatUrls: Set<string> = new Set();
  private dataPreferences: preferences.Preferences | null = null;
  
  async initialize(context: Context): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, 'threat_db');
      
      const cachedUrls = await this.dataPreferences.get(LocalThreatDatabase.PREF_KEY, []) as string[];
      if (cachedUrls && cachedUrls.length > 0) {
        this.localThreatUrls = new Set(cachedUrls);
        hilog.info(DOMAIN, TAG, '从缓存加载威胁URL: %{public}d个', this.localThreatUrls.size);
      } else {
        this.localThreatUrls = new Set(LocalThreatDatabase.THREAT_URLS);
        hilog.info(DOMAIN, TAG, '使用默认威胁URL: %{public}d个', this.localThreatUrls.size);
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '初始化本地威胁数据库失败，使用默认数据');
      this.localThreatUrls = new Set(LocalThreatDatabase.THREAT_URLS);
    }
  }
  
  async updateThreatUrls(urls: string[]): Promise<void> {
    this.localThreatUrls = new Set(urls);
    
    if (this.dataPreferences) {
      try {
        await this.dataPreferences.put(LocalThreatDatabase.PREF_KEY, urls);
        await this.dataPreferences.flush();
        hilog.info(DOMAIN, TAG, '更新本地威胁数据库: %{public}d个', urls.length);
      } catch (err) {
        hilog.error(DOMAIN, TAG, '保存威胁URL失败');
      }
    }
  }
  
  checkUrl(url: string): safetyDetect.UrlThreatType {
    const urlLower = url.toLowerCase();
    
    for (const threatUrl of this.localThreatUrls) {
      if (urlLower.includes(threatUrl.toLowerCase())) {
        return safetyDetect.UrlThreatType.OTHERS;
      }
    }
    
    return safetyDetect.UrlThreatType.NORMAL;
  }
  
  checkUrls(urls: string[]): safetyDetect.UrlCheckResponse {
    const results: safetyDetect.UrlCheckResult[] = urls.map(url => ({
      url: url,
      threat: this.checkUrl(url)
    }));
    
    return { results };
  }
}

export class UrlThreatCheckerWithFallback {
  private localDb: LocalThreatDatabase;
  private isOnlineMode: boolean = true;
  
  constructor() {
    this.localDb = new LocalThreatDatabase();
  }
  
  async initialize(context: Context): Promise<void> {
    await this.localDb.initialize(context);
  }
  
  async checkUrls(urls: string[]): Promise<safetyDetect.UrlCheckResponse> {
    if (!urls || urls.length === 0) {
      throw new Error('URL列表不能为空');
    }
    
    if (urls.length > 10) {
      throw new Error('单次请求最多检测10个URL');
    }
    
    if (this.isOnlineMode) {
      try {
        const response = await this.checkOnline(urls);
        await this.updateLocalDatabase(response);
        return response;
      } catch (err) {
        const e: BusinessError = err as BusinessError;
        hilog.warn(DOMAIN, TAG, '在线检测失败: %{public}d，切换到本地检测', e.code);
        return this.checkFallback(urls, err as BusinessError);
      }
    } else {
      hilog.info(DOMAIN, TAG, '使用本地检测模式');
      return this.localDb.checkUrls(urls);
    }
  }
  
  private async checkOnline(urls: string[]): Promise<safetyDetect.UrlCheckResponse> {
    const req: safetyDetect.UrlCheckRequest = { urls };
    
    try {
      hilog.info(DOMAIN, TAG, '开始在线检测URL威胁');
      const response = await safetyDetect.checkUrlThreat(req);
      hilog.info(DOMAIN, TAG, '在线检测完成');
      return response;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, '在线检测失败: %{public}d %{public}s', e.code, e.message);
      throw err;
    }
  }
  
  private checkFallback(urls: string[], err: BusinessError): safetyDetect.UrlCheckResponse {
    if (this.isRecoverableError(err.code)) {
      hilog.info(DOMAIN, TAG, '使用本地降级检测');
      return this.localDb.checkUrls(urls);
    } else {
      hilog.error(DOMAIN, TAG, '不可恢复错误，无法使用降级检测');
      throw err;
    }
  }
  
  private async updateLocalDatabase(response: safetyDetect.UrlCheckResponse): Promise<void> {
    const threatUrls: string[] = [];
    
    for (const result of response.results) {
      if (result.threat !== safetyDetect.UrlThreatType.NORMAL) {
        threatUrls.push(result.url);
      }
    }
    
    if (threatUrls.length > 0) {
      await this.localDb.updateThreatUrls(threatUrls);
      hilog.info(DOMAIN, TAG, '更新本地威胁数据库: %{public}d个新威胁', threatUrls.length);
    }
  }
  
  private isRecoverableError(code: number): boolean {
    const recoverableCodes = [
      1010800002,
      1010800003,
      1010800007,
      1010800008
    ];
    
    return recoverableCodes.includes(code);
  }
  
  setOnlineMode(enabled: boolean): void {
    this.isOnlineMode = enabled;
    hilog.info(DOMAIN, TAG, '检测模式: %{public}s', enabled ? '在线' : '离线');
  }
}

export class UrlThreatCache {
  private static readonly CACHE_DURATION = 24 * 60 * 60 * 1000;
  private cache: Map<string, { threat: safetyDetect.UrlThreatType, timestamp: number }> = new Map();
  
  get(url: string): safetyDetect.UrlThreatType | null {
    const cached = this.cache.get(url);
    
    if (!cached) {
      return null;
    }
    
    const now = Date.now();
    if (now - cached.timestamp > UrlThreatCache.CACHE_DURATION) {
      this.cache.delete(url);
      return null;
    }
    
    return cached.threat;
  }
  
  set(url: string, threat: safetyDetect.UrlThreatType): void {
    this.cache.set(url, {
      threat: threat,
      timestamp: Date.now()
    });
  }
  
  has(url: string): boolean {
    const cached = this.cache.get(url);
    if (!cached) {
      return false;
    }
    
    const now = Date.now();
    if (now - cached.timestamp > UrlThreatCache.CACHE_DURATION) {
      this.cache.delete(url);
      return false;
    }
    
    return true;
  }
  
  clear(): void {
    this.cache.clear();
  }
}

export class UrlThreatCheckerOptimized {
  private checkerWithFallback: UrlThreatCheckerWithFallback;
  private cache: UrlThreatCache;
  
  constructor() {
    this.checkerWithFallback = new UrlThreatCheckerWithFallback();
    this.cache = new UrlThreatCache();
  }
  
  async initialize(context: Context): Promise<void> {
    await this.checkerWithFallback.initialize(context);
  }
  
  async checkUrls(urls: string[]): Promise<safetyDetect.UrlCheckResponse> {
    const uncachedUrls: string[] = [];
    const results: safetyDetect.UrlCheckResult[] = [];
    
    for (const url of urls) {
      const cachedThreat = this.cache.get(url);
      if (cachedThreat !== null) {
        results.push({
          url: url,
          threat: cachedThreat
        });
      } else {
        uncachedUrls.push(url);
      }
    }
    
    if (uncachedUrls.length > 0) {
      const freshResults = await this.checkerWithFallback.checkUrls(uncachedUrls);
      
      for (const result of freshResults.results) {
        this.cache.set(result.url, result.threat);
        results.push(result);
      }
    }
    
    return { results };
  }
}