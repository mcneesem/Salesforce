/**
Apex Class Name      :  NSP_UnfollowCasesClosedFor90DaysBatch
Version              :  1.0 
Author               :  Simran
Function             :  Enabling Follow Button On 90 days old Closed Cases
Story                :  As part of                                                                     

*/
public class NSP_UnfollowCasesClosedFor90DaysBatch implements Schedulable,Database.Batchable<SObject>{
    private static final String CASE_OBJECT = 'Case';
    private static final List<String> serviceProfile = system.label.NSP_Service_Profiles.split(',');
    private static final List<String> CASE_FIELDS = new List<String>{ 'Id', 'Status','ClosedDate' };
    public Date testDate;
    public NSP_UnfollowCasesClosedFor90DaysBatch(Date testDate){
        this.testDate = testDate;
    }
    //starting the batch
    public Database.QueryLocator start(Database.BatchableContext bc){
        date reqDate = testDate != null ? testDate : system.today().addDays(-90);
		//quering the case which are closed for 90 days over
        String query = new NSP_QueryBuilder(CASE_OBJECT, CASE_FIELDS)
            .addFilter('Status', NSP_ServiceConstants.CASE_CLOSED_STATUS)
            .addFilter('DAY_ONLY(ClosedDate)',  String.valueOf(reqDate), NSP_QueryBuilder.Operator.LESS_THAN_OR_EQUALS, false)
            .setSecurityEnforce(false)
            .build();                                        
        return Database.getQueryLocator(query);
    }
    
     //executing the batch
    public void execute(Database.BatchableContext BC, List<Case> closedCases) {
        Set<Id> caseId = new Set<Id> ();
		list<Id> entSubs = new list<Id>();
		//query for service profile users
		List<User> currentUser = [SELECT Id, Profile.Name FROM User WHERE Profile.Name IN: serviceProfile];
		//fetching records where service users are following closed cases for over 90 days.
        for (EntitySubscription entitySubs : [SELECT Id FROM EntitySubscription WHERE ParentId IN: closedCases AND SubscriberId IN: currentUser]) {
            //caseRecord.Has_Active_Follow__c = false; // Set the follow status to inactive
            entSubs.add(entitySubs.Id);
        }
        for(Integer i = 0; i < entSubs.size(); i++)
         {
            ConnectApi.Chatter.deleteSubscription(null, entSubs[i]);  
        }
    }
    //finishing the batch
    public void finish(Database.BatchableContext BC) {
        // Final processing, if needed
    }
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_UnfollowCasesClosedFor90DaysBatch(null),1);
    }

}