/**
Apex Class Name      :  NSP_AccountGrowthForeCastBatch
Version              :  1.0                                                                          
Created Date         :  11/01/2022
Function             :  This batch runs every quarter of the year and roll of the Q3 Year of each GrowthForecase types
Story                :  STY-00576                                                                  
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Anil                       11/01/2022          First Iteration
* system.schedule('AccountGroupGrowthForecast', '0 0 5 1 JAN,APR,JUL,OCT ?',new NSP_AccountGrowthForeCastBatch());
*/
global class NSP_AccountGrowthForeCastBatch implements Database.Batchable<sObject>, Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext bC){

        String query = 'SELECT Id, NSP_Type__c, NSP_Past_Quarter__c, NSP_Past_Quarter_Date__c, NSP_Organic_Current_Quarter__c, NSP_Acquisition_Current_Quarter__c, NSP_Reduction_Current_Quarter__c, NSP_Organic_Current_Quarter_1__c, NSP_Acquisition_Current_Quarter_1__c, NSP_Reduction_Current_Quarter_1__c, NSP_Acquisition_Current_Quarter_2__c, NSP_Organic_Current_Quarter_2__c, NSP_Reduction_Current_Quarter_2__c, NSP_Organic_Current_Quarter_3__c, NSP_Acquisition_Current_Quarter_3__c, NSP_Reduction_Current_Quarter_3__c FROM NSP_Account_Group__c';
        query += ' WHERE NSP_Type__c  = \'Growth Forecast\' AND NSP_Past_Quarter_Date__c != NULL AND NSP_Past_Quarter_Date__c < THIS_QUARTER';
                
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bC, List<NSP_Account_Group__c> lstAccountGroups){
        // process each batch of records
        try {
            
            List<NSP_Account_Group__c> lstAccountGroupsToUpdate = new List<NSP_Account_Group__c>();
            
            for(NSP_Account_Group__c accGroup : lstAccountGroups){
                
                accGroup.NSP_Organic_Current_Quarter__c = accGroup.NSP_Organic_Current_Quarter_1__c;
                accGroup.NSP_Organic_Current_Quarter_1__c = accGroup.NSP_Organic_Current_Quarter_2__c;
                accGroup.NSP_Organic_Current_Quarter_2__c = accGroup.NSP_Organic_Current_Quarter_3__c;
                accGroup.NSP_Organic_Current_Quarter_3__c = null;
                
                accGroup.NSP_Reduction_Current_Quarter__c = accGroup.NSP_Reduction_Current_Quarter_1__c;
                accGroup.NSP_Reduction_Current_Quarter_1__c = accGroup.NSP_Reduction_Current_Quarter_2__c;
                accGroup.NSP_Reduction_Current_Quarter_2__c = accGroup.NSP_Reduction_Current_Quarter_3__c;
                accGroup.NSP_Reduction_Current_Quarter_3__c = null;
                
                accGroup.NSP_Acquisition_Current_Quarter__c = accGroup.NSP_Acquisition_Current_Quarter_1__c;
                accGroup.NSP_Acquisition_Current_Quarter_1__c = accGroup.NSP_Acquisition_Current_Quarter_2__c;
                accGroup.NSP_Acquisition_Current_Quarter_2__c = accGroup.NSP_Acquisition_Current_Quarter_3__c;
                accGroup.NSP_Acquisition_Current_Quarter_3__c = null;

                accGroup.NSP_Past_Quarter_Date__c = System.today();
                accGroup.NSP_Past_Quarter__c = currentQuarter;
                
                lstAccountGroupsToUpdate.add(accGroup);
            }
            
            if(!lstAccountGroupsToUpdate.isEmpty()){
                Database.update(lstAccountGroupsToUpdate, false);
            }
            
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('AccountGrowthForeCastBatch', 'execute', ex.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext bC){ }

    private static String currentQuarter {
        get {
            DateTime dt = System.now();
            Integer currentMnt = dt.month();
            Integer currentQ = ((currentMnt - 1) / 3) + 1;
            return 'Q' + currentQ + '/' + dt.year();
        }
        private set;
    }
    
    global void execute(SchedulableContext sc) {
        NSP_AccountGrowthForeCastBatch batchGrowth = new NSP_AccountGrowthForeCastBatch(); 
        database.executebatch(batchGrowth, 200);
    }
}