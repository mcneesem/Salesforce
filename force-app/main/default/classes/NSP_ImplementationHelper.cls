/**
* @description  :  Helper class for Implementation profile.
* @date 09/13/2022
* Author : Bindushree R
* Name : NSP_ImplementationHelper
*/
public class NSP_ImplementationHelper {
    // test w/ NSP_ImplementationHelperTest (??%)

    // URL Params for Copy Action
    private static final String SOURCE_PARAM = 'source';
    private static final String REC_TYPE_PARAM = 'recType';
    private static final String SUCCESS_PARAM = 'success';
    private static final String FAIL_PARAM = 'fail';
    private static final String CLASS_NAME = 'NSP_ImplementationHelper';

    /***********************************************************************************************
    * MethodName: prepopulateIPData
    * Description : prepopulate IP fields based on opportunities related checklist
    * Params:       String  accountId
    * ********************************************************************************************/ 
    @AuraEnabled
    public static Implementation_Profile__c prepopulateIPData(String accountId){
        try{
            Implementation_Profile__c ip=new Implementation_Profile__c();
        prepopulateIPData(accountId,ip);
        return ip;
        } catch(Exception exc){
            throw new AuraHandledException(exc.getMessage());
        }
    }
    
    public static Implementation_Profile__c prepopulateIPData(String accountId, Implementation_Profile__c ip){
        try{

			
                
        	List<Opportunity> oppList=[SELECT Id FROM Opportunity WHERE AccountId=:accountId AND StageName=:NSP_ServiceConstants.CLOSED_WON AND
                             Type=:NSP_ServiceConstants.NEWPRODUCT AND NSP_PrimaryProduct__c=:NSP_ServiceConstants.WO_ASSET_RECORDTYPE
                                                        ORDER BY CreatedDate LIMIT 1];
            
            if(!oppList.isEmpty() && oppList.size()>0){
                List<NSP_ChecklistIPMapping__mdt> checklistIPMappingMdt = [SELECT NSP_Source_Field__c, NSP_Source_Object__c,NSP_Source_Type__c,
                                    NSP_Target_Field__c,NSP_Target_Object__c FROM NSP_ChecklistIPMapping__mdt WHERE NSP_Source_Field__c != NULL];
                
                Map<string,List<NSP_ChecklistIPMapping__mdt>> mapOfChecklistIPMappingMdt = new Map<string,List<NSP_ChecklistIPMapping__mdt>>();
                
                for(NSP_ChecklistIPMapping__mdt checklistIPMapping : checklistIPMappingMdt){
                    
                    List<NSP_ChecklistIPMapping__mdt> checklistIPMappingMdtList=new List<NSP_ChecklistIPMapping__mdt>();
                    if(mapOfChecklistIPMappingMdt.containsKey(checklistIPMapping.NSP_Source_Type__c)){
                        checklistIPMappingMdtList=mapOfChecklistIPMappingMdt.get(checklistIPMapping.NSP_Source_Type__c);
                    }
                    
                    checklistIPMappingMdtList.add(checklistIPMapping);
                    mapOfChecklistIPMappingMdt.put(checklistIPMapping.NSP_Source_Type__c,checklistIPMappingMdtList);
                }
                
                for(string recordTypeName : mapOfChecklistIPMappingMdt.keySet()){
            		string checkListQuery=constructChecklistQuery(mapOfChecklistIPMappingMdt.get(recordTypeName),oppList[0].Id,recordTypeName);
                    
                    List<NSP_Checklist__c> checkListObj = Database.query(checkListQuery);
                    
                    if(checkListObj!=null && checkListObj.size()>0){
                        getChecklistDataIntoIP(mapOfChecklistIPMappingMdt.get(recordTypeName),checkListObj[0],ip);
                    }                    
                }               
                
            }
            return ip;
            
        } catch(Exception excep){
            throw new AuraHandledException(excep.getMessage());
        }
        
    }
    
    /***********************************************************************************************
    * MethodName: constructChecklistQuery
    * Description : prepare dynamic query for checklist object
    * Params:       List<NSP_ChecklistIPMapping__mdt> checklistIPMappingList, Id oppId,string recordTypeName
    * ********************************************************************************************/ 
	
    public static String constructChecklistQuery(List<NSP_ChecklistIPMapping__mdt> checklistIPMappingList,  Id oppId,string recordTypeName){
        
        Set<String> fieldsToQuerySet = new Set<String>();
        for(NSP_ChecklistIPMapping__mdt checklistIPMapping : checklistIPMappingList){
            if(String.isNotBlank(checklistIPMapping.NSP_Source_Field__c)){
                fieldsToQuerySet.add(checklistIPMapping.NSP_Source_Field__c);    
            }
        }
        
        String objectToQuery = '';
        for(NSP_ChecklistIPMapping__mdt checklistIPMapping: checklistIPMappingList){
            if(checklistIPMapping.NSP_Source_Object__c != null){
                objectToQuery = checklistIPMapping.NSP_Source_Object__c;
                break;
            }
        }
        
        Map<String, String> filterMap = new Map<String,String>{ 'NSP_Opportunity__c' => oppId,'RecordType.Name'=>recordTypeName};
            String query = getQuery(new List<String>(fieldsToQuerySet),objectToQuery,filterMap,null);
        return query;
        
    } 
    
    
    
    public static String getQuery(List<String> fieldsToQueryList, String objectToQuery, Map<String, String> filterMap, Integer range){
        //query construction
        String fieldsToQuery = String.join(fieldsToQueryList, ',');
        String query = 'SELECT '+fieldsToQuery+' FROM '+ objectToQuery;
        String filter = '';
        Integer filterCount=1;
        if(!filterMap.isEmpty()){
            for(String key : filterMap.keySet()){
                if(filterCount>1){
                    filter+=' AND ';
                }
                filter += String.escapeSingleQuotes(key) + '= \'' + String.escapeSingleQuotes(filterMap.get(key)) + '\' ';
                filterCount++;
            }
        }
        if(String.isNotBlank(filter)){
            query += ' WHERE ' + filter;
        }
        if(range != null){
            query += ' LIMIT ' + range;
        }
        return query;
    } 
    
    /***********************************************************************************************
    * MethodName: getChecklistDataIntoIP
    * Description : get checklist data into IP
    * Params:       List<NSP_ChecklistIPMapping__mdt> checklistIPMappingList, NSP_Checklist__c checkList,Implementation_Profile__c ip
    * ********************************************************************************************/ 
    
     public static void getChecklistDataIntoIP(List<NSP_ChecklistIPMapping__mdt> checklistIPMappingList,NSP_Checklist__c checkList,Implementation_Profile__c ip){     
                 
        //looping through metadata reocrds to fetch the field api names
        for(NSP_ChecklistIPMapping__mdt checklistIPMapping : checklistIPMappingList){
            if(String.isNotBlank(checklistIPMapping.NSP_Target_Field__c) && String.isNotBlank(checklistIPMapping.NSP_Source_Field__c)){
                
                Object value=	checkList.get(checklistIPMapping.NSP_Source_Field__c);
                ip.put(checklistIPMapping.NSP_Target_Field__c, applyValueConversionPolicy(checklistIPMapping.NSP_Source_Field__c,value)); 
                
            }
        }
    }
    
    private static object applyValueConversionPolicy(string sourceFieldName,object value){
        switch on sourceFieldName{
            when 'NSP_Does_company_have_more_than_one_FEIN__c'{
            	return boolean.valueOf(value) ? 'No':null;
            }
            
            when 'NSP_Commission_only_employees__c'{
            	return boolean.valueOf(value) ?'Yes':null;
            }
            when 'NSP_ClientRelatedtootherInsperityClient__c'{
            	return value=='Yes'?'Related Clients ':null;
            }
            when 'NSP_Version_Number__c'{
            	return value!=null?string.valueOf(value):null;
            }
            when 'NSP_DBA_AKA_T_A_Name__c'{
                return getDBAName(value);
            }
            when 'NSP_Benefits_Waiting_Period__c'{
                if(value==null){
                	return value;
                }
                return string.valueOf(value).toLowerCase();
                
            }
            when 'NSP_Client_FEIN__c'{
                
                if(value==null){
                	return value;
                }
                String feinString=string.valueOf(value);
                if(feinString.length()==9){
                    return feinString.substring(0, 2)+'-'+feinString.substring(2);
                }
                return feinString;
            }

            when 'NSP_Pay_Frequency__c'{
                return value == 'Biweekly' ? 'Bi-Weekly' : value;  
            }
            
            when else {
            	return value;
            }
        }
    }
    
     /***********************************************************************************************
    * MethodName: getDBAName
    * Description : get user name based on the user selected
    * Params:        userId
    * ********************************************************************************************/ 
    
    private static String getDBAName(Object userId){
       if(userId!=null){
           Id id=(Id)userId;
       		User userRec=[SELECT Name from User WHERE Id=:id]; 
           return userRec.Name;
       }
       return null;
        
    }

    /**
     * Copies data from one IP record to multiple records & send status email on process completion.
     * @param recordIds List of Id of the target IP records to which data will be written.
     * @param fieldValues String representation of IP object field and values
     * @param sourceId Id of the source IP record
     * @param recType Record Type of source IP record
     * @param userEmail Email Id of user to which we need to send status email
     * @return void
     */
	@future(callout=true)
    public static void copyIpRecordData(List<String> recordIds, String fieldValues, String sourceId, String recType, String userEmail){
        try {
            // Copy Data to target IP records
            Map<String, List<String>> ipRecordsMap = updateCopyTargetIPRecords(recordIds, fieldValues);

            // Send a status mail on finish of copy action
            if(String.isNotBlank(userEmail)){
                sendCopyActionStatusEmail(sourceId, recType, userEmail, ipRecordsMap);
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(CLASS_NAME, 'copyIpRecordData', ex.getMessage());
        }
    }

    private static Map<String, List<String>> updateCopyTargetIPRecords(List<String> recordIds, String fieldValues){
        List<Implementation_Profile__c> recToUpdate = new List<Implementation_Profile__c>();

        for(String recId : recordIds){
            Implementation_Profile__c ipObj = (Implementation_Profile__c) JSON.deserialize(fieldValues, Implementation_Profile__c.class);
            ipObj.Id = recId;
            
            recToUpdate.add(ipObj);
        }

        List<Database.SaveResult> result = Database.update(recToUpdate, false);
        List<String> successRecords = new List<String>();
        List<String> failedRecords = new List<String>();

        for(Database.SaveResult res : result){
            if (res.isSuccess()) {
                successRecords.add(res.getId());
            } else {
                failedRecords.add(res.getId());
            }
        }

        Map<String, List<String>> updatedIpRecordsMap = new Map<String, List<String>>{
            SUCCESS_PARAM => successRecords, FAIL_PARAM => failedRecords
        };

        return updatedIpRecordsMap;
    }

    private static String getCopyActionStatusEmailBody(String accName, String recType, List<String> successRecords, List<String> failedRecords){
        PageReference page = Page.NSP_CopyActionStatusEmailBody;
        Map<String, String> params = page.getParameters();
        params.put(SOURCE_PARAM, accName);
        params.put(REC_TYPE_PARAM, recType);

        if(!successRecords.isEmpty()){
	        params.put(SUCCESS_PARAM, JSON.serialize(successRecords));
        }

        if(!failedRecords.isEmpty()){
	        params.put(FAIL_PARAM, JSON.serialize(failedRecords));
        }

        return page.getContent().toString().substringBetween('<body>','</body>');
    }

    private static String getCopyActionStatusEmailSubject(String accName){
        String emailSubject = 'Implementation Profile Copy Results';

		return String.isBlank(accName) ? emailSubject : emailSubject + ' for ' + accName;
    }

    private static void sendEmail(String[] toAddresses, String subject, String body){
        // First, reserve email capacity for the current Apex transaction
        Messaging.reserveSingleEmailCapacity(1);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Assign the addresses for the To list to the mail object.
        mail.setToAddresses(toAddresses);

        // Specify the subject line for your email address.
        mail.setSubject(subject);

        // Specify the content of the email.
        mail.setHtmlBody(body);

        // Send the email you have created.
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    private static void sendCopyActionStatusEmail(String sourceId, String recType, String userEmail, Map<String, List<String>> ipRecordsMap){
        String sourceName = String.isNotBlank(sourceId) ? NSP_IPSelector.getRecordById(sourceId, null).Account__r.Name : null;

        List<String> successRecords = ipRecordsMap.get(SUCCESS_PARAM);
        List<String> failedRecords = ipRecordsMap.get(FAIL_PARAM);

        String emailBody = getCopyActionStatusEmailBody(sourceName, recType, successRecords, failedRecords);
        
        // Strings to hold the email addresses to which you are sending the email.
		String[] toAddresses = new String[] { userEmail };

        sendEmail(toAddresses, getCopyActionStatusEmailSubject(sourceName), emailBody);
    }
}