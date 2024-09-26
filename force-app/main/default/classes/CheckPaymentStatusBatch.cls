/**
 * @author TechMatrix Team
 * @description ISS-000673 This batch class updates the status of payment in transaction records
 */
public class CheckPaymentStatusBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    
    private List<String> errors;
    private static final String UNPAID_STATUS = 'UnPaid';

    /**
     * @description Constructor to initialize the errors list
     */
    public CheckPaymentStatusBatch() {
        this.errors = new List<String>();
    }
    
    /**
     * @description Starts the batch job by returning a query locator
     * @param bc The batch context
     * @return Database.QueryLocator The query locator for the batch job
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, RazorPay_Payment_Id__c, Status 
            FROM FinancialAccountTransaction
            WHERE RazorPay_Payment_Id__c != null
        ]);
    }
    
    /**
     * @description Executes the batch job for a chunk of records
     * @param bc The batch context
     * @param transactions The list of FinancialAccountTransactionrecords to process
     */
    public void execute(Database.BatchableContext bc, List<FinancialAccountTransaction> transactions) {
        try {
            List<String> paymentIds = new List<String>();
            Map<String, String> paymentIdToTransactionId = new Map<String, String>();
            
            for (FinancialAccountTransaction transactionInstance : transactions) {
                paymentIds.add(transactionInstance.RazorPay_Payment_Id__c);
                paymentIdToTransactionId.put(transactionInstance.RazorPay_Payment_Id__c, transactionInstance.Id);
            }
            
            PaymentGatewayIntegration.ApiResponse apiResponse = PaymentGatewayIntegration.checkPaymentStatus(paymentIds, false, '');
            
            if (!apiResponse.isSuccess) {
                errors.add(apiResponse.message);
                return;
            }
            
            List<FinancialAccountTransaction> transactionsToUpdate = new List<FinancialAccountTransaction>();
            
            for (PaymentGatewayIntegration.RazorpayPaymentLinkResponse paymentResponse : apiResponse.paymentLinkResponse) {
                String transactionId = paymentIdToTransactionId.get(paymentResponse.id);
                if (String.isNotBlank(transactionId)) {
                    transactionsToUpdate.add(new FinancialAccountTransaction(
                        Id = transactionId,
                        Status = paymentResponse.status
                    ));
                }
            }
            
            if (!transactionsToUpdate.isEmpty()) {
                update transactionsToUpdate;
            }
        } catch (Exception ex) {
            errors.add(ex.getMessage());
            // Consider logging the exception or notifying admins
        }
    }
    
    /**
     * @description Finishes the batch job and handles any errors
     * @param bc The batch context
     */
    public void finish(Database.BatchableContext bc) {
        if (!errors.isEmpty()) {
            sendErrorNotification();
        }
    }

    /**
     * @description Sends an email notification to administrators about the errors
     */
    private void sendErrorNotification() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>{system.Label.Batch_Error_Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('CheckPaymentStatusBatch Errors');
        
        String emailBody = 'The following errors occurred in the CheckPaymentStatusBatch job:\n\n';
        for (String error : errors) {
            emailBody += '- ' + error + '\n';
        }
        
        mail.setPlainTextBody(emailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
}