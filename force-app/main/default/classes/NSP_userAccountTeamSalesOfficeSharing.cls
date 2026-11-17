// intentionally `without sharing` to preserve default sharing at api version 54...
public without sharing class NSP_userAccountTeamSalesOfficeSharing implements Queueable  {
    // test w/ NSP_salesOfficeRecordSharingTest (81%)

    private Map<String,Set<String>> mapnewSalesofficeSetUserId = new Map<String,Set<String>>();
    private Set<Id> ownerIdSet = new Set <Id>();
    private Map<String,Set<String>> mapUserIdSetOldSalesOffice = new Map<String,Set<String>>();

    public NSP_userAccountTeamSalesOfficeSharing(
        Map<String,Set<String>> mapnewSalesofficeSetUserIdLocal ,
        Map<String,Set<String>> mapUserIdSetOldSalesOfficeLocal ,
        Set<Id> ownerIdSetLocal
        )
    {
        this.mapnewSalesofficeSetUserId = mapnewSalesofficeSetUserIdLocal;
        this.ownerIdSet = ownerIdSetLocal;
        this.mapUserIdSetOldSalesOffice = mapUserIdSetOldSalesOfficeLocal;
    }

    public void execute( QueueableContext qc ) {
        try {
            Map<String,String> mapSalesOfficePublicGroupId = NSP_salesOfficeRecordSharing.mapSalesOfficePublicGroup(
                this.mapnewSalesofficeSetUserId?.keySet()
            );
            List<NSP_Account_Team__c> accountTeamList = [
                SELECT
                    Id ,
                    NSP_Account__c ,
                    NSP_Account__r.OwnerId ,
                    toLabel( NSP_Account__r.Owner.NSP_Sales_Office_Membership__c ) ,
                    NSP_User__c ,
                    toLabel( NSP_User__r.NSP_Sales_Office_Membership__c )
                FROM NSP_Account_Team__c
                WHERE (
                    ( NSP_Role__c = :System.Label.NSP_AccountTeamMemberRole )
                    AND ( NSP_User__c IN :this.ownerIdSet )
                    AND ( NSP_User__c != null )
                    AND ( NSP_Account__c != null )
                )
            ];
            Map<String,Set<String>> mapAccountIdSetAccTeamSalesOffice = new Map<String,Set<String>>();
            Map<String,Set<String>> mapAccountIdSetAccountOwnerSalesOffice = new Map<String,Set<String>>();
            List<AccountShare> newSalesAccountShareList = new List<AccountShare>();
            if ( ( accountTeamList != null ) && !accountTeamList.isEmpty() ) {
                for ( NSP_Account_Team__c acTeam : accountTeamList ) {
                    // Creating Map of Account Id and Sales Offices of Account Team User Sales Office
                    mapAccountIdSetAccTeamSalesOffice = this.buildMapAccountTeamSalesOffices( acTeam );
                    // Store Account Sales Office for compairing with Account Team Sales Office
                    // creating a map of AccountId and set of account owner Sales office
                    mapAccountIdSetAccountOwnerSalesOffice = this.buildMapAccountOwnerSalesOffices( acTeam );
                    // create Account Sharing If Account Team Sales Office not Matches Account Sales Office
                    newSalesAccountShareList = this.buildAccountSharesNew(
                        acTeam ,
                        mapAccountIdSetAccountOwnerSalesOffice ,
                        mapSalesOfficePublicGroupId
                    );
                }
            }
            // fetching old Sales Office Account Share of ATM Users
            // creating List of Old Sales Office Account Shares for Account Team
            List<AccountShare> deleteOldAccountShareList = this.buildAccountSharesOld(
                mapAccountIdSetAccTeamSalesOffice ,
                mapAccountIdSetAccountOwnerSalesOffice
            );
            // Inserting Account Shares for New Sales Office
            if ( ( newSalesAccountShareList != null )
                && !newSalesAccountShareList.isEmpty()
                )
            {
                List<Database.SaveResult> results = Database.insert( newSalesAccountShareList , false );
                NSP_userAccountTeamSalesOfficeSharing.handleResults( results , 'execute:insert:AccountShare' );
            }
            // Deleting Account Shares for Old Sales Office
            if ( ( deleteOldAccountShareList != null )
                && !deleteOldAccountShareList.isEmpty()
                )
            {
                List<Database.DeleteResult> results = Database.delete( deleteOldAccountShareList , false );
                NSP_userAccountTeamSalesOfficeSharing.handleResults( results , 'execute:delete:AccountShare' );
            }
            //updating Users after Processing Complete
            if ( ( this.mapUserIdSetOldSalesOffice != null )
                && !this.mapUserIdSetOldSalesOffice.isEmpty()
                )
            {
                List<User> updateUserList = new List<User>();
                for ( Id userId : this.mapUserIdSetOldSalesOffice.keySet() ) {
                    User usr = new User();
                    usr.Id = userId;
                    usr.NSP_Office_Processing__c = 'Processing Complete';
                    updateUserList.add( usr );
                }
                if ( !updateUserList.isEmpty() ) {
                    List<Database.SaveResult> results = Database.update( updateUserList , false );
                    NSP_userAccountTeamSalesOfficeSharing.handleResults( results , 'execute:update:User' );
                }
            }
        } catch ( Exception e ) {
            NSP_userAccountTeamSalesOfficeSharing.handleException( e , 'execute' );
        }
    }

    //
    //
    //

    // sonar helper method...
    private Map<String,Set<String>> buildMapAccountTeamSalesOffices( NSP_Account_Team__c acTeam ) {
        // Creating Map of Account Id and Sales Offices of Account Team User Sales Office
        Map<String,Set<String>> response = new Map<String,Set<String>>();
        if ( ( acTeam.NSP_Account__c != null )
            && ( acTeam.NSP_User__c != null )
            && ( this.mapUserIdSetOldSalesOffice != null )
            && this.mapUserIdSetOldSalesOffice.containsKey( acTeam.NSP_User__c )
            && ( this.mapUserIdSetOldSalesOffice.get( acTeam.NSP_User__c ) != null )
            )
        {
            if ( !response.containsKey( acTeam.NSP_Account__c ) ) {
                response.put(
                    acTeam.NSP_Account__c ,
                    new Set<String>()
                );
            }
            response.get( acTeam.NSP_Account__c ).addAll(
                this.mapUserIdSetOldSalesOffice.get( acTeam.NSP_User__c )
            );
        }
        return response;
    }

    // sonar helper method...
    private Map<String,Set<String>> buildMapAccountOwnerSalesOffices( NSP_Account_Team__c acTeam ) {
        // Store Account Sales Office for compairing with Account Team Sales Office
        // creating a map of AccountId and set of account owner Sales office
        Map<String,Set<String>> response = new Map<String,Set<String>>();
        if ( ( acTeam != null )
            && ( acTeam.NSP_Account__c != null )
            && ( acTeam.NSP_Account__r.Owner != null )
            && String.isNotBlank( acTeam.NSP_Account__r.Owner.NSP_Sales_Office_Membership__c )
            )
        {
            if ( !response.containsKey( acTeam.NSP_Account__c ) ) {
                response.put(
                    acTeam.NSP_Account__c ,
                    new Set<String>()
                );
            }
            response.get( acTeam.NSP_Account__c ).addAll(
                new List<String>(
                    acTeam.NSP_Account__r.Owner.NSP_Sales_Office_Membership__c.split( ';' )
                )
            );
        }
        return response;
    }

    // sonar helper method...
    private List<AccountShare> buildAccountSharesNew(
        NSP_Account_Team__c acTeam ,
        Map<String,Set<String>> mapAccountIdSetAccountOwnerSalesOffice ,
        Map<String,String> mapSalesOfficePublicGroupId
        )
    {
        // create Account Sharing If Account Team Sales Office not Matches Account Sales Office
        List<AccountShare> records = new List<AccountShare>();
        if ( ( acTeam != null )
            && ( acTeam.NSP_User__r != null )
            && String.isNotBlank( acTeam.NSP_User__r.NSP_Sales_Office_Membership__c )
            )
        {
            for ( String acTeamSalesOffice : acTeam.NSP_User__r.NSP_Sales_Office_Membership__c.split( ';' ) ){
                AccountShare acShare = this.buildAccountShare(
                    acTeam ,
                    acTeamSalesOffice ,
                    mapAccountIdSetAccountOwnerSalesOffice ,
                    mapSalesOfficePublicGroupId
                );
                if ( acShare != null ) {
                    records.add( acShare );
                }
            }
        }
        return records;
    }

    // sonar helper method...
    private AccountShare buildAccountShare(
        NSP_Account_Team__c acTeam ,
        String acTeamSalesOffice ,
        Map<String,Set<String>> mapAccountIdSetAccountOwnerSalesOffice ,
        Map<String,String> mapSalesOfficePublicGroupId
        )
    {
        AccountShare record = null;
        if ( ( acTeam != null )
            && ( acTeam.NSP_Account__c != null )
            && String.isNotBlank( acTeamSalesOffice )
            && ( mapAccountIdSetAccountOwnerSalesOffice != null )
            && mapAccountIdSetAccountOwnerSalesOffice.containsKey( acTeam.NSP_Account__c )
            && ( mapAccountIdSetAccountOwnerSalesOffice.get( acTeam.NSP_Account__c ) != null )
            && !mapAccountIdSetAccountOwnerSalesOffice.get( acTeam.NSP_Account__c ).contains( acTeamSalesOffice )
            && ( mapSalesOfficePublicGroupId != null )
            && mapSalesOfficePublicGroupId.containsKey( acTeamSalesOffice )
            && ( mapSalesOfficePublicGroupId.get( acTeamSalesOffice ) != null )
            )
        {
            // only create AccountShares that are NOT IN mapAccountIdSetAccountOwnerSalesOffice...
            record = new AccountShare();
            record.AccountId = acTeam.NSP_Account__c;
            record.AccountAccessLevel = 'Edit';
            record.OpportunityAccessLevel = 'None';
            record.RowCause = 'Manual';
            record.UserOrGroupId = mapSalesOfficePublicGroupId.get( acTeamSalesOffice );
        }
        return record;
    }

    // sonar helper method...
    private List<AccountShare> buildAccountSharesOld(
        Map<String,Set<String>> mapAccountIdSetAccTeamSalesOffice ,
        Map<String,Set<String>> mapAccountIdSetAccountOwnerSalesOffice
        )
    {
        // creating List of Old Sales Office Account Shares for Account Team
        List<AccountShare> records = new List<AccountShare>();
        List<AccountShare> oldAccountTeamShareList = this.selectExistingAccountShares(
            mapAccountIdSetAccTeamSalesOffice?.keySet()
        );
        if ( ( oldAccountTeamShareList != null ) && !oldAccountTeamShareList.isEmpty() ) {
            for ( AccountShare acShare : oldAccountTeamShareList ) {
                records = this.buildAccountSharesOld(
                    records ,
                    acShare ,
                    mapAccountIdSetAccTeamSalesOffice ,
                    mapAccountIdSetAccountOwnerSalesOffice
                );
            }
        }
        return records;
    }

    // sonar helper method...
    private List<AccountShare> buildAccountSharesOld(
        List<AccountShare> records ,
        AccountShare acShare ,
        Map<String,Set<String>> mapAccountIdSetAccTeamSalesOffice ,
        Map<String,Set<String>> mapAccountIdSetAccountOwnerSalesOffice
        )
    {
        if ( records == null ) {
            records = new List<AccountShare>();
        }
        if ( ( acShare != null )
            && ( acShare.AccountId != null )
            && ( acShare.UserOrGroup != null )
            && String.isNotBlank( acShare.UserOrGroup.Name )
            && ( mapAccountIdSetAccTeamSalesOffice != null )
            && mapAccountIdSetAccTeamSalesOffice.containsKey( acShare.AccountId )
            && ( mapAccountIdSetAccTeamSalesOffice.get( acShare.AccountId ) != null )
            && mapAccountIdSetAccTeamSalesOffice.get( acShare.AccountId ).contains( acShare.UserOrGroup.Name )
            && ( mapAccountIdSetAccountOwnerSalesOffice != null )
            && mapAccountIdSetAccountOwnerSalesOffice.containsKey( acShare.AccountId )
            && ( mapAccountIdSetAccountOwnerSalesOffice.get( acShare.AccountId ) != null )
            && !mapAccountIdSetAccountOwnerSalesOffice.get( acShare.AccountId ).contains( acShare.UserOrGroup.Name )
            )
        {
            // only remove AccountShares that are IN mapAccountIdSetAccTeamSalesOffice but NOT IN mapAccountIdSetAccountOwnerSalesOffice...
            records.add( acShare );
        }
        return records;
    }

    // sonar helper method...
    private List<AccountShare> selectExistingAccountShares( Set<String> accountIds ) {
        // fetching old Sales Office Account Share of ATM Users
        List<AccountShare> response = null;
        if ( ( accountIds != null )
            && !accountIds.isEmpty()
            )
        {
            response = [
                SELECT
                    Id ,
                    AccountId ,
                    UserorGroupId ,
                    UserOrGroup.Name ,
                    RowCause
                FROM AccountShare
                WHERE (
                    ( AccountId IN :accountIds )
                    AND ( AccountId != null )
                    AND ( RowCause = 'Manual' )
                    AND ( UserorGroupId != null )
                )
            ];
        }
        return response;
    }

    //
    //
    //

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_userAccountTeamSalesOfficeSharing.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_userAccountTeamSalesOfficeSharing.class.getName() ,
            methodName ,
            e
        );
    }

    private static void handleResults( List<Database.SaveResult> results , String methodName ) {
        NSP_ErrorLogHandler.logResults(
            NSP_userAccountTeamSalesOfficeSharing.class.getName() ,
            methodName ,
            results
        );
    }

    private static void handleResults( List<Database.DeleteResult> results , String methodName ) {
        NSP_ErrorLogHandler.logResults(
            NSP_userAccountTeamSalesOfficeSharing.class.getName() ,
            methodName ,
            results
        );
    }

}
//