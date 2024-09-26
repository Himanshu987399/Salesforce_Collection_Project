public class ChallanMappingHandler implements omnistudio.VlocityOpenInterface, Callable {
    
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
        TokenData tokenDataInstance = new TokenData();
        Boolean isSuccess = false;
        try {
            String challanId = (String) inputMap.get('objectId');
            List<Challan__c> challanData = [SELECT Id, Name, Challan_Date__c, FOS_User__r.Name, Branch_Unit__r.Name, FOS_User__r.MobilePhone FROM Challan__c WHERE Id = :challanId];
            if (!challanData.isEmpty()) {
                Decimal TotalAmount = 0;
                List<Id> transactionId = new List<Id>();
                List<FinancialAccountTransaction> transactionData = [Select Id,Status,Receipt__r.Name,Receipt__r.CreatedDate,Amount ,Payment_Method__c,Case__r.Financial_Account__r.FinancialAccountNumber from FinancialAccountTransaction Where Challan__c =: challanId AND Status = 'Paid'];
                List<TransactionDetails> transactionList = new List<TransactionDetails>();
                for(FinancialAccountTransaction transactionInstance : transactionData){
                    TotalAmount += transactionInstance.Amount ;
                    TransactionDetails transactionDetIns = new TransactionDetails();
                    transactionDetIns.Loan_Account_Number = transactionInstance.Case__r.Financial_Account__r.FinancialAccountNumber;
                    transactionDetIns.Receipt_Number = transactionInstance.Receipt__r.Name ?? '';
                    transactionDetIns.Receipt_Date = Date.ValueOf(transactionInstance.Receipt__r.CreatedDate) ?? System.Today();
                    transactionDetIns.Receipt_Amount = transactionInstance.Amount ;
                    transactionDetIns.Payment_Method = transactionInstance.Payment_Method__c;
                    transactionId.add(transactionInstance.Id);
                    transactionList.add(transactionDetIns);
                }
                Decimal totalDenominationAmount = 0;
                Map<Decimal,Decimal> denominationValueVsQuantity = new Map<Decimal,Decimal>();
                List<Denomination> denomiantionListData = new List<Denomination>();
                List<Denomination__c> denominationList = [Select Id,Denomination_Value__c,Quantity__c from Denomination__c  where Financial_Account_Transaction__c IN: transactionId];//
                for(Denomination__c denominationInstance : denominationList){
                    if(denominationValueVsQuantity.containsKey(denominationInstance.Denomination_Value__c)){
                        denominationValueVsQuantity.put(denominationInstance.Denomination_Value__c,denominationValueVsQuantity.get(denominationInstance.Denomination_Value__c) + denominationInstance.Quantity__c);
                    }else{
                        denominationValueVsQuantity.put(denominationInstance.Denomination_Value__c,denominationInstance.Quantity__c);
                    }
                }
                for(Decimal denoValue : denominationValueVsQuantity.keySet()){
                    Denomination denoInstance = new Denomination();
                    denoInstance.Denomination = denoValue;
                    denoInstance.Denomiantion_Notes = denominationValueVsQuantity.get(denoValue);
                    denoInstance.Denomination_Amount = denoValue * denominationValueVsQuantity.get(denoValue);
                    totalDenominationAmount += denoValue * denominationValueVsQuantity.get(denoValue);
                    denomiantionListData.add(denoInstance);
                }
                tokenDataInstance.Today_Date = System.Today();
                tokenDataInstance.Challan_Number = challanData[0].Name ?? '';
                tokenDataInstance.Branch_Name = challanData[0].Branch_Unit__r.Name ?? '';
                tokenDataInstance.Challan_Date = Date.valueOf(challanData[0].Challan_Date__c) ?? System.Today();
                tokenDataInstance.FOS_Agent_Name = challanData[0].FOS_User__r.Name ?? '';
                tokenDataInstance.FOS_Agent_Number = challanData[0].FOS_User__r.MobilePhone ?? '';
                tokenDataInstance.Amount_Description = 'Received Rs '+TotalAmount+' towards deposit of cash against the following accounts';    
                tokenDataInstance.ReceiptDetails = transactionList;    
                tokenDataInstance.Total_Receipt_Amount = TotalAmount;
                tokenDataInstance.Denomination_Details = denomiantionListData;    
                tokenDataInstance.Total_Denomination_Amount = totalDenominationAmount;
                outputMap.put('responseData', JSON.serialize(tokenDataInstance));
                isSuccess = true;
            } else {
                outputMap.put('errorMessage', 'No Challan found with the given ID');
                isSuccess = false;
            }
        } catch(Exception ex) {
            outputMap.put('errorMessage', ex.getMessage());
            isSuccess = false;
        }
        return isSuccess;
    }
    
    public class TokenData {
        public String Bank_Name { get; set; }
        public Date Today_Date { get; set; }
        public String Challan_Number { get; set; }
        public String Branch_Name { get; set; }
        public Date Challan_Date { get; set; }
        public String FOS_Agent_Name { get; set; }
        public String FOS_Agent_Number { get; set; }
        public String Amount_Description {get;set;}
        public List<TransactionDetails> ReceiptDetails{get;set;}
        public Decimal Total_Receipt_Amount {get;set;}
        public List<Denomination> Denomination_Details{get;set;}
        public Decimal Total_Denomination_Amount {get;set;}
    }
    public class TransactionDetails{
        public string Loan_Account_Number {get;set;}
        public String Receipt_Number {get;set;}
        public Date Receipt_Date {get;set;}
        public Decimal Receipt_Amount {get;set;}
        public string Payment_Method {get;set;}
        
    }
    public class Denomination{
        public Decimal Denomination{get;set;}
        public Decimal Denomiantion_Notes{get;set;}
        public Decimal Denomination_Amount{get;set;}
    }
}