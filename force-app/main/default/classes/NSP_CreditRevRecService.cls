/**
* 
*
*
Apex Class Name      :  NSP_CreditRevRecService
Version              :  1.0                                                                          
Created Date         :                                                                       
Description    :        This class is responsible to generate revenue schedules for credit transactions
*
*--------------------------------------------------------------------------------------------------  
*  Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
public class NSP_CreditRevRecService {
    private NSP_CreditRevRecService(){}
    /***********************************************************************************************
   * MethodName: generateRevenue
   * Description : This method prepaares requited input and call recognizeRevenue api to create revenue schduels and transcatinos
   * Params:       List<blng__CreditNoteLine__c> Lines
   *Author:CPQ Team
   * Date:
   *Return void
   * ****************************************************************************************/
   public static void generateRevenue(List<blng__CreditNoteLine__c> lines){
       List<blng.RevenueRecognitionInput> inputs = new List<blng.RevenueRecognitionInput>();
       for(blng__CreditNoteLine__c line :lines){
               blng.RevenueRecognitionInput input = new blng.RevenueRecognitionInput();
               input.source = line.Id;
               input.sourceFieldName = 'blng__CreditNoteLine__c';
               input.revenueAmount = -(line.blng__Subtotal__c);
               String revRecModel=null;
               if(line.blng__InvoiceLine__c!=null){
                   revRecModel=line.blng__InvoiceLine__r.blng__OrderProduct__r.NSP_Revenue_Recognition_Rule_Credit__r.NSP_Rev_Rec_Model__c;
                   input.revenueRecognitionRuleId = line.blng__InvoiceLine__r.blng__OrderProduct__r.NSP_Revenue_Recognition_Rule_Credit__c;
               }
               else{
                   revRecModel=line.NSP_Revenue_Recognition_Rule_Credit__r.NSP_Rev_Rec_Model__c;
                   input.revenueRecognitionRuleId = line.NSP_Revenue_Recognition_Rule_Credit__c;
               }
               if(revRecModel!=null && (revRecModel==NSP_CPQConstants.PROJ_REV_REC||revRecModel==NSP_CPQConstants.PROJ_REV_REC12)){
                   if(line.blng__InvoiceLine__c!=null && line.NSP_Project_Go_Live_Date__c!=null){
                       input.startDate=line.NSP_Project_Go_Live_Date__c;     
                   }
                   else if(line.blng__InvoiceLine__c!=null && line.NSP_Project_Go_Live_Date__c==null){
                       input.startDate = line.blng__InvoiceLine__r.blng__OrderProduct__r.Order.NSP_Project_Go_Live_Date__c!=null?line.blng__InvoiceLine__r.blng__OrderProduct__r.Order.NSP_Project_Go_Live_Date__c:line.blng__InvoiceLine__r.blng__Invoice__r.blng__InvoiceDate__c.addMonths(2);
                   }
                   else{
                       input.startDate=line.NSP_Project_Go_Live_Date__c!=null?line.NSP_Project_Go_Live_Date__c:line.blng__StartDate__c.addMonths(2);
                   }
                   input.endDate = input.startDate.addMonths(12);
               }
               else if(revRecModel!=null && revRecModel==NSP_CPQConstants.DELAY_12_1){
                   input.startDate = system.today().addMonths(1);
                   input.endDate = input.startDate.addMonths(12);
               }
               else if(revRecModel!=null && (revRecModel==NSP_CPQConstants.IMMEDIATE_REV ||revRecModel==NSP_CPQConstants.MONTH_12)){
                   input.startDate = line.blng__StartDate__c;
                   input.endDate = line.blng__EndDate__c;
               }
               input.legalEntityId = line.blng__LegalEntity__c;      
               inputs.add(input);
       }
       if (inputs != null && inputs.size() > 0) {
           List<blng.RevenueRecognitionResponse> response = blng.RevenueRecognition.recognizeRevenue(inputs);
       }
   }
       /***********************************************************************************************
   * MethodName: recreateInvoiceRevSchedules
   * Description : This method is used to recreate revenue shcedules and transcations when a project go live date is changed at Invoice line
   * Params:       List<Id> invLines
   *Author:CPQ Team
   * Date:
   *Return void
   * ****************************************************************************************/
   public static void recreateCreditRevSchedules(List<Id> cLines){
       List<String> distributions= new List<String>{NSP_CPQConstants.PROJ_REV_REC12_CRED_DIST,NSP_CPQConstants.PROJ_REV_REC_CRED_DIST};
           List<Id> credLineIds= new List<Id>();
       List<blng__RevenueSchedule__c> revSchedules= new List<blng__RevenueSchedule__c>();
       List<blng__RevenueSchedule__c> schedules=[SELECT Id,blng__RecognizedRevenueLastClosedPeriod__c,blng__RevenueStartDate__c,blng__CreditNoteLine__c,blng__CreditNoteLine__r.NSP_Project_Go_Live_Date__c,
                                                 blng__RevenueDistributionMethod__r.Name,blng__FullRecognitionDate__c,blng__RevenueFinanceBook__c
                                                 FROM blng__RevenueSchedule__c 
                                                 WHERE blng__RecognizedRevenueLastClosedPeriod__c=0
                                                 AND blng__RevenueDistributionMethod__r.Name IN :distributions
                                                 AND blng__CreditNoteLine__c IN:cLines];
       for(blng__RevenueSchedule__c schedule:schedules){
           if(schedule.blng__CreditNoteLine__c!=null && schedule.blng__CreditNoteLine__r.NSP_Project_Go_Live_Date__c!=null){
               if(schedule.blng__RevenueDistributionMethod__r.Name==NSP_CPQConstants.PROJ_REV_REC12_CRED_DIST && schedule.blng__RevenueStartDate__c!=schedule.blng__CreditNoteLine__r.NSP_Project_Go_Live_Date__c){
                   credLineIds.add(schedule.blng__CreditNoteLine__c);
                   revSchedules.add(schedule);
               }
               if(schedule.blng__RevenueDistributionMethod__r.Name==NSP_CPQConstants.PROJ_REV_REC_CRED_DIST && schedule.blng__FullRecognitionDate__c!=schedule.blng__CreditNoteLine__r.NSP_Project_Go_Live_Date__c){
                   credLineIds.add(schedule.blng__CreditNoteLine__c);
                   revSchedules.add(schedule);
               } 
           }
       }
       if(revSchedules.size()>0){
           try{
               delete revSchedules;
               NSP_CreditNoteLineTriggerHelper.prepareDataForRevRecGeneration(credLineIds);
           } catch(Exception ex){
               NSP_ErrorLogHandler.logSaveException('NSP_CreditRevRecService','recreateCreditRevSchedules',ex.getMessage());
           }
       }  
   }
   }