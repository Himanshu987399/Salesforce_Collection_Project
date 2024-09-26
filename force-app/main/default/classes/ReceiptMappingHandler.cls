public class ReceiptMappingHandler implements omnistudio.VlocityOpenInterface, Callable {
    /**
* @description callmethod
* @param action string variable
* @param args map of argumnets
* @return invokeMethod
*/
    public Object Call(String action, Map<String, Object> args) {
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
            Boolean FromApi = (Boolean)inputMap.get('FromApi');
            String receiptId = '';
            if(FromApi){
                receiptId = (String) inputMap.get('objectId');
            }else{
                Map<String,Object> getSetUpData = (Map<String,Object>) inputMap.get('setupServiceCallInputParams') ?? null ;
                receiptId = (String) getSetUpData.get('objectId') ?? '';
            }
            if(String.isNotBlank(receiptId)){
                Decimal TotalChargesAmount = 0;
                Decimal TotalRefundAndWaiveOffAmount = 0;
                Decimal totalDenominationAmount = 0;
                Decimal TotalChequeAmount = 0;
                Decimal totalOnlineAmount = 0;
                List<FinancialAccountFee> chargesAndFees = new List<FinancialAccountFee>();
                List<ChargesAndFessDetails> chargesDetailsList = new List<ChargesAndFessDetails>();
                List<Refund_and_Waive_off_Request__c> refundAndWaiveOff = new List<Refund_and_Waive_off_Request__c>();
                List<RefundAndWaiveOffClass> refundDataDetailsList = new List<RefundAndWaiveOffClass>();
                List<Denomination> denomiantionListData = new List<Denomination>();
                List<ChequeDetails> chequeDetailsList = new List<ChequeDetails>();
                List<paymentDetails> paymentDetailsList = new List<paymentDetails>();
                system.debug('receiptId--'+receiptId);
                Receipt__c receiptData = [Select Id,Case__c,Name,CreatedDate,Account__r.Name,Case__r.ContactId,Case__r.Contact.MailingStreet,Case__r.Contact.Name,Case__r.Contact.MailingCity,Case__r.Contact.MailingState,Case__r.Contact.MailingAddress,Case__r.Contact.MailingCountry,Case__r.Financial_Account__r.FinancialAccountNumber from Receipt__c Where Id =: receiptId LIMIT 1];
                String caseId = receiptData.Case__c ?? '';
                Address arr = receiptData.Case__r.Contact.MailingAddress != null ? receiptData.Case__r.Contact.MailingAddress : new Address();
                String CustomerAddress = arr.getStreet() == null ? '' :String.ValueOf(arr.getStreet())+' '+
                    arr.getCity() == null ? '' : String.valueOf(arr.getCity()) + ' '+arr.getState() == null ? '' :String.ValueOf(arr.getState())+' '
                        +arr.getcountry() == null ? '' :String.ValueOf(arr.getcountry())+' '
                        +arr.getStateCode() == null ? '' :String.ValueOf(arr.getStateCode());
                if(String.isNotBlank(caseId)){
                    chargesAndFees = [Select Id,Case__c,Type,Amount from FinancialAccountFee Where Case__c =: caseId];
                    if(!chargesAndFees.isEmpty()){
                        List<Schema.PicklistEntry> values = FinancialAccountFee.Type.getDescribe().getPicklistValues();
                        Map<String,String> statusApiToLabelMap = new Map<String,String>();
                        For(Schema.PicklistEntry spE : values){
                            statusApiToLabelMap.put(spE.getValue(), spE.getLabel());
                        }
                        For(FinancialAccountFee chargesInstance : chargesAndFees){
                            TotalChargesAmount += chargesInstance.Amount;
                            ChargesAndFessDetails chargesDetailInstance  = new ChargesAndFessDetails();
                            chargesDetailInstance.ChargesTypes = statusApiToLabelMap.get(chargesInstance.Type ?? '');
                            chargesDetailInstance.ChargesCode = chargesInstance.Type ?? '';
                            chargesDetailInstance.ChargesAmount =  chargesInstance.Amount ?? 0;
                            chargesDetailsList.add(chargesDetailInstance);
                        }
                    }
                    refundAndWaiveOff = [Select Id,Case__c,Amount__c,Type__c from Refund_and_Waive_off_Request__c where Case__c =: caseId AND Approval_Status__c = 'Approved'];
                    For(Refund_and_Waive_off_Request__c rAndWInstance : refundAndWaiveOff){
                        TotalRefundAndWaiveOffAmount += rAndWInstance.Amount__c;
                        RefundAndWaiveOffClass refundAndWaiveOffInstance  = new RefundAndWaiveOffClass();
                        refundAndWaiveOffInstance.RefundType = rAndWInstance.Type__c ?? '';
                        refundAndWaiveOffInstance.RefundAmount = rAndWInstance.Amount__c ?? 0;
                        refundDataDetailsList.add(refundAndWaiveOffInstance);
                    }
                    List<FinancialAccountTransaction > transactionData = [Select Id,status,Receipt__r.Name,Receipt__r.CreatedDate,Amount ,Payment_Method__c,Case__r.Financial_Account__r.FinancialAccountNumber,Refund_and_Waive_off_Request__c from FinancialAccountTransaction Where Case__c =:caseId AND status = 'Paid'AND Refund_and_Waive_off_Request__c = NULL];
                    List<FinancialAccountTransaction > updateReceiptDataInTransaction = new List<FinancialAccountTransaction >();
                    List<Id> cashTransactionId = new List<Id>();
                    List<Id> chequeTransactionId = new List<Id>();
                    List<Id> transactionId = new List<Id>();
                        For( FinancialAccountTransaction transactionInstance : transactionData){
                        if(transactionInstance.Payment_Method__c == 'Cash'){
                            cashTransactionId.add(transactionInstance.Id);
                        }
                        if(transactionInstance.Payment_Method__c == 'Cheque'){
                            chequeTransactionId.add(transactionInstance.Id);
                        }
                        if(transactionInstance.Payment_Method__c == 'Send Payment Link' || transactionInstance.Payment_Method__c == 'Online'){
                            transactionId.add(transactionInstance.Id);
                        }
                        updateReceiptDataInTransaction.add(new FinancialAccountTransaction (Id = transactionInstance.Id,Receipt__c=receiptId));
                    }
                    System.debug('cashTransactionId'+cashTransactionId);
                    Map<Decimal,Decimal> denominationValueVsQuantity = new Map<Decimal,Decimal>();
                    List<Denomination__c> denominationList = [Select Id,Denomination_Value__c,Quantity__c from Denomination__c where Financial_Account_Transaction__c IN: cashTransactionId];//
                    for(Denomination__c denominationInstance : denominationList){
                        if(denominationValueVsQuantity.containsKey(denominationInstance.Denomination_Value__c)){
                            denominationValueVsQuantity.put(denominationInstance.Denomination_Value__c,denominationValueVsQuantity.get(denominationInstance.Denomination_Value__c) + denominationInstance.Quantity__c);
                        }else{
                            denominationValueVsQuantity.put(denominationInstance.Denomination_Value__c,denominationInstance.Quantity__c);
                        }
                    }
                    system.debug('denominationValueVsQuantity---'+denominationValueVsQuantity);
                    for(Decimal denoValue : denominationValueVsQuantity.keySet()){
                        Denomination denoInstance = new Denomination();
                        denoInstance.Denomination = denoValue;
                        denoInstance.Denomiantion_Notes = denominationValueVsQuantity.get(denoValue);
                        denoInstance.Denomination_Amount = denoValue * denominationValueVsQuantity.get(denoValue);
                        totalDenominationAmount += denoValue * denominationValueVsQuantity.get(denoValue);
                        denomiantionListData.add(denoInstance);
                    }
                    //Query List OF Cheque transaction
                    List<FinancialAccountTransaction > chequeTransaction = [select id,Bank_Name__c,Account__r.Name,IFSC__c,MICR__c,Cheque_Number__c,CreatedDate,Amount  from FinancialAccountTransaction Where Id IN: chequeTransactionId];
                    if(!chequeTransaction.isEmpty()){
                        for(FinancialAccountTransaction transactionInstance : chequeTransaction){
                            TotalChequeAmount += transactionInstance.Amount ;
                            ChequeDetails chequeInstance = new ChequeDetails();
                            chequeInstance.Bank_Name = transactionInstance.Bank_Name__c ?? '';
                            chequeInstance.IFSC_code = transactionInstance.IFSC__c ?? '';
                            chequeInstance.MICR_code = transactionInstance.MICR__c ?? '';
                            chequeInstance.Account_Name = transactionInstance.Account__r.Name ?? '';
                            chequeInstance.Cheque_Number =  transactionInstance.Cheque_Number__c;
                            chequeInstance.Cheque_Date = Date.ValueOf(transactionInstance.CreatedDate) ?? System.Today();
                            chequeInstance.Cheque_Amount = transactionInstance.Amount  ?? 0;
                            chequeDetailsList.add(chequeInstance);
                        }
                    }
                    //Query List OF Online transaction
                    List<FinancialAccountTransaction > onlineTransaction = [select id,Bank_Name__c,Transaction_Date__c ,RazorPay_Payment_Id__c,Amount  from FinancialAccountTransaction Where Id IN: transactionId];
                    if(!onlineTransaction.isEmpty()){
                        for(FinancialAccountTransaction transactionInstance : onlineTransaction){
                            totalOnlineAmount += transactionInstance.Amount ;
                            paymentDetails onlineInstance = new paymentDetails();
                            onlineInstance.BankName = transactionInstance.Bank_Name__c ?? '';
                            onlineInstance.TransactionId = transactionInstance.RazorPay_Payment_Id__c ?? '';
                            onlineInstance.TransactionDate = transactionInstance.Transaction_Date__c  ?? '';
                            onlineInstance.TotalAmount = transactionInstance.Amount  ?? 0;
                            paymentDetailsList.add(onlineInstance);
                        }
                    }
                    
                    if(!updateReceiptDataInTransaction.isEmpty()){
                        UPDATE updateReceiptDataInTransaction;
                    }
                    Update new Case(Is_Receipt_Send__c = true,Id = caseId);
                }
                tokenDataInstance.Bank_Name = system.label.Bank_Name;
                tokenDataInstance.Today_Date = System.Today();
                tokenDataInstance.ReceiptNumber = receiptData.Name;
                tokenDataInstance.CreatedDate = Date.ValueOf(receiptData.CreatedDate);
                tokenDataInstance.FullName = receiptData.Case__r.Contact.Name ?? '';
                tokenDataInstance.Loan_Account_Number =receiptData.Case__r.Financial_Account__r.FinancialAccountNumber;
                tokenDataInstance.Customer_Address = CustomerAddress;
                tokenDataInstance.show_Charges =chargesDetailsList.isEmpty() ? false : true;
                tokenDataInstance.ChargesData = chargesDetailsList;
                tokenDataInstance.TotalChargesAmount = TotalChargesAmount;
                tokenDataInstance.RefundData = refundDataDetailsList;
                tokenDataInstance.TotalRefundAndWaiveOffAmount = TotalRefundAndWaiveOffAmount;
                tokenDataInstance.showRefunds = refundDataDetailsList.isEmpty() ? false:true;
                tokenDataInstance.Denomination_Details = denomiantionListData;
                tokenDataInstance.showCash = denomiantionListData.isEmpty() ? false:true;
                tokenDataInstance.Total_Denomination_Amount = totalDenominationAmount;
                tokenDataInstance.show_Cheque = chequeDetailsList.isEmpty() ? false:true;
                tokenDataInstance.ChequeDetails = chequeDetailsList;
                tokenDataInstance.show_Online_Transaction = paymentDetailsList.isEmpty() ? false:true;
                tokenDataInstance.OnlineDetails = paymentDetailsList;
                tokenDataInstance.GrandTotalAmount = totalDenominationAmount + TotalChequeAmount + totalOnlineAmount ;
                tokenDataInstance.Description =  'Received with thanks, ₹ '+ tokenDataInstance.GrandTotalAmount  +' towards settlement of overdue amount in Loan Account '+tokenDataInstance.Loan_Account_Number+'.';
                outputMap.put('responseData', JSON.serialize(tokenDataInstance));
                outputMap.put('isSuccessfulTransaction', True);
                isSuccess = true;
            } else {
                Database.rollback(sp);
                outputMap.put('isSuccessfulTransaction', false);
                outputMap.put('errorMessage', 'No Receipt found with the given ID');
                isSuccess = false;
            }
        } catch(Exception ex) {
            Database.rollback(sp);
            outputMap.put('isSuccessfulTransaction', false);
            outputMap.put('errorMessage', ex.getMessage());
            isSuccess = false;
        }
        return isSuccess;
    }
    
    public class TokenData {
        public String Bank_Name {get;set;}
        public Date Today_Date { get; set; }
        public String ReceiptNumber { get; set;}
        public Date CreatedDate {get;set;}
        public String FullName {get;set;}
        public String Loan_Account_Number {get;set;}
        public String Customer_Address {get;set;}
        public String Description {get;set;}
        public Boolean show_Charges {get;set;}
        public List<ChargesAndFessDetails> ChargesData {get;set;}
        public Decimal TotalChargesAmount{get;set;}
        public List<RefundAndWaiveOffClass> RefundData{get;set;}
        public Decimal TotalRefundAndWaiveOffAmount{get;set;}
        public Boolean showRefunds {get;set;}
        public List<Denomination> Denomination_Details{get;set;}
        public Boolean showCash {get;set;}
        public Decimal Total_Denomination_Amount{get;set;}
        public Boolean show_Cheque {get;set;}
        public List<ChequeDetails> ChequeDetails{get;set;}
        public Boolean show_Online_Transaction{get;set;}
        public List<paymentDetails> OnlineDetails{get;set;}
        public Decimal GrandTotalAmount{get;set;} 
    }
    public class ChargesAndFessDetails{
        public String ChargesTypes {get;set;}
        public String ChargesCode {get;set;}
        public Decimal ChargesAmount {get;set;}
    }
    public class RefundAndWaiveOffClass{
        public String RefundType {get;set;}
        public Decimal RefundAmount {get;set;}
    }
    public class Denomination{
        public Decimal Denomination{get;set;}
        public Decimal Denomiantion_Notes{get;set;}
        public Decimal Denomination_Amount{get;set;}
    }
    public class ChequeDetails{
        public String Bank_Name{get;set;}
        public String IFSC_code{get;set;}
        public String MICR_code{get;set;}
        public String Account_Name{get;set;}
        public String Cheque_Number{get;set;}
        public Date Cheque_Date{get;set;}
        public Decimal Cheque_Amount{get;set;}
    }
    public class paymentDetails {
        public String BankName{get;set;}
        public String TransactionId{get;set;}
        public String TransactionDate{get;set;}
        public Decimal TotalAmount{get;set;}
    }
}