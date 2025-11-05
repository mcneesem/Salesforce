public class NSP_SObjectUpdateTriggerHelper {
    // test w/ NSP_AccountContactRelationHelperTest, NSP_AccountTeamMemberTriggerHelperTest, NSP_AccountTeamTriggerTest, NSP_AccountTriggerHelperTest, NSP_ContactTriggerHelperTest, NSP_EventTriggerHelperTest, NSP_OpportunityTeamMemberTriggerTest, NSP_OpportunityTriggerHelperTest (100%)

    // NSP_AccountContactRelationTriggerHelper
    // NSP_AccountTeamMemberTriggerHelper
    // NSP_AccountTeamTriggerHelper
    // NSP_AccountTriggerHelper
    // NSP_ContactTriggerHelper
    // NSP_OpportunityTeamMemberTriggerHelper
    // NSP_OpportunityTriggerHelper
    public Set<Id> fetchUpdFieldsLst(String objName, Map<Id, SObject> newMapSObject, Map<Id, SObject> oldMapSObject) {

        Map<Id, SObject> sObjectMap = New Map<Id, SObject>();
        Set<Id> sObjectRecordId = New Set<Id>();    // Hold list of Ids to pass the Platform Event.
        String objectType = String.valueOf(newMapSObject.getsobjecttype());
        List<NSP_SObject_Field_Update_Integration__mdt> objFldInt = New List<NSP_SObject_Field_Update_Integration__mdt>();
        objFldInt = [Select Id, DeveloperName, NSP_SObject_Name__c, NSP_Field_Name__c, NSP_Integration_User__c From NSP_SObject_Field_Update_Integration__mdt WHERE NSP_SObject_Name__c =: objectType AND NSP_Integration_User__c = FALSE];

        //
        // For Account object
        // @param sObjectMap feed the Account Id and Records
        // @param sObjectRecordId feed only Account Id
        //
        //

        if(objFldInt.size() > 0 && objName == NSP_IntegrationConstants.SOBJECT_ACCOUNT) {
            for(Id identifier : newMapSObject.keySet()) {
                sObject newRec = newMapSObject.get(identifier);
                sObject oldRec = oldMapSObject.get(identifier);
                    // Iterate metadata field list to every record field value
                    for(NSP_SObject_Field_Update_Integration__mdt ofi : objFldInt) {
                        if(newRec.get(ofi.NSP_Field_Name__c) != oldRec.get(ofi.NSP_Field_Name__c)) {
                            sObjectMap.Put(identifier, newRec);  // Map<Id, Acocunt>
                            sObjectRecordId.add(identifier); // Set<Id> only AccountIds.
                            break;
                        }
                    }
             }

            if(sObjectRecordId.size() > 0){
                return sObjectRecordId;
            }
        }

        //
        // For AccountTeamMember object
        // @param sObjectMap feed the AccountTeamMember Id and Records
        // @param sObjectRecordId feed Account Id from AccountTeamMember records
        //

        if(objFldInt.size() > 0 && objName == NSP_IntegrationConstants.SOBJECT_ACCOUNTTEAMMEMBER) {
            for(Id identifier : newMapSObject.keySet()) {
                sObject newRec = newMapSObject.get(identifier);
                sObject oldRec = oldMapSObject.get(identifier);

                // Iterate metadata field list to compare old and new field value
                for(NSP_SObject_Field_Update_Integration__mdt ofi : objFldInt){
                    if(newRec.get(ofi.NSP_Field_Name__c) != oldRec.get(ofi.NSP_Field_Name__c)) {
                        sObjectMap.Put(identifier, newRec);  // Map<Id, AcocuntTeamMember>

                        Id aId = (Id) newRec.get('AccountId');
                        sObjectRecordId.add(aId);  // Set<Id> only AccountIds.
                        break;
                    }
                }
            }
            if(sObjectRecordId.size() > 0){
                return sObjectRecordId;
            }
        }

        //
        // For Contact object
        // @param sObjectMap feed the Contact Id and Records
        // @param sObjectRecordId feed Account Id from Contact records
        //

        if(objFldInt.size() > 0 && objName == NSP_IntegrationConstants.SOBJECT_CONTACT) {
            for(Id identifier : newMapSObject.keySet()) {
                sObject newRec = newMapSObject.get(identifier);
                sObject oldRec = oldMapSObject.get(identifier);

                // Iterate metadata field list to compare old and new field value
                    for(NSP_SObject_Field_Update_Integration__mdt ofi : objFldInt){
                        if(newRec.get('AccountId')!=null && newRec.get(ofi.NSP_Field_Name__c) != oldRec.get(ofi.NSP_Field_Name__c)) {
                            sObjectMap.Put(identifier, newRec);  // Map<Id, Contact>

                            Id aId = (Id) newRec.get('AccountId');
                            sObjectRecordId.add(aId);  // Set<Id> only AccountIds.
                            break;
                        }
                    }

            }
            List<AccountContactRelation> listAccCon = [SELECT Id, AccountId FROM AccountContactRelation
                                                      WHERE ContactId IN: sObjectMap.keySet()];
            for(AccountContactRelation acr : listAccCon){
                sObjectRecordId.add(acr.AccountId);
            }
            if(sObjectRecordId.size() > 0){
                return sObjectRecordId;
            }
        }


        //
        // For Opportunity object
        // @param sObjectRecordId feed Opportunity Id from Contact records
        //

        if(objFldInt.size() > 0 && objName == NSP_IntegrationConstants.SOBJECT_OPPORTUNITY) {
            for(Id identifier : newMapSObject.keySet()) {
                sObject newRec = newMapSObject.get(identifier);
                sObject oldRec = oldMapSObject.get(identifier);
                    // Iterate metadata field list to compare old and new field value
                    for(NSP_SObject_Field_Update_Integration__mdt ofi : objFldInt){
                        if(newRec.get(ofi.NSP_Field_Name__c) != oldRec.get(ofi.NSP_Field_Name__c)) {
                            sObjectMap.Put(identifier, newRec);  // Map<Id, Acocunt>
                            sObjectRecordId.add(identifier); // Set<Id> only AccountIds.
                            break;
                        }
                    }

            }
            if(sObjectRecordId.size() > 0){
                return sObjectRecordId;
            }
        }

        //
        // For OpportunityTeamMember object
        // @param sObjectMap feed the Contact Id and Records
        // @param sObjectRecordId feed Account Id from Contact records
        //

        if(objFldInt.size() > 0 && objName == NSP_IntegrationConstants.SOBJECT_OPPORTUNITYTEAMMEMBER) {
            for(Id identifier : newMapSObject.keySet()) {
                sObject newRec = newMapSObject.get(identifier);
                sObject oldRec = oldMapSObject.get(identifier);
                    // Iterate metadata field list to compare old and new field value
                    for(NSP_SObject_Field_Update_Integration__mdt ofi : objFldInt){
                        if(newRec.get(ofi.NSP_Field_Name__c) != oldRec.get(ofi.NSP_Field_Name__c)) {
                            sObjectMap.Put(identifier, newRec);  // Map<Id, Acocunt>
                            Id aId = (Id) newRec.get('opportunityId');
                            sObjectRecordId.add(aId);// Set<Id> only AccountIds.
                            break;
                        }
                    }

            }
            if(sObjectRecordId.size() > 0){
                return sObjectRecordId;
            }
        }


        //
        // For AccountContactRelation object
        // @param sObjectMap feed the Contact Id and Records
        // @param sObjectRecordId feed Account Id from Contact records
        //

        if(objFldInt.size() > 0 && objName == NSP_IntegrationConstants.SOBJECT_ACCOUNTCONTACTRELATION) {
            for(Id identifier : newMapSObject.keySet()) {
                sObject newRec = newMapSObject.get(identifier);
                sObject oldRec = oldMapSObject.get(identifier);
                    // Iterate metadata field list to compare old and new field value
                    for(NSP_SObject_Field_Update_Integration__mdt ofi : objFldInt){
                        if(newRec.get(ofi.NSP_Field_Name__c) != oldRec.get(ofi.NSP_Field_Name__c)) {
                            sObjectMap.Put(identifier, newRec);  // Map<Id, Acocunt>
                            Id aId = (Id) newRec.get('accountId');
                            sObjectRecordId.add(aId);// Set<Id> only AccountIds.
                            break;
                        }
                    }

            }
            if(sObjectRecordId.size() > 0){
                return sObjectRecordId;
            }
        }

        //
        // For AccountTeam object
        // @param sObjectMap feed the AccountTeam Id and Records
        // @param sObjectRecordId feed Account Id from AccountTeam records
        //

        if(objFldInt.size() > 0 && objName == NSP_IntegrationConstants.SOBJECT_ACCOUNTTEAM) {
            for(Id identifier : newMapSObject.keySet()) {
                sObject newRec = newMapSObject.get(identifier);
                sObject oldRec = oldMapSObject.get(identifier);
                    // Iterate metadata field list to compare old and new field value
                    for(NSP_SObject_Field_Update_Integration__mdt ofi : objFldInt){
                        if(newRec.get(ofi.NSP_Field_Name__c) != oldRec.get(ofi.NSP_Field_Name__c)) {
                            sObjectMap.Put(identifier, newRec);  // Map<Id, Acocunt>
                            Id aId = (Id) newRec.get('NSP_Account__c');
                            sObjectRecordId.add(aId);// Set<Id> only AccountIds.
                            break;
                        }
                    }

            }
            if(sObjectRecordId.size() > 0){
                return sObjectRecordId;
            }
        }

        return sObjectRecordId;
    }

}
//