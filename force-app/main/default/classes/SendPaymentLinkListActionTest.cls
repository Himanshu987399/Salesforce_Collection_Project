/**
* @author TechMatrix Team
* @description Test class for SendPaymentLinkList
*/
@isTest
public class SendPaymentLinkListActionTest {
    
    @isTest
    static void nocaseFound() {  //test method when no case is found
        SendPaymentLinkListAction.InputVariable input = new SendPaymentLinkListAction.InputVariable();
        input.caseId = '0';
        
        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{input};
            List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);
        
        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        System.assertNotEquals(null, result[0].errorMessage,'');
    }
    
    @isTest
    static void noEmailOnRelatedContact() { // test class when no Email is found
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact testContact = TestDataFactory.createContact('FirstName1', 'Contact 1', null, '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        Case testCase = TestDataFactory.createCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000,100000, Date.today().addDays(-10));
        SendPaymentLinkListAction.InputVariable input = new SendPaymentLinkListAction.InputVariable();
        input.caseId = testCase.Id;
        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{input};
            List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);
        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        System.assertNotEquals(null, result[0].errorMessage,'');
    }
    
    @isTest
    static void noPhoneOnRelatedContact() {
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact testContact = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', null, accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        Case testCase = TestDataFactory.createCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000,100000, Date.today().addDays(-10));
        
        SendPaymentLinkListAction.InputVariable input = new SendPaymentLinkListAction.InputVariable();
        input.caseId = testCase.Id;
        
        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{input};
            List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);
        
        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        System.assertEquals('Phone number is missing on contact', result[0].errorMessage,'');
    }
    
    @isTest
    static void testInvokeMethodnoCaseFound() {
        // Prepare inputMap with an invalid case ID
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('ContextId', '0'); // Invalid case ID
        Map<String, Object> outputMap = new Map<String, Object>();
        Boolean result = new SendPaymentLinkListAction().invokeMethod('sendPaymentLink', inputMap, outputMap, null);//invoke method
        System.assertEquals(false, result,'');
        System.assertEquals('No case found with the provided ID', outputMap.get('result'),'');
    }
    
    
    @isTest
    static void testInvokeMethodexceptionHandling() {
        // invalid input map for exception
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('ContextId', null); // Invalid context ID
        Map<String, Object> outputMap = new Map<String, Object>();
        Boolean result = new SendPaymentLinkListAction().invokeMethod('sendPaymentLink', inputMap, outputMap, null);
        System.assertEquals(false, result,'');
    }
    
    /**
* @description Test class for SendPaymentLinkList
*/
    private class PaymentGatewayMock implements HttpCalloutMock {
        private Integer statusCode;
        /**
* @description status code constructor 
* @param statusCode status code th know the server response
*/
        public PaymentGatewayMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        /**
* @description mock http response 
* @param req http mock request
* @return mockResponse
*/
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            
            if (this.statusCode == 200) { // Successful callout
                String responseBody = '{"id": "pay_29QQoUBi66xm2f", "shortUrl": "https://paymentlink.com", "status": "Pending"}';
                res.setBody(responseBody);
            } else { // Error scenario
                String responseBody = '{"error": "Internal Server Error"}';
                res.setBody(responseBody);
            }
            return res;
        }
    }
    @IsTest
    static void testSuccessfulPaymentLink() {
        //mock response for successful payment (
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayMock(200));
        
        // Create necessary test data
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact testContact = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        //String dataCase = '{"Subject" : "Himanshu","ContactId" :"idddd","AcountId":"shshshs","Product_Type__c":"Auto Loan","Finserv_FinancialAccount__c":"sssss","Total_EMI_due__c : "1234","Amount_Paid__c":"123456","Last_EMI_Due_date__c":"today.addDays(10)","FOS_Agent__c":"DDD"}';
        Case testCase = TestDataFactory.createCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10));
        
        Test.startTest();
        // Input variables
        SendPaymentLinkListAction.InputVariable inputVar = new SendPaymentLinkListAction.InputVariable();
        inputVar.caseId = testCase.Id;
        inputVar.amount = 100.0;
        inputVar.paymentMode = 'Credit Card';
        inputVar.paymentOption = 'Full Payment'; 
        
        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{ inputVar };
            
            // Invoke method
            List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);
        
        FinancialAccountTransaction finTransaction = TestDataFactory.createFinancialAccountTransaction( result[0].razorePaymentId,result[0].razorePaymentStatus,inputList[0].amount,System.Today(),'Credit',financialAccount.Id);
        //FinancialAccountTransaction finTransaction = TestdataFactory.createFinancialAccountTransaction('Mock Id','Pending', 100.00,System.Today()+1,'Credit',financialAccount.Id);
        finTransaction.Case__c =testCase.Id;
        finTransaction.Payment_Option__c = 'Pay the Entire Amount';
        finTransaction.Payment_Method__c = 'Send Payment Link';
        finTransaction.Payment_Url__c = result[0].razorePaymentUrl;
        update finTransaction;
        
        Test.stopTest();
        
        //Assertions
        System.assertEquals('pay_29QQoUBi66xm2f', result[0].razorePaymentId, 'Payment ID mismatch');
        System.assertEquals('https://paymentlink.com', result[0].razorePaymentUrl, 'Payment Link mismatch');
        System.assertEquals('Pending', result[0].razorePaymentStatus, 'Payment Status mismatch');
        System.assertEquals(false, result[0].isError, 'Expected no error');
        System.assertEquals(System.Label.Success_Message_of_payment, result[0].errorMessage, 'Success message mismatch');
    } 
    
    @IsTest
    static void testServiceError() {
        // mock response error
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayMock(500));
        
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        
        Contact testContact = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        Case testCase = TestDataFactory.createCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10));
        
        Test.startTest();
        //input variables
        SendPaymentLinkListAction.InputVariable inputVar = new SendPaymentLinkListAction.InputVariable();
        inputVar.caseId = testCase.Id;
        inputVar.amount = 100.0;
        inputVar.paymentMode = 'Credit Card';
        inputVar.paymentOption = 'Full Payment'; 
        
        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{ inputVar };
            
            // Invoke the method
            List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(true, result[0].isError,'');
    }
    
    @IsTest
    static void testInvokeMethod() {
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayMock(200));
        
        // test data
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact testContact = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        Case testCase = TestDataFactory.createCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10));
        
        // Prepare input map
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('ContextId', testCase.Id);
        Map<String, Object> step2Map = new Map<String, Object>();
        step2Map.put('Amount_to_Paid', 100.0);
        step2Map.put('How_much_do_you_want_to_pay', 'Full payment');
        inputMap.put('Step2', step2Map);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean isSuccess = new SendPaymentLinkListAction().invokeMethod('sendPaymentLink', inputMap, outputMap, options);
        Test.stopTest();
        System.assertEquals(false, isSuccess,'');
         
    }
    
    @IsTest
    static void testInvokeMethod1() {
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayMock(200));
        
        // test data
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact testContact = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        Case testCase = TestDataFactory.createCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10));
        
        // Prepare input map
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('ContextId', testCase.Id);
        Map<String, Object> step2Map = new Map<String, Object>();
        step2Map.put('Amount_to_Paid', 100.0);
        step2Map.put('How_much_do_you_want_to_pay', 'Full payment');
        inputMap.put('Step2', step2Map);
        
        //Map<String, Object> outputMap = new Map<String, Object>();
        //Map<String, Object> options = new Map<String, Object>();
       
        Test.startTest();
        Response resp = SendPaymentLinkListAction.sendPaymentLinkFromLWC(testCase.Id,200,System.Label.Pay_the_Entire_Amount);
        Test.stopTest();
        System.assertNotEquals(null, resp,'');
        
    }
    
    @isTest
    public static void getCaseAmountDataTest(){
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact testContact = TestDataFactory.createContact('FirstName1', 'Contact 1', null, '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        Case testCase = TestDataFactory.createCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000,100000, Date.today().addDays(-10)); 
        Test.startTest();
        String amount = SendPaymentLinkListAction.getCaseAmountData(testCase.Id);
        Test.stopTest();
      	System.assertNotEquals('', amount,'');
    }
}