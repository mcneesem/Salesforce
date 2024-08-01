public class FindContactVoiceFlow{
    @InvocableMethod(label = 'Get Contacts by Phone')
    public static List<List<Contact>> getContactsByPhone(List<String> phoneNumbers){
        List<List<Contact>> result = new List<List<Contact>>();
        if (phoneNumbers != null && !phoneNumbers.isEmpty()){
            String phoneNumber = phoneNumbers[0];
            String searchString = '' + phoneNumber + '';
            Find_Related_Contact_Settings__c settings = Find_Related_Contact_Settings__c.getInstance(UserInfo.getProfileId());
            Integer createdDateLimitDays = settings.LimitCreatedDate__c != null ?(settings.LimitCreatedDate__c>=0?(Integer)settings.LimitCreatedDate__c :1): 1; 
            Integer queryLimitCount = settings.LimitQuery__c != null ?(settings.LimitQuery__c>=0?(Integer)settings.LimitQuery__c :1): 1; 
            Date limitDate = System.today().addDays(-createdDateLimitDays);
            List<List<Contact>> searchResults = [FIND : searchString IN PHONE FIELDS RETURNING Contact(Id, Name, Email, HomePhone, NSP_Work_Phone__c, MobilePhone WHERE CreatedDate >= :(limitDate) LIMIT:QueryLimitCount)];
            List<Contact> contacts = new List<Contact>();
            for (List<Contact> resultList : searchResults){
                contacts.addAll(resultList);
            }
            result.add(contacts);
        }
        return result;
    }
}