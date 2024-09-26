/**
* @author TechMatrix Team
* @description Class for Payment Gateway Integration with Razorpay
*/
public class PaymentGatewayIntegration {
    // Constants for API endpoints and credentials
    private static final String ENDPOINT_PAYMENT_LINK = 'callout:RazorPay/v1/payment_links';
    
    /**
* @description Creates a payment link using Razorpay API
* @param amount The payment amount
* @param currencyType The currency code (e.g., 'INR')
* @param transactionName Reference ID for the transaction
* @param description Description of the payment
* @param customerName Name of the customer
* @param customerEmail Email of the customer
* @param customerPhone Phone number of the customer
* @return ApiResponse containing the result of the operation
*/
    public static ApiResponse createPaymentLink(Decimal amount, String currencyType, String transactionName, 
                                                String description, String customerName, String customerEmail, 
                                                String customerPhone) {
                                                    try {
                                                        // Generate JSON body for the API request
                                                        ApiResponse jsonBodyResponse = generateJsonBody(amount, currencyType, transactionName, description, 
                                                                                                        customerName, customerEmail, customerPhone);
                                                        if (!jsonBodyResponse.isSuccess) {
                                                            return jsonBodyResponse;
                                                        }
                                                        
                                                        // Make the API call
                                                        ApiResponse apiCallResponse = makeHttpRequest(jsonBodyResponse.message, ENDPOINT_PAYMENT_LINK, 'POST');
                                                        if (!apiCallResponse.isSuccess) {
                                                            return apiCallResponse;
                                                        }
                                                        
                                                        // Parse the successful response
                                                        RazorpayPaymentLinkResponse paymentLinkResponse = (RazorpayPaymentLinkResponse)JSON.deserialize(
                                                            apiCallResponse.message, RazorpayPaymentLinkResponse.class);
                                                        return new ApiResponse(true, '', paymentLinkResponse.id, paymentLinkResponse.shortUrl, paymentLinkResponse.status);
                                                    } catch(Exception ex) {
                                                        return new ApiResponse(false, ex.getMessage(), '', '', '');        
                                                    }
                                                }
    
    /**
* @description Checks the status of multiple payment links
* @param paymentIds Set of payment IDs to check
* @param singleRecordFound Boolean indicating if a single record is being checked
* @param singlePaymentId String containing a single payment ID (if applicable)
* @return ApiResponse containing the status of payment links
*/
    @AuraEnabled
    public static ApiResponse checkPaymentStatus(List<String> paymentIds, Boolean singleRecordFound, String singlePaymentId) {
        try {
            String endpoint = ENDPOINT_PAYMENT_LINK + '?entity_type=payment_link';
            
            if(singleRecordFound){
                endpoint = ENDPOINT_PAYMENT_LINK + '/' + singlePaymentId;
            }else{
                for (String paymentId : paymentIds) {
                    endpoint += '&entity_ids=' + EncodingUtil.urlEncode(paymentId, 'UTF-8');
                } 
            }
            
            // Make the API call
            ApiResponse apiCallResponse = makeHttpRequest('', endpoint, 'GET'); 
            if (!apiCallResponse.isSuccess) {
                return apiCallResponse;
            }
            // Parse the successful response
            if(singleRecordFound){
                RazorpayPaymentLinkResponse responsePayment = (RazorpayPaymentLinkResponse)JSON.deserialize(
                    apiCallResponse.message, RazorpayPaymentLinkResponse.class); 
                return new ApiResponse(true, '', '', '', responsePayment.status);
            }
            PaymentLinkStatusResponse paymentLinkResponse = (PaymentLinkStatusResponse)JSON.deserialize(
                apiCallResponse.message, PaymentLinkStatusResponse.class);
            ApiResponse response = new ApiResponse(true, '', '', '', '');
            response.paymentLinkResponse = paymentLinkResponse.paymentLinks;
            return response;
        } catch(Exception ex) {
            return new ApiResponse(false, ex.getMessage(), '', '', '');        
        }
    }
    
    /**
* @description Makes an HTTP request to the specified endpoint
* @param body The request body
* @param endpointUrl The URL to send the request to
* @param httpMethod The HTTP method (GET, POST, etc.)
* @return ApiResponse containing the result of the HTTP request
*/
    public static ApiResponse makeHttpRequest(String body, String endpointUrl, String httpMethod) {
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpointUrl);
            request.setMethod(httpMethod);
            request.setHeader('Content-Type', 'application/json');
            
            if (String.isNotBlank(body)) {
                request.setBody(body);
            }
            
            Http http = new Http();
            HTTPResponse response = http.send(request);
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204) {
                return new ApiResponse(true, response.getBody(), '', '', '');
            } else {
                return new ApiResponse(false, response.getBody(), '', '', '');
            }
        } catch(Exception ex) {
            return new ApiResponse(false, ex.getMessage(), '', '', '');
        }
    }   
    
    /**
* @description Generates the JSON body for the payment link request
* @param amount The payment amount
* @param currencyType The currency code
* @param transactionName Reference ID for the transaction
* @param description Description of the payment
* @param customerName Name of the customer
* @param customerEmail Email of the customer
* @param customerPhone Phone number of the customer
* @return ApiResponse containing the generated JSON string or error message
*/
    private static ApiResponse generateJsonBody(Decimal amount, String currencyType, String transactionName, 
                                                String description, String customerName, String customerEmail, 
                                                String customerPhone) {
                                                    try {
                                                        JSONGenerator jsonGen = JSON.createGenerator(true);
                                                        jsonGen.writeStartObject();
                                                        jsonGen.writeNumberField('amount', (Integer)(amount * 100));
                                                        jsonGen.writeStringField('currency', currencyType);
                                                        jsonGen.writeBooleanField('accept_partial', false);
                                                        jsonGen.writeNumberField('expire_by', calculateExpiryTimestamp());
                                                        jsonGen.writeStringField('reference_id', transactionName);
                                                        jsonGen.writeStringField('description', description);
                                                        jsonGen.writeFieldName('customer');
                                                        jsonGen.writeStartObject();
                                                        jsonGen.writeStringField('name', customerName);
                                                        jsonGen.writeStringField('contact', customerPhone);
                                                        jsonGen.writeStringField('email', customerEmail);
                                                        jsonGen.writeEndObject();
                                                        jsonGen.writeFieldName('notify');
                                                        jsonGen.writeStartObject();
                                                        jsonGen.writeBooleanField('sms', true);
                                                        jsonGen.writeBooleanField('email', true);
                                                        jsonGen.writeEndObject();
                                                        jsonGen.writeBooleanField('reminder_enable', true);
                                                        jsonGen.writeFieldName('notes');
                                                        jsonGen.writeStartObject();
                                                        jsonGen.writeStringField('policy_name', 'Transaction Payment');
                                                        jsonGen.writeEndObject();
                                                        jsonGen.writeStringField('callback_url', 'https://google.com');
                                                        jsonGen.writeStringField('callback_method', 'get');
                                                        jsonGen.writeEndObject();
                                                        return new ApiResponse(true, jsonGen.getAsString(), '', '', '');
                                                    } catch(Exception ex) {
                                                        return new ApiResponse(false, ex.getMessage(), '', '', '');
                                                    }
                                                }
    
    /**
* @description Calculates the expiry timestamp for the payment link (24 hours from now)
* @return Long representation of the expiry timestamp
*/
    private static Long calculateExpiryTimestamp() {
        return DateTime.now().addHours(24).getTime() / 1000;
    }
    
    
    
    /**
* @description Wrapper class for API responses
* @param isSuccess Indicates if the API call was successful
* @param message Response message or error description
* @param paymentId Unique identifier for the payment
* @param paymentUrl URL for the payment link
* @param paymentStatus Current status of the payment
* @param List<RazorpayPaymentLinkResponse> paymentLinkResponse
*/

    public class ApiResponse {
            /**
* @description Wrapper class for API responses
* @param isSuccess Indicates if the API call was successful
* @param message Response message or error description
* @param paymentId Unique identifier for the payment
* @param paymentUrl URL for the payment link
* @param paymentStatus Current status of the payment
* @param List<RazorpayPaymentLinkResponse> paymentLinkResponse
*/
/**
 * @description : Boolean value to indicate if the API call was successful
 */
        @AuraEnabled
        public Boolean isSuccess { get; set;}
        /**
 * @description : Getting message or error description
  */
        @AuraEnabled
        public String message { get; set;}
        /**
 * @description : Getting the payment Id of the payment
 */
        @AuraEnabled
        public String paymentId { get; set;}
        /**
 * @description : Gettting the Payment URL of the payment
 */
        @AuraEnabled
        public String paymentUrl { get; set;}
        /**
 * @description : Get the status of Payment 
 */
        @AuraEnabled
        public String paymentStatus { get; set;}
        /**
 * @description : Get the payment link response
  */
        @AuraEnabled
        public List<RazorpayPaymentLinkResponse> paymentLinkResponse  { get; set;}
        
        /**
* @description Constructor for ApiResponse
* @param isSuccess Indicates if the API call was successful
* @param message Response message or error description
* @param paymentId Unique identifier for the payment
* @param paymentUrl URL for the payment link
* @param paymentStatus Current status of the payment
*/
        public ApiResponse(Boolean isSuccess, String message, String paymentId, String paymentUrl, String paymentStatus) {
            this.isSuccess = isSuccess;
            this.message = message;   
            this.paymentId = paymentId;
            this.paymentUrl = paymentUrl;
            this.paymentStatus = paymentStatus;
        }
    }
    
    /**
* @description Wrapper class for Razorpay payment link response
*/
    public class RazorpayPaymentLinkResponse {
        public String id;
        public String shortUrl;
        public String status;
    }
    
    /**
* @description Wrapper class for payment link status response
*/
    public class PaymentLinkStatusResponse {
        public List<RazorpayPaymentLinkResponse> paymentLinks;
    }
}