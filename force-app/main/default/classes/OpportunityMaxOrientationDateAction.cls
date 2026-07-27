public with sharing class OpportunityMaxOrientationDateAction {
    // test w/ OpportunityMaxOrientationDateActionTest (83%)
    @InvocableMethod(label='Update Opportunity max orientation date' description='This method updates the max orientation date in any Opportunity')
    public static void invoke(List<FlowInput> inputs ) {
        try{
            Map<Id, Date> opportunityMap = new Map<Id, Date>();
            if ( inputs != null  && !inputs.isEmpty()){
                for(FlowInput input : inputs){
                    if(input != null && input.opportunitytId != null && input.maxOrientationDate != null){
                        opportunityMap.put(input.opportunitytId, input.maxOrientationDate);
                    }
                }
            }
            if(!opportunityMap.isEmpty()){
                OpportunityMaxOrientationDateAction.updateMaxOrientationDate(opportunityMap);
            }
        }
        catch(Exception e){
            NSP_ErrorLogHandler.logException(
                OpportunityMaxOrientationDateAction.class.getName() ,
            'invoke' ,
            e
                );
        }
    }

    public class FlowInput {
        @InvocableVariable(label='Opprtunity Id' required=true)
        public String opportunitytId;
        @InvocableVariable(label='Max Orientation Date' required=true)
        public Date maxOrientationDate;
    }

    private static void updateMaxOrientationDate(Map<Id, Date> opportunityMap){
        List<Opportunity> opportunityList = null;
        if( opportunityMap != null ){
            opportunityList = [SELECT Id, Max_Orientation_Date__c
                                            FROM Opportunity
                                            WHERE Id IN :opportunityMap.keySet()];
        }
        if(opportunityList !=null && !opportunityList.isEmpty()){

            List<Opportunity> opportunityUpdate = new List<Opportunity>();
            for(Opportunity opportunityRecord : opportunityList){
                if ( opportunityMap.containsKey( opportunityRecord.Id ) ) {
                    Date max = opportunityMap.get( opportunityRecord.Id );
                    if ( opportunityRecord.Max_Orientation_Date__c != max ) {
                        opportunityRecord.Max_Orientation_Date__c = max;
                        opportunityUpdate.add( opportunityRecord );
                    }
                }
            }
            if(!opportunityUpdate.isEmpty()){
                List<Database.SaveResult> results = Database.update( opportunityUpdate, false );
                NSP_ErrorLogHandler.logResults(
                    OpportunityMaxOrientationDateAction.class.getName() ,
                'updateMaxOrientationDate' ,
                results
                    );
            }
        }
    }
}