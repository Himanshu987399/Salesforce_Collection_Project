@isTest
public class ChallanMappingHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact testContact = TestDataFactory.createContactPostal('Test', 'Contact Final', 'test@phone.com','9998887771', accBusinessJoint.Id,'123456','Business');
        Contact fOSContact = TestDataFactory.createContactPostal('FOS', 'Contact FOS', 'FOS@phone.com', '9998887773', accBusinessJoint.Id,'123456','FOS');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint', accBusinessPrimary.Id, accBusinessJoint.Id, 'Checking', '12345');

        // Create a branch unit for the Challan
        BranchUnit branchUnit = new BranchUnit(Name = 'Test Branch');
        insert branchUnit;

        // Create FinancialAccountTransaction with Status = 'Paid' and Receipts for the Challan
        Case testFOSCase = TestDataFactory.createFOSAgentAssignedCase('Test Case', testContact.Id, accBusinessJoint.Id, 
                                                                      'Auto Loan', financialAccount.Id, 98000, 100000,
                                                                      Date.today().addDays(-10), fOSContact.Id);
        
        Receipt__c receipt = new Receipt__c(Case__c = testFOSCase.Id);
        insert receipt;
        
        // Create a Challan
        Challan__c challan = new Challan__c(
            Challan_Date__c = System.today(),
            FOS_User__c = fOSContact.Id,
            Branch_Unit__c = branchUnit.Id
        );
        insert challan;
        
        FinancialAccountTransaction  transactionFin =  TestdataFactory.createFinancialAccountTransaction('Mock Id','Paid', 1000.00,
                                                                                                         System.Today()+1,'Credit',
                                                                                                         financialAccount.Id);
        transactionFin.Challan__c = challan.Id;
        transactionFin.Case__c = testFOSCase.Id;
        transactionFin.Payment_Method__c = 'Cash';
        update transactionFin;

        Denomination__c denomination = new Denomination__c(
            Financial_Account_Transaction__c = transactionFin.Id,
            Denomination_Value__c = 500,
            Quantity__c = 2
        );
        insert denomination;    
    }
    
    @isTest
    static void testInvokeMethodSuccess() {
        Challan__c challan = [SELECT Id FROM Challan__c LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectId' => challan.Id
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        ChallanMappingHandler handler = new ChallanMappingHandler();
        Boolean result = handler.invokeMethod('someMethod', inputMap, outputMap, new Map<String, Object>());

        System.assertEquals(true, result, 'invokeMethod should return true for valid challan');
        System.assert(outputMap.containsKey('responseData'), 'Output map should contain responseData');

        String responseData = (String) outputMap.get('responseData');
        ChallanMappingHandler.TokenData tokenData = (ChallanMappingHandler.TokenData) JSON.deserialize(responseData, ChallanMappingHandler.TokenData.class);       

        // Validate TransactionDetails
        System.assertNotEquals(null, tokenData.ReceiptDetails, 'ReceiptDetails should not be null');
        System.assertEquals(1, tokenData.ReceiptDetails.size(), 'There should be 1 transaction');
        ChallanMappingHandler.TransactionDetails transactionDetails = tokenData.ReceiptDetails[0];
        System.assertEquals('12345', transactionDetails.loanAccountNumber, 'Loan account number should match');
        System.assertEquals('1000', transactionDetails.receiptAmount, 'Receipt amount should match');
        System.assertEquals('Cash', transactionDetails.paymentMethod, 'Payment method should match');

        // Validate Denomination
        System.assertNotEquals(null, tokenData.denominationDetails, 'Denomination details should not be null');
        System.assertEquals(1, tokenData.denominationDetails.size(), 'There should be 1 denomination');
        ChallanMappingHandler.Denomination denomination = tokenData.denominationDetails[0];
        System.assertEquals(500, denomination.denominationValue, 'Denomination value should match');
        System.assertEquals(2, denomination.denominationNotes, 'Denomination notes should match');
        System.assertEquals('1000', denomination.denominationAmount, 'Denomination amount should match');
    }

    @isTest
    static void testInvokeMethodNoChallan() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectId' => 'invalidChallanId'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        ChallanMappingHandler handler = new ChallanMappingHandler();
        Boolean result = handler.invokeMethod('someMethod', inputMap, outputMap, new Map<String, Object>());
        System.assertEquals(false, result, 'invokeMethod should return false for invalid challan ID');
        System.assertEquals('No Challan found with the given ID', outputMap.get('errorMessage'), 'Error message should be correct');
    }

    @isTest
    static void testInvokeMethodExceptionHandling() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectId' => null 
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        ChallanMappingHandler handler = new ChallanMappingHandler();
        Boolean result = handler.invokeMethod('someMethod', inputMap, outputMap, new Map<String, Object>());
        System.assertEquals(false, result, 'invokeMethod should return false in case of exception');
        System.assertNotEquals(null, outputMap.get('errorMessage'), 'Error message should be populated on exception');
    }
}