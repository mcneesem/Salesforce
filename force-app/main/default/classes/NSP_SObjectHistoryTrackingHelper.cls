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
***************************************************************************************************
*/
public class NSP_SObjectHistoryTrackingHelper implements Queueable{
    
    private Map<Id, sObject> newMapSObject;
    private Map<Id, sObject> oldMapSObject;
    public static final String CLIENTSEGMENTTYPE = 'Client Segment type';
    public static final String CLIENTSEGMENTDATE = 'NSP_Client_SegmentDate__c';
    
    public NSP_SObjectHistoryTrackingHelper(Map<Id, sObject> newMapSObject,Map<Id, sObject> oldMapSObject) {
        this.newMapSObject = newMapSObject;
        this.oldMapSObject = oldMapSObject;
    }
	
     /*
     * Here we insert the Customer Interaction big object records,
     * or log an error if insertion fails.
     */
    public void execute(QueueableContext context){
        //calling function to log history data.
        fieldHistoryLogData(newMapSObject,oldMapSObject);
    }
    
    public static void fieldHistoryLogData(Map<Id, sObject> newMapSObject, Map<Id, sObject> oldMapSObject) {
      
        String objectType = String.valueOf(newMapSObject.getsobjecttype());

        // get a list of the fields that need to be updated 
        List<NSP_SObject_Field_History__mdt> objFields = [SELECT NSP_Field_API_Name__c 
                FROM NSP_SObject_Field_History__mdt WHERE NSP_SObject_Name__c = :objectType ];
        List<NSP_SObjects_History_Tracking__b> trackList = new List<NSP_SObjects_History_Tracking__b>();
        if (objFields.size() > 0){
            // get labels for fields
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType objSchema = schemaMap.get(objectType);
            Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();

            // loop through new records, finding fields that changed
            for(Id  sobjkey : newMapSObject.keySet()) {
                sObject newRec = newMapSObject.get(sobjkey);
                sObject oldRec = oldMapSObject.get(sobjkey);
                
                for(NSP_SObject_Field_History__mdt ofh : objFields) {
                    if(newRec.get(ofh.NSP_Field_API_Name__c) != oldRec.get(ofh.NSP_Field_API_Name__c)) {
                        NSP_SObjects_History_Tracking__b oht = new NSP_SObjects_History_Tracking__b();
                       
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
                         if(oht.NSP_Field_Name__c == String.valueOf(CLIENTSEGMENTTYPE)){
                        	oht.NSP_Effective_Date__c = (Datetime) newRec.get(CLIENTSEGMENTDATE);
                        }
                        trackList.add(oht);
                    }
                }
            }
            try{
                // insert history tracking records
                if(!trackList.isEmpty() && !Test.isRunningTest()){
                    database.insertImmediate(trackList);
                }
                //catch block
            }catch(Exception ex){
                NSP_CustomException.LogException(ex);
            }  
        }
    }
}