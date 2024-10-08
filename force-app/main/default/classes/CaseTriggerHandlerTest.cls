/**
 * @description Test class for Case Trigger Handler
 * @author TechMatrix Team
 */
@isTest
public class CaseTriggerHandlerTest {
    
    @isTest
    public static void testOnBeforeUpdate() {
        // Set up test data
        TestData testData = createTestData();
        
        // Start the test execution
        Test.startTest();
        
        // Update case status to 'Paid'
        testData.testCase.Status = 'Paid';
        update testData.testCase;
        
        // Verify the case status after first update
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :testData.testCase.Id];
        System.assertEquals('Paid', updatedCase.Status, 'Case status should be updated to Paid');
        
        // Update case status back to 'Open'
        testData.testCase.Status = 'Open';
        update testData.testCase;
        Test.stopTest();

        Case finalCase = [SELECT Id, Status FROM Case WHERE Id = :testData.testCase.Id];
        System.assertEquals('Open', finalCase.Status, 'Case status should be updated back to Open');
    }
    
    /**
     * @description Creates and returns test data for the test methods
     * @return TestData object containing all the test records
     */
    public static TestData createTestData() {
        TestData data = new TestData();
        
        // Create test accounts
        data.primaryAccount = TestDataFactory.createAccount('Test Account Primary', 'Business');
        data.jointAccount = TestDataFactory.createAccount('Test Account Joint', 'Business');
        
        // Create test financial accounts
        data.financialAccount = TestDataFactory.createFinancialAccount(
            'Financial Test Joint',
            data.primaryAccount.Id,
            data.jointAccount.Id,
            'Savings',
            '12345'
        );
        
        data.savingsAccount = TestDataFactory.createFinancialAccount(
            'Test Savings Account',
            data.primaryAccount.Id,
            data.jointAccount.Id,
            'Savings',
            '67890'
        );
        
        // Create test contacts
        data.businessContact = TestDataFactory.createContact(
            'John', 'Doe', 'johndoe@example.com', '1234567890', 
            data.primaryAccount.Id, '12345', 'Business'
        );
        
        data.fosContact = TestDataFactory.createContact(
            'Jane', 'Smith', 'janesmith@example.com', '9876543210', 
            data.primaryAccount.Id, '67890', 'FOS'
        );
        
        // Create test FOS agent assigned case
        data.testCase = TestDataFactory.createFOSAgentAssignedCase(
            'Test FOS Case',
            data.businessContact.Id,
            data.primaryAccount.Id,
            'Auto Loan',
            data.savingsAccount.Id,
            10000,
            50000,
            Date.today(),
            data.fosContact.Id
        );
        
        return data;
    }
    
    /**
     * @description Inner class to hold test data
     */
    private class TestData {
        public Account primaryAccount;
        public Account jointAccount;
        public FinancialAccount financialAccount;
        public FinancialAccount savingsAccount;
        public Contact businessContact;
        public Contact fosContact;
        public Case testCase;
    }
}