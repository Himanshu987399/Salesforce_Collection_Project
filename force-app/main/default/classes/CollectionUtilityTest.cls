/**
 * @description Test class for CollectionUtility
 */
@isTest
public class CollectionUtilityTest {
    
    /**
     * @description Test method to verify various functionalities of CollectionUtility
     */
    @isTest
    static void testCollectionUtilityMethods() {
        // Test data setup
        TestData testData = createTestData();
        
        Test.startTest();
        
        // Test createErrorLogRecord method
        Id errorLogId = CollectionUtility.createErrorLogRecord(
            testData.recordId, 
            testData.apexClassName, 
            testData.methodName, 
            testData.location, 
            testData.lineNumber, 
            testData.errorTitle, 
            testData.errorDescription
        );
        System.assertNotEquals(null, errorLogId, 'Error log should be created');
        
        // Test createAPILogRecord method
        API_Log__c apiLog = CollectionUtility.createAPILogRecord(
            testData.recordId, 
            testData.type, 
            testData.endpoint, 
            testData.headers, 
            testData.method, 
            testData.requestBody, 
            testData.responseBody, 
            testData.responseCode
        );
        System.assertNotEquals(null, apiLog.Id, 'API log should be created');
        
        // Test getContentDocumentId method
        CollectionUtility.getContentDocumentId(String.ValueOf(testData.documentGenerationProcess.Id));
        
        // Test Call method
        CollectionUtility collectionUtility = new CollectionUtility();
        Object callResult = collectionUtility.Call('TestAction', testData.args);
        Test.stopTest();
        System.assertEquals(true, callResult, '');
        
    }
    
    /**
     * @description Creates and returns test data for the test methods
     * @return TestData object containing all the test records
     */
    private static TestData createTestData() {
        TestData data = new TestData();
        
        // Create test accounts
        data.primaryAccount = TestDataFactory.createAccount('Test Account Primary', 'Business');
        data.jointAccount = TestDataFactory.createAccount('Test Account Joint', 'Business');
        
        // Create test financial accounts
        data.financialAccount = TestDataFactory.createFinancialAccount(
            'Financial Test Joint',
            data.primaryAccount.Id,
            data.jointAccount.Id,
            'Checking',
            '12345'
        );
        
        data.savingsAccount = TestDataFactory.createFinancialAccount(
            'Test Financial Account',
            data.primaryAccount.Id,
            data.jointAccount.Id,
            'Checking',
            '1234567890'
        );
        
        // Create test contacts
        data.businessContact = TestDataFactory.createContact(
            'John', 'Doe', 'johndoe@test.com', '1234567890', 
            data.primaryAccount.Id, '12345', 'Business'
        );
        
        data.fosContact = TestDataFactory.createContact(
            'JohnFOS', 'DoeFOS', 'fos@test.com', '1234567810', 
            data.primaryAccount.Id, '12345', 'FOS'
        );
        
        // Create test FOS agent assigned case
        data.testCase = TestDataFactory.createFOSAgentAssignedCase(
            'Test Case',
            data.businessContact.Id,
            data.primaryAccount.Id,
            'Auto Loan',
            data.savingsAccount.Id,
            10000,
            50000,
            Date.today(),
            data.fosContact.Id
        );
        
        // Create ContentVersion
        ContentVersion cv = new Contentversion(
            title = 'ABC',
            PathOnClient = 'test',
            versiondata = EncodingUtil.base64Decode('This is version data')
        );
        insert cv;
        
        // Create DocumentGenerationProcess
        data.documentGenerationProcess = new DocumentGenerationProcess(
            RequestText = '{"keepIntermediate":false,"title":"Legal notice","templateContentVersionId":' + cv.Id + '}',
            TokenData = '{"CustomerNameLegal":"Sohan Rawat","CustomerAddressLegal":"Hokaran Ajmer 305004 RJ","EMIAmountLegal":3000.00,"CaseOwnerNameLegal":""}'
        );
        insert data.documentGenerationProcess;
        
        // Set up other test data
        data.recordId = data.testCase.Id;
        data.apexClassName = 'TestClass';
        data.methodName = 'testMethod';
        data.location = 'TestLocation';
        data.lineNumber = 123;
        data.errorTitle = 'TestError';
        data.errorDescription = 'This is a test error description';
        data.type = 'Outbound';
        data.endpoint = 'https://test.endpoint.com';
        data.headers = 'TestHeaders';
        data.method = 'POST';
        data.requestBody = 'TestRequestBody';
        data.responseBody = 'TestResponseBody';
        data.responseCode = 200;
        
        // Set up args for Call method
        data.args = new Map<String, Object>{
            'input' => new Map<String, Object>{'ContextId' => data.testCase.Id},
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
        
        return data;
    }
    
    /**
     * @description Inner class to hold test data
     */
    private class TestData {
        public Account primaryAccount;
        public Account jointAccount;
        public FinancialAccount financialAccount;
        public FinancialAccount savingsAccount;
        public Contact businessContact;
        public Contact fosContact;
        public Case testCase;
        public DocumentGenerationProcess documentGenerationProcess;
        public String recordId;
        public String apexClassName;
        public String methodName;
        public String location;
        public Decimal lineNumber;
        public String errorTitle;
        public String errorDescription;
        public String type;
        public String endpoint;
        public String headers;
        public String method;
        public String requestBody;
        public String responseBody;
        public Integer responseCode;
        public Map<String, Object> args;
    }
}