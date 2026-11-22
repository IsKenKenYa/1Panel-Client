import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "UrlThreatCheck";
const DOMAIN = 0x0000;

export class UrlThreatChecker {
  private static instance: UrlThreatChecker;
  
  private constructor() {}
  
  static getInstance(): UrlThreatChecker {
    if (!UrlThreatChecker.instance) {
      UrlThreatChecker.instance = new UrlThreatChecker();
    }
    return UrlThreatChecker.instance;
  }
  
  async checkSingleUrl(url: string): Promise<safetyDetect.UrlThreatType> {
    const response = await this.checkUrls([url]);
    if (response.results.length > 0) {
      return response.results[0].threat;
    }
    throw new Error('No result returned');
  }
  
  async checkUrls(urls: string[]): Promise<safetyDetect.UrlCheckResponse> {
    if (!urls || urls.length === 0) {
      throw new Error('URL列表不能为空');
    }
    
    if (urls.length > 10) {
      throw new Error('单次请求最多检测10个URL');
    }
    
    for (const url of urls) {
      if (url.length > 4096) {
        throw new Error(`URL长度超过限制: ${url}`);
      }
      
      if (!this.isValidUrl(url)) {
        throw new Error(`URL格式无效: ${url}`);
      }
    }
    
    const req: safetyDetect.UrlCheckRequest = {
      urls: urls
    };
    
    try {
      hilog.info(DOMAIN, TAG, '开始检测URL威胁，URL数量: %{public}d', urls.length);
      
      const response: safetyDetect.UrlCheckResponse = await safetyDetect.checkUrlThreat(req);
      
      hilog.info(DOMAIN, TAG, 'URL检测完成，结果数量: %{public}d', response.results.length);
      
      return response;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'URL检测失败: %{public}d %{public}s', e.code, e.message);
      throw e;
    }
  }
  
  getThreatTypeName(threat: safetyDetect.UrlThreatType): string {
    switch (threat) {
      case safetyDetect.UrlThreatType.NORMAL:
        return '未发现威胁';
      case safetyDetect.UrlThreatType.PHISHING:
        return '钓鱼网站';
      case safetyDetect.UrlThreatType.MALWARE:
        return '恶意软件网站';
      case safetyDetect.UrlThreatType.OTHERS:
        return '其他威胁';
      default:
        return '未知威胁';
    }
  }
  
  isUrlSafe(threat: safetyDetect.UrlThreatType): boolean {
    return threat === safetyDetect.UrlThreatType.NORMAL;
  }
  
  private isValidUrl(url: string): boolean {
    try {
      const urlPattern = /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/;
      return urlPattern.test(url);
    } catch (err) {
      return false;
    }
  }
}

async function main(): Promise<void> {
  const checker = UrlThreatChecker.getInstance();
  
  try {
    const urls = [
      'https://example.com',
      'https://test.com'
    ];
    
    const response = await checker.checkUrls(urls);
    
    for (const result of response.results) {
      const threatName = checker.getThreatTypeName(result.threat);
      const isSafe = checker.isUrlSafe(result.threat);
      
      console.log(`URL: ${result.url}`);
      console.log(`威胁类型: ${threatName}`);
      console.log(`是否安全: ${isSafe ? '是' : '否'}`);
      console.log('---');
    }
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    console.error(`检测失败: ${e.code} - ${e.message}`);
  }
}

main();