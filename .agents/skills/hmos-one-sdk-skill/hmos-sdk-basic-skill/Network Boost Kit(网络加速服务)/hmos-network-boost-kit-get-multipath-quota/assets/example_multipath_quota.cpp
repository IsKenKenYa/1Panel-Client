/**
 * 多网配额查询示例代码
 * 
 * 本示例演示如何使用Network Boost Kit的C API查询多网并发配额信息
 * 
 * 功能：
 * 1. 查询已使用的多网并发配额（次数和时长）
 * 2. 查询剩余的多网并发配额（次数和时长）
 * 3. 检查配额是否充足
 * 4. 错误处理和降级方案
 * 
 * API版本要求：6.0.2(22)及以上
 * 权限要求：ohos.permission.LINKTURBO
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
#include <string>

/**
 * 多网配额管理类
 */
class MultiPathQuotaManager {
public:
    /**
     * 获取配额信息
     * @param quota 输出参数，配额信息
     * @return 0表示成功，其他值表示错误码
     */
    int32_t GetQuotaInfo(NetworkBoost_MultiPathQuota& quota)
    {
        // 清空结构体
        memset(&quota, 0, sizeof(quota));
        
        // 调用API获取配额信息
        int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
        
        if (ret == 0) {
            PrintQuotaInfo(quota);
        } else {
            PrintError(ret);
        }
        
        return ret;
    }
    
    /**
     * 打印配额信息
     * @param quota 配额信息结构体
     */
    void PrintQuotaInfo(const NetworkBoost_MultiPathQuota& quota)
    {
        printf("\n=== 多网配额信息 ===\n");
        printf("已使用配额:\n");
        printf("  时长: %u 秒\n", quota.used.duration);
        printf("  次数: %u 次\n", quota.used.count);
        printf("剩余配额:\n");
        printf("  时长: %u 秒\n", quota.remaining.duration);
        printf("  次数: %u 次\n", quota.remaining.count);
        printf("==================\n\n");
    }
    
    /**
     * 打印错误信息
     * @param errorCode 错误码
     */
    void PrintError(int32_t errorCode)
    {
        std::string errorMsg;
        
        switch (errorCode) {
            case 201:
                errorMsg = "权限不足，请检查是否已申请ohos.permission.LINKTURBO权限";
                break;
            case 801:
                errorMsg = "系统能力不支持，当前设备不支持多网并发功能";
                break;
            case 1013600001:
                errorMsg = "内部错误，系统内部处理异常";
                break;
            case 1013600002:
                errorMsg = "系统处理异常，IPC跨进程调用失败或网络管理服务启动失败";
                break;
            case 1013600004:
                errorMsg = "参数错误，传入参数有误（如空指针）";
                break;
            default:
                errorMsg = "未知错误";
                break;
        }
        
        printf("\n[错误] %s (错误码: %d)\n\n", errorMsg.c_str(), errorCode);
    }
    
    /**
     * 检查是否可以发起多网请求
     * @return true表示配额充足，false表示配额不足或查询失败
     */
    bool CanRequestMultiPath()
    {
        NetworkBoost_MultiPathQuota quota;
        
        // 获取配额信息
        int32_t ret = GetQuotaInfo(quota);
        if (ret != 0) {
            return false;
        }
        
        // 检查剩余配额
        if (quota.remaining.count == 0) {
            printf("[警告] 配额次数已耗尽，请等待24小时后自动刷新\n");
            return false;
        }
        
        if (quota.remaining.duration == 0) {
            printf("[警告] 配额时长已耗尽，请等待24小时后自动刷新\n");
            return false;
        }
        
        printf("[成功] 配额充足，可以发起多网请求\n");
        printf("  剩余次数: %u 次\n", quota.remaining.count);
        printf("  剩余时长: %u 秒\n", quota.remaining.duration);
        
        return true;
    }
    
    /**
     * 业务示例：发起多网请求前检查配额
     * @return 0表示可以发起请求，-1表示配额不足
     */
    int32_t RequestMultiPathWithQuotaCheck()
    {
        printf("正在检查多网配额...\n");
        
        // 检查配额
        if (!CanRequestMultiPath()) {
            printf("配额不足，无法发起多网请求\n");
            printf("提示: 配额将在24小时后自动刷新\n");
            return -1;
        }
        
        // 配额充足，可以发起多网请求
        printf("配额检查通过，可以发起多网请求\n");
        // TODO: 调用 HMS_NetworkBoost_RequestMultiPath 等其他API
        
        return 0;
    }
    
    /**
     * 配额使用率计算
     * @param quota 配额信息
     * @param usedPercent 输出参数，已使用百分比
     * @return 0表示成功，-1表示参数错误
     */
    int32_t CalculateQuotaUsage(const NetworkBoost_MultiPathQuota& quota, float& usedPercent)
    {
        // 计算总配额
        uint32_t totalCount = quota.used.count + quota.remaining.count;
        uint32_t totalDuration = quota.used.duration + quota.remaining.duration;
        
        if (totalCount == 0 || totalDuration == 0) {
            printf("[错误] 配额数据异常\n");
            return -1;
        }
        
        // 计算已使用百分比
        float countPercent = (float)quota.used.count / totalCount * 100.0f;
        float durationPercent = (float)quota.used.duration / totalDuration * 100.0f;
        
        usedPercent = (countPercent + durationPercent) / 2.0f;
        
        printf("配额使用情况:\n");
        printf("  次数使用率: %.1f%% (%u/%u)\n", 
               countPercent, quota.used.count, totalCount);
        printf("  时长使用率: %.1f%% (%u秒/%u秒)\n", 
               durationPercent, quota.used.duration, totalDuration);
        printf("  综合使用率: %.1f%%\n", usedPercent);
        
        return 0;
    }
};

/**
 * 主函数 - 示例演示
 */
int main()
{
    printf("\n========================================\n");
    printf("  多网配额查询示例\n");
    printf("========================================\n");
    
    MultiPathQuotaManager manager;
    
    // 示例1: 获取配额信息
    printf("\n[示例1] 获取多网配额信息\n");
    NetworkBoost_MultiPathQuota quota;
    int32_t ret = manager.GetQuotaInfo(quota);
    
    if (ret == 0) {
        // 示例2: 计算配额使用率
        printf("\n[示例2] 计算配额使用率\n");
        float usedPercent = 0.0f;
        manager.CalculateQuotaUsage(quota, usedPercent);
        
        // 示例3: 检查是否可以发起多网请求
        printf("\n[示例3] 检查是否可以发起多网请求\n");
        if (manager.CanRequestMultiPath()) {
            printf("建议: 可以正常使用多网并发功能\n");
        } else {
            printf("建议: 配额不足，请等待刷新或减少使用频率\n");
        }
        
        // 示例4: 模拟业务场景
        printf("\n[示例4] 业务场景演示\n");
        manager.RequestMultiPathWithQuotaCheck();
    } else {
        printf("获取配额信息失败，无法继续演示\n");
        return -1;
    }
    
    printf("\n========================================\n");
    printf("  示例演示完成\n");
    printf("========================================\n\n");
    
    return 0;
}