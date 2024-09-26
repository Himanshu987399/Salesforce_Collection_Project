/**
 * @description Batch class to assign FOS agents to cases created in the last day
 * @author TechMatrix Team
 */
public class BatchFOSAgentAssigned implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    /** @description List to store error messages during processing */
    private List<ErrorMessage> errorMessages;

    /** @description Inner class to represent error messages */
    public class ErrorMessage {
        /** @description hold case id while error messages */
        public Id caseId { get; set; }
        /** @description hold message while error messages */
        public String message { get; set; }
    }
    
    /** @description Constructor to initialize error messages list */
    public BatchFOSAgentAssigned() {
        this.errorMessages = new List<ErrorMessage>();
    }
    
    /**
     * @description Start method to query cases created in the last day
     * @param bc BatchableContext
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select Id,WhatId,RecordType.Name,Payment_Mode__c,ActivityDate from Task where ActivityDate = TODAY AND RecordType.Name =: \'PTP\' AND Payment_Mode__c =: \'Offline\' AND Status =: \'Open\'';
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method to process the queried cases
     * @param bc BatchableContext
     * @param taskListData List of Case records to process
     */
    public void execute(Database.BatchableContext bc, List<Task> taskListData) {
        Map<Id, Id> caseIdToTaskId = new Map<Id, Id>();
        List<Task> tasksToUpdate = new List<Task>();
        
        for (Task task : taskListData) {
            caseIdToTaskId.put(task.WhatId, task.Id);
        }
        
        Map<String, List<Id>> postalCodeToCaseId = new Map<String, List<Id>>();
        Map<Id, Case> casesWithoutFOSAgent = new Map<Id, Case>([
            SELECT Id, FOS_Agent__c, ContactId, PTP_Date__c 
            FROM Case 
            WHERE Id IN :caseIdToTaskId.keySet()
        ]);
        
        Map<Id, List<Id>> contactIdToCaseId = new Map<Id, List<Id>>();
        for (Case caseRecord : casesWithoutFOSAgent.values()) {
            if(!contactIdToCaseId.containsKey(caseRecord.ContactId)){
                contactIdToCaseId.put(caseRecord.ContactId, new List<Id>());
            }
            contactIdToCaseId.get(caseRecord.ContactId).add(caseRecord.Id);
        }
        
        processContacts(contactIdToCaseId, postalCodeToCaseId);
        
        Response response = RoundRobinAssignment.assignCaseToFOS(postalCodeToCaseId, casesWithoutFOSAgent, false);
        
        if (response.isError) {
            ErrorMessage error = new ErrorMessage();
            error.message = response.message;
            errorMessages.add(error);
        } else {
            if(!response.caseList.isEmpty()){
                for (Case updatedCase : response.caseList) {
                    tasksToUpdate.add(new Task(
                        Status = 'Completed',
                        Id = caseIdToTaskId.get(updatedCase.Id)
                    )); 
                }
                if (!tasksToUpdate.isEmpty()) {
                    update tasksToUpdate;
                } 
            }
            
        }
    }
    
    /**
     * @description Process contacts related to cases
     * @param contactIdToCaseId Map of Contact Id to Case Id
     * @param postalCodeToCaseId Map to store Postal Code to Case Id
     */
    private void processContacts(Map<Id, List<Id>> contactIdToCaseId, Map<String, List<Id>> postalCodeToCaseId) {
        for (Contact conInstance : [SELECT Id, MailingPostalCode FROM Contact WHERE Id IN :contactIdToCaseId.keySet()]) {
            if (String.isBlank(conInstance.MailingPostalCode)) {
                ErrorMessage err = new ErrorMessage();
                err.caseId = String.join( contactIdToCaseId.get(conInstance.Id), ',' );
                err.message = System.Label.Postal_Code_Missing;
                errorMessages.add(err);
            } else {
               // for(String case)
                //if(!postalCodeToCaseId.containsKey(conInstance.MailingPostalCode)){
                  //  postalCodeToCaseId.put(conInstance.MailingPostalCode, new List<Id>());
                //}
                
                postalCodeToCaseId.put(conInstance.MailingPostalCode,contactIdToCaseId.get(conInstance.Id));
            }
        }
    }
    
    /**
     * @description Finish method to handle any post-processing tasks
     * @param bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {

    }
     
    /**
     * @description Schedulable execute method to run the batch job
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchFOSAgentAssigned());
    }
    
    /**
     * @description Method to schedule the job
     * @param jobName Name of the scheduled job
     * @param cronExp Cron expression for job scheduling
     */
    public static void scheduleJob(String jobName, String cronExp) {
        System.schedule(jobName, cronExp, new BatchFOSAgentAssigned());
    }
    
}