global class NSP_SetAccountStageToInactiveScheduler implements Schedulable{
  /**
* Schedules the accountstageInactivebatch
* @param SC SchedulableContext.  
* @return void             
*                
*/
    global void execute (SchedulableContext SC){
         NSP_SetAccountInactiveBatch batchObject = new  NSP_SetAccountInactiveBatch();
       database.executeBatch(batchObject,200);
     
    } 

}