public with sharing class NSP_CampaignTriggerHelper {
    // test w/ NSP_CampaignTriggerHelperTest (86%)

     public void beforeInsertDirector( List<Campaign> newList ) {
        try {
            updateCampaignField( newList , null );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_CampaignTriggerHelper.class.getName() ,
                'beforeInsertDirector' ,
                e
            );
        }
    }

    private void updateCampaignField( List<Campaign> newList , Map<Id,Campaign> oldCampaignMap ) {
        Set<Id> ownerIdSet = new set<Id>();
        Set<String> officeSet = new set<String>();
        for ( Campaign newCampaign : newList ) {
            Campaign oldCampaign = ( oldCampaignMap != null ) ? oldCampaignMap.get(newCampaign.Id) : null;
            if ( Trigger.isInsert || ( newCampaign.OwnerId != oldCampaign.OwnerId ) ) {
                if ( NSP_CampaignTriggerHelper.ownerBasedUserMap.keySet().contains( newCampaign.OwnerId ) ) {
                    ownerIdSet.add( newCampaign.OwnerId );
                } else if ( NSP_CampaignTriggerHelper.campaignBasedUserMap.keySet().contains( newCampaign.OwnerId )
                    && ( newCampaign.NSP_Sales_Office__c != null )
                    )
                {
                    officeSet.add( newCampaign.NSP_Sales_Office__c );
                }
            }
        }
        updateCampaignSOFieldsFromOwner( ownerIdSet , newList , oldCampaignMap );
        updateCampaignSOFieldsFromCampaign( officeSet , newList , oldCampaignMap );
    }

    private void updateCampaignSOFieldsFromOwner( Set<Id> ownerIdSet , List<Campaign> newList , Map<Id,Campaign> oldCampaignMap ) {
        if ( ( ownerIdSet != null ) && !ownerIdSet.isEmpty() ) {
            Map<Id,User> userIdMap = new Map<Id,User>(
                [
                    SELECT
                        Id ,
                        NSP_SalesDivision__c ,
                        NSP_Sales_Office__c ,
                        NSP_SalesRegion__c ,
                        UserRole.Name
                    FROM User
                    WHERE (
                        ( Id IN :ownerIdSet )
                        AND ( NSP_Sales_Office__c != null )
                    )
                ]
            );
            for ( Campaign newCampaign : newList ) {
                Campaign oldCampaign = ( oldCampaignMap != null ) ? oldCampaignMap.get( newCampaign.Id ) : null;
                if ( userIdMap.containsKey( newCampaign.ownerId )
                    && ( Trigger.isInsert || ( newCampaign.OwnerId != oldCampaign.OwnerId ) )
                    )
                {
                    user eachUser = userIdMap.get( newCampaign.OwnerId );
                    newCampaign.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c; // sales region
                    newCampaign.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newCampaign.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                }
            }
        }
    }

    private void updateCampaignSOFieldsFromCampaign( Set<String> officeSet , List<Campaign> newList , Map<Id,Campaign> oldCampaignMap ) {
        if ( ( officeSet != null ) && !officeSet.isEmpty() ) {
            Map<String,NSP_Sales_Office_Mapping__c> salesOfficeToMappingMap =  new Map<String,NSP_Sales_Office_Mapping__c>();
            for ( NSP_Sales_Office_Mapping__c eachMapping : [
                        SELECT 
                            Id , 
                            NSP_Sales_Office__c , 
                            NSP_Sales_Division__c , 
                            NSP_Sales_Region__c
                        FROM NSP_Sales_Office_Mapping__c
                        WHERE (
                            ( NSP_Sales_Office__c IN :officeSet )
                            AND ( IsActive__c = true )
                        )
                    ]
                )
            {
                salesOfficeToMappingMap.put( eachMapping.NSP_Sales_Office__c , eachMapping );
            }
            for ( Campaign newCampaign : newList ) {
                Campaign oldCampaign = ( oldCampaignMap != null ) ? oldCampaignMap.get( newCampaign.Id ) : null;
                if ( Trigger.isInsert
                    || (
                        ( newCampaign.OwnerId != oldCampaign.OwnerId )
                        && ( newCampaign.NSP_Sales_Office__c != null )
                        )
                    )
                {
                    NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get( newCampaign.NSP_Sales_Office__c );
                    newCampaign.NSP_Sales_Region__c = officeMapping.NSP_Sales_Region__c; // sales region
                    newCampaign.NSP_Sales_Division__c = officeMapping.NSP_Sales_Division__c; // sales division
                }
            }
        }
    }
    
    private static Map<Id,User> ownerBasedUserMap {
        private get {
            if ( ownerBasedUserMap == null ) {
                ownerBasedUserMap = CustomPermissionController.getPermittedUsersMap( 'Campaign_Update_Sales_Office_Info_Owner_Assigned' );
            }
            return ownerBasedUserMap;
        }
        private set;
    }
    
    private static Map<Id,User> campaignBasedUserMap {
        private get {
            if ( campaignBasedUserMap == null ) {
                campaignBasedUserMap = CustomPermissionController.getPermittedUsersMap( 'Campaign_Update_Sales_Office_Info_Campaign_Assigned' );
            }
            return campaignBasedUserMap;
        }
        private set;
    }
}
//