/**
 * @author TechMatrix Team
 * @description Test class for FetchPaymentStatus
 */
@isTest
public class FetchPaymentStatusListActionTest {

    /*@isTest
    static void testTransactionNotFound() {
        // Test with a non-existing transaction ID
        FetchPaymentStatusListAction.InputVariable input = new FetchPaymentStatusListAction.InputVariable();
        input.transactionId = '0'; // Non-existing transaction ID

        List<FetchPaymentStatusListAction.InputVariable> inputList = new List<FetchPaymentStatusListAction.InputVariable>{input};
        List<FetchPaymentStatusListAction.OutputVariable> result = FetchPaymentStatusListAction.fetchPaymentStatus(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertEquals('Transaction is not found', result[0].errorMessage);
    }
    
    @isTest
    static void testRazorpayPaymentIdNotFound() {
        // Testing with missing RazorPay ID
        FinServ__FinancialAccountTransaction__c transactionFin = new FinServ__FinancialAccountTransaction__c(
            Status__c = 'Pending',
            FinServ__Amount__c = 100.00,
            FinServ__TransactionDate__c = System.Today()
        );
        insert transactionFin;

        FetchPaymentStatusListAction.InputVariable input = new FetchPaymentStatusListAction.InputVariable();
        input.transactionId = transactionFin.Id;

        List<FetchPaymentStatusListAction.InputVariable> inputList = new List<FetchPaymentStatusListAction.InputVariable>{input};
        List<FetchPaymentStatusListAction.OutputVariable> result = FetchPaymentStatusListAction.fetchPaymentStatus(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertEquals('Razorpay payment id not found', result[0].errorMessage);
    }

    @isTest
    static void testSuccessfulPaymentStatus() {
        // Setup mock response for successful payment status

        // Creating a valid transaction with RazorPay ID
        FinServ__FinancialAccountTransaction__c transactionFinan = new FinServ__FinancialAccountTransaction__c(
            RazorPay_Payment_Id__c = 'mock_payment_id',
            Status__c = 'Pending',
            FinServ__Amount__c = 100.00,
            FinServ__TransactionDate__c = System.Today()
        );
        insert transactionFinan;
		transactionFinan.Status__c = 'Paid';
        update transactionFinan;
        
        Test.startTest();
        
        // Mock API response
        PaymentGateWayIntegration.ApiResponse mockResponse = new PaymentGateWayIntegration.ApiResponse(true, 'Successfully found payment status, payment status is Paid', 'mock_payment_id', '', 'Paid');
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock(mockResponse));

        FetchPaymentStatusListAction.InputVariable input = new FetchPaymentStatusListAction.InputVariable();
        input.transactionId = transactionFinan.Id;

        List<FetchPaymentStatusListAction.InputVariable> inputList = new List<FetchPaymentStatusListAction.InputVariable>{input};
        List<FetchPaymentStatusListAction.OutputVariable> result = FetchPaymentStatusListAction.fetchPaymentStatus(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(false, result[0].isError);
        //System.assertEquals('Successfully found payment status, payment status is Paid', result[0].errorMessage); // Update to match actual return
        //System.assertEquals('Paid', result[0].razorPaymentStatus);

        Test.stopTest();
    }

    // Mock class for PaymentGatewayIntegration
    private class PaymentGatewayIntegrationMock implements HttpCalloutMock {
        private PaymentGateWayIntegration.ApiResponse response;

        public PaymentGatewayIntegrationMock(PaymentGateWayIntegration.ApiResponse response) {
            this.response = response;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(response));
            res.setStatusCode(response.isSuccess ? 200 : 400);
            return res;
        }
    }*/
}