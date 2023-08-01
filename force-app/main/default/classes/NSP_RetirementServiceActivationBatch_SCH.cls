/**
 Apex Class Name      :  NSP_RetirementServiceActivationBatch_SCH
 Version              :  1.0
 Created Date         :  13/12/2022
 Function             :  Represents batch class for NSP_RetirementServiceActivationBatch
 Story                :  STY-03601
 Modification Log     :
 *--------------------------------------------------------------------------------------------------
 * Developer                   Date                   Description
 * -------------------------------------------------------------------------------------------------
 * Manikandan Mohan           13/12/2022              Schedule for Retirement Service Activation on Order Products Related to Asset object in the Client sub plan History.
 */
global class NSP_RetirementServiceActivationBatch_SCH implements Schedulable{
    global void execute(SchedulableContext SC){
        NSP_RetirementServiceActivationBatch batchObj = new NSP_RetirementServiceActivationBatch();
        Database.executeBatch(batchObj, 200);
    }

}