@IsTest
private class ReceiptMappingHandlerTest {
    @TestSetup
    static void makeData() {
        // Create test accounts
        Account testPrimaryAccount = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account testJointAccount = TestDataFactory.createAccount('Test Account Joint', 'Business');
        
        // Create test contacts
        Contact testBusinessContact = TestDataFactory.createContact(
            'John', 'Doe', 'johndoe@test.com', '1234567890', 
            testPrimaryAccount.Id, '12345', 'Business'
        );
        Contact testFOSContact = TestDataFactory.createContact(
            'JohnFOS', 'DoeFOS', 'fos@test.com', '1234567810', 
            testPrimaryAccount.Id, '12345', 'FOS'
        );
        
        // Create another test financial account
        FinancialAccount testSavingsAccount = TestDataFactory.createFinancialAccount(
            'Test Financial Account',
            testPrimaryAccount.Id,
            testJointAccount.Id,
            'Checking',
            '1234567890'
        );
        
        // Create test FOS agent assigned case
        Case testCase = TestDataFactory.createFOSAgentAssignedCase(
            'Test Case',
            testBusinessContact.Id,
            testPrimaryAccount.Id,
            'Auto Loan',
            testSavingsAccount.Id,
            10000,
            50000,
            Date.today().addDays(-8),
            testFOSContact.Id
        );
      
        
        Receipt__c testReceipt = new Receipt__c(Case__c = testCase.Id);
        insert testReceipt;
        
        FinancialAccountFee testFee = new FinancialAccountFee(Case__c = testCase.Id, Type = 'EMI', Amount = 100,FinancialAccountId = testSavingsAccount.Id);
        insert testFee;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' Limit 1]; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='893827373737@test.com');
        Insert u;
        
        User u2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id,ManagerId = u.Id,
                           TimeZoneSidKey='America/Los_Angeles', UserName='21312312323232121@testorg.com');
        
        insert u2;
        
        System.runAs(u2) {
            Refund_and_Waive_off_Request__c testRefund = new Refund_and_Waive_off_Request__c(Case__c = testCase.Id, Amount__c = 50, Type__c = 'Waive Off');
            insert testRefund;
            testRefund.Approval_Status__c = 'Approved';
            testRefund.Financial_Account__c = testSavingsAccount.Id;
            update testRefund;
        }
        
       
        FinancialAccountTransaction  transactionCash =  TestdataFactory.createFinancialAccountTransaction(null,'Pending', 100.00,System.Today(),'Credit',testSavingsAccount.Id);
        transactionCash.Payment_Method__c = 'Cash';
        transactionCash.Case__c = testCase.Id;
        transactionCash.status = 'Paid';
        update transactionCash;
        
        FinancialAccountTransaction  transactionCash1 =  TestdataFactory.createFinancialAccountTransaction(null,'Pending', 100.00,System.Today(),'Credit',testSavingsAccount.Id);
        transactionCash1.Payment_Method__c = 'Cash';
        transactionCash1.Case__c = testCase.Id;
        transactionCash1.status = 'Paid';
        update transactionCash1;
        
        FinancialAccountTransaction  transactionCheque =  TestdataFactory.createFinancialAccountTransaction(null,'Pending', 100.00,System.Today(),'Credit',testSavingsAccount.Id);
        transactionCheque.Payment_Method__c = 'Cheque';
        transactionCheque.Case__c = testCase.Id;
        transactionCheque.status = 'Paid';
        update transactionCheque;
        
        FinancialAccountTransaction  transactionOnline =  TestdataFactory.createFinancialAccountTransaction(null,'Pending', 100.00,System.Today(),'Credit',testSavingsAccount.Id);
        transactionOnline.Payment_Method__c = 'Online';
        transactionOnline.Case__c = testCase.Id;
        transactionOnline.status = 'Paid';
        update transactionOnline;
        
        Denomination__c testDenomination = new Denomination__c(Financial_Account_Transaction__c = transactionCash.Id, Denomination_Value__c = 100, Quantity__c = 2);
        insert testDenomination;
        Denomination__c testDenomination1 = new Denomination__c(Financial_Account_Transaction__c = transactionCash1.Id, Denomination_Value__c = 100, Quantity__c = 2);
        insert testDenomination1;
    }
    
    @IsTest
    static void testInvokeMethodSuccess() {
        // Arrange
        ReceiptMappingHandler handler = new ReceiptMappingHandler();
        Receipt__c testReceipt = [SELECT Id FROM Receipt__c LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>{
            'FromApi' => true,
            'objectId' => testReceipt.Id
        };
        Map<String, Object> inputMap1 = new Map<String, Object>{
            'FromApi' => true
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Act
        Test.startTest();
        Boolean result = handler.invokeMethod('testMethod', inputMap, outputMap, options); 
        handler.invokeMethod('testMethod', inputMap1, outputMap, options);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(false, result,'');
       
    }
    
    @IsTest
    static void testInvokeMethodNoReceipt() {
        // Arrange
        ReceiptMappingHandler handler = new ReceiptMappingHandler();
        List<Case> caseList = [Select Id from Case Limit 1];
        Map<String, Object> inputMap = new Map<String, Object>{
            'FromApi' => true,
            'objectId' => caseList[0].Id
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Act
        Test.startTest();
        Boolean result = handler.invokeMethod('testMethod', inputMap, outputMap, options);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result,'');
    }
    
    @IsTest
    static void testCallMethod() {
        // Arrange
        ReceiptMappingHandler handler = new ReceiptMappingHandler();
        Receipt__c testReceipt = [SELECT Id FROM Receipt__c LIMIT 1];
        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>{
                'FromApi' => true,
                'objectId' => testReceipt.Id
            },
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
        
        // Act
        Test.startTest();
        Object result = handler.Call('testMethod', args);
        Test.stopTest();
        
        // Assert
        System.assert(result instanceof Boolean, 'Result should be a Boolean');
        System.assert((Boolean)result, 'Call method should return true for successful execution');
    }
    
    @IsTest
    static void testTokenDataSerialization() {
        // Arrange
        ReceiptMappingHandler.TokenData tokenData = new ReceiptMappingHandler.TokenData();
        tokenData.bankName = 'Test Bank';
        tokenData.todayDate =Date.today().format();
        tokenData.receiptNumber = 'REC-001';
        tokenData.createdDate = Date.today().format();
        tokenData.fullName = 'John Doe';
        tokenData.loanAccountNumber = '1234567890';
        tokenData.customerAddress = '123 Test St, Test City';
        tokenData.Description = 'Test Description';
        tokenData.showCharges = true;
        tokenData.ChargesData = new List<ReceiptMappingHandler.ChargesAndFessDetails>();
        tokenData.TotalChargesAmount = '100';
        tokenData.RefundData = new List<ReceiptMappingHandler.RefundAndWaiveOffClass>();
        tokenData.TotalRefundAndWaiveOffAmount = '50';
        tokenData.showRefunds = true;
        tokenData.denominationDetails = new List<ReceiptMappingHandler.Denomination>();
        tokenData.showCash = true;
        tokenData.totalDenominationAmount = '200';
        tokenData.showCheque = false;
        tokenData.ChequeDetails = new List<ReceiptMappingHandler.ChequeDetails>();
        tokenData.showOnlineTransaction = false;
        tokenData.OnlineDetails = new List<ReceiptMappingHandler.paymentDetails>();
        tokenData.GrandTotalAmount = '250';
        
        // Act
        String jsonString = JSON.serialize(tokenData);
        ReceiptMappingHandler.TokenData deserializedData = (ReceiptMappingHandler.TokenData)JSON.deserialize(jsonString, ReceiptMappingHandler.TokenData.class);
        
        // Assert
        System.assertEquals(tokenData.bankName, deserializedData.bankName, 'Bank Name should match after serialization and deserialization');
        System.assertEquals(tokenData.ReceiptNumber, deserializedData.ReceiptNumber, 'Receipt Number should match after serialization and deserialization');
        System.assertEquals(tokenData.GrandTotalAmount, deserializedData.GrandTotalAmount, 'Grand Total Amount should match after serialization and deserialization');
    }
}