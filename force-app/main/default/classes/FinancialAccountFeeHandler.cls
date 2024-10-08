/**
 * @description Handles trigger operations for FinancialAccountFee objects.
 * This class is responsible for updating related Case records with total EMI due and total amount paid.
 */
public with sharing class FinancialAccountFeeHandler {
    
    /**
     * @description Handles the trigger logic for FinancialAccountFee objects.
     * @param newFees The list of new FinancialAccountFee records (in insert, update, and undelete contexts)
     * @param oldFees The list of old FinancialAccountFee records (in update and delete contexts)
     * @param oldFeeMap A map of old FinancialAccountFee records by Id (in update context)
     * @param triggerEvent The current trigger event (e.g., AFTER_INSERT, AFTER_UPDATE)
     */
    public static void handleTrigger(List<FinancialAccountFee> newFees, List<FinancialAccountFee> oldFees, 
                                     Map<Id, FinancialAccountFee> oldFeeMap, System.TriggerOperation triggerEvent) {
        // Map to store Case Ids and their associated fee types
        Map<Id, Set<String>> caseIdToFeeTypes = new Map<Id, Set<String>>();
        
        // Process fees based on the trigger event
        switch on triggerEvent {
            when AFTER_INSERT, AFTER_UNDELETE {
                processFees(newFees, caseIdToFeeTypes);
            }
            when AFTER_UPDATE {
                processFees(newFees, caseIdToFeeTypes);
                processFees(oldFees, caseIdToFeeTypes);
            }
            when AFTER_DELETE {
                processFees(oldFees, caseIdToFeeTypes);
            }
        }
        
        // Update Case totals if there are any affected Cases
        if (!caseIdToFeeTypes.isEmpty()) {
            updateCaseTotals(caseIdToFeeTypes.keySet());
        }
    }
    
    /**
     * @description Processes a list of FinancialAccountFee records and populates the caseIdToFeeTypes map.
     * @param fees The list of FinancialAccountFee records to process
     * @param caseIdToFeeTypes The map to populate with Case Ids and their associated fee types
     */
    private static void processFees(List<FinancialAccountFee> fees, Map<Id, Set<String>> caseIdToFeeTypes) {
        for (FinancialAccountFee fee : fees) {
            if (fee.Case__c != null) {
                if (!caseIdToFeeTypes.containsKey(fee.Case__c)) {
                    caseIdToFeeTypes.put(fee.Case__c, new Set<String>());
                }
                caseIdToFeeTypes.get(fee.Case__c).add(fee.Type);
            }
        }
    }
    
    /**
     * @description Updates the total EMI due and total amount paid for the specified Case records.
     * @param caseIds The set of Case Ids to update
     */
    private static void updateCaseTotals(Set<Id> caseIds) {
        Map<Id, Case> casesToUpdate = new Map<Id, Case>();
        
        // Query to aggregate fee amounts by Case and fee type
        for (AggregateResult ar : [
            SELECT Case__c, Type, SUM(Amount) totalAmount
            FROM FinancialAccountFee
            WHERE Case__c IN :caseIds 
            AND Case__r.Type = 'Collection Request' WITH SECURITY_ENFORCED
            GROUP BY Case__c, Type 
        ]) {
            Id caseId = (Id)ar.get('Case__c');
            String feeType = (String)ar.get('Type');
            Decimal amount = (Decimal)ar.get('totalAmount');
            
            // Initialize Case record if not already in the map
            if (!casesToUpdate.containsKey(caseId)) {
                casesToUpdate.put(caseId, new Case(Id = caseId, Total_EMI_Due__c = 0, Amount_Paid__c = 0));
            }
            
            Case c = casesToUpdate.get(caseId);
            if (feeType == 'EMI') {
                c.Total_EMI_Due__c += amount;
            }
            c.Amount_Paid__c += amount;
        }
        
        // Update Cases with new totals, allowing partial success
        if (!casesToUpdate.isEmpty()) {
            Database.update(casesToUpdate.values(), false);
        }
    }
}