@isTest
public class FetchPaymentStatusBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create sample FinancialAccountTransaction records
        List<FinancialAccountTransaction> transactions = new List<FinancialAccountTransaction>();
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        for (Integer i = 0; i < 5; i++) {
            FinancialAccountTransaction trans = new FinancialAccountTransaction();
            trans.RazorPay_Payment_Id__c = 'pay_' + String.valueOf(i);
            trans.Status = 'Pending';
            trans.FinancialAccountId = financialAccount.Id ;
            trans.DebitCreditIndicator = 'Credit';
            trans.Amount = 100.00;
            trans.TransactionDate = Date.today().addDays(-i);
            transactions.add(trans);
        }
        insert transactions;
    }

    @isTest
    static void testFetchPaymentStatusBatch() {
        FetchPaymentStatusBatch batchClass = new FetchPaymentStatusBatch();
        Test.startTest();
        Database.executeBatch(batchClass, 200);
        Test.stopTest();
        List<FinancialAccountTransaction> transactions = [SELECT Id, RazorPay_Payment_Id__c, Status 
                                                          FROM FinancialAccountTransaction 
                                                          WHERE RazorPay_Payment_Id__c != null];
        System.assertEquals(5, transactions.size(), 'All transactions should be processed');
    }
    @isTest
    static void testFetchPaymentStatusBatchNoRazorPayId() {
        Account accBusinessPrimary = TestDataFactory.createAccount('Test Account Primary', 'Business');
        Account accBusinessJoint = TestDataFactory.createAccount('Test Account Joint', 'Business');
        FinancialAccount financialAccount = TestDataFactory.createFinancialAccount('Fianacial Test Joint',accBusinessPrimary.Id , accBusinessJoint.Id,'Checking','12345');
        FinancialAccountTransaction trans = new FinancialAccountTransaction();
        trans.Status = 'Pending';
        trans.Amount = 100.00;
        trans.TransactionDate = Date.today();
        trans.FinancialAccountId = financialAccount.Id ;
        trans.DebitCreditIndicator = 'Credit';
        insert trans;
        FetchPaymentStatusBatch batchClass = new FetchPaymentStatusBatch();
        
        Test.startTest();
        Database.executeBatch(batchClass, 200);
        Test.stopTest();
        
        List<FinancialAccountTransaction> transactions = [SELECT Id, RazorPay_Payment_Id__c 
                                                          FROM FinancialAccountTransaction 
                                                          WHERE Id = :trans.Id];
        System.assertEquals(null, transactions[0].RazorPay_Payment_Id__c, 'This transaction should not have a RazorPay_Payment_Id__c');
    }
}