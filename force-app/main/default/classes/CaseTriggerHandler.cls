/**
* @author       TechMatrix Team
* @description Case Trigger Handler for Handle Case Trigger.
*/
public with sharing class CaseTriggerHandler {
    /**
* @description Ensure Comment mendatory for Approval proccess.
* 
* @param newCase List of new case 
* @param oldCase List of old case
* @param newCaseMap Map of new case
* @param oldCaseMap Map of old case
*/
    public static void onBeforeUpdate( List<Case> newCase, List<Case> oldCase, Map<ID, Case> newCaseMap , Map<ID, Case> oldCaseMap )
    {
        // Case Dispute Approval Process
        ApprovalProcessComment.ensureCommentOnApprovalChange(
            newCase,
            oldCaseMap,
            'Dispute_Status__c',
            'Dispute Approved',
            'Dispute Rejected',
            newCaseMap
        );
        
        // Settlement Approval Process
        ApprovalProcessComment.ensureCommentOnApprovalChange(
            newCase,
            oldCaseMap,
            'Settelment__c',
            'Settlement Approved',
            'Settlement Rejected',
            newCaseMap
        );
        
        List<String> forFalseOpen = new List<String>();
        List<String> forUpdateOpen = new List<String>();
        for (Case newCaseInstance : newCase) {
            Case oldCaseInstance = oldCaseMap.get(newCaseInstance.Id);
            if (newCaseInstance.Status != oldCaseInstance.Status && oldCaseInstance.Status == 'Open' && newCaseInstance.Status != 'Open') {
                forFalseOpen.add(newCaseInstance.Id);
            }
            if (newCaseInstance.Status != oldCaseInstance.Status && oldCaseInstance.Status != 'Open' && newCaseInstance.Status == 'Open') {
                forUpdateOpen.add(newCaseInstance.Id);
            }
        }
        if((!forFalseOpen.isEmpty() || !forUpdateOpen.isEmpty()) && !System.isBatch()){
            updateIsOpen(JSON.serialize(forFalseOpen),JSON.serialize(forUpdateOpen));
        }
    }
    
    /**
* @description future method for approval process comment test
* 
* @param forFalseOpen string 
* @param forTrueOpen string
*/ 
    @future 
    public static void updateIsOpen(String forFalseOpen, String forTrueOpen) {
        List<String> forFalseOpenList = (List<String>)JSON.deserialize(forFalseOpen, List<String>.class);
        List<String> forTrueOpenList = (List<String>)JSON.deserialize(forTrueOpen, List<String>.class);
        List<Case> caseData = new List<Case>();
        for(Case caseInstance : [SELECT Id FROM Case WHERE Id IN :forFalseOpenList WITH SECURITY_ENFORCED]) {
            caseData.add(new Case(Id = caseInstance.Id, Is_Open__c = false));
        }
        for(Case caseInstance : [SELECT Id FROM Case WHERE Id IN :forTrueOpenList WITH SECURITY_ENFORCED]) {
            caseData.add(new Case(Id = caseInstance.Id, Is_Open__c = true));
        }
        
        if(!caseData.isEmpty()){
            update as System caseData;
        }
    }
}