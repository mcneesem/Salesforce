public with sharing class NSP_CaseService {
    
    public final String fieldValidationError = 'field is required for this Case Type';

    public Case fillCaseBasedOnType(Case oCase){
        if(oCase != null){
            return fillCasesBasedOnType(new List<Case>{oCase})[0];
        }else{
            return null;
        }
    }

    public List<Case> fillCasesBasedOnType(List<Case> lCases){
        Set<String> sTypes = new Set<String>();
        Set<Id> sAccountIds = new Set<Id>();
        
        for(Case oCase : lCases){
            sTypes.add(oCase.Type);
            if(oCase.AccountId != null){
                sAccountIds.add(oCase.AccountId);
            }
        }

        List<NSP_Case_Configuration__mdt> lCaseConfigurations = new List<NSP_Case_Configuration__mdt>([SELECT Label,NSP_Subject__c,NSP_Assigned_To__c,NSP_Category__c,NSP_Contact__c,
        NSP_Covid_19__c,NSP_Detail__c,NSP_Email_Sent__c,NSP_Email__c,NSP_Level_2__c,NSP_Origin__c,NSP_Phone__c,NSP_Priority__c,NSP_Root_Cause__c,NSP_Status__c,NSP_External_Id__c,
        NSP_Sub_Category__c,NSP_Sub_Status__c,NSP_Time_Entry__c,NSP_User_Notes__c FROM NSP_Case_Configuration__mdt WHERE Label in : sTypes]);
        
        Map<String,Set<String>> mObjectToFields = new Map<String,Set<String>>();
        mObjectToFields.put('User',new Set<String>());
        mObjectToFields.put('Queue',new Set<String>());
        
        // GET USERS/QUEUE NAMES TO GET THE ID
        Map<String,NSP_Case_Configuration__mdt> mNameToConfig  = new Map<String,NSP_Case_Configuration__mdt>();
        for(NSP_Case_Configuration__mdt oCaseConfig : lCaseConfigurations){
            mNameToConfig.put(oCaseConfig.Label,oCaseConfig);
            if(oCaseConfig.NSP_Assigned_To__c != null){
                Map<String,String> mFieldConfig = (Map<String,String>)JSON.deserialize(oCaseConfig.NSP_Assigned_To__c,Map<String,String>.class);
                mObjectToFields.get(mFieldConfig.get('object')).add(mFieldConfig.get('value'));
            }
        }
        Map<String,User> mUsers = new Map<String,User>();
        Map<String,Group> mQueues = new  Map<String,Group>();
        Map<Id,Account> mAccounts = new Map<Id,Account>();

        if(mObjectToFields.get('User').size() > 0){
            List<User> lUsers = new List<User>([SELECT Id,Name FROM User WHERE Name in : mObjectToFields.get('User')]);
            for(User oUser: lUsers){
                mUsers.put(oUser.Name,oUser);
            }
        }

        if(mObjectToFields.get('Queue').size() > 0){
            List<Group> lQueues = new List<Group>([SELECT Id,Name FROM Group WHERE Name in : mObjectToFields.get('Queue') AND Type = 'Queue']);
            for(Group oQueue: lQueues){
                mQueues.put(oQueue.Name,oQueue);
            }
        }

        if(sAccountIds.size() > 0){
            mAccounts = new Map<Id,Account>([SELECT Name,AccountNumber,NSP_AIMS_Client__c FROM Account WHERE Id in : sAccountIds]);
        }

        for(Case oCase : lCases){
            NSP_Case_Configuration__mdt oCaseConfig = mNameToConfig.get(oCase.Type);
            if(oCaseConfig == null){
                continue;
            }
            Account oAccount = mAccounts.get(oCase.AccountId);
            if(oAccount == null){
                if(!String.isBlank(oCaseConfig.NSP_Subject__c)){
                    oCase.Subject = oCaseConfig.NSP_Subject__c.replace('<NAME>', '').replace('<CLIENTNUMBER>','');
                }
                if(!String.isBlank(oCaseConfig.NSP_User_Notes__c)){
                    oCase.NSP_User_Notes__c = oCaseConfig.NSP_User_Notes__c.replace('<NAME>', '').replace('<CLIENTNUMBER>','');
                }
            }else{
                String oClientNumber = String.isBlank(oAccount.NSP_AIMS_Client__c) ? '' : oAccount.NSP_AIMS_Client__c;
                if(oCaseConfig.NSP_Subject__c != null){
                    oCase.Subject = oCaseConfig.NSP_Subject__c.replace('<NAME>', oAccount.Name).replace('<CLIENTNUMBER>',oClientNumber);
                }
                if(oCaseConfig.NSP_User_Notes__c != null){
                    oCase.NSP_User_Notes__c = oCaseConfig.NSP_User_Notes__c.replace('<NAME>', oAccount.Name).replace('<CLIENTNUMBER>',oClientNumber);
                }
            }
            
            
            if(oCaseConfig.NSP_Assigned_To__c != null){
                Map<String,String> mFieldConfig = (Map<String,String>)JSON.deserialize(oCaseConfig.NSP_Assigned_To__c,Map<String,String>.class);
                if(mFieldConfig.get('object') == 'User' && mUsers.get(mFieldConfig.get('value')) != null){
                    oCase.OwnerId = mUsers.get(mFieldConfig.get('value')).Id;
                }else if(mFieldConfig.get('object') == 'Queue' && mQueues.get(mFieldConfig.get('value')) != null){
                    oCase.OwnerId = mQueues.get(mFieldConfig.get('value')).Id;
                }
            }

            updateCaseField(oCase, 'ContactId', oCaseConfig.NSP_Contact__c);
            //updateCaseField(oCase, 'Email__c', oCaseConfig.NSP_Email__c);
            //updateCaseField(oCase, 'ContactPhone', oCaseConfig.NSP_Phone__c);
            updateCaseField(oCase, 'Status', oCaseConfig.NSP_Status__c);
            updateCaseField(oCase, 'NSP_Case_Sub_Status__c', oCaseConfig.NSP_Sub_Status__c);


            updateCaseField(oCase, 'Priority', oCaseConfig.NSP_Priority__c);
            updateCaseField(oCase, 'Origin', oCaseConfig.NSP_Origin__c);
            updateCaseField(oCase, 'NSP_Category__c', oCaseConfig.NSP_Category__c);
            updateCaseField(oCase, 'NSP_SubCategory__c', oCaseConfig.NSP_Sub_Category__c);
            updateCaseField(oCase, 'NSP_Detail__c', oCaseConfig.NSP_Detail__c);
            updateCaseField(oCase, 'NSP_Root_Cause__c', oCaseConfig.NSP_Root_Cause__c);
            updateCaseField(oCase, 'NSP_Covid_19__c', oCaseConfig.NSP_Covid_19__c);
            updateCaseField(oCase, 'NSP_External_Id__c', oCaseConfig.NSP_External_Id__c);
            oCase.NSP_L2__c = oCaseConfig.NSP_Level_2__c;
        }
        return lCases;
    }

    void updateCaseField(Case oCase,String field,String value){
        if(!String.isBlank(value)){
            if(value == '<CLEAR>'){
                oCase.put(field,null);
            }else{
                oCase.put(field,value);
            }                
        }
    }
}