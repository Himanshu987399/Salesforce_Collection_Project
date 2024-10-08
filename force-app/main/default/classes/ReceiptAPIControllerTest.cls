/**
* @description Test class for ReceiptAPIController
* @author TechMatrix Team
*/
@isTest
public class ReceiptAPIControllerTest {
    
    /**
* @description Set up test data
*/
    @TestSetup
    static void setupTestData() {
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
            Date.today(),
            testFOSContact.Id
        );
        
        
        // Create test Receipt
        Receipt__c testReceipt = new Receipt__c(Case__c = testCase.Id);
        insert testReceipt;
        
        // Create test Challan
        Challan__c testChallan = new Challan__c();
        insert testChallan;
        
        // Create test Document Templates
        DocumentTemplate receiptTemplate = new DocumentTemplate(
            Name = System.Label.Reciept_Doc_Template,
            IsActive = true,
            TokenMappingType = 'JSON',
            Type = 'MicrosoftWord',
            TokenMappingMethodType = 'CustomClass',
            CustomClassName = 'ReceiptMappingHandler'
        );
        insert receiptTemplate;
        
        DocumentTemplate challanTemplate = new DocumentTemplate(
            Name = System.Label.Challan_Doc_Template,
            IsActive = true,
            TokenMappingType = 'JSON',
            Type = 'MicrosoftWord',
            TokenMappingMethodType = 'CustomClass',
            CustomClassName = 'ChallanMappingHandler'
        );
        insert challanTemplate;
    }
    
    /**
* @description Test successful receipt generation
*/
    @isTest
    static void testGenerateReceiptPdfSuccess() {
        Receipt__c testReceipt = [SELECT Id, Case__c FROM Receipt__c LIMIT 1];
        
        // Set up the REST request
        RestRequest req = new RestRequest();
        req.params.put('recordId', testReceipt.Id);
        req.params.put('fileType', 'Receipt');
        RestContext.request = req;
        
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion;
        
        DocumentTemplateContentDoc tested = new DocumentTemplateContentDoc();
        tested.Name = 'Document';
        tested.DocumentTemplateId = [select id from DocumentTemplate LIMIT 1].Id;
        tested.ContentDocumentId = [select id,ContentDocumentId from contentVersion].ContentDocumentId;
        insert tested;
        
        
        Test.startTest();
        ReceiptAndChallanRestResource.SendResponse response = ReceiptAndChallanRestResource.generateReceiptPdf();
        Test.stopTest();
        System.assertNotEquals('Job ID is blank or null', response.documentProcessId,'');
        
    }   
}