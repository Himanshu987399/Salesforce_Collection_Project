/**
* @Author       TechMatrix Team
* @description  The class for assigning FOS agent based on round robin
*
*/
public without sharing class RoundRobinAssignment {
    /**
* @description  Method to assign dispute approved cases to FOS agent
* @param pCodeVsCaseId
* @param newCaseMap
* @param callFromButton
* @return Response
*/
    public static Response assignCaseToFOS(Map<String, List<Id>> pCodeVsCaseId, Map<Id, Case> newCaseMap, Boolean callFromButton) {
        Savepoint sp = Database.setSavepoint(); 
        try {
            List<Branch_Pincode_Mapping__c> branchPincodeMappingList = [
                SELECT Id, Branch_Unit__c, Pincode__r.Name, Branch_Unit__r.IsActive 
                FROM Branch_Pincode_Mapping__c 
                WHERE Pincode__r.Name IN :pCodeVsCaseId.keySet() 
                AND Branch_Unit__r.IsActive = true
            ];
            
            if (branchPincodeMappingList.isEmpty()) {
                return handleEmptyResult(callFromButton, System.Label.No_Branch_Pincode_Found, newCaseMap.keySet());
            }
            
            Map<String, String> branchUnitIdVsPostalCode = new Map<String, String>();
            for (Branch_Pincode_Mapping__c mapping : branchPincodeMappingList) {
                branchUnitIdVsPostalCode.put(mapping.Branch_Unit__c, mapping.Pincode__r.Name);
            }
            List<BranchUnitBusinessMember> brUnBuMeList = [
                SELECT Id, BranchUnitId, BusinessUnitMemberId 
                FROM BranchUnitBusinessMember 
                WHERE BranchUnitId IN :branchUnitIdVsPostalCode.keySet() 
                AND IsActive = true
                
            ];
            
            if (brUnBuMeList.isEmpty()) {
                return handleEmptyResult(callFromButton, System.Label.No_Business_Unit_Found, newCaseMap.keySet());
            }
            
            Map<String, String> businessUnitMemIdVsPostalCode = new Map<String, String>();
            for (BranchUnitBusinessMember brUnBuMeInstance : brUnBuMeList) {
                businessUnitMemIdVsPostalCode.put(brUnBuMeInstance.BusinessUnitMemberId, branchUnitIdVsPostalCode.get(brUnBuMeInstance.BranchUnitId));
            }
            
            List<Banker> bankerList = [
                SELECT Id, UserOrContactId 
                FROM Banker 
                WHERE Id IN :businessUnitMemIdVsPostalCode.keySet()
                
            ];
            
            if (bankerList.isEmpty()) {
                return handleEmptyResult(callFromButton, System.Label.No_Banker_Found, newCaseMap.keySet());
            }
            
            Map<String, String> contactIdVSBankerId = new Map<String, String>();
            for (Banker bankerInstance : bankerList) {
                contactIdVSBankerId.put(bankerInstance.UserOrContactId, bankerInstance.Id);
            }
            
            List<Contact> contactList = [
                SELECT Id,Email,Name,Is_Active__c
                FROM Contact 
                WHERE Id IN :contactIdVSBankerId.keySet()
                AND Is_Active__c = true
                WITH USER_MODE
                
            ];
            
            if (contactList.isEmpty()) {
                return handleEmptyResult(callFromButton, System.Label.No_Contact_Found_Againt_Banker, newCaseMap.keySet());
            }
            if(callFromButton){
                Response response = new Response('',false);
                response.fosContactList = contactList;
                return response;
            }
            
            
            Map<String, List<Contact>> caseIdVsListOfContact = new Map<String, List<Contact>>();
            Set<Id> contactIds = new Set<Id>();
            for (Contact conInstance : contactList) {
                contactIds.add(conInstance.Id);
                List<String> caseIds = pCodeVsCaseId.get(businessUnitMemIdVsPostalCode.get(contactIdVSBankerId.get(conInstance.Id)));
                for(String caseIdsInstance : caseIds){
                    if (!caseIdVsListOfContact.containsKey(caseIdsInstance)) {
                        caseIdVsListOfContact.put(caseIdsInstance, new List<Contact>());
                    }
                    caseIdVsListOfContact.get(caseIdsInstance).add(conInstance);                    
                }
            }
            
            
            Map<Id, Integer> fosAgentIdVsNoOfCaseAssign = new Map<Id, Integer>();
            List<Case> assignedCaseListOfFosAgent = [
                SELECT Id, FOS_Agent__c, Status, FOS_Agent_Assigned_Date__c
                FROM Case 
                WHERE FOS_Agent__c IN :contactIds AND FOS_Agent_Assigned_Date__c = :System.today() 
                WITH USER_MODE
                
            ];
            for (Case caseInstance : assignedCaseListOfFosAgent) {
                Id agentId = caseInstance.FOS_Agent__c;
                if (fosAgentIdVsNoOfCaseAssign.containsKey(agentId)) {
                    fosAgentIdVsNoOfCaseAssign.put(agentId, fosAgentIdVsNoOfCaseAssign.get(agentId) + 1);
                } else {
                    fosAgentIdVsNoOfCaseAssign.put(agentId, 1);
                }
            }
            
            
            List<Case> caseList = new List<Case>();
            Set<Id> caseIds = new Set<Id>();
            for (String caseId : caseIdVsListOfContact.keySet()) {
                Id assignedFOSAgent = getLeastRecentlyAssignedFOS(caseIdVsListOfContact.get(caseId), fosAgentIdVsNoOfCaseAssign);
                if (assignedFOSAgent != null) {
                    caseList.add(new Case(Id = caseId,Status = 'Assigned to FOS Agent', Visit_Date__c = system.Today() ,FOS_Agent__c = assignedFOSAgent, FOS_Agent_Assigned_Date__c = System.today()));
                } else {
                    caseIds.add(caseId);
                }
            }
            
            if (!caseIds.isEmpty()) {
                return assignedCaseToQueue(caseIds,callFromButton);
            }
            
            if (!caseList.isEmpty()) {
                update as system caseList;
            }
            Response resp = new Response(System.Label.Assigend_FOS_Successfully, false);
            resp.caseList = caseList;
            return resp;
            
        } catch (Exception ex) {
            Database.rollback(sp);
            CollectionUtility.createErrorLogRecord('','RoundRobinAssignment','assignCaseToFOS',ex.getStackTraceString(),ex.getLineNumber(), ex.getTypeName() + ' in Assigned FOS Agent Process', ex.getMessage());
            return new Response(ex.getMessage(), true);
        }
    }
    
    /**
* @description  Method to assigned cases to fos agents queue
* @param caseIds
* @param callFromButton
* @return Response
*/
    private static Response assignedCaseToQueue(Set<Id> caseIds,Boolean callFromButton) {
        List<Case> caseList = [SELECT Id, OwnerId FROM Case WHERE Id IN :caseIds ];
        List<Group> getQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = :System.Label.FOS_Agent_Queue];
        
        if (!getQueue.isEmpty() && !caseList.isEmpty()) {
            Id queueId = getQueue[0].Id;
            for (Case caseInstance : caseList) {
                caseInstance.OwnerId = queueId;
            }
            update as system caseList;
            if(callFromButton){
                return new Response(System.Label.Agents_Not_Avaiable,true);
            }
        }
        Response response = new Response('',False);
        response.caseList = new List<Case>();
        return response;
    }
    
    /**
* @description Method to get the least recently assigned FOS agent from a list of contacts
* @param contacts
* @param fosAgentIdVsNoOfCaseAssign
* @return Id
*/
    private static Id getLeastRecentlyAssignedFOS(List<Contact> contacts, Map<Id, Integer> fosAgentIdVsNoOfCaseAssign) {
        Id assignedContactId = null;
        Integer minCasesAssigned = null;
        for (Contact contact : contacts) {
            Integer casesAssigned = fosAgentIdVsNoOfCaseAssign.get(contact.Id) == null ? 0 : fosAgentIdVsNoOfCaseAssign.get(contact.Id);
            if ((assignedContactId == null || casesAssigned < minCasesAssigned) && casesAssigned < Integer.valueOf(System.Label.Daily_Case_Assign_Limit)) {
                assignedContactId = contact.Id;
                minCasesAssigned = casesAssigned;
            }
        }
        return assignedContactId;
    }
    
/**
* @description  Helper method to handle empty result sets
* @param callFromButton
* @param label
* @param caseIds
* @return Response
*/
    private static Response handleEmptyResult(Boolean callFromButton, String label, Set<Id> caseIds) {
        if (!callFromButton) {
            return assignedCaseToQueue(caseIds, callFromButton);
        }
        return new Response(label, true);
    }    
}