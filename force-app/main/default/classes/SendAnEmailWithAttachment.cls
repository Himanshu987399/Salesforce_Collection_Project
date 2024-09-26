/**
 * @description This class provides functionality to send an email with an attachment using Salesforce's email services.
 * It is designed to be invocable from Flow or Process Builder.
 */
public with sharing class SendAnEmailWithAttachment {
    

    /**
     * @description Sends an email with an attachment based on the provided input parameters.
     * @param inputVal List of InputVariable containing the necessary information for sending the email.
     * @return List<OutputVariable> Returns null as the method doesn't currently utilize the output variables.
     */
    @InvocableMethod(label='Send An Email' description='Sends an email with attachment and returns a message')
    public static void sendEmail(List<InputVariable> inputVal){
        
        // Query for the email template
        List<EmailTemplate> template = [SELECT Id, Name, Subject, DeveloperName, Body 
                                        FROM EmailTemplate 
                                        WHERE DeveloperName = :inputVal[0].templateName WITH SECURITY_ENFORCED
                                        LIMIT 1 ];
        
        // Query for the content version (attachment)
        List<ContentVersion> contentVersion = [SELECT Id, VersionData, Title, FileExtension 
                                               FROM ContentVersion 
                                               WHERE Id = :inputVal[0].contentVersionId WITH SECURITY_ENFORCED
                                               LIMIT 1 ];
        
        // Get Contact Id based on Case
        List<case> caseData = [Select Id,ContactId from Case where Id =: inputVal[0].caseId WITH SECURITY_ENFORCED LIMIT 1 ];
        
        // Create and populate the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { inputVal[0].recipientEmail });
        email.setTemplateId(template[0].Id);
        email.setSaveAsActivity(false);
        email.setTargetObjectId(caseData[0].ContactId ?? '');
        
        // Create and attach the file
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(contentVersion[0].Title + '.' + contentVersion[0].FileExtension);
        attachment.setBody(contentVersion[0].VersionData);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        
        // TODO: Consider implementing error handling and utilizing the OutputVariable
        
    }
    
    /**
     * @description Input variable class to hold the necessary information for sending an email.
     */
    public class InputVariable {
        @InvocableVariable(required=true label='Case Record Id')
        public String caseId;
        
        @InvocableVariable(required=true label='Content Version')
        public String contentVersionId;
        
        @InvocableVariable(required=true label='Email')
        public String recipientEmail;
        
        @InvocableVariable(required=true label='Email Template')
        public String templateName;
    }
    
   
}