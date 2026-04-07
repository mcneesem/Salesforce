// unified solution for setting "sync flags", publishing "integration sync" events, and clearing "sync flags"...
// intentionally `without sharing` to prevent ~ INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id
public without sharing class IntegrationSyncController {
    // test w/ IntegrationSyncControllerTest, NSP_OpportunityTriggerHelperTest (86%)
    // test w/ IntegrationSyncControllerTest (79%)
    // test w/ NSP_AccountContactRelationHelperTest (29%)
    // test w/ NSP_AccountTeamMemberTriggerHelperTest (29%)
    // test w/ NSP_AccountTeamTriggerTest (29%)
    // test w/ NSP_AccountTriggerHelperTest (32%)
    // test w/ NSP_ContactTriggerHelperTest (29%)
    // test w/ NSP_OpportunityTriggerHelperTest (32%)

    //
    // assign-flag
    //
    // Account-before-insert
    // Account-before-update
    public static void assignReadyForIntegrationSync( List<Account> records ) {
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( Account record : records ) {
                record.NSP_Ready_for_Integration_Sync__c = true; // DEPRECATED
            }
        }
    }

    //
    // set-flag
    //
    // AccountContactRelation-after-insert
    // AccountContactRelation-after-update
    // NSP_Account_Team__c-after-insert
    // NSP_Account_Team__c-after-update
    // AccountTeamMember-after-insert
    // AccountTeamMember-after-update
    public static void setReadyForIntegrationSync( Set<Id> recordIds ) {
        IntegrationSyncController.setReadyForIntegrationSync( recordIds , Account.getSObjectType() );
    }
    // Contact-before-update
    // Event-after-insert
    // OpportunityTeamMember-after-insert
    public static void setReadyForIntegrationSync( Set<Id> recordIds , Schema.sObjectType soType ) {
        if ( soType != null ) {
            if ( soType == Account.getSObjectType() ) {
                NSP_AccountTriggerHelper.setReadyForIntegrationSync( recordIds );
            } else if ( soType == Contact.getSObjectType() ) {
                NSP_AccountTriggerHelper.setReadyForIntegrationSync( recordIds );
            } else if ( soType == Event.getSObjectType() ) {
                NSP_OpportunityTriggerHelper.setReadyForIntegrationSync( recordIds );
            } else if ( soType == OpportunityTeamMember.getSObjectType() ) {
                NSP_OpportunityTriggerHelper.setReadyForIntegrationSync( recordIds );
            }
        }
    }

    // clear-flag
    // after-publish
    private static void clearReadyForIntegrationSync( Set<Id> recordIds ) {
        IntegrationSyncController.updateReadyForIntegrationSync( recordIds , false , false );
    }

    // private-setter
    private static void updateReadyForIntegrationSync( Set<Id> recordIds , Boolean value , Boolean disableAccountTrigger ) {
        if ( ( recordIds != null ) && !recordIds.isEmpty() ) {
            List<Account> records = new List<Account>();
            for ( Id recordId : recordIds ) {
                Account record = new Account();
                record.Id = recordId;
                record.NSP_Ready_for_Integration_Sync__c = value; // DEPRECATED
                records.add( record );
            }
            if ( !records.isEmpty() ) {
                try {
                    if ( disableAccountTrigger ) {
                        NSP_AccountTriggerHandler.TriggerDisabled = true; // added for ADO-195356
                    }
                    List<Database.SaveResult> results = Database.update( records , false );
                    NSP_ErrorLogHandler.logResults(
                        IntegrationSyncController.class.getName() ,
                        'updateReadyForIntegrationSync' ,
                        results
                    );
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        IntegrationSyncController.class.getName() ,
                        'updateReadyForIntegrationSync' ,
                        e
                    );
                }
            }
        }
    }

    // Account-after-insert
    // Account-after-update
    public static void publishIntegrationAccountEvents( Set<Id> recordIds ) {
        if ( ( recordIds != null ) && !recordIds.isEmpty() ) {
            List<Integration_Account_Event__e> events = new List<Integration_Account_Event__e>();
            for ( Id recordId : recordIds ) {
                events.add(
                    new Integration_Account_Event__e(
                        Id__c=recordId
                    )
                );
            }
            IntegrationSyncController.publishIntegrationAccountEvents( events , recordIds );
        }
    }

    // Account-after-delete
    public static void publishIntegrationAccountEvents( List<Account> records ) {
        if ( ( records != null ) && !records.isEmpty() ) {
            List<Integration_Account_Delete_Event__e> events = new List<Integration_Account_Delete_Event__e>();
            for ( Account record : records ) {
                Map<String,Object> populatedFieldsMap = record.getPopulatedFieldsAsMap();
                if ( populatedFieldsMap.containsKey( 'Id' )
                    && populatedFieldsMap.containsKey( 'MasterRecordId' )
                    && ( record.MasterRecordId != null )
                    )
                {
                    events.add(
                        new Integration_Account_Delete_Event__e(
                            Id__c=record.Id ,
                            MasterRecordId__c=record.MasterRecordId
                        )
                    );
                }
            }
            IntegrationSyncController.publishIntegrationAccountEvents( events );
        }
    }

    // private-publisher
    private static void publishIntegrationAccountEvents( List<Integration_Account_Delete_Event__e> events ) {
        IntegrationSyncController.publishIntegrationAccountEvents( events , new Set<Id>() );
    }
    private static void publishIntegrationAccountEvents( List<SObject> events , Set<Id> recordIds ) {
        if ( IntegrationSyncController.isEnabledIntegrationAccountEvent ) {
            if ( ( events != null )
                && !events.isEmpty()
                && ( ( events.getSObjectType() == Integration_Account_Event__e.getSObjectType() )
                    || ( events.getSObjectType() == Integration_Account_Delete_Event__e.getSObjectType() )
                    )
                )
            {
                List<Database.SaveResult> results = EventBus.publish( events );
                NSP_ErrorLogHandler.logResults(
                    IntegrationSyncController.class.getName() ,
                    'publishIntegrationAccountEvents' ,
                    results
                );
            }
            IntegrationSyncController.clearReadyForIntegrationSync( recordIds );
        }
    }

    //
    // Custom Settings
    //

    private static PlatformEventSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = PlatformEventSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabledIntegrationAccountEvent {
        private get {
            if ( isEnabledIntegrationAccountEvent == null ) {
                Boolean local = false;
                if ( IntegrationSyncController.settings != null ) {
                    local = IntegrationSyncController.settings.IsEnabled_IntegrationAccountEvent__c;
                }
                isEnabledIntegrationAccountEvent = local;
            }
            return isEnabledIntegrationAccountEvent;
        }
        private set;
    }

}
//