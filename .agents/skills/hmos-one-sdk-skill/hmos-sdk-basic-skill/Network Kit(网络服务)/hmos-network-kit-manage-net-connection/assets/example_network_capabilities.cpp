/**
 * @file example_network_capabilities.cpp
 * @brief Network capabilities query example for HarmonyOS Native development
 * 
 * This example demonstrates how to use NetConnection C APIs to:
 * - Get network connection properties
 * - Query network capabilities
 * - Get HTTP proxy configuration
 * 
 * @requirements:
 * - HarmonyOS API 11+
 * - Permission: ohos.permission.GET_NETWORK_INFO
 */

#include "network/netmanager/net_connection.h"
#include <stdio.h>
#include <string.h>

class NetworkCapabilitiesManager {
public:
    NetworkCapabilitiesManager() {}
    ~NetworkCapabilitiesManager() {}
    
    int32_t GetConnectionProperties(int32_t netId) {
        NetConn_NetHandle netHandle;
        netHandle.netId = netId;
        
        NetConn_ConnectionProperties properties;
        memset(&properties, 0, sizeof(NetConn_ConnectionProperties));
        
        int32_t result = OH_NetConn_GetConnectionProperties(&netHandle, &properties);
        
        if (result != 0) {
            printf("[Error] Get connection properties failed, error code: %d\n", result);
            return result;
        }
        
        printf("[Info] Connection properties:\n");
        if (properties.domainName != nullptr) {
            printf("  Domain name: %s\n", properties.domainName);
        }
        
        return result;
    }
    
    int32_t GetNetworkCapabilities(int32_t netId) {
        NetConn_NetHandle netHandle;
        netHandle.netId = netId;
        
        NetConn_NetCapabilities capabilities;
        memset(&capabilities, 0, sizeof(NetConn_NetCapabilities));
        
        int32_t result = OH_NetConn_GetNetCapabilities(&netHandle, &capabilities);
        
        if (result != 0) {
            printf("[Error] Get network capabilities failed, error code: %d\n", result);
            return result;
        }
        
        printf("[Info] Network capabilities:\n");
        printf("  Link up bandwidth: %u Kbps\n", capabilities.linkUpBandwidthKbps);
        printf("  Link down bandwidth: %u Kbps\n", capabilities.linkDownBandwidthKbps);
        
        return result;
    }
    
    int32_t GetDefaultHttpProxy() {
        NetConn_HttpProxy httpProxy;
        memset(&httpProxy, 0, sizeof(NetConn_HttpProxy));
        
        int32_t result = OH_NetConn_GetDefaultHttpProxy(&httpProxy);
        
        if (result != 0) {
            printf("[Error] Get default HTTP proxy failed, error code: %d\n", result);
            return result;
        }
        
        printf("[Info] HTTP proxy configuration:\n");
        if (httpProxy.host != nullptr && strlen(httpProxy.host) > 0) {
            printf("  Proxy host: %s\n", httpProxy.host);
            printf("  Proxy port: %d\n", httpProxy.port);
            
            if (httpProxy.exclusionList != nullptr) {
                printf("  Exclusion list configured\n");
            }
        } else {
            printf("  No proxy configured\n");
        }
        
        return result;
    }
    
    int32_t GetAllActiveNetworks() {
        NetConn_NetHandleList netHandleList;
        memset(&netHandleList, 0, sizeof(NetConn_NetHandleList));
        
        int32_t result = OH_NetConn_GetAllNets(&netHandleList);
        
        if (result != 0) {
            printf("[Error] Get all active networks failed, error code: %d\n", result);
            return result;
        }
        
        printf("[Info] All active networks:\n");
        printf("  Network count: %d\n", netHandleList.netHandleListSize);
        
        if (netHandleList.netHandles != nullptr) {
            for (uint32_t i = 0; i < netHandleList.netHandleListSize; i++) {
                printf("  Network %d: netId=%d\n", i + 1, netHandleList.netHandles[i].netId);
            }
        }
        
        return result;
    }
    
private:
    const char* GetErrorMessage(int32_t errorCode) {
        switch (errorCode) {
            case 0:
                return "Success";
            case 201:
                return "Permission denied";
            case 401:
                return "Parameter error";
            case 2100002:
                return "Service unavailable";
            case 2100003:
                return "Internal error";
            default:
                return "Unknown error";
        }
    }
};

int main() {
    printf("=== HarmonyOS Network Capabilities Query Example ===\n\n");
    
    NetworkCapabilitiesManager manager;
    
    printf("Step 1: Get default network\n");
    NetConn_NetHandle defaultNetHandle;
    int32_t result = OH_NetConn_GetDefaultNet(&defaultNetHandle);
    if (result != 0) {
        printf("[Error] Failed to get default network\n");
        return -1;
    }
    printf("[Info] Default network ID: %d\n", defaultNetHandle.netId);
    
    printf("\nStep 2: Get connection properties\n");
    result = manager.GetConnectionProperties(defaultNetHandle.netId);
    if (result != 0) {
        printf("Warning: Failed to get connection properties\n");
    }
    
    printf("\nStep 3: Get network capabilities\n");
    result = manager.GetNetworkCapabilities(defaultNetHandle.netId);
    if (result != 0) {
        printf("Warning: Failed to get network capabilities\n");
    }
    
    printf("\nStep 4: Get HTTP proxy configuration\n");
    result = manager.GetDefaultHttpProxy();
    if (result != 0) {
        printf("Warning: Failed to get HTTP proxy\n");
    }
    
    printf("\nStep 5: Get all active networks\n");
    result = manager.GetAllActiveNetworks();
    if (result != 0) {
        printf("Warning: Failed to get all active networks\n");
    }
    
    printf("\n=== Example completed ===\n");
    return 0;
}