public with sharing class RecordTypeSelectorController {
    // test w/ RecordTypeSelectorControllerTest (100%)

    @AuraEnabled(cacheable=true)
    public static List<RecordType> getAccessibleRecordTypes( String objectApiName ) {
        List<RecordType> response = new List<RecordType>();
        Map<String,Schema.RecordTypeInfo> recordTypeMap = NSP_GenericRecordType.getRecordTypeMap( objectApiName );
        if ( recordTypeMap != null ) {
            for ( Schema.RecordTypeInfo info : recordTypeMap.values() ) {
                if ( ( info != null )
                    && info.isAvailable()
                    && info.isActive()
                    && !info.isMaster()
                   )
                {
                    response.add(
                        new RecordType(
                            Id=info.getRecordTypeId() ,
                            Name=info.getName() ,
                            DeveloperName=info.getDeveloperName()
                        )
                    );
                }
            }
        }
        return response;
    }

}
//