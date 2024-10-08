@isTest
public class BatchFOSAgentAssignedTest {
    @isTest
    static void testExecuteBatchClass() {
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
        Case testFOSCase = TestDataFactory.createFOSAgentAssignedCase(
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
        
        // Create a Task related to the Case
        Task testPTPTask = new Task(
            WhatId = testFOSCase.Id,
            Status = 'Open',
            ActivityDate = Date.today(),
            Payment_Mode__c = 'Offline',
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'PTP' AND SObjectType = 'Task' LIMIT 1].Id
        );
        insert testPTPTask;
        
        // Create test Pincode
        Pincode__c testPincode = new Pincode__c(Name = '12345');
        insert testPincode;
        
        // Create test Branch Unit
        BranchUnit testBranchUnit = new BranchUnit(Name = 'Branch 1', IsActive = true);
        insert testBranchUnit;
        
        // Create test Branch Pincode Mapping
        Branch_Pincode_Mapping__c testBranchPincodeMapping = new Branch_Pincode_Mapping__c(
            Branch_Unit__c = testBranchUnit.Id,
            Pincode__c = testPincode.Id
        );
        insert testBranchPincodeMapping;
        
        // Create test Banker
        Banker testBanker = new Banker(UserOrContactId = testFOSContact.Id, Name = 'Test User');
        insert testBanker;
        
        // Create test Branch Unit Business Member
        BranchUnitBusinessMember testBusinessMember = new BranchUnitBusinessMember(
            BranchUnitId = testBranchUnit.Id,
            BusinessUnitMemberId = testBanker.Id,
            IsActive = true
        );
        insert testBusinessMember;
        
        Test.startTest();
        // Schedule the batch job
        String testJobName = 'Test FOS Agent Assignment Batch';
        String testCronExpression = '0 0 12 * * ?'; // Every day at 12 PM
        BatchFOSAgentAssigned.scheduleJob(testJobName, testCronExpression);
        Test.stopTest();
         System.assertEquals(testFOSContact.Id, testFOSCase.FOS_Agent__c,'');
       
    }
}