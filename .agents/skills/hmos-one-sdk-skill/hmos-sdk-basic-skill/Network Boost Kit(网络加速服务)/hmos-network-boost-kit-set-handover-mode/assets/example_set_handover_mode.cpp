/**
 * @file example_set_handover_mode.cpp
 * @brief 设置连接迁移模式的完整示例代码
 * 
 * 本示例演示如何使用HMS_NetworkBoost_SetHandoverMode接口设置网络连接迁移模式。
 * 包括委托模式和自主模式的设置,以及错误处理和降级方案。
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>

// 全局变量:记录当前迁移模式
static NetworkBoost_HandoverMode g_currentMode = NB_MODE_DELEGATION;

/**
 * @brief 错误码处理函数
 * @param errorCode HMS_NetworkBoost_SetHandoverMode返回的错误码
 * @return 处理后的错误码
 */
int32_t HandleError(int32_t errorCode)
{
    switch (errorCode) {
        case 0:
            printf("[SUCCESS] 设置连接迁移模式成功\n");
            break;
        case 201:
            printf("[ERROR] 权限不足(201)\n");
            printf("[SOLUTION] 需在module.json5中申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("[ERROR] 参数错误(401)\n");
            printf("[SOLUTION] 检查传入的mode参数是否为有效枚举值\n");
            break;
        case 801:
            printf("[ERROR] 系统能力不支持(801)\n");
            printf("[SOLUTION] 检查设备API版本是否>=5.1.0(18)\n");
            break;
        case 62100001:
            printf("[ERROR] 内部错误(62100001)\n");
            printf("[SOLUTION] 建议稍后重试或重启应用\n");
            break;
        case 62100002:
            printf("[ERROR] 系统服务操作失败(62100002)\n");
            printf("[SOLUTION] 检查网络服务状态,重启设备\n");
            break;
        default:
            printf("[ERROR] 未知错误(%d)\n", errorCode);
            break;
    }
    return errorCode;
}

/**
 * @brief 设置连接迁移模式
 * @param mode 迁移模式(NB_MODE_DELEGATION或NB_MODE_DISCRETION)
 * @return 0表示成功,其他值表示错误码
 */
int32_t SetHandoverMode(NetworkBoost_HandoverMode mode)
{
    printf("[INFO] 开始设置迁移模式...\n");
    printf("[INFO] 目标模式: %s\n", 
           (mode == NB_MODE_DELEGATION) ? "委托模式(系统控制)" : "自主模式(应用控制)");
    
    // 调用API
    int32_t ret = HMS_NetworkBoost_SetHandoverMode(mode);
    
    // 处理结果
    if (ret == 0) {
        // 更新全局状态
        g_currentMode = mode;
        printf("[SUCCESS] 模式已更新为: %s\n", 
               (mode == NB_MODE_DELEGATION) ? "委托模式" : "自主模式");
    } else {
        HandleError(ret);
    }
    
    return ret;
}

/**
 * @brief 获取当前迁移模式描述
 * @return 模式描述字符串
 */
const char* GetCurrentModeDescription()
{
    if (g_currentMode == NB_MODE_DELEGATION) {
        return "委托模式(由系统自动发起连接迁移)";
    } else if (g_currentMode == NB_MODE_DISCRETION) {
        return "自主模式(由应用自主控制连接迁移)";
    } else {
        return "未知模式";
    }
}

/**
 * @brief 降级处理方案
 * @param targetMode 目标模式
 */
void SetHandoverModeWithFallback(NetworkBoost_HandoverMode targetMode)
{
    printf("[INFO] 尝试设置迁移模式(含降级方案)\n");
    
    int32_t ret = SetHandoverMode(targetMode);
    
    if (ret != 0) {
        printf("[WARN] 设置失败,启动降级方案...\n");
        
        // 降级方案1:保持当前模式不变
        printf("[FALLBACK1] 保持当前模式: %s\n", GetCurrentModeDescription());
        
        // 降级方案2:根据错误类型提供具体建议
        if (ret == 201) {
            printf("[FALLBACK2] 权限问题,建议:\n");
            printf("  - 检查module.json5中权限配置\n");
            printf("  - 确认应用签名包含权限声明\n");
        } else if (ret == 801) {
            printf("[FALLBACK2] 设备不支持,建议:\n");
            printf("  - 检查设备HarmonyOS版本\n");
            printf("  - 使用传统网络管理机制\n");
        } else {
            printf("[FALLBACK2] 其他错误,建议:\n");
            printf("  - 检查网络服务状态\n");
            printf("  - 重启应用或设备\n");
        }
    }
}

/**
 * @brief 主函数
 */
int main()
{
    printf("=== Network Boost Kit - 连接迁移模式设置示例 ===\n\n");
    
    // 示例1:设置为委托模式(系统控制)
    printf("【示例1】设置为委托模式\n");
    int32_t ret1 = SetHandoverMode(NB_MODE_DELEGATION);
    printf("返回值: %d\n", ret1);
    printf("当前模式: %s\n\n", GetCurrentModeDescription());
    
    // 示例2:设置为自主模式(应用控制)
    printf("【示例2】设置为自主模式\n");
    int32_t ret2 = SetHandoverMode(NB_MODE_DISCRETION);
    printf("返回值: %d\n", ret2);
    printf("当前模式: %s\n\n", GetCurrentModeDescription());
    
    // 示例3:使用降级方案设置模式
    printf("【示例3】使用降级方案设置模式\n");
    SetHandoverModeWithFallback(NB_MODE_DISCRETION);
    printf("\n");
    
    // 示例4:动态切换模式
    printf("【示例4】动态切换模式\n");
    printf("切换前: %s\n", GetCurrentModeDescription());
    
    // 切换到自主模式
    if (g_currentMode == NB_MODE_DELEGATION) {
        SetHandoverMode(NB_MODE_DISCRETION);
    } else {
        SetHandoverMode(NB_MODE_DELEGATION);
    }
    
    printf("切换后: %s\n", GetCurrentModeDescription());
    
    printf("\n=== 示例结束 ===\n");
    return 0;
}