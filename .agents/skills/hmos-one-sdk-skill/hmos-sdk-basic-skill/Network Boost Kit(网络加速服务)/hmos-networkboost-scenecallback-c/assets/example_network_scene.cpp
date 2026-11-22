#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstdint>
#include <thread>
#include <chrono>

static uint32_t g_callbackId = 0;
static bool g_isRunning = true;

void onNetworkSceneChanged(NetworkBoost_NetworkScene* ns)
{
    if (ns == nullptr) {
        printf("[ERROR] Callback parameter is NULL\n");
        return;
    }

    printf("\n=== Network Scene Changed ===\n");
    
    printf("Path Type: ");
    switch (ns->pathType) {
        case NB_PATH_CELLULAR_PRIMARY:
            printf("Cellular Primary\n");
            break;
        case NB_PATH_CELLULAR_SECONDARY:
            printf("Cellular Secondary\n");
            break;
        case NB_PATH_WIFI_PRIMARY:
            printf("WiFi Primary\n");
            break;
        case NB_PATH_WIFI_SECONDARY:
            printf("WiFi Secondary\n");
            break;
        default:
            printf("Unknown (%d)\n", ns->pathType);
            break;
    }

    printf("Scene Type: ");
    switch (ns->scene) {
        case NB_SCENE_NORMAL:
            printf("Normal - Network quality is good\n");
            break;
        case NB_SCENE_CONGESTION:
            printf("Congestion - Network is congested\n");
            break;
        case NB_SCENE_FREQUENT_HANDOVER:
            printf("Frequent Handover - Cell switching frequently\n");
            break;
        case NB_SCENE_WEAK_SIGNAL:
            printf("Weak Signal - Weak network signal detected\n");
            break;
        default:
            printf("Unknown (%d)\n", ns->scene);
            break;
    }

    printf("Recommended Action: ");
    switch (ns->recommendedAction) {
        case NB_ACTION_DO_CACHING:
            printf("Do Caching - Pre-cache data\n");
            break;
        case NB_ACTION_SUSPEND_DATA:
            printf("Suspend Data - Stop sending data\n");
            break;
        case NB_ACTION_DECREASE_DATA:
            printf("Decrease Data - Reduce sending rate\n");
            break;
        case NB_ACTION_INCREASE_DATA:
            printf("Increase Data - Increase sending rate\n");
            break;
        case NB_ACTION_KEEP_DATA:
            printf("Keep Data - Maintain current rate\n");
            break;
        default:
            printf("Unknown (%d)\n", ns->recommendedAction);
            break;
    }

    if (ns->weakSignalPrediction.isLastPredictionValid) {
        printf("\n--- Weak Signal Prediction ---\n");
        printf("Start Time: %u seconds\n", ns->weakSignalPrediction.startTime);
        printf("Duration: %u seconds\n", ns->weakSignalPrediction.duration);
        
        if (ns->weakSignalPrediction.duration > 0) {
            printf("Prediction: Will enter weak signal area in %u seconds, lasting %u seconds\n",
                   ns->weakSignalPrediction.startTime, 
                   ns->weakSignalPrediction.duration);
            printf("Suggestion: Prepare caching strategy or adjust bitrate\n");
        } else {
            printf("Warning: Duration is 0, prediction invalid\n");
        }
    } else {
        printf("\nWeak Signal Prediction: Not valid or expired\n");
    }

    printf("==============================\n\n");
}

int32_t registerCallback()
{
    printf("[INFO] Registering network scene callback...\n");
    
    HMS_NetworkBoost_NetSceneChange callback = onNetworkSceneChanged;
    
    int32_t ret = HMS_NetworkBoost_RegisterNetSceneCallback(callback, &g_callbackId);
    
    if (ret == 0) {
        printf("[SUCCESS] Callback registered successfully, ID: %u\n", g_callbackId);
        return 0;
    }
    
    printf("[ERROR] Registration failed with error code: %d\n", ret);
    
    switch (ret) {
        case 201:
            printf("[ERROR] Permission denied - Check GET_NETWORK_INFO permission\n");
            break;
        case 401:
            printf("[ERROR] Invalid parameter - Check callback function and callbackId pointer\n");
            break;
        case 801:
            printf("[ERROR] System capability not supported - Requires SDK 5.1.0(18)+\n");
            break;
        case 62100001:
            printf("[ERROR] Internal error - Try again later\n");
            break;
        case 62100002:
            printf("[ERROR] System service failed - Check system service status\n");
            break;
        case 62100003:
            printf("[ERROR] Registration limit reached - Unregister unused callbacks first\n");
            break;
        default:
            printf("[ERROR] Unknown error code: %d\n", ret);
            break;
    }
    
    return ret;
}

int32_t unregisterCallback()
{
    if (g_callbackId == 0) {
        printf("[WARNING] Callback ID is 0, may not registered or already unregistered\n");
        return -1;
    }
    
    printf("[INFO] Unregistering network scene callback, ID: %u...\n", g_callbackId);
    
    int32_t ret = HMS_NetworkBoost_UnregisterNetSceneCallback(g_callbackId);
    
    if (ret == 0) {
        printf("[SUCCESS] Callback unregistered successfully\n");
        g_callbackId = 0;
        return 0;
    }
    
    printf("[ERROR] Unregistration failed with error code: %d\n", ret);
    
    switch (ret) {
        case 201:
            printf("[ERROR] Permission denied\n");
            break;
        case 401:
            printf("[ERROR] Invalid parameter - Invalid callback ID\n");
            break;
        case 801:
            printf("[ERROR] System capability not supported\n");
            break;
        case 62100001:
            printf("[ERROR] Internal error\n");
            break;
        case 62100002:
            printf("[ERROR] System service failed\n");
            break;
        default:
            printf("[ERROR] Unknown error code: %d\n", ret);
            break;
    }
    
    return ret;
}

void simulateNetworkScenario()
{
    printf("\n[INFO] Simulating network scenario changes...\n");
    printf("[INFO] Switch network or change network quality to trigger callbacks\n");
    printf("[INFO] Press Ctrl+C to stop monitoring\n\n");
    
    while (g_isRunning) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}

int main()
{
    printf("\n========================================\n");
    printf("Network Boost - Scene Callback Demo\n");
    printf("========================================\n\n");
    
    int32_t ret = registerCallback();
    if (ret != 0) {
        printf("[FATAL] Failed to register callback, exiting...\n");
        return ret;
    }
    
    simulateNetworkScenario();
    
    ret = unregisterCallback();
    if (ret != 0) {
        printf("[WARNING] Failed to unregister callback, may cause resource leak\n");
    }
    
    printf("\n[INFO] Demo completed\n");
    printf("========================================\n");
    
    return 0;
}