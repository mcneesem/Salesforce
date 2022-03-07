/*
*@Description: This class describes about when the Opportunity owner is changing, then the new Opp Team should be created with team role = opportunity Owner and
old owner team should be updated with the old owner user role.
@createdDate: 01/18/2022
@Story : STY-02066
*/
public class NSP_OpportunityTeamMemberAssignment {
    
    public static final String OPP_TEAMMEMBER_ROLE = 'Opportunity Owner';
    public static final String OPP_TEAMMEMBER_ACCESS = 'Edit';
    
    /*
*@Description: This method describes about insertion of new Opportunity Team on Insertion of Opportunity.
@createdDate: 01/18/2022
@Story : STY-02066
*/
    public static void insertOppTeamMember(List<Opportunity> newList){
        
        List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
        for(Opportunity nOpp : newList){
            OpportunityTeamMember member = new OpportunityTeamMember();  
            member.OpportunityId = nOpp.Id;  
            member.UserId = nOpp.OwnerId;  
            member.TeamMemberRole = OPP_TEAMMEMBER_ROLE;  
            member.OpportunityAccessLevel = OPP_TEAMMEMBER_ACCESS; 
            oppTeamList.add(member);
        }
        
        if(!oppTeamList.isEmpty()){
            try{
                Database.insert(oppTeamList);
            }catch(Exception ex){
                NSP_CustomException.LogException(ex);
            } 
        }
    }
    
    /*
*@Description: This method describes about insertion of new Opportunity Team on owner change of Opportunity and updation of Old Opportunity team to the oser role name.
@createdDate: 01/18/2022
@Story : STY-02066
*/
    public static void updateAndInsertOppTeamMember(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap){
        
        List<OpportunityTeamMember> oOwnerOppTeamList = new List<OpportunityTeamMember> ();
        List<OpportunityTeamMember> nOwneroppTeamList = new List<OpportunityTeamMember> ();
        Map<Id,String> ownerIdRoleNameMap = new Map<Id, String>();
        Map<Id,OpportunityTeamMember> oppIdoppteamIdMap = new Map<Id, OpportunityTeamMember> (); 
        Map<Id,Id> oppIdOwnerIdMap = new Map<Id,Id>();
        
        for(Opportunity nOpp : newMap.values()){
            if(nOpp.OwnerId != oldMap.get(nOpp.Id).OwnerId){
                
                oppIdOwnerIdMap.put(nOpp.Id, oldMap.get(nOpp.Id).OwnerId); // Map of Opp Id and Opp Owner
                
                OpportunityTeamMember member = new OpportunityTeamMember();  
                member.OpportunityId = nOpp.Id;  
                member.UserId = nOpp.OwnerId;  
                member.TeamMemberRole = OPP_TEAMMEMBER_ROLE;  
                member.OpportunityAccessLevel = OPP_TEAMMEMBER_ACCESS; 
                nOwneroppTeamList.add(member);
            }           
        }
        if(!oppIdOwnerIdMap.isEmpty()){
            // Mapping userId and user role
            for(User oppOwner : [SELECT Id, 
                                 		Name, 
                                 		Email, 
                                 		Profile.Name,
                                 		UserRole.Name,
                                 		UserRole.Id 
                                 		FROM User 
                                 		WHERE Id IN :oppIdOwnerIdMap.values()]){
                                     ownerIdRoleNameMap.put(oppOwner.Id, oppOwner.UserRole.Name);
                                 }
            // Mapping OppId and Opp Team 
            for(OpportunityTeamMember oppTeamMem : [SELECT Id, 
                                                    OpportunityAccessLevel,
                                                    TeamMemberRole,
                                                    UserId,
                                                    OpportunityId,
                                                    Opportunity.ownerId
                                                    FROM OpportunityTeamMember  
                                                    WHERE UserId IN : oppIdOwnerIdMap.values()]){
                                                        oppIdoppteamIdMap.put(oppTeamMem.OpportunityId, oppTeamMem);
                                                    }
            for(Opportunity opp : [SELECT Id,OwnerId FROM Opportunity WHERE ID IN: oppIdOwnerIdMap.keyset() ]){
                if(oppIdoppteamIdMap.containsKey(opp.Id)){
                    OpportunityTeamMember oppTeamMem =oppIdoppteamIdMap.get(opp.Id) ; 
                    oppTeamMem.TeamMemberRole = ownerIdRoleNameMap.get(oppTeamMem.UserId);
                    oppTeamMem.OpportunityAccessLevel = 'Edit';
                    oOwnerOppTeamList.add(oppTeamMem); 
                }
            }
            
            if(!oOwnerOppTeamList.isEmpty()){
                try{
                    Database.update(oOwnerOppTeamList);
                }catch(Exception ex){
                    NSP_CustomException.LogException(ex);
                } 
            }
            if(!nOwneroppTeamList.isEmpty()){
                try{
                    Database.insert(nOwneroppTeamList);
                }catch(Exception ex){
                    NSP_CustomException.LogException(ex);
                } 
            } 
        }      
    }
    
}