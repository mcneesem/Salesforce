public class NSP_RevRecService {
    
    private NSP_RevRecService(){}
    public static void generateRevenue(List<blng__InvoiceLine__c> lines){
        List<blng.RevenueRecognitionInput> inputs = new List<blng.RevenueRecognitionInput>();
        for(blng__InvoiceLine__c line :lines){
            String revRecModel=line.blng__OrderProduct__r.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c;
            blng.RevenueRecognitionInput input = new blng.RevenueRecognitionInput();
            input.source = line.Id;
            input.sourceFieldName = 'blng__InvoiceLine__c';
            input.revenueAmount = line.blng__Subtotal__c;
            if(revRecModel!=null && (revRecModel==NSP_CPQConstants.PROJ_REV_REC||revRecModel==NSP_CPQConstants.PROJ_REV_REC12)){
                if(line.NSP_Go_Live_Date__c!=null){
                    input.startDate =line.NSP_Go_Live_Date__c;
                }
                else{
                    input.startDate = line.blng__OrderProduct__r.Order.NSP_Project_Go_Live_Date__c!=null?line.blng__OrderProduct__r.Order.NSP_Project_Go_Live_Date__c:line.blng__Invoice__r.blng__InvoiceDate__c.addMonths(2);
                }
                input.endDate = input.startDate.addMonths(12);
            }
            else if(revRecModel!=null && revRecModel==NSP_CPQConstants.DELAY_12_1){
                input.startDate = system.today().addMonths(1);
                input.endDate = input.startDate.addMonths(12);
            }
            else{
                //to surpass codescan issue
            }
            input.revenueRecognitionRuleId = line.blng__OrderProduct__r.blng__RevenueRecognitionRule__c;
            input.legalEntityId = line.blng__LegalEntity__c;
            inputs.add(input);
        }
        if (inputs != null && inputs.size() > 0) {
            List<blng.RevenueRecognitionResponse> response = blng.RevenueRecognition.recognizeRevenue(inputs);
        }
    }
        /***********************************************************************************************
    * MethodName: updateGoLiveDatesOnInvLineAndCredLines
    * Description : This method is used to update Project Go Live Dates on Invoice Line and Credit Note Line. This method is called in 
     response to platform event which gets published when Go Live Date on Project changes
    * Params:       Map<String,Date> projectGoLiveDateMap
    * ****************************************************************************************/
    public static void updateGoLiveDatesOnInvLineAndCredLines(Map<String,Date> projectGoLiveDateMap){
        List<blng__InvoiceLine__c> invLinesToUpdate= new List<blng__InvoiceLine__c>();
        List<blng__CreditNoteLine__c> cLinesToUpdate= new List<blng__CreditNoteLine__c>();
        
        for(blng__InvoiceLine__c invLine:[SELECT Id,NSP_Project__c,NSP_Go_Live_Date__c FROM blng__InvoiceLine__c WHERE NSP_Project__c IN :projectGoLiveDateMap.keySet()]){
            invLinesToUpdate.add(new blng__InvoiceLine__c(Id=invLine.Id,NSP_Go_Live_Date__c=projectGoLiveDateMap.get(invLine.NSP_Project__c)));
        }
        for(blng__CreditNoteLine__c cLine:[SELECT Id,NSP_Project__c,NSP_Project_Go_Live_Date__c FROM blng__CreditNoteLine__c WHERE NSP_Project__c IN :projectGoLiveDateMap.keySet()]){
            cLinesToUpdate.add(new blng__CreditNoteLine__c(Id=cLine.Id,NSP_Project_Go_Live_Date__c=projectGoLiveDateMap.get(cLine.NSP_Project__c)));
        }
        if(invLinesToUpdate.size()>0){
            List<Database.SaveResult> invLineResults = Database.update(invLinesToUpdate,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_RevRecService', 'updateGoLiveDatesOnInvLineAndCredLines', invLineResults ); 
        }
        if(cLinesToUpdate.size()>0){
             List<Database.SaveResult> cLineResults = Database.update(cLinesToUpdate,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_RevRecService', 'updateGoLiveDatesOnInvLineAndCredLines', cLineResults );
        }
    }
        /***********************************************************************************************
    * MethodName: recreateInvoiceRevSchedules
    * Description : This method is used to recreate revenue shcedules and transcations when a project go live date is changed at Invoice line
    * Params:       List<Id> invLines
    * ****************************************************************************************/
    public static void recreateInvoiceRevSchedules(List<Id> invLines){
        List<String> distributions= new List<String>{NSP_CPQConstants.PROJ_REV_REC12_INV_DIST,NSP_CPQConstants.PROJ_REV_REC_INV_DIST};
        List<Id> invLineIds= new List<Id>();
        List<blng__RevenueSchedule__c> revSchedules= new List<blng__RevenueSchedule__c>();
        List<blng__RevenueSchedule__c> schedules=[SELECT Id,blng__RecognizedRevenueLastClosedPeriod__c,blng__RevenueStartDate__c,blng__InvoiceLine__c,blng__InvoiceLine__r.NSP_Go_Live_Date__c,
                                                  blng__RevenueDistributionMethod__r.Name,blng__FullRecognitionDate__c,blng__RevenueFinanceBook__c
                                                  FROM blng__RevenueSchedule__c 
                                                  WHERE blng__RecognizedRevenueLastClosedPeriod__c=0
                                                  AND blng__RevenueDistributionMethod__r.Name IN :distributions
                                                  AND blng__InvoiceLine__c IN:invLines];
        for(blng__RevenueSchedule__c schedule:schedules){
            if(schedule.blng__InvoiceLine__c!=null && schedule.blng__InvoiceLine__r.NSP_Go_Live_Date__c!=null){
                if(schedule.blng__RevenueDistributionMethod__r.Name==NSP_CPQConstants.PROJ_REV_REC12_INV_DIST && schedule.blng__RevenueStartDate__c!=schedule.blng__InvoiceLine__r.NSP_Go_Live_Date__c){
                    invLineIds.add(schedule.blng__InvoiceLine__c);
                    revSchedules.add(schedule);
                }
                if(schedule.blng__RevenueDistributionMethod__r.Name==NSP_CPQConstants.PROJ_REV_REC_INV_DIST && schedule.blng__FullRecognitionDate__c!=schedule.blng__InvoiceLine__r.NSP_Go_Live_Date__c){
                    invLineIds.add(schedule.blng__InvoiceLine__c);
                    revSchedules.add(schedule);
                } 
            }
        }
        if(revSchedules.size()>0){
            try{
                delete revSchedules;
                NSP_InvoiceLineTriggerHelper.prepareForRevRecGeneration(invLineIds);
            } catch(Exception ex){
                NSP_ErrorLogHandler.logSaveException('NSP_RevRecService','recreateInvoiceRevSchedules',ex.getMessage());
            }
        }     
    }

}