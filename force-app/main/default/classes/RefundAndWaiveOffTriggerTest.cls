@isTest
public class RefundAndWaiveOffTriggerTest {
    @isTest
    public static void RefundAndWaiveOffTest() {
        // Create test data
        Account primaryTestAccount = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account jointTestAccount = TestDataFactory.createAccount('Test Account Joint', 'Business');
        
        Contact testContactPostal = TestDataFactory.createContactPostal(
            'Test', 'Contact Final', 'test@example.com', '9998887771', 
            jointTestAccount.Id, '12345', 'Business'
        );
        
        FinancialAccount testFinancialAccount = TestDataFactory.createFinancialAccount(
            'Financial Test Joint', primaryTestAccount.Id, jointTestAccount.Id, 
            'Checking', '12345'
        );
        
        Contact testFosContact = TestDataFactory.createContact(
            'FOS', 'Contact FOS', 'fos@example.com', '9998887773', 
            jointTestAccount.Id, '1234567', 'FOS'
        );
        
        Case testFosCase = TestDataFactory.createFOSAgentAssignedCase(
            'Test Case', testContactPostal.Id, jointTestAccount.Id, 'Auto Loan', 
            testFinancialAccount.Id, 98000, 100000, Date.today().addDays(-10), 
            testFosContact.Id
        );

        // Start test context
        Test.startTest();

        testFosCase.Dispute_Status__c = 'Dispute Approved'; 
        testFosCase.Comments = 'test';
        update testFosCase;

        // End test context
        Test.stopTest();
        system.assertEquals('Contact Final',testContactPostal.LastName,'name must be same');
    }

}