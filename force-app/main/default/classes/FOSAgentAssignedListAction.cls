/**
 * @author       TechMatrix Team
 * @description   The class for assigning FOS agent and returning success or error message in flow
 */
public with sharing class FOSAgentAssignedListAction {
    
    /**
     * @description Assigns FOS agent and returns success or error message
     * @param inputVal List of InputVariable containing case ID
     * @return List<OutputVariable> containing status message and error information
     */
    @InvocableMethod(label='Assigned FOS Agent' description='Returns message while assigning FOS.')
    public static List<OutputVariable> assignedFosAgent(List<InputVariable> inputVal) {
        String caseId ;
        try {

            // Get the case ID from the input variables
            caseId = inputVal[0].caseId;
            
            // Query to retrieve the case with the given case ID
            Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, FOS_Agent__c FROM Case WHERE Id = :caseId LIMIT 1]);
            
            // Check if the case was found
            if (caseMap.isEmpty()) {
                return new List<OutputVariable> {new OutputVariable(System.Label.No_Case_Found, true,null)};
            }
            
            // Get the case object from the map
            Case caseValue = caseMap.get(caseId);
            
            // Check if the case has a related FOS Agent
          /*  if (String.isNotBlank(caseValue.FOS_Agent__c)) {
                return new List<OutputVariable> {new OutputVariable(System.Label.FOS_Agent_Assigned, true,null)};
            }*/
   
            // Query to retrieve the contact associated with the case
            List<Contact> conList = [SELECT Id, MailingPostalCode FROM Contact WHERE Is_Active__c = True AND Id = :caseValue.ContactId WITH SECURITY_ENFORCED LIMIT 1];
            
            // Check if the contact's postal code is missing
            if (!conList.isEmpty() && String.isBlank(conList[0].MailingPostalCode)) {
                return new List<OutputVariable> {new OutputVariable(System.Label.Postal_Code_Missing, true,null)};
            }
            
            // Map to hold the postal code and case ID
            Map<String, List<Id>> postalCodeVsCaseId = new Map<String, List<Id>>();
            if (!conList.isEmpty()) {
                List<Id> ids = new List<Id>();
                ids.add(caseId);
                postalCodeVsCaseId.put(conList[0].MailingPostalCode,ids);
            }
            
            // Call the custom method for further processing if necessary
            Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeVsCaseId, caseMap, true);
			
            // Return the response message and error status
            return new List<OutputVariable>{new OutputVariable(response.message, response.isError,response.fosContactList)};
        } catch (Exception ex) {
            CollectionUtility.createErrorLogRecord(caseId,'FOSAgentAssignedListAction','assignedFosAgent',ex.getStackTraceString(),ex.getLineNumber(), ex.getTypeName() + ' in Assigned FOS Agent Process', ex.getMessage());
            // Handle any exceptions and return the error message
            return new List<OutputVariable> {new OutputVariable(ex.getMessage(), true,null)};
        }
    }
    
    /**
     * @description Inner class to represent input variables for the invocable method
     */
    public class InputVariable {
        @InvocableVariable(required=true label='Case Record Id')
        public String caseId;
    }
    
    /**
     * @description Inner class to represent output variables for the invocable method
     */
    public class OutputVariable {
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        @InvocableVariable(label='Is Error')
        public boolean isError;
        @InvocableVariable(label = 'FOSContactList')
        public List<Contact> fosContactList;
        
        /**
         * @description Constructor to initialize output variables
         * @param errorMessageP Error message if any
         * @param isErrorP Flag indicating if there's an error
         * @param contactList List of Contacts
         */
        public OutputVariable(String errorMessageP, Boolean isErrorP,List<Contact> contactList) {
            errorMessage = errorMessageP;
            isError = isErrorP;
            fosContactList = contactList;
        }
    }
}