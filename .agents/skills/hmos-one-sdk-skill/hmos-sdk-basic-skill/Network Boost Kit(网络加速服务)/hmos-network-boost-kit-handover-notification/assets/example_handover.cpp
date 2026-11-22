#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>

static uint32_t g_callbackId = 0;
static std::atomic<bool> g_handoverInProgress(false);
static std::mutex g_mutex;
static std::condition_variable g_cv;

void PauseDataTransmission() {
    printf("[业务] 暂停数据传输\n");
}

void DecreaseDataRate() {
    printf("[业务] 降低数据传输速率\n");
}

void IncreaseDataRate() {
    printf("[业务] 增加数据传输速率\n");
}

void KeepDataRate() {
    printf("[业务] 保持当前数据传输速率\n");
}

void ReestablishConnectionWithSameIP() {
    printf("[业务] 使用原远端IP重建连接\n");
    std::thread([]() {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        printf("[业务] 连接重建完成\n");
        g_handoverInProgress = false;
        g_cv.notify_one();
    }).detach();
}

void QueryDNSAndReestablish() {
    printf("[业务] DNS查询新IP并重建连接\n");
    std::thread([]() {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        printf("[业务] DNS查询完成，连接重建完成\n");
        g_handoverInProgress = false;
        g_cv.notify_one();
    }).detach();
}

void ReestablishConnectionWithNewIP() {
    printf("[业务] 使用不同远端IP重建连接\n");
    std::thread([]() {
        std::this_thread::sleep_for(std::chrono::milliseconds(80));
        printf("[业务] 连接重建完成\n");
        g_handoverInProgress = false;
        g_cv.notify_one();
    }).detach();
}

void ReestablishConnectionWithNewIPVersion() {
    printf("[业务] 更换IP版本(IPv4/IPv6)重建连接\n");
    std::thread([]() {
        std::this_thread::sleep_for(std::chrono::milliseconds(60));
        printf("[业务] 连接重建完成\n");
        g_handoverInProgress = false;
        g_cv.notify_one();
    }).detach();
}

void RetryImmediatelyOnOldPath() {
    printf("[业务] 无需重建，立即在老链路重试\n");
    std::thread([]() {
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
        printf("[业务] 重试完成\n");
        g_handoverInProgress = false;
        g_cv.notify_one();
    }).detach();
}

void HandleHandoverError(NetworkBoost_ErrorResult result) {
    printf("[业务] 处理迁移错误: ");
    switch (result) {
        case NB_ERROR_HANDOVER_TIMEOUT:
            printf("迁移超时，立即重建连接\n");
            ReestablishConnectionWithSameIP();
            break;
        case NB_ERROR_NEW_PATH_ACTIVATION_FAILED:
            printf("新链路激活失败，等待系统重新迁移\n");
            break;
        case NB_ERROR_ABORT:
            printf("迁移被取消，恢复原有传输策略\n");
            KeepDataRate();
            g_handoverInProgress = false;
            g_cv.notify_one();
            break;
        default:
            printf("未知错误\n");
            g_handoverInProgress = false;
            g_cv.notify_one();
            break;
    }
}

void onNetworkHandoverStart(NetworkBoost_HandoverStart* handoverStart) {
    if (handoverStart == nullptr) {
        printf("[回调] 错误: handoverStart为空指针\n");
        return;
    }
    
    uint32_t expires = handoverStart->expires;
    NetworkBoost_DataSpeedAction dataSpeedAction = handoverStart->dataSpeedAction;
    
    printf("\n[回调] ========== 连接迁移开始 ========== \n");
    printf("[回调] 迁移超时时间: %u秒\n", expires);
    
    g_handoverInProgress = true;
    
    switch (dataSpeedAction.simpleAction) {
        case NB_SIMPLEACTION_SUSPEND_DATA:
            printf("[回调] 系统建议: 暂停发包\n");
            PauseDataTransmission();
            break;
        case NB_SIMPLEACTION_DECREASE_DATA:
            printf("[回调] 系统建议: 降低发包速率\n");
            DecreaseDataRate();
            break;
        case NB_SIMPLEACTION_INCREASE_DATA:
            printf("[回调] 系统建议: 增加发包速率\n");
            IncreaseDataRate();
            break;
        case NB_SIMPLEACTION_KEEP_DATA:
            printf("[回调] 系统建议: 保持当前发包速率\n");
            KeepDataRate();
            break;
        default:
            printf("[回调] 系统建议: 未知发包策略(%d)\n", dataSpeedAction.simpleAction);
            break;
    }
}

void onNetworkHandoverComplete(NetworkBoost_HandoverComplete* handoverComplete) {
    if (handoverComplete == nullptr) {
        printf("[回调] 错误: handoverComplete为空指针\n");
        return;
    }
    
    NetworkBoost_ErrorResult result = handoverComplete->result;
    bool handoverContinue = handoverComplete->handoverContinue;
    uint32_t oldPathLifetime = handoverComplete->oldPathLifetime;
    bool pathTypeChanged = handoverComplete->pathTypeChanged;
    NetworkBoost_ReEstAction reEstAction = handoverComplete->reEstAction;
    NetworkBoost_DataSpeedAction newDataSpeedAction = handoverComplete->newDataSpeedAction;
    
    printf("\n[回调] ========== 连接迁移完成 ========== \n");
    printf("[回调] 迁移结果: ");
    switch (result) {
        case NB_ERROR_NONE:
            printf("成功\n");
            break;
        case NB_ERROR_HANDOVER_TIMEOUT:
            printf("迁移超时\n");
            break;
        case NB_ERROR_NEW_PATH_ACTIVATION_FAILED:
            printf("新链路激活失败\n");
            break;
        case NB_ERROR_ABORT:
            printf("迁移被取消\n");
            break;
        default:
            printf("未知(%d)\n", result);
            break;
    }
    
    printf("[回调] 是否还有后续回调: %s\n", handoverContinue ? "是(继续等待)" : "否(迁移完成)");
    printf("[回调] 老链路剩余生存时长: %u秒\n", oldPathLifetime);
    printf("[回调] 新老链路类型是否变更: %s", pathTypeChanged ? "是(WiFi<->蜂窝)" : "否");
    
    if (result != NB_ERROR_NONE) {
        HandleHandoverError(result);
        return;
    }
    
    printf("\n[回调] 重建建议: ");
    switch (reEstAction) {
        case NB_REEST_DEFAULT:
            printf("使用原远端IP重建\n");
            ReestablishConnectionWithSameIP();
            break;
        case NB_REEST_QUERY_DNS:
            printf("DNS查询新IP\n");
            QueryDNSAndReestablish();
            break;
        case NB_REEST_CHANGE_REMOTE_IP:
            printf("使用不同远端IP\n");
            ReestablishConnectionWithNewIP();
            break;
        case NB_REEST_CHANGE_IP_VERSION:
            printf("更换IP版本(IPv4/IPv6)\n");
            ReestablishConnectionWithNewIPVersion();
            break;
        case NB_NO_EST:
            printf("无需重建，立即重试\n");
            RetryImmediatelyOnOldPath();
            break;
        default:
            printf("未知(%d)\n", reEstAction);
            g_handoverInProgress = false;
            g_cv.notify_one();
            break;
    }
    
    printf("[回调] 新链路发包建议: ");
    switch (newDataSpeedAction.simpleAction) {
        case NB_SIMPLEACTION_SUSPEND_DATA:
            printf("暂停发包\n");
            break;
        case NB_SIMPLEACTION_DECREASE_DATA:
            printf("降低发包速率\n");
            break;
        case NB_SIMPLEACTION_INCREASE_DATA:
            printf("增加发包速率\n");
            IncreaseDataRate();
            break;
        case NB_SIMPLEACTION_KEEP_DATA:
            printf("保持发包速率\n");
            break;
        default:
            printf("未知(%d)\n", newDataSpeedAction.simpleAction);
            break;
    }
    
    if (!handoverContinue) {
        printf("\n[回调] ===== 多路径迁移流程完全结束 =====\n");
    }
}

int32_t RegisterNetworkHandoverCallback() {
    printf("\n[注册] 开始注册连接迁移回调...\n");
    
    HMS_NetworkBoost_HandoverCallback callback;
    callback.onNetworkHandoverStart = onNetworkHandoverStart;
    callback.onNetworkHandoverComplete = onNetworkHandoverComplete;
    
    int32_t ret = HMS_NetworkBoost_RegisterHandoverChangeCallback(&callback, &g_callbackId);
    
    printf("[注册] 注册结果: ");
    switch (ret) {
        case 0:
            printf("成功, callbackId=%u\n", g_callbackId);
            break;
        case 201:
            printf("失败 - 权限不足\n");
            printf("[注册] 解决方法: 在module.json5中配置ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("失败 - 参数错误\n");
            printf("[注册] 解决方法: 检查回调函数指针是否为空\n");
            break;
        case 801:
            printf("失败 - 系统能力不支持\n");
            printf("[注册] 解决方法: API版本需>=5.1.0(18)\n");
            break;
        case 62100001:
            printf("失败 - 内部错误\n");
            break;
        case 62100002:
            printf("失败 - 系统服务操作失败\n");
            break;
        case 62100003:
            printf("失败 - 注册达到上限(最多1000个)\n");
            break;
        default:
            printf("失败 - 未知错误码%d\n", ret);
            break;
    }
    
    return ret;
}

int32_t UnregisterNetworkHandoverCallback() {
    printf("\n[取消注册] 开始取消注册连接迁移回调...\n");
    
    if (g_callbackId == 0) {
        printf("[取消注册] 错误: callbackId无效，未注册或已取消\n");
        return -1;
    }
    
    int32_t ret = HMS_NetworkBoost_UnregisterHandoverChangeCallback(g_callbackId);
    
    printf("[取消注册] 取消注册结果: ");
    switch (ret) {
        case 0:
            printf("成功\n");
            g_callbackId = 0;
            break;
        case 201:
            printf("失败 - 权限不足\n");
            break;
        case 401:
            printf("失败 - callbackId参数错误\n");
            break;
        case 801:
            printf("失败 - 系统能力不支持\n");
            break;
        case 62100001:
            printf("失败 - 内部错误\n");
            break;
        case 62100002:
            printf("失败 - 系统服务操作失败\n");
            break;
        default:
            printf("失败 - 未知错误码%d\n", ret);
            break;
    }
    
    return ret;
}

void WaitForHandoverComplete() {
    std::unique_lock<std::mutex> lock(g_mutex);
    g_cv.wait(lock, [] { return !g_handoverInProgress; });
    printf("\n[主线程] 迁移流程已完成，恢复业务\n");
}

int main() {
    printf("========================================\n");
    printf("Network Boost Kit - 连接迁移通知示例\n");
    printf("========================================\n");
    
    int32_t ret = RegisterNetworkHandoverCallback();
    if (ret != 0) {
        printf("\n[主线程] 注册失败，退出程序\n");
        return ret;
    }
    
    printf("\n[主线程] 注册成功，等待系统发起迁移事件...\n");
    printf("[主线程] 提示: 手动切换WiFi开关或飞行模式触发迁移\n");
    
    WaitForHandoverComplete();
    
    printf("\n[主线程] 等待5秒后取消注册...\n");
    std::this_thread::sleep_for(std::chrono::seconds(5));
    
    ret = UnregisterNetworkHandoverCallback();
    if (ret != 0) {
        printf("\n[主线程] 取消注册失败\n");
        return ret;
    }
    
    printf("\n========================================\n");
    printf("示例程序执行完成\n");
    printf("========================================\n");
    
    return 0;
}