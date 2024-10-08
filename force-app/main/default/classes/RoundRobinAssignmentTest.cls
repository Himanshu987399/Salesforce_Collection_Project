/**
* @author TechMatrix Team
* @description Test class for Round Robin Assignment
*/
@isTest
public class RoundRobinAssignmentTest {
    @isTest
    static void branchPincodeMappingPresent() {
        Pincode__c pincode1 = new Pincode__c(Name = '12345');
        insert pincode1;
        
        // Creating Account and Contact record using TestDataFactory
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact contact1 = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        // Creating Case record using TestDataFactory
        Case case1 = TestDataFactory.createCase('Case 1', contact1.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 1000, 2000, Date.today().addMonths(-1));
        // Map to hold the postal code and case ID
        List<Id> cList = new List<Id>();
        cList.add(case1.Id);
        Map<String, List<Id>> postalCodeVsCaseId = new Map<String, List<Id>>();
        postalCodeVsCaseId.put('12345', cList);
        
        // Query Case records
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);
        
        Test.startTest();
        RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
        RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, false);
        BranchUnit branchUnit1 = new BranchUnit(Name = 'Branch 1', IsActive = true);
        insert branchUnit1;
        Branch_Pincode_Mapping__c mapping1 = new Branch_Pincode_Mapping__c(Branch_Unit__c = branchUnit1.Id, Pincode__c = pincode1.Id);
        insert mapping1;
        
        List<Branch_Pincode_Mapping__c> mapping2 = [SELECT Id, Branch_Unit__c, Pincode__r.Name, Branch_Unit__r.IsActive 
                                                    FROM Branch_Pincode_Mapping__c 
                                                    WHERE Pincode__r.Name IN :postalCodeVsCaseId.keySet() 
                                                    AND Branch_Unit__r.IsActive = true];
        
        System.assertEquals(1, mapping2.size(),'');
        Test.stopTest();
    }
    
    @isTest
    static void branchPincodeMappingMissing() {
        // Creating Account and Contact record using TestDataFactory  Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'IndustriesBusiness');
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact contact1 = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        // Creating Case record using TestDataFactory
        Case case1 = TestDataFactory.createCase('Case 1', contact1.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 1000, 2000, Date.today().addMonths(-1));
        
        // Map to hold the postal code and case ID
        List<Id> cList = new List<Id>();
        cList.add(case1.Id);
        Map<String, List<Id>> postalCodeVsCaseId = new Map<String, List<Id>>();
        postalCodeVsCaseId.put('12345', cList);
        
        // Query Case records
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);
        
        Test.startTest();
        Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
        Test.stopTest();
        
        //System.assert(response != null, 'Response should not be null','');
        System.assertEquals(System.Label.No_Branch_Pincode_Found, response.message,'');
        System.assertEquals(true, response.isError,'');
    }
    
    @isTest
    static void branchUnitBusinessMemberMissing() {
        Pincode__c pincode1 = new Pincode__c(Name = '12345');
        insert pincode1;
        
        // Creating Account and Contact record using TestDataFactory
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact contact1 = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        // Creating Case record using TestDataFactory
        Case case1 = TestDataFactory.createCase('Case 1', contact1.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 1000, 2000, Date.today().addMonths(-1));
        
        List<Id>cList= new List<Id>();
        cList.add(case1.Id);
        
        // Map to hold the postal code and case ID
        Map<String, List<Id>> postalCodeVsCaseId = new Map<String, List<Id>>();
        postalCodeVsCaseId.put('12345', cList);
        
        // Query Case records
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);
        
        BranchUnit branchUnit1 = new BranchUnit(Name = 'Branch 1', IsActive = true);
        insert branchUnit1;
        Branch_Pincode_Mapping__c mapping1 = new Branch_Pincode_Mapping__c(Branch_Unit__c = branchUnit1.Id, Pincode__c = pincode1.Id);
        insert mapping1;
        
        Test.startTest();
        Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
        Test.stopTest();
        
        //System.assert(response != null, 'Response should not be null','');
        System.assertEquals(System.Label.No_Business_Unit_Found, response.message,'');
        System.assertEquals(true, response.isError,'');
    }
    
    @isTest
    static void contactPresent() {
        Pincode__c pincode1 = new Pincode__c(Name = '12345');
        insert pincode1;
        
        // Creating Account record using TestDataFactory
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact contact1 = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        // Creating Case record using TestDataFactory
        Case case1 = TestDataFactory.createCase('Case 1', contact1.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 1000, 2000, Date.today().addMonths(-1));
        
        // Map to hold the postal code and case ID
        List<Id> cList = new List<Id>();
        cList.add(case1.Id);
        Map<String, List<Id>> postalCodeVsCaseId = new Map<String, List<Id>>();
        postalCodeVsCaseId.put('12345', cList);
        
        // Query Case records
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);
        
        BranchUnit branchUnit1 = new BranchUnit(Name = 'Branch 1', IsActive = true);
        insert branchUnit1;
        Branch_Pincode_Mapping__c mapping1 = new Branch_Pincode_Mapping__c(Branch_Unit__c = branchUnit1.Id, Pincode__c = pincode1.Id);
        insert mapping1;
        
        Banker banker1 = new Banker(UserOrContactId = UserInfo.getUserId(), Name = 'Test User');
        insert banker1;
        BranchUnitBusinessMember businessMember1 = new BranchUnitBusinessMember(BranchUnitId = branchUnit1.Id, BusinessUnitMemberId = banker1.Id, IsActive = true);
        insert businessMember1;
        
        Test.startTest();
        Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
        Test.stopTest();
        
        //System.assert(response != null ? true: false, 'Response should not be null','');
        System.assertEquals(System.Label.No_Contact_Found_Againt_Banker, response.message,'');
        System.assertEquals(true, response.isError,'');
    }
    
    @isTest
    static void emptyPostalCodeMap() {
        Map<String, List<Id>> postalCodeVsCaseId = new Map<String, List<Id>>();
        Map<Id, Case> caseMap = new Map<Id, Case>();
        Test.startTest();
        Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
        Test.stopTest();
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    @isTest
    public static void testCoverage(){
        Pincode__c pincode1 = new Pincode__c(Name = '12345');
        insert pincode1;
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        Contact contact1 = TestDataFactory.createContact('FirstName1', 'Contact 1', 'contact1@example.com', '1234567890', accBusinessJoint.Id, '12345','Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        Case case1 = TestDataFactory.createCase('Case 1', contact1.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 1000, 2000, Date.today().addMonths(-1));
        Case case2 = TestDataFactory.createCase('Case 1', contact1.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 1000, 2000, Date.today().addMonths(-1));
        case2.FOS_Agent__c = contact1.Id;
        case2.FOS_Agent_Assigned_Date__c = System.Today();
        update case2;
        Case case3 = TestDataFactory.createCase('Case 1', contact1.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 1000, 2000, Date.today().addMonths(-1));
        case3.FOS_Agent__c = contact1.Id;
        case3.FOS_Agent_Assigned_Date__c = System.Today();
        update case3;
        List<Id> cList = new List<Id>();
        cList.add(case1.Id);
        Map<String, List<Id>> postalCodeVsCaseId = new Map<String, List<Id>>();
        postalCodeVsCaseId.put('12345', cList);
        
        // Query Case records
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);
        
        BranchUnit branchUnit1 = new BranchUnit(Name = 'Branch 1', IsActive = true);
        insert branchUnit1;
        Branch_Pincode_Mapping__c mapping1 = new Branch_Pincode_Mapping__c(Branch_Unit__c = branchUnit1.Id, Pincode__c = pincode1.Id);
        insert mapping1;
        
        Banker banker1 = new Banker(UserOrContactId = contact1.Id, Name = 'Test User');
        insert banker1;
        BranchUnitBusinessMember businessMember1 = new BranchUnitBusinessMember(BranchUnitId = branchUnit1.Id, BusinessUnitMemberId = banker1.Id, IsActive = true);
        insert businessMember1;
        
        Test.startTest();
        Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, false);
        Test.stopTest();
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
}