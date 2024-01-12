/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  October 18, 2022                                                             
Function             :  Represents To display the cases which are having access to the logged in user.
Test class           :  NSP_Display_ConfidentialCasesTest
Story                :  STY-03293                                                                      
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* ------------------------------------------------------------------------------------------------- 
ManiTeja				11/2/2022				Modified as part of STY-03741 to filter cases based on Operators
***************************************************************************************************/
public without Sharing class NSP_Display_ConfidentialCases {
    
    /**
* @MethodName: getRelatedCases
* @Description: Represents To display the cases which are having access to the logged in user.
* @param : String statusValue, Date openDate, Date closedDate, string parentId, String parentObject
* @createdDate : 10/18/2022
* @Story : STY-03293
* @return void                          
*/
    @AuraEnabled(cacheable=true)
    public static List<Case> getRelatedCases( String statusValue, Date openDate, Date closedDate, string parentId, String parentObject, String openDateFilter, String closeDateFilter) {
        Set<Id> filteredCaseIdSet = new Set<Id>();
        Set<Id> unFilteredCaseIdSet = new Set<Id>();
         Set<Id> frameUnfilteredCases = new Set<Id>();
        String OBJECT_NAME = 'Case';
        List<String> FIELDS = new List<String>{'Id','Subject', 'ContactId', 'AssetId', 'OwnerId', 'NSP_Opened_Date__c', 'NSP_Case_Sub_Status__c', 'NSP_Confidential__c',
            'CreatedDate', 'Owner.Name', 'NSP_Case_Created_date__c', 'Status', 'NSP_Date_Closed__c', 'NSP_Category__c',
            'NSP_SubCategory__c', 'reason', 'NSP_Detail__c', 'NSP_Due_Date__c', 'Priority', 'NSP_Private__c', 'AccountId', 'Account.Name'};                               
                String confidentailField = 'NSP_Confidential__c';
        Boolean isConfValue = true;
        String privateCheckBoxField = 'NSP_Private__c';
        String corpCaseField = 'NSP_CorporateEmployeeEE__c';
        Integer caseResulMinimumtCount = 200;
        Boolean isPrivateCheckBoxValue, isCorpCaseFieldValue = false;
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(OBJECT_NAME, FIELDS); // Framing the query
        queryBuilder.addFilter(confidentailField, isConfValue , NSP_QueryBuilder.Operator.EQUALS);
        queryBuilder.addFilter(privateCheckBoxField, isPrivateCheckBoxValue , NSP_QueryBuilder.Operator.EQUALS);
        queryBuilder.addFilter(corpCaseField, isCorpCaseFieldValue , NSP_QueryBuilder.Operator.EQUALS);
        if(parentObject == 'Account'){
            queryBuilder.addFilter(parentObject+'Id', parentId , NSP_QueryBuilder.Operator.EQUALS); 
        }else if(parentObject == 'Asset'){
            queryBuilder.addFilter(parentObject+'Id', parentId , NSP_QueryBuilder.Operator.EQUALS);
        }else if(parentObject == 'Contact'){
            queryBuilder.addFilter(parentObject+'Id', parentId , NSP_QueryBuilder.Operator.EQUALS);
        }
        queryBuilder.setSecurityEnforce(false);
        String queryAllCases = queryBuilder.build(); // Building the query
        List<case> getAllCases =  Database.query( queryAllCases );
        if(getAllCases.size() < 200){
            for(Case getUnfilteredCase : Database.query( queryAllCases )){
                frameUnfilteredCases.add(getUnfilteredCase.Id);
                
            }
            for(UserRecordAccess userAccessCase : [SELECT RecordID FROM UserRecordAccess 
                                                   WHERE UserId = : UserInfo.getUserId() 
                                                   AND RecordID IN: frameUnfilteredCases AND HasEditAccess = True]){
                                                       filteredCaseIdSet.add(userAccessCase.Id);
                                                   }
            frameUnfilteredCases.removeAll(filteredCaseIdSet);
        }else{
            List<List<Case>> getChunckedCases = split(getAllCases, 80);
            for(List<Case> caseList : getChunckedCases){
                unFilteredCaseIdSet.clear();
                for(Case getUnfilteredCase : caseList){
                    unFilteredCaseIdSet.add(getUnfilteredCase.Id);
                    frameUnfilteredCases.add(getUnfilteredCase.Id);                    
                }
                for(UserRecordAccess userAccessCase : [SELECT RecordID FROM UserRecordAccess 
                                                       WHERE UserId = : UserInfo.getUserId() 
                                                       AND RecordID IN: unFilteredCaseIdSet AND HasEditAccess = True]){
                                                           filteredCaseIdSet.add(userAccessCase.Id);
                                                       }
            }
            frameUnfilteredCases.removeAll(filteredCaseIdSet);
        }
        
        if ( StatusValue != null && StatusValue != ''  && StatusValue != 'None' ) {
            queryBuilder.addFilter('Status', StatusValue , NSP_QueryBuilder.Operator.EQUALS);
        }
        queryBuilder.setSecurityEnforce(false);
        String finalQuery = queryBuilder.build();
        finalQuery += ' AND Id IN: frameUnfilteredCases';
        
        if ( openDate != null ) {
            String getOpenDateFilter  = (openDateFilter == '=' || String.isBlank(openDateFilter)) ? '=' : openDateFilter;
            finalQuery += ' AND NSP_Case_Created_date__c ' + getOpenDateFilter + ': openDate'; 
        }
        if ( closedDate != null ) {
            String getCloseDateFilter = ( closeDateFilter == '=' ||  String.isBlank(closeDateFilter)) ? '=' : closeDateFilter;
            finalQuery += ' AND ClosedDate ' + getCloseDateFilter + ': closedDate'; 
        }
        finalQuery += ' ORDER BY Status, NSP_Case_Created_date__c DESC'; // DF-03623
        return Database.query( finalQuery );
    }
    
    /**
    * @MethodName: split
    * @Description: Represents To split the list of cases to split in to list of 80 so that no exception comes when the list of cases is more than 200.
    * @param : List<Case> source, Integer size
    * @createdDate : 06/30/2023
    * @Story : DF-05214
    * @return void                          
    */

    public static List<List<Case>> split(List<Case> source, Integer size) {
        List<List<Case>> ret = new List<List<Case>>();
        if (source == null) return ret;
        if (source.size() <= size) {
            ret.add(source);
            return ret;
        }
        Integer partition = 0;
        ret.add(new List<Case>());
        
        for (Case obj : source) {
            if (ret[partition].size() == size) {
                partition++;
                ret.add(new List<Case>());
            }
            ret[partition].add(obj);
        }
        
        return ret;
    }
    
}