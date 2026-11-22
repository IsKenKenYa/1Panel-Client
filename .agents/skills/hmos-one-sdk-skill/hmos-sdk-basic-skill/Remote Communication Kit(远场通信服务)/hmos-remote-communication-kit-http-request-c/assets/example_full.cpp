#include "RemoteCommunicationKit/rcp.h"
#include <cstdlib>
#include <cstring>
#include <stdio.h>
#include <unistd.h>
#include <thread>

void ResponseCallback(void *usrCtx, Rcp_Response *response, uint32_t errCode) {
    (void)usrCtx;
    if (response != NULL) {
        printf("Response status: %d\n", response->statusCode);
        
        if (response->headers != NULL) {
            printf("Response headers:\n");
        }
        
        if (response->content != NULL) {
            if (response->content->type == RCP_CONTENT_TYPE_STRING &&
                response->content->data.contentStr.buffer != NULL) {
                printf("Response content (string): %s\n", 
                       response->content->data.contentStr.buffer);
            } else if (response->content->type == RCP_CONTENT_TYPE_BUFFER &&
                       response->content->data.contentBuf.buffer != NULL) {
                printf("Response content (buffer): length=%u\n", 
                       response->content->data.contentBuf.length);
            }
        }
        
        response->destroyResponse(response);
    } else {
        printf("Fetch failed, errCode: %u\n", errCode);
        
        switch (errCode) {
            case 1007900001:
                printf("Session not found\n");
                break;
            case 1007900002:
                printf("Request not found\n");
                break;
            case 1007900003:
                printf("URL format error\n");
                break;
            case 1007900004:
                printf("Network error\n");
                break;
            case 1007900005:
                printf("DNS resolution failed\n");
                break;
            case 1007900006:
                printf("Connection timeout\n");
                break;
            case 1007900007:
                printf("Transfer timeout\n");
                break;
            default:
                printf("Unknown error\n");
        }
    }
}

int main() {
    const char *kHttpServerAddress = "https://www.example.com/api";
    const char *requestBody = "{\"action\":\"test\"}";
    uint32_t errCode = 0;
    
    printf("=== Step 1: Create Request ===\n");
    Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
    if (request == NULL) {
        printf("Failed to create request\n");
        return -1;
    }
    printf("Request created successfully\n");
    
    printf("=== Step 2: Configure Request ===\n");
    request->method = RCP_METHOD_POST;
    
    request->content = (Rcp_RequestContent *)calloc(1, sizeof(Rcp_RequestContent));
    if (request->content == NULL) {
        printf("Failed to allocate content\n");
        HMS_Rcp_DestroyRequest(request);
        return -1;
    }
    request->content->type = RCP_CONTENT_TYPE_STRING;
    request->content->data.contentStr.buffer = requestBody;
    request->content->data.contentStr.length = strlen(requestBody);
    
    Rcp_Configuration config;
    memset(&config, 0, sizeof(Rcp_Configuration));
    config.transferConfiguration.autoRedirect = true;
    config.transferConfiguration.timeout.transferMs = 10000;
    config.transferConfiguration.timeout.connectMs = 10000;
    request->configuration = &config;
    
    printf("Request configured: method=POST, timeout=10s\n");
    
    printf("=== Step 3: Create Session ===\n");
    Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
    if (session == NULL || errCode != 0) {
        printf("Failed to create session, errCode: %u\n", errCode);
        free(request->content);
        HMS_Rcp_DestroyRequest(request);
        return -1;
    }
    printf("Session created successfully\n");
    
    printf("=== Step 4: Send Async Request ===\n");
    Rcp_ResponseCallbackObject responseCallback = {ResponseCallback, NULL};
    errCode = HMS_Rcp_Fetch(session, request, &responseCallback);
    if (errCode != 0) {
        printf("Failed to fetch, errCode: %u\n", errCode);
        free(request->content);
        HMS_Rcp_DestroyRequest(request);
        HMS_Rcp_CloseSession(&session);
        return -1;
    }
    printf("Request sent, waiting for response...\n");
    
    std::this_thread::sleep_for(std::chrono::milliseconds(3000));
    
    printf("=== Step 5: Cleanup Resources ===\n");
    errCode = HMS_Rcp_CancelSession(session);
    if (errCode != 0) {
        printf("Cancel session warning, errCode: %u\n", errCode);
    }
    
    if (request->content != NULL) {
        free(request->content);
    }
    HMS_Rcp_DestroyRequest(request);
    
    errCode = HMS_Rcp_CloseSession(&session);
    if (errCode != 0) {
        printf("Close session warning, errCode: %u\n", errCode);
    } else {
        printf("Session closed successfully\n");
    }
    
    printf("=== Complete ===\n");
    return 0;
}