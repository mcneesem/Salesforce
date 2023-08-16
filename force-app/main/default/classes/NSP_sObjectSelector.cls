/*
    Apex class Name      :  NSP_sObjectSelector
    Version              :  1.0
    Created Date         :  02 Nov, 2022
    Story                :  STY-03359
    Description          :  Generic selector class to fetch sObject records from DB.
    Created By           :  Nishkarsh Manav
*/
public with sharing class NSP_sObjectSelector {

    private NSP_QueryBuilder builder;
    private Integer limitCount;
    private Boolean isSecurityEnforced = true;

    public NSP_sObjectSelector(String objectName) {
        this.builder = new NSP_QueryBuilder(objectName);
    }

    public NSP_sObjectSelector(String objectName, List<String> fields) {
        this.builder = new NSP_QueryBuilder(objectName, fields);
    }

    public NSP_sObjectSelector addLimit(Integer limitCount){
        this.limitCount = limitCount;

        return this;
    }
    
    public NSP_sObjectSelector setSecurityEnforce(Boolean enforce){
        this.isSecurityEnforced = enforce;

        return this;
    }

    public SObject selectById(String recId){
        if(recId == null){
            return null;
        }

        String query = this.builder.addFilter('Id', recId).setSecurityEnforce(isSecurityEnforced).addLimit(1).build();

        List<SObject> sObjects = Database.query(query);

        return sObjects.isEmpty() ? null : sObjects[0];
    }

    public List<SObject> selectById(List<String> recIds){
        if(recIds == null || recIds.isEmpty()){
            return new List<SObject>();
        }

        String query = this.builder.addFilter('Id', recIds, NSP_QueryBuilder.Operator.INCLUDES).setSecurityEnforce(isSecurityEnforced).addLimit(limitCount).build();

        return Database.query(query);
    }

    public List<SObject> selectByRecordTypeName(String recTypeDeveloperName){
        String query = this.builder
                        .addFilter('RecordType.DeveloperName', recTypeDeveloperName)
            			.setSecurityEnforce(isSecurityEnforced)
                        .addLimit(limitCount)
                        .build();

        return Database.query(query);
    }

    public List<SObject> selectByRecordTypeId(String recTypeId){
        String query = this.builder.addFilter('RecordTypeId', recTypeId)
            			.setSecurityEnforce(isSecurityEnforced)
                        .addLimit(limitCount)
                        .build();

        return Database.query(query);
    }

    public List<SObject> selectByName(String name, List<Id> recordsToExclude, Boolean compareStrictly){
        if(compareStrictly){
            this.builder.addFilter('Name', name);
        }else{
            this.builder.addContainsFilter('Name', name);
        }
        NSP_QueryBuilder queryBuilder = this.builder.setSecurityEnforce(isSecurityEnforced).addLimit(limitCount);
        
        if(recordsToExclude != null && !recordsToExclude.isEmpty()){
            queryBuilder.addFilter('Id', recordsToExclude, NSP_QueryBuilder.Operator.NOT_IN);
        }
        return Database.query(queryBuilder.build());
    }
    
    public List<SObject> selectByName(String name, List<Id> recordsToExclude){
        return selectByName(name, recordsToExclude, false);  
    }
    
    public List<SObject> selectByName(String name){
        return selectByName(name, null, false);
    }

    public static List<Group> selectGroupsByTypeAndApiName(String type, String developerName, List<String> fields, Integer getlimit){
        String query = new NSP_QueryBuilder('Group', fields)
                        .addFilter('Type', type)
                        .addFilter('DeveloperName', developerName)
                        .addLimit(getlimit)
                        .build();

        return (List<Group>) Database.query(query);
    }
    public static Group selectGroupByTypeAndApiName(String type, String developerName, List<String> fields){
        Group retrunGroup = null;
        List<Group> getGroup = selectGroupsByTypeAndApiName(type, developerName, fields, 1);
            return retrunGroup = !getGroup.isEmpty() ? getGroup[0] : retrunGroup;
    }

    public static EmailTemplate selectByDeveloperName(List<String> fields,String developerName){
       
        String query = new NSP_QueryBuilder('EmailTemplate', fields)
                        .addFilter('DeveloperName', developerName)
                        .addLimit(1)
                        .build();     

      return  (EmailTemplate) Database.query(query);
  }
    public static Profile selectProfileByName(String profileName){
       
    String query = new NSP_QueryBuilder('Profile')
                    .addFilter('Name', profileName)
                    .addLimit(1)
                    .build();     

    return  (Profile) Database.query(query);
}
    public static UserRole selectUserRoleByName(String userRoleName){
 
    String query = new NSP_QueryBuilder('UserRole')
                    .addFilter('Name', userRoleName)
                    .addLimit(1)
                    .build();     

    return  (UserRole) Database.query(query);
    }

    
    public static List<Account> getAccountsById (Set<Id> accountIdSet) {
        List <Account> accRecs;
        try {
            accRecs = [SELECT Id, Name from Account WHERE Id IN:accountIdSet];
        }
        catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_OrderTriggerHelper','createAndStampSalesTaxContact',ex.getMessage());
        }
        return accrecs;
    }


    public static List<Contact> getContactsByAccountAndRecTypeId (Set<Id> accountIdSet, String salesTaxRecordType) {
        List <Contact> contactRecs;
        try {
            contactRecs = [Select Id, Name, AccountId, Account.Name, NSP_Sales_Tax_Contact_Key__c, NSP_Sales_Tax_Contact_Counter__c,
                            MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingStateCode, MailingCountryCode  
                            FROM Contact WHERE accountId IN : accountIdSet AND recordTypeId =:salesTaxRecordType];
        }
        catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_OrderTriggerHelper','createAndStampSalesTaxContact',ex.getMessage());
        }
        return contactRecs;
    }

}