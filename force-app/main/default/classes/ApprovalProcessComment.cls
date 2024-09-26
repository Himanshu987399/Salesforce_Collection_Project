/**
 * @author       TechMatrix Team
 * @description Handles approval process comments for SObjects.
 * This class ensures that comments are mandatory when approving or rejecting records.
 * It provides functionality to check if a comment has been added during the approval
 * or rejection process, and adds an error to the record if a comment is missing.
 */
public with sharing class ApprovalProcessComment {

    /**
     * @description Verifies that comments are provided when a record is approved or rejected.
     * This method is the main entry point for the class functionality. It checks for changes
     * in the approval status of records and ensures that comments are provided for those changes.
     * 
     * @param sobjectRecords List of SObject records being processed in the current transaction
     * @param oldSobjectMap Map of old SObject records, keyed by their Id
     * @param approvalField API name of the field that stores approval status
     * @param approvedName Value of the approval field when the record is approved
     * @param rejectedName Value of the approval field when the record is rejected
     * @param newSobjectMap Map of new SObject records, keyed by their Id
     */
    public static void ensureCommentOnApprovalChange(
        List<SObject> sobjectRecords,
        Map<Id, SObject> oldSobjectMap,
        String approvalField,
        String approvedName,
        String rejectedName,
        Map<Id, SObject> newSobjectMap
    ) {
        Set<Id> changedRecordIds = new Set<Id>();

        for (SObject newRecord : sobjectRecords) {
            Id recordId = (Id)newRecord.get('Id');
            SObject oldRecord = oldSobjectMap.get(recordId);
            
            if (isApprovalStatusChanged(newRecord, oldRecord, approvalField, approvedName, rejectedName)) {
                changedRecordIds.add(recordId);
            }
        }

        if (!changedRecordIds.isEmpty()) {
            validateComments(changedRecordIds, newSobjectMap);
        }
    }

    /**
     * @description Checks if the approval status of a record has changed to either approved or rejected.
     * This method compares the old and new values of the approval field to determine if there's been
     * a change to either the approved or rejected status.
     * 
     * @param newRecord The new version of the SObject record
     * @param oldRecord The old version of the SObject record
     * @param approvalField API name of the field that stores approval status
     * @param approvedName Value of the approval field when the record is approved
     * @param rejectedName Value of the approval field when the record is rejected
     * @return Boolean True if the approval status has changed to approved or rejected, false otherwise
     */
    private static Boolean isApprovalStatusChanged(
        SObject newRecord,
        SObject oldRecord,
        String approvalField,
        String approvedName,
        String rejectedName
    ) {
        String newStatus = (String)newRecord.get(approvalField);
        String oldStatus = (String)oldRecord.get(approvalField);

        return (newStatus == approvedName || newStatus == rejectedName) && newStatus != oldStatus;
    }

    /**
     * @description Validates that comments are provided for records that have changed approval status.
     * This method queries the ProcessInstance and ProcessInstanceStep objects to check if a comment
     * was provided in the most recent approval or rejection step. If no comment is found, it adds
     * an error to the record.
     * 
     * @param recordIds Set of Ids for records that have changed approval status
     * @param newSobjectMap Map of new SObject records, keyed by their Id
     */
    private static void validateComments(Set<Id> recordIds, Map<Id, SObject> newSobjectMap) {
        List<ProcessInstance> processInstances = [
            SELECT Id, TargetObjectId, 
                (SELECT Id, StepStatus, Comments 
                 FROM Steps 
                 WHERE StepStatus IN ('Approved', 'Rejected') 
                 ORDER BY CreatedDate DESC 
                 LIMIT 1)
            FROM ProcessInstance 
            WHERE TargetObjectId IN :recordIds
            WITH SECURITY_ENFORCED
        ];

        for (ProcessInstance proInstance : processInstances) {
            if (!proInstance.Steps.isEmpty()) {
                ProcessInstanceStep lastStep = proInstance.Steps[0];
                if (String.isBlank(lastStep.Comments)) {
                    newSobjectMap.get(proInstance.TargetObjectId).addError(System.Label.Comment_is_mandatory);
                }
            }
        }
    }
}