@isTest
public class TestDataFactory {
/**  @description Creates a Financial Account Transaction
 * @param razorPayId RazorPayment Id
 * @param status of the financial Account Transaction
 * @param amount Amount of the Financial Acount Transaction
 * @param transactionDate financial account Date
 * @param debitCard debit card on the transation
 * @param financialAccount financial account Id
   @return fiTransaction financial account transaction
*/
    public static  FinancialAccountTransaction createFinancialAccountTransaction(String razorPayId ,String status , Decimal amount , Date transactionDate , string debitCard , Id financialAccount)
        {  
            FinancialAccountTransaction fiTransaction = new FinancialAccountTransaction();
            fiTransaction.Status = status;
            fiTransaction.Amount = amount;
            fiTransaction.TransactionDate = transactionDate;
            fiTransaction.RazorPay_Payment_Id__c = razorPayId;
            fiTransaction.FinancialAccountId  = financialAccount;
            fiTransaction.DebitCreditIndicator = debitCard;
            insert fiTransaction;
            return fiTransaction;
            
        }
    /**  @description Creates a Financial Account
     *  @param name String Name of Financial Account
     *  @param primaryOwnerId  Primary Account Id of Financial Account
     *  @param jointOwnerId Joint Account Id of Financial Account
     *  @param financialAccountType Financial Account Type
   	 *  @param financialAccountNumber String Financial Account Number
   	 *  @return fa which is Financial Account Record with all the valdiation considered
	*/
    public static FinancialAccount createFinancialAccount(String name, Id primaryOwnerId, Id jointOwnerId,String financialAccountType , String financialAccountNumber ) {
        FinancialAccount fa = new FinancialAccount();
        fa.Name = name;
        fa.PrimaryOwner__c = primaryOwnerId;
        fa.Type = financialAccountType;
        fa.FinancialAccountNumber = financialAccountNumber;

        // Apply validation rules
        if (primaryOwnerId != null && jointOwnerId != null && primaryOwnerId == jointOwnerId) {
            jointOwnerId = null;
        }
            fa.JointOwner__c = jointOwnerId;
        insert fa;
        return fa;
    }
    
     /**  @description  Helper method to determine if the account is individual based on record type
      *  @param accountId
      * @return a bollean value
	*/
    private static Boolean isIndividualAccount(Id accountId) {
        Account acc = [SELECT RecordType.DeveloperName FROM Account WHERE Id = :accountId LIMIT 1];
        return acc.RecordType.DeveloperName == 'IndustriesIndividual';
    }
     /**  @description Creates a test Account
      *  @param name
      * @param recordTypeName
      * @return a bollean value
	*/
    public static Account createAccount(String name, String recordTypeName) {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = :recordTypeName LIMIT 1];
        Account acc = new Account(Name = name, RecordTypeId = rt.Id);
        insert acc;
        return acc;
    }
   /**  @description Creates a test Contact
      * @param firstName
      * @param lastName
      * @param email
      * @param phone
      * @param accountId
      * @param postal
      * @param recordTypeName
      * @return Contact
	*/
    public static Contact createContact(String firstName, String lastName, String email, String phone,Id accountId,String postal,String recordTypeName) {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = :recordTypeName LIMIT 1];
        Contact con = new Contact(FirstName = firstName, LastName = lastName, Email = email, MobilePhone = phone,AccountId = accountId,MailingPostalCode =postal,RecordTypeId = rt.Id);
        insert con;
        return con;
    }
     /**  @description Creates a test Contact with postal code
      * @param firstName
      * @param lastName
      * @param email
      * @param phone
      * @param accountId
      * @param postal
      * @param recordTypeName
      * @return Contact
	*/
    public static Contact createContactPostal(String firstName, String lastName, String email, String phone,Id accountId, String postal , String recordTypeName) {
         RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = :recordTypeName LIMIT 1];
        Contact con = new Contact(FirstName = firstName, LastName = lastName, Email = email, MobilePhone = phone,AccountId = accountId,MailingPostalCode =postal ,RecordTypeId = rt.Id );
        insert con;
        return con;
    }
   /**  @description Creates a test Case
      *  @param subject
      * @param contactId
      * @param accountId
      * @param productType
      * @param financialAccountId
      * @param totalEmiDue
      * @param amountPaid
      * @param lastEmiDueDate
      * @return a bollean value
	*/
    public static Case createCase(String subject, Id contactId, 
                                  Id accountId, String productType, 
                                  Id financialAccountId, Decimal totalEmiDue, 
                                  Decimal amountPaid, Date lastEmiDueDate) {
        Case cs = new Case(Subject = subject, ContactId = contactId, AccountId = accountId,
         Product_Type__c = productType, Financial_Account__c = financialAccountId,
          Total_EMI_due__c = totalEmiDue, Amount_Paid__c = amountPaid, 
          Last_EMI_Due_Date__c = lastEmiDueDate
          );
        insert cs;
        return cs;
    }
     /**  @description Creates a FOS Agent Assigned test Case
      *  @param subject
      * @param contactId
      * @param accountId
      * @param productType
      * @param financialAccountId
      * @param totalEmiDue
      * @param amountPaid
      * @param lastEmiDueDate
      * @param fosAgentId
      * @return a bollean value
	*/
     public static Case createFOSAgentAssignedCase(String subject, Id contactId, 
                                  Id accountId, String productType, 
                                  Id financialAccountId, Decimal totalEmiDue, 
                                  Decimal amountPaid, Date lastEmiDueDate
                                  ,Id fosAgentId) {
    Case cs = new Case(Subject = subject, ContactId = contactId, 
                           AccountId = accountId, Product_Type__c = productType, 
                           Financial_Account__c = financialAccountId, 
                           Total_EMI_due__c = totalEmiDue, Amount_Paid__c = amountPaid, 
                           Last_EMI_Due_Date__c = lastEmiDueDate,
                          	FOS_Agent__c = fosAgentId);
        insert cs;
        return cs;
    }
}