public without sharing class NSP_AddressCtrl {
    // test w/ NSP_AddressCtrlTest (83%)

    public static final string SUCCESS = 'Success';
    public static final string ERROR = 'Error';
    
    @AuraEnabled
    public static NSP_Address__c getAddress( String recId ) {
        NSP_Address__c address = null;
        try {
            List<NSP_Address__c> addresses = [
                SELECT NSP_Address_Type__c , NSP_Country__c , NSP_State__c
                FROM NSP_Address__c
                WHERE ( Id = :recId )
            ];
            if ( !addresses.isEmpty() ) {
                address = addresses[0];
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
        return address;
    }

    @AuraEnabled
    public static ResponseWrapper saveAddress( NSP_Address__c addressRecord ) {
        ResponseWrapper responseWrap = new ResponseWrapper();
        try {
            if (null != addressRecord) {
                upsert addressRecord;
                responseWrap.responseType = NSP_AddressCtrl.SUCCESS;
                responseWrap.responseData.add( addressRecord.Id );
                responseWrap.responseData.add( addressRecord.Name );
            }
        } catch( DMLException dmlExc ) {
            throw new AuraHandledException( dmlExc.getDmlMessage(0) );
        }
        return responseWrap;
    }

    // Wrapper class for response
    public class ResponseWrapper {
        @AuraEnabled
        public String responseType{ get; set; }
        @AuraEnabled
        public List<String> responseData{ get; set; }
        public ResponseWrapper() {
            responseData = new List<String>();
        }
    }

}
//
