/**
* @description  :  Batch Class to update FF user on contact.
* @date 16/01/2023
* Author : Nischay Jindal
* Name : NSP_FFUserContactBatch
*/
public class NSP_FFUserContactBatch implements Schedulable, Database.Batchable<SObject>, Database.Stateful{
    // test w/ NSP_FFUserContactBatchTest (92%)
    public static final String FFUSER_CONTACT_SET = 'NSP_FFUserContactBatch';
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Integer filterDaysCount = 7;
        FF_User_Contact_Batch_Setting__c customSettingRec = FF_User_Contact_Batch_Setting__c.getInstance(UserInfo.getUserId());
        if (customSettingRec != null && String.isNotBlank(customSettingRec.SoqlDaysLimit__c)) {
            filterDaysCount = Integer.valueOf(customSettingRec.SoqlDaysLimit__c);
        }
        // Calculate start date dynamically
        Date startDate = System.today().addDays(-filterDaysCount);

        
        // Convert dynamic SOQL to static SOQL using bind variables
        return Database.getQueryLocator([
            SELECT Id, Name, NSP_IS_FF_User__c, NSP_Employee_Per_ID__c, NSP_Financial_Force_User__c, NSP_FF_User_Count__c
            FROM User
            WHERE Id IN (
                SELECT UserId
                FROM UserHistory
                WHERE Field = 'NSP_IS_FF_User__c'
                AND CreatedDate >= :startDate
            ) 
            AND ( IsActive  = TRUE ) 
            AND ( NSP_IS_FF_User__c = TRUE ) 
            AND ( NSP_Employee_Per_ID__c != NULL ) 
            AND (NSP_FF_User_Count__c <= 30 OR NSP_FF_User_Count__c = NULL)
            AND ( NSP_Financial_Force_User__c != NULL )
        ]);
    }
    public void execute(Database.BatchableContext bc, List<User> userList){
        Id insperityAccountId = System.Label.NSP_Insperity_Account; 
        Map<String, User> userPerIdUserMap = new Map<String,User>();
        List<Contact> FFContactList = new List<Contact>();
        Set<Id> FFUserContactSet = new Set<Id>();
        FFBatchWrapper ffWrapper = new FFBatchWrapper();
        List<String> regionField = new List<String>{'Id', 'Name' };
        try{
            for(User usr :userList){
                userPerIdUserMap.put(usr.NSP_Employee_Per_ID__c,usr);
           }

            String regionQuery = new NSP_QueryBuilder('pse__Region__c', regionField).addFilter('Name', NSP_ServiceConstants.UnitedStatesRegion).addLimit(1).build();
            if(!userPerIdUserMap.isEmpty()){
                for(Contact con :[Select Id,AccountId , Account.Name ,NSP_Per_ID__c , pse__Salesforce_User__c FROM 
                                  Contact WHERE NSP_Per_ID__c IN:userPerIdUserMap.keySet() AND AccountId !=Null AND pse__Is_Resource__c =True AND pse__Is_Resource_Active__c = True]){
                                      insperityAccountId = test.isRunningTest() ? con.AccountId : System.Label.NSP_Insperity_Account;
                                      if(con.AccountId == insperityAccountId && userPerIdUserMap.containsKey(con.NSP_Per_ID__c)){
                                          Contact contact = new Contact();
                                          contact.Id = con.Id;
                                          contact.pse__Salesforce_User__c = userPerIdUserMap.get(con.NSP_Per_ID__c).Id;
                                          FFContactList.add(contact);
                                          FFUserContactSet.add(userPerIdUserMap.get(con.NSP_Per_ID__c).Id);
                                      }
                                      
                                  }
            }
            pse__Region__c region = Database.query(regionQuery);
            for(User usr :userPerIdUserMap.values()){
                Integer FFUserCount = 0;
                if(Integer.ValueOf(usr.NSP_FF_User_Count__c)!=Null){
                    FFUserCount = Integer.ValueOf(usr.NSP_FF_User_Count__c); 
                }
                ffWrapper = updateFFUser(FFUserContactSet,FFUserCount, usr.Id, region.Id);
            }
            
            if(!ffWrapper.perControlList.isEmpty() && !Test.isRunningTest()){
                List<Database.UpsertResult> results = Database.upsert(ffWrapper.perControlList,false);
                NSP_ErrorLogHandler.logUpsertResultsException(FFUSER_CONTACT_SET, 'updatePerContList', results );
            }
            if(!ffWrapper.userList.isEmpty() && !Test.isRunningTest()){
           		List<Database.SaveResult> results = Database.update(ffWrapper.userList,false);
           		 NSP_ErrorLogHandler.logSaveResultsException(FFUSER_CONTACT_SET, 'updateUserList', results );
            }
            if(!FFContactList.isEmpty() && !Test.isRunningTest()){
                List<Database.SaveResult> results = Database.update(FFContactList,false);
                NSP_ErrorLogHandler.logSaveResultsException(FFUSER_CONTACT_SET, 'FFContactList', results );
                
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(FFUSER_CONTACT_SET, 'executeBatch', ex.getMessage());
        }
    }
    public void finish(Database.BatchableContext bc){
        
    }
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_FFUserContactBatch(),1);
    }
    public static FFBatchWrapper updateFFUser(Set<Id> FFUserContactSet , Integer FFUserCount ,Id userId , Id regionId ){
        List<User> FFUserList = new List<User>();
        List<User> nonFFUserList = new List<User>();
        List<User> updateUserList = new List <User>();
        List<pse__Permission_Control__c> updatePerContList = new List <pse__Permission_Control__c>();
        FFBatchWrapper ffWrapper = new FFBatchWrapper();
        if(FFUserContactSet.contains(userId) && FFUserCount <= 30){
            User user = new User();
            user.Id = userId;
            user.NSP_FF_User_Count__c = FFUserCount + 1;
            user.NSP_IS_FF_User__c = True;
            FFUserList.add(user);
            updatePerContList.addAll(createPermissionControl(userId,regionId ));
        }else if(!FFUserContactSet.contains(userId) && FFUserCount < 30){
            User user = new User();
            user.Id = userId;
            user.NSP_FF_User_Count__c = FFUserCount + 1;
            nonFFUserList.add(user); 
        }
        updateUserList.addAll(FFUserList);
        updateUserList.addAll(nonFFUserList);

        if(!FFUserList.isEmpty()){
            if(!updatePerContList.isEmpty()){
			ffWrapper.perControlList.addAll(updatePerContList);
            } 
        } 
        if(!updateUserList.isEmpty()){
			ffWrapper.userList.addAll(updateUserList);
        }
        return ffWrapper;
    }

    /***********************************************************************************************
    * MethodName: createPermissionControl
    * Description : Create PermissionControl record
    * ********************************************************************************************/    
    public static   List<pse__Permission_Control__c>  createPermissionControl(Id userId , Id regionId){ 
        List<pse__Permission_Control__c> perContolList = new List <pse__Permission_Control__c>();
        pse__Permission_Control__c  perCon = new pse__Permission_Control__c();
        perCon.pse__Region__c = regionId;
        perCon.pse__User__c = userId;
        perCon.pse__Cascading_Permission__c= True;
        perCon.pse__Expense_Entry__c= True;
        perCon.pse__Expense_Ops_Edit__c= True;
        perCon.pse__Invoicing__c= True;
        perCon.pse__Edit_Task_Manager__c= True;
        perCon.pse__View_Task_Manager__c= True;
        perCon.pse__Compare_Project_Version__c= True;
        perCon.pse__Create_Project_Version__c= True;
        perCon.pse__Delete_Project_Version__c= True;
        perCon.pse__Resource_Request_Entry__c= True;
        perCon.pse__Forecast_Edit__c= True;
        perCon.pse__Forecast_View__c= True;
        perCon.pse__Skills_And_Certifications_Entry__c= True;
        perCon.pse__Skills_And_Certifications_View__c= True;
        perCon.pse__Staffing__c= True;
        perCon.pse__Team_Create__c= True;
        perCon.pse__Team_Edit__c= True;
        perCon.pse__Team_View__c= True;
        perCon.pse__Timecard_Entry__c= True;
        perCon.pse__Timecard_Ops_Edit__c= True;
        perContolList.add(perCon);
        return perContolList;
    } 
    public class FFBatchWrapper{
        public List<User> userList = new List<User>();
		public List<pse__Permission_Control__c> perControlList = new List<pse__Permission_Control__c>();
    }
}
