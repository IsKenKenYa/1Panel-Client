/**
 * @file example_net_connection.cpp
 * @brief Network connection management example for HarmonyOS Native development
 * 
 * This example demonstrates how to use NetConnection C APIs to:
 * - Check if device has default network connection
 * - Get default network handle
 * - Query network connection status
 * 
 * @requirements:
 * - HarmonyOS API 11+
 * - Permission: ohos.permission.GET_NETWORK_INFO
 */

#include "network/netmanager/net_connection.h"
#include <stdio.h>
#include <string.h>

class NetConnectionManager {
public:
    NetConnectionManager() {}
    ~NetConnectionManager() {}
    
    int32_t CheckNetworkConnection() {
        int32_t hasDefaultNet = 0;
        int32_t result = OH_NetConn_HasDefaultNet(&hasDefaultNet);
        
        if (result != 0) {
            printf("[Error] Check network connection failed, error code: %d\n", result);
            return result;
        }
        
        if (hasDefaultNet) {
            printf("[Info] Network is connected, device has default network\n");
        } else {
            printf("[Info] Network is not connected, no default network available\n");
        }
        
        return result;
    }
    
    int32_t GetDefaultNetwork(int32_t *netId) {
        if (netId == nullptr) {
            printf("[Error] Parameter error: netId pointer is null\n");
            return 401;
        }
        
        NetConn_NetHandle netHandle;
        memset(&netHandle, 0, sizeof(NetConn_NetHandle));
        
        int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
        
        if (result != 0) {
            printf("[Error] Get default network failed, error code: %d\n", result);
            return result;
        }
        
        *netId = netHandle.netId;
        printf("[Info] Default network ID: %d\n", *netId);
        
        return result;
    }
    
    int32_t CheckNetworkMetered(bool *isMetered) {
        if (isMetered == nullptr) {
            printf("[Error] Parameter error: isMetered pointer is null\n");
            return 401;
        }
        
        int32_t meteredFlag = 0;
        int32_t result = OH_NetConn_IsDefaultNetMetered(&meteredFlag);
        
        if (result != 0) {
            printf("[Error] Check network metered failed, error code: %d\n", result);
            return result;
        }
        
        *isMetered = (meteredFlag != 0);
        
        if (*isMetered) {
            printf("[Info] Default network is metered (traffic counted)\n");
        } else {
            printf("[Info] Default network is not metered (free traffic)\n");
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
    printf("=== HarmonyOS Network Connection Management Example ===\n\n");
    
    NetConnectionManager manager;
    
    printf("Step 1: Check network connection status\n");
    int32_t result = manager.CheckNetworkConnection();
    if (result != 0) {
        printf("Example failed at step 1\n");
        return -1;
    }
    
    printf("\nStep 2: Get default network ID\n");
    int32_t netId = -1;
    result = manager.GetDefaultNetwork(&netId);
    if (result != 0) {
        printf("Example failed at step 2\n");
        return -1;
    }
    
    printf("\nStep 3: Check if network is metered\n");
    bool isMetered = false;
    result = manager.CheckNetworkMetered(&isMetered);
    if (result != 0) {
        printf("Example failed at step 3\n");
        return -1;
    }
    
    printf("\n=== Example completed successfully ===\n");
    printf("Network ID: %d\n", netId);
    printf("Is metered: %s\n", isMetered ? "Yes" : "No");
    
    return 0;
}