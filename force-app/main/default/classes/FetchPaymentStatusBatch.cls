public with sharing class FetchPaymentStatusBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'SELECT Id, RazorPay_Payment_Id__c, Status, Amount , TransactionDate  ' +
                   'FROM FinancialAccountTransaction ' +
                   'WHERE Status != \'Created\'';
    return Database.getQueryLocator(query);
}

    public void execute(Database.BatchableContext BC, List<FinancialAccountTransaction> scope) {
    for (FinancialAccountTransaction fin : scope) {
        if (fin.RazorPay_Payment_Id__c != null) {
            List<String> razorPayId = new List<String>{fin.RazorPay_Payment_Id__c};
            PaymentGatewayIntegration.checkPaymentStatus(razorPayId, false, null);
        }
    }
}
   public void finish(Database.BatchableContext BC) {
    }
}