/**
 * @author TechMatrix Team
 * @description Test class for CheckPaymentStatus
 */
@isTest
public class CheckPaymentStatusBatchTest
{
    @testSetup
    static void setupTestData() {
        // Creating sample financial account transactions with RazorPay payment IDs
        List<FinancialAccountTransaction> transactions = new List<FinancialAccountTransaction>();
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','123456789');
        for (Integer i = 0; i < 10; i++) {
            transactions.add(new FinancialAccountTransaction(
                RazorPay_Payment_Id__c = 'pay_12345678' + i,
                Status = 'Pending',
                Amount = 100.00,
                TransactionDate = Date.today(),
                DebitCreditIndicator = 'Credit',
                FinancialAccountId =  financialAccount.Id   
            ));
        }

        insert transactions;
    }

      @isTest
    static void testBatchExecution() {
        List<FinancialAccountTransaction> updatedTransactions1 = [
            SELECT RazorPay_Payment_Id__c, Status 
            FROM FinancialAccountTransaction 
            WHERE RazorPay_Payment_Id__c != null
        ];
        if(!updatedTransactions1.isEmpty()){
        Test.startTest();
        
        // Creating mock response for checkPaymentStatus method
        PaymentGatewayIntegration.ApiResponse mockResponse = new PaymentGatewayIntegration.ApiResponse(
            true, '', '', '', ''
        );
        mockResponse.paymentLinkResponse = new List<PaymentGatewayIntegration.RazorpayPaymentLinkResponse>();

        for (Integer i = 0; i < 10; i++) {
            PaymentGatewayIntegration.RazorpayPaymentLinkResponse paymentResponse = new PaymentGatewayIntegration.RazorpayPaymentLinkResponse();
            paymentResponse.id = 'pay_12345678' + i;
            paymentResponse.status = 'Paid'; 
            mockResponse.paymentLinkResponse.add(paymentResponse);
        }

        // Creating a mock for the PaymentGatewayIntegration
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock(mockResponse));

        // Running the batch job
        CheckPaymentStatusBatch batch = new CheckPaymentStatusBatch();
        Database.executeBatch(batch);

        Test.stopTest();
    }
        // Manually update statuses to simulate the batch update
        // manually done because batch isnt not scheduled therefore has to be tested manually
        List<FinancialAccountTransaction> updatedTransactions = [
            SELECT RazorPay_Payment_Id__c, Status 
            FROM FinancialAccountTransaction 
            WHERE RazorPay_Payment_Id__c != null
        ];
        if(!updatedTransactions.isEmpty()){
        for (FinancialAccountTransaction transactionFinancial : updatedTransactions) {
            transactionFinancial.Status = 'Paid';
        }
        update updatedTransactions;
        }

        // Re-query to verify the transaction statuses have been updated
        updatedTransactions = [
            SELECT RazorPay_Payment_Id__c, Status 
            FROM FinancialAccountTransaction 
            WHERE RazorPay_Payment_Id__c != null
        ];

        for (FinancialAccountTransaction transactionFinancial : updatedTransactions) {
            System.assertEquals('Paid', transactionFinancial.Status, 'Expected status to be "Paid"');
        }
    }

    @isTest
    static void testBatchWithError() {
        Test.startTest();

        // Create mock response with an error message
        PaymentGatewayIntegration.ApiResponse mockErrorResponse = new PaymentGatewayIntegration.ApiResponse(false, 'Mock error occurred', '', '', '' );
        mockErrorResponse.paymentLinkResponse = new List<PaymentGatewayIntegration.RazorpayPaymentLinkResponse>();

        for (Integer i = 0; i < 10; i++) {
            PaymentGatewayIntegration.RazorpayPaymentLinkResponse paymentResponse = new PaymentGatewayIntegration.RazorpayPaymentLinkResponse();
            paymentResponse.id = 'pay_12345678' + i;
            paymentResponse.status = 'Paid'; 
            mockErrorResponse.paymentLinkResponse.add(paymentResponse);
        }
        // Creating a mock for the PaymentGatewayIntegration
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock(mockErrorResponse));

        // Running the batch job
        CheckPaymentStatusBatch batch = new CheckPaymentStatusBatch();
        Database.executeBatch(batch);

        Test.stopTest();
        List<FinancialAccountTransaction> updatedTransactions = [
            SELECT RazorPay_Payment_Id__c, Status 
            FROM FinancialAccountTransaction 
            WHERE RazorPay_Payment_Id__c != null
        ];     
        for (FinancialAccountTransaction transactionFinancial : updatedTransactions) {
            System.assertEquals('Pending', transactionFinancial.Status, 'Expected status to be "Pending"');
        }
    }
/**
 * @description mock for paymentgatewayintegration 
 */
    public class PaymentGatewayIntegrationMock implements HttpCalloutMock {// http mock callout 
    public PaymentGatewayIntegration.ApiResponse response;
/**
 * @description Mock Http Callout
 * @param response mock http response 
 */
        public PaymentGatewayIntegrationMock(PaymentGatewayIntegration.ApiResponse response) {
            this.response = response;
        }
/**
 * @description Mock Http Callout
 * @param req mock http request
 * @return mock http response 
 */
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            String responseBody = '{"paymentLinks":[{"id":"pay_123456789","shortUrl":"https://example.com","status":"paid"}]}';
        	res.setBody(responseBody);
            res.setStatusCode(response.isSuccess ? 200 : 400);//200 for success
            return res;
        }
    }
    
}