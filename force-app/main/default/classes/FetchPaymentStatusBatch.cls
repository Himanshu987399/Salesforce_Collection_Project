/**
     * @author TechMatrix Team
     * @description This class fetches the payment status using batch Apex
     */
public with sharing class FetchPaymentStatusBatch implements Database.Batchable<SObject> {
    /**
* @description Starting method for batch Apex
* @param bc batchable Context
* @return query String Querry for Batch process
*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
    String query = 'SELECT Id, RazorPay_Payment_Id__c, Status, Amount , TransactionDate  ' +
                   'FROM FinancialAccountTransaction ' +
                   'WHERE Status != \'Created\'';
    return Database.getQueryLocator(query);
}
    /**
* @description execute method for Batch Apex.
* @param bc batchable Context
* @param scope List<FinancialAccountTransaction> this List was queeried as string in strat method
*/
    public void execute(Database.BatchableContext bc, List<FinancialAccountTransaction> scope) {
    for (FinancialAccountTransaction fin : scope) {
        if (fin.RazorPay_Payment_Id__c != null) {
            List<String> razorPayId = new List<String>{fin.RazorPay_Payment_Id__c};
            PaymentGatewayIntegration.checkPaymentStatus(razorPayId, false, null);
        }
    }
}
        /**
* @description final method for Batch Apex.
* @param bc batchable Context
*/
   public void finish(Database.BatchableContext bc) {
       // no post batch process right now therfore empty
    }
}