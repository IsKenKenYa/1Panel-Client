#include "RemoteCommunicationKit/rcp.h"
#include <cstring>
#include <stdio.h>
#include <unistd.h>

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
    const char *kHttpServerAddress = "https://www.example.com";
    uint32_t errCode = 0;
    
    Rcp_Configuration config;
    memset(&config, 0, sizeof(Rcp_Configuration));
    config.transferConfiguration.autoRedirect = true;
    config.transferConfiguration.timeout.transferMs = 10000;
    config.transferConfiguration.timeout.connectMs = 10000;
    
    Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
    if (request == NULL) {
        printf("Failed to create request\n");
        return -1;
    }
    
    request->method = RCP_METHOD_GET;
    request->configuration = &config;
    
    Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
    if (session == NULL || errCode != 0) {
        printf("Failed to create session, errCode: %u\n", errCode);
        HMS_Rcp_DestroyRequest(request);
        return -1;
    }
    
    Rcp_ResponseCallbackObject responseCallback = {ResponseCallback, NULL};
    errCode = HMS_Rcp_Fetch(session, request, &responseCallback);
    if (errCode != 0) {
        printf("Failed to fetch, errCode: %u\n", errCode);
    }
    
    usleep(3000000);
    printf("Fetch completed, errCode: %u\n", errCode);
    
    errCode = HMS_Rcp_CancelSession(session);
    HMS_Rcp_DestroyRequest(request);
    errCode = HMS_Rcp_CloseSession(&session);
    
    return 0;
}