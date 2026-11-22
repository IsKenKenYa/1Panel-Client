#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstdint>
#include <mutex>
#include <thread>
#include <chrono>

class NetworkQualityMonitor {
private:
    uint32_t callbackId = 0;
    bool isRegistered = false;
    std::mutex dataMutex;
    NetworkBoost_NetworkQosArray latestQosData;
    
public:
    NetworkQualityMonitor() {
        latestQosData.pathNum = 0;
    }
    
    ~NetworkQualityMonitor() {
        if (isRegistered) {
            stopMonitoring();
        }
    }
    
    void onQoSChanged(NetworkBoost_NetworkQosArray *msg)
    {
        if (!msg) {
            printf("[ERROR] 回调数据指针为空\n");
            return;
        }
        
        if (msg->pathNum < 1 || msg->pathNum > 4) {
            printf("[ERROR] 路径数量异常: %u\n", msg->pathNum);
            return;
        }
        
        std::lock_guard<std::mutex> lock(dataMutex);
        latestQosData = *msg;
        
        printf("\n========== 网络质量回调 ==========\n");
        printf("路径数量: %u\n", msg->pathNum);
        
        for (uint32_t i = 0; i < msg->pathNum; i++) {
            NetworkBoost_NetworkQos &qos = msg->networkQos[i];
            
            const char* pathTypeName = "";
            switch (qos.pathType) {
                case NB_PATH_CELLULAR_PRIMARY:
                    pathTypeName = "蜂窝主卡";
                    break;
                case NB_PATH_CELLULAR_SECONDARY:
                    pathTypeName = "蜂窝副卡";
                    break;
                case NB_PATH_WIFI_PRIMARY:
                    pathTypeName = "主Wi-Fi";
                    break;
                case NB_PATH_WIFI_SECONDARY:
                    pathTypeName = "辅Wi-Fi";
                    break;
                default:
                    pathTypeName = "未知";
                    break;
            }
            
            printf("\n路径 %u (%s):\n", i, pathTypeName);
            printf("  上行带宽: %llu bps\n", qos.linkUpBandwidth);
            printf("  下行带宽: %llu bps\n", qos.linkDownBandwidth);
            printf("  上行速率: %llu bps (%llu B/s)\n", 
                   qos.linkUpRate, qos.linkUpRate / 8);
            printf("  下行速率: %llu bps (%llu B/s)\n", 
                   qos.linkDownRate, qos.linkDownRate / 8);
            printf("  实时速率: %llu B/s\n", 
                   (qos.linkUpRate + qos.linkDownRate) / 8);
            printf("  RTT时延: %u ms\n", qos.rttMs);
            printf("  上行缓冲时延: %u ms\n", qos.linkUpBufferDelayMs);
            printf("  缓冲占比: %u%%\n", qos.linkUpBufferCongestionPercent);
            
            uint64_t totalRate = (qos.linkUpRate + qos.linkDownRate) / 8;
            
            if (totalRate < 50000) {
                printf("  [建议] 弱网环境，建议降低码率至50KB/s以下\n");
            } else if (qos.rttMs > 200) {
                printf("  [建议] 高延迟环境，建议增加缓冲至200ms以上\n");
            } else if (qos.linkUpBufferCongestionPercent > 80) {
                printf("  [建议] 缓冲拥堵，建议暂停发包或降低速率\n");
            } else {
                printf("  [建议] 网络质量良好，可正常传输\n");
            }
        }
        printf("==================================\n\n");
    }
    
    static void callbackWrapper(NetworkBoost_NetworkQosArray *msg)
    {
        extern NetworkQualityMonitor g_monitor;
        g_monitor.onQoSChanged(msg);
    }
    
    int32_t startMonitoring()
    {
        if (isRegistered) {
            printf("[INFO] 已注册回调，回调ID: %u\n", callbackId);
            return 0;
        }
        
        printf("[INFO] 开始注册网络质量回调...\n");
        
        HMS_NetworkBoost_NetQosChange callback = callbackWrapper;
        
        int32_t ret = HMS_NetworkBoost_RegisterNetQosCallback(callback, &callbackId);
        
        if (ret == 0) {
            isRegistered = true;
            printf("[SUCCESS] 注册成功，回调ID: %u\n", callbackId);
            printf("[INFO] 系统将在网络质量变化时触发回调\n");
        } else {
            handleRegisterError(ret);
        }
        
        return ret;
    }
    
    int32_t stopMonitoring()
    {
        if (!isRegistered || callbackId == 0) {
            printf("[INFO] 未注册回调，无需取消注册\n");
            return 0;
        }
        
        printf("[INFO] 开始取消注册网络质量回调...\n");
        printf("[INFO] 当前回调ID: %u\n", callbackId);
        
        int32_t ret = HMS_NetworkBoost_UnregisterNetQosCallback(callbackId);
        
        if (ret == 0) {
            isRegistered = false;
            callbackId = 0;
            printf("[SUCCESS] 取消注册成功\n");
            printf("[INFO] 网络质量回调已停止\n");
        } else {
            handleRegisterError(ret);
        }
        
        return ret;
    }
    
    NetworkBoost_NetworkQosArray getLatestQosData()
    {
        std::lock_guard<std::mutex> lock(dataMutex);
        return latestQosData;
    }
    
    bool isMonitoring()
    {
        return isRegistered;
    }
    
private:
    void handleRegisterError(int32_t errorCode)
    {
        printf("[ERROR] 操作失败，错误码: %d\n", errorCode);
        
        switch (errorCode) {
            case 201:
                printf("[ERROR] 权限不足\n");
                printf("[SOLUTION] 请在module.json5中配置ohos.permission.GET_NETWORK_INFO权限\n");
                break;
            case 401:
                printf("[ERROR] 参数错误\n");
                printf("[SOLUTION] 请检查回调函数指针和callbackId指针是否有效\n");
                break;
            case 801:
                printf("[ERROR] 系统能力不支持\n");
                printf("[SOLUTION] 请检查设备系统版本是否>=5.1.0(18)\n");
                break;
            case 62100001:
                printf("[ERROR] 内部错误\n");
                printf("[SOLUTION] 系统内部异常，建议稍后重试或重启应用\n");
                break;
            case 62100002:
                printf("[ERROR] 系统服务操作失败\n");
                printf("[SOLUTION] 系统服务异常，建议重启应用或设备\n");
                break;
            case 62100003:
                printf("[ERROR] 注册请求达到上限\n");
                printf("[SOLUTION] 已达到最大回调注册数量，请先取消其他回调注册\n");
                break;
            default:
                printf("[ERROR] 未知错误\n");
                printf("[SOLUTION] 请检查代码逻辑或联系技术支持\n");
                break;
        }
    }
};

NetworkQualityMonitor g_monitor;

int main()
{
    printf("\n========================================\n");
    printf("Network Boost Kit - 网络质量监听示例\n");
    printf("========================================\n\n");
    
    NetworkQualityMonitor monitor;
    
    printf("[步骤1] 注册网络质量回调\n");
    int32_t ret = monitor.startMonitoring();
    
    if (ret != 0) {
        printf("[FAILED] 注册失败，程序退出\n");
        return -1;
    }
    
    printf("\n[步骤2] 监听网络质量变化 (等待30秒)\n");
    printf("[INFO] 您可以在此期间切换网络环境触发回调\n");
    printf("[INFO] 例如：开关Wi-Fi、切换蜂窝网络等\n\n");
    
    for (int i = 0; i < 30; i++) {
        if (i % 5 == 0) {
            printf("[INFO] 已监听 %d 秒...\n", i);
        }
        
        NetworkBoost_NetworkQosArray qosData = monitor.getLatestQosData();
        if (qosData.pathNum > 0) {
            printf("[INFO] 已接收到 %u 条路径的网络质量数据\n", qosData.pathNum);
        }
        
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    
    printf("\n[步骤3] 取消注册网络质量回调\n");
    ret = monitor.stopMonitoring();
    
    if (ret == 0) {
        printf("[SUCCESS] 示例执行完成\n");
    } else {
        printf("[FAILED] 取消注册失败\n");
    }
    
    printf("\n========================================\n");
    printf("示例程序结束\n");
    printf("========================================\n\n");
    
    return 0;
}