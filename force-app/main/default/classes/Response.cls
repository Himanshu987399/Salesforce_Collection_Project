/**
* @Author       TechMatrix Team
* @description   The class for store response as a wrapper.
*/
public class Response {
/**
* @description   response wrapper.
* @param message message 
* @param isError boolean value to know wether the response is errro
* @param paymentId the payment id during the response
* @param fosContactList list of FOS Contacts
* @param caseList List of case
*/
/**
 * @description : Message to hold error details
 */
    @AuraEnabled 
    public String message {get;set;}    
 /**
 * @description : Getting the flag to know wether the response is error or not
 */
    @AuraEnabled
    public Boolean isError{get;set;}
    /**
     * @description : Payment id during the response
     */
   
    @AuraEnabled
    public String paymentId{get;set;}
    /**
     * @description : List of FOS Contacts
     */
    @AuraEnabled
    public List<Contact> fosContactList{get;set;}
    /**
     * @description : List of Cases
         */
    @AuraEnabled
    public List<Case> caseList {get;set;}
    
    /**
* @description Constructor to initialize response variables
* @param message message during the response
* @param isError boolean value to know wether there was error during the response
*/
    public Response(String message, Boolean isError) {
        this.message = message;
        this.isError = isError;
    }
}