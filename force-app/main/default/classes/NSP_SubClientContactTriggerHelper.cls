public with sharing class NSP_SubClientContactTriggerHelper {
    // test w/ NSP_SubClientContactTriggerHelperTest (81%)

    public void deleteAddressRecordsBasedOnStatus( List<NSP_Sub_Client_Contact__c> newSubClientCon , Map<Id,NSP_Sub_Client_Contact__c> oldSubClientConMap ) {
        if ( NSP_SubClientContactTriggerHelper.isEnabledDeleteAddresses ) { // kill switch added by AZD-237218
            Map<Id,NSP_Sub_Client_Contact__c> subClientConByContact = new Map<Id,NSP_Sub_Client_Contact__c> ();
            List<string> clientId_PERIDs = new List<string>();
            for (NSP_Sub_Client_Contact__c subClientCon : newSubClientCon) {
                if ( subClientCon.NSP_Contact__c != null ) {
                    Boolean isRequiredToDeleteAddresses = False;
                    if ( ( oldSubClientConMap == null )
                        && String.isNotBlank( subClientCon.NSP_Employee_Status__c )
                        && ( subClientCon.NSP_Employee_Status__c != 'PRIMED' )
                        )
                    {
                        // inserting an NSP_Sub_Client_Contact__c that IS NOT 'PRIMED'...
                        isRequiredToDeleteAddresses = True;
                    } else if ( ( oldSubClientConMap != null )
                        && ( oldSubClientConMap.get(subClientCon.Id).NSP_Employee_Status__c == 'PRIMED' )
                        )
                    {
                        // updating an NSP_Sub_Client_Contact__c that WAS OR STILL IS 'PRIMED'...
                        isRequiredToDeleteAddresses = True;
                    }
                    if ( isRequiredToDeleteAddresses ) {
                        subClientConByContact.put(subClientCon.NSP_Contact__c,subClientCon);
                    }
                }
            }
            if(!subClientConByContact.isEmpty()){
                Map<Id, Contact> contactMap = new  Map<Id, Contact>([SELECT Id, NSP_PER_ID__c FROM Contact WHERE Id =:subClientConByContact.keyset()]);
                string clientId_PERIDWithComma1 = '';
                for(NSP_Sub_Client_Contact__c subClientCon : newSubClientCon) {
                    if(contactMap.containskey(subClientCon.NSP_Contact__c)){
                        if( subClientCon.NSP_AIMS_Sub_Client__c != null ){
                            clientId_PERIDWithComma1 += subClientCon.NSP_AIMS_Sub_Client__c+'-';
                        }
                        if(contactMap.get(subClientCon.NSP_Contact__c).NSP_PER_ID__c != null ){
                            clientId_PERIDWithComma1 += contactMap.get(subClientCon.NSP_Contact__c).NSP_PER_ID__c;
                        }
                        clientId_PERIDs.add(clientId_PERIDWithComma1+'PH1');
                        clientId_PERIDs.add(clientId_PERIDWithComma1 +'PW1');
                        clientId_PERIDs.add(clientId_PERIDWithComma1 +'PH1PW1');
                    }
                }
                if(!clientId_PERIDs.isEmpty()){
                    initiateAddressDelete(clientId_PERIDs);
                }
            }
        }
    }

    // kill switch added by AZD-237218
    public static Boolean isEnabledDeleteAddresses {
        public get {
            if ( isEnabledDeleteAddresses == null ) {
                isEnabledDeleteAddresses = SubClientContactTriggerSettings__c.getInstance( UserInfo.getUserId() ).IsEnabledDeleteAddresses__c;
            }
            return isEnabledDeleteAddresses;
        }
        private set;
    }

    // DEPRECATED BY AZD-237218
    @future public static void initiateAddressDelete( List<string> clientId_PERIDs ) {
        if ( NSP_SubClientContactTriggerHelper.isEnabledDeleteAddresses ) { // kill switch added by AZD-237218
            List<NSP_Address__c> addressToBeDeleted = [
                SELECT Id, NSP_Label_Code__c
                FROM NSP_Address__c
                WHERE (
                    ( NSP_Label_Code__c != null )
                    AND ( NSP_Label_Code__c =: clientId_PERIDs )
                )
            ];
            if(addressToBeDeleted.size() > 0){
                Database.DeleteResult[] results = Database.delete( addressToBeDeleted , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientContactTriggerHelper.class.getName() ,
                    'initiateAddressDelete' ,
                    results
                );
            }
        }
    }

    public void updatePaperlessBatchDateBeforeInsertOrUpdate( List<NSP_Sub_Client_Contact__c> newList , Map<Id,NSP_Sub_Client_Contact__c> oldMap ) {
        for(NSP_Sub_Client_Contact__c SubClientContactObj : newList){
            if( oldMap == null
                && ((SubClientContactObj.NSP_Employee_Status__c != null ) ||
                (SubClientContactObj.NSP_Paid_Non_Paid__c != null ) ||
                (SubClientContactObj.NSP_IsPaperless__c != False ) )||
                (oldMap != null && oldMap.containskey(SubClientContactObj.Id) &&
                SubClientContactObj.NSP_Employee_Status__c != oldMap.get(SubClientContactObj.Id).NSP_Employee_Status__c)||
                (oldMap != null && oldMap.containskey(SubClientContactObj.Id) &&
                SubClientContactObj.NSP_Paid_Non_Paid__c != oldMap.get(SubClientContactObj.Id).NSP_Paid_Non_Paid__c)||
                (oldMap != null && oldMap.containskey(SubClientContactObj.Id) &&
                SubClientContactObj.NSP_IsPaperless__c != oldMap.get(SubClientContactObj.Id).NSP_IsPaperless__c)
                )
            {
                SubClientContactObj.NSP_Paperless_Batch_Date__c = System.Today();
            }
        }
    }

    //
    // @MethodName: updatePDSContactRelatedFieldsBasedOnSCC
    // @Description: This method is used to update PDS Fields on before Insert
    // @param : Map<Id, NSP_Sub_Client_Contact__c> newMap, Map<Id, NSP_Sub_Client_Contact__c> oldMap
    // @createdDate : 11/16/2022
    // @Defect : STY-03235
    // @return void
    //
    public static void updatePDSContactRelatedFieldsBasedOnSCC( Map<Id,NSP_Sub_Client_Contact__c> newMap , Map<Id, NSP_Sub_Client_Contact__c> oldMap ) {
        try {
            Map<Id , List<NSP_Sub_Client_Contact__c>> subClientConBySubClientIds = new Map<Id , List<NSP_Sub_Client_Contact__c>>();
            Map<Id, String> conIdEmpStatusMap = new Map<Id, String>();
            Map<Id, Date> conIdStatusDate = new Map<Id, Date>();


            // get existing Sub Client Contact
            for(NSP_Sub_Client_Contact__c newSubClientCon : newMap.values()){
                if ( newSubClientCon.NSP_Contact__c != null
                    && newSubClientCon.NSP_Sub_Client__c != null
                    && (
                        ( newSubClientCon.NSP_On_Site_Supervisor__c && oldMap.get(newSubClientCon.Id).NSP_On_Site_Supervisor__c != newSubClientCon.NSP_On_Site_Supervisor__c )
                        || (newSubClientCon.NSP_Payroll_Contact__c && oldMap.get(newSubClientCon.Id).NSP_Payroll_Contact__c != newSubClientCon.NSP_Payroll_Contact__c )
                        || (newSubClientCon.NSP_HR_Contact__c && oldMap.get(newSubClientCon.Id).NSP_HR_Contact__c != newSubClientCon.NSP_HR_Contact__c )
                        || (newSubClientCon.NSP_Background_Contact__c && oldMap.get(newSubClientCon.Id).NSP_Background_Contact__c != newSubClientCon.NSP_Background_Contact__c )
                        )
                    )
                {
                    //Map to store subclient with its related sub client contacts
                    if(subClientConBySubClientIds.Containskey(newSubClientCon.NSP_Sub_Client__c)) {
                        subClientConBySubClientIds.get(newSubClientCon.NSP_Sub_Client__c).add(newSubClientCon);
                    } else {
                        subClientConBySubClientIds.put(newSubClientCon.NSP_Sub_Client__c , new list<NSP_Sub_Client_Contact__c> {newSubClientCon});
                    }
                }
                if(newSubClientCon.NSP_Employee_Status__c != oldMap.get(newSubClientCon.Id).NSP_Employee_Status__c && newSubClientCon.NSP_Is_Primary__c){
                    conIdEmpStatusMap.put(newSubClientCon.NSP_Contact__c, newSubClientCon.NSP_Employee_Status__c);
                    conIdStatusDate.put(newSubClientCon.NSP_Contact__c, newSubClientCon.NSP_Status_Date__c);
                }
            }

            Map<Id,NSP_Payroll__c> pdsToBeUpdatedMap = new Map<Id,NSP_Payroll__c>();
            // Update Payroll field logic based on respective confirmation checkbox
            for(NSP_Payroll__c pds : [
                        SELECT
                            Id , NSP_Sub_Client_Name__c, NSP_On_site_Supervisor__c, NSP_OSS_SCC__c,
                            NSP_Primary_Payroll_Contact__c,NSP_HR_Contact__c, NSP_Payroll_SCC__c,
                            NSP_HR_Contact_SCC__c ,NSP_Back_Up_Payroll_Contact__c, NSP_Backup_Payroll_Contact_SCC__c
                        FROM NSP_Payroll__c
                        WHERE NSP_Sub_Client_Name__c =: subClientConBySubClientIds.keySet()
                    ]
                )
            {
                // get all related subclient contacts from Map
                List<NSP_Sub_Client_Contact__c>  subCliConList = subClientConBySubClientIds.get(pds.NSP_Sub_Client_Name__c) ;
                for(NSP_Sub_Client_Contact__c subClientCon : subCliConList ){
                    if ( !NSP_PayrollTriggerHelper.isEnabledOnsiteSupervisor
                        && subClientCon.NSP_On_Site_Supervisor__c == true
                        )
                    {
                        pds.NSP_On_site_Supervisor__c = subClientCon.NSP_Contact__c;
                        pds.NSP_OSS_SCC__c = subClientCon.Id;
                    }
                    if ( !NSP_PayrollTriggerHelper.isEnabledPrimaryPayrollContact
                        && subClientCon.NSP_Payroll_Contact__c == true
                        )
                    {
                        pds.NSP_Primary_Payroll_Contact__c = subClientCon.NSP_Contact__c;
                        pds.NSP_Payroll_SCC__c = subClientCon.Id;
                    }
                    // if HR Contact doesn't exist
                    if ( !NSP_PayrollTriggerHelper.isEnabledHRContact
                        && subClientCon.NSP_HR_Contact__c == true
                        )
                    {
                        pds.NSP_HR_Contact__c = subClientCon.NSP_Contact__c;
                        pds.NSP_HR_Contact_SCC__c = subClientCon.Id;
                    }
                    // add PDS in list to be updated
                    pdsToBeUpdatedMap.put( pds.Id , pds ); // prevent System.ListException: Duplicate id in list
                }
            }
            // PDS ready to be updated
            if(!pdsToBeUpdatedMap.isEmpty()){
                List<Database.SaveResult> results = Database.update( pdsToBeUpdatedMap.values() , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientContactTriggerHelper.class.getName() ,
                    'updatePDSContactRelatedFieldsBasedOnSCC' ,
                    results
                );
            }
            if(!conIdEmpStatusMap.isEmpty()){
                updateRelatedWizardEmployeeStatus(conIdEmpStatusMap, conIdStatusDate);
            }
        } catch ( Exception e ) {
            NSP_SubClientContactTriggerHelper.handleException( e , 'updatePDSContactRelatedFieldsBasedOnSCC' );
        }
    }

    //
    // MethodName: updateRelatedWizardEmployeeStatus
    // Description : This method describes about the updation of Employee status and Status date on wizard output
    // Params: Map<Id, String> conIdEmpStatusMap, Map<Id, Date> conIdStatusDate
    // Story: STY-02069
    //
    public static void updateRelatedWizardEmployeeStatus( Map<Id, String> conIdEmpStatusMap, Map<Id, Date> conIdStatusDate){
        List<NSP_ReportRequest__c> repReqListToUpdate = new List<NSP_ReportRequest__c>();
        try{
            for(NSP_ReportRequest__c repReq : [SELECT Id, NSP_WSEE__c, NSP_Termination_Date__c
                                            	FROM NSP_ReportRequest__c WHERE NSP_WSEE__c IN: conIdStatusDate.keySet()]){
                                                repReq.NSP_Termination_Date__c = conIdEmpStatusMap.get(repReq.NSP_WSEE__c) == NSP_ServiceConstants.TERMINATED_STATUS ?
                                                    conIdStatusDate.get(repReq.NSP_WSEE__c) : repReq.NSP_Termination_Date__c ;
                                                repReqListToUpdate.add(repReq);
                                            }
            if(!repReqListToUpdate.isEmpty()){
                List<Database.SaveResult> results = Database.update( repReqListToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientContactTriggerHelper.class.getName() ,
                    'updateRelatedWizardEmployeeStatus' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_SubClientContactTriggerHelper.handleException( e , 'updateRelatedWizardEmployeeStatus' );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_SubClientContactTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//