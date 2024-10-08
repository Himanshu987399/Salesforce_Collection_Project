/**
 * @author TechMatrix Team
 * @description Test class for FOS agent assigned action 
 */
@isTest
private class FOSAgentAssignedListAction_Test {

    @isTest
    static void testAssignedFosAgentNoCaseFound() {
        FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
        input.caseId = '0'; // Non-existing case ID

        List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable>{input};
        List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);

        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        System.assertEquals(Label.No_Case_Found, result[0].errorMessage,'');
    }
    
     @isTest
    static void testAssignedFosAgentPostalCodeMissing()
    {
    	Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
    	Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
    
    	Contact testContact = TestDataFactory.createContact('Test', 'Contact Final', 'test@phone.com','9998887771', accBusinessJoint.Id,null,'Business');
    
    	FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
    
    	// Create the Case record without assigning the Id field
    	Case testFOSCase = TestDataFactory.createFOSAgentAssignedCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10),null);
		/*FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
        input.caseId = testFOSCase.Id;

        List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable>{input};
        List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);*/
        
        
        FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
    	input.caseId = testFOSCase.Id;

    	List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable> { input };

    	Test.startTest();
    	List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);
    	Test.stopTest();

        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        System.assertEquals(Label.Postal_Code_Missing, result[0].errorMessage,'');
    }

     
        @isTest
        static void testAssignedFosAgentSuccess()
        {
         Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
         Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
    
    	Contact testContact = TestDataFactory.createContactPostal('Test', 'Contact Final', 'test@phone.com','9998887771', accBusinessJoint.Id,'123456','Business');
    	Contact fOSContact = TestDataFactory.createContactPostal('FOS', 'Contact FOS', 'FOS@phone.com', '9998887773', accBusinessJoint.Id,'123456','FOS');
    
    	FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
    
    	// Create the Case record without assigning the Id field
    	Case testFOSCase = TestDataFactory.createFOSAgentAssignedCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10),fOSContact.Id);

        FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
        input.caseId = testFOSCase.Id;

        List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable>{input};
        
        // Mock the response RoundRobinAssignment
        Test.startTest();
        List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);
        Test.stopTest();

        // Assert the result based on the mock response
        System.assertEquals(1, result.size(),'');
        System.assertEquals(true, result[0].isError,'');
        }
    
    @IsTest
static void testPostalCodeVsCaseIdMapping() {
    // Create test data
    Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
    Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
    
    // Create a Contact with a valid postal code
    Contact testContact = TestDataFactory.createContactPostal('Test', 'Contact Final', 'test@phone.com','9998887771', accBusinessJoint.Id,'123456','Business');
    Contact fOSContact = TestDataFactory.createContactPostal('FOS', 'Contact FOS', 'FOS@phone.com', '9998887773', accBusinessJoint.Id,'123456','FOS');

    FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
    // Create a Case record associated with the Contact
    Case testFOSCase = TestDataFactory.createFOSAgentAssignedCase('Test Case', testContact.Id, accBusinessJoint.Id, 'Auto Loan', financialAccount.Id, 98000, 100000, Date.today().addDays(-10),fOSContact.Id);
    
    // Prepare input for the FOSAgentAssignedListAction method
    FOSAgentAssignedListAction.InputVariable input = new FOSAgentAssignedListAction.InputVariable();
    input.caseId = testFOSCase.Id;

    List<FOSAgentAssignedListAction.InputVariable> inputList = new List<FOSAgentAssignedListAction.InputVariable> { input };

    Test.startTest();
    List<FOSAgentAssignedListAction.OutputVariable> result = FOSAgentAssignedListAction.assignedFosAgent(inputList);
    Test.stopTest();

    System.assertEquals(1, result.size(), 'The result list should contain one element.');
}

}