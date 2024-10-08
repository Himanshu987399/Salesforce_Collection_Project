@isTest
public class PaymentGatewayIntegrationTest {
    private class PaymentGatewayIntegrationMock implements HttpCalloutMock {
       
        private String methodName;
   /**
     * @description mock callout constructor
     * @param methodName name of the method using the intergration class
     */
        public PaymentGatewayIntegrationMock(String methodName) {
            this.methodName = methodName;
        }
    /**
     * @description mock callout
     * @param req mock http request 
     * @return mock response
     */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            //specfying each method name as response is differnet for different methods 
            if (methodName == 'createPaymentLink') {
                res.setBody('{"id": "pay_29QQoUBi66xm2f", "short_url": "https://rzp.io/i/29QQoUBi66xm2f", "status": "created"}');
            } else if (methodName == 'checkPaymentStatus') {
                res.setBody('{"paymentLinks": [{"id": "pay_29QQoUBi66xm2f", "status": "paid"}]}');
            } else if (methodName == 'checkPaymentStatusSingle') {
                res.setBody('{"id": "pay_29QQoUBi66xm2f", "status": "paid"}');
            } else if (methodName == 'createPaymentLinkError') {
                res.setStatusCode(400);
                res.setBody('{"error": "Invalid Request"}');
            } else if (methodName == 'checkPaymentStatusError') {
                res.setStatusCode(400);
                res.setBody('{"error": "Invalid Payment ID"}');
            }
            
            return res;
        }
    }
  
    @isTest
    static void testCreatePaymentLink() {
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock('createPaymentLink'));
        
        Test.startTest();
        
        PaymentGatewayIntegration.ApiResponse response = PaymentGatewayIntegration.createPaymentLink(
            100.00,
            'INR',
            'txn_123',
            'Test payment',
            'John Doe',
            'john.doe@example.com',
            '9876543210'
        );
        
        Test.stopTest();
        
        System.assert(response.isSuccess, 'Expected isSuccess to be true');
        System.assertEquals('pay_29QQoUBi66xm2f', response.paymentId, 'Expected paymentId to match');
        System.assertEquals('created', response.paymentStatus, 'Expected paymentStatus to match');
    }
    
    @isTest
    static void testCheckPaymentStatus() {
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock('checkPaymentStatus'));
        
        Test.startTest();
        
        List<String> paymentIds = new List<String>{'pay_29QQoUBi66xm2f'};
        PaymentGatewayIntegration.ApiResponse response = PaymentGatewayIntegration.checkPaymentStatus(paymentIds, false, '');
        
        Test.stopTest();
        
        System.assert(response.isSuccess, 'Expected isSuccess to be true');
        System.assertNotEquals(null, response.paymentLinkResponse, 'Expected paymentLinkResponse not to be null');
        System.assertEquals(1, response.paymentLinkResponse.size(), 'Expected size of paymentLinkResponse to be 1');
        System.assertEquals('pay_29QQoUBi66xm2f', response.paymentLinkResponse[0].id, 'Expected paymentId to match');
        System.assertEquals('paid', response.paymentLinkResponse[0].status, 'Expected paymentStatus to match');
    }

    @isTest
    static void testCheckSinglePaymentStatus() {
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock('checkPaymentStatusSingle'));
        
        Test.startTest();
        PaymentGatewayIntegration.ApiResponse response = PaymentGatewayIntegration.checkPaymentStatus(new List<String>(), true, 'pay_29QQoUBi66xm2f');
        Test.stopTest();
        
        System.assert(response.isSuccess, 'Expected isSuccess to be true');
        System.assertEquals('paid', response.paymentStatus, 'Expected paymentStatus to match');
    }

    @isTest
    static void testCreatePaymentLinkError() {
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock('createPaymentLinkError'));
        
        Test.startTest();
        
        // Assuming the mock returns error
        PaymentGatewayIntegration.ApiResponse response = PaymentGatewayIntegration.createPaymentLink(
            100.00,
            'INR',
            'txn_123',
            'Test payment',
            'John Doe',
            'john.doe@example.com',
            '9876543210'
        );
        
        Test.stopTest();
        
        System.assert(!response.isSuccess, 'Expected isSuccess to be false');
        System.assertEquals('', response.paymentId, 'Expected paymentId to be empty');
    }

    @isTest
    static void testCheckPaymentStatusError() {
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock('checkPaymentStatusError'));
        
        Test.startTest();
        
        List<String> paymentIds = new List<String>{'invalid_payment_id'};
        PaymentGatewayIntegration.ApiResponse response = PaymentGatewayIntegration.checkPaymentStatus(paymentIds, false, '');
        
        Test.stopTest();
        
        System.assert(!response.isSuccess, 'Expected isSuccess to be false');
    }
}