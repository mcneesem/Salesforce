// intentionally `without sharing` to see all AccountContactRelations, Contacts, and Users for successful provisioning...
public without sharing class PortalPermitAction {
    // test w/ PortalPermitActionTest (86%)

    private static String UNKNOWN_PERMITTING_ERROR = 'Unknown Permitting Error';

    //
    //
    //

    @InvocableMethod(label='Permit Portal User' description='Manage Permission Set Assignments for Portal User.')
    public static List<FlowOutput> permit( List<FlowInput> inputs ) {
        List<FlowOutput> results = new List<FlowOutput>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( FlowInput input : inputs ) {
                String response = PortalPermitAction.permit(
                    input.recordId ,
                    input.selectedPermissionSets
                );
                Boolean isSuccess = (
                    String.isNotBlank( response )
                    && ( response InstanceOf Id )
                    && ( Id.valueOf( response ).getSObjectType() == User.getSObjectType() )
                );
                FlowOutput result = new FlowOutput();
                result.isSuccess = isSuccess;
                if ( isSuccess ) {
                    result.assignedPermissionSets = String.join(
                        PortalPermitAction.getPortalAssignmentNames( response ) ,
                        ';'
                    );
                } else {
                    result.errorMessage = response;
                }
                results.add( result );
            }
        }
        return results;
    }

    public class FlowInput {
        @InvocableVariable(label='Record Id' description='is-a User.Id' required=true)
        public String recordId;
        @InvocableVariable(label='Selected Permission Set API Names' description='is-a semi-colon (;) delimited String of PermissionSet.Names')
        public String selectedPermissionSets;
    }

    public class FlowOutput {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
        @InvocableVariable(label='Assigned Permission Set API Names' description='is-a semi-colon (;) delimited String of PermissionSet.Names')
        public String assignedPermissionSets;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    //
    // Sonar Helpers
    //

    private static String permit( String recordId , String selections ) {
        String response = PortalPermitAction.UNKNOWN_PERMITTING_ERROR;
        User record = PortalPermitAction.selectUser( recordId );
        Set<String> sanitizedSelections = PortalPermitAction.sanitizeSelections( selections );
        if ( record == null ) {
            response = 'Missing User (Id=' + recordId + ')';
        } else if ( sanitizedSelections == null ) {
            response = 'Invalid Selections (' + selections + ')';
        } else {
            response = PortalPermitAction.permit( record?.Id , sanitizedSelections );
        }
        return response;
    }

    private static String permit( String recordId , Set<String> selections ) {
        List<PermissionSetAssignment> assignments = PortalPermitAction.selectAssignments( recordId );
        // determine which assignments to remove...
        List<PermissionSetAssignment> removalAssignments = PortalPermitAction.buildRemovalPortalAssignments(
            selections ,
            assignments
        );
        // determine which assignments to create...
        List<PermissionSetAssignment> creationAssignments = PortalPermitAction.buildCreationPortalAssignments(
            recordId ,
            selections ,
            PortalPermitAction.getPortalAssignmentNames( assignments )
        );
        // perform DML operations...
        return PortalPermitAction.permit(
            recordId ,
            removalAssignments ,
            creationAssignments
        );
    }

    private static String permit(
        String recordId ,
        List<PermissionSetAssignment> removalAssignments ,
        List<PermissionSetAssignment> creationAssignments
        )
    {
        String response = PortalPermitAction.UNKNOWN_PERMITTING_ERROR;
        try {
            Savepoint sp = Database.setSavepoint();
            if ( !removalAssignments?.isEmpty() ) {
                delete removalAssignments; // logging this database result to NSP_Error_Log__c would throw MIXED_DML_OPERATION...
            }
            if ( !creationAssignments?.isEmpty() ) {
                insert creationAssignments; // logging this database result to NSP_Error_Log__c would throw MIXED_DML_OPERATION...
            }
            response = recordId;
            if ( PortalPermitAction.isDryRun ) {
                System.debug( ' ~ PortalPermitAction.permit ~ ROLLBACK ~ ' + sp );
                Database.rollback( sp );
                response = '[DRY-RUN]' + response;
            }
        } catch ( Exception e ) {
            response = 'Type: ' + e.getTypeName() + '\n'
                + 'Message: ' + e.getMessage() + '\n' + '\n'
                + 'Stack Trace: ' + e.getStackTraceString()
                ;
            // logging this exception to NSP_Error_Log__c would throw MIXED_DML_OPERATION...
        }
        return response;
    }

    //
    //
    //

    // ensure selection input is limited to allowed Portal Permission Sets...
    private static Set<String> sanitizeSelections( String selections ) {
        Set<String> sanitized = new Set<String>();
        if ( String.isNotBlank( selections ) ) {
            List<String> selectionsSplit = selections.split( ';' );
            if ( !selectionsSplit?.isEmpty() ) {
                sanitized = new Set<String>( selectionsSplit );
            }
            sanitized.retainAll( PortalPermitAction.portalPermissionSetMap.keySet() );
        }
        return sanitized;
    }

    //
    //
    //

    // determine which assignments to remove...
    private static List<PermissionSetAssignment> buildRemovalPortalAssignments(
        Set<String> selections ,
        List<PermissionSetAssignment> assignments
        )
    {
        List<PermissionSetAssignment> removals = new List<PermissionSetAssignment>();
        if ( selections == null ) {
            selections = new Set<String>();
        }
        if ( ( assignments != null ) && !assignments.isEmpty() ) {
            for ( PermissionSetAssignment assignment : assignments ) {
                if ( ( assignment.Id != null )
                    && ( assignment.PermissionSet != null )
                    && String.isNotBlank( assignment.PermissionSet.Name )
                    && PortalPermitAction.portalPermissionSetMap.containsKey( assignment.PermissionSet.Name )
                    && !selections.contains( assignment.PermissionSet.Name )
                )
                {
                    removals.add(
                        new PermissionSetAssignment(
                            Id=assignment.Id
                        )
                    );
                }
            }
        }
        return removals;
    }

    //
    //
    //

    // determine which assignments to create...
    private static List<PermissionSetAssignment> buildCreationPortalAssignments(
        String recordId ,
        Set<String> selections ,
        Set<String> current
        )
    {
        if ( current == null ) {
            current = new Set<String>();
        }
        List<PermissionSetAssignment> creations = new List<PermissionSetAssignment>();
        if ( String.isNotBlank( recordId )
            && ( recordId InstanceOf Id )
            && ( selections != null )
            && !selections.isEmpty()
            )
        {
            for ( String selection : selections ) {
                if ( !current.contains( selection )
                    && PortalPermitAction.portalPermissionSetMap.containsKey( selection )
                    && ( PortalPermitAction.portalPermissionSetMap.get( selection ) != null )
                )
                {
                    PermissionSet selectedPermissionSet = PortalPermitAction.portalPermissionSetMap.get( selection );
                    if ( selectedPermissionSet != null ) {
                        creations.add(
                            new PermissionSetAssignment(
                                PermissionSetId=selectedPermissionSet.Id ,
                                AssigneeId=recordId
                            )
                        );
                    }
                }
            }
        }
        return creations;
    }

    //
    //
    //

    private static Set<String> getPortalAssignmentNames( String recordId ) {
        return PortalPermitAction.getPortalAssignmentNames(
            PortalPermitAction.selectAssignments( recordId )
        );
    }

    private static Set<String> getPortalAssignmentNames( List<PermissionSetAssignment> assignments ) {
        Set<String> names = new Set<String>();
        if ( ( assignments != null ) && !assignments.isEmpty() ) {
            for ( PermissionSetAssignment assignment : assignments ) {
                names.add( assignment.PermissionSet.Name );
            }
        }
        names.retainAll( PortalPermitAction.portalPermissionSetMap.keySet() );
        return names;
    }

    //
    // Helper Methods
    //

    private static User selectUser( String recordId ) {
        User record = null;
        if ( ( recordId != null ) && ( recordId InstanceOf Id ) ) {
            List<User> records = [
                SELECT
                    Id ,
                    CreatedDate ,
                    LastModifiedDate
                FROM User
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

    private static List<PermissionSetAssignment> selectAssignments( String userId ) {
        List<PermissionSetAssignment> assignments = null;
        if ( ( userId != null ) && ( userId InstanceOf Id ) ) {
            assignments = [
                SELECT
                    Id ,
                    PermissionSetId ,
                    PermissionSet.Name ,
                    AssigneeId ,
                    SystemModstamp
                FROM PermissionSetAssignment
                WHERE (
                    ( AssigneeId = :userId )
                    AND ( PermissionSet.PermissionSetGroupId = null ) // true sources only...
                    AND ( PermissionSet.ProfileId = null ) // true sources only...
                )
                ORDER BY SystemModstamp DESC
            ];
        }
        return assignments;
    }

    //
    //
    //

    private static List<PermissionSet> portalPermissionSets {
        private get {
            if ( portalPermissionSets == null ) {
                List<PermissionSet> local = [
                    SELECT
                        Id ,
                        Name ,
                        SystemModstamp
                    FROM PermissionSet
                    WHERE ( Name IN :PortalPermitAction.allowedPermissionSetNames )
                ];
                if ( local == null ) {
                    local = new List<PermissionSet>();
                }
                portalPermissionSets = local;
            }
            return portalPermissionSets;
        }
        private set;
    }

    private static Map<String,PermissionSet> portalPermissionSetMap {
        private get {
            if ( portalPermissionSetMap == null ) {
                Map<String,PermissionSet> local = new Map<String,PermissionSet>();
                if ( ( PortalPermitAction.portalPermissionSets != null )
                    && !PortalPermitAction.portalPermissionSets.isEmpty()
                    )
                {
                    for ( PermissionSet ps : PortalPermitAction.portalPermissionSets ) {
                        local.put( ps.Name , ps );
                    }
                }
                portalPermissionSetMap = local;
            }
            return portalPermissionSetMap;
        }
        private set;
    }

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
                if ( PortalPermitAction.settings != null ) {
                    local = PortalPermitAction.settings.IsDryRun__c;
                }
                isDryRun = local;
            }
            return isDryRun;
        }
        private set;
    }

    private static List<String> allowedPermissionSetNames  {
        private get {
            if ( allowedPermissionSetNames == null ) {
                List<String> local = new List<String>();
                if ( PortalPermitAction.settings != null ) {
                    String rawAllowedPermissionSetNames = PortalPermitAction.settings.AllowedPermissionSetNames__c;
                    if ( String.isNotBlank( rawAllowedPermissionSetNames ) ) {
                        List<String> splitAllowedPermissionSetNames = rawAllowedPermissionSetNames.split( '\r\n' );
                        if ( ( splitAllowedPermissionSetNames != null ) && ( splitAllowedPermissionSetNames.size() > 0 ) ) {
                            local = splitAllowedPermissionSetNames;
                        }
                    }
                }
                allowedPermissionSetNames = local;
            }
            return allowedPermissionSetNames;
        }
        private set;
    }

}
//