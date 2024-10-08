/**
 * @author TechMatrix Team
 * @description Test class for FetchPaymentStatus
 */
@isTest
public class FetchPaymentStatusListActionTest {

    @isTest
    static void testTransactionNotFound() {
        // Test with a non-existing transaction ID
        FetchPaymentStatusListAction.InputVariable input = new FetchPaymentStatusListAction.InputVariable();
        input.transactionId = '0'; // Non-existing transaction ID

        List<FetchPaymentStatusListAction.InputVariable> inputList = new List<FetchPaymentStatusListAction.InputVariable>{input};
        List<FetchPaymentStatusListAction.OutputVariable> result = FetchPaymentStatusListAction.fetchPaymentStatus(inputList);

        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        System.assertEquals('Transaction is not found', result[0].errorMessage,'');
    }
    
    @isTest
    static void testRazorpayPaymentIdNotFound() {
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        FinancialAccountTransaction  transactionFin =  TestdataFactory.createFinancialAccountTransaction(null,'Pending', 100.00,System.Today(),'Credit',financialAccount.Id);
        FetchPaymentStatusListAction.InputVariable input = new FetchPaymentStatusListAction.InputVariable();
        input.transactionId = transactionFin.Id;

        List<FetchPaymentStatusListAction.InputVariable> inputList = new List<FetchPaymentStatusListAction.InputVariable>{input};
        List<FetchPaymentStatusListAction.OutputVariable> result = FetchPaymentStatusListAction.fetchPaymentStatus(inputList);

        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        System.assertEquals('Razorpay payment id not found', result[0].errorMessage,'');
    }

    @isTest
    static void testSuccessfulPaymentStatus() {
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        FinancialAccountTransaction  transactionFin =  TestdataFactory.createFinancialAccountTransaction('Mock Id','Pending', 100.00,System.Today()+1,'Credit',financialAccount.Id);
		transactionFin.Status = 'Paid';
        update transactionFin;      
        Test.startTest(); 
        // Mock API response
        PaymentGateWayIntegration.ApiResponse mockResponse = new PaymentGateWayIntegration.ApiResponse(false, 'Successfully found payment status, payment status is Paid', 'mock_payment_id', '', 'Paid');
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock(mockResponse));

        FetchPaymentStatusListAction.InputVariable input = new FetchPaymentStatusListAction.InputVariable();
        input.transactionId = transactionFin.Id;

        List<FetchPaymentStatusListAction.InputVariable> inputList = new List<FetchPaymentStatusListAction.InputVariable>{input};
        List<FetchPaymentStatusListAction.OutputVariable> result = FetchPaymentStatusListAction.fetchPaymentStatus(inputList);

        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        Test.stopTest();
    }
    
     @isTest
    static void testFailurePaymentStatus() {
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        FinancialAccountTransaction  transactionFin =  TestdataFactory.createFinancialAccountTransaction('Mock Id','Pending', 100.00,System.Today()+1,'Credit',financialAccount.Id);
		transactionFin.Status = 'Paid';
        update transactionFin;      
        Test.startTest(); 
        // Mock API response
        PaymentGateWayIntegration.ApiResponse mockResponse = new PaymentGateWayIntegration.ApiResponse(true, 'Successfully found payment status, payment status is Paid', 'mock_payment_id', '', 'Paid');
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayIntegrationMock(mockResponse));

        FetchPaymentStatusListAction.InputVariable input = new FetchPaymentStatusListAction.InputVariable();
        input.transactionId = transactionFin.Id;

        List<FetchPaymentStatusListAction.InputVariable> inputList = new List<FetchPaymentStatusListAction.InputVariable>{input};
        List<FetchPaymentStatusListAction.OutputVariable> result = FetchPaymentStatusListAction.fetchPaymentStatus(inputList);

        System.assertEquals(1, result.size(),'');
        System.assertEquals(false, result[0].isError,'');
        Test.stopTest();
        }
   
     /**
     * @description Mock Http callOut
     */        
    private class PaymentGatewayIntegrationMock implements HttpCalloutMock {
        private PaymentGateWayIntegration.ApiResponse response;
    /**
     * @description Mock Http callOut
     * @param response mock http response
     */
        public PaymentGatewayIntegrationMock(PaymentGateWayIntegration.ApiResponse response) {
            this.response = response;
        }
  /**
     * @description Mock Http callOut
     * @param req mock http request 
     * @return mock Response
     */
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(response));
            res.setStatusCode(response.isSuccess ? 200 : 400);
            return res;
        }
    }
}