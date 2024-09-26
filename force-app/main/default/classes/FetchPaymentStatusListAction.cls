/**
 * @Author       TechMatrix Team
 * @description  ISS-000673 The class for fetching payment status and returning success or error message in flow
 */
public with sharing class FetchPaymentStatusListAction {
    /**
     * @description Fetches payment status and returns a message
     * @param inputVal List of InputVariable containing transaction ID
     * @return List<OutputVariable> containing status message and error information
     */
    @InvocableMethod(label='Fetch Payment Status' description='Returns message while fetching payment status.')
    public static List<OutputVariable> fetchPaymentStatus(List<InputVariable> inputVal) {
        try {
            // Get the Transaction ID from the input variables
            String transactionId = inputVal[0].transactionId;

            // Query to retrieve the transaction with the given ID
            Map<Id, FinancialAccountTransaction> transactionMap = new Map<Id, FinancialAccountTransaction>([
                SELECT Id, RazorPay_Payment_Id__c, Status 
                FROM FinancialAccountTransaction
                WHERE Id = :transactionId 
                LIMIT 1
            ]);

            // Check if the transaction was found
            if (transactionMap.isEmpty()) {
                return new List<OutputVariable> {new OutputVariable('Transaction is not found', true, '')};
            }

            // Get the transaction object from the map
            FinancialAccountTransaction transactionData = transactionMap.get(transactionId);

            // Check if the transaction has a Razorpay payment ID
            if (String.isBlank(transactionData.RazorPay_Payment_Id__c)) {
                return new List<OutputVariable> {new OutputVariable('Razorpay payment id not found', true, '')};
            }

            // Call https request to check payment status
            PaymentGateWayIntegration.ApiResponse responseFromPaymentClass = PaymentGateWayIntegration.checkPaymentStatus(new List<String>(), true, transactionData.RazorPay_Payment_Id__c);
            
            if (!responseFromPaymentClass.isSuccess) {
                // Return the response message and error status
                return new List<OutputVariable>{new OutputVariable(responseFromPaymentClass.message, true, '')};
            }

            // Return the Success message, error status, payment status
            return new List<OutputVariable>{new OutputVariable('Successfully found payment status, payment status is ' + responseFromPaymentClass.paymentStatus, false, responseFromPaymentClass.paymentStatus)};
        } catch (Exception ex) {
            // Handle any exceptions and return the error message
            return new List<OutputVariable> {new OutputVariable(ex.getMessage(), true, '')};
        }
    }
    
    /**
     * @description Inner class to represent input variables for the invocable method
     */
    public class InputVariable {
        @InvocableVariable(required=true label='Transaction Id')
        public String transactionId;
    }

    /**
     * @description Inner class to represent output variables for the invocable method
     */
    public class OutputVariable {
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        @InvocableVariable(label='Is Error')
        public boolean isError;
        @InvocableVariable(label='Payment Status')
        public String razorPaymentStatus;
        
        /**
         * @description Constructor to initialize output variables
         * @param errorMessage Error message if any
         * @param isError Flag indicating if there's an error
         * @param razorPaymentStatus Payment status from Razorpay
         */
        public OutputVariable(String errorMessage, Boolean isError, String razorPaymentStatus) {
            this.errorMessage = errorMessage;
            this.isError = isError;
            this.razorPaymentStatus = razorPaymentStatus;
        }
    }
}