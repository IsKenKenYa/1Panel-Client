/**
 * @file example_cancel_request.cpp
 * @brief 取消网络请求完整示例代码
 * @details 展示如何使用HMS_Rcp_CancelRequest和HMS_Rcp_CancelSession取消HTTP请求
 */

#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>
#include <string.h>

/**
 * @brief 响应回调函数
 * @param usrCtx 用户上下文
 * @param response 响应对象
 * @param errCode 错误码
 */
void ResponseCallback(void *usrCtx, Rcp_Response *response, uint32_t errCode)
{
    (void *)usrCtx;  // 未使用的参数
    
    if (response != NULL) {
        printf("Response received - Status: %d\n", response->statusCode);
        
        // 处理响应内容（如果有）
        if (response->body != NULL) {
            printf("Response body length: %zu\n", response->body->length);
        }
        
        // 销毁响应对象
        response->destroyResponse(response);
    } else {
        // 处理错误情况
        printf("Fetch failed - Error code: %u\n", errCode);
        
        // 如果是取消导致的错误，特殊处理
        if (errCode == 1007900001) {
            printf("Request was canceled\n");
        }
    }
}

/**
 * @brief 处理取消请求的错误码
 * @param errCode 错误码
 * @return 错误说明字符串
 */
const char* GetErrorDescription(uint32_t errCode)
{
    switch (errCode) {
        case 0:
            return "Success";
        case 201:
            return "Permission denied - Check network permissions in module.json5";
        case 401:
            return "Parameter error - Invalid session or request object";
        case 1007900993:
            return "Session closed or invalid - Recreate the session";
        case 1007900001:
            return "Request canceled by user";
        default:
            return "Unknown error";
    }
}

/**
 * @brief 取消单个请求示例
 * @param session 会话对象
 * @param request 请求对象
 */
void CancelSingleRequestExample(Rcp_Session *session, Rcp_Request *request)
{
    printf("\n=== Cancel Single Request Example ===\n");
    
    uint32_t errCode = HMS_Rcp_CancelRequest(session, request);
    
    if (errCode == 0) {
        printf("Request canceled successfully\n");
    } else {
        printf("Failed to cancel request: %s (errCode: %u)\n", 
               GetErrorDescription(errCode), errCode);
    }
}

/**
 * @brief 取消会话全部请求示例
 * @param session 会话对象
 */
void CancelSessionExample(Rcp_Session *session)
{
    printf("\n=== Cancel Session Example ===\n");
    
    uint32_t errCode = HMS_Rcp_CancelSession(session);
    
    if (errCode == 0) {
        printf("Session canceled successfully - All requests stopped\n");
    } else {
        printf("Failed to cancel session: %s (errCode: %u)\n", 
               GetErrorDescription(errCode), errCode);
    }
}

/**
 * @brief 降级处理示例 - 取消失败时等待请求自然完成
 * @param session 会话对象
 * @param request 请求对象
 */
void FallbackCancelRequest(Rcp_Session *session, Rcp_Request *request)
{
    printf("\n=== Fallback Cancel Request Example ===\n");
    
    uint32_t errCode = HMS_Rcp_CancelRequest(session, request);
    
    if (errCode != 0) {
        printf("Cancel operation failed: %s\n", GetErrorDescription(errCode));
        
        // 降级策略：等待请求自然完成
        printf("Fallback: Waiting for request to complete naturally\n");
        printf("Warning: Request may continue running for some time\n");
        
        // 可选：直接关闭会话（如果业务允许）
        // errCode = HMS_Rcp_CloseSession(&session);
    } else {
        printf("Request canceled successfully\n");
    }
}

/**
 * @brief 主函数 - 完整的取消请求示例
 */
int main()
{
    printf("=== HarmonyOS Remote Communication Kit - Cancel Request Example ===\n\n");
    
    uint32_t errCode = 0;
    const char *kHttpServerAddress = "http://www.example.com/api/delete";
    
    // 步骤1：创建请求对象
    printf("Step 1: Creating request...\n");
    Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
    if (request == NULL) {
        printf("Failed to create request\n");
        return -1;
    }
    
    // 设置请求方法
    request->method = RCP_METHOD_DELETE;
    printf("Request created with URL: %s\n", kHttpServerAddress);
    
    // 步骤2：创建会话
    printf("\nStep 2: Creating session...\n");
    Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
    if (errCode != 0 || session == NULL) {
        printf("Failed to create session: %s (errCode: %u)\n", 
               GetErrorDescription(errCode), errCode);
        HMS_Rcp_DestroyRequest(request);
        return -1;
    }
    printf("Session created successfully\n");
    
    // 步骤3：配置请求回调
    printf("\nStep 3: Configuring response callback...\n");
    Rcp_ResponseCallbackObject responseCallback = {ResponseCallback, NULL};
    
    // 步骤4：发起异步请求
    printf("\nStep 4: Sending async request...\n");
    errCode = HMS_Rcp_Fetch(session, request, &responseCallback);
    if (errCode != 0) {
        printf("Failed to send request: %s (errCode: %u)\n", 
               GetErrorDescription(errCode), errCode);
        HMS_Rcp_DestroyRequest(request);
        HMS_Rcp_CloseSession(&session);
        return -1;
    }
    printf("Request sent successfully (async mode)\n");
    
    // 步骤5：取消指定请求
    CancelSingleRequestExample(session, request);
    
    // 步骤6：取消会话全部请求（可选）
    // CancelSessionExample(session);
    
    // 步骤7：降级处理示例（可选）
    // FallbackCancelRequest(session, request);
    
    // 步骤8：清理资源
    printf("\nStep 8: Cleaning up resources...\n");
    
    // 销毁请求对象
    HMS_Rcp_DestroyRequest(request);
    printf("Request destroyed\n");
    
    // 关闭会话
    errCode = HMS_Rcp_CloseSession(&session);
    if (errCode != 0) {
        printf("Failed to close session: %s (errCode: %u)\n", 
               GetErrorDescription(errCode), errCode);
    } else {
        printf("Session closed successfully\n");
    }
    
    printf("\n=== Example Complete ===\n");
    return 0;
}

/**
 * @brief 使用说明
 * 
 * 编译步骤：
 * 1. 确保已安装HarmonyOS SDK
 * 2. 在CMakeLists.txt中添加: target_link_libraries(your_target librcp_c.so)
 * 3. 在module.json5中添加网络权限: "ohos.permission.INTERNET"
 * 4. 编译并运行程序
 * 
 * 注意事项：
 * - 取消操作是异步的，可能需要等待回调确认
 * - 取消已完成请求会返回错误码
 * - 取消后可以继续使用会话（如果未关闭）
 * - 建议在取消后立即清理资源
 * 
 * 支持设备：
 * - Phone, 2in1, Tablet, Wearable (5.0.0+)
 * - TV (5.1.1(19)+)
 * - Car (6.1.0(23)+)
 */