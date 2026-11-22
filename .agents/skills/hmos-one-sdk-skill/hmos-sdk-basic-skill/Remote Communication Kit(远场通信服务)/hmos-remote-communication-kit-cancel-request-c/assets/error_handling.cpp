/**
 * @file error_handling.cpp
 * @brief 错误处理和异常场景示例代码
 * @version 1.0
 * @date 2026-07-03
 */

#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

// 错误码常量定义(根据实际API文档定义)
#define RCP_ERROR_INVALID_PARAM 1
#define RCP_ERROR_SESSION_CLOSED 2
#define RCP_ERROR_REQUEST_NOT_FOUND 3
#define RCP_ERROR_NETWORK_UNAVAILABLE 4
#define RCP_ERROR_MEMORY_ALLOCATION 5
#define RCP_ERROR_TIMEOUT 6
#define RCP_ERROR_CANCELED 7

// 全局状态跟踪
typedef struct {
    bool requestActive;
    bool sessionActive;
    int requestCount;
    int canceledCount;
} AppState;

AppState g_state = {false, false, 0, 0};

/**
 * @brief 增强的错误处理函数
 * @param errCode 错误码
 * @param operation 操作名称
 * @param context 上下文信息
 * @return 0表示成功, -1表示失败
 */
int EnhancedHandleError(uint32_t errCode, const char *operation, const char *context)
{
    if (errCode == 0) {
        printf("[OK] %s - %s\n", operation, context);
        return 0;
    }
    
    printf("[ERROR] %s - %s\n", operation, context);
    printf("  Error Code: %u\n", errCode);
    
    // 错误级别分类
    const char* severity = "UNKNOWN";
    if (errCode <= 3) {
        severity = "LOW"; // 参数类错误,可快速修复
    } else if (errCode <= 6) {
        severity = "MEDIUM"; // 执行类错误,需要处理
    } else {
        severity = "HIGH"; // 系统类错误,可能需要重启
    }
    
    printf("  Severity: %s\n", severity);
    
    // 详细错误分析和解决建议
    switch (errCode) {
        case RCP_ERROR_INVALID_PARAM:
            printf("  Type: Invalid Parameter Error\n");
            printf("  Detail: One or more parameters are invalid or NULL\n");
            printf("  Possible Causes:\n");
            printf("    - Session pointer is NULL\n");
            printf("    - Request pointer is NULL\n");
            printf("    - Configuration object is invalid\n");
            printf("  Solutions:\n");
            printf("    1. Verify all pointer parameters before calling API\n");
            printf("    2. Check object creation was successful\n");
            printf("    3. Ensure objects are not already destroyed\n");
            break;
            
        case RCP_ERROR_SESSION_CLOSED:
            printf("  Type: Session State Error\n");
            printf("  Detail: Attempting to use a closed session\n");
            printf("  Possible Causes:\n");
            printf("    - Session was closed by HMS_Rcp_CloseSession\n");
            printf("    - Session was canceled by HMS_Rcp_CancelSession\n");
            printf("    - Session object was destroyed\n");
            printf("  Solutions:\n");
            printf("    1. Check session state before use\n");
            printf("    2. Create new session if old one is closed\n");
            printf("    3. Maintain session lifecycle management\n");
            break;
            
        case RCP_ERROR_REQUEST_NOT_FOUND:
            printf("  Type: Request State Error\n");
            printf("  Detail: Request not found in session\n");
            printf("  Possible Causes:\n");
            printf("    - Request was not added to session\n");
            printf("    - Request was already canceled\n");
            printf("    - Request was already completed\n");
            printf("  Solutions:\n");
            printf("    1. Ensure request is added via HMS_Rcp_Fetch\n");
            printf("    2. Track request status in application\n");
            printf("    3. Avoid canceling already completed requests\n");
            break;
            
        case RCP_ERROR_NETWORK_UNAVAILABLE:
            printf("  Type: Network Error\n");
            printf("  Detail: Network connection is unavailable\n");
            printf("  Possible Causes:\n");
            printf("    - Device lost network connectivity\n");
            printf("    - Network configuration is incorrect\n");
            printf("    - Network permission not granted\n");
            printf("  Solutions:\n");
            printf("    1. Check device network status\n");
            printf("    2. Verify network permissions in app config\n");
            printf("    3. Implement retry mechanism with delay\n");
            break;
            
        case RCP_ERROR_MEMORY_ALLOCATION:
            printf("  Type: Resource Error\n");
            printf("  Detail: Memory allocation failed\n");
            printf("  Possible Causes:\n");
            printf("    - System memory is insufficient\n");
            printf("    - Memory leak in application\n");
            printf("    - Large request body size\n");
            printf("  Solutions:\n");
            printf("    1. Free unused resources immediately\n");
            printf("    2. Implement memory monitoring\n");
            printf("    3. Reduce request size or buffer size\n");
            break;
            
        case RCP_ERROR_TIMEOUT:
            printf("  Type: Timeout Error\n");
            printf("  Detail: Operation timed out\n");
            printf("  Possible Causes:\n");
            printf("    - Network latency is high\n");
            printf("    - Server response is slow\n");
            printf("    - Timeout configuration is too short\n");
            printf("  Solutions:\n");
            printf("    1. Increase timeout in request configuration\n");
            printf("    2. Check server status\n");
            printf("    3. Implement timeout handling logic\n");
            break;
            
        case RCP_ERROR_CANCELED:
            printf("  Type: Cancel Error (Expected)\n");
            printf("  Detail: Request was canceled\n");
            printf("  Note: This is expected if cancellation was requested\n");
            printf("  Solutions:\n");
            printf("    1. Mark request as canceled in application state\n");
            printf("    2. Update UI to reflect cancellation\n");
            printf("    3. Optionally retry request if needed\n");
            break;
            
        default:
            printf("  Type: Unknown Error\n");
            printf("  Detail: Unrecognized error code\n");
            printf("  Solutions:\n");
            printf("    1. Check API documentation for error code %u\n", errCode);
            printf("    2. Report issue to SDK support\n");
            printf("    3. Implement generic error handling\n");
            break;
    }
    
    return -1;
}

/**
 * @brief 资源状态验证函数
 * @param session 会话对象
 * @param request 请求对象
 * @return true表示状态正常, false表示状态异常
 */
bool ValidateResourceState(Rcp_Session *session, Rcp_Request *request)
{
    printf("Validating resource state...\n");
    
    if (session == NULL) {
        printf("  [FAIL] Session is NULL\n");
        return false;
    }
    printf("  [OK] Session is valid\n");
    
    if (request == NULL) {
        printf("  [FAIL] Request is NULL\n");
        return false;
    }
    printf("  [OK] Request is valid\n");
    
    if (!g_state.sessionActive) {
        printf("  [WARN] Session state flag is inactive\n");
        return false;
    }
    
    if (!g_state.requestActive) {
        printf("  [WARN] Request state flag is inactive\n");
        return false;
    }
    
    printf("  [OK] All resources validated successfully\n");
    return true;
}

/**
 * @brief 降级处理策略1:重试机制
 * @param session 会话对象
 * @param request 请求对象
 * @param maxRetries 最大重试次数
 * @return 0表示成功, -1表示失败
 */
int Fallback_Retry(Rcp_Session *session, Rcp_Request *request, int maxRetries)
{
    printf("\n[Fallback Strategy 1: Retry Mechanism]\n");
    
    uint32_t errCode = 0;
    Rcp_ResponseCallbackObject callback = {NULL, NULL};
    
    for (int i = 0; i < maxRetries; i++) {
        printf("Retry attempt %d/%d\n", i + 1, maxRetries);
        
        // 发送请求
        errCode = HMS_Rcp_Fetch(session, request, &callback);
        
        if (errCode == 0) {
            printf("Retry successful\n");
            return 0;
        }
        
        EnhancedHandleError(errCode, "Retry Fetch", "Attempting to resend request");
        
        // 如果是网络错误,等待后重试
        if (errCode == RCP_ERROR_NETWORK_UNAVAILABLE) {
            printf("Network unavailable, waiting before retry...\n");
            sleep(2); // 等待2秒
        }
        
        // 如果是参数错误,不重试
        if (errCode <= RCP_ERROR_REQUEST_NOT_FOUND) {
            printf("Parameter error, stopping retry\n");
            break;
        }
    }
    
    printf("All retry attempts failed\n");
    return -1;
}

/**
 * @brief 降级处理策略2:会话重建
 * @param oldSession 原会话对象(将被关闭)
 * @return 新会话对象指针,失败返回NULL
 */
Rcp_Session* Fallback_RecreateSession(Rcp_Session *oldSession)
{
    printf("\n[Fallback Strategy 2: Session Recreation]\n");
    
    uint32_t errCode = 0;
    
    // 关闭旧会话
    if (oldSession != NULL) {
        printf("Closing old session...\n");
        errCode = HMS_Rcp_CloseSession(&oldSession);
        EnhancedHandleError(errCode, "Close old session", "Cleanup before recreation");
        g_state.sessionActive = false;
    }
    
    // 创建新会话
    printf("Creating new session...\n");
    Rcp_Session *newSession = HMS_Rcp_CreateSession(NULL, &errCode);
    
    if (newSession == NULL || errCode != 0) {
        EnhancedHandleError(errCode, "Create new session", "Session recreation failed");
        return NULL;
    }
    
    g_state.sessionActive = true;
    printf("Session recreation successful\n");
    return newSession;
}

/**
 * @brief 降级处理策略3:等待超时
 * @param waitTimeMs 等待时间(毫秒)
 * @return 0表示完成等待
 */
int Fallback_WaitTimeout(int waitTimeMs)
{
    printf("\n[Fallback Strategy 3: Wait Timeout]\n");
    printf("Waiting %d milliseconds for natural completion or timeout...\n", waitTimeMs);
    
    usleep(waitTimeMs * 1000);
    
    printf("Wait completed\n");
    return 0;
}

/**
 * @brief 综合降级处理函数
 * @param session 会话对象
 * @param request 请求对象
 * @param errCode 初始错误码
 */
void ComprehensiveFallback(Rcp_Session **session, Rcp_Request *request, uint32_t errCode)
{
    printf("\n========== Comprehensive Fallback Handling ==========\n");
    printf("Initial error: %u\n", errCode);
    
    // 根据错误类型选择降级策略
    switch (errCode) {
        case RCP_ERROR_NETWORK_UNAVAILABLE:
            printf("Network error detected, applying retry strategy\n");
            Fallback_Retry(*session, request, 3);
            break;
            
        case RCP_ERROR_SESSION_CLOSED:
            printf("Session closed, applying recreation strategy\n");
            *session = Fallback_RecreateSession(*session);
            if (*session != NULL) {
                // 使用新会话重试请求
                Fallback_Retry(*session, request, 1);
            }
            break;
            
        case RCP_ERROR_MEMORY_ALLOCATION:
            printf("Memory error, freeing resources\n");
            // 清理资源并等待
            if (request != NULL) {
                HMS_Rcp_DestroyRequest(request);
                g_state.requestActive = false;
            }
            Fallback_WaitTimeout(1000);
            break;
            
        case RCP_ERROR_TIMEOUT:
            printf("Timeout error, applying wait strategy\n");
            Fallback_WaitTimeout(5000);
            break;
            
        case RCP_ERROR_INVALID_PARAM:
        case RCP_ERROR_REQUEST_NOT_FOUND:
            printf("Parameter error, no fallback available\n");
            printf("Please fix application code and restart\n");
            break;
            
        case RCP_ERROR_CANCELED:
            printf("Request canceled, this is expected behavior\n");
            g_state.canceledCount++;
            break;
            
        default:
            printf("Unknown error, applying generic fallback\n");
            // 依次尝试各种策略
            if (Fallback_Retry(*session, request, 1) != 0) {
                *session = Fallback_RecreateSession(*session);
                if (*session != NULL) {
                    Fallback_Retry(*session, request, 1);
                }
            }
            break;
    }
    
    printf("Fallback handling completed\n");
}

/**
 * @brief 演示各种错误场景的处理
 */
void DemonstrateErrorHandling()
{
    printf("\n========== Error Handling Demonstration ==========\n");
    
    uint32_t errCode = 0;
    Rcp_Session *session = NULL;
    Rcp_Request *request = NULL;
    
    // 场景1: 网络不可用错误
    printf("\n--- Scenario 1: Network Unavailable ---\n");
    session = HMS_Rcp_CreateSession(NULL, &errCode);
    request = HMS_Rcp_CreateRequest("http://invalid.url/test");
    
    g_state.sessionActive = true;
    g_state.requestActive = true;
    
    // 模拟网络错误(通过无效URL)
    Rcp_ResponseCallbackObject callback = {NULL, NULL};
    errCode = HMS_Rcp_Fetch(session, request, &callback);
    
    if (errCode != 0) {
        ComprehensiveFallback(&session, request, errCode);
    }
    
    // 清理资源
    if (request) HMS_Rcp_DestroyRequest(request);
    if (session) HMS_Rcp_CloseSession(&session);
    g_state.sessionActive = false;
    g_state.requestActive = false;
    
    // 场景2: 会话已关闭错误
    printf("\n--- Scenario 2: Session Closed ---\n");
    session = HMS_Rcp_CreateSession(NULL, &errCode);
    request = HMS_Rcp_CreateRequest("http://www.example.com/test");
    
    g_state.sessionActive = true;
    g_state.requestActive = true;
    
    // 立即关闭会话
    HMS_Rcp_CloseSession(&session);
    g_state.sessionActive = false;
    
    // 尝试在关闭的会话上操作(会返回错误)
    errCode = HMS_Rcp_CancelSession(session);
    
    if (errCode != 0) {
        ComprehensiveFallback(&session, request, errCode);
    }
    
    if (request) HMS_Rcp_DestroyRequest(request);
    g_state.requestActive = false;
    
    // 场景3: 参数无效错误
    printf("\n--- Scenario 3: Invalid Parameters ---\n");
    session = HMS_Rcp_CreateSession(NULL, &errCode);
    g_state.sessionActive = true;
    
    // 尝试取消NULL请求
    errCode = HMS_Rcp_CancelRequest(session, NULL);
    
    if (errCode != 0) {
        EnhancedHandleError(errCode, "Cancel NULL request", "Testing parameter validation");
    }
    
    if (session) HMS_Rcp_CloseSession(&session);
    g_state.sessionActive = false;
    
    printf("\n========================================\n");
    printf("Error handling demonstration completed\n");
    printf("Total requests: %d\n", g_state.requestCount);
    printf("Canceled requests: %d\n", g_state.canceledCount);
    printf("========================================\n");
}

/**
 * @brief 主函数
 */
int main()
{
    printf("========================================\n");
    printf("Error Handling and Fallback Examples\n");
    printf("========================================\n");
    
    DemonstrateErrorHandling();
    
    return 0;
}