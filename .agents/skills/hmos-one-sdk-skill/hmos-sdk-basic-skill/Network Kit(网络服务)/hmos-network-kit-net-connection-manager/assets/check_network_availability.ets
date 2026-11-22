import { connection } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CheckNetworkAvailability';
const DOMAIN = 0x0000;

export enum NetworkStatus {
  NO_NETWORK = 'no_network',
  CHECKING = 'checking',
  VALIDATED = 'validated',
  NOT_VALIDATED = 'not_validated',
}

export interface NetworkCheckResult {
  status: NetworkStatus;
  netId: number;
  bearerType: string;
  canAccessInternet: boolean;
  message: string;
}

export function checkNetworkAvailabilitySync(): NetworkCheckResult {
  try {
    const netHandle = connection.getDefaultNetSync();
    
    if (!netHandle || netHandle.netId === 0) {
      return {
        status: NetworkStatus.NO_NETWORK,
        netId: 0,
        bearerType: '',
        canAccessInternet: false,
        message: 'No default network available',
      };
    }
    
    hilog.info(DOMAIN, TAG, `Default network NetId: ${netHandle.netId}`);
    
    const netCapabilities = connection.getNetCapabilitiesSync(netHandle);
    const cap = netCapabilities.networkCap;
    
    hilog.info(DOMAIN, TAG, `Network capabilities: ${JSON.stringify(netCapabilities)}`);
    
    const bearerType = getBearerType(netCapabilities.bearerTypes);
    
    if (cap && cap.includes(connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY)) {
      return {
        status: NetworkStatus.CHECKING,
        netId: netHandle.netId,
        bearerType: bearerType,
        canAccessInternet: false,
        message: 'Network is checking connectivity, please retry later',
      };
    }
    
    const isValidated = cap && cap.includes(connection.NetCap.NET_CAPABILITY_VALIDATED);
    
    return {
      status: isValidated ? NetworkStatus.VALIDATED : NetworkStatus.NOT_VALIDATED,
      netId: netHandle.netId,
      bearerType: bearerType,
      canAccessInternet: isValidated,
      message: isValidated 
        ? 'Network is validated, can access internet' 
        : 'Network is not validated, cannot access internet',
    };
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Check failed: ${JSON.stringify(error)}`);
    return {
      status: NetworkStatus.NO_NETWORK,
      netId: 0,
      bearerType: '',
      canAccessInternet: false,
      message: `Error: ${JSON.stringify(error)}`,
    };
  }
}

export async function checkNetworkAvailabilityAsync(): Promise<NetworkCheckResult> {
  try {
    const netHandle = await connection.getDefaultNet();
    
    if (netHandle.netId === 0) {
      return {
        status: NetworkStatus.NO_NETWORK,
        netId: 0,
        bearerType: '',
        canAccessInternet: false,
        message: 'No default network available',
      };
    }
    
    hilog.info(DOMAIN, TAG, `Default network NetId: ${netHandle.netId}`);
    
    const netCapabilities = await connection.getNetCapabilities(netHandle);
    const cap = netCapabilities.networkCap;
    
    const bearerType = getBearerType(netCapabilities.bearerTypes);
    
    if (cap && cap.includes(connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY)) {
      return {
        status: NetworkStatus.CHECKING,
        netId: netHandle.netId,
        bearerType: bearerType,
        canAccessInternet: false,
        message: 'Network is checking connectivity, please retry later',
      };
    }
    
    const isValidated = cap && cap.includes(connection.NetCap.NET_CAPABILITY_VALIDATED);
    
    return {
      status: isValidated ? NetworkStatus.VALIDATED : NetworkStatus.NOT_VALIDATED,
      netId: netHandle.netId,
      bearerType: bearerType,
      canAccessInternet: isValidated,
      message: isValidated 
        ? 'Network is validated, can access internet' 
        : 'Network is not validated, cannot access internet',
    };
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Check failed: ${JSON.stringify(error)}`);
    return {
      status: NetworkStatus.NO_NETWORK,
      netId: 0,
      bearerType: '',
      canAccessInternet: false,
      message: `Error: ${JSON.stringify(error)}`,
    };
  }
}

export function hasDefaultNetworkSync(): boolean {
  try {
    return connection.hasDefaultNetSync();
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Check has default net failed: ${JSON.stringify(error)}`);
    return false;
  }
}

export async function hasDefaultNetworkAsync(): Promise<boolean> {
  try {
    return await connection.hasDefaultNet();
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Check has default net failed: ${JSON.stringify(error)}`);
    return false;
  }
}

export function isNetworkMeteredSync(): boolean {
  try {
    return connection.isDefaultNetMeteredSync();
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Check metered failed: ${JSON.stringify(error)}`);
    return true;
  }
}

export async function isNetworkMeteredAsync(): Promise<boolean> {
  try {
    return await connection.isDefaultNetMetered();
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Check metered failed: ${JSON.stringify(error)}`);
    return true;
  }
}

function getBearerType(bearerTypes: number[]): string {
  for (const type of bearerTypes) {
    if (type === connection.NetBearType.BEARER_CELLULAR) return 'Cellular';
    if (type === connection.NetBearType.BEARER_WIFI) return 'WiFi';
    if (type === connection.NetBearType.BEARER_ETHERNET) return 'Ethernet';
    if (type === connection.NetBearType.BEARER_BLUETOOTH) return 'Bluetooth';
  }
  return 'Unknown';
}