/**
* Represents the TimeCard trigger helper which handles all the logic.
*/
public class NSP_TimeCardTriggerHelper {
    /* Description: This method accepts list of TimeCard Header and 
     * 				Update Approved,Submitted and Include in Financial fields to True.
     * Date: 01/11/2021 */
    Public Void updateTimeCardStatus(List<pse__Timecard_Header__c> newList){ 
        
        for(pse__Timecard_Header__c eachTimeCard : newList){
            eachTimeCard.pse__Approved__c=True;
            eachTimeCard.pse__Submitted__c=True;
            eachTimeCard.pse__Include_In_Financials__c=True;
        }
    }
}