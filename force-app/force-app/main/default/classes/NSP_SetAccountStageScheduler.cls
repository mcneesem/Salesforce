global class NSP_SetAccountStageScheduler implements Schedulable{
    
        /**
* Schedules the accountstagebatch
* @param SC SchedulableContext.  
* @return void             
*                
*/
    global void execute (SchedulableContext SC){
         NSP_SetAccountStageBatch batchObject = new  NSP_SetAccountStageBatch();
       database.executeBatch(batchObject,200);
     
    } 

}