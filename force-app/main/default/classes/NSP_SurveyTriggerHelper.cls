/**
* Represents the Survey trigger helper which handles all the logic.
* Modification Log-
* DF-03278  Updated Case Record Type on 3/27/2023 
*/
public class NSP_SurveyTriggerHelper {
    
    public static final Id casePEORecordTypeId = NSP_GenericRecordType.getRecordTypeId('Case',NSP_ServiceConstants.PEO );
    public static final Id recordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Survey__c','CSAT');
    public static final Id TransitionProgressrecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Survey__c','Transition_Progress');
    private static final String YES = 'Yes';
    private static final String CLIENT_MANAGEMENT = 'Client Management';
    private static final String SATISFACTORY_SURVEY = 'Satisfaction Survey';
    /**
* Iterates throught the list of new  NSP_Survey__c and passes the required attributes to other methods.
* @param . 
* @param .   
* @return void             
*                
*/
    public void createCaseFromCSATSurveyResult(List<NSP_Survey__c> newSurveysList, Map<Id, NSP_Survey__c> newSurveyMap,  Map<Id, NSP_Survey__c> oldSurveyMap){
        if(newSurveysList == null){
            newSurveysList = newSurveyMap.values();
        }
        List<NSP_Survey__c> CSATSurveyLists = new List<NSP_Survey__c>();
        Set<Id> relatedAccountId = new Set<Id>();
        Set<String> caseSubjectStringSet = new Set<String>{'Client Requested a call',
         'The client’s Overall Satisfaction is Somewhat Satisfied',
          'The client’s Overall Satisfaction is Not Satisfied',
           'The Client would not recommend Insperity',
            'The Client’s likelihood of renewal is low',
            'Client Contact requested a call'}; //Added as part of DF-03788            
        Map<Id, NSP_Account_Team__c> accountWithAccountTeamMember = new Map<Id, NSP_Account_Team__c>();
        List<Case> newCaseList = new List<Case>();
        Map<Id, String> accountWithClientRequestedCase = new Map<Id, String>();
        Map<Id, String> accountWithSatisfactionCase = new Map<Id, String>();
        Map<Id, String> accountWithRecommendedCase = new Map<Id, String>();
        Map<Id, String> accountWithRenewCase = new Map<Id, String>();
        Map<Id, String> accountWithPEOCase = new Map<Id, String>();
        List<String> FIELDS = new List<String>{'Id'};    
        Group adminQueue = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.GroupType, NSP_ServiceConstants.ADMIN_QUEUE, FIELDS);
        Id queueId =adminQueue.Id;
        try{
            for(NSP_Survey__c newSurvey : newSurveysList){
                if((newSurvey.RecordTypeId == recordTypeId || newSurvey.RecordTypeId == TransitionProgressrecordTypeId) && String.isNotBlank(newSurvey.Account__c)){
                    CSATSurveyLists.add(newSurvey);
                    relatedAccountId.add(newSurvey.Account__c);
                }    
            }
            if(CSATSurveyLists.size() > 0 && relatedAccountId.size() > 0){
                for(NSP_Account_Team__c accountTeamMember : [SELECT ID, NSP_Role__c,NSP_Account__c, NSP_User__c 
                                                             FROM NSP_Account_Team__c WHERE NSP_Role__c = 'Manager, HR Services'
                                                             AND NSP_Account__c IN: relatedAccountId]){
                                                                 accountWithAccountTeamMember.put(accountTeamMember.NSP_Account__c, accountTeamMember);                                       
                                                                 
                                                             }
                for(Case ca : [SELECT Id, Subject, AccountId FROM Case WHERE Subject IN: caseSubjectStringSet AND AccountId IN: relatedAccountId]){      
                    if(ca.Subject == 'Client Requested a call'){
                        accountWithClientRequestedCase.put(ca.AccountId, ca.Subject);   
                    }else if(ca.Subject == 'The client’s Overall Satisfaction is Somewhat Satisfied' || ca.Subject == 'The client’s Overall Satisfaction is Not Satisfied'){
                        accountWithSatisfactionCase.put(ca.AccountId, ca.Subject);
                    }else if(ca.Subject == 'The Client would not recommend Insperity'){
                        accountWithRecommendedCase.put(ca.AccountId, ca.Subject);   
                    }else if(ca.Subject == 'The Client’s likelihood of renewal is low'){
                        accountWithRenewCase.put(ca.AccountId, ca.Subject);   
                    } else if(ca.Subject == 'Client Contact requested a call'){
                        accountWithPEOCase.put(ca.AccountId, ca.Subject);   
                    } 
                }
            }
            if(CSATSurveyLists.size() > 0 && relatedAccountId.size() > 0){
                for(NSP_Survey__c newSurvey : CSATSurveyLists){
                    if(newSurvey.RecordTypeId == recordTypeId){
                        if(accountWithClientRequestedCase.get(newSurvey.Account__c) == null &&
                           ((oldSurveyMap != null && 
                             oldSurveyMap.get(newSurvey.Id).Call_Requested__c != newSurvey.Call_Requested__c && 
                             newSurvey.Call_Requested__c == YES) ||
                            newSurvey.Call_Requested__c == YES)){
                                Case reqCase = createCaseRecord(newSurvey.Account__c, 
                                                                'Client Requested a call', 
                                                                CLIENT_MANAGEMENT, 
                                                                SATISFACTORY_SURVEY,
                                                                !accountWithAccountTeamMember.isEmpty() ? accountWithAccountTeamMember.get(newSurvey.Account__c).NSP_User__c : queueId,
                                                                casePEORecordTypeId);
                                newCaseList.add(reqCase);
                            }
                        
                        if(accountWithSatisfactionCase.get(newSurvey.Account__c) == null && 
                           ((oldSurveyMap != null &&
                             oldSurveyMap.get(newSurvey.Id).Overall_Satisfaction__c != newSurvey.Overall_Satisfaction__c &&
                             (newSurvey.Overall_Satisfaction__c == 'Somewhat Satisfied' || newSurvey.Overall_Satisfaction__c == 'Not Satisfied')) ||
                            (newSurvey.Overall_Satisfaction__c == 'Somewhat Satisfied' || newSurvey.Overall_Satisfaction__c == 'Not Satisfied'))){
                                Case overAllCase = createCaseRecord(newSurvey.Account__c, 
                                                                    'The client’s Overall Satisfaction is '+newSurvey.Overall_Satisfaction__c,
                                                                    CLIENT_MANAGEMENT, 
                                                                    SATISFACTORY_SURVEY,
                                                                    !accountWithAccountTeamMember.isEmpty() ? accountWithAccountTeamMember.get(newSurvey.Account__c).NSP_User__c : queueId,
                                                                    casePEORecordTypeId);
                                newCaseList.add(overAllCase);
                            }
                        
                        if(accountWithRecommendedCase.get(newSurvey.Account__c) == null && 
                           ((oldSurveyMap != null && 
                             oldSurveyMap.get(newSurvey.Id).Recommend__c != newSurvey.Recommend__c &&
                             (newSurvey.Recommend__c >= 0 && newSurvey.Recommend__c <= 6)) ||
                            (newSurvey.Recommend__c >= 0 && newSurvey.Recommend__c <= 6) )){
                                Case recomendCase = createCaseRecord(newSurvey.Account__c, 
                                                                     'The Client would not recommend Insperity', 
                                                                     CLIENT_MANAGEMENT,
                                                                     SATISFACTORY_SURVEY,
                                                                     !accountWithAccountTeamMember.isEmpty() ? accountWithAccountTeamMember.get(newSurvey.Account__c).NSP_User__c : queueId, 
                                                                     casePEORecordTypeId);
                                newCaseList.add(recomendCase);
                            }
                        
                        if(accountWithRenewCase.get(newSurvey.Account__c) == null && 
                           ((oldSurveyMap != null && 
                             oldSurveyMap.get(newSurvey.Id).Renew__c != newSurvey.Renew__c &&
                             (newSurvey.Renew__c == 'Disagree' || newSurvey.Renew__c == 'Strongly Disagree')) ||
                            (newSurvey.Renew__c == 'Disagree' || newSurvey.Renew__c == 'Strongly Disagree'))){
                                Case renewCase = createCaseRecord(newSurvey.Account__c, 
                                                                  'The Client’s likelihood of renewal is low', 
                                                                  CLIENT_MANAGEMENT, 
                                                                  SATISFACTORY_SURVEY,
                                                                  !accountWithAccountTeamMember.isEmpty() ? accountWithAccountTeamMember.get(newSurvey.Account__c).NSP_User__c : queueId,
                                                                  casePEORecordTypeId);
                                newCaseList.add(renewCase);
                            }
                    } else if(newSurvey.RecordTypeId == TransitionProgressrecordTypeId){
                        if(accountWithPEOCase.get(newSurvey.Account__c) == null && 
                           ((oldSurveyMap != null && 
                             oldSurveyMap.get(newSurvey.Id).NSP_Onboarding_Experience__c != newSurvey.NSP_Onboarding_Experience__c
                             && newSurvey.NSP_Onboarding_Experience__c == YES) ||
                            newSurvey.NSP_Onboarding_Experience__c == YES)){
                                Case transCase =createCaseRecord(newSurvey.Account__c, 
                                                                 'Client Contact requested a call',
                                                                 CLIENT_MANAGEMENT, 
                                                                 'Transition Progress Report', 
                                                                 System.Label.Transition_Progress_Survey_Case_Owner,
                                                                 casePEORecordTypeId);
                                newCaseList.add(transCase);
                            } 
                    }
                }
            }
            if(newCaseList.size() > 0){ 
                List<Database.SaveResult> results = Database.insert(newCaseList,false);
        NSP_ErrorLogHandler.logSaveResultsException('NSP_SurveyTriggerHelper', 'createCaseFromCSATSurveyResult', results);
            }
        }catch(Exception ex ){
            NSP_ErrorLogHandler.logSaveException('NSP_SurveyTriggerHelper', 'createCaseFromCSATSurveyResult', ex.getMessage());
        }
        
    }
    
    private Static case createCaseRecord(String accountId, String subject, String Category, String subCategory, String ownerId, String recTypeId){
        Case newCase = new Case();
        newCase.AccountId = accountId;
        newCase.Subject = subject;
        newCase.NSP_Category__c = Category;
        newCase.NSP_SubCategory__c = subCategory;
        newCase.OwnerId = ownerId;
        if(String.isNotBlank(recTypeId)){
            newCase.RecordTypeId = recTypeId;
        }
        return newCase;
    }
}