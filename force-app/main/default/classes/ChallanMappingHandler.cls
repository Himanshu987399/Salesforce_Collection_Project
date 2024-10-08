/**
 * @description This class handles the mapping of receipt data and related financial transactions.
 * It implements the VlocityOpenInterface for integration with Vlocity and is also Callable.
 * The class processes challan information and performs various calculations on financial data.
 */
public with sharing class ChallanMappingHandler implements omnistudio.VlocityOpenInterface, Callable {
    
    /**
     * @description Implements the Callable interface method.
     * @param action The action to be performed.
     * @param args A map of arguments for the action.
     * @return The result of invokeMethod.
     */
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }
    
    /**
     * @description Invokes the specified method with given parameters.
     * @param methodName The name of the method to invoke.
     * @param inputMap A map of input parameters.
     * @param outputMap A map to store output results.
     * @param options A map of additional options.
     * @return Boolean indicating success or failure of the method invocation.
     */
    public Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        TokenData tokenData = new TokenData();
        Boolean isSuccess = false;
        try {
            String challanId = (String) inputMap.get('objectId');
            List<Challan__c> challanList = [SELECT Id, Name, Challan_Date__c, FOS_User__r.Name, Branch_Unit__r.Name, FOS_User__r.MobilePhone 
                                            FROM Challan__c 
                                            WHERE Id = :challanId 
                                            WITH SECURITY_ENFORCED
                                            LIMIT 1];
            
            if (!challanList.isEmpty()) {
                Challan__c challan = challanList[0];
                Decimal totalAmount = 0.00;
                List<Id> transactionIds = new List<Id>();
                List<FinancialAccountTransaction> transactionList = [SELECT Id, Status, Receipt__r.Name, Receipt__r.CreatedDate, Amount, Payment_Method__c, Case__r.Financial_Account__r.FinancialAccountNumber 
                                                                     FROM FinancialAccountTransaction 
                                                                     WHERE Challan__c = :challanId AND Status = 'Paid' WITH SECURITY_ENFORCED];
                
                List<TransactionDetails> transactionDetailsList = new List<TransactionDetails>();
                
                for (FinancialAccountTransaction transactionInstance : transactionList) {
                    totalAmount += transactionInstance.Amount.setScale(2);
                    TransactionDetails transactionDetail = new TransactionDetails();
                    transactionDetail.loanAccountNumber = transactionInstance.Case__r.Financial_Account__r.FinancialAccountNumber;
                    transactionDetail.receiptNumber = transactionInstance.Receipt__r.Name != null ? transactionInstance.Receipt__r.Name : '';
                    transactionDetail.receiptDate = transactionInstance.Receipt__r.CreatedDate != null ? transactionInstance.Receipt__r.CreatedDate.format('dd/MM/yyyy') : Date.today().format();
                    transactionDetail.receiptAmount = String.valueOf(transactionInstance.Amount.setScale(2));
                    transactionDetail.paymentMethod = transactionInstance.Payment_Method__c;
                    transactionIds.add(transactionInstance.Id);
                    transactionDetailsList.add(transactionDetail);
                }
                
                Decimal totalDenominationAmount = 0.00;
                Map<Decimal, Decimal> denominationValueToQuantity = new Map<Decimal, Decimal>();
                List<Denomination> denominationList = new List<Denomination>();
                
                List<Denomination__c> denominationRecords = [SELECT Id, Denomination_Value__c, Quantity__c 
                                                             FROM Denomination__c 
                                                             WHERE Financial_Account_Transaction__c IN :transactionIds WITH SECURITY_ENFORCED];
                
                for (Denomination__c denominationRecord : denominationRecords) {
                    Decimal currentQuantity = denominationValueToQuantity.containsKey(denominationRecord.Denomination_Value__c) 
                        ? denominationValueToQuantity.get(denominationRecord.Denomination_Value__c) 
                        : 0;
                    denominationValueToQuantity.put(denominationRecord.Denomination_Value__c, currentQuantity + denominationRecord.Quantity__c);
                }
                
                for (Decimal denominationValue : denominationValueToQuantity.keySet()) {
                    Denomination denomination = new Denomination();
                    denomination.denominationValue = denominationValue;
                    denomination.denominationNotes = denominationValueToQuantity.get(denominationValue);
                    denomination.denominationAmount = String.valueOf((denominationValue * denominationValueToQuantity.get(denominationValue)).setScale(2));
                    totalDenominationAmount += (denominationValue * denominationValueToQuantity.get(denominationValue)).setScale(2);
                    denominationList.add(denomination);
                }
                
                tokenData.todayDate = Date.today().format();
                tokenData.challanNumber = challan.Name != null ? challan.Name : '';
                tokenData.branchName = challan.Branch_Unit__r.Name != null ? challan.Branch_Unit__r.Name : '';
                tokenData.challanDate = challan.Challan_Date__c != null ? challan.Challan_Date__c.format('dd/MM/yyyy') : Date.today().format();
                tokenData.fosAgentName = challan.FOS_User__r.Name != null ? challan.FOS_User__r.Name : '';
                tokenData.fosAgentNumber = challan.FOS_User__r.MobilePhone != null ? challan.FOS_User__r.MobilePhone : '';
                tokenData.amountDescription = 'Received Rs ' + totalAmount + ' towards deposit of cash against the following accounts';    
                tokenData.receiptDetails = transactionDetailsList;    
                tokenData.totalReceiptAmount = String.valueOf(totalAmount);
                tokenData.denominationDetails = denominationList;    
                tokenData.totalDenominationAmount = String.valueOf(totalDenominationAmount);
                
                outputMap.put('responseData', JSON.serialize(tokenData));
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
    
    /**
     * @description Represents the token data structure for challan information.
     */
    public class TokenData {
        /** @description Name of the bank */
        public String bankName { get; set; }
        /** @description Current date */
        public String todayDate { get; set; }
        /** @description Challan number */
        public String challanNumber { get; set; }
        /** @description Name of the branch */
        public String branchName { get; set; }
        /** @description Date of the challan */
        public String challanDate { get; set; }
        /** @description Name of the FOS agent */
        public String fosAgentName { get; set; }
        /** @description Phone number of the FOS agent */
        public String fosAgentNumber { get; set; }
        /** @description Description of the amount */
        public String amountDescription { get; set; }
        /** @description List of receipt details */
        public List<TransactionDetails> receiptDetails { get; set; }
        /** @description Total amount of all receipts */
        public String totalReceiptAmount { get; set; }
        /** @description List of denomination details */
        public List<Denomination> denominationDetails { get; set; }
        /** @description Total amount of all denominations */
        public String totalDenominationAmount { get; set; }
    }
    
    /**
     * @description Represents the details of a single transaction.
     */
    public class TransactionDetails {
        /** @description Loan account number */
        public String loanAccountNumber { get; set; }
        /** @description Receipt number */
        public String receiptNumber { get; set; }
        /** @description Date of the receipt */
        public String receiptDate { get; set; }
        /** @description Amount on the receipt */
        public String receiptAmount { get; set; }
        /** @description Method of payment */
        public String paymentMethod { get; set; }
    }
    
    /**
     * @description Represents the details of a single denomination.
     */
    public class Denomination {
        /** @description Value of the denomination */
        public Decimal denominationValue { get; set; }
        /** @description Number of notes for this denomination */
        public Decimal denominationNotes { get; set; }
        /** @description Total amount for this denomination */
        public String denominationAmount { get; set; }
    }
}