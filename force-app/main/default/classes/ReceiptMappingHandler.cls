/**
* @description This class handles the mapping of receipt data and related financial transactions.
* It implements the VlocityOpenInterface for integration with Vlocity and is also Callable.
* The class processes receipt information, including charges, refunds, denominations, and various payment methods.
*/
public without sharing class ReceiptMappingHandler implements omnistudio.VlocityOpenInterface, Callable {
    /**
* @description callmethod
* @param action string variable
* @param args map of argumnets
* @return invokeMethod
*/
    public Object call(String action, Map<String, Object> args) {
        Map<String,Object> input = (Map<String,Object>) args.get('input');
        Map<String,Object> output = (Map<String,Object>) args.get('output');
        Map<String,Object> options = (Map<String,Object>) args.get('input');
        return invokeMethod(action, input, output, options);
    }
    
    /**
* @description boolean invoke method
* @param methodName method name string
* @param inputMap input map
* @param outputMap output map
* @param options map of options
* @return  isSuccess boolean value 
*/
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Savepoint sp = Database.setSavepoint(); 
        TokenData tokenDataInstance = new TokenData();
        Boolean isSuccess = false;
        try {
            Boolean fromApi = (Boolean)inputMap.get('FromApi');
            String receiptId = '';
            if(fromApi){
                receiptId = (String) inputMap.get('objectId');
            }else{
                Map<String,Object> getSetUpData = (Map<String,Object>) inputMap.get('setupServiceCallInputParams') ?? null ;
                receiptId = (String) getSetUpData.get('objectId') ?? '';
            }
            if(String.isBlank(receiptId)){
                Database.rollback(sp);
                outputMap.put('isSuccessfulTransaction', false);
                outputMap.put('errorMessage', 'Receipt id not found.');
                isSuccess = false;
                return isSuccess;
            }
            Decimal totalChargesAmount = 0.00;
            Decimal totalRefundAndWaiveOffAmount = 0.00;
            Decimal totalDenominationAmount = 0.00;
            Decimal totalChequeAmount = 0.00;
            Decimal totalOnlineAmount = 0.00;
            List<FinancialAccountFee> chargesAndFees = new List<FinancialAccountFee>();
            List<ChargesAndFessDetails> chargesDetailsList = new List<ChargesAndFessDetails>();
            List<Refund_and_Waive_off_Request__c> refundAndWaiveOff = new List<Refund_and_Waive_off_Request__c>();
            List<RefundAndWaiveOffClass> refundDataDetailsList = new List<RefundAndWaiveOffClass>();
            List<Denomination> denomiantionListData = new List<Denomination>();
            List<ChequeDetails> chequeDetailsList = new List<ChequeDetails>();
            List<PaymentDetails> paymentDetailsList = new List<PaymentDetails>();
            Receipt__c receiptData = [SELECT Id, Case__c, Name, CreatedDate, Account__r.Name, Case__r.ContactId, Case__r.Contact.MailingStreet, Case__r.Contact.Name, Case__r.Contact.MailingCity, Case__r.Contact.MailingState, Case__r.Contact.MailingAddress, Case__r.Contact.MailingCountry, Case__r.Account.PersonMailingStreet,
                                      Case__r.Account.IsPersonAccount, Case__r.Account.PersonMailingCity, Case__r.Account.PersonMailingCountry, Case__r.Account.PersonMailingState, Case__r.Account.PersonMailingAddress, Case__r.Financial_Account__r.FinancialAccountNumber FROM Receipt__c WHERE Id = :receiptId WITH SYSTEM_MODE LIMIT 1];
            String caseId = receiptData.Case__c ?? '';
            if(String.isBlank(caseId)){
                Database.rollback(sp);
                outputMap.put('isSuccessfulTransaction', false);
                outputMap.put('errorMessage', 'Case id not found against receipt.');
                isSuccess = false;
                return isSuccess;
            }
            String customerAddress = '';
            Address arr = new Address();
            if(receiptData.Case__r.Account.IsPersonAccount){
                arr = receiptData.Case__r.Account.PersonMailingAddress != null ? receiptData.Case__r.Account.PersonMailingAddress : new Address();
            }
            else{
                arr = receiptData.Case__r.Contact.MailingAddress != null ? receiptData.Case__r.Contact.MailingAddress : new Address();
            }
            if (arr != null) {
                customerAddress = (arr.getStreet() != null) ? String.valueOf(arr.getStreet()) + ' ' : '';
                customerAddress += (arr.getCity() != null ) ? String.valueOf(arr.getCity()) + ' ' : '';
                customerAddress += (arr.getState() != null) ? String.valueOf(arr.getState()) + ' ' : '';
                customerAddress += (arr.getCountry() != null) ? String.valueOf(arr.getCountry()) + ' ' : '';
                customerAddress += (arr.getStateCode() != null) ? String.valueOf(arr.getStateCode()) : '';
            }
            chargesAndFees = [SELECT Id, Case__c, Type, Amount FROM FinancialAccountFee WHERE Case__c = :caseId WITH SYSTEM_MODE];
            if(!chargesAndFees.isEmpty()){
                List<Schema.PicklistEntry> values = FinancialAccountFee.Type.getDescribe().getPicklistValues();
                Map<String,String> statusApiToLabelMap = new Map<String,String>();
                for(Schema.PicklistEntry spE : values){
                    statusApiToLabelMap.put(spE.getValue(), spE.getLabel());
                }
                for(FinancialAccountFee chargesInstance : chargesAndFees){
                    totalChargesAmount += (chargesInstance.Amount).setScale(2);
                    ChargesAndFessDetails chargesDetailInstance = new ChargesAndFessDetails();
                    chargesDetailInstance.chargesTypes = statusApiToLabelMap.get(chargesInstance.Type ?? '');
                    chargesDetailInstance.chargesCode = chargesInstance.Type ?? '';
                    chargesDetailInstance.chargesAmount = String.valueOf((chargesInstance.Amount ?? 0).setScale(2));
                    chargesDetailsList.add(chargesDetailInstance);
                }
            }
            refundAndWaiveOff = [SELECT Id, Case__c, Amount__c, Type__c FROM Refund_and_Waive_off_Request__c WHERE Case__c = :caseId AND Approval_Status__c = 'Approved' WITH SYSTEM_MODE];
            for(Refund_and_Waive_off_Request__c rAndWInstance : refundAndWaiveOff){
                totalRefundAndWaiveOffAmount += (rAndWInstance.Amount__c).setScale(2);
                RefundAndWaiveOffClass refundAndWaiveOffInstance = new RefundAndWaiveOffClass();
                refundAndWaiveOffInstance.refundType = rAndWInstance.Type__c ?? '';
                refundAndWaiveOffInstance.refundAmount = String.valueOf((rAndWInstance.Amount__c ?? 0).setScale(2));
                refundDataDetailsList.add(refundAndWaiveOffInstance);
            }
            List<FinancialAccountTransaction> transactionData = [SELECT Id, Status, Receipt__r.Name, Receipt__r.CreatedDate, Amount, Payment_Method__c, Case__r.Financial_Account__r.FinancialAccountNumber, Refund_and_Waive_off_Request__c FROM FinancialAccountTransaction WHERE Case__c = :caseId AND Status = 'Paid' AND Refund_and_Waive_off_Request__c = NULL WITH SYSTEM_MODE];
            List<FinancialAccountTransaction> updateReceiptDataInTransaction = new List<FinancialAccountTransaction>();
            List<Id> cashTransactionId = new List<Id>();
            List<Id> chequeTransactionId = new List<Id>();
            List<Id> transactionId = new List<Id>();
            for(FinancialAccountTransaction transactionInstance : transactionData){
                if(transactionInstance.Payment_Method__c == 'Cash'){
                    cashTransactionId.add(transactionInstance.Id);
                }
                if(transactionInstance.Payment_Method__c == 'Cheque'){
                    chequeTransactionId.add(transactionInstance.Id);
                }
                if(transactionInstance.Payment_Method__c == 'Send Payment Link' || transactionInstance.Payment_Method__c == 'Online'){
                    transactionId.add(transactionInstance.Id);
                }
                updateReceiptDataInTransaction.add(new FinancialAccountTransaction(Id = transactionInstance.Id, Receipt__c = receiptId));
            }
            Map<Decimal,Decimal> denominationValueVsQuantity = new Map<Decimal,Decimal>();
            List<Denomination__c> denominationList = [SELECT Id, Denomination_Value__c, Quantity__c FROM Denomination__c WHERE Financial_Account_Transaction__c IN :cashTransactionId WITH SYSTEM_MODE];
            for(Denomination__c denominationInstance : denominationList){
                if(denominationValueVsQuantity.containsKey(denominationInstance.Denomination_Value__c)){
                    denominationValueVsQuantity.put(denominationInstance.Denomination_Value__c, denominationValueVsQuantity.get(denominationInstance.Denomination_Value__c) + denominationInstance.Quantity__c);
                }else{
                    denominationValueVsQuantity.put(denominationInstance.Denomination_Value__c, denominationInstance.Quantity__c);
                }
            }
            for(Decimal denoValue : denominationValueVsQuantity.keySet()){
                Denomination denoInstance = new Denomination();
                denoInstance.denomination = denoValue;
                denoInstance.denominationNotes = denominationValueVsQuantity.get(denoValue);
                denoInstance.denominationAmount = String.valueOf((denoValue * denominationValueVsQuantity.get(denoValue)).setScale(2));
                totalDenominationAmount += (denoValue * denominationValueVsQuantity.get(denoValue)).setScale(2);
                denomiantionListData.add(denoInstance);
            }
            List<FinancialAccountTransaction> chequeTransaction = [SELECT Id, Bank_Name__c, Account__r.Name, IFSC__c, MICR__c, Cheque_Number__c, CreatedDate, Amount, Account_Holder_name__c FROM FinancialAccountTransaction WHERE Id IN :chequeTransactionId WITH SECURITY_ENFORCED];
            if(!chequeTransaction.isEmpty()){
                for(FinancialAccountTransaction transactionInstance : chequeTransaction){
                    totalChequeAmount += (transactionInstance.Amount).setScale(2);
                    ChequeDetails chequeInstance = new ChequeDetails();
                    chequeInstance.bankName = transactionInstance.Bank_Name__c ?? '';
                    chequeInstance.ifscCode = transactionInstance.IFSC__c ?? '';
                    chequeInstance.micrCode = transactionInstance.MICR__c ?? '';
                    chequeInstance.accountName = transactionInstance.Account_Holder_name__c ?? '';
                    chequeInstance.chequeNumber = transactionInstance.Cheque_Number__c;
                    chequeInstance.chequeDate = transactionInstance.CreatedDate.format('dd/MM/YYYY') ?? Date.today().format();
                    chequeInstance.chequeAmount = String.valueOf((transactionInstance.Amount ?? 0).setScale(2));
                    chequeDetailsList.add(chequeInstance);
                }
            }
            List<FinancialAccountTransaction> onlineTransaction = [SELECT Id, Bank_Name__c, Transaction_Date__c, RazorPay_Payment_Id__c, Amount FROM FinancialAccountTransaction WHERE Id IN :transactionId WITH SECURITY_ENFORCED];
            if(!onlineTransaction.isEmpty()){
                for(FinancialAccountTransaction transactionInstance : onlineTransaction){
                    totalOnlineAmount += (transactionInstance.Amount).setScale(2);
                    PaymentDetails onlineInstance = new PaymentDetails();
                    onlineInstance.bankName = transactionInstance.Bank_Name__c ?? '';
                    onlineInstance.transactionId = transactionInstance.RazorPay_Payment_Id__c ?? '';
                    onlineInstance.transactionDate = transactionInstance.Transaction_Date__c ?? '';
                    onlineInstance.totalAmount = String.valueOf((transactionInstance.Amount ?? 0).setScale(2));
                    paymentDetailsList.add(onlineInstance);
                }
            }
            
            if(!updateReceiptDataInTransaction.isEmpty()){
                update as System updateReceiptDataInTransaction;
            }
            update as System new Case(Is_Receipt_Send__c = true, Id = caseId);
            tokenDataInstance.bankName = System.Label.Bank_Name;
            tokenDataInstance.todayDate = Date.today().format();
            tokenDataInstance.receiptNumber = receiptData.Name;
            tokenDataInstance.createdDate = receiptData.CreatedDate.format('dd/MM/yyyy');
            tokenDataInstance.fullName = receiptData.Case__r.Contact.Name ?? '';
            tokenDataInstance.loanAccountNumber = receiptData.Case__r.Financial_Account__r.FinancialAccountNumber;
            tokenDataInstance.customerAddress = customerAddress;
            tokenDataInstance.showCharges = chargesDetailsList.isEmpty() ? false : true;
            tokenDataInstance.chargesData = chargesDetailsList;
            tokenDataInstance.totalChargesAmount = String.valueOf(totalChargesAmount);
            tokenDataInstance.refundData = refundDataDetailsList;
            tokenDataInstance.totalRefundAndWaiveOffAmount = String.valueOf(totalRefundAndWaiveOffAmount);
            tokenDataInstance.showRefunds = refundDataDetailsList.isEmpty() ? false : true;
            tokenDataInstance.denominationDetails = denomiantionListData;
            tokenDataInstance.showCash = denomiantionListData.isEmpty() ? false : true;
            tokenDataInstance.totalDenominationAmount = String.valueOf(totalDenominationAmount);
            tokenDataInstance.showCheque = chequeDetailsList.isEmpty() ? false : true;
            tokenDataInstance.chequeDetails = chequeDetailsList;
            tokenDataInstance.showOnlineTransaction = paymentDetailsList.isEmpty() ? false : true;
            tokenDataInstance.onlineDetails = paymentDetailsList;
            tokenDataInstance.grandTotalAmount = String.valueOf(totalDenominationAmount + totalChequeAmount + totalOnlineAmount);
            tokenDataInstance.description = 'Received with thanks, ₹ ' + tokenDataInstance.grandTotalAmount + ' towards settlement of overdue amount in Loan Account ' + tokenDataInstance.loanAccountNumber + '.';
            outputMap.put('responseData', JSON.serialize(tokenDataInstance));
            outputMap.put('isSuccessfulTransaction', true);
            isSuccess = true;
        } catch(Exception ex) {
            Database.rollback(sp);
            outputMap.put('isSuccessfulTransaction', false);
            outputMap.put('errorMessage', ex.getMessage());
            isSuccess = false;
        }
        return isSuccess;
    }
    
    /**
* @description Wrapper class to hold token data for receipt
*/
    public class TokenData {
        /** @description Name of the bank */
        public String bankName {get;set;}
        
        /** @description Current date */
        public String todayDate {get;set;}
        
        /** @description Unique identifier for the receipt */
        public String receiptNumber {get;set;}
        
        /** @description Date when the receipt was created */
        public String createdDate {get;set;}
        
        /** @description Full name of the customer */
        public String fullName {get;set;}
        
        /** @description Loan account number of the customer */
        public String loanAccountNumber {get;set;}
        
        /** @description Mailing address of the customer */
        public String customerAddress {get;set;}
        
        /** @description Brief description of the transaction */
        public String description {get;set;}
        
        /** @description Flag to indicate if charges should be displayed */
        public Boolean showCharges {get;set;}
        
        /** @description List of charges applied */
        public List<ChargesAndFessDetails> chargesData {get;set;}
        
        /** @description Sum of all charges */
        public String totalChargesAmount {get;set;}
        
        /** @description List of refunds and waive-offs */
        public List<RefundAndWaiveOffClass> refundData {get;set;}
        
        /** @description Total amount of refunds and waive-offs */
        public String totalRefundAndWaiveOffAmount {get;set;}
        
        /** @description Flag to indicate if refunds should be displayed */
        public Boolean showRefunds {get;set;}
        
        /** @description List of denomination details for cash payments */
        public List<Denomination> denominationDetails {get;set;}
        
        /** @description Flag to indicate if cash payment details should be displayed */
        public Boolean showCash {get;set;}
        
        /** @description Total amount of cash denominations */
        public String totalDenominationAmount {get;set;}
        
        /** @description Flag to indicate if cheque payment details should be displayed */
        public Boolean showCheque {get;set;}
        
        /** @description List of cheque payment details */
        public List<ChequeDetails> chequeDetails {get;set;}
        
        /** @description Flag to indicate if online transaction details should be displayed */
        public Boolean showOnlineTransaction {get;set;}
        
        /** @description List of online transaction details */
        public List<PaymentDetails> onlineDetails {get;set;}
        
        /** @description Total amount of the transaction including all payment methods */
        public String grandTotalAmount {get;set;}
    }
    
    /**
* @description Wrapper class to hold charges and fees details
*/
    public class ChargesAndFessDetails {
        /** @description Type of charge or fee */
        public String chargesTypes {get;set;}
        
        /** @description Code associated with the charge or fee */
        public String chargesCode {get;set;}
        
        /** @description Amount of the charge or fee */
        public String chargesAmount {get;set;}
    }
    
    /**
* @description Wrapper class to hold refund and waive-off details
*/
    public class RefundAndWaiveOffClass {
        /** @description Type of refund or waive-off */
        public String refundType {get;set;}
        
        /** @description Amount of the refund or waive-off */
        public String refundAmount {get;set;}
    }
    
    /**
* @description Wrapper class to hold denomination details
*/
    public class Denomination {
        /** @description Value of the denomination */
        public Decimal denomination {get;set;}
        
        /** @description Number of notes for this denomination */
        public Decimal denominationNotes {get;set;}
        
        /** @description Total amount for this denomination */
        public String denominationAmount {get;set;}
    }
    
    /**
* @description Wrapper class to hold cheque details
*/
    public class ChequeDetails {
        /** @description Name of the bank issuing the cheque */
        public String bankName {get;set;}
        
        /** @description IFSC code of the bank */
        public String ifscCode {get;set;}
        
        /** @description MICR code of the bank */
        public String micrCode {get;set;}
        
        /** @description Name on the account */
        public String accountName {get;set;}
        
        /** @description Cheque number */
        public String chequeNumber {get;set;}
        
        /** @description Date on the cheque */
        public String chequeDate {get;set;}
        
        /** @description Amount on the cheque */
        public String chequeAmount {get;set;}
    }
    
    /**
* @description Wrapper class to hold online payment details
*/
    public class PaymentDetails {
        /** @description Name of the bank for online transaction */
        public String bankName {get;set;}
        
        /** @description Unique identifier for the online transaction */
        public String transactionId {get;set;}
        
        /** @description Date of the online transaction */
        public String transactionDate {get;set;}
        
        /** @description Total amount of the online transaction */
        public String totalAmount {get;set;}
    }
}