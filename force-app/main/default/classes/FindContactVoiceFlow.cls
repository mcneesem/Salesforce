public class without sharing FindContactVoiceFlow {
    // test w/ FindContactVoiceFlowTest (95%)

    @InvocableMethod(label='Get Contacts by Phone')
    public static List<List<Contact>> getContactsByPhone( List<String> phoneNumbers ) {
        List<List<Contact>> result = new List<List<Contact>>();
        if ( ( phoneNumbers != null )
            && !phoneNumbers.isEmpty()
            && String.isNotBlank( phoneNumbers[0] )
            )
        {
            String input = String.valueOf( phoneNumbers[0] ).trim();
            if ( input.length() > 1 ) {
                Date limitDate = System.today().addDays( -1 * FindContactVoiceFlow.limitCreatedDate );
                List<List<Contact>> searchResults = [
                    FIND :input
                    IN PHONE FIELDS
                    RETURNING Contact(
                            Id ,
                            Name ,
                            Email ,
                            HomePhone ,
                            OtherAddress ,
                            MobilePhone ,
                            NSP_Date_of_Birth__c ,
                            NSP_Last_4Digit_Of_SSN__c ,
                            NSP_Per_ID__c ,
                            NSP_Work_Phone__c
                        WHERE ( CreatedDate >= :(limitDate) )
                        LIMIT :FindContactVoiceFlow.limitSearch
                    )
                ];
                List<Contact> records = new List<Contact>();
                for ( List<Contact> resultList : searchResults ) {
                    records.addAll( resultList );
                }
                result.add( records );
            }
        }
        return result;
    }

    //
    // attributes controlled by Custom Settings...
    //

    private static Find_Related_Contact_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Find_Related_Contact_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Integer limitSearch {
        private get {
            if ( limitSearch == null ) {
                Integer local = 0;
                if ( ( FindContactVoiceFlow.settings != null )
                    && ( FindContactVoiceFlow.settings.LimitSearch__c != null )
                    )
                {
                    local = FindContactVoiceFlow.settings.LimitSearch__c.intValue();
                }
                // must non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                limitSearch = local;
            }
            return limitSearch;
        }
        private set;
    }

    private static Integer limitCreatedDate {
        private get {
            if ( limitCreatedDate == null ) {
                Integer local = 0;
                if ( ( FindContactVoiceFlow.settings != null )
                    && ( FindContactVoiceFlow.settings.LimitCreatedDateSearch__c != null )
                    )
                {
                    local = FindContactVoiceFlow.settings.LimitCreatedDateSearch__c.intValue();
                }
                // must non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                limitCreatedDate = local;
            }
            return limitCreatedDate;
        }
        private set;
    }

}
//