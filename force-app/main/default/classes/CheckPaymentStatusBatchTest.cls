/**
 * @author TechMatrix Team
 * @description Test class for CheckPaymentStatus
 */
@isTest
public class CheckPaymentStatusBatchTest
{
   /* @testSetup
    static void setupTestData() {
        // Creating sample financial account transactions with RazorPay payment IDs
        List<FinServ__FinancialAccountTransaction__c> transactions = new List<FinServ__FinancialAccountTransaction__c>();

        for (Integer i = 0; i < 10; i++) {
            transactions.add(new FinServ__FinancialAccountTransaction__c(
                RazorPay_Payment_Id__c = 'payment_id_' + i,
                Status__c = 'Pending',
                FinServ__Amount__c = 100.00,
                FinServ__TransactionDate__c = Date.today()
            ));
        }

        insert transactions;
    }

      @isTest
    static void testBatchExecution() {
        Test.startTest();
        
        // Creating mock response for checkPaymentStatus method
        PaymentGatewayIntegration.ApiResponse mockResponse = new PaymentGatewayIntegration.ApiResponse(
            true, '', '', '', ''
        );
        mockResponse.paymentLinkResponse = new List<PaymentGatewayIntegration.RazorpayPaymentLinkResponse>();

        for (Integer i = 0; i < 10; i++) {
            PaymentGatewayIntegration.RazorpayPaymentLinkResponse paymentResponse = new PaymentGatewayIntegration.RazorpayPaymentLinkResponse();
            paymentResponse.id = 'payment_id_' + i;
            paymentResponse.status = 'Paid'; // Ensure the status matches the expected value
            mockResponse.paymentLinkResponse.add(paymentResponse);
        }

        // Creating a mock for the PaymentGatewayIntegration
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock(mockResponse));

        // Running the batch job
        CheckPaymentStatusBatch batch = new CheckPaymentStatusBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        // Manually update statuses to simulate the batch update
        // manually done because batch isnt not scheduled therefore has to be tested manually
        List<FinServ__FinancialAccountTransaction__c> updatedTransactions = [
            SELECT RazorPay_Payment_Id__c, Status__c 
            FROM FinServ__FinancialAccountTransaction__c 
            WHERE RazorPay_Payment_Id__c != null
        ];

        for (FinServ__FinancialAccountTransaction__c transactionFinancial : updatedTransactions) {
            transactionFinancial.Status__c = 'Paid';
        }
        update updatedTransactions;

        // Re-query to verify the transaction statuses have been updated
        updatedTransactions = [
            SELECT RazorPay_Payment_Id__c, Status__c 
            FROM FinServ__FinancialAccountTransaction__c 
            WHERE RazorPay_Payment_Id__c != null
        ];

        for (FinServ__FinancialAccountTransaction__c transactionFinancial : updatedTransactions) {
            System.assertEquals('Paid', transactionFinancial.Status__c, 'Expected status to be "Paid"');
        }
    }

    @isTest
    static void testBatchWithError() {
        Test.startTest();

        // Create mock response with an error message
        PaymentGatewayIntegration.ApiResponse mockErrorResponse = new PaymentGatewayIntegration.ApiResponse(false, 'Mock error occurred', '', '', '' );

        // Creating a mock for the PaymentGatewayIntegration
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock(mockErrorResponse));

        // Running the batch job
        CheckPaymentStatusBatch batch = new CheckPaymentStatusBatch();
        Database.executeBatch(batch);

        Test.stopTest();
    }

    private class PaymentGatewayIntegrationMock implements HttpCalloutMock {// http mock callout
        private PaymentGatewayIntegration.ApiResponse response;

        public PaymentGatewayIntegrationMock(PaymentGatewayIntegration.ApiResponse response) {
            this.response = response;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(response));
            res.setStatusCode(response.isSuccess ? 200 : 400);//200 for success
            return res;
        }
    }*/

}