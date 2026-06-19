// intentionally `without sharing` to ensure that Find_Related_Contact_Screen_Flow has access to all Contact records...
public without sharing class FindContactVoiceFlow {
    // test w/ FindContactVoiceFlowTest (88%)

    @InvocableMethod(label='Get Contacts by Phone')
    public static List<List<Contact>> getContactsByPhone( List<String> phoneNumbers ) {
        List<List<Contact>> result = new List<List<Contact>>();
        try {
            if ( ( phoneNumbers != null )
                && !phoneNumbers.isEmpty()
                && String.isNotBlank( phoneNumbers[0] )
                )
            {
                String input = FindContactVoiceFlow.filterInput( phoneNumbers[0].trim() );
                if ( String.isNotBlank( input )
                    && ( input.length() > 1 )
                    )
                {
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
                                Workday_Employee_ID__c ,
                                NSP_Work_Phone__c ,
                                Contact_Center_Email__c
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
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                FindContactVoiceFlow.class.getName() ,
                'getContactsByPhone' ,
                e
            );
        }
        return result;
    }

    // helper method to defeat sonar cognitive complexity...
    private static String filterInput( String value ) {
        if ( String.isNotBlank( value )
            && ( FindContactVoiceFlow.countryCodes != null )
            && !FindContactVoiceFlow.countryCodes.isEmpty()
            )
        {
            for ( String countryCode : FindContactVoiceFlow.countryCodes ) {
                if ( value.startsWith( countryCode ) ) {
                    value = value.removeStart( countryCode );
                    break;
                }
            }
        }
        return value;
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

    private static List<String> countryCodes  {
        private get {
            if ( countryCodes == null ) {
                List<String> local = new List<String>();
                if ( FindContactVoiceFlow.settings != null ) {
                    String rawCountryCodes = FindContactVoiceFlow.settings.CountryCodes__c;
                    if ( String.isNotBlank( rawCountryCodes ) ) {
                        List<String> splitCountryCodes = rawCountryCodes.split( ',' );
                        if ( ( splitCountryCodes != null ) && ( splitCountryCodes.size() > 0 ) ) {
                            local = splitCountryCodes;
                        }
                    }
                }
                countryCodes = local;
            }
            return countryCodes;
        }
        private set;
    }

}
//