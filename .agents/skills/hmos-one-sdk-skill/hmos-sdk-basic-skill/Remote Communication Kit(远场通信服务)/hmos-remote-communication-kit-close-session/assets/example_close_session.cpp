/**
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @file example_close_session.cpp
 * @brief 关闭HTTP会话完整示例代码
 * 
 * 功能说明：
 * - 创建HTTP会话
 * - 发起异步GET请求
 * - 接收响应数据
 * - 取消可能还在执行的请求
 * - 关闭会话释放资源
 * - 销毁request对象
 * 
 * 使用场景：
 * - HTTP请求完成后清理资源
 * - 防止资源泄漏
 * - 保持系统健康和高效运行
 */

#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>
#include <unistd.h>
#include <string.h>

/**
 * @brief 响应回调函数
 * @param usrCtx 用户上下文（可选）
 * @param response 响应对象
 * @param errCode 错误码
 */
void ResponseCallback(void *usrCtx, Rcp_Response *response, uint32_t errCode) {
    (void *)usrCtx; // 未使用的参数
    
    if (response != NULL) {
        printf("Response received, status code: %d\n", response->statusCode);
        
        // 打印响应头信息
        if (response->headers != NULL) {
            Rcp_HeaderEntry *entries = HMS_Rcp_GetHeaderEntries(response->headers);
            if (entries != NULL) {
                printf("Response headers:\n");
                // 注意：实际应用中需要遍历entries数组
                HMS_Rcp_DestroyHeaderEntries(entries);
            }
        }
        
        // 销毁响应对象
        response->destroyResponse(response);
    } else {
        printf("Request failed, errCode: %u\n", errCode);
    }
}

/**
 * @brief 安全关闭会话的函数
 * @param session 会话指针的指针
 * @param request 请求对象指针
 */
void SafeCloseSession(Rcp_Session **session, Rcp_Request *request) {
    if (session == NULL || *session == NULL) {
        printf("Warning: Session pointer is NULL, skip close operation\n");
        return;
    }
    
    printf("Starting session close process...\n");
    
    // 步骤1：取消可能还在执行的请求
    uint32_t errCode = HMS_Rcp_CancelSession(*session);
    if (errCode != 0) {
        printf("Warning: Cancel session failed, errCode: %u (continue to close)\n", errCode);
    } else {
        printf("Session canceled successfully\n");
    }
    
    // 步骤2：关闭会话
    errCode = HMS_Rcp_CloseSession(session);
    if (errCode != 0) {
        printf("Error: Close session failed, errCode: %u\n", errCode);
        
        // 错误码处理
        switch (errCode) {
            case 1007900001:
                printf("Session internal error\n");
                break;
            case 1007900002:
                printf("Session not found\n");
                break;
            case 1007900003:
                printf("Session already closed\n");
                break;
            case 1007900004:
                printf("Invalid parameter\n");
                break;
            default:
                printf("Unknown error\n");
                break;
        }
    } else {
        printf("Session closed successfully\n");
        
        // 验证session指针已置空
        if (*session == NULL) {
            printf("Verification: Session pointer is NULL (closed)\n");
        }
    }
    
    // 步骤3：销毁request对象
    if (request != NULL) {
        HMS_Rcp_DestroyRequest(request);
        printf("Request destroyed successfully\n");
    }
    
    printf("Session close process completed\n");
}

/**
 * @brief 主函数 - 演示完整的会话关闭流程
 */
int main() {
    printf("=== HTTP Session Close Example ===\n\n");
    
    // 配置请求URL（请替换为实际URL）
    const char *kHttpServerAddress = "http://www.example.com";
    
    uint32_t errCode = 0;
    
    // 步骤1：创建请求对象
    printf("Step 1: Creating request...\n");
    Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
    if (request == NULL) {
        printf("Error: Failed to create request\n");
        return -1;
    }
    
    // 设置请求方法为GET
    request->method = RCP_METHOD_GET;
    printf("Request created, URL: %s, Method: GET\n", kHttpServerAddress);
    
    // 步骤2：创建会话
    printf("\nStep 2: Creating session...\n");
    Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
    if (session == NULL) {
        printf("Error: Failed to create session, errCode: %u\n", errCode);
        HMS_Rcp_DestroyRequest(request);
        return -1;
    }
    printf("Session created successfully\n");
    
    // 步骤3：配置响应回调
    printf("\nStep 3: Configuring response callback...\n");
    Rcp_ResponseCallbackObject responseCallback = {ResponseCallback, NULL};
    printf("Response callback configured\n");
    
    // 步骤4：发起异步请求
    printf("\nStep 4: Sending async request...\n");
    errCode = HMS_Rcp_Fetch(session, request, &responseCallback);
    if (errCode != 0) {
        printf("Error: Failed to send request, errCode: %u\n", errCode);
        SafeCloseSession(&session, request);
        return -1;
    }
    printf("Request sent successfully (async)\n");
    
    // 步骤5：等待响应
    printf("\nStep 5: Waiting for response (3 seconds)...\n");
    usleep(1000 * 1000 * 3);
    printf("Wait completed\n");
    
    // 步骤6：关闭会话（核心功能）
    printf("\nStep 6: Closing session...\n");
    SafeCloseSession(&session, request);
    
    // 步骤7：验证资源释放
    printf("\nStep 7: Verifying resource release...\n");
    if (session == NULL && request == NULL) {
        printf("Success: All resources released\n");
    } else {
        printf("Warning: Some resources may not be released\n");
        printf("  session: %p\n", session);
        printf("  request: %p\n", request);
    }
    
    printf("\n=== Example Completed ===\n");
    return 0;
}