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

        contactList.add(New Contact(FirstName = 'FName', LastName = 'LName', AccountId = acc.Id));

        // Start Test
        Test.startTest();
        if(contactList.size() > 0) {
            insert contactList;
        }
        
        Contact conObj = new Contact();
        conObj.Id  = contactList[5].Id;
        conObj.LastName = 'testupdated';
        update conObj;
        
        Test.stopTest();
        System.assertEquals(conObj.LastName,'testupdated');
    }
}