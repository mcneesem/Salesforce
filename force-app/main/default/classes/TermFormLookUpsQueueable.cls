//
// ClassName:TermFormLookUpsQueueable
// @description: Represents the Termination Form and Account Team trigger Roles/Users
// @date: 10/11/2024
// @author: Roberto Rivero
//
public class TermFormLookUpsQueueable implements Queueable {
    // test w/ NSP_AccountTeamTriggerTest (90%)

    private Set<Id> accountId;
    private Map<String,Id> newRolesMap;
    private List<NSP_Account_Team__c> oldMap;

    public TermFormLookUpsQueueable( Set<Id> accountId , Map<String,Id> newRolesMap , List<NSP_Account_Team__c> oldMap ) {
        this.accountId = accountId;
        this.newRolesMap = newRolesMap;
        this.oldMap = oldMap;
    }

    public void execute( QueueableContext context ) {
        Map<Id,NSP_Termination_Form__c> accountToTerminationFormMap = new Map<Id, NSP_Termination_Form__c>();
        Map<String,List<Id>> oldRolesMap = new Map<String,List<Id>>();
        List<Id> oldRolesList;
        List<NSP_Termination_Form__c> updateTermForm = new List<NSP_Termination_Form__c>();
        List<NSP_Termination_Form__c> terminationForms = [
            SELECT
                Id , NSP_Account__c , NSP_Payroll_Specialist__c , NSP_Insperity_Blended_Role__c ,
                NSP_Supervisor__c , NSP_Client_Liaison__c , NSP_Manager_HR_Services__c ,
                NSP_Account_Executive__c , NSP_Credit_Specialist__c , NSP_Sales_Representative__c
            FROM NSP_Termination_Form__c
            WHERE (
                ( NSP_Account__c IN :this.accountId )
                AND ( NSP_Status__c != :NSP_ServiceConstants.TERM_SUPERVISOR_APPROVED )
                AND ( NSP_Project_Task__c NOT IN (
                        SELECT Id
                        FROM pse__Project_Task__c
                        WHERE ( pse__Status__c = :NSP_ServiceConstants.TASKCOMPLETE )
                    )
                )
            )
        ];
        // Get previous Role values
        if ( this.oldMap != null ) {
            for ( NSP_Account_Team__c oldAccTeam : this.oldMap ) {
                if ( !oldRolesMap.containsKey( oldAccTeam.NSP_Role__c ) ) {
                    oldRolesMap.put( oldAccTeam.NSP_Role__c , new List<Id>() );
                }
                oldRolesMap.get( oldAccTeam.NSP_Role__c ).add( oldAccTeam.NSP_User__c );
            }
        }
        if ( ( terminationForms != null )
            && !terminationForms.isEmpty()
            && ( this.newRolesMap != null )
            )
        {
            // Iterate through Account key
            for ( NSP_Termination_Form__c mapTermForm : terminationForms ) {
                if ( this.newRolesMap.containsKey(NSP_ServiceConstants.PAYROLL_SUPERVISOR)
                    && mapTermForm.NSP_Supervisor__c != null
                    && oldRolesMap.containsKey( NSP_ServiceConstants.PAYROLL_SUPERVISOR )
                    && oldRolesMap.get( NSP_ServiceConstants.PAYROLL_SUPERVISOR ).contains( mapTermForm.NSP_Supervisor__c )
                    )
                {
                    mapTermForm.NSP_Supervisor__c = this.newRolesMap.get( NSP_ServiceConstants.PAYROLL_SUPERVISOR );
                }
                if ( this.newRolesMap.containsKey(NSP_ServiceConstants.PAYROLL_SPECIALIST)
                    && mapTermForm.NSP_Payroll_Specialist__c != null
                    && oldRolesMap.containsKey( NSP_ServiceConstants.PAYROLL_SPECIALIST )
                    && oldRolesMap.get( NSP_ServiceConstants.PAYROLL_SPECIALIST ).contains( mapTermForm.NSP_Payroll_Specialist__c )
                    )
                {
                    mapTermForm.NSP_Payroll_Specialist__c = this.newRolesMap.get( NSP_ServiceConstants.PAYROLL_SPECIALIST );
                }
                if ( this.newRolesMap.containsKey(NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR)
                    && mapTermForm.NSP_Sales_Representative__c != null
                    && oldRolesMap.containsKey( NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR )
                    && oldRolesMap.get( NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR ).contains( mapTermForm.NSP_Sales_Representative__c )
                    )
                {
                    mapTermForm.NSP_Sales_Representative__c = this.newRolesMap.get( NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR );
                }
                if ( this.newRolesMap.containsKey(NSP_ServiceConstants.CLIENT_LIAISION)
                    && mapTermForm.NSP_Client_Liaison__c != null
                    && oldRolesMap.containsKey( NSP_ServiceConstants.CLIENT_LIAISION )
                    && oldRolesMap.get( NSP_ServiceConstants.CLIENT_LIAISION ).contains( mapTermForm.NSP_Client_Liaison__c )
                    )
                {
                    mapTermForm.NSP_Client_Liaison__c = this.newRolesMap.get( NSP_ServiceConstants.CLIENT_LIAISION );
                }
                if ( this.newRolesMap.containsKey(NSP_ServiceConstants.MID_MARKET_ACC_EX)
                    && mapTermForm.NSP_Account_Executive__c != null
                    && oldRolesMap.containsKey( NSP_ServiceConstants.MID_MARKET_ACC_EX )
                    && oldRolesMap.get( NSP_ServiceConstants.MID_MARKET_ACC_EX ).contains( mapTermForm.NSP_Account_Executive__c )
                    )
                {
                    mapTermForm.NSP_Account_Executive__c = this.newRolesMap.get( NSP_ServiceConstants.MID_MARKET_ACC_EX );
                }
                if ( this.newRolesMap.containsKey(NSP_ServiceConstants.MANAGER_HRSERVICES)
                    && mapTermForm.NSP_Manager_HR_Services__c != null
                    && oldRolesMap.containsKey( NSP_ServiceConstants.MANAGER_HRSERVICES )
                    && oldRolesMap.get( NSP_ServiceConstants.MANAGER_HRSERVICES ).contains( mapTermForm.NSP_Manager_HR_Services__c )
                    )
                {
                    mapTermForm.NSP_Manager_HR_Services__c = this.newRolesMap.get( NSP_ServiceConstants.MANAGER_HRSERVICES );
                }
                if ( this.newRolesMap.containsKey(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)
                    && mapTermForm.NSP_Insperity_Blended_Role__c != null
                    && oldRolesMap.containsKey( NSP_ServiceConstants.BUS_TEAM_HRSP_CL )
                    && oldRolesMap.get( NSP_ServiceConstants.BUS_TEAM_HRSP_CL ).contains( mapTermForm.NSP_Insperity_Blended_Role__c )
                    )
                {
                    mapTermForm.NSP_Insperity_Blended_Role__c = this.newRolesMap.get( NSP_ServiceConstants.BUS_TEAM_HRSP_CL );
                }
                updateTermForm.add( mapTermForm );
            }
        }
        if ( !updateTermForm.isEmpty() ) {
            try {
                Database.SaveResult[] results = Database.update(updateTermForm, false);
                NSP_ErrorLogHandler.logResults(
                    TermFormLookUpsQueueable.class.getName() ,
                    'execute' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    TermFormLookUpsQueueable.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

}
//