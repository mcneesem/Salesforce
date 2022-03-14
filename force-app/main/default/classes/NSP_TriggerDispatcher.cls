/**
 * Represents the Trigger Dispatcher class.
 */
public class NSP_TriggerDispatcher {
    
     /**
* Dummy private constructor             
*                
*/  
    private NSP_TriggerDispatcher() {  }

     /**
   * Represents the run mehtod which is called directly from the trigger
   * @param handler refrence of NSP_ITriggerHandler.  
   * @param triggerName Name of the trigger being called            
   *                
   */  
  public static void run(NSP_ITriggerHandler handler, string triggerName){
         
        //Check if the trigger is disabled
        if (handler.IsDisabled()){
            return;
        }
         
        
        
        //Check trigger context from trigger operation type
        switch on Trigger.operationType {
                
            when BEFORE_INSERT {
                //Invoke before insert trigger handler
                
                handler.beforeInsert(trigger.new);
            }
            when AFTER_INSERT {
                //Invoke after insert trigger handler
                handler.afterInsert(trigger.new, trigger.newMap);
            }
            when BEFORE_UPDATE {
                //Invoke before update trigger handler
                handler.beforeUpdate(trigger.newMap,trigger.oldMap);
            }
            when AFTER_UPDATE {
                //Invoke after update trigger handler
                handler.afterUpdate(trigger.newMap,trigger.oldMap);
            }
            when AFTER_DELETE {
                    //Invoke after delete trigger handler
                    handler.afterDelete(trigger.old, trigger.oldMap);
            }
            /*  when BEFORE_DELETE {
                //Invoke before delete trigger handler
                handler.beforeDelete(trigger.old, trigger.oldMap);
            }
            
            when AFTER_UNDELETE {
                //Invoke after undelete trigger handler
                handler.afterUnDelete(trigger.new, trigger.newMap);
            }*/
        }
        
    }
}