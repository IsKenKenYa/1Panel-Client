#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstring>

uint32_t g_callbackId = 0;
bool g_isRegistered = false;

void onNetworkSceneChanged(NetworkBoost_NetworkScene* ns) {
    if (ns == nullptr) {
        printf("[ERROR] Callback received null pointer\n");
        return;
    }
    
    printf("\n========== Network Scene Changed ==========\n");
    
    printf("Path Type: ");
    switch (ns->pathType) {
        case NB_PATH_CELLULAR_PRIMARY:
            printf("Cellular Primary (主蜂窝)\n");
            break;
        case NB_PATH_CELLULAR_SECONDARY:
            printf("Cellular Secondary (副蜂窝)\n");
            break;
        case NB_PATH_WIFI_PRIMARY:
            printf("WiFi Primary (主WiFi)\n");
            break;
        case NB_PATH_WIFI_SECONDARY:
            printf("WiFi Secondary (辅WiFi)\n");
            break;
        default:
            printf("Unknown (%d)\n", ns->pathType);
            break;
    }
    
    printf("Scene Type: ");
    switch (ns->scene) {
        case NB_SCENE_NORMAL:
            printf("Normal (正常场景)\n");
            printf("Recommendation: Maintain current strategy\n");
            break;
        case NB_SCENE_CONGESTION:
            printf("Congestion (拥塞场景)\n");
            printf("Recommendation: Reduce bitrate and framerate\n");
            break;
        case NB_SCENE_FREQUENT_HANDOVER:
            printf("Frequent Handover (频繁切换场景)\n");
            printf("Recommendation: Increase buffer and error resilience\n");
            break;
        case NB_SCENE_WEAK_SIGNAL:
            printf("Weak Signal (弱信号场景)\n");
            printf("Recommendation: Pause or significantly reduce data\n");
            break;
        default:
            printf("Unknown (%d)\n", ns->scene);
            break;
    }
    
    printf("Recommended Action: ");
    switch (ns->recommendedAction) {
        case NB_ACTION_DO_CACHING:
            printf("Do Caching (建议缓存)\n");
            break;
        case NB_ACTION_SUSPEND_DATA:
            printf("Suspend Data (建议暂停发包)\n");
            break;
        case NB_ACTION_DECREASE_DATA:
            printf("Decrease Data (建议降低发包速率)\n");
            break;
        case NB_ACTION_INCREASE_DATA:
            printf("Increase Data (建议增加发包速率)\n");
            break;
        case NB_ACTION_KEEP_DATA:
            printf("Keep Data (建议保持当前速率)\n");
            break;
        default:
            printf("Unknown (%d)\n", ns->recommendedAction);
            break;
    }
    
    printf("Weak Signal Prediction:\n");
    if (ns->weakSignalPrediction.isLastPredictionValid) {
        printf("  - Valid: Yes\n");
        printf("  - Start Time: %u seconds (预计%u秒后进入弱信号)\n", 
               ns->weakSignalPrediction.startTime, ns->weakSignalPrediction.startTime);
        printf("  - Duration: %u seconds (预计停留%u秒)\n",
               ns->weakSignalPrediction.duration, ns->weakSignalPrediction.duration);
        
        if (ns->weakSignalPrediction.startTime <= 5) {
            printf("  - WARNING: Weak signal approaching soon, adjust strategy NOW!\n");
        }
        if (ns->weakSignalPrediction.duration > 60) {
            printf("  - INFO: Long weak signal period, consider pausing service\n");
        }
    } else {
        printf("  - Valid: No (无有效预测)\n");
    }
    
    printf("==========================================\n\n");
}

int32_t RegisterNetSceneCallback() {
    if (g_isRegistered) {
        printf("[WARN] Already registered with callback ID: %u\n", g_callbackId);
        printf("[INFO] Please unregister first before registering again\n");
        return -1;
    }
    
    if (g_callbackId != 0) {
        printf("[WARN] Callback ID is not zero, potential inconsistency\n");
        g_callbackId = 0;
    }
    
    HMS_NetworkBoost_NetSceneChange callback = onNetworkSceneChanged;
    
    printf("[INFO] Registering network scene callback...\n");
    int32_t ret = HMS_NetworkBoost_RegisterNetSceneCallback(callback, &g_callbackId);
    
    if (ret == 0) {
        g_isRegistered = true;
        printf("[SUCCESS] Callback registered successfully\n");
        printf("[INFO] Assigned callback ID: %u\n", g_callbackId);
        printf("[INFO] Now monitoring network scene changes...\n");
    } else {
        printf("[FAILED] Registration failed with error code: %d\n", ret);
        g_callbackId = 0;
        
        switch (ret) {
            case 201:
                printf("[ERROR] Permission denied\n");
                printf("[SOLUTION] Check module.json5 for ohos.permission.GET_NETWORK_INFO\n");
                break;
            case 401:
                printf("[ERROR] Invalid parameter\n");
                printf("[SOLUTION] Check callback function and callbackId pointer\n");
                break;
            case 801:
                printf("[ERROR] System capability not supported\n");
                printf("[SOLUTION] Device may not support NetworkBoost capability\n");
                break;
            case 62100001:
                printf("[ERROR] Internal error\n");
                printf("[SOLUTION] Retry later or contact support\n");
                break;
            case 62100002:
                printf("[ERROR] System service operation failed\n");
                printf("[SOLUTION] Network management service may be abnormal\n");
                break;
            case 62100003:
                printf("[ERROR] Registration limit reached\n");
                printf("[SOLUTION] Unregister other callbacks first\n");
                break;
            default:
                printf("[ERROR] Unknown error code: %d\n", ret);
                break;
        }
    }
    
    return ret;
}

int32_t UnregisterNetSceneCallback() {
    if (!g_isRegistered) {
        printf("[WARN] Not registered, no need to unregister\n");
        return 0;
    }
    
    if (g_callbackId == 0) {
        printf("[WARN] Callback ID is zero, cannot unregister\n");
        g_isRegistered = false;
        return -1;
    }
    
    printf("[INFO] Unregistering network scene callback (ID: %u)...\n", g_callbackId);
    int32_t ret = HMS_NetworkBoost_UnregisterNetSceneCallback(g_callbackId);
    
    if (ret == 0) {
        g_isRegistered = false;
        g_callbackId = 0;
        printf("[SUCCESS] Callback unregistered successfully\n");
        printf("[INFO] No longer monitoring network scene changes\n");
    } else {
        printf("[FAILED] Unregistration failed with error code: %d\n", ret);
        
        switch (ret) {
            case 201:
                printf("[ERROR] Permission denied\n");
                break;
            case 401:
                printf("[ERROR] Invalid callback ID\n");
                break;
            case 801:
                printf("[ERROR] System capability not supported\n");
                break;
            case 62100001:
                printf("[ERROR] Internal error\n");
                break;
            case 62100002:
                printf("[ERROR] System service operation failed\n");
                break;
            default:
                printf("[ERROR] Unknown error code: %d\n", ret);
                break;
        }
    }
    
    return ret;
}

class VideoPlayer {
public:
    void adjustStrategy(NetworkBoost_Scene scene, NetworkBoost_RecommendedAction action) {
        printf("[VideoPlayer] Adjusting strategy based on network scene...\n");
        
        switch (scene) {
            case NB_SCENE_NORMAL:
                setBitrate(2000);
                setFrameRate(30);
                setBufferDuration(2);
                printf("[VideoPlayer] Normal scene: High quality playback\n");
                break;
            
            case NB_SCENE_CONGESTION:
                setBitrate(800);
                setFrameRate(15);
                setBufferDuration(5);
                printf("[VideoPlayer] Congestion: Reduced quality to maintain playback\n");
                break;
            
            case NB_SCENE_FREQUENT_HANDOVER:
                setBitrate(1200);
                setFrameRate(20);
                setBufferDuration(8);
                enableErrorResilience(true);
                printf("[VideoPlayer] Frequent handover: Increased buffer and error resilience\n");
                break;
            
            case NB_SCENE_WEAK_SIGNAL:
                if (action == NB_ACTION_SUSPEND_DATA) {
                    pausePlayback();
                    showNetworkWarning("网络信号弱，已暂停播放");
                    printf("[VideoPlayer] Weak signal: Playback paused\n");
                } else {
                    setBitrate(400);
                    setFrameRate(10);
                    setBufferDuration(10);
                    printf("[VideoPlayer] Weak signal: Minimal quality playback\n");
                }
                break;
            
            default:
                printf("[VideoPlayer] Unknown scene: Using default strategy\n");
                break;
        }
    }
    
private:
    void setBitrate(int kbps) {
        printf("[VideoPlayer] Setting bitrate: %d kbps\n", kbps);
    }
    
    void setFrameRate(int fps) {
        printf("[VideoPlayer] Setting frame rate: %d fps\n", fps);
    }
    
    void setBufferDuration(int seconds) {
        printf("[VideoPlayer] Setting buffer duration: %d seconds\n", seconds);
    }
    
    void enableErrorResilience(bool enable) {
        printf("[VideoPlayer] Error resilience: %s\n", enable ? "Enabled" : "Disabled");
    }
    
    void pausePlayback() {
        printf("[VideoPlayer] Playback paused\n");
    }
    
    void showNetworkWarning(const char* message) {
        printf("[VideoPlayer] Warning shown: %s\n", message);
    }
};

VideoPlayer g_videoPlayer;

void onNetworkSceneChangedForVideo(NetworkBoost_NetworkScene* ns) {
    if (ns == nullptr) {
        printf("[ERROR] Null pointer in video callback\n");
        return;
    }
    
    g_videoPlayer.adjustStrategy(ns->scene, ns->recommendedAction);
}

int32_t main() {
    printf("\n========================================\n");
    printf("Network Boost Scene Callback Demo\n");
    printf("========================================\n\n");
    
    int32_t ret = RegisterNetSceneCallback();
    if (ret != 0) {
        printf("[FATAL] Failed to initialize network scene monitoring\n");
        printf("[INFO] Application may not function properly without network awareness\n");
        return ret;
    }
    
    printf("\n[INFO] Application is running...\n");
    printf("[INFO] Network scene changes will be detected and reported\n");
    printf("[INFO] Press Ctrl+C to stop\n\n");
    
    while (true) {
        printf("[INFO] Waiting for network scene changes...\n");
        break;
    }
    
    printf("\n[INFO] Application is shutting down...\n");
    UnregisterNetSceneCallback();
    
    printf("\n========================================\n");
    printf("Demo completed\n");
    printf("========================================\n");
    
    return 0;
}