import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'DNSResolve';
const DOMAIN = 0x0000;

export interface DNSResolveResult {
  hostname: string;
  addresses: string[];
  success: boolean;
  errorMessage?: string;
}

export async function resolveHostname(hostname: string): Promise<DNSResolveResult> {
  try {
    hilog.info(DOMAIN, TAG, `Resolving hostname: ${hostname}`);
    
    const addresses = await connection.getAddressesByName(hostname);
    
    if (!addresses || addresses.length === 0) {
      hilog.warn(DOMAIN, TAG, `No addresses found for ${hostname}`);
      return {
        hostname: hostname,
        addresses: [],
        success: false,
        errorMessage: 'No addresses found',
      };
    }
    
    const addressStrings = addresses.map(addr => {
      if (addr.family === 'IPv4') {
        return `${addr.address} (IPv4)`;
      } else if (addr.family === 'IPv6') {
        return `${addr.address} (IPv6)`;
      } else {
        return addr.address;
      }
    });
    
    hilog.info(DOMAIN, TAG, `Resolved addresses: ${JSON.stringify(addressStrings)}`);
    
    return {
      hostname: hostname,
      addresses: addressStrings,
      success: true,
    };
    
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Resolve failed: Code ${err.code}, Message: ${err.message}`);
    
    return {
      hostname: hostname,
      addresses: [],
      success: false,
      errorMessage: `Error ${err.code}: ${err.message}`,
    };
  }
}

export async function resolveMultipleHostnames(hostnames: string[]): Promise<DNSResolveResult[]> {
  const results: DNSResolveResult[] = [];
  
  for (const hostname of hostnames) {
    const result = await resolveHostname(hostname);
    results.push(result);
  }
  
  return results;
}

export async function resolveHostnameWithRetry(hostname: string, maxRetries: number = 3): Promise<DNSResolveResult> {
  let retries = 0;
  
  while (retries < maxRetries) {
    const result = await resolveHostname(hostname);
    
    if (result.success) {
      return result;
    }
    
    retries++;
    hilog.warn(DOMAIN, TAG, `Retry ${retries}/${maxRetries} for hostname: ${hostname}`);
    
    await delay(1000);
  }
  
  return {
    hostname: hostname,
    addresses: [],
    success: false,
    errorMessage: `Failed after ${maxRetries} retries`,
  };
}

export async function resolveCommonHostnames(): Promise<DNSResolveResult[]> {
  const commonHostnames = [
    'www.huawei.com',
    'www.baidu.com',
    'www.qq.com',
    'www.taobao.com',
  ];
  
  return resolveMultipleHostnames(commonHostnames);
}

export function isValidHostname(hostname: string): boolean {
  const hostnameRegex = /^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*$/;
  return hostnameRegex.test(hostname) && hostname.length <= 253;
}

export async function safeResolveHostname(hostname: string): Promise<DNSResolveResult> {
  if (!hostname || hostname.trim().length === 0) {
    return {
      hostname: hostname,
      addresses: [],
      success: false,
      errorMessage: 'Hostname is empty',
    };
  }
  
  const trimmedHostname = hostname.trim();
  
  if (!isValidHostname(trimmedHostname)) {
    return {
      hostname: hostname,
      addresses: [],
      success: false,
      errorMessage: 'Invalid hostname format',
    };
  }
  
  return resolveHostname(trimmedHostname);
}

function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}