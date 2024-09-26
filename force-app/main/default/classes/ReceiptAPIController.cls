/**
 * @author       TechMatrix Team
 * @description This class serves as a REST API controller for generating receipt PDFs.
 * It provides an endpoint to generate receipts or challans based on the provided parameters.
 * 
 * @apiNote This class is marked as 'without sharing', which bypasses sharing rules.
 * Ensure this is necessary and doesn't introduce security vulnerabilities.
 */
@RestResource(urlMapping='/receipt/*')
global without sharing class ReceiptAPIController {
    
    private static final String RECEIPT_TEMPLATE = System.Label.Reciept_Doc_Template;
    private static final String CHALLAN_TEMPLATE = System.Label.Challan_Doc_Template;
    private static final String IP_PROCEDURE_NAME = System.Label.Receipt_IP_Name;
    private static final String CHALLAN_IP_PROCEDURE_NAME = System.Label.Challan_IP_Name;

    /**
     * @description Inner class to structure the response sent back to the client.
     * It contains fields for the document process ID and any error message.
     */
    global class SendResponse {
        public String documentProcessId;
        public String error;
        
        /**
         * @description Constructor for SendResponse
         * @param errorMessage The error message, if any
         * @param documentProcessIdP The document process ID
         */
        public SendResponse(String errorMessage, String documentProcessIdP) {
            this.error = errorMessage;
            this.documentProcessId = documentProcessIdP;
        }
    }
    
    /**
     * @description Main method to handle GET requests for generating receipt PDFs.
     * This method orchestrates the entire process of fetching the template,
     * preparing input parameters, calling the integration procedure, and updating the record.
     * 
     * @return SendResponse An object containing either the document process ID or an error message
     */
    @HttpGet
    global static SendResponse generateReceiptPdf() {
        try {
            RestRequest req = RestContext.request;
            String recordId = req.params.get('recordId');
            String fileType = req.params.get('fileType');
            String receiptNumber = '';
            String mainId = recordId;
            String objectName = fileType == 'Receipt' ? 'Receipt__c':'Challan__c';
            
            DocumentTemplate docTemplate = getActiveDocumentTemplate(fileType);
            if (docTemplate == null && fileType == 'Receipt') {
                return new SendResponse('The receipt document template is missing.', '');
            }
            
            if (docTemplate == null && fileType == 'Challan') {
                return new SendResponse('The challan document template is missing.', '');
            }
            if(fileType == 'Receipt'){
                Receipt__c receiptData = [Select Id,Case__c,Name from Receipt__c Where Id =: recordId LIMIT 1];
                //receiptNumber = receiptData.Name ?? '';
                //recordId = receiptData.Case__c ?? '';
                String caseId = receiptData.Case__c ?? '';
                if(String.isBlank(recordId)){
                   return new SendResponse('Case Id is not associated against receipt record.', '');
                }
                Case caseRecord = [Select Id,AccountId from Case Where Id =: caseId LIMIT 1];
                Receipt__c receipt = new Receipt__c();
                receipt.Id = mainId;
                receipt.Account__c = caseRecord.AccountId ?? '';
                Update receipt;
            }
            String query = 'Select Id,Name From '+objectName+ ' Where Id =: mainId Limit 1';
			sObject recordData = Database.query(query);
            Map<String, Object> ipInput = prepareInputParameters(recordId, docTemplate, fileType,receiptNumber,mainId,recordData.get('Name'));
            Map<String, Object> ipOutput = callIntegrationProcedure(ipInput,fileType);
            
            if(ipOutput == null){
                return new SendResponse('FileType name is wrong', '');
            }
            
            String jobId = (String) ipOutput.get('jobId');
            if (String.isBlank(jobId)) {
                return new SendResponse('Job ID is blank or null', '');
            }
            
            SObject obj = ((Id)mainId).getSObjectType().newSObject(mainId);
            obj.put('Document_Process_Id__c', jobId);
            update obj;
            
            return new SendResponse('', jobId);
        } catch (Exception e) {
            return new SendResponse('Error in generateReceiptPdf: ' + e.getMessage(), '');
        }
    }
    
    /**
     * @description Retrieves the active document template based on the file type.
     * 
     * @param fileType The type of file to be generated ('Receipt' or 'Challan')
     * @return DocumentTemplate The active document template, or null if not found
     */
    private static DocumentTemplate getActiveDocumentTemplate(String fileType) {
        String documentName = (fileType == 'Receipt') ? RECEIPT_TEMPLATE : CHALLAN_TEMPLATE;
        List<DocumentTemplate> docTemplates = [
            SELECT Id, Name, Type
            FROM DocumentTemplate
            WHERE IsActive = true
            AND Name = :documentName
            AND TokenMappingType = 'JSON'
            AND Type = 'MicrosoftWord'
            LIMIT 1
        ];
        return docTemplates.isEmpty() ? null : docTemplates[0];
    }
    
    /**
     * @description Prepares the input parameters for the integration procedure.
     * 
     * @param recordId The ID of the record for which the document is being generated
     * @param template The DocumentTemplate object containing template details
     * @param fileType The type of file being generated
     * @return Map<String, Object> A map of input parameters for the integration procedure
     */
    private static Map<String, Object> prepareInputParameters(String recordId, DocumentTemplate template, String fileType,String receiptNumber,String mainId,Object Name) {
        Datetime now = Datetime.now();
		Integer offset = UserInfo.getTimezone().getOffset(now);
		Datetime local = now.addSeconds(offset/1000);
        String title = fileType+' '+Name +' ('+local+')';
		Map<String, Object> ipInput = new Map<String, Object>();
        ipInput.put('objectId', recordId);
        ipInput.put('templateId', template.Id);
        ipInput.put('title', title);
        ipInput.put('outputFileFormat', 'pdf');
        ipInput.put('contextId', recordId);
        ipInput.put('selectedTemplate', template.Name);
        ipInput.put('templateType', template.Type);
        ipInput.put('receiptNumber', receiptNumber);
        ipInput.put('FromAPI', true);
        ipInput.put('receiptId', mainId);
        ipInput.put('documentTitle', fileType);
        ipInput.put('FromApi', true);
        return ipInput;
    }
    
    /**
     * @description Calls the integration procedure to generate the document.
     * 
     * @param ipInput The input parameters for the integration procedure
     * @return Map<String, Object> The output from the integration procedure
     */
    private static Map<String, Object> callIntegrationProcedure(Map<String, Object> ipInput,String fileType) {
        Map<String, Object> ipOptions = new Map<String, Object>();
      //  return (Map<String, Object>) omnistudio.IntegrationProcedureService.runIntegrationService(CHALLAN_IP_PROCEDURE_NAME, ipInput, ipOptions);
        
        
        if(fileType == 'Receipt'){
        	return (Map<String, Object>) omnistudio.IntegrationProcedureService.runIntegrationService(IP_PROCEDURE_NAME, ipInput, ipOptions);
        }
        if(fileType == 'Challan'){
        	return (Map<String, Object>) omnistudio.IntegrationProcedureService.runIntegrationService(CHALLAN_IP_PROCEDURE_NAME, ipInput, ipOptions);
        }
        return null;
    }
}