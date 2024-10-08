/**
* @author       TechMatrix Team
* @description This class serves as a Utility class.
*/
public with sharing class CollectionUtility implements omnistudio.VlocityOpenInterface,Callable {
    /**
* @description This metod will accept all the field values and create a record of Error_Log__c
* @param recordId the Id of therecord in error log
* @param apexClassName string Apex Class 
* @param methodName string method name
* @param location string location
* @param lineNumber string line number of the error 
* @param errorTitle strin error title
* @param errorDescription string error description
* @return errorLogRecord.Id
*/
    public static Id createErrorLogRecord(String recordId,String apexClassName, String methodName, String location, Decimal lineNumber, String errorTitle, String errorDescription){
        Error_Log__c errorLogRecord = new Error_Log__c();
        errorLogRecord.Record_Id__c = recordId;
        errorLogRecord.Apex_Class_Name__c = apexClassName;
        errorLogRecord.Method_Name__c = methodName;
        errorLogRecord.Location__c = location;
        errorLogRecord.Line_Number__c = lineNumber;
        errorLogRecord.Error_Title__c = errorTitle;
        errorLogRecord.Error_Description__c = errorDescription;
        if(Schema.sObjectType.Error_Log__c.isCreateable()){
            insert errorLogRecord;}                                      
        return errorLogRecord.Id;
        /*
applicationName string application name which is creating the error record 
integrationRequest string integration request
integrationResponses response 
integrationStatus string response 
*/
    }
    /**
* @description This metod will accept all the field values and create a record of API_Log__c
* @param recordId  record Id of error record
* @param type string type
* @param endpoint string endpoint of API
* @param headers string header 
* @param method string method
* @param requestBody String request body for API error log
* @param responseBody String response body for API error log
* @param responseCode Integer response code for API error log
* @return apiLogRecord
*/
    @AuraEnabled
    public static API_Log__c createAPILogRecord(String recordId,String type,String endpoint, String headers, String method, String  requestBody, String responseBody, Integer responseCode){
        API_Log__c apiLogRecord = new API_Log__c();
        apiLogRecord.Record_Id__c = recordId;	
        apiLogRecord.Type__c = type;
        apiLogRecord.Endpoint__c = endpoint;
        apiLogRecord.Headers__c = headers;
        apiLogRecord.Method__c = method;
        apiLogRecord.Request_Body__c = requestBody.length() > 131072 ? requestBody.subString(0,131069) + '...' : requestBody;
        apiLogRecord.Response_Body__c = responseBody.length() > 131072 ? responseBody.subString(0,131069) + '...' : responseBody;
        apiLogRecord.Response_Code__c = responseCode;
        insert as System apiLogRecord;
        return apiLogRecord;
    }
    /**
* @description : Retrieves the ContentDocumentId associated with a DocumentGenerationProcess job.
* 
* @param jobId The Id of the DocumentGenerationProcess job
* @return The ContentDocumentId as a String, or an empty string if not found
* @throws AuraHandledException if any error occurs during the process
*/
    @AuraEnabled
    public Static String getContentDocumentId(String jobId){
        try{
            List<DocumentGenerationProcess> docGenProcess = [Select Id,ResponseText from DocumentGenerationProcess Where Id =: jobId WITH SECURITY_ENFORCED];
            String contentVersionId = docGenProcess[0].ResponseText ?? '';
            List<ContentVersion> contVersion = [select Id,ContentDocumentId from ContentVersion where Id =: contentVersionId WITH SECURITY_ENFORCED];
            if(contVersion.isEmpty()){
                return '';
            }else{
                return String.valueOf(contVersion[0].ContentDocumentId);
            }
        }catch(Exception ex){
            AuraHandledException e = new AuraHandledException(ex.getMessage());
            e.setMessage(ex.getMessage());
            throw e;
        }
    }
    /**
* @description callmethod
* @param action string variable
* @param args map of argumnets
* @return invokeMethod
*/
    public Object call(String action,Map<String, Object> args){
        Map<String,Object> input = (Map<String,Object>) args.get('input');
        Map<String,Object> output = (Map<String,Object>) args.get('output');
        Map<String,Object> options = (Map<String,Object>) args.get('input');
        return invokeMethod(action,input,output,options);
    }
    /**
* @description boolean invoke method
* @param methodName method name string
* @param inputMap input map
* @param outputMap output map
* @param options map of options
* @return  isSuccess boolean value 
*/
    
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        Savepoint sp = Database.setSavepoint(); 
        Boolean isSuccess = false;
        try{
            String caseId = (String) inputMap.get('ContextId');
            Case caseInstance = new Case();
            caseInstance.Id = caseId;
            caseInstance.Status = 'Under Dispute';
            caseInstance.Dispute_Status__c = 'Dispute Initiated';
            Update as system caseInstance;
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setObjectId(caseId);
            req1.setSubmitterId(userinfo.getuserId()); 
            req1.setProcessDefinitionNameOrId('Case_Dispute_Approval_Process');
            Approval.process(req1);
            isSuccess = true;
        }
        catch(Exception ex){
            Database.rollback(sp);
            outputMap.put('errorMessage', ex.getMessage());
            isSuccess = false;
        }
        return isSuccess;
    }
    
    
}