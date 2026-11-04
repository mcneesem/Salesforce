// intentionally `without sharing` to preserve default sharing at api version 54...
public without sharing class NSP_AccountGroupTriggerHelper {
    // test w/ NSP_AccountGroupMemberController_Test (92%)
    // test w/ NSP_AccountGroupTriggerHelperTest (77%)

    //
    // Iterates throught the list of NSP_Account_Groups and Updates the group Name based on Criteria.
    // @param newList List of New NSP_Account_Group__c.  OldMap of NSP_Account_Group__c
    // @return void
    //
    public void beforeUpdateGroupName( List<NSP_Account_Group__c> newList , Map<Id,NSP_Account_Group__c> oldMap ) {
        for(NSP_Account_Group__c accGroup : newList){
            NSP_Account_Group__c oldAccountGroup = oldMap != null ? oldMap?.get(accGroup.Id) : null;
            String newName = accGroup.Name;
            List<String> accGroupName = new List<String>();
            //When a Account Group tag/Account is changed, we concat the Group Type & Primary Account & tag
            if(isFieldUpdatedForGroupName(accGroup, oldAccountGroup)){
                if(String.isNotBlank(accGroup.NSP_Type__c)){
                    accGroupName.add(accGroup.NSP_Type__c);
                }
                if(String.isNotBlank(accGroup.NSP_Account__c)){
                    accGroupName.add(accGroup.NSP_Account__c);
                }
                if(String.isNotBlank(accGroup.NSP_Tag__c)){
                    accGroupName.add(accGroup.NSP_Tag__c);
                }

                if(!accGroupName.isEmpty()){
                    newName = String.join(accGroupName, ' - ') ;
                }
            } else if(accGroup.NSP_Type__c == NSP_ServiceConstants.TYPECONTROLLEDGROUP){
                if(String.isNotBlank(accGroup.NSP_Type__c)){
                    accGroupName.add(accGroup.NSP_Type__c);
                }
                if(String.isNotBlank(accGroup.NSP_Account_Group_External_ID__c)){
                    accGroupName.add(accGroup.NSP_Account_Group_External_ID__c);
                }

                if(!accGroupName.isEmpty()){
                    newName = String.join(accGroupName, ' ') ;
                }
            }
            // prevents ~ AccountGroupTrigger: data changed by trigger for field Account Group Name: data value too large: (value has been hidden)
            accGroup.Name = SchemaController.safeText(
                newName ,
                sObjectType.NSP_Account_Group__c.Fields.Name
            );
        }
    }

    // group Type should not be able to change by the user.
    private Boolean isFieldUpdatedForGroupName(NSP_Account_Group__c accGroup, NSP_Account_Group__c oldAccountGroup){
        return accGroup.NSP_Type__c != NSP_ServiceConstants.TYPECONTROLLEDGROUP && (oldAccountGroup == null || (oldAccountGroup != null &&
                (oldAccountGroup.Name != accGroup.Name || oldAccountGroup.NSP_Type__c != accGroup.NSP_Type__c || oldAccountGroup.NSP_Account__c != accGroup.NSP_Account__c||oldAccountGroup.NSP_Tag__c != accGroup.NSP_Tag__c)));
    }

    // group Type should not be able to change by the user.
    public void groupTypeValidation( List<NSP_Account_Group__c> newList , Map<Id,NSP_Account_Group__c> oldMap ) {
        List<String> lstGrpTypes = new List<String>{
            'Account Health' ,
            'Renewal Probability' ,
            'Growth Forecast'
        };
        List<String> lstManualGrpTypes = new List<String>{
            'Controlled Group' ,
            'EEO' ,
            'Renew & Review Together' ,
            'WX Account Group'
        };
        for ( NSP_Account_Group__c accGrp : newList ) {
            if ( !CustomPermissionController.checkUserPermission( 'Bypass_Restrict_Account_Group_Types' , UserInfo.getUserId() ) ) {
                NSP_Account_Group__c accGrpOld = oldMap?.get( accGrp.Id );
                if ( ( accGrp.NSP_Type__c != accGrpOld?.NSP_Type__c )
                    && ( lstGrpTypes.contains( accGrp.NSP_Type__c )
                        || lstGrpTypes.contains( accGrpOld?.NSP_Type__c )
                        )
                    )
                {
                    accGrp.addError( System.Label.NSP_AccountGroupErrorMessage );
                }
                if ( ( ( accGrp.NSP_Type__c != accGrpOld?.NSP_Type__c )
                        || ( accGrp.NSP_Tag__c != accGrpOld?.NSP_Tag__c )
                        || ( accGrp.NSP_Watchlist__c != accGrpOld?.NSP_Watchlist__c )
                        )
                    && ( lstManualGrpTypes.contains( accGrp.NSP_Type__c )
                        || lstManualGrpTypes.contains( accGrpOld?.NSP_Type__c )
                        )
                    )
                {
                    accGrp.addError( System.Label.NSP_AccountGroupErrorMessage );
                }
            }
        }
    }

    //
    // Pass all the records to the Queuable for Account Group History for Big Object.
    // @param  Map of New NSP_Account_Group__c.  OldMap of NSP_Account_Group__c
    // @param newList Map of New NSP_Account_Group__c.  OldMap of NSP_Account_Group__c
    // @return void
    //
    public void afterUpdate( Map<Id,NSP_Account_Group__c> newMap , Map<Id,NSP_Account_Group__c> oldMap ) {
    }
}
//