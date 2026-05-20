// intentionally `without sharing` to see all AccountContactRelations, Contacts, and Users for successful provisioning...
public without sharing class PortalProvisionAction {
    // test w/ PortalProvisionActionTest (89%)

    private static String UNKNOWN_PROVISIONING_ERROR = 'Unknown Provisioning Error';

    //
    //
    //

    @InvocableMethod(label='Provision Portal User' description='Create Portal User from Account Contact Relationship for Contact with Portal Alias.')
    public static List<FlowOutput> provision( List<FlowInput> inputs ) {
        List<FlowOutput> results = new List<FlowOutput>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( FlowInput input : inputs ) {
                String response = PortalProvisionAction.provision( input.recordId );
                FlowOutput result = new FlowOutput();
                if ( String.isNotBlank( response )
                    && ( response InstanceOf Id )
                    && ( Id.valueOf( response ).getSObjectType() == User.getSObjectType() )
                    )
                {
                    result.userId = response;
                } else {
                    result.errorMessage = response;
                }
                results.add( result );
            }
        }
        return results;
    }

    public class FlowInput {
        @InvocableVariable(label='Record Id' description='is-a AccountContactRelation.Id' required=true)
        public String recordId;
    }

    public class FlowOutput {
        @InvocableVariable(label='Portal User Id' description='is-a User.Id')
        public String userId;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    //
    // Sonar Helpers
    //

    private static String provision( String recordId ) {
        String response = PortalProvisionAction.UNKNOWN_PROVISIONING_ERROR;
        AccountContactRelation relation = PortalProvisionAction.selectRelation( recordId );
        if ( relation == null ) {
            response = 'Missing AccountContactRelation (Id=' + recordId + ')';
        } else if ( String.isBlank( relation.NSP_Work_Email__c ) ) {
            response = 'Missing Work Email (Id=' + recordId + ')';
        } else {
            response = PortalProvisionAction.provision( relation );
        }
        return response;
    }

    private static String provision( AccountContactRelation relation ) {
        String response = PortalProvisionAction.UNKNOWN_PROVISIONING_ERROR;
        Contact record = PortalProvisionAction.selectContact( relation?.ContactId );
        if ( record == null ) {
            response = 'Missing Contact (Id=' + relation?.ContactId + ')';
        } else if ( String.isBlank( record.AccountId ) ) {
            response = 'Contact Must Have Account (Id=' + record.Id + ')';
        } else if ( String.isBlank( record.Account.OwnerId ) ) {
            response = 'Contact Account Must Have Owner (AccountId=' + record.AccountId + ')';
        } else if ( String.isBlank( record.Account.Owner.UserRoleId ) ) {
            response = 'Account Owner Must Have Role (AccountId=' + record.AccountId + ', Account.OwnerId=' + record.Account.OwnerId + ')';
        } else if ( String.isBlank( record.LastName ) ) {
            response = 'Missing Last Name (Id=' + record.Id + ')';
        } else if ( String.isBlank( record.NSP_Preferred_First_Name__c ) ) {
            response = 'Missing Preferred First Name (Id=' + record.Id + ')';
        } else if ( String.isBlank( record.Portal_Alias__c ) ) {
            response = 'Missing Portal Alias (Id=' + record.Id + ')';
        } else if ( !PortalProvisionAction.validatePortalAlias( record.Portal_Alias__c ) ) {
            response = 'Invalid Portal Alias (Id=' + record.Id + ', Portal_Alias__c=' + record.Portal_Alias__c + ')';
        } else if ( ( record.Users != null ) && !record.Users.isEmpty() ) {
            response = 'Portal User already provisioned (Id=' + record.Users[0].Id + ')';
        } else {
            response = PortalProvisionAction.provision(
                record ,
                relation
            );
        }
        return response;
    }

    private static String provision( Contact record , AccountContactRelation relation ) {
        String response = PortalProvisionAction.UNKNOWN_PROVISIONING_ERROR;
        User portalUser = PortalProvisionAction.buildPortalUser(
            record ,
            relation
        );
        if ( portalUser == null ) {
            response = 'Failed to construct Portal User (Id=' + relation?.ContactId + ')';
        } else {
            response = PortalProvisionAction.createPortalUser( portalUser );
        }
        return response;
    }

    //
    // Helper Methods
    //

    private static AccountContactRelation selectRelation( String recordId ) {
        AccountContactRelation record = null;
        if ( ( recordId != null ) && ( recordId InstanceOf Id ) ) {
            List<AccountContactRelation> records = [
                SELECT
                    Id ,
                    AccountId ,
                    Account.Name ,
                    ContactId ,
                    Contact.Name ,
                    Contact.Portal_Alias__c ,
                    Contact.NSP_Preferred_First_Name__c ,
                    Contact.LastName ,
                    NSP_Work_email__c ,
                    CreatedDate ,
                    LastModifiedDate
                FROM AccountContactRelation
                WHERE ( Id = :recordId )
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];
            if ( ( records != null ) && !records.isEmpty() ) {
                record = records[0];
            }
        }
        return record;
    }

    private static Contact selectContact( String recordId ) {
        Contact record = null;
        if ( ( recordId != null ) && ( recordId InstanceOf Id ) ) {
            List<Contact> records = [
                SELECT
                    Id ,
                    AccountId ,
                    Account.OwnerId ,
                    Account.Owner.UserRoleId ,
                    Portal_Alias__c ,
                    NSP_Preferred_First_Name__c ,
                    LastName ,
                    (
                        SELECT Id
                        FROM Users
                        ORDER BY CreatedDate ASC
                        LIMIT 1
                    ) ,
                    CreatedDate ,
                    LastModifiedDate
                FROM Contact
                WHERE ( Id = :recordId )
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];
            if ( ( records != null ) && !records.isEmpty() ) {
                record = records[0];
            }
        }
        return record;
    }

    //
    // Contact.Portal_Alias__c is precomputed by Portal_Access Flow
    // ~ maximum of 30-characters...
    // ~ format: lastname.autonumber
    // ~ lastname maximum of 20-characters
    // ~ autonumber maximum of 9-characters
    //
    private static Boolean validatePortalAlias( String alias ) {
        return (
            String.isNotBlank( alias )
            && alias.contains( '.' )
            && ( alias.countMatches( '.' ) == 1 )
            && ( alias.length() <= 30 )
            && ( alias.substringBeforeLast( '.' ).length() <= 20 )
            && ( alias.substringAfterLast( '.' ).length() <= 9 )
        );
    }

    //
    // Contact.Portal_Alias__c is precomputed by Portal_Access Flow
    // ~ maximum of 30-characters...
    // ~ format: lastname.autonumber
    // ~ lastname maximum of 20-characters
    // ~ autonumber maximum of 9-characters
    //
    // User.CommunityNickname will be the Contact.Portal_Alias__c
    //
    // User.Alias will be first 8-characters of User.CommunityNickname
    //
    // User.Username ~ Text(80) ~ lastname.autonumber@portal.insperity.com.sandboxapi
    // ~ 32 ~ @portal.insperity.com.sandboxapi
    // ~ 21 ~ @portal.insperity.com
    // ~ 10 ~ sandboxapi
    //
    // User.FederationIdentifier will be User.Username without the sandboxapi suffix
    //
    // User.Email will be with .invalid in sandbox for non-insperity domains
    //
    private static User buildPortalUser( Contact record , AccountContactRelation relation ) {
        User portalUser = null;
        if ( ( record != null )
            && record.isSet( Contact.Portal_Alias__c )
            && PortalProvisionAction.validatePortalAlias( record.Portal_Alias__c )
            && record.isSet( Contact.NSP_Preferred_First_Name__c )
            && String.isNotBlank( record.NSP_Preferred_First_Name__c )
            && record.isSet( Contact.LastName )
            && String.isNotBlank( record.LastName )
            && ( relation != null )
            && relation.isSet( AccountContactRelation.NSP_Work_email__c )
            && String.isNotBlank( relation.NSP_Work_email__c )
            && ( PortalProvisionAction.communityProfileId != null )
            )
        {
            //
            // create a community nickname with less than or equal to 40 characters maximum...
            // ~ User.CommunityNickname must be unique across the org...
            // ~ User.CommunityNickname will be the prefix of the User.Username...
            // ~ keep all letters, numbers, periods, and set to lowercase...
            String communityNickname = record.Portal_Alias__c.replaceAll( '[^a-zA-Z0-9.]' , '' ).toLowerCase();
            //
            // create an alias with less than or equal to 8 characters maximum...
            // ~ User.Alias is not required to be unique...
            String alias = communityNickname;
            if ( String.isNotBlank( alias ) && ( alias.length() > 8 ) ) {
                alias = alias.substring( 0 , 8 );
            }
            //
            // create a username with less than or equal to 80 characters maximum...
            // ~ User.Username must be unique across the entire salesforce ecosystem...
            // ~ use community nickname as the prefix...
            // ~ use sandbox api name as the suffix...
            String suffix = '';
            if ( String.isNotBlank( SetupAuditTrailQueueable.sandboxName ) ) {
                suffix = '.' + SetupAuditTrailQueueable.sandboxName.toLowerCase();
            }
            String federationIdentifier = communityNickname + '@portal.insperity.com';
            String username = federationIdentifier + suffix;
            //
            // create a sandbox safe email address...
            // ~ append .invalid when creating users in sandboxes with emails outside of the @insperity.com domain...
            String email = relation.NSP_Work_email__c;
            if ( String.isNotBlank( SetupAuditTrailQueueable.sandboxName )
                && !email.toLowerCase().endsWith( '@insperity.com' )
                )
            {
                email = email + '.invalid';
            }
            //
            portalUser = new User();
            portalUser.ContactId = record.Id;
            portalUser.ProfileId = PortalProvisionAction.communityProfileId;
            portalUser.FederationIdentifier = federationIdentifier;
            portalUser.UserName = userName;
            portalUser.Email = email;
            portalUser.Alias = SchemaController.safeText(
                alias ,
                sObjectType.User.Fields.Alias
            );
            portalUser.CommunityNickname = SchemaController.safeText(
                communityNickname ,
                sObjectType.User.Fields.CommunityNickname
            );
            portalUser.FirstName = SchemaController.safeText(
                record.NSP_Preferred_First_Name__c ,
                sObjectType.User.Fields.FirstName
            );
            portalUser.LastName = SchemaController.safeText(
                record.LastName ,
                sObjectType.User.Fields.LastName
            );
            portalUser.EmailEncodingKey = 'UTF-8';
            portalUser.LanguageLocaleKey = 'en_US';
            portalUser.LocaleSidKey = 'en_US';
            portalUser.TimeZoneSidKey = 'America/Chicago';
        }
        return portalUser;
    }

    //
    // User Operations
    //

    private static String createPortalUser( User portalUser ) {
        String response = PortalProvisionAction.UNKNOWN_PROVISIONING_ERROR;
        try {
            Savepoint sp = Database.setSavepoint();
            if ( portalUser != null ) {
                insert portalUser; // logging this database result to NSP_Error_Log__c would throw MIXED_DML_OPERATION...
                response = portalUser.Id;
                PortalProvisionAction.grantPortalSiteAccess( portalUser );
                PortalProvisionAction.setPortalPassword( portalUser );
            }
            if ( PortalProvisionAction.isDryRun ) {
                System.debug( ' ~ PortalProvisionAction.createPortalUser ~ ROLLBACK ~ ' + sp );
                Database.rollback( sp );
                response = '[DRY-RUN]' + response;
            }
        } catch ( Exception e ) {
            response = ''
                + 'Type: ' + e.getTypeName() + '\n'
                + 'Message: ' + e.getMessage() + '\n' + '\n'
                + 'Stack Trace: ' + e.getStackTraceString()
                ;
            // logging this exception to NSP_Error_Log__c would throw MIXED_DML_OPERATION...
        }
        return response;
    }

    // Assign Permission Set: Portal Site Access
    private static void grantPortalSiteAccess( User portalUser ) {
        if ( portalUser != null ) {
            insert new PermissionSetAssignment(
                PermissionSetId=PortalProvisionAction.portalSiteAccessId ,
                AssigneeId=portalUser.Id
            ); // logging this database result to NSP_Error_Log__c would throw MIXED_DML_OPERATION...
        }
    }

    // Set Default Password
    // ~ place holder logic until we have the notify step in place...
    private static void setPortalPassword( User portalUser ) {
        if ( portalUser != null ) {
            System.setPassword( portalUser.Id , 'Insperity1!!' ); // default portal password...
        }
    }

    //
    // Helper Properties
    //

    //
    //
    //

    private static Portal_Access_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Portal_Access_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isDryRun {
        private get {
            if ( isDryRun == null ) {
                Boolean local = false;
                if ( PortalProvisionAction.settings != null ) {
                    local = PortalProvisionAction.settings.IsDryRun__c;
                }
                isDryRun = local;
            }
            return isDryRun;
        }
        private set;
    }

    private static Id communityProfileId {
        private get {
            if ( communityProfileId == null ) {
                Id local = null;
                if ( ( PortalProvisionAction.settings != null )
                    && String.isNotBlank( PortalProvisionAction.settings.CommunityProfileId__c )
                    && ( PortalProvisionAction.settings.CommunityProfileId__c InstanceOf Id )
                    && ( Id.valueOf( PortalProvisionAction.settings.CommunityProfileId__c ).getSObjectType() == Profile.getSObjectType() )
                    )
                {
                    local = PortalProvisionAction.settings.CommunityProfileId__c;
                }
                communityProfileId = local;
            }
            return communityProfileId;
        }
        private set;
    }

    private static String membershipPermissionSetName {
        private get {
            if ( membershipPermissionSetName == null ) {
                String local = null;
                if ( ( PortalProvisionAction.settings != null )
                    && String.isNotBlank( PortalProvisionAction.settings.MembershipPermissionSetName__c )
                    )
                {
                    local = PortalProvisionAction.settings.MembershipPermissionSetName__c;
                }
                membershipPermissionSetName = local;
            }
            return membershipPermissionSetName;
        }
        private set;
    }

    private static Id portalSiteAccessId {
        private get {
            if ( portalSiteAccessId == null ) {
                Id local = null;
                if ( String.isNotBlank( PortalProvisionAction.membershipPermissionSetName ) ) {
                    List<PermissionSet> parents = [
                        SELECT Id
                        FROM PermissionSet
                        WHERE ( Name = :PortalProvisionAction.membershipPermissionSetName )
                        LIMIT 1
                    ];
                    if ( ( parents != null ) && !parents.isEmpty() ) {
                        local = parents[0].Id;
                    }
                }
                portalSiteAccessId = local;
            }
            return portalSiteAccessId;
        }
        private set;
    }

    //
    //
    //

}
//