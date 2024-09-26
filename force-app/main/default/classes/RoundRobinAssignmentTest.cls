/**
 * @author TechMatrix Team
 * @description Test class for Round Robin Assignment
 */
@isTest(seeAllData=true)
public class RoundRobinAssignmentTest {

   /* @isTest
    static void setupTestData() {
        // Create Pincode records
        Pincode__c pincode1 = new Pincode__c(Name = '12345');
        Pincode__c pincode2 = new Pincode__c(Name = '67890');
        insert new List<Pincode__c> { pincode1, pincode2 };
            
        // Create Contact records
        Contact contact1 = new Contact(LastName = 'Contact 1', MailingPostalCode='12345');
        Contact contact2 = new Contact(LastName = 'Contact 2', MailingPostalCode='67890');
        insert new List<Contact> { contact1, contact2 };  
            
        // Create Case records
        Case case1 = new Case(Subject = 'Case 1', ContactId=contact1.Id);
        Case case2 = new Case(Subject = 'Case 2', ContactId=contact2.Id);
        insert new List<Case> { case1, case2 };
            
        // Map to hold the postal code and case ID
        Map<String, Id> postalCodeVsCaseId = new Map<String, Id>();
        postalCodeVsCaseId.put('12345', case1.Id);
        postalCodeVsCaseId.put('67890', case2.Id);
        
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);
        
        Test.startTest();
        RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);

        BranchUnit branchUnit1 = new BranchUnit(Name = 'Branch 1', IsActive = true);
        insert branchUnit1;
        Branch_Pincode_Mapping__c mapping1 = new Branch_Pincode_Mapping__c(Branch_Unit__c = branchUnit1.Id, Pincode__c = pincode1.Id);
        insert mapping1;
        RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);

        Banker banker1 = new Banker(UserOrContactId = contact1.Id, Name='Tested'); 
        insert banker1;
        BranchUnitBusinessMember businessMember1 = new BranchUnitBusinessMember(BranchUnitId = branchUnit1.Id, BusinessUnitMemberId = banker1.Id, IsActive = true);
        insert businessMember1;
        RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);

        Case case3 = new Case(Subject = 'Case 1', FOS_Agent__c=contact1.Id, FOS_Agent_Assigned_Date__c=system.today());
        insert case3;
        RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
        Test.stopTest();
    }

    @isTest
    static void branchPincodeMappingPresent() {
        Pincode__c pincode1 = new Pincode__c(Name = '12345');
        insert pincode1;

        // Creating Contact record
        Contact contact1 = new Contact(LastName = 'Contact 1', MailingPostalCode = '12345');
        insert contact1;

        // Creating Case record
        Case case1 = new Case(Subject = 'Case 1', ContactId = contact1.Id);
        insert case1;

        // Map to hold the postal code and case ID
        Map<String, Id> postalCodeVsCaseId = new Map<String, Id>();
        postalCodeVsCaseId.put('12345', case1.Id);

        // Query Case records
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);

        Test.startTest();
        RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);

        BranchUnit branchUnit1 = new BranchUnit(Name = 'Branch 1', IsActive = true);
        insert branchUnit1;
        Branch_Pincode_Mapping__c mapping1 = new Branch_Pincode_Mapping__c(Branch_Unit__c = branchUnit1.Id, Pincode__c = pincode1.Id);
        insert mapping1;

        List<Branch_Pincode_Mapping__c> mapping2 = [SELECT Id, Branch_Unit__c, Pincode__r.Name, Branch_Unit__r.IsActive 
                                                    FROM Branch_Pincode_Mapping__c 
                                                    WHERE Pincode__r.Name IN :postalCodeVsCaseId.keySet() 
                                                    AND Branch_Unit__r.IsActive = true];
        
        System.assertEquals(1, mapping2.size());
        Test.stopTest();
    }
    
    @isTest
    static void branchPincodeMappingMissing() {
        Pincode__c pincode1 = new Pincode__c(Name = '12345');
        insert pincode1;

        // Creating Contact record
        Contact contact1 = new Contact(LastName = 'Contact 1', MailingPostalCode = '12345');
        insert contact1;

        // Creating Case record
        Case case1 = new Case(Subject = 'Case 1', ContactId = contact1.Id);
        insert case1;

        // Map to hold the postal code and case ID
        Map<String, Id> postalCodeVsCaseId = new Map<String, Id>();
        postalCodeVsCaseId.put('12345', case1.Id);

        // Query Case records
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);

        Test.startTest();
        Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assertEquals(System.Label.No_Branch_Pincode_Found, response.message);
        System.assertEquals(true, response.isError);
    }

    @isTest
    static void branchUnitBusinessMemberMissing() {
        Pincode__c pincode1 = new Pincode__c(Name = '12345');
        insert pincode1;

        // Creating Contact record
        Contact contact1 = new Contact(LastName = 'Contact 1', MailingPostalCode = '12345');
        insert contact1;

        // Creating Case record
        Case case1 = new Case(Subject = 'Case 1', ContactId = contact1.Id);
        insert case1;

        // Map to hold the postal code and case ID
        Map<String, Id> postalCodeVsCaseId = new Map<String, Id>();
        postalCodeVsCaseId.put('12345', case1.Id);

        // Query Case records
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);

        BranchUnit branchUnit1 = new BranchUnit(Name = 'Branch 1', IsActive = true);
        insert branchUnit1;
        Branch_Pincode_Mapping__c mapping1 = new Branch_Pincode_Mapping__c(Branch_Unit__c = branchUnit1.Id, Pincode__c = pincode1.Id);
        insert mapping1;

        Test.startTest();
        Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
        Test.stopTest();

        System.assert(response != null, 'Response should not be null');
        System.assertEquals(System.Label.No_Business_Unit_Found, response.message);
        System.assertEquals(true, response.isError);
    }

    @isTest
    static void contactPresent() {
    Pincode__c pincode1 = new Pincode__c(Name = '12345');
    insert pincode1;

    // Creating Case record
    Case case1 = new Case(Subject = 'Case 1');
    insert case1;

    // Map to hold the postal code and case ID
    Map<String, Id> postalCodeVsCaseId = new Map<String, Id>();
    postalCodeVsCaseId.put('12345', case1.Id);

    // Query Case records
    Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case]);
    
        Contact contact1 = new Contact(LastName = 'Contact 1', MailingPostalCode = '12345');
        insert contact1;

    BranchUnit branchUnit1 = new BranchUnit(Name = 'Branch 1', IsActive = true);
    insert branchUnit1;
    Branch_Pincode_Mapping__c mapping1 = new Branch_Pincode_Mapping__c(Branch_Unit__c = branchUnit1.Id, Pincode__c = pincode1.Id);
    insert mapping1;

    Banker banker1 = new Banker(UserOrContactId = contact1.Id,Name = 'Tested');
    insert banker1;
    BranchUnitBusinessMember businessMember1 = new BranchUnitBusinessMember(BranchUnitId = branchUnit1.Id, BusinessUnitMemberId = banker1.Id, IsActive = true);//, UserOrContactId = banker1.Id
    insert businessMember1;

    Test.startTest();
    Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
    Test.stopTest();

    System.assert(response != null, 'Response should not be null');
    //System.assertEquals(System.Label.No_Contact_Found_Againt_Banker, response.message);
    System.assertEquals(false, response.isError);
}*/
}