#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>

uint32_t g_callbackId = 0;
bool g_isRegistered = false;

void onMultiPathStateChangeCallback(NetworkBoost_MultiPathStateChange* result) {
    if (result == nullptr) {
        printf("[ERROR] 多网状态变化回调: 参数为空指针\n");
        return;
    }
    
    printf("\n=== 多网状态变化事件 ===\n");
    printf("多网状态: %d\n", result->multiPathState);
    printf("变化原因: %d\n", result->changeCause);
    printf("链路类型: %d\n", result->pathType);
    printf("链路状态: %d\n", result->pathState);
    
    switch (result->multiPathState) {
        case NB_MULTIPATH_IDLE:
            printf("多网状态解析: 空闲态\n");
            printf("建议操作: 切换回单网传输策略\n");
            break;
        case NB_MULTIPATH_CREATEING:
            printf("多网状态解析: 正在建立中\n");
            printf("建议操作: 等待建立完成\n");
            break;
        case NB_MULTIPATH_CREATED:
            printf("多网状态解析: 已建立\n");
            printf("建议操作: 启用多网并发传输策略\n");
            break;
        case NB_MULTIPATH_RELEASING:
            printf("多网状态解析: 正在释放中\n");
            printf("建议操作: 准备切换回单网传输策略\n");
            break;
        default:
            printf("多网状态解析: 未知状态 (%d)\n", result->multiPathState);
            break;
    }
    
    switch (result->pathType) {
        case NB_PATH_CELLULAR_PRIMARY:
            printf("链路类型解析: 蜂窝主卡\n");
            break;
        case NB_PATH_CELLULAR_SECONDARY:
            printf("链路类型解析: 蜂窝副卡\n");
            break;
        case NB_PATH_WIFI_PRIMARY:
            printf("链路类型解析: 主Wi-Fi\n");
            break;
        case NB_PATH_WIFI_SECONDARY:
            printf("链路类型解析: 辅Wi-Fi\n");
            break;
        default:
            printf("链路类型解析: 未知类型 (%d)\n", result->pathType);
            break;
    }
    
    switch (result->pathState) {
        case NB_PATH_IDLE:
            printf("链路状态解析: 空闲\n");
            break;
        case NB_PATH_CONNECTED:
            printf("链路状态解析: 已连接\n");
            break;
        case NB_PATH_SUSPENDED:
            printf("链路状态解析: 挂起\n");
            break;
        default:
            printf("链路状态解析: 未知状态 (%d)\n", result->pathState);
            break;
    }
    
    switch (result->changeCause) {
        case NB_MULTIPATH_CAUSE_REQUEST_NORMAL:
            printf("变化原因解析: 正常发起多网请求\n");
            break;
        case NB_MULTIPATH_CAUSE_RELEASE_NORMAL:
            printf("变化原因解析: 正常释放多网请求\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK:
            printf("变化原因解析: 网络原因释放多网\n");
            printf("建议操作: 检查网络状态, 可能需要重试\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED:
            printf("变化原因解析: 用户操作开关释放多网\n");
            break;
        case NB_MULTIPATH_CAUSE_RELEASE_NO_QUOTA:
            printf("变化原因解析: 配额耗尽释放多网\n");
            printf("建议操作: 提示用户配额不足\n");
            break;
        case NB_MULTIPATH_CAUSE_RELEASE_POWER_CONSUMPTION:
            printf("变化原因解析: 功耗原因释放多网\n");
            printf("建议操作: 优化功耗策略\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC:
            printf("变化原因解析: 流量不足释放多网\n");
            printf("建议操作: 提示用户流量不足\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_CONFLICT:
            printf("变化原因解析: 场景冲突释放多网\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING:
            printf("变化原因解析: 应用使用不规范, 系统释放多网\n");
            printf("建议操作: 检查应用多网使用逻辑, 避免长时间占用\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_DEFAULT:
            printf("变化原因解析: 系统网络状态变化释放多网\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER:
            printf("变化原因解析: 多网进入挂起状态\n");
            printf("建议操作: 暂停使用多网链路传输数据\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE:
            printf("变化原因解析: 多网退出挂起状态\n");
            printf("建议操作: 可恢复使用多网链路传输数据\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_CONN_PROPERTIES_UPDATE:
            printf("变化原因解析: 多网链路连接属性更新\n");
            printf("建议操作: 可获取新的链路属性信息\n");
            break;
        default:
            printf("变化原因解析: 其他原因 (%d)\n", result->changeCause);
            break;
    }
    
    printf("=== 事件处理完成 ===\n\n");
}

int32_t RegisterMultiPathStateChange() {
    printf("\n=== 注册多网状态监听 ===\n");
    
    if (g_isRegistered) {
        printf("[WARN] 已注册多网状态监听, callbackId=%u, 无需重复注册\n", g_callbackId);
        return 0;
    }
    
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathStateChangeCallback(
        onMultiPathStateChangeCallback, 
        &g_callbackId
    );
    
    if (ret == 0) {
        g_isRegistered = true;
        printf("[SUCCESS] 注册成功, callbackId=%u\n", g_callbackId);
    } else {
        printf("[FAILED] 注册失败, 错误码=%d\n", ret);
        switch (ret) {
            case 201:
                printf("[ERROR] 权限不足, 需申请ohos.permission.GET_NETWORK_INFO权限\n");
                printf("[SOLUTION] 在module.json5中添加权限声明\n");
                break;
            case 401:
                printf("[ERROR] 参数错误, 回调函数或callbackId指针为空\n");
                printf("[SOLUTION] 检查回调函数和callbackId参数是否正确\n");
                break;
            case 801:
                printf("[ERROR] 系统能力不支持\n");
                printf("[SOLUTION] 检查设备是否支持多网功能, API版本>=6.0.2(22)\n");
                break;
            case 1013600001:
                printf("[ERROR] 内部处理异常\n");
                printf("[SOLUTION] 记录日志, 稍后重试\n");
                break;
            case 1013600002:
                printf("[ERROR] 系统服务操作失败\n");
                printf("[SOLUTION] 检查网络服务状态, 重启应用\n");
                break;
            case 62100003:
                printf("[ERROR] 注册请求达到上限\n");
                printf("[SOLUTION] 注销已有回调后再注册新回调\n");
                break;
            default:
                printf("[ERROR] 其他错误\n");
                break;
        }
    }
    
    printf("=== 注册流程结束 ===\n\n");
    return ret;
}

int32_t UnregisterMultiPathStateChange() {
    printf("\n=== 注销多网状态监听 ===\n");
    
    if (!g_isRegistered || g_callbackId == 0) {
        printf("[WARN] 未注册多网状态监听, 无需注销\n");
        g_isRegistered = false;
        g_callbackId = 0;
        return 0;
    }
    
    printf("[INFO] 使用callbackId=%u注销回调\n", g_callbackId);
    
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback(g_callbackId);
    
    if (ret == 0) {
        printf("[SUCCESS] 注销成功\n");
        g_isRegistered = false;
        g_callbackId = 0;
    } else {
        printf("[FAILED] 注销失败, 错误码=%d\n", ret);
        switch (ret) {
            case 201:
                printf("[ERROR] 权限不足\n");
                break;
            case 401:
                printf("[ERROR] callbackId无效\n");
                printf("[SOLUTION] 确保使用注册时分配的callbackId\n");
                break;
            case 801:
                printf("[ERROR] 系统能力不支持\n");
                break;
            case 1013600001:
                printf("[ERROR] 内部处理异常\n");
                break;
            case 1013600002:
                printf("[ERROR] 系统服务操作失败\n");
                break;
            default:
                printf("[ERROR] 其他错误\n");
                break;
        }
    }
    
    printf("=== 注销流程结束 ===\n\n");
    return ret;
}

void PrintUsage() {
    printf("\n=== 多网状态监听示例程序 ===\n");
    printf("命令说明:\n");
    printf("  r - 注册多网状态监听回调\n");
    printf("  u - 注销多网状态监听回调\n");
    printf("  s - 查询当前状态\n");
    printf("  h - 显示帮助信息\n");
    printf("  q - 退出程序\n");
    printf("=== 使用说明 ===\n\n");
}

void PrintStatus() {
    printf("\n=== 当前状态 ===\n");
    printf("注册状态: %s\n", g_isRegistered ? "已注册" : "未注册");
    printf("callbackId: %u\n", g_callbackId);
    printf("=== 状态信息 ===\n\n");
}

int main() {
    printf("\n********************************************\n");
    printf("*     多网状态监听完整示例程序            *\n");
    printf("*     API版本要求: 6.0.2(22)及以上        *\n");
    printf("*     权限要求: ohos.permission.GET_NETWORK_INFO *\n");
    printf("********************************************\n\n");
    
    PrintUsage();
    
    char command[10] = {0};
    bool running = true;
    
    while (running) {
        printf("请输入命令 (r/u/s/h/q): ");
        if (scanf("%s", command) != 1) {
            printf("[ERROR] 输入读取失败\n");
            continue;
        }
        
        if (strcmp(command, "r") == 0) {
            RegisterMultiPathStateChange();
        } else if (strcmp(command, "u") == 0) {
            UnregisterMultiPathStateChange();
        } else if (strcmp(command, "s") == 0) {
            PrintStatus();
        } else if (strcmp(command, "h") == 0) {
            PrintUsage();
        } else if (strcmp(command, "q") == 0) {
            printf("\n=== 退出程序 ===\n");
            if (g_isRegistered) {
                printf("[INFO] 检测到已注册监听, 执行自动注销\n");
                UnregisterMultiPathStateChange();
            }
            printf("[INFO] 程序已退出\n");
            running = false;
        } else {
            printf("[ERROR] 未知命令: %s, 请输入有效命令\n", command);
            PrintUsage();
        }
        
        memset(command, 0, sizeof(command));
    }
    
    printf("\n=== 示例程序执行完成 ===\n");
    return 0;
}