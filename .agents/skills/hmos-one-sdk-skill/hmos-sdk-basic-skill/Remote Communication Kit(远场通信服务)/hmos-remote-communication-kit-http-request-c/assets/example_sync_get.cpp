#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>
#include <cstring>

int main() {
    const char *kHttpServerAddress = "https://www.example.com";
    uint32_t errCode = 0;
    
    Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
    if (request == NULL) {
        printf("Failed to create request\n");
        return -1;
    }
    
    request->method = RCP_METHOD_GET;
    
    Rcp_Configuration config;
    memset(&config, 0, sizeof(Rcp_Configuration));
    config.transferConfiguration.autoRedirect = true;
    config.transferConfiguration.timeout.transferMs = 10000;
    config.transferConfiguration.timeout.connectMs = 10000;
    request->configuration = &config;
    
    Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
    if (session == NULL || errCode != 0) {
        printf("Failed to create session, errCode: %u\n", errCode);
        HMS_Rcp_DestroyRequest(request);
        return -1;
    }
    
    Rcp_Response *response = HMS_Rcp_FetchSync(session, request, &errCode);
    if (response != NULL) {
        printf("Response status: %d\n", response->statusCode);
        if (response->content != NULL && 
            response->content->data.contentStr.buffer != NULL) {
            printf("Response content: %s\n", 
                   response->content->data.contentStr.buffer);
        }
    } else {
        printf("Fetch failed, errCode: %u\n", errCode);
    }
    
    HMS_Rcp_DestroyRequest(request);
    if (response != NULL) {
        response->destroyResponse(response);
    }
    
    errCode = HMS_Rcp_CloseSession(&session);
    if (errCode != 0) {
        printf("Failed to close session, errCode: %u\n", errCode);
    }
    
    return 0;
}