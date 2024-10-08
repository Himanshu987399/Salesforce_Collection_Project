@isTest
public class FinancialAccountFeeHandlerTest {
 
    @isTest
    static void testAfter() {
        // Setup accounts and contacts
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact testContact = TestDataFactory.createContactPostal('Test', 'Contact Final', 'test@phone.com','9998887771', accBusinessJoint.Id,'123456','Business');
        Contact fOSContact = TestDataFactory.createContactPostal('FOS', 'Contact FOS', 'FOS@phone.com', '9998887773', accBusinessJoint.Id,'123456','FOS');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Financial Test Joint', accBusinessPrimary.Id, accBusinessJoint.Id, 'Checking', '12345');
        
        // Create a Case record associated with the Contact
        Case testFOSCase = TestDataFactory.createFOSAgentAssignedCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10), fOSContact.Id);
        
        // Create and insert a FinancialAccountFee record
        FinancialAccountFee feeRecord = new FinancialAccountFee(
            Case__c = testFOSCase.Id,
            FinancialAccountId = financialAccount.Id, 
            Type = 'EMI',
            Amount = 100.00
        );
        insert feeRecord;

        // Update the fee record
        feeRecord.Amount = 150.00;
        update feeRecord;
        
        // Test after update
        Test.startTest();
        FinancialAccountFeeHandler.handleTrigger(
            new List<FinancialAccountFee>{feeRecord}, 
            new List<FinancialAccountFee>{feeRecord}, 
            null, 
            TriggerOperation.AFTER_UPDATE
        );
        Test.stopTest();
        // Assert Case totals after update
        Case updatedCase = [SELECT Total_EMI_Due__c, Amount_Paid__c FROM Case WHERE Id = :testFOSCase.Id];
        System.assertEquals(150.00, updatedCase.Total_EMI_Due__c, 'Total EMI Due should be updated after update.');
        System.assertEquals(150.00, updatedCase.Amount_Paid__c, 'Amount Paid should be updated after update.');
    }

}