/**
* @author TechMatrix Team
* @description This class is responsible for sending payment links and returning success or error messages in a flow.
* It handles the process of generating and sending payment links for cases with associated contacts.
*/
public with sharing class SendPaymentLinkListAction implements omnistudio.VlocityOpenInterface {
    
    /**
* @description Invocable method to send a payment link and return the result.
* @param inputVal List of InputVariable containing the case ID and payment details.
* @return List<OutputVariable> Contains the result of the payment link generation process.
*/
    @InvocableMethod(label='Send Payment Link' description='Returns message while sending payment link.')
    public static List<OutputVariable> sendPaymentLink(List<InputVariable> inputVal) {
        try {
            // Get the case ID from the input variables
            String caseId = inputVal[0].caseId;
            // Query to retrieve the case with the given case ID
            List<Case> caseList = [SELECT Id, ContactId, FOS_Agent__c FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED LIMIT 1];  
            // Check if the case was found
            if (caseList.isEmpty()) {
                return new List<OutputVariable> {new OutputVariable(System.Label.No_Case_Found, true, '', '', '')};
                    }
            
            // Get the case object from the list
            Case caseValue = caseList[0];
            // Query to retrieve the contact associated with the case
            List<Contact> conList = [SELECT Id, Email, MobilePhone, Name FROM Contact WHERE Id = :caseValue.ContactId WITH SECURITY_ENFORCED LIMIT 1];
            
            // Check if the contact's email id is missing
            if (conList.isEmpty() || String.isBlank(conList[0].Email)) {
                return new List<OutputVariable> {new OutputVariable(System.Label.Email_Missing, true, '', '', '')};
                    }
            
            // Check if the contact's MobilePhone number is missing
            if (String.isBlank(conList[0].MobilePhone)) {
                return new List<OutputVariable> {new OutputVariable(System.Label.Phone_Number_Missing, true, '', '', '')};
                    }
            // Call https request to generate payment url BEFORE creating the transaction record
            PaymentGateWayIntegration.ApiResponse responseFromPaymentClass = PaymentGateWayIntegration.createPaymentLink(
                inputVal[0].amount, 'INR', inputVal[0].paymentMode, inputVal[0].paymentOption, conList[0].Name, conList[0].Email, conList[0].MobilePhone
            );
            
            if (!responseFromPaymentClass.isSuccess) {
                // Return the response message and error status
                Map<String, Object> errorMap = (Map<String, Object>)JSON.deserializeUntyped(responseFromPaymentClass.message);
                Map<String, Object> errorDetails = (Map<String, Object>)errorMap.get('error');
                String description = (String)errorDetails.get('description');
                
                return new List<OutputVariable>{new OutputVariable(description, true, '', '', '')};
                    }
            // Return the Success message, error status, payment Id, url
            
            return new List<OutputVariable>{new OutputVariable(System.Label.Success_Message_of_payment, false, responseFromPaymentClass.paymentId, responseFromPaymentClass.paymentUrl, responseFromPaymentClass.paymentStatus)};
                } catch (Exception ex) {
                    // Handle any exceptions and return the error message
                    return new List<OutputVariable> {new OutputVariable(ex.getMessage(), true, '', '', '')};
                        }
    }
    /**
* @description this method is using on log a call functionality for getting amount of case 
* @param caseId hold current case record Id
* @return caseRecord the value if actual amount to be paid
*/
    @AuraEnabled
    public static String getCaseAmountData(String caseId){
        try{
            List<Case> caseRecord = [select Id,Format(Actual_Amount_To_Be_Paid__c) from case Where Id =: caseId WITH SECURITY_ENFORCED LIMIT 1 ];
            return String.ValueOf(caseRecord[0].Actual_Amount_To_Be_Paid__c) ?? '';
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    
    /**
* @description Implementation of the invokeMethod required by VlocityOpenInterface
* @param methodName The name of the method to invoke
* @param inputMap A map of input parameters
* @param outputMap A map of output parameters
* @param options A map of options
* @return Boolean indicating success or failure
*/
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Boolean isSuccess = false;
        try {  
            // Create a new instance of InputVariable and populate it from the inputMap
            InputVariable inputVar = new InputVariable();
            inputVar.caseId = (String) inputMap.get('ContextId');
            Map<String, Object> step2Map = (Map<String, Object>) inputMap.get('Step2');
            if (step2Map != null && step2Map.containsKey('Amount_to_Paid')) {
                inputVar.amount = (Decimal) step2Map.get('Amount_to_Paid');
            } else {
                inputVar.amount = 0;
            }
            inputVar.paymentMode = 'Send Payment Link';
            inputVar.paymentOption = 'Send Payment Link';
            
            // Add the input variable to a list as expected by the sendPaymentLink method
            List<InputVariable> inputVal = new List<InputVariable>();
            inputVal.add(inputVar);
            
            // Call sendPaymentLink and get the result
            List<OutputVariable> resultOutput = sendPaymentLink(inputVal);
            
            // Check if there was an error
            if (resultOutput[0].isError) {
                outputMap.put('result', resultOutput[0].errorMessage);
                isSuccess = false;
            } else {
                List<Case> caseList = [SELECT Id,Financial_Account__c FROM Case WHERE Id = : (String) inputMap.get('ContextId') WITH SECURITY_ENFORCED LIMIT 1];
                FinancialAccountTransaction	 trans = new FinancialAccountTransaction();
                trans.Case__c = (String) inputMap.get('ContextId');
                trans.Amount  = (Decimal) step2Map.get('Amount_to_Paid');
                trans.TransactionDate  = system.today();
                trans.Payment_Method__c = 'Send Payment Link';
                trans.Payment_Option__c =(String) step2Map.get('How_much_do_you_want_to_pay') == 'Full payment' ? 'Pay the Entire Amount' : 'Pay Partial Amount'; 
                trans.Payment_Url__c = resultOutput[0].razorePaymentUrl;
                trans.RazorPay_Payment_Id__c =  resultOutput[0].razorePaymentId;
                trans.status = resultOutput[0].razorePaymentStatus;
                trans.FinancialAccountId = caseList[0].Financial_Account__c;
                INSERT as system trans;
                outputMap.put('result', System.Label.Success_Message_of_payment);
                outputMap.put('paymentId', resultOutput[0].razorePaymentId);  // Store the payment ID
                outputMap.put('paymentUrl', resultOutput[0].razorePaymentUrl);  // Store the payment URL
                outputMap.put('paymentStatus', resultOutput[0].razorePaymentStatus);  // Store the payment status
                isSuccess = true;
            }      
        } catch (Exception ex) {
            outputMap.put('errorMessage', ex.getMessage());
            isSuccess = false;
        }
        return isSuccess;
    }
    
    
    /**
* @description this method is using on log a call functionality for send payment Link
* @param caseId hold current case record Id
* @param amount amount of which user want to pay
* @param paymentOption method of payment like partial payment,full payment
* @return Response which hold success and error message
*/
    @AuraEnabled 
    public static Response sendPaymentLinkFromLWC(String caseId,Decimal amount,String paymentOption){
        Response response = new Response(System.Label.Something_went_wrong,true);
        try{
            InputVariable inputVar = new InputVariable();
            inputVar.caseId = caseId;
            inputVar.amount = amount;
            inputVar.paymentMode = System.Label.Send_Payment_Link;
            inputVar.paymentOption = System.Label.Send_Payment_Link;
            List<InputVariable> inputVal = new List<InputVariable>();
            inputVal.add(inputVar);
            List<OutputVariable> resultOutput = sendPaymentLink(inputVal);
            if (resultOutput[0].isError) {
                AuraHandledException e = new AuraHandledException(resultOutput[0].errorMessage);
                e.setMessage(resultOutput[0].errorMessage);
                throw e;
            } else {
                List<Case> caseList = [SELECT Id,Financial_Account__c FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED LIMIT 1];  
                FinancialAccountTransaction	 trans = new FinancialAccountTransaction();
                trans.Case__c = caseId;
                trans.Amount  = amount;
                trans.TransactionDate  = system.today();
                trans.Payment_Method__c = System.Label.Send_Payment_Link;
                trans.Payment_Option__c = paymentOption == System.Label.Pay_the_Entire_Amount ? System.Label.Pay_the_Entire_Amount : System.Label.Pay_Partial_Amount; 
                trans.Payment_Url__c = resultOutput[0].razorePaymentUrl;
                trans.RazorPay_Payment_Id__c =  resultOutput[0].razorePaymentId;
                trans.status = resultOutput[0].razorePaymentStatus;
                trans.FinancialAccountId = caseList[0].Financial_Account__c;
                trans.DebitCreditIndicator = System.Label.DebitCreditIndicator;
                INSERT as system trans;
                UPDATE as system new Case(Id=caseId,status=System.Label.Under_Payment_Process);
                response.isError = false;
                response.message = System.Label.Success_Message_of_payment;
                response.paymentId = resultOutput[0].razorePaymentId;
            }      
            return response;
        }catch(Exception ex){
            AuraHandledException e = new AuraHandledException(ex.getMessage());
            e.setMessage(ex.getMessage());
            throw e;
        }
    }
    
    
    
    
    /**
* @description Inner class to represent input variables for the invocable method
*/
    public class InputVariable {
        @InvocableVariable(required=true label='Case Record Id')
        @AuraEnabled
        public String caseId;
        @InvocableVariable(required=true label='Amount')
        @AuraEnabled
        public Decimal amount;
        @InvocableVariable(label='Payment Mode')
        @AuraEnabled
        public String paymentMode;
        @InvocableVariable(label='Payment Option')
        @AuraEnabled
        public String paymentOption;
    }
    
    /**
* @description Inner class to represent output variables for the invocable method
*/
    public class OutputVariable {
        @InvocableVariable(label='Error Message')
        @AuraEnabled
        public String errorMessage;
        @InvocableVariable(label='Is Error')
        @AuraEnabled
        public Boolean isError;
        @InvocableVariable(label='Payment Id')
        @AuraEnabled
        public String razorePaymentId;
        @InvocableVariable(label='Payment Url')
        @AuraEnabled
        public String razorePaymentUrl;
        @InvocableVariable(label='Payment Status')
        @AuraEnabled
        public String razorePaymentStatus;
        
        /**
* @description Constructor to initialize output variables
* @param errorMessage The error message if any
* @param isError Indicates if there was an error
* @param razorePaymentIdP The Razorpay payment ID
* @param razorePaymentUrlP The Razorpay payment URL
* @param razorePaymentStatus The Razorpay payment status
*/
        public OutputVariable(String errorMessage, Boolean isError, String razorePaymentIdP, String razorePaymentUrlP, String razorePaymentStatus) {
            this.errorMessage = errorMessage;
            this.isError = isError;
            this.razorePaymentId = razorePaymentIdP;
            this.razorePaymentUrl = razorePaymentUrlP;
            this.razorePaymentStatus = razorePaymentStatus;
        }
    }
}