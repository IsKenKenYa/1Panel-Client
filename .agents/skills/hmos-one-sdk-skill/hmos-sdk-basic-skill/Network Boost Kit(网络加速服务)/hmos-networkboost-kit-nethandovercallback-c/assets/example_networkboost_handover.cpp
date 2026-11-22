#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>

static uint32_t g_callbackId = 0;

void onNetworkHandoverStart(NetworkBoost_HandoverStart* handoverStart)
{
    if (handoverStart == nullptr) {
        printf("HandoverStart参数为空\n");
        return;
    }
    
    printf("=== 连接迁移开始通知 ===\n");
    printf("建议动作：%d\n", handoverStart->recommendedAction);
    
    switch (handoverStart->recommendedAction) {
        case NB_ACTION_DO_CACHING:
            printf("建议：执行缓存动作\n");
            break;
        case NB_ACTION_SUSPEND_DATA:
            printf("建议：暂停发包\n");
            break;
        case NB_ACTION_DECREASE_DATA:
            printf("建议：降低发包速率\n");
            break;
        case NB_ACTION_INCREASE_DATA:
            printf("建议：增加发包速率\n");
            break;
        case NB_ACTION_KEEP_DATA:
            printf("建议：保持当前速率\n");
            break;
        default:
            printf("未知的建议动作：%d\n", handoverStart->recommendedAction);
            break;
    }
}

void onNetworkHandoverComplete(NetworkBoost_HandoverComplete* handoverComplete)
{
    if (handoverComplete == nullptr) {
        printf("HandoverComplete参数为空\n");
        return;
    }
    
    printf("=== 连接迁移完成通知 ===\n");
    printf("迁移结果：%d\n", handoverComplete->errorResult);
    printf("重建建议：%d\n", handoverComplete->reEstAction);
    
    if (handoverComplete->errorResult == NB_ERROR_NONE) {
        printf("迁移成功\n");
        
        switch (handoverComplete->reEstAction) {
            case NB_REEST_DEFAULT:
                printf("建议：使用相同远端IP重建链路\n");
                break;
            case NB_REEST_QUERY_DNS:
                printf("建议：重新查询DNS（链路类型变化）\n");
                break;
            case NB_REEST_CHANGE_REMOTE_IP:
                printf("建议：更换远端IP重建链路\n");
                break;
            case NB_REEST_CHANGE_IP_VERSION:
                printf("建议：修改IP版本重建（IPv4 <-> IPv6）\n");
                break;
            case NB_NO_EST:
                printf("建议：在老链路立即重试，无需重建\n");
                break;
            default:
                printf("未知的重建建议：%d\n", handoverComplete->reEstAction);
                break;
        }
    } else {
        printf("迁移失败\n");
        switch (handoverComplete->errorResult) {
            case NB_ERROR_HANDOVER_TIMEOUT:
                printf("错误：连接迁移超时\n");
                break;
            case NB_ERROR_NEW_PATH_ACTIVATION_FAILED:
                printf("错误：新链路激活失败\n");
                break;
            case NB_ERROR_ABORT:
                printf("错误：迁移被取消\n");
                break;
            default:
                printf("错误：未知错误，错误码：%d\n", handoverComplete->errorResult);
                break;
        }
    }
}

void handleRegisterError(int32_t errorCode)
{
    switch (errorCode) {
        case 201:
            printf("权限不足，请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("参数错误，请检查回调函数是否正确实现\n");
            break;
        case 801:
            printf("系统能力不支持，请检查HarmonyOS版本\n");
            break;
        case 62100001:
            printf("内部错误，请稍后重试\n");
            break;
        case 62100002:
            printf("系统服务操作失败，请检查网络服务状态\n");
            break;
        case 62100003:
            printf("注册请求达到上限，请取消其他回调后再注册\n");
            break;
        default:
            printf("未知错误，错误码：%d\n", errorCode);
            break;
    }
}

int32_t RegisterNetworkHandoverCallback()
{
    printf("开始注册连接迁移回调...\n");
    
    HMS_NetworkBoost_HandoverCallback callback;
    callback.onNetworkHandoverStart = onNetworkHandoverStart;
    callback.onNetworkHandoverComplete = onNetworkHandoverComplete;
    
    int32_t ret = HMS_NetworkBoost_RegisterHandoverChangeCallback(&callback, &g_callbackId);
    
    if (ret == 0) {
        printf("注册成功，回调ID：%u\n", g_callbackId);
        return 0;
    } else {
        printf("注册失败，错误码：%d\n", ret);
        handleRegisterError(ret);
        return ret;
    }
}

int32_t UnregisterNetworkHandoverCallback()
{
    if (g_callbackId == 0) {
        printf("回调未注册或已取消\n");
        return -1;
    }
    
    printf("开始取消注册回调，ID：%u...\n", g_callbackId);
    
    int32_t ret = HMS_NetworkBoost_UnregisterHandoverChangeCallback(g_callbackId);
    
    if (ret == 0) {
        printf("取消注册成功\n");
        g_callbackId = 0;
        return 0;
    } else {
        printf("取消注册失败，错误码：%d\n", ret);
        handleRegisterError(ret);
        return ret;
    }
}

int main()
{
    printf("=== Network Boost Kit 连接迁移通知示例 ===\n");
    printf("HarmonyOS版本：5.1.0(18)及以上\n");
    printf("所需权限：ohos.permission.GET_NETWORK_INFO\n\n");
    
    int32_t ret = RegisterNetworkHandoverCallback();
    if (ret != 0) {
        printf("注册失败，程序退出\n");
        return -1;
    }
    
    printf("\n回调已注册，等待连接迁移事件...\n");
    printf("提示：在弱网环境下，系统会自动发起多网迁移\n");
    printf("支持场景：WiFi <-> 蜂窝，主卡 <-> 副卡\n\n");
    
    printf("按Enter键取消注册并退出...\n");
    getchar();
    
    ret = UnregisterNetworkHandoverCallback();
    if (ret == 0) {
        printf("程序正常退出\n");
        return 0;
    } else {
        printf("程序异常退出\n");
        return -1;
    }
}