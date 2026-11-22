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
        if (response->content != NULL && 
            response->content->data.contentStr.buffer != NULL) {
            printf("Response content: %s\n", 
                   response->content->data.contentStr.buffer);
        }
        response->destroyResponse(response);
    } else {
        printf("Fetch failed, errCode: %u\n", errCode);
    }
}

int main() {
    const char *kHttpServerAddress = "http://www.example.com";
    const char *content = "{\"update\":\"data\"}";
    uint32_t errCode = 0;
    
    Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
    if (request == NULL) {
        printf("Failed to create request\n");
        return -1;
    }
    
    request->method = RCP_METHOD_PUT;
    request->content = (Rcp_RequestContent *)calloc(1, sizeof(Rcp_RequestContent));
    request->content->type = RCP_CONTENT_TYPE_STRING;
    request->content->data.contentStr.buffer = content;
    request->content->data.contentStr.length = strlen(content);
    
    Rcp_Configuration config;
    memset(&config, 0, sizeof(Rcp_Configuration));
    config.transferConfiguration.autoRedirect = true;
    config.transferConfiguration.timeout.transferMs = 10000;
    config.transferConfiguration.timeout.connectMs = 10000;
    request->configuration = &config;
    
    Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
    if (session == NULL || errCode != 0) {
        printf("Failed to create session, errCode: %u\n", errCode);
        free(request->content);
        HMS_Rcp_DestroyRequest(request);
        return -1;
    }
    
    Rcp_ResponseCallbackObject responseCallback = {ResponseCallback, NULL};
    errCode = HMS_Rcp_Fetch(session, request, &responseCallback);
    if (errCode != 0) {
        printf("Failed to fetch, errCode: %u\n", errCode);
    }
    
    std::this_thread::sleep_for(std::chrono::milliseconds(3000));
    printf("Fetch completed, errCode: %u\n", errCode);
    
    errCode = HMS_Rcp_CancelSession(session);
    free(request->content);
    HMS_Rcp_DestroyRequest(request);
    errCode = HMS_Rcp_CloseSession(&session);
    
    return 0;
}