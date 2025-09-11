public class NSP_SubClientTriggerHelper {
    // test w/ NSP_SubClientTriggerTest (79%)

    /**
     * Iterates throught the list of new NSP_Sub_Client__c and passes the required attributes to other methods.
     * @param newList List of New NSP_Sub_Client__c.
     * @return void
     *
     */
    public void beforeInsertDirector(List<NSP_Sub_Client__c> newList){
        Set<String> aimsClientStr = new Set<String>();
        List<NSP_Sub_Client__c> newSubClientToPopulateAsset = new List<NSP_Sub_Client__c>();

        for(NSP_Sub_Client__c subClientObj : newList){
            if(!String.isBlank(subClientObj.NSP_Client__c)){
                aimsClientStr.add(subClientObj.NSP_Client__c);
                newSubClientToPopulateAsset.add(subClientObj);
            }
        }
    }

    public Void updatePaperlessBatchDateBeforeInsertOrUpdate( List<NSP_Sub_Client__c> newList , Map<Id,NSP_Sub_Client__c> oldMap ) {
         Set<Id> AssetIds = New Set<Id>();
         for(NSP_Sub_Client__c Sc : newList){
             if(Sc.NSP_Asset__c != null){
                 AssetIds.Add(Sc.NSP_Asset__c);
             }
         }
         Map<Id , Asset> AssetMap = New Map<Id , Asset>();
         for(Asset Ast : [Select Id, NSP_Account_Status__c FROM Asset WHERE Id =: AssetIds]){
              AssetMap.Put(Ast.Id , Ast);
       }

        for(NSP_Sub_Client__c SubClientObj : newList){

            if((SubClientObj.NSP_Account_Status__c != null && oldMap == null && AssetMap.containsKey(SubClientObj.NSP_Asset__c) &&
               AssetMap.get(SubClientObj.NSP_Asset__c).NSP_Account_Status__c == 'Active') ||
                (oldMap != null && oldMap.containskey(SubClientObj.Id) && AssetMap.containsKey(SubClientObj.NSP_Asset__c) &&
               AssetMap.get(SubClientObj.NSP_Asset__c).NSP_Account_Status__c == 'Active' &&
                SubClientObj.NSP_Account_Status__c != oldMap.get(SubClientObj.Id).NSP_Account_Status__c)){
                SubClientObj.NSP_Paperless_Batch_Date__c = System.Today();
            }
        }
    }


    /**
     * Iterates throught the list of new NSP_Sub_Client__c and passes the required attributes to other methods.
     * @param newList List of New NSP_Sub_Client__c.
     * @param newMap List of New NSP_Sub_Client__c.
     * @return void
     *
     */
    public void afterInsertDirector(List<NSP_Sub_Client__c> newList, Map<Id, NSP_Sub_Client__c> newMap) {
        Set<Id> assetIdSet = new Set<Id>();
        for(NSP_Sub_Client__c subClientObj : newList){
            assetIdSet.add(subClientObj.NSP_Asset__c);
        }
        if(assetIdSet.size() > 0){
            populateStatusAndStatusDateOnAsset(assetIdSet);
        }
    }


     /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *
     */

    public void afterUpdateDirector(Map<Id, NSP_Sub_Client__c> newMap,Map<Id, NSP_Sub_Client__c> oldMap) {

        //Set<String> subClientAIMSClientIdSetWithUnionEmployees = new Set<String>();
        Set<Id> assetId = new Set<Id>();
        Set<Id> subClientIDs = new Set<Id>();

        for(NSP_Sub_Client__c subClientObj : newMap.values()){
           if(subClientObj.NSP_Account_Status__c != oldMap.get(subClientObj.Id).NSP_Account_Status__c ||
              subClientObj.NSP_Account_Status_Date__c != oldMap.get(subClientObj.Id).NSP_Account_Status_Date__c ||
              subClientObj.NSP_Asset__c != oldMap.get(subClientObj.Id).NSP_Asset__c){
                 assetId.add(subClientObj.NSP_Asset__c);
              }

            if(subClientObj.NSP_States_of_Operations__c != oldMap.get(subClientObj.Id).NSP_States_of_Operations__c){
                subClientIDs.add(subClientObj.Id);
            }
        }

        if(assetId.size() > 0){
            populateStatusAndStatusDateOnAsset(assetId);
        }

        if(subClientIDs.size() > 0){
            updateSooValueOnRelatedPDS(subClientIDs, newMap);
        }
    }


    /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *
     */
    public void populateStatusAndStatusDateOnAsset(Set<Id> assetId){

        List<Asset> assetList = [SELECT Id,(Select Id,NSP_Account_Status__c,NSP_Account_Status_Date__c from Sub_Clients__r order by createddate asc limit 1)
                                     FROM Asset WHERE Id in: assetId];

        for(Asset assetObj : assetList){
            assetObj.NSP_Account_Status__c = assetObj.Sub_Clients__r[0].NSP_Account_Status__c;
            assetObj.NSP_Account_Status_Date__c = assetObj.Sub_Clients__r[0].NSP_Account_Status_Date__c;
        }

        update assetList;

    }

    /**
     * Iterates through the list of Sub Client records and populate the updated State of Opertaions value in the related PDS records.
     * @param Set<Id> List of Sub Client record IDs.
     * @param Map<Id, NSP_Sub_Client__c> Map of new Sub Client records.
     * @return void
     */
    private void updateSooValueOnRelatedPDS(Set<Id> subClientIDs, Map<Id, NSP_Sub_Client__c> newMap){
        List<NSP_Payroll__c> payrolls = [SELECT Id, NSP_States_of_Operation__c, NSP_Sub_Client_Name__c FROM NSP_Payroll__c WHERE NSP_Sub_Client_Name__c IN :subClientIDs];
        for(NSP_Payroll__c payrollRec : payrolls){
            payrollRec.NSP_States_of_Operation__c = newMap.get(payrollRec.NSP_Sub_Client_Name__c).NSP_States_of_Operations__c;
        }
        update payrolls;
    }

    //
    // MethodName: updateAssetTerminationForm
    // Description : This method will clear the asset termination information section
    // Params: List<NSP_Sub_Client__c> newList , Map<Id,NSP_Sub_Client__c> oldMapSubClient
    //
    public void updateAssetTerminationForm( List<NSP_Sub_Client__c> newList , Map<Id, NSP_Sub_Client__c> oldMapSubClient ) {
        //added as part of STY-03529 changes
        Map<Id,NSP_Sub_Client__c> mapOfSubAccount = new Map<Id,NSP_Sub_Client__c> ();
        List<Asset> updatedAssetList = new List<Asset>();
        try {
            for ( NSP_Sub_Client__c sc : newList ) {
                if ( sc.NSP_Sub_Client__c != null
                    && sc.Is_Primary_Contract__c
                    && sc.NSP_Renewal_Date__c != null
                    && sc.NSP_Renewal_Date__c != oldMapSubClient.get( sc.Id ).NSP_Renewal_Date__c
                    && sc.NSP_Account__c != null
                    )
                {
                    mapOfSubAccount.put( sc.NSP_Account__c , sc );
                }
            }
            //clear asset termination form section values
            if ( !mapOfSubAccount.isEmpty() ) {
                for ( Asset record : [
                            SELECT
                                AccountId , NSP_Renewal_Date__c , NSP_Client__c ,
                                NSP_Verbal_Term_recd__c , NSP_Verbal_Term_Date__c ,
                                NSP_Verbal_Term_Updatedby__c , NSP_Written_Term_recd__c ,
                                NSP_Written_Term_Date__c , NSP_Written_Termination_Updated_By__c ,
                                NSP_Anticipated_Date_Of_Termination__c ,
                                NSP_Reason_for_Term__c , NSP_Pending_Termination__c
                            FROM Asset
                            WHERE ( AccountId IN :mapOfSubAccount.keyset() )
                        ]
                    )
                {
                    if ( mapOfSubAccount.get( record.AccountId ).NSP_Renewal_Date__c >= record.NSP_Anticipated_Date_Of_Termination__c ) {
                        record = this.updateAssetFields( record );
                        updatedAssetList.add( record );
                    }
                }
            }
            if ( !updatedAssetList.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( updatedAssetList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientTriggerHelper.class.getName() ,
                    'updateAssetTerminationForm:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_SubClientTriggerHelper.class.getName() ,
                'updateAssetTerminationForm' ,
                e
            );
        }
    }

    private Asset updateAssetFields( Asset record ) {
        if ( record != null ) {
            if ( record.NSP_Verbal_Term_recd__c ) {
                record.NSP_Verbal_Term_recd__c = false;
                record.NSP_Verbal_Term_Date__c = null;
                record.NSP_Verbal_Term_Updatedby__c = Label.NSP_Deployment_Manager;
                record.NSP_Anticipated_Date_Of_Termination__c = null;
                record.NSP_Reason_for_Term__c = null;
                record.NSP_Pending_Termination__c = false;
            }
            if ( record.NSP_Written_Term_recd__c ) {
                record.NSP_Written_Term_recd__c = false;
                record.NSP_Written_Term_Date__c = null;
                record.NSP_Written_Termination_Updated_By__c = Label.NSP_Deployment_Manager;
                record.NSP_Anticipated_Date_Of_Termination__c = null;
                record.NSP_Reason_for_Term__c = null;
                record.NSP_Pending_Termination__c = false;
            }
        }
        return record;
    }

}
//