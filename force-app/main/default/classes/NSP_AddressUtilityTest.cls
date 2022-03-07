/*
*Test class for NSP_AddressUtility
*@Utpal Utkalit
*/


@isTest(SeeAllData=false)
public class NSP_AddressUtilityTest {

    static TestMethod void testMultipleBPDataControllerPostive(){
        Test.startTest();
       
        map<string, list<string>> countryStateMap = new map<string, list<string>>();
        NSP_AddressUtility.NPS_TPicklistEntry plist= new NSP_AddressUtility.NPS_TPicklistEntry();
        plist.defaultValue='Default';
        plist.active='True';
        plist.label='Default';
        plist.value='Default';
        countryStateMap = NSP_AddressUtility.getAuraDependentOptions('contact','MailingCountryCode','MailingStateCode');
        system.assert(countryStateMap.size() != 0);
        Test.stopTest();
    }

}