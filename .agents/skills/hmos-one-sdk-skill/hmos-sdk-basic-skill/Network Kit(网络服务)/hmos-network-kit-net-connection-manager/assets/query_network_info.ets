import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'QueryNetworkInfo';
const DOMAIN = 0x0000;

export interface NetworkInfo {
  netId: number;
  bearerType: string;
  capabilities: string[];
  isMetered: boolean;
  interfaceName: string;
  linkAddresses: string[];
  dnsAddresses: string[];
}

export async function queryDefaultNetworkInfo(): Promise<NetworkInfo | null> {
  try {
    const netHandle = await connection.getDefaultNet();
    
    if (netHandle.netId === 0) {
      hilog.info(DOMAIN, TAG, 'No default network available');
      return null;
    }
    
    hilog.info(DOMAIN, TAG, `Default network NetId: ${netHandle.netId}`);
    
    const capabilities = await connection.getNetCapabilities(netHandle);
    const properties = await connection.getConnectionProperties(netHandle);
    
    const bearerType = getBearerTypeString(capabilities.bearerTypes);
    const capStrings = getCapabilitiesStrings(capabilities.networkCap);
    
    const networkInfo: NetworkInfo = {
      netId: netHandle.netId,
      bearerType: bearerType,
      capabilities: capStrings,
      isMetered: !capStrings.includes('NOT_METERED'),
      interfaceName: properties.interfaceName || '',
      linkAddresses: properties.linkAddresses?.map(addr => `${addr.address}/${addr.prefixLength}`) || [],
      dnsAddresses: properties.dnsAddresses?.map(addr => addr.address) || [],
    };
    
    hilog.info(DOMAIN, TAG, `Network info: ${JSON.stringify(networkInfo)}`);
    return networkInfo;
    
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Query failed: Code ${err.code}, Message: ${err.message}`);
    return null;
  }
}

export async function queryAllNetworksInfo(): Promise<NetworkInfo[]> {
  try {
    const netHandles = await connection.getAllNets();
    
    if (!netHandles || netHandles.length === 0) {
      hilog.info(DOMAIN, TAG, 'No active networks');
      return [];
    }
    
    hilog.info(DOMAIN, TAG, `Found ${netHandles.length} active networks`);
    
    const networkInfos: NetworkInfo[] = [];
    
    for (const netHandle of netHandles) {
      try {
        const capabilities = await connection.getNetCapabilities(netHandle);
        const properties = await connection.getConnectionProperties(netHandle);
        
        const bearerType = getBearerTypeString(capabilities.bearerTypes);
        const capStrings = getCapabilitiesStrings(capabilities.networkCap);
        
        networkInfos.push({
          netId: netHandle.netId,
          bearerType: bearerType,
          capabilities: capStrings,
          isMetered: !capStrings.includes('NOT_METERED'),
          interfaceName: properties.interfaceName || '',
          linkAddresses: properties.linkAddresses?.map(addr => `${addr.address}/${addr.prefixLength}`) || [],
          dnsAddresses: properties.dnsAddresses?.map(addr => addr.address) || [],
        });
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Failed to query NetId ${netHandle.netId}`);
      }
    }
    
    return networkInfos;
    
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Get all nets failed: Code ${err.code}, Message: ${err.message}`);
    return [];
  }
}

export function queryDefaultNetworkInfoSync(): NetworkInfo | null {
  try {
    const netHandle = connection.getDefaultNetSync();
    
    if (!netHandle || netHandle.netId === 0) {
      hilog.info(DOMAIN, TAG, 'No default network available');
      return null;
    }
    
    const capabilities = connection.getNetCapabilitiesSync(netHandle);
    const properties = connection.getConnectionPropertiesSync(netHandle);
    
    const bearerType = getBearerTypeString(capabilities.bearerTypes);
    const capStrings = getCapabilitiesStrings(capabilities.networkCap);
    
    return {
      netId: netHandle.netId,
      bearerType: bearerType,
      capabilities: capStrings,
      isMetered: !capStrings.includes('NOT_METERED'),
      interfaceName: properties.interfaceName || '',
      linkAddresses: properties.linkAddresses?.map(addr => `${addr.address}/${addr.prefixLength}`) || [],
      dnsAddresses: properties.dnsAddresses?.map(addr => addr.address) || [],
    };
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Query sync failed: ${JSON.stringify(error)}`);
    return null;
  }
}

function getBearerTypeString(bearerTypes: number[]): string {
  const types: string[] = [];
  
  for (const type of bearerTypes) {
    switch (type) {
      case connection.NetBearType.BEARER_CELLULAR:
        types.push('Cellular');
        break;
      case connection.NetBearType.BEARER_WIFI:
        types.push('WiFi');
        break;
      case connection.NetBearType.BEARER_BLUETOOTH:
        types.push('Bluetooth');
        break;
      case connection.NetBearType.BEARER_ETHERNET:
        types.push('Ethernet');
        break;
      default:
        types.push(`Unknown(${type})`);
    }
  }
  
  return types.join(', ');
}

function getCapabilitiesStrings(networkCap: number[]): string[] {
  const caps: string[] = [];
  
  for (const cap of networkCap) {
    switch (cap) {
      case connection.NetCap.NET_CAPABILITY_MMS:
        caps.push('MMS');
        break;
      case connection.NetCap.NET_CAPABILITY_NOT_METERED:
        caps.push('NOT_METERED');
        break;
      case connection.NetCap.NET_CAPABILITY_INTERNET:
        caps.push('INTERNET');
        break;
      case connection.NetCap.NET_CAPABILITY_NOT_VPN:
        caps.push('NOT_VPN');
        break;
      case connection.NetCap.NET_CAPABILITY_VALIDATED:
        caps.push('VALIDATED');
        break;
      case connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY:
        caps.push('CHECKING_CONNECTIVITY');
        break;
      default:
        caps.push(`Unknown(${cap})`);
    }
  }
  
  return caps;
}