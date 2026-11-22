#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstdlib>

int32_t SetHandoverMode(NetworkBoost_HandoverMode mode)
{
    if (mode != NB_MODE_DELEGATION && mode != NB_MODE_DISCRETION) {
        printf("参数错误：无效的迁移模式，有效值为0(委托)或1(自主)\n");
        return 401;
    }
    
    int32_t ret = HMS_NetworkBoost_SetHandoverMode(mode);
    
    switch (ret) {
        case 0:
            if (mode == NB_MODE_DELEGATION) {
                printf("设置委托迁移模式成功(系统自动控制)\n");
            } else {
                printf("设置自主迁移模式成功(应用主动控制)\n");
            }
            break;
        case 201:
            printf("错误：权限不足\n");
            printf("解决方法：在module.json5中配置ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("错误：参数错误\n");
            printf("解决方法：使用有效枚举值 NB_MODE_DELEGATION(0) 或 NB_MODE_DISCRETION(1)\n");
            break;
        case 801:
            printf("错误：系统能力不支持\n");
            printf("解决方法：检查API版本，最低要求5.1.0(18)\n");
            break;
        case 62100001:
            printf("错误：内部错误\n");
            printf("解决方法：系统服务异常，请稍后重试\n");
            break;
        case 62100002:
            printf("错误：系统服务操作失败\n");
            printf("解决方法：检查网络管理服务状态\n");
            break;
        default:
            printf("错误：未知错误码 %d\n", ret);
            break;
    }
    
    return ret;
}

int32_t SetDelegationMode()
{
    printf("=== 设置委托迁移模式 ===\n");
    return SetHandoverMode(NB_MODE_DELEGATION);
}

int32_t SetDiscretionMode()
{
    printf("=== 设置自主迁移模式 ===\n");
    return SetHandoverMode(NB_MODE_DISCRETION);
}

bool CheckSystemSupport()
{
    printf("=== 检查系统支持 ===\n");
    int32_t testRet = HMS_NetworkBoost_SetHandoverMode(NB_MODE_DELEGATION);
    
    if (testRet == 801) {
        printf("当前系统不支持Network Boost Kit\n");
        printf("最低版本要求：API 5.1.0(18)\n");
        return false;
    }
    
    if (testRet == 201) {
        printf("缺少必要权限\n");
        return false;
    }
    
    printf("系统支持Network Boost Kit\n");
    return true;
}

void PrintCurrentModeInfo(NetworkBoost_HandoverMode mode)
{
    printf("\n=== 当前迁移模式信息 ===\n");
    switch (mode) {
        case NB_MODE_DELEGATION:
            printf("模式：委托模式(系统自动控制)\n");
            printf("说明：系统自动判断并发起连接迁移\n");
            printf("适用：大多数应用，无需关注网络切换细节\n");
            break;
        case NB_MODE_DISCRETION:
            printf("模式：自主模式(应用主动控制)\n");
            printf("说明：应用控制连接迁移，可禁止系统自动迁移\n");
            printf("适用：需要精细控制网络切换的应用\n");
            printf("注意：应用切换到后台时系统仍可能触发切换\n");
            break;
        default:
            printf("模式：未知\n");
            break;
    }
}

int main(int argc, char* argv[])
{
    printf("===========================================\n");
    printf(" Network Boost Kit - 迁移模式设置示例\n");
    printf("===========================================\n\n");
    
    if (!CheckSystemSupport()) {
        printf("\n系统不支持，示例退出\n");
        return -1;
    }
    
    NetworkBoost_HandoverMode targetMode = NB_MODE_DISCRETION;
    
    if (argc > 1) {
        int modeValue = atoi(argv[1]);
        if (modeValue == 0) {
            targetMode = NB_MODE_DELEGATION;
        } else if (modeValue == 1) {
            targetMode = NB_MODE_DISCRETION;
        } else {
            printf("警告：无效的命令行参数 %s，使用默认自主模式\n", argv[1]);
        }
    }
    
    PrintCurrentModeInfo(targetMode);
    
    int32_t result = SetHandoverMode(targetMode);
    
    if (result == 0) {
        printf("\n=== 示例执行成功 ===\n");
        printf("迁移模式已设置\n");
        printf("建议后续步骤：\n");
        printf("1. 注册连接迁移回调监听切换事件\n");
        printf("2. 根据业务需求调整网络策略\n");
        printf("3. 测试网络切换场景\n");
    } else {
        printf("\n=== 示例执行失败 ===\n");
        printf("错误码：%d\n", result);
        printf("请根据错误提示解决问题\n");
    }
    
    printf("\n===========================================\n");
    return result;
}