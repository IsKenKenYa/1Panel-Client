import com.fasterxml.jackson.databind.ObjectMapper;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;

public class AttributionPostbackController {
    
    private static final ConcurrentHashMap<String, AttributionPostbackResponse> 
        processedRequests = new ConcurrentHashMap<>();
    
    private AttributionPostbackHandler handler = new AttributionPostbackHandler();
    private ObjectMapper objectMapper = new ObjectMapper();
    
    public void handlePostback(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        
        try {
            if (!"POST".equalsIgnoreCase(request.getMethod())) {
                sendErrorResponse(response, HttpServletResponse.SC_METHOD_NOT_ALLOWED, 
                    "METHOD_NOT_ALLOWED", "Only POST method is supported");
                return;
            }
            
            String contentType = request.getContentType();
            if (contentType == null || !contentType.contains("application/json")) {
                sendErrorResponse(response, HttpServletResponse.SC_UNSUPPORTED_MEDIA_TYPE, 
                    "UNSUPPORTED_MEDIA_TYPE", "Content-Type must be application/json");
                return;
            }
            
            AttributionPostbackRequest postbackRequest = objectMapper.readValue(
                request.getInputStream(), 
                AttributionPostbackRequest.class
            );
            
            handler.validateRequiredFields(postbackRequest);
            
            AttributionPostbackResponse cachedResponse = 
                processedRequests.get(postbackRequest.getTransactionId());
            if (cachedResponse != null) {
                sendSuccessResponse(response, cachedResponse);
                return;
            }
            
            handler.validateTimestamp(postbackRequest.getTimestamp());
            
            boolean isValid = handler.verifySignature(postbackRequest);
            
            if (!isValid) {
                sendErrorResponse(response, HttpServletResponse.SC_OK, 
                    "SIGNATURE_INVALID", "Signature verification failed");
                return;
            }
            
            processBusinessLogic(postbackRequest);
            
            AttributionPostbackResponse successResponse = new AttributionPostbackResponse();
            successResponse.setResultCode("0");
            successResponse.setResultDesc("Success.");
            
            processedRequests.put(postbackRequest.getTransactionId(), successResponse);
            sendSuccessResponse(response, successResponse);
            
        } catch (AttributionException e) {
            sendErrorResponse(response, HttpServletResponse.SC_OK, 
                "PROCESSING_ERROR", e.getMessage());
        } catch (Exception e) {
            sendErrorResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, 
                "INTERNAL_ERROR", "Internal server error: " + e.getMessage());
        }
    }
    
    private void processBusinessLogic(AttributionPostbackRequest request) {
        if (request.getTriggerData() != null) {
            if (request.getTriggerData() >= 1 && request.getTriggerData() <= 200) {
                System.out.println("Processing standard conversion event: " + 
                    request.getTriggerData());
            } else if (request.getTriggerData() >= 501 && request.getTriggerData() <= 600) {
                System.out.println("Processing custom conversion event: " + 
                    request.getTriggerData());
            }
        }
    }
    
    private void sendSuccessResponse(HttpServletResponse response, 
            AttributionPostbackResponse postbackResponse) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().write(objectMapper.writeValueAsString(postbackResponse));
    }
    
    private void sendErrorResponse(HttpServletResponse response, int statusCode, 
            String code, String message) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(statusCode);
        
        AttributionPostbackResponse errorResponse = new AttributionPostbackResponse();
        errorResponse.setResultCode(code);
        errorResponse.setResultDesc(message);
        
        response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
    }
}