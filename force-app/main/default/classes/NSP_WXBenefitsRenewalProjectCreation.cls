/**
Apex Class Name      :  NSP_WXBenefitsRenewalProjectCreation
Version              :  1.0 
Author               :  Simran
Function             :  Creates Project with WX Rebewal Template
Story                :  As part of STY-02160                                                                  

*/
public class NSP_WXBenefitsRenewalProjectCreation implements Schedulable,Database.Batchable<sObject> {
    
    private static Set<Id> astAccountId = new Set<Id>();
    private static final List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> lProjRequests = new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>();
    private static final Map<String, NSP_Account_Team__c> mapOfBenefitsAccIdAccTeam = new Map<String, NSP_Account_Team__c>();
    private static Map<String, List< NSP_Account_Team__c>> mapOfAccIdListAccTeam = new Map<String, List< NSP_Account_Team__c>>();
    private static List<pse__Proj__c> lstProjToInsert = new List<pse__Proj__c>();
    private static final List<String> toEmailAddressList = new List<String>();
    
    @TestVisible
    private NSP_OpportunityTriggerServiceHelper opp = new NSP_OpportunityTriggerServiceHelper();
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        Id WX_RECORDTYPE_ID = NSP_GenericRecordType.getRecordTypeId('Asset', 'NSP_Asset_Product');
        List<String> ASSET_FIELDS = new List<String>{
            'Id', 'NSP_Benefits_Renewal_Date__c',
                'RecordTypeId', 'AccountId' 
                };
                    date reqDate = system.today().addDays(65);
        String query = new NSP_QueryBuilder('Asset', ASSET_FIELDS)
            .addFilter('RecordTypeId', WX_RECORDTYPE_ID)
        .addFilter('NSP_Benefits_Renewal_Date__c', String.valueOf(reqDate), NSP_QueryBuilder.Operator.EQUALS, false)
            .build();
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Asset> listOfAssets){
        List<String> TEMPLATE_FIELDS = new List<String>{
            'Id', 'Key__c','Template_ID__c',
                'Template_Name__c' 
                };
                    String query = new NSP_QueryBuilder('Template_Key_and_Id_Mapping__mdt', TEMPLATE_FIELDS)
                    .addFilter('Key__c', NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ)
                    .addFilter('NSP_From_Object__c', NSP_ServiceConstants.FROM_OBJECT_ASSET)
                    .setSecurityEnforce(false)
                    .build();
        List<Template_Key_and_Id_Mapping__mdt> oTempKey = (List<Template_Key_and_Id_Mapping__mdt>)Database.query(query);
        
        for(Asset asset: listOfAssets){
            astAccountId.add(asset.AccountId);
            //Creating Project with WX Renewal Project Template
            pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest =
                new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(asset.AccountId, oTempKey[0].Template_ID__c, System.Today());
            projRequest.ProjectName = NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ;
            lProjRequests.add(projRequest); 
            
        }
        try{
            if (!lProjRequests.isEmpty()){
                Set<Id> projectId = opp.createProjectAndDeleteBudget(lProjRequests);
                assigningProjTasks(projectId);
            }
        }catch (Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_WXBenefitsRenewalProjectCreation', 'execute', ex.getMessage());            
        } 
    }
    
    public void assigningProjTasks(Set<Id> newProjId){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Set<Id> benefitAccIdSet = new Set<Id>();
        List<Id> lstAccountIds = new List<Id>();
        List<Id> lstnewProjIds = new List<Id>();
        lstAccountIds.addAll(astAccountId);
        lstnewProjIds.addAll(newProjId);
        List<String> accTeam = new List<String>{'Id', 'NSP_User__c', 'NSP_Role__c', 'NSP_Account__c','NSP_Primary__c' };
            String accountTeam = new NSP_QueryBuilder('NSP_Account_Team__c', accTeam)
            .addFilter('NSP_Account__c', lstAccountIds, NSP_QueryBuilder.Operator.INCLUDES)
            .orderby('NSP_Primary__c', 'DESC', false) 
            .build();
        for(NSP_Account_Team__c oAccountTeam : Database.query(accountTeam)){
            if(oAccountTeam.NSP_Role__c == NSP_ServiceConstants.BENEFITS_SPECIALIST && !mapOfBenefitsAccIdAccTeam.containsKey(oAccountTeam.NSP_Account__c)){
                if(oAccountTeam.NSP_Primary__c){
                    mapOfBenefitsAccIdAccTeam.put(oAccountTeam.NSP_Account__c, oAccountTeam);
                    benefitAccIdSet.add(oAccountTeam.NSP_Account__c);
                }else{
                    mapOfBenefitsAccIdAccTeam.put(oAccountTeam.NSP_Account__c, oAccountTeam);  
                    benefitAccIdSet.add(oAccountTeam.NSP_Account__c);
                }
            }   
        } 
        //removing those account id which have benefit specialist as an account team record
        astAccountId.removeAll(benefitAccIdSet);
        Set<Id> projToSendEmail = new Set<Id>();

        List<String> projField = new List<String>{'Id','Name', 'TemplateName__c','pse__Account__c','pse__Start_Date__c' , 'recordTypeId', 'Project_Implementer__c'};
        String projObj = new NSP_QueryBuilder('pse__Proj__c', projField)
        .addFilter('TemplateName__c', NSP_ServiceConstants.WX_BENEFIT_RENEW_PROJ)
        .addFilter('Id', lstnewProjIds , NSP_QueryBuilder.Operator.INCLUDES)
        .build();
        //Assignment of Implementer Field If Role is not Benefit Specialist
        for(pse__Proj__c proj : Database.query(projObj)){
            if(!mapOfBenefitsAccIdAccTeam.isEmpty() && mapOfBenefitsAccIdAccTeam.containsKey(proj.pse__Account__c)){
                proj.Project_Implementer__c = mapOfBenefitsAccIdAccTeam.get(proj.pse__Account__c).NSP_User__c;
                lstProjToInsert.add(proj);
            }else if(astAccountId.contains(proj.pse__Account__c)){
                projToSendEmail.add(proj.Id);    
            }                      
            
        }
        
        if (!lstProjToInsert.isEmpty()){
            List<Database.SaveResult> results = Database.update(lstProjToInsert, false);
            NSP_ErrorLogHandler.logSaveResult('NSP_WXBenefitsRenewalProjectCreation', 'assigningProjTasks', results );
        }        
        if(!projToSendEmail.isEmpty()){
            emails  = sendMailNotification(projToSendEmail);
            if(emails.size()>0) {
                NSP_GenericEmailUtility.sendSingleEmailMessages(emails,false); //method to send emails
            }
        }
    }
    
    //sending mail if the account team doesn't have benefit specialist role
    private static List<Messaging.SingleEmailMessage> sendMailNotification(Set<Id> projToSendEmail){
        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
        List<String> emailTempFields = new List<String>{'ID'};
            EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_Project_Task_Assignment_Alert');
        toEmailAddressList.add(System.label.NSP_WXCarrierEmail);  
        for(Id projId : projToSendEmail){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , projId);
            email.setTemplateId(emailTemplate.Id); 
            email.setToAddresses(toEmailAddressList);
            email.setWhatId(projId);
            email.setSaveAsActivity(false);
            lstEmailMessages.add(email);
            
        }
        return lstEmailMessages; 
    }
    
    public void finish(Database.BatchableContext bc){}
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_WXBenefitsRenewalProjectCreation(),1);// 
    }
}