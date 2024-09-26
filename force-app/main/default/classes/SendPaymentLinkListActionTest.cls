/**
 * @author TechMatrix Team
 * @description Test class for SendPaymentLinkList
 */
@isTest
public class SendPaymentLinkListActionTest {

    /*@isTest
    static void splla_nocaseFound() {  //test method when no case is found
        SendPaymentLinkListAction.InputVariable input = new SendPaymentLinkListAction.InputVariable();
        input.caseId = '0';

        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{input};
        List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertNotEquals(null, result[0].errorMessage);
    }

    @isTest
    static void splla_relatedContactOnCase() { // test method when no related contact is found on the case
        Case testCase = new Case();
        testCase.Subject = 'No related Contact';
        insert testCase;

        SendPaymentLinkListAction.InputVariable input = new SendPaymentLinkListAction.InputVariable();
        input.caseId = testCase.Id;

        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{input};
        List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertNotEquals(null, result[0].errorMessage);
    }

    @isTest
    static void splla_noEmailOnRelatedContact() { // test class when no Email is found
        Contact testContact = new Contact();
        testContact.LastName = 'Test';
        testContact.FirstName = 'SendPaymentAction';
        insert testContact;

        Case testCase = new Case();
        testCase.Subject = 'No emai';
        testCase.ContactId = testContact.Id;
        insert testCase;

        SendPaymentLinkListAction.InputVariable input = new SendPaymentLinkListAction.InputVariable();
        input.caseId = testCase.Id;

        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{input};
        List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertNotEquals(null, result[0].errorMessage);
    }

    @isTest
    static void splla_noPhoneOnRelatedContact() { // Test class when no Phone is found on the contact of test case
        Contact testContact = new Contact(); 
        testContact.LastName = 'Test';
        testContact.FirstName = 'SendPaymentAction';
        testContact.Email = 'test@example.com'; 
        testContact.MobilePhone = null; // No phone
        insert testContact;

        Case testCase = new Case();
        testCase.Subject = 'No phone';
        testCase.ContactId = testContact.Id;
        insert testCase;

        SendPaymentLinkListAction.InputVariable input = new SendPaymentLinkListAction.InputVariable();
        input.caseId = testCase.Id;

        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{input};
        List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].isError);
        System.assertEquals('Phone number is missing on contact', result[0].errorMessage);
    }

    @isTest
    static void splla_testSendPaymentLink_success() {
        // Creating a test contact
        Contact testContact = new Contact();
        testContact.LastName = 'Test';
        testContact.FirstName = 'SendPaymentAction';
        testContact.Email = 'test@example.com';
        testContact.MobilePhone = '1234567890';
        insert testContact;

        // Creating a test case
        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.ContactId = testContact.Id;
        insert testCase;

        //the input variable
        SendPaymentLinkListAction.InputVariable input = new SendPaymentLinkListAction.InputVariable();
        input.caseId = testCase.Id;
        input.amount = 100;

        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<SendPaymentLinkListAction.InputVariable> inputList = new List<SendPaymentLinkListAction.InputVariable>{input};
        List<SendPaymentLinkListAction.OutputVariable> result = SendPaymentLinkListAction.sendPaymentLink(inputList);

        // Validate the results
        System.assertEquals(1, result.size());
        //System.assertEquals(false, result[0].isError);
        //System.assertNotEquals('', result[0].razorePaymentId);
        //System.assertNotEquals('', result[0].razorePaymentUrl);
        //System.assertEquals('created', result[0].razorePaymentStatus);
    }

    // Mock HTTP Response Class
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Creating the HTTP response
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Check the endpoint to determine the correct mock response
            if (req.getEndpoint().contains('payment_links')) {
                String responseBody = '{"id": "pay_123456789", "short_url": "https://rzp.io/i/test", "status": "created"}';
                res.setBody(responseBody);
            } else {
                res.setStatusCode(400);
                res.setBody('{"error": "Invalid Request"}');
            }

            return res;
        }
    }*/
}