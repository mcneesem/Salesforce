public with sharing class NSP_SurveySubjectTriggerHelper {
    public final String caseObjectType = 'Case';
    // Minimum Access Required to View Responses it Read/Write on Invitation and Read on Survey
    public final String accessLevel = 'Edit';


    /**
    * Iterates throught the list of new SurveySubjects and passes the required attributes to other methods.
    * @param lSurveySubjects List of New SurveySubjects
    * @param mSurveySubjects Map of New SurveySubjects
    * @return void             
    *                
    */
    public void afterInsertFilter(List<SurveySubject> lSurveySubjects,Map<Id,SurveySubject> mSurveySubjects){
        Map<Id,SurveySubject> mChatSurveySubjects = new Map<Id,SurveySubject>();
        Set<Id> sCaseIds = new Set<Id>();
        for(SurveySubject oSurveySubject: lSurveySubjects){
            if(oSurveySubject.SubjectEntityType == caseObjectType){
                mChatSurveySubjects.put(oSurveySubject.Id,oSurveySubject);
                sCaseIds.add(oSurveySubject.SubjectId);
            }
        }
        if(mChatSurveySubjects.keySet().size() > 0){
            shareSubjectsWithCaseOwner(mChatSurveySubjects,sCaseIds);
        }
    }
    /**
    * Shares the List of Survey to the Chat Owners
    * @param lSurveySubjects List of New SurveySubjects
    * @return void            
    *                
    */
    public void shareSubjectsWithCaseOwner(Map<Id,SurveySubject> mSurveySubjects,Set<Id> sCaseIds){
        List<Case> lCases = (List<Case>)NSP_PerformActionWithoutShare.queryWithoutShare('SELECT Id,OwnerId FROM Case WHERE Id in: sIds', sCaseIds);
        Map<Id,Case> mCases = new Map<Id,Case>(lCases);
        Map<Id,Id> mSurveyInvitationToUsers = new Map<Id,Id>();
        for(SurveySubject oSurveySubject : mSurveySubjects.values()){
            mSurveyInvitationToUsers.put(oSurveySubject.ParentId,mCases.get(oSurveySubject.SubjectId).OwnerId);
        }
        //SHARING LOGIC
        List<SurveyInvitationShare> lSurveyInvitationShares = new List<SurveyInvitationShare>();
        for(Id iSurveyInvitation : mSurveyInvitationToUsers.keySet()){
            lSurveyInvitationShares.add(new SurveyInvitationShare(ParentId = iSurveyInvitation,UserOrGroupId = mSurveyInvitationToUsers.get(iSurveyInvitation),AccessLevel = accessLevel));
        }
        if(lSurveyInvitationShares.size() > 0){
            NSP_PerformActionWithoutShare.insertWithoutShare(lSurveyInvitationShares);
        }
    }
}