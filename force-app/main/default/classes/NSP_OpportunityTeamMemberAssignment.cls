// Description: This class describes about when the Opportunity owner is changing, then the new Opp Team should be created with team role = opportunity Owner and
// old owner team should be updated with the old owner user role.
public class NSP_OpportunityTeamMemberAssignment {
    
    public static final String OPP_TEAMMEMBER_ROLE = 'Opportunity Owner';
    public static final String OPP_TEAMMEMBER_ACCESS = 'Edit';

    // Description: This method describes about insertion of new Opportunity Team on Insertion of Opportunity.
    public static void insertOppTeamMember(List<Opportunity> newList){
        
        List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
        for( Opportunity nOpp : newList ){
            OpportunityTeamMember member = new OpportunityTeamMember();  
            member.OpportunityId = nOpp.Id;  
            member.UserId = nOpp.OwnerId;  
            member.TeamMemberRole = OPP_TEAMMEMBER_ROLE;  
            member.OpportunityAccessLevel = OPP_TEAMMEMBER_ACCESS; 
            oppTeamList.add(member);
        }
        
        if( !oppTeamList.isEmpty() ){
            try{
                Database.insert(oppTeamList);
            }catch(Exception ex){
                NSP_CustomException.LogException(ex);
            } 
        }
    }
    
    // Description: This method describes about insertion of new Opportunity Team on owner change of Opportunity 
    // and update of Old Opportunity team to the oser role name.
    public static void updateAndInsertOppTeamMember( Map<Id,Opportunity> newMap , Map<Id,Opportunity> oldMap ){
            
        List<OpportunityTeamMember> oOwnerOppTeamList = new List<OpportunityTeamMember> ();
        List<OpportunityTeamMember> nOwneroppTeamList = new List<OpportunityTeamMember> ();
        Map<Id,String> ownerIdRoleNameMap = new Map<Id, String>();
        Map<Id,OpportunityTeamMember> oppIdoppteamIdMap = new Map<Id, OpportunityTeamMember> (); 
        Map<Id,Id> oppIdOwnerIdMap = new Map<Id,Id>();
        for( Opportunity nOpp : newMap.values() ){
            if( nOpp.OwnerId != oldMap.get(nOpp.Id).OwnerId ){
                
                oppIdOwnerIdMap.put(nOpp.Id, oldMap.get(nOpp.Id).OwnerId); // Map of Opp Id and old Opp Owner
                
                OpportunityTeamMember member = new OpportunityTeamMember();  
                member.OpportunityId = nOpp.Id;  
                member.UserId = nOpp.OwnerId;  
                member.TeamMemberRole = OPP_TEAMMEMBER_ROLE;  
                member.OpportunityAccessLevel = OPP_TEAMMEMBER_ACCESS; 
                nOwneroppTeamList.add(member);
            }           
        }
        if( !oppIdOwnerIdMap.isEmpty() ){
            // Mapping userId and user role
            for( User oppOwner : [
                            SELECT
                                Id, 
                                Name,
                                Email,
                                Profile.Name,
                                Title,
                                UserRole.Name,
                                UserRole.Id
                            FROM User 
                            WHERE Id IN :oppIdOwnerIdMap.values()
                        ]
                )
            {
                ownerIdRoleNameMap.put(oppOwner.Id, oppOwner.UserRole.Name);
            }
            // Mapping OppId and Opp Team 
            for( OpportunityTeamMember oppTeamMem : [
                                                SELECT
                                                    Id, 
                                                    OpportunityAccessLevel,
                                                    TeamMemberRole,
                                                    UserId,
                                                    OpportunityId,
                                                    Opportunity.ownerId
                                                FROM OpportunityTeamMember  
                                                WHERE UserId IN : oppIdOwnerIdMap.values()
                                            ]
                )
            {
                oppIdoppteamIdMap.put(oppTeamMem.OpportunityId, oppTeamMem);
            }
            for( Opportunity opp : [SELECT Id,OwnerId FROM Opportunity WHERE ID IN: oppIdOwnerIdMap.keyset()] ){
                if( oppIdoppteamIdMap.containsKey( opp.Id ) ){
                    // Modified as a part of DF-01483
                    OpportunityTeamMember oppTeamMem = oppIdoppteamIdMap.get( opp.Id ) ;
                    if( NSP_OpportunityTeamMemberAssignment.oppTeamRoleValues.contains( ownerIdRoleNameMap.get( oppTeamMem.UserId ) ) ){
                        oppTeamMem.TeamMemberRole = ownerIdRoleNameMap.get( oppTeamMem.UserId );
                    }else{
                        // assigning 'Other' Role to the opportunity Team Member after the owner is hetting changed
                        oppTeamMem.TeamMemberRole = NSP_SalesConstants.OpportunityTeamMemberRole;
                    }
                    oppTeamMem.OpportunityAccessLevel = OPP_TEAMMEMBER_ACCESS;
                    oOwnerOppTeamList.add(oppTeamMem); 
                }
            }

            if( !oOwnerOppTeamList.isEmpty() ){
                try{
                    Database.update(oOwnerOppTeamList);
                }catch(Exception ex){
                    NSP_CustomException.LogException(ex);
                }
            }
            if( !nOwneroppTeamList.isEmpty() ){
                try{
                    Database.insert(nOwneroppTeamList);
                }catch(Exception ex){
                    NSP_CustomException.LogException(ex);
                }
            }
        }
    }

    private static List<String> oppTeamRoleValues {
        private get {
            if ( oppTeamRoleValues == null ) {
                oppTeamRoleValues = new List<String>();
                Schema.DescribeFieldResult fieldResult = OpportunityTeamMember.TeamMemberRole.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple ){
                    oppTeamRoleValues.add( pickListVal.getLabel() );
                }
            }
            return oppTeamRoleValues;
        }
        private set;
    }
}