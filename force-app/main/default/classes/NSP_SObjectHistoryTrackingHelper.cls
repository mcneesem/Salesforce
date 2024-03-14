/* **************************************************************************************************   
Component Name :  NSP_SObjectHistoryTrackingHelper class
Version              :  1.0                                                                          
Created Date         :  November, 2021                                                             
Function             :  Imported from generic utility
					 : Used in custom history tracking  	
Story                :                                                                             
Modification Log     :                                                                               
*	Hemali           November 10, 2021          First IterationH
*   Harsha Khiroya   March 3, 2022              DF-01347
*   Anil             March 31, 2023             DF-03332

***************************************************************************************************
*/
public class NSP_SObjectHistoryTrackingHelper implements Queueable {
    // test w/ NSP_SObjectHistoryTrackingHelperTest (88%)

    // unified entry point...
    public static void enqueueJob( Map<Id,sObject> newRecords , Map<Id,sObject> oldRecords ) {
        if ( Limits.getQueueableJobs() != Limits.getLimitQueueableJobs() ) {
            System.enqueueJob(
                new NSP_SObjectHistoryTrackingHelper(
                    newRecords ,
                    oldRecords
                )
            );
        }
    }

    //
    //
    //

    private Map<Id, sObject> newMapSObject;
    private Map<Id, sObject> oldMapSObject;
    private Map<Id, Decimal> recIdHistoryCountMap = new Map<Id, Decimal>();
    private List<NSP_SObject_Field_History__mdt> objFields = new List<NSP_SObject_Field_History__mdt>();

    public NSP_SObjectHistoryTrackingHelper(Map<Id, sObject> newMapSObject,Map<Id, sObject> oldMapSObject) {
        this.newMapSObject = newMapSObject;
        this.oldMapSObject = oldMapSObject;
    }
	
     /*
     * Here we insert the Customer Interaction big object records,
     * or log an error if insertion fails.
     */
    public void execute(QueueableContext context){
        // 2024-03-13 ~ PMCC ~ top offender ~ throws... System.LimitException: Apex CPU time limit exceeded
        //calling function to log history data.
        if(recIdHistoryCountMap.isEmpty() && newMapSObject instanceof Map<Id,Implementation_Profile__c>){
            getPreviousIPHistoryRecordCount();
        }
        objFields.addAll(getMetaDataFields());
        if (objFields!=null && objFields.size() > 0){
            fieldHistoryLogData(newMapSObject,oldMapSObject);
        }
    }
    
    private void fieldHistoryLogData(Map<Id, sObject> newMapSObject, Map<Id, sObject> oldMapSObject) {
      
        final List<sObject> trackList = new List<sObject>();
        
        // loop through new records, finding fields that changed
        for(Id  sobjkey : newMapSObject.keySet()) {
            sObject newRec = newMapSObject.get(sobjkey);
            sObject oldRec = oldMapSObject.get(newRec.Id);
            
            Integer count = 1;
            for(NSP_SObject_Field_History__mdt ofh : objFields) {
                if(newRec.getSObjectType().getDescribe().fields.getMap().containsKey(ofh.NSP_Field_API_Name__c.toLowerCase())
                   && newRec.get(ofh.NSP_Field_API_Name__c) != oldRec.get(ofh.NSP_Field_API_Name__c)) {
                       
                       if(newRec instanceof Implementation_Profile__c){
                           trackList.add(newIPHistoryTrackingRec(newRec, ofh, count));
                           count++;
                       } else {
                           trackList.add(newHistoryTrackingRec(newRec, ofh));
                       }
                       
                   }
            }
        }
        
        try{
            // insert history tracking records
            if(!trackList.isEmpty() && !Test.isRunningTest()){
                database.insertImmediate(trackList);
            }
            //catch block
        } catch(Exception ex) {
            NSP_CustomException.LogException(ex);
        }  
    }
    
    /***********************************************************************************************
    * MethodName: newHistoryTrackingRec
    * Description : prepare bigobject history record
    * ********************************************************************************************/
    private  NSP_SObjects_History_Tracking__b newHistoryTrackingRec(sObject newRec, NSP_SObject_Field_History__mdt ofh){
        final NSP_SObjects_History_Tracking__b oht = new NSP_SObjects_History_Tracking__b();
        sObject oldRec = oldMapSObject.get(newRec.Id);

        // set rest of fields
        oht.NSP_Field_Name__c = fieldMap.get(ofh.NSP_Field_API_Name__c).getDescribe().getLabel();
        oht.NSP_Sobject_Record_Id__c  = (String)newRec.get('Id');
        // set old and new values
        oht.NSP_Old_Value__c = String.valueOf(oldRec.get(ofh.NSP_Field_API_Name__c));
        oht.NSP_New_Value__c = String.valueOf(newRec.get(ofh.NSP_Field_API_Name__c));
        // for now - get the userid and modify date out of the new record
        oht.NSP_Modified_By__c	 = (Id) newRec.get('LastModifiedById');
        oht.NSP_Modified_Date__c = (Datetime) newRec.get('LastModifiedDate');
        //poulate Effective date if NSP_Client_Segment_type__c is changed on asset
        if ( oht.NSP_Field_Name__c == String.valueOf( 'Client Segment type' ) ) {
            oht.NSP_Effective_Date__c = (Datetime)newRec.get( 'NSP_Client_SegmentDate__c' );
        }
        return oht;
    }
    
    /***********************************************************************************************
    * MethodName: newIPHistoryTrackingRec
    * Description : prepare bigobject IP history record
    * ********************************************************************************************/
    private  NSP_IP_History_Tracking__b newIPHistoryTrackingRec(sObject newRec, NSP_SObject_Field_History__mdt ofh, Integer count){
        final NSP_IP_History_Tracking__b oht = new NSP_IP_History_Tracking__b();
        sObject oldRec = oldMapSObject.get(newRec.Id);
        // set rest of fields
        oht.NSP_Field_Label__c = fieldMap.get(ofh.NSP_Field_API_Name__c).getDescribe().getLabel();
        oht.NSP_Field_Name__c = fieldMap.get(ofh.NSP_Field_API_Name__c).getDescribe().getName();
        oht.NSP_Sobject_Record_Id__c  = (String)newRec.get('Id');
        // set old and new values
        oht.NSP_Old_Value__c = String.valueOf(oldRec.get(ofh.NSP_Field_API_Name__c));
        oht.NSP_New_Value__c = String.valueOf(newRec.get(ofh.NSP_Field_API_Name__c));
        // for now - get the userid and modify date out of the new record
        oht.NSP_Modified_By__c	 = (Id) newRec.get('LastModifiedById');
        oht.NSP_Modified_Date__c = (Datetime) newRec.get('LastModifiedDate');
        //this is set for pagination
        if(recIdHistoryCountMap.containsKey((String)newRec.get('Id'))){
            oht.NSP_Index__c = recIdHistoryCountMap.get((String)newRec.get('Id'));
            recIdHistoryCountMap.put((String)newRec.get('Id'), recIdHistoryCountMap.get((String)newRec.get('Id')) + 1);
        } else {
            oht.NSP_Index__c = count;
        }
        return oht;
    }

    private String objectType {
        get { 
            return String.valueOf(newMapSObject.getsobjecttype());
        }
    }
    
    private Map<String, Schema.SObjectField> fieldMap {
        get { 
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType objSchema = schemaMap?.get(objectType);
            Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe()?.fields?.getMap();
            return fieldMap;
        }
    }
    
    /***********************************************************************************************
    * MethodName: getMetaDataFields
    * Description : get a list of the fields that need to be updated 
    * ********************************************************************************************/
    private List<NSP_SObject_Field_History__mdt> getMetaDataFields() {
        return [SELECT NSP_Field_API_Name__c , NSP_Field_Label__c FROM NSP_SObject_Field_History__mdt WHERE NSP_SObject_Name__c = :objectType ];
    }

    /***********************************************************************************************
    * MethodName: getPreviousIPHistoryRecordCount
    * Description : Get previous IP bigObject count
    * ********************************************************************************************/
    private void getPreviousIPHistoryRecordCount(){
        for(NSP_IP_History_Tracking__b obj: [SELECT NSP_Index__c, NSP_Sobject_Record_Id__c FROM NSP_IP_History_Tracking__b WHERE NSP_Sobject_Record_Id__c IN: newMapSObject.keySet() ]){
            if(!recIdHistoryCountMap.containsKey(obj.NSP_Sobject_Record_Id__c)){
                recIdHistoryCountMap.put(obj.NSP_Sobject_Record_Id__c, obj.NSP_Index__c >= 1 ? obj.NSP_Index__c + 1: 1 );
            }
        }
    }
    
}