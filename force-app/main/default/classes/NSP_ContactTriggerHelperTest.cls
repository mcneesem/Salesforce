/**
 * Represents test class for Contact trigger helper
 */

@isTest(SeeAllData=FALSE)
public class NSP_ContactTriggerHelperTest {

    /**
     * Checks the Contact After Insert Trigger
     * @param N/A. 
     * @return void                          
     */

    @isTest
    static void testContactInsert() {
        
        Account acc = New Account(Name = 'TestAccount', AccountNumber = '12345');
        insert acc;

        List<Contact>  contactList = New List<Contact>();

        for(integer idx = 0; idx < 5; idx++) {
            contactList.add(New Contact(FirstName = 'FName'+idx, LastName = 'LName'+idx, AccountId = acc.Id));
        }

        contactList.add(New Contact(FirstName = 'FName', LastName = 'LName', AccountId = acc.Id,phone = '8987678652'));
		contactList.add(New Contact(FirstName = 'FName T', LastName = 'LNameT', AccountId = acc.Id,phone = '1987678654',NSP_Client_Reference__c = true,NSP_Reference_Products__c = 'Applicant Tracking',NSP_Reference_Type__c  = 'Client Testimonial'));

        // Start Test
        Test.startTest();
        if(contactList.size() > 0) {
            insert contactList;
        }
        
        Contact conObj = new Contact();
        conObj.Id  = contactList[5].Id;
        conObj.LastName = 'testupdated';
        conObj.phone = '12876786523';
        conObj.NSP_Client_Reference__c = true;
        conObj.NSP_Reference_Products__c = 'Applicant Tracking';
        conObj.NSP_Reference_Type__c  = 'Client Testimonial';
        update conObj;
        
        Contact conObj2 = new Contact();
        conObj2.Id  = contactList[6].Id;
        conObj2.phone = '2287678652 ext 123';
        update conObj2; 
        
        Test.stopTest();
        System.assertEquals(conObj.LastName,'testupdated');
    }
}