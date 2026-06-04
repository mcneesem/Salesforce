// intentionally `without sharing` to see all Accounts, AccountContactRelations, Contacts, Portal Clientes, and Users for successful sharing calculations...
public without sharing class PortalClientSharing implements Queueable {
    // test w/ PortalClientSharing (85%)

    //
    // Queueable
    //

    public static void enqueueJob( Set<Id> recordIdSet ) {
        if ( PortalClientSharing.isEnabled
            && ( recordIdSet != null )
            && !recordIdSet.isEmpty()
            && !System.isQueueable() // prevent AsyncExceptions...
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) // prevent LimitExceptions...
            )
        {
            System.enqueueJob(
                new PortalClientSharing(
                    recordIdSet
                )
            );
        }
    }

    private Set<Id> recordIds = null;

    private PortalClientSharing( Set<Id> recordIdSet ) {
        this.recordIds = recordIdSet;
    }

    public void execute( QueueableContext context ) {
        if ( PortalClientSharing.isEnabled ) {
            this.calculateSharing();
        }
    }

    //
    // Internal Properties
    //

    private Schema.SObjectType soType {
        private get {
            if ( soType == null ) {
                Schema.SObjectType local = null;
                if ( ( this.recordIds != null )
                    && !this.recordIds.isEmpty()
                   )
                {
                    List<Id> recordIdList = new List<Id>( this.recordIds );
                    if ( ( recordIdList != null )
                        && !recordIdList.isEmpty()
                       )
                    {
                        local = recordIdList[0].getSObjectType();
                    }
                }
                soType = local;
            }
            return soType;
        }
        private set;
    }

    //
    // Primary Action
    //

    private void calculateSharing() {
        try {
            Set<Id> accountIds = this.pickAccountIds();
            List<Portal_Client__Share> existingShares = this.selectExistingShares();
            Map<Id,List<Portal_Client__c>> accountClientsMap = this.buildAccountPortalClientsMap( accountIds );
            List<Portal_Client__c> allClientsList = this.buildAllClientsList( accountClientsMap );
            Map<Id,User> contactUserMap = this.buildContactUserMap( accountClientsMap?.keySet() );
            Map<Id,Set<Id>> accountContactMap = this.buildAccountContactMap( contactUserMap?.keySet() );
            Map<Id,Set<Id>> portalClientUserMap = this.buildPortalClientUserMap(
                allClientsList ,
                accountContactMap ,
                contactUserMap
            );
            List<Portal_Client__Share> removalShares = this.buildRemovalShares( portalClientUserMap , existingShares );
            this.deleteShares( removalShares );
            List<Portal_Client__Share> shares = this.buildShares( portalClientUserMap );
            this.insertShares( shares );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                PortalClientSharing.class.getName() ,
                'action' ,
                e
            );
        }
    }

    //
    // Selection Helpers
    //

    private Set<Id> pickAccountIds() {
        Set<Id> accountIds = new Set<Id>();
        List<sObject> records = this.selectRecords( this.soType , this.recordIds );
        if ( records == null ) {
            records = new List<sObject>();
        }
        if ( this.soType != null ) {
            if ( this.soType == Account.getSObjectType() ) {
                // Account
                accountIds = this.recordIds;
            } else if ( this.soType == Portal_Client__c.getSObjectType() ) {
                // Portal_Client__c
                accountIds = this.pickAccountIds( records );
            } else if ( ( this.soType == AccountContactRelation.getSObjectType() )
                || ( this.soType == Contact.getSObjectType() )
                || ( this.soType == User.getSObjectType() )
                )
            {
                // AccountContactRelation
                // Contact
                // User
                Set<Id> contactIds = this.pickContactIds( records );
                List<AccountContactRelation> relations = [
                    SELECT Id , AccountId , ContactId
                    FROM AccountContactRelation
                    WHERE ( ContactId IN :contactIds )
                ];
                accountIds = this.pickAccountIds( relations );
            }
        }
        return accountIds;
    }

    private Set<Id> pickAccountIds( List<sObject> records ) {
        Set<Id> accountIds = new Set<Id>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( sObject record : records ) {
                Id accountId = null;
                if ( record.getSObjectType() == AccountContactRelation.getSObjectType() ) {
                    accountId = (Id)record.get( 'AccountId' );
                } else if ( record.getSObjectType() == Portal_Client__c.getSObjectType() ) {
                    accountId = (Id)record.get( 'Account__c' );
                }
                if ( accountId != null ) {
                    accountIds.add( accountId );
                }
            }
        }
        return accountIds;
    }

    private Set<Id> pickContactIds( List<sObject> records ) {
        Set<Id> contactIds = new Set<Id>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( sObject record : records ) {
                Id contactId = null;
                if ( record.getSObjectType() == AccountContactRelation.getSObjectType() ) {
                    contactId = (Id)record.get( 'ContactId' );
                } else if ( record.getSObjectType() == Contact.getSObjectType() ) {
                    contactId = (Id)record.get( 'Id' );
                } else if ( record.getSObjectType() == User.getSObjectType() ) {
                    contactId = (Id)record.get( 'ContactId' );
                }
                if ( contactId != null ) {
                    contactIds.add( contactId );
                }
            }
        }
        return contactIds;
    }

    private List<sObject> selectRecords( Schema.SObjectType selectionSObjectType , Set<Id> selectionIds ) {
        List<sObject> records = new List<sObject>();
        if ( ( selectionSObjectType != null )
            && ( selectionIds != null )
            && !selectionIds.isEmpty()
            )
        {
            if ( selectionSObjectType == Account.getSObjectType() ) {
                // Account
                records = [
                    SELECT Id
                    FROM Account
                    WHERE ( Id IN :selectionIds )
                ];
            } else if ( selectionSObjectType == AccountContactRelation.getSObjectType() ) {
                // AccountContactRelation
                records = [
                    SELECT Id , AccountId , ContactId
                    FROM AccountContactRelation
                    WHERE ( Id IN :selectionIds )
                ];
            } else if ( selectionSObjectType == Contact.getSObjectType() ) {
                // Contact
                records = [
                    SELECT Id
                    FROM Contact
                    WHERE ( Id IN :selectionIds )
                ];
            } else if ( selectionSObjectType == Portal_Client__c.getSObjectType() ) {
                // Portal_Client__c
                records = [
                    SELECT Id , Account__c
                    FROM Portal_Client__c
                    WHERE ( Id IN :selectionIds )
                ];
            } else if ( selectionSObjectType == User.getSObjectType() ) {
                // User
                records = [
                    SELECT Id , ContactId
                    FROM User
                    WHERE (
                        ( Id IN :selectionIds )
                        AND ( IsActive = true )
                        AND ( IsPortalEnabled = true )
                        AND ( ContactId != null )
                    )
                ];
            }
        }
        return records;
    }

    private List<Portal_Client__Share> selectExistingShares() {
        List<Portal_Client__Share> existingShares = new List<Portal_Client__Share>();
        if ( this.soType != null ) {
            if ( this.soType == Account.getSObjectType() ) {
                // Account
                existingShares = [
                    SELECT Id , ParentId , Parent.Name , UserOrGroupId , UserOrGroup.Name
                    FROM Portal_Client__Share
                    WHERE (
                        ParentId IN (
                            SELECT Id
                            FROM Portal_Client__c
                            WHERE ( Account__c IN :this.recordIds )
                        )
                    )
                    ORDER BY ParentId ASC , UserOrGroupId ASC
                ];
            } else if ( this.soType == AccountContactRelation.getSObjectType() ) {
                // AccountContactRelation
                List<AccountContactRelation> records = [
                    SELECT Id , AccountId , ContactId
                    FROM AccountContactRelation
                    WHERE ( Id IN :this.recordIds )
                ];
                Set<Id> contactIds = new Set<Id>();
                for ( AccountContactRelation record : records ) {
                    contactIds.add( record.ContactId );
                }
                //
                existingShares = [
                    SELECT Id , ParentId , Parent.Name , UserOrGroupId , UserOrGroup.Name
                    FROM Portal_Client__Share
                    WHERE (
                        UserOrGroupId IN (
                            SELECT Id
                            FROM User
                            WHERE ( ContactId IN :contactIds )
                        )
                    )
                    ORDER BY ParentId ASC , UserOrGroupId ASC
                ];
            } else if ( this.soType == Contact.getSObjectType() ) {
                // Contact
                existingShares = [
                    SELECT Id , ParentId , Parent.Name , UserOrGroupId , UserOrGroup.Name
                    FROM Portal_Client__Share
                    WHERE (
                        UserOrGroupId IN (
                            SELECT Id
                            FROM User
                            WHERE ( ContactId IN :this.recordIds )
                        )
                    )
                    ORDER BY ParentId ASC , UserOrGroupId ASC
                ];
            } else if ( this.soType == Portal_Client__c.getSObjectType() ) {
                // Portal_Client__c
                existingShares = [
                    SELECT Id , ParentId , Parent.Name , UserOrGroupId , UserOrGroup.Name
                    FROM Portal_Client__Share
                    WHERE ( ParentId IN :this.recordIds )
                    ORDER BY ParentId ASC , UserOrGroupId ASC
                ];
            } else if ( this.soType == User.getSObjectType() ) {
                // User
                existingShares = [
                    SELECT Id , ParentId , Parent.Name , UserOrGroupId , UserOrGroup.Name
                    FROM Portal_Client__Share
                    WHERE ( UserOrGroupId IN :this.recordIds )
                    ORDER BY ParentId ASC , UserOrGroupId ASC
                ];
            }
        }
        return existingShares;
    }

    //
    // Calculation Helpers
    //

    // build a map to translate from Account to all Portal Clients...
    // ~ Map from Account.Id to Portal_Client__c record...
    private Map<Id,List<Portal_Client__c>> buildAccountPortalClientsMap( Set<Id> accountIds ) {
        List<Portal_Client__c> clients = new List<Portal_Client__c>();
        if ( ( accountIds != null ) && !accountIds.isEmpty() ) {
            clients = [
                SELECT Id , Name , Account__c
                FROM Portal_Client__c
                WHERE ( Account__c IN :accountIds )
            ];
        } else {
            clients = [
                SELECT Id , Name , Account__c
                FROM Portal_Client__c
                WHERE ( Account__c != null )
            ];
        }
        Map<Id,List<Portal_Client__c>> accountClientsMap = new Map<Id,List<Portal_Client__c>>();
        for ( Portal_Client__c client : clients ) {
            if ( !accountClientsMap.containsKey( client.Account__c ) ) {
                accountClientsMap.put( client.Account__c , new List<Portal_Client__c>() );
            }
            accountClientsMap.get( client.Account__c ).add( client );

        }
        return accountClientsMap;
    }

    private List<Portal_Client__c> buildAllClientsList( Map<Id,List<Portal_Client__c>> accountClientsMap ) {
        List<Portal_Client__c> allClientsList = new List<Portal_Client__c>();
        if ( ( accountClientsMap != null ) && !accountClientsMap.isEmpty() ) {
            for ( Id accountId : accountClientsMap.keySet() ) {
                if ( ( accountClientsMap.get( accountId ) != null )
                    && !accountClientsMap.get( accountId ).isEmpty()
                    )
                {
                    allClientsList.addAll( accountClientsMap.get( accountId ) );
                }
            }
        }
        return allClientsList;
    }

    // based on a set of Accounts, build a map to translate from all related Contacts to their related Portal User...
    // ~ Map from Contact.Id to User record...
    private Map<Id,User> buildContactUserMap( Set<Id> accountIds ) {
        Map<Id,User> contactUserMap = new Map<Id,User>();
        if ( ( accountIds != null ) && !accountIds.isEmpty() ) {
            List<User> records = [
                SELECT Id , Name , ContactId
                FROM User
                WHERE (
                    ( IsActive = true )
                    AND ( IsPortalEnabled = true )
                    AND (
                        ContactId IN (
                            SELECT ContactId
                            FROM AccountContactRelation
                            WHERE ( AccountId IN :accountIds )
                        )
                    )
                )
            ];
            for ( User record : records ) {
                contactUserMap.put( record.ContactId , record );
            }
        }
        return contactUserMap;
    }

    // based on a set of Contacts, build a map to translate from Account to the set of related Contacts...
    // ~ Map from Account.Id to Set of Contact.Id values
    private Map<Id,Set<Id>> buildAccountContactMap( Set<Id> contactIds ) {
        Map<Id,Set<Id>> accountContactMap = new Map<Id,Set<Id>>();
        if ( ( contactIds != null ) && !contactIds.isEmpty() ) {
            List<AccountContactRelation> relations = [
                SELECT Id , AccountId , ContactId
                FROM AccountContactRelation
                WHERE ( ContactId IN :contactIds )
            ];
            for ( AccountContactRelation relation : relations ) {
                if ( !accountContactMap.containsKey( relation.AccountId ) ) {
                    accountContactMap.put( relation.AccountId , new Set<Id>() );
                }
                accountContactMap.get( relation.AccountId ).add( relation.ContactId );
            }
        }
        return accountContactMap;
    }

    // build a map to translate from Portal_Client__c to the set of permitted Users...
    // ~ Map from Portal_Client__c.Id to Set of User.Id values
    private Map<Id,Set<Id>> buildPortalClientUserMap(
        List<Portal_Client__c> clients ,
        Map<Id,Set<Id>> accountContactMap ,
        Map<Id,User> contactUserMap
        )
    {
        Map<Id,Set<Id>> portalClientUserMap = new Map<Id,Set<Id>>();
        if ( ( clients != null )
            && !clients.isEmpty()
            && ( accountContactMap != null )
            && !accountContactMap.isEmpty()
            )
        {
            for ( Portal_Client__c client : clients ) {
                if ( ( client.Account__c != null )
                    && accountContactMap.containsKey( client.Account__c )
                    )
                {
                    this.buildPortalClientUserMap(
                        portalClientUserMap ,
                        client ,
                        accountContactMap.get( client.Account__c ) ,
                        contactUserMap
                    );
                }
            }
        }
        return portalClientUserMap;
    }

    // helper method to defeat sonar cognitive complexity...
    private Map<Id,Set<Id>> buildPortalClientUserMap(
        Map<Id,Set<Id>> portalClientUserMap ,
        Portal_Client__c client ,
        Set<Id> contactIds ,
        Map<Id,User> contactUserMap
        )
    {
        if ( portalClientUserMap == null ) {
            portalClientUserMap = new Map<Id,Set<Id>>();
        }
        if ( ( contactIds != null )
            && !contactIds.isEmpty()
            && ( contactUserMap != null )
            )
        {
            for ( Id contactId : contactIds ) {
                if ( contactUserMap.containsKey( contactId ) ) {
                    this.buildPortalClientUserMap(
                        portalClientUserMap ,
                        client ,
                        contactUserMap.get( contactId )
                    );
                }
            }
        }
        return portalClientUserMap;
    }

    // helper method to defeat sonar cognitive complexity...
    private Map<Id,Set<Id>> buildPortalClientUserMap(
        Map<Id,Set<Id>> portalClientUserMap ,
        Portal_Client__c client ,
        User portalUser
        )
    {
        if ( portalClientUserMap == null ) {
            portalClientUserMap = new Map<Id,Set<Id>>();
        }
        if ( ( client != null ) && ( portalUser != null ) ) {
            if ( !portalClientUserMap.containsKey( client.Id ) ) {
                portalClientUserMap.put( client.Id , new Set<Id>() );
            }
            portalClientUserMap.get( client.Id ).add( portalUser.Id );
        }
        return portalClientUserMap;
    }

    //
    // Removal Helpers
    //

    // helper method to defeat sonar cognitive complexity...
    private List<Portal_Client__Share> buildRemovalShares( Map<Id,Set<Id>> portalClientUserMap , List<Portal_Client__Share> existingShares ) {
        List<Portal_Client__Share> removalShares = new List<Portal_Client__Share>();
        if ( ( existingShares != null ) && !existingShares.isEmpty() ) {
            if ( ( portalClientUserMap == null ) || portalClientUserMap.isEmpty() ) {
                // remove all existing shares when no shares should exist...
                removalShares = existingShares;
            }
            // build map from Portal_Client__c.Id to the List of existing related Portal_Client__Share records...
            Map<Id,List<Portal_Client__Share>> existingSharesMap = this.buildExistingSharesMap( existingShares );
            if ( ( portalClientUserMap != null ) && !portalClientUserMap.isEmpty() ) {
                for ( Id clientId : existingSharesMap.keySet() ) {
                    removalShares = this.buildRemovalShares(
                        removalShares ,
                        existingSharesMap.get( clientId ) , // the existing shares for a specific client...
                        portalClientUserMap.get( clientId ) // the required shares for a specific client...
                    );
                }
            }
        }
        return removalShares;
    }

    // build map from Portal_Client__c.Id to the List of existing related Portal_Client__Share records...
    // ~ Map from Portal_Client__c.Id to List of Portal_Client__Share
    private Map<Id,List<Portal_Client__Share>> buildExistingSharesMap( List<Portal_Client__Share> existingShares ) {
        Map<Id,List<Portal_Client__Share>> existingSharesMap = new Map<Id,List<Portal_Client__Share>>();
        if ( ( existingShares != null ) && !existingShares.isEmpty() ) {
            for ( Portal_Client__Share existingShare : existingShares ) {
                if ( !existingSharesMap.containsKey( existingShare.ParentId ) ) {
                    existingSharesMap.put( existingShare.ParentId , new List<Portal_Client__Share>() );
                }
                existingSharesMap.get( existingShare.ParentId ).add( existingShare );
            }
        }
        return existingSharesMap;
    }

    // helper method to defeat sonar cognitive complexity...
    private List<Portal_Client__Share> buildRemovalShares(
        List<Portal_Client__Share> removalShares ,
        List<Portal_Client__Share> existingShares ,
        Set<Id> portalUserIds
        )
    {
        if ( removalShares == null ) {
            // ensure non-null inputs to defeat sonar cognitive complexity...
            removalShares = new List<Portal_Client__Share>();
        }
        if ( existingShares == null ) {
            // ensure non-null inputs to defeat sonar cognitive complexity...
            existingShares = new List<Portal_Client__Share>();
        }
        if ( ( portalUserIds == null ) || portalUserIds.isEmpty() ) {
            // remove all existing shares for a specific client when no shares should exist for that client...
            removalShares.addAll( existingShares );
        }
        if ( ( portalUserIds != null ) && !portalUserIds.isEmpty() ) {
            // determine which specific shares should be removed for a specific client...
            for ( Portal_Client__Share existingShare : existingShares ) {
                if ( !portalUserIds.contains( existingShare.UserOrGroupId ) ) {
                    removalShares.add( existingShare );
                }
            }
        }
        return removalShares;
    }

    private void deleteShares( List<Portal_Client__Share> shares ) {
        if ( ( shares != null ) && !shares.isEmpty() ) {
            Savepoint sp = Database.setSavepoint();
            List<Database.DeleteResult> results = Database.delete( shares , false );
            if ( PortalClientSharing.isDryRun ) {
                System.debug( ' ~ PortalClientSharing.deleteShares ~ ROLLBACK ~ ' + sp );
                Database.rollback( sp );
            }
            NSP_ErrorLogHandler.logResults(
                PortalClientSharing.class.getName() ,
                'deleteShares' ,
                results
            );
        }
    }

    //
    // Creation Helpers
    //

    // helper method to defeat sonar cognitive complexity...
    private List<Portal_Client__Share> buildShares( Map<Id,Set<Id>> portalClientUserMap ) {
        List<Portal_Client__Share> shares = new List<Portal_Client__Share>();
        if ( ( portalClientUserMap != null ) && !portalClientUserMap.isEmpty() ) {
            for ( Id clientId : portalClientUserMap.keySet() ) {
                this.buildShares(
                    shares ,
                    clientId ,
                    portalClientUserMap.get( clientId )
                );
            }
        }
        return shares;
    }

    // helper method to defeat sonar cognitive complexity...
    private List<Portal_Client__Share> buildShares( List<Portal_Client__Share> shares , Id clientId , Set<Id> portalUserIds ) {
        if ( shares == null ) {
            shares = new List<Portal_Client__Share>();
        }
        if ( ( portalUserIds != null ) && !portalUserIds.isEmpty() ) {
            for ( Id portalUserId : portalUserIds ) {
                Portal_Client__Share share = this.buildShare(
                    clientId ,
                    portalUserId
                );
                if ( share != null ) {
                    shares.add( share );
                }
            }
        }
        return shares;
    }

    // helper method to defeat sonar cognitive complexity...
    private Portal_Client__Share buildShare( Id clientId , Id portalUserId ) {
        Portal_Client__Share share = null;
        if ( ( clientId != null ) && ( portalUserId != null ) ) {
            share = new Portal_Client__Share(
                ParentId=clientId ,
                UserOrGroupId=portalUserId ,
                AccessLevel='Edit' ,
                RowCause=Schema.Portal_Client__Share.RowCause.InsperitySharing__c
            );
        }
        return share;
    }

    private void insertShares( List<Portal_Client__Share> shares ) {
        if ( ( shares != null ) && !shares.isEmpty() ) {
            Savepoint sp = Database.setSavepoint();
            List<Database.SaveResult> results = Database.insert( shares , false );
            if ( PortalClientSharing.isDryRun ) {
                System.debug( ' ~ PortalClientSharing.insertShares ~ ROLLBACK ~ ' + sp );
                Database.rollback( sp );
            }
            NSP_ErrorLogHandler.logResults(
                PortalClientSharing.class.getName() ,
                'insertShares' ,
                results
            );
        }
    }

    //
    // Custom Settings
    //

    private static Portal_Client_Sharing_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Portal_Client_Sharing_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( PortalClientSharing.settings != null ) {
                    local = PortalClientSharing.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Boolean isDryRun {
        private get {
            if ( isDryRun == null ) {
                Boolean local = true;
                if ( PortalClientSharing.settings != null ) {
                    local = PortalClientSharing.settings.IsDryRun__c;
                }
                isDryRun = local;
            }
            return isDryRun;
        }
        private set;
    }

}
//