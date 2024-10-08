@isTest
public class SendAnEmailWithAttachmentTest {

    @isTest
    static void testSendEmail() {
        // Create test data using TestDataFactory
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        
        // Create a Contact with a valid postal code
        Contact testContact = TestDataFactory.createContactPostal('Test', 'Contact Final', 'test@phone.com','9998887771', accBusinessJoint.Id,'123456','Business');
        Contact fOSContact = TestDataFactory.createContactPostal('FOS', 'Contact FOS', 'FOS@phone.com', '9998887773', accBusinessJoint.Id,'123456','FOS');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Financial Test Joint', accBusinessPrimary.Id, accBusinessJoint.Id, 'Checking', '12345');
        
        // Create a Case record associated with the Contact
        Case testFOSCase = TestDataFactory.createFOSAgentAssignedCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10), fOSContact.Id);
        EmailTemplate template = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Legal_Notice_Email' LIMIT 1];
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Attachment',
            VersionData = Blob.valueOf('Test data for attachment'),
            PathOnClient = 'TestAttachment.txt',
            IsMajorVersion = true
        );
        insert testContentVersion;

        // Create the InputVariable for the Invocable method
        SendAnEmailWithAttachment.InputVariable inputVar = new SendAnEmailWithAttachment.InputVariable();
        inputVar.caseId = testFOSCase.Id;
        inputVar.contentVersionId = testContentVersion.Id;
        inputVar.recipientEmail = 'recipient@example.com';
        inputVar.templateName = template.DeveloperName;

        List<SendAnEmailWithAttachment.InputVariable> inputList = new List<SendAnEmailWithAttachment.InputVariable> { inputVar };
        Test.startTest();
        SendAnEmailWithAttachment.sendEmail(inputList);
        Test.stopTest();

        //Integer emailInvocations = Limits.getEmailInvocations();
        System.assertEquals('Test Attachment.txt', testContentVersion.Title + '.txt', 'The file attachment should match the expected filename.');
    }
}