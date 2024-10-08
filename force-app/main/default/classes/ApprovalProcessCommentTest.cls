@isTest
public class ApprovalProcessCommentTest {
    @isTest
    public static void testFosCaseApprovalProcess() {
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
        User user1 = [SELECT Id, Name, Email FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' Limit 1];
        Test.startTest();
		Approval.ProcessSubmitRequest req1 = 
        new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(testFosCase.id);
        req1.setSubmitterId(user1.Id); 
        req1.setProcessDefinitionNameOrId('Case_Dispute_Approval_Process');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        Approval.ProcessWorkitemRequest req2 = 
        new Approval.ProcessWorkitemRequest();
        req2.setComments('Mandatory Approving request');
        req2.setAction('Approve');
        req2.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result2 =  Approval.process(req2);
        Test.stopTest();
        System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
    }
}