public class NSP_AccountContactRelationTriggerHandler extends NSP_TriggerAction  implements NSP_ITriggerHandler {
    // test w/ NSP_AccountContactRelationHelperTest, NSP_AccountContactServiceHelperTest, NSP_AccountContactRelationSharingTest (85%)
    // test w/ NSP_AccountContactRelationHelperTest (85%)
    // test w/ NSP_AccountContactServiceHelperTest (78%)
    // test w/ NSP_AccountContactRelationSharingTest (78%)

    public static Boolean TriggerDisabled = false;

    public Boolean isDisabled() {
        return NSP_AccountContactRelationTriggerHandler.TriggerDisabled;
    }

    public void beforeInsert( List<sObject> newList ) {
        NSP_AccountContactRelationTriggerHelper.beforeUpsertDirector( (List<AccountContactRelation>)newList );
    }

    public void afterInsert( List<sObject> newList , Map<Id,sObject> newMap ) {
        NSP_AccountContactRelationTriggerHelper accContactTriggerHelperObject = new NSP_AccountContactRelationTriggerHelper();
        accContactTriggerHelperObject.afterInsertDirector( (List<AccountContactRelation>)newList , (Map<Id,AccountContactRelation>)newMap );
        accContactTriggerHelperObject.afterInsertJobTitle( (List<AccountContactRelation>)newList , (Map<Id,AccountContactRelation>)newMap );
        NSP_AccountContactRelationTriggerHelper.createPlatformEventForACR( (List<AccountContactRelation>)newList , (Map<Id,AccountContactRelation>)newMap );
    }

    public void beforeUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
        if ( !this.hasRun() ) {
            if ( NSP_hotfix_Switch__c.getOrgDefaults().IsEnabledMarkRun__c ) {
                this.markRun();
            }
            NSP_AccountContactRelationTriggerHelper.beforeUpsertDirector( (List<AccountContactRelation>)newMap.values() );
        }
    }

    public void afterUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
        if ( !this.hasRun() || ( this.timesRun() < 2 ) ) {
            if ( NSP_hotfix_Switch__c.getOrgDefaults().IsEnabledMarkRun__c ) {
                this.markRun();
            }
            NSP_AccountContactRelationTriggerHelper accContactTriggerHelperObject = new NSP_AccountContactRelationTriggerHelper();
            accContactTriggerHelperObject.afterUpdateDirector( (Map<Id,AccountContactRelation>)newMap , (Map<Id,AccountContactRelation>)oldMap );
            accContactTriggerHelperObject.afterUpdateJobTitle( (Map<Id,AccountContactRelation>)newMap , (Map<Id,AccountContactRelation>)oldMap );
            NSP_AccountContactServiceHelper.createExternalUser( (Map<Id,AccountContactRelation>)newMap , (Map<Id,AccountContactRelation>)oldMap );
            NSP_AccountContactRelationTriggerHelper.createPlatformEventForACR( (List<AccountContactRelation>)newMap.values() , (Map<Id,AccountContactRelation>)oldMap );
        }
    }

    public void beforeDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
        NSP_AccountContactRelationTriggerHelper.restrictDeletingACR( (List<AccountContactRelation>)oldList );
    }

    public void afterDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
        NSP_AccountContactRelationTriggerHelper.afterDeleteDirector( (List<AccountContactRelation>)oldList );
    }

}
//