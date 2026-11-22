/**
 * 应用传输体验反馈完整示例
 * 
 * 本示例演示如何使用HMS_NetworkBoost_ReportQoe API上报应用传输体验信息
 * 包含多种业务场景的上报示例和完整的错误处理
 */

#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstring>
#include <ctime>

// 上报结果结构体
struct ReportResult {
    int32_t errorCode;
    const char* message;
    const char* suggestion;
};

// 错误码映射表
const ReportResult ERROR_MAP[] = {
    {0, "上报成功", "系统已收到反馈"},
    {201, "权限不足", "请在module.json5中添加ohos.permission.GET_NETWORK_INFO权限"},
    {401, "参数错误", "请检查serviceType和qoeType是否为有效枚举值"},
    {801, "系统能力不支持", "请升级系统至API 5.1.0(18)及以上"},
    {62100001, "内部错误", "系统服务异常，稍后重试"},
    {62100002, "系统服务操作失败", "请检查网络状态并重试"}
};

/**
 * 获取错误信息
 */
const ReportResult* GetErrorInfo(int32_t errorCode) {
    for (size_t i = 0; i < sizeof(ERROR_MAP) / sizeof(ERROR_MAP[0]); i++) {
        if (ERROR_MAP[i].errorCode == errorCode) {
            return &ERROR_MAP[i];
        }
    }
    return nullptr;
}

/**
 * 参数校验
 */
bool ValidateParams(NetworkBoost_ServiceType serviceType, NetworkBoost_QoeType qoeType) {
    if (serviceType < NB_SERVICE_DEFAULT || serviceType > NB_SERVICE_SHOPPING) {
        printf("[ERROR] serviceType参数超出范围: %d (有效范围: 0-23)\n", serviceType);
        return false;
    }
    
    if (qoeType < NB_QOE_GOOD || qoeType > NB_QOE_BAD_HIGH_LATENCY) {
        printf("[ERROR] qoeType参数超出范围: %d (有效范围: 0-7)\n", qoeType);
        return false;
    }
    
    return true;
}

/**
 * 核心上报函数
 */
int32_t ReportQoe(NetworkBoost_ServiceType serviceType, NetworkBoost_QoeType qoeType) {
    // 参数校验
    if (!ValidateParams(serviceType, qoeType)) {
        return 401;
    }
    
    // 获取当前时间戳
    time_t now = time(nullptr);
    char timestamp[64];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", localtime(&now));
    
    printf("[INFO] %s - 开始上报传输体验: serviceType=%d, qoeType=%d\n", 
           timestamp, serviceType, qoeType);
    
    // 调用API
    int32_t ret = HMS_NetworkBoost_ReportQoe(serviceType, qoeType);
    
    // 处理返回结果
    const ReportResult* errorInfo = GetErrorInfo(ret);
    if (errorInfo) {
        printf("[RESULT] %s: %s\n", errorInfo->message, errorInfo->suggestion);
    } else {
        printf("[RESULT] 未知错误码: %d\n", ret);
    }
    
    return ret;
}

/**
 * 短视频播放卡顿上报示例
 */
void Example1_VideoPlaybackStutter() {
    printf("\n========== 示例1: 短视频播放卡顿上报 ==========\n");
    
    // 场景：短视频播放过程中出现卡顿，可能是服务器异常
    NetworkBoost_ServiceType serviceType = NB_SERVICE_SHORT_VIDEO;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_SERVER_ERROR;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret == 0) {
        printf("[SUCCESS] 系统已启用网络加速，卡顿情况将改善\n");
    } else {
        printf("[FAILED] 上报失败，建议：%s\n", GetErrorInfo(ret)->suggestion);
    }
}

/**
 * 实时游戏高延迟上报示例
 */
void Example2_GameHighLatency() {
    printf("\n========== 示例2: 实时游戏高延迟上报 ==========\n");
    
    // 场景：实时游戏过程中延迟突然增大，影响游戏体验
    NetworkBoost_ServiceType serviceType = NB_SERVICE_REAL_TIME_GAME;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_HIGH_LATENCY;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret == 0) {
        printf("[SUCCESS] 系统已收到延迟反馈，将启用低延迟加速策略\n");
    }
}

/**
 * 直播观看丢包上报示例
 */
void Example3_LiveStreamingPacketLost() {
    printf("\n========== 示例3: 直播观看丢包上报 ==========\n");
    
    // 场景：直播观看过程中出现丢包，画面花屏或卡顿
    NetworkBoost_ServiceType serviceType = NB_SERVICE_LIVE_STREAMING_WATCHER;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_PACKET_LOST;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret == 0) {
        printf("[SUCCESS] 系统已启用抗丢包加速策略\n");
    }
}

/**
 * 文件下载无数据上报示例
 */
void Example4_DownloadNoData() {
    printf("\n========== 示例4: 文件下载无数据上报 ==========\n");
    
    // 场景：文件下载过程中突然无数据传输
    NetworkBoost_ServiceType serviceType = NB_SERVICE_DOWNLOAD;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_NO_DATA;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret == 0) {
        printf("[SUCCESS] 系统已启用下载加速策略\n");
    }
}

/**
 * 长视频高抖动上报示例
 */
void Example5_LongVideoHighJitter() {
    printf("\n========== 示例5: 长视频高抖动上报 ==========\n");
    
    // 场景：长视频播放过程中出现高抖动，画面不稳定
    NetworkBoost_ServiceType serviceType = NB_SERVICE_LONG_VIDEO;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_HIGH_JITTER;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret == 0) {
        printf("[SUCCESS] 系统已启用抗抖动加速策略\n");
    }
}

/**
 * 实时语音乱序上报示例
 */
void Example6_VoiceOutOfOrder() {
    printf("\n========== 示例6: 实时语音乱序上报 ==========\n");
    
    // 场景：实时语音通话过程中数据包乱序，语音不连贯
    NetworkBoost_ServiceType serviceType = NB_SERVICE_REAL_TIME_VOICE;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_PACKET_OUT_OF_ORDER;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret == 0) {
        printf("[SUCCESS] 系统已启用抗乱序加速策略\n");
    }
}

/**
 * 体验良好状态上报示例
 */
void Example7_QoeGood() {
    printf("\n========== 示例7: 体验良好状态上报 ==========\n");
    
    // 场景：网络恢复正常，体验良好，告知系统恢复正常
    NetworkBoost_ServiceType serviceType = NB_SERVICE_SHORT_VIDEO;
    NetworkBoost_QoeType qoeType = NB_QOE_GOOD;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret == 0) {
        printf("[SUCCESS] 已上报体验良好状态\n");
    }
}

/**
 * 降级处理示例
 */
void Example8_FallbackHandling() {
    printf("\n========== 示例8: 降级处理示例 ==========\n");
    
    // 场景：上报失败时的降级处理
    NetworkBoost_ServiceType serviceType = NB_SERVICE_BROWSER;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_UNKNOWN;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret != 0) {
        printf("[FALLBACK] 启用降级策略:\n");
        
        switch (ret) {
            case 201:
                printf("  - 策略1: 提示用户申请GET_NETWORK_INFO权限\n");
                printf("  - 策略2: 继续使用当前网络，不触发系统加速\n");
                break;
                
            case 801:
                printf("  - 策略1: 提示用户升级系统\n");
                printf("  - 策略2: 应用自身实现网络优化策略\n");
                break;
                
            case 62100001:
            case 62100002:
                printf("  - 策略1: 缓存当前体验状态，等待下次成功上报\n");
                printf("  - 策略2: 降低码率或调整传输策略\n");
                break;
                
            default:
                printf("  - 策略1: 记录日志并跳过本次上报\n");
                break;
        }
    }
}

/**
 * 主函数：运行所有示例
 */
int main() {
    printf("========================================\n");
    printf("应用传输体验反馈完整示例\n");
    printf("API: HMS_NetworkBoost_ReportQoe\n");
    printf("版本: HarmonyOS API 5.1.0(18)\n");
    printf("========================================\n\n");
    
    // 运行各种业务场景示例
    Example1_VideoPlaybackStutter();
    Example2_GameHighLatency();
    Example3_LiveStreamingPacketLost();
    Example4_DownloadNoData();
    Example5_LongVideoHighJitter();
    Example6_VoiceOutOfOrder();
    Example7_QoeGood();
    Example8_FallbackHandling();
    
    printf("\n========================================\n");
    printf("所有示例执行完成\n");
    printf("========================================\n");
    
    return 0;
}