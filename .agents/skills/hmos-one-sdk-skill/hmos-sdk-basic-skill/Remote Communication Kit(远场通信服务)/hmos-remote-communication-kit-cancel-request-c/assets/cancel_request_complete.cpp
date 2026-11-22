/**
 * @file cancel_request_complete.cpp
 * @brief 完整的取消网络请求示例代码(C++)
 * @version 1.0
 * @date 2026-07-03
 * 
 * 本示例展示如何使用Remote Communication Kit C API:
 * 1. 创建HTTP请求对象
 * 2. 创建会话对象
 * 3. 发送异步HTTP请求
 * 4. 取消单个请求(HMS_Rcp_CancelRequest)
 * 5. 取消会话的所有请求(HMS_Rcp_CancelSession)
 * 6. 清理资源(销毁请求对象和关闭会话)
 */

#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

// 定义请求状态标志
volatile bool requestCompleted = false;
volatile bool requestCanceled = false;

/**
 * @brief HTTP响应回调函数
 * @param usrCtx 用户上下文指针
 * @param response 响应对象指针
 * @param errCode 错误码
 */
void ResponseCallback(void *usrCtx, Rcp_Response *response, uint32_t errCode)
{
    (void *)usrCtx; // 未使用的参数
    
    if (errCode != 0) {
        printf("Request failed with error code: %u\n", errCode);
        if (errCode == RCP_ERROR_CANCELED) {
            printf("Request was canceled\n");
            requestCanceled = true;
        }
    } else if (response != NULL) {
        printf("Response received:\n");
        printf("  Status Code: %d\n", response->statusCode);
        
        // 打印响应头信息
        if (response->headers != NULL) {
            Rcp_HeaderEntry *entries = HMS_Rcp_GetHeaderEntries(response->headers);
            if (entries != NULL) {
                printf("  Headers:\n");
                for (int i = 0; entries[i].name != NULL; i++) {
                    printf("    %s: %s\n", entries[i].name, entries[i].value);
                }
                HMS_Rcp_DestroyHeaderEntries(entries);
            }
        }
        
        // 打印响应内容(如果有)
        if (response->body != NULL && response->body->buffer != NULL) {
            printf("  Body Length: %zu bytes\n", response->body->length);
            printf("  Body Content: %.*s\n", (int)response->body->length, response->body->buffer);
        }
        
        requestCompleted = true;
        
        // 销毁响应对象
        response->destroyResponse(response);
    }
}

/**
 * @brief 错误处理函数
 * @param errCode 错误码
 * @param operation 操作名称
 */
void HandleError(uint32_t errCode, const char *operation)
{
    if (errCode == 0) {
        printf("[SUCCESS] %s completed successfully\n", operation);
        return;
    }
    
    printf("[ERROR] %s failed with error code: %u\n", operation, errCode);
    
    // 根据错误码输出具体原因
    switch (errCode) {
        case RCP_ERROR_INVALID_PARAM:
            printf("  Reason: Invalid parameter\n");
            printf("  Solution: Check if session/request pointers are valid\n");
            break;
        case RCP_ERROR_SESSION_CLOSED:
            printf("  Reason: Session is closed\n");
            printf("  Solution: Create a new session before making requests\n");
            break;
        case RCP_ERROR_REQUEST_NOT_FOUND:
            printf("  Reason: Request not found in session\n");
            printf("  Solution: Ensure request is added to session and not destroyed\n");
            break;
        case RCP_ERROR_NETWORK_UNAVAILABLE:
            printf("  Reason: Network unavailable\n");
            printf("  Solution: Check network connectivity\n");
            break;
        case RCP_ERROR_MEMORY_ALLOCATION:
            printf("  Reason: Memory allocation failed\n");
            printf("  Solution: Free unused resources or increase memory\n");
            break;
        case RCP_ERROR_TIMEOUT:
            printf("  Reason: Operation timeout\n");
            printf("  Solution: Increase timeout or check network latency\n");
            break;
        case RCP_ERROR_CANCELED:
            printf("  Reason: Request was canceled\n");
            printf("  Solution: This is expected if cancellation was requested\n");
            break;
        default:
            printf("  Reason: Unknown error\n");
            printf("  Solution: Check documentation for error code %u\n", errCode);
            break;
    }
}

/**
 * @brief 示例1:取消单个请求
 */
int Example_CancelSingleRequest()
{
    printf("\n========== Example 1: Cancel Single Request ==========\n");
    
    uint32_t errCode = 0;
    Rcp_Session *session = NULL;
    Rcp_Request *request = NULL;
    
    // 步骤1: 创建请求对象
    const char *url = "http://www.example.com/api/data";
    printf("Step 1: Creating request for URL: %s\n", url);
    request = HMS_Rcp_CreateRequest(url);
    if (request == NULL) {
        HandleError(RCP_ERROR_MEMORY_ALLOCATION, "Create request");
        return -1;
    }
    request->method = RCP_METHOD_GET;
    
    // 步骤2: 创建会话对象
    printf("Step 2: Creating session\n");
    session = HMS_Rcp_CreateSession(NULL, &errCode);
    HandleError(errCode, "Create session");
    if (session == NULL || errCode != 0) {
        HMS_Rcp_DestroyRequest(request);
        return -1;
    }
    
    // 步骤3: 发送异步请求
    printf("Step 3: Sending async fetch request\n");
    Rcp_ResponseCallbackObject callback = {ResponseCallback, NULL};
    errCode = HMS_Rcp_Fetch(session, request, &callback);
    HandleError(errCode, "Fetch request");
    if (errCode != 0) {
        HMS_Rcp_DestroyRequest(request);
        HMS_Rcp_CloseSession(&session);
        return -1;
    }
    
    // 步骤4: 等待一小段时间后取消请求(模拟用户取消操作)
    printf("Step 4: Waiting 100ms before canceling...\n");
    usleep(100000); // 等待100ms
    
    // 步骤5: 取消单个请求
    printf("Step 5: Canceling the request\n");
    errCode = HMS_Rcp_CancelRequest(session, request);
    HandleError(errCode, "Cancel request");
    
    // 步骤6: 等待回调完成
    printf("Step 6: Waiting for callback...\n");
    usleep(200000); // 等待200ms
    
    // 步骤7: 清理资源
    printf("Step 7: Cleaning up resources\n");
    if (request != NULL) {
        HMS_Rcp_DestroyRequest(request);
        request = NULL;
    }
    
    if (session != NULL) {
        errCode = HMS_Rcp_CloseSession(&session);
        HandleError(errCode, "Close session");
        session = NULL;
    }
    
    printf("Request state: completed=%d, canceled=%d\n", requestCompleted, requestCanceled);
    
    return 0;
}

/**
 * @brief 示例2:取消会话的所有请求
 */
int Example_CancelSession()
{
    printf("\n========== Example 2: Cancel Session (All Requests) ==========\n");
    
    uint32_t errCode = 0;
    Rcp_Session *session = NULL;
    Rcp_Request *request1 = NULL;
    Rcp_Request *request2 = NULL;
    
    // 步骤1: 创建多个请求对象
    printf("Step 1: Creating multiple requests\n");
    request1 = HMS_Rcp_CreateRequest("http://www.example.com/api/data1");
    request2 = HMS_Rcp_CreateRequest("http://www.example.com/api/data2");
    
    if (request1 == NULL || request2 == NULL) {
        HandleError(RCP_ERROR_MEMORY_ALLOCATION, "Create requests");
        if (request1) HMS_Rcp_DestroyRequest(request1);
        if (request2) HMS_Rcp_DestroyRequest(request2);
        return -1;
    }
    
    request1->method = RCP_METHOD_GET;
    request2->method = RCP_METHOD_POST;
    
    // 步骤2: 创建会话对象
    printf("Step 2: Creating session\n");
    session = HMS_Rcp_CreateSession(NULL, &errCode);
    HandleError(errCode, "Create session");
    if (session == NULL || errCode != 0) {
        HMS_Rcp_DestroyRequest(request1);
        HMS_Rcp_DestroyRequest(request2);
        return -1;
    }
    
    // 步骤3: 发送多个异步请求
    printf("Step 3: Sending multiple async fetch requests\n");
    Rcp_ResponseCallbackObject callback = {ResponseCallback, NULL};
    
    errCode = HMS_Rcp_Fetch(session, request1, &callback);
    HandleError(errCode, "Fetch request 1");
    
    errCode = HMS_Rcp_Fetch(session, request2, &callback);
    HandleError(errCode, "Fetch request 2");
    
    // 步骤4: 等待一小段时间
    printf("Step 4: Waiting 100ms before canceling session...\n");
    usleep(100000);
    
    // 步骤5: 取消会话的所有请求
    printf("Step 5: Canceling all requests in session\n");
    errCode = HMS_Rcp_CancelSession(session);
    HandleError(errCode, "Cancel session");
    
    // 步骤6: 等待回调完成
    printf("Step 6: Waiting for callbacks...\n");
    usleep(200000);
    
    // 步骤7: 清理资源
    printf("Step 7: Cleaning up resources\n");
    HMS_Rcp_DestroyRequest(request1);
    HMS_Rcp_DestroyRequest(request2);
    
    errCode = HMS_Rcp_CloseSession(&session);
    HandleError(errCode, "Close session");
    
    return 0;
}

/**
 * @brief 示例3:错误处理和降级方案
 */
int Example_ErrorHandling()
{
    printf("\n========== Example 3: Error Handling and Fallback ==========\n");
    
    uint32_t errCode = 0;
    Rcp_Session *session = NULL;
    Rcp_Request *request = NULL;
    
    // 创建请求和会话
    request = HMS_Rcp_CreateRequest("http://www.example.com/test");
    session = HMS_Rcp_CreateSession(NULL, &errCode);
    
    if (request == NULL || session == NULL) {
        printf("Failed to create request or session\n");
        if (request) HMS_Rcp_DestroyRequest(request);
        if (session) HMS_Rcp_CloseSession(&session);
        return -1;
    }
    
    request->method = RCP_METHOD_DELETE;
    
    // 发送请求
    Rcp_ResponseCallbackObject callback = {ResponseCallback, NULL};
    errCode = HMS_Rcp_Fetch(session, request, &callback);
    
    if (errCode != 0) {
        printf("Fetch failed, implementing fallback strategy\n");
        
        // 降级方案1: 尝试取消请求
        errCode = HMS_Rcp_CancelRequest(session, request);
        if (errCode != 0) {
            printf("Cancel request failed, trying session cancel\n");
            
            // 降级方案2: 取消整个会话
            errCode = HMS_Rcp_CancelSession(session);
            if (errCode != 0) {
                printf("Session cancel failed, waiting for timeout\n");
                // 降级方案3: 等待请求自然完成或超时
                usleep(1000000);
            }
        }
    }
    
    // 清理资源
    HMS_Rcp_DestroyRequest(request);
    HMS_Rcp_CloseSession(&session);
    
    return 0;
}

/**
 * @brief 主函数
 */
int main()
{
    printf("========================================\n");
    printf("Remote Communication Kit - Cancel Request Examples\n");
    printf("API Version: 5.0.0(12)\n");
    printf("========================================\n");
    
    // 重置状态标志
    requestCompleted = false;
    requestCanceled = false;
    
    // 执行示例1:取消单个请求
    Example_CancelSingleRequest();
    
    // 重置状态标志
    requestCompleted = false;
    requestCanceled = false;
    
    // 执行示例2:取消会话的所有请求
    Example_CancelSession();
    
    // 执行示例3:错误处理和降级方案
    Example_ErrorHandling();
    
    printf("\n========================================\n");
    printf("All examples completed\n");
    printf("========================================\n");
    
    return 0;
}