public with sharing class NSP_Lib {

    public static String getRoleIdByApiName(String apiName){
        UserRole role = [SELECT Id FROM UserRole WHERE developerName =:apiName];
        if(role != null){
            return role.Id;
        }
        return '';
    }

    public static List<UserRole> getRolesIdByApiName(List<String> apiNames){
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE developerName IN:apiNames];
        return roles;
    }
    
    public static List<String> getPickListValuesByRecordType(String objectName, String recordApiName, String fieldApiName ){
        
        List<String> values = new  List<String>();

        try{

            //  Get the record type id
            String recordTypeId = [SELECT id FROM RecordType WHERE sObjectType =: objectName AND developerName =: recordApiName].id;

            String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v57.0/';
            
            //  Create request
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endPoint + 'ui-api/object-info/' + objectName + '/picklist-values/' + recordTypeId + '/' + fieldApiName);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

            //  Send the request
            Http http = new Http();
            HTTPResponse response = http.send(request);

            if(response.getStatusCode() == 200){
                PickListResponse result = (PickListResponse)JSON.deserialize(response.getBody(), PickListResponse.class);
                for(PickListItem pli : result.values){
                    values.add(pli.value);
                }
            }
            
        }
        catch(Exception e){
            values.add('AN UNEXPECTED ERROR OCCURRED, READ THE LOG FOR DETAILS');
            NSP_CustomException.LogException(e);
        }

        return values;
    }

    private class PickListResponse{
        public PickListItem[] values;
    }
    
    private class PickListItem{
    	public String label;
        public String value;
    }
}