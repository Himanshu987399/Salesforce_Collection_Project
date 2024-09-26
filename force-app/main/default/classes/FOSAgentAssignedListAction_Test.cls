/**
 * @author TechMatrix Team
 * @description Test class for FOS agent assigned action 
 */
@isTest
private class FOSAgentAssignedListAction_Test { 
    /*@isTest
    static void testAssignedFosAgent_NoCaseFound() {//method when no case is found or invlaid case is found
        FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
        input.caseId = '0'; // Non-existing case ID

        List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable>{input};
        List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertEquals(Label.No_Case_Found, result[0].errorMessage);
    }

    @isTest
    static void testAssignedFosAgent_NoRelatedContact() {
        //Creating a test case with no related contact
        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        insert testCase;

        FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
        input.caseId = testCase.Id;

        List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable>{input};
        List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertEquals(Label.No_Related_Contact_Found, result[0].errorMessage);
    }

    @isTest
    static void testAssignedFosAgent_FosAgentAlreadyAssigned() {
        // Creating a FOS agent contact
        Contact agentFOS = new Contact(FirstName = 'AgentFOS', LastName = 'Test');
        insert agentFOS;

        // Creating a test case with a FOS agent already assigned
        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.FOS_Agent__c = agentFOS.Id; 
        testCase.ContactId = agentFOS.Id; 
        insert testCase;

        FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
        input.caseId = testCase.Id;

        List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable>{input};
        List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError); 
        System.assertEquals(Label.FOS_Agent_Assigned, result[0].errorMessage);
    }

    @isTest
    static void testAssignedFosAgent_PostalCodeMissing() {
        // Creating a test contact without a postal code
        Contact testContact = new Contact(LastName = 'Doe');
        insert testContact;

        // Creating a test case related to the contact
        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.ContactId = testContact.Id;
        insert testCase;

        FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
        input.caseId = testCase.Id;

        List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable>{input};
        List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertEquals(Label.Postal_Code_Missing, result[0].errorMessage);
    }

    @isTest
    static void testAssignedFosAgent_Success() {
        // Creating a test contact with a postal code
        Contact testContact = new Contact(LastName = 'Doe', MailingPostalCode = '12345');
        insert testContact;

        // Creating a test case related to the contact
        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.ContactId = testContact.Id;
        insert testCase;

        FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
        input.caseId = testCase.Id;

        List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable>{input};
        
        // Mock the response RoundRobinAssignment
        Test.startTest();
        List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);
        Test.stopTest();

        // Assert the result based on the mock response
        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
    }*/
}