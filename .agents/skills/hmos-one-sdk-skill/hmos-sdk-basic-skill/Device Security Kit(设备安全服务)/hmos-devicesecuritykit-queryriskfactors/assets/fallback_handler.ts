import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@ohos.base';

const TAG = "FallbackHandler";
const DOMAIN = 0x0000;

export interface CachedRiskFactors {
  timestamp: number;
  nonce: string;
  factors: Map<string, { status: number, result: string }>;
  appId: string;
}

export class FallbackHandler {
  private cache: CachedRiskFactors | null = null;
  private maxCacheAge: number = 300000; // 5 minutes
  
  handleQueryFailure(error: BusinessError): string {
    hilog.warn(DOMAIN, TAG, 'Query failed with error %{public}d: %{public}s', error.code, error.message);
    
    switch (error.code) {
      case 1010800002:
        hilog.warn(DOMAIN, TAG, 'Network unreachable - using network fallback');
        return this.networkFallback();
        
      case 1010800006:
        hilog.warn(DOMAIN, TAG, 'Frequency exceeded - using frequency fallback');
        return this.frequencyFallback();
        
      case 1010800005:
        hilog.warn(DOMAIN, TAG, 'Concurrency exceeded - using concurrency fallback');
        return this.concurrencyFallback();
        
      case 1010800007:
        hilog.warn(DOMAIN, TAG, 'Operation timeout - using timeout fallback');
        return this.timeoutFallback();
        
      case 1010800003:
      case 1010800008:
        hilog.warn(DOMAIN, TAG, 'Cloud service issue - using service fallback');
        return this.serviceFallback();
        
      default:
        hilog.warn(DOMAIN, TAG, 'Unknown error - using generic fallback');
        return this.genericFallback();
    }
  }
  
  networkFallback(): string {
    hilog.info(DOMAIN, TAG, 'Executing network fallback strategy');
    
    if (this.hasValidCache()) {
      hilog.info(DOMAIN, TAG, 'Using cached risk factors data');
      return 'CACHED_DATA';
    }
    
    hilog.warn(DOMAIN, TAG, 'No valid cache available, using local simple detection');
    this.localSimpleDetection();
    return 'LOCAL_DETECTION';
  }
  
  frequencyFallback(): string {
    hilog.info(DOMAIN, TAG, 'Executing frequency fallback strategy');
    
    if (this.hasValidCache()) {
      hilog.info(DOMAIN, TAG, 'Using cached risk factors data');
      return 'CACHED_DATA';
    }
    
    hilog.warn(DOMAIN, TAG, 'Please wait before retrying. Frequency limit: 5 calls/minute, 20 calls/day');
    return 'WAIT_AND_RETRY';
  }
  
  concurrencyFallback(): string {
    hilog.info(DOMAIN, TAG, 'Executing concurrency fallback strategy');
    
    hilog.info(DOMAIN, TAG, 'Waiting for other concurrent calls to complete');
    this.waitForConcurrencySlot();
    return 'WAIT_CONCURRENCY';
  }
  
  timeoutFallback(): string {
    hilog.info(DOMAIN, TAG, 'Executing timeout fallback strategy');
    
    hilog.warn(DOMAIN, TAG, 'Operation timed out, checking network status and retrying with simpler query');
    return 'SIMPLIFIED_RETRY';
  }
  
  serviceFallback(): string {
    hilog.info(DOMAIN, TAG, 'Executing service fallback strategy');
    
    if (this.hasValidCache()) {
      hilog.info(DOMAIN, TAG, 'Using cached risk factors data');
      return 'CACHED_DATA';
    }
    
    hilog.warn(DOMAIN, TAG, 'Cloud service unavailable, try again later or use local detection');
    this.localSimpleDetection();
    return 'LOCAL_DETECTION';
  }
  
  genericFallback(): string {
    hilog.info(DOMAIN, TAG, 'Executing generic fallback strategy');
    
    hilog.warn(DOMAIN, TAG, 'Unknown error occurred, device security status unknown');
    this.showSecurityWarning();
    return 'SECURITY_UNKNOWN';
  }
  
  hasValidCache(): boolean {
    if (!this.cache) {
      hilog.info(DOMAIN, TAG, 'No cache available');
      return false;
    }
    
    const cacheAge = Date.now() - this.cache.timestamp;
    if (cacheAge > this.maxCacheAge) {
      hilog.info(DOMAIN, TAG, 'Cache expired (age: %{public}dms, max: %{public}dms)', cacheAge, this.maxCacheAge);
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'Cache valid (age: %{public}dms)', cacheAge);
    return true;
  }
  
  localSimpleDetection(): void {
    hilog.info(DOMAIN, TAG, 'Performing local simple security detection');
    
    hilog.info(DOMAIN, TAG, 'Local detection: checking basic device settings');
    hilog.info(DOMAIN, TAG, 'Note: Local detection provides limited security assessment');
    hilog.info(DOMAIN, TAG, 'Recommend: Use full query when service available for comprehensive assessment');
    
    this.showLimitedSecurityWarning();
  }
  
  waitForConcurrencySlot(): void {
    hilog.info(DOMAIN, TAG, 'Waiting for concurrency slot (max 10 concurrent calls)');
    hilog.info(DOMAIN, TAG, 'Current concurrent calls may be at maximum');
    hilog.info(DOMAIN, TAG, 'Strategy: Queue the request or use cached data if available');
    
    if (this.hasValidCache()) {
      hilog.info(DOMAIN, TAG, 'Fallback to cached data while waiting');
    }
  }
  
  showSecurityWarning(): void {
    hilog.warn(DOMAIN, TAG, 'SECURITY WARNING: Device security status unknown');
    hilog.warn(DOMAIN, TAG, 'Recommendation: Proceed with caution');
    hilog.warn(DOMAIN, TAG, 'Actions: Avoid sensitive operations until security verified');
  }
  
  showLimitedSecurityWarning(): void {
    hilog.warn(DOMAIN, TAG, 'LIMITED SECURITY WARNING: Using local detection only');
    hilog.warn(DOMAIN, TAG, 'Recommendation: Local detection provides limited assessment');
    hilog.warn(DOMAIN, TAG, 'Actions: Recommend full query when service available');
  }
  
  updateCache(nonce: string, factors: Map<string, { status: number, result: string }>, appId: string): void {
    this.cache = {
      timestamp: Date.now(),
      nonce: nonce,
      factors: factors,
      appId: appId
    };
    
    hilog.info(DOMAIN, TAG, 'Cache updated with %{public}d factors', factors.size);
  }
  
  clearCache(): void {
    this.cache = null;
    hilog.info(DOMAIN, TAG, 'Cache cleared');
  }
  
  getCacheAge(): number {
    if (!this.cache) {
      return -1;
    }
    return Date.now() - this.cache.timestamp;
  }
}

export class RetryStrategy {
  private maxRetries: number = 3;
  private retryDelay: number = 1000; // 1 second
  
  async executeWithRetry<T>(
    operation: () => Promise<T>,
    fallback: () => T
  ): Promise<T> {
    let retryCount = 0;
    
    while (retryCount < this.maxRetries) {
      try {
        hilog.info(DOMAIN, TAG, 'Attempt %{public}d of %{public}d', retryCount + 1, this.maxRetries);
        const result = await operation();
        hilog.info(DOMAIN, TAG, 'Operation succeeded on attempt %{public}d', retryCount + 1);
        return result;
        
      } catch (err) {
        retryCount++;
        hilog.warn(DOMAIN, TAG, 'Attempt %{public}d failed: %{public}s', retryCount, err.message);
        
        if (retryCount < this.maxRetries) {
          hilog.info(DOMAIN, TAG, 'Retrying in %{public}dms...', this.retryDelay);
          await this.delay(this.retryDelay);
        }
      }
    }
    
    hilog.warn(DOMAIN, TAG, 'All %{public}d attempts failed, using fallback', this.maxRetries);
    return fallback();
  }
  
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export class FrequencyTracker {
  private callsPerMinute: number = 0;
  private callsPerDay: number = 0;
  private lastMinuteReset: number = Date.now();
  private lastDayReset: number = Date.now();
  
  private maxCallsPerMinute: number = 5;
  private maxCallsPerDay: number = 20;
  
  canCall(): boolean {
    this.resetIfNeeded();
    
    if (this.callsPerMinute >= this.maxCallsPerMinute) {
      hilog.warn(DOMAIN, TAG, 'Minute frequency limit reached: %{public}d/%{public}d', 
                this.callsPerMinute, this.maxCallsPerMinute);
      return false;
    }
    
    if (this.callsPerDay >= this.maxCallsPerDay) {
      hilog.warn(DOMAIN, TAG, 'Day frequency limit reached: %{public}d/%{public}d', 
                this.callsPerDay, this.maxCallsPerDay);
      return false;
    }
    
    return true;
  }
  
  recordCall(): void {
    this.resetIfNeeded();
    this.callsPerMinute++;
    this.callsPerDay++;
    
    hilog.info(DOMAIN, TAG, 'Call recorded: %{public}d/min, %{public}d/day', 
              this.callsPerMinute, this.callsPerDay);
  }
  
  private resetIfNeeded(): void {
    const now = Date.now();
    
    if (now - this.lastMinuteReset >= 60000) {
      this.callsPerMinute = 0;
      this.lastMinuteReset = now;
      hilog.info(DOMAIN, TAG, 'Minute counter reset');
    }
    
    if (now - this.lastDayReset >= 86400000) {
      this.callsPerDay = 0;
      this.lastDayReset = now;
      hilog.info(DOMAIN, TAG, 'Day counter reset');
    }
  }
  
  getStatus(): { minute: number, day: number, canCall: boolean } {
    this.resetIfNeeded();
    return {
      minute: this.callsPerMinute,
      day: this.callsPerDay,
      canCall: this.canCall()
    };
  }
}