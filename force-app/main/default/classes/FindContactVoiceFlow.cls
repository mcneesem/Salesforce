public class FindContactVoiceFlow {
    // test w/ FindContactVoiceFlowTest (94%)

    @InvocableMethod(label='Get Contacts by Phone')
    public static List<List<Contact>> getContactsByPhone( List<String> phoneNumbers ) {
        List<List<Contact>> result = new List<List<Contact>>();
        if ( ( phoneNumbers != null ) && !phoneNumbers.isEmpty() ) {
            String searchString = '' + phoneNumbers[0] + '';
            Date limitDate = System.today().addDays( -1 * FindContactVoiceFlow.limitCreatedDate );
            List<List<Contact>> searchResults = [
                FIND :searchString IN PHONE FIELDS
                RETURNING Contact(
                    Id , Name , Email , HomePhone , NSP_Work_Phone__c , MobilePhone
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