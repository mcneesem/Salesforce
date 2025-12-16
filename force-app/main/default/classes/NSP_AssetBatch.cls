public with sharing class NSP_AssetBatch implements Database.Batchable<Sobject>, Database.Stateful {

    public final String PEORECORDTYPE = 'PEO';
    public final String HRSPECIALISTROLE = 'HR Specialist';
    public final String BTHRSPECIALISTROLE = 'Bus. Team-HRSp/CL';
    public final String MHRSPECIALISTROLE = 'Manager, HR Services';
    public final List<String> lAccountTeamRoles = new List<String>{HRSPECIALISTROLE,BTHRSPECIALISTROLE,MHRSPECIALISTROLE};
    public final String VALIDATEBIOMETRICSUBJECT = 'Validate Biometric Consent form removed from OEE; Discuss removal of handbook policy w/ client';
    public final String HRSERVICECATEGORY = 'HR Services';
    public final String HRINFRASTRUCTURESUBCATEGORY = 'HR Infrastructure';
    public final String CLIENTGUIDANCE = 'Client Guidance';
    public final String AIMS = 'AIMS';
    private String failure = '';

    public Database.QueryLocator start(Database.BatchableContext BC){
        Date today = System.today().addDays(-1);
        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        List<String> FIELDS = new List<String>{'Id','AccountId','NSP_Biometric_End_Date__c','RecordTypeId'};
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Asset', FIELDS)
            .addFilter('NSP_Biometric_Indicator_Expired__c', false)
            .addFilter('AccountId', NULL, NSP_QueryBuilder.Operator.NOT_EQUALS,false)
            .addFilter('RecordTypeId', woRecordTypeId)
            .setSecurityEnforce(false);
        String queryString = queryBuilder.build();
        queryString += ' AND NSP_Biometric_End_Date__c =: today';
        return Database.getQueryLocator(queryString);
    }
    public void execute(Database.BatchableContext BC, List<Asset> lAssets){

        try{
            Set<Id> sAccountIds = new Set<Id>();
            for(Asset oAsset : lAssets){
                sAccountIds.add(oAsset.AccountId);
            }

            Id peoRecordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(PEORECORDTYPE)?.getRecordTypeId();

            if(sAccountIds.size() == 0){
                return;
            }

            List<NSP_Account_Team__c> lAccountTeams = new List<NSP_Account_Team__c>([SELECT Id,NSP_Account__c,NSP_Role__c,NSP_User__c,NSP_Primary__c FROM NSP_Account_Team__c WHERE NSP_Account__c IN : sAccountIds AND NSP_Role__c IN : lAccountTeamRoles AND NSP_Integrated_With__c =: AIMS]);

            Map<Id,Map<String,Id>> mAccountToUsers = new Map<ID,Map<String,Id>>();
            Map<Id,Map<String,Boolean>> mAccountToValues = new Map<ID,Map<String,Boolean>>();
            for(NSP_Account_Team__c oAccountTeam: lAccountTeams){
                if(oAccountTeam.NSP_User__c == null){
                    continue;
                }
                if( mAccountToUsers.get(oAccountTeam.NSP_Account__c) != null ){
                    mAccountToUsers.get(oAccountTeam.NSP_Account__c).put(oAccountTeam.NSP_Role__c,oAccountTeam.NSP_User__c);
                    mAccountToValues.get(oAccountTeam.NSP_Account__c).put(oAccountTeam.NSP_Role__c,oAccountTeam.NSP_Primary__c);
                }else {
                    mAccountToUsers.put(oAccountTeam.NSP_Account__c,new Map<String,Id>{oAccountTeam.NSP_Role__c => oAccountTeam.NSP_User__c});
                    mAccountToValues.put(oAccountTeam.NSP_Account__c,new Map<String,Boolean>{oAccountTeam.NSP_Role__c => oAccountTeam.NSP_Primary__c});
                }
            }

            List<Case> lCases = new List<Case>();
            for(Asset oAsset : lAssets){
                oAsset.NSP_Biometric_Indicator_Expired__c = true;
                Map<String,Id> mAccountTeamUsers = mAccountToUsers.get(oAsset.AccountId);
                Map<String, Boolean> mAccountTeamValues = mAccountToValues.get(oAsset.AccountId);
                Id caseOwnerId = getCaseOwnerId(mAccountTeamUsers, mAccountTeamValues);
                lCases.add(new Case(Subject=VALIDATEBIOMETRICSUBJECT,OwnerId = caseOwnerId,NSP_Category__c = HRSERVICECATEGORY,NSP_SubCategory__c = HRINFRASTRUCTURESUBCATEGORY,NSP_Detail__c = CLIENTGUIDANCE,RecordTypeId = peoRecordTypeId,AssetId = oAsset.Id,AccountId = oAsset.AccountId));
            }

            update lAssets;
            if(lCases.size() > 0){
                insert lCases;
            }
        }catch(Exception ex){
            failure += '\n' + ex.getMessage() + '' + ex.getStackTraceString();
        }
    }

    public Id getCaseOwnerId(Map<String,Id> mAccountTeamUsers, Map<String, Boolean> mAccountTeamValues){
        Id caseOwnerId = UserInfo.getUserId();
        if(mAccountTeamUsers != null){
            if(mAccountTeamUsers.get(HRSPECIALISTROLE) != null && mAccountTeamUsers.get(BTHRSPECIALISTROLE) != null){
                caseOwnerId = true == mAccountTeamValues.get(HRSPECIALISTROLE)?
                    mAccountTeamUsers.get(HRSPECIALISTROLE)
                    : mAccountTeamUsers.get(BTHRSPECIALISTROLE);
            }else if(mAccountTeamUsers.get(HRSPECIALISTROLE) != null){
            caseOwnerId = mAccountTeamUsers.get(HRSPECIALISTROLE);
            }else if(mAccountTeamUsers.get(BTHRSPECIALISTROLE) != null){
                caseOwnerId = mAccountTeamUsers.get(BTHRSPECIALISTROLE);
            }else if(mAccountTeamUsers.get(MHRSPECIALISTROLE) != null){
                caseOwnerId = mAccountTeamUsers.get(MHRSPECIALISTROLE);
            }
    }
        return caseOwnerId;
    }

    public void finish( Database.BatchableContext bc ) {
        // SEND EMAIL FOR FAILED RECORDS
        if ( String.isNotBlank( failure )
            && ( EmailDeliverabilityController.IsEnabledOutbound )
            )
        {
            Messaging.SingleEmailMessage oEmail = new Messaging.SingleEmailMessage();
            oEmail.setSubject('Asset Batch Failed');
            oEmail.setTargetObjectId(UserInfo.getUserId());
            oEmail.setSaveAsActivity(false);
            oEmail.setPlainTextBody(failure);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{oEmail});
        }
    }

}
//