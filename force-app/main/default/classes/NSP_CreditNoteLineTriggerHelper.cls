/**
* 
Apex Class Name      :  NSP_CreditNoteLineTriggerHelper
Version              :  1.0                                                                          
Created Date         :                                                                      
Description    :         This is the helper class for Credit Note Line Trigger                                                                     
*--------------------------------------------------------------------------------------------------  
*  Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
public class NSP_CreditNoteLineTriggerHelper {
    /**
* Method Name : beforeInsertDirector 
* Description : Method to handle the automations in before insert scenario,routes to respective methods as per use cases
* Author : CPQ     
* @param  List of Credit Note Lines. 
* @return Map of void
*/
    public void beforeInsertDirector(List<blng__CreditNoteLine__c> credLines){
        List<Id>productIds= new List<Id>();
        List<Id> projectIds= new List<Id>();
        List<blng__CreditNoteLine__c> standaloneLines= new List<blng__CreditNoteLine__c>();
        for(blng__CreditNoteLine__c cLine:credLines){
            if(cLine.blng__Product__c!=null){
                productIds.add(cLine.blng__Product__c);
            }
        }
        Map<Id,Product2> productsMap = new Map<Id,Product2>([Select Id, NSP_Revenue_Recognition_Rule_Credit__c,NSP_Product_Credit_GL_Rule__c,NSP_Product_Credit_Tax_GL_Rule__c,NSP_Legal_Entity__c,Description FROM Product2 WHERE Id IN:productIds]);
        Map<String,blng__FinancePeriod__c> financePeriodsMap=getFinancePeriods();
        for(blng__CreditNoteLine__c cLine:credLines){
            if(productsMap.get(cLine.blng__Product__c)!=null){
                if(cLine.blng__InvoiceLine__c==null){ //stand alone credit note line
                    cLine.NSP_Revenue_Recognition_Rule_Credit__c=productsMap.get(cLine.blng__Product__c).NSP_Revenue_Recognition_Rule_Credit__c; 
                    if(cline.NSP_Project__c!=null){
                        projectIds.add(cline.NSP_Project__c);
                    }
                    cLine.NSP_Additional_Product_Description__c=productsMap.get(cLine.blng__Product__c)?.Description;
                    cLine.blng__StartDate__c=cline.blng__CreditNoteLineDate__c;
                    standaloneLines.add(cLine);
                }
                else if(cLine.blng__InvoiceLine__c!=null){ //issued from Invoice
                    Date firstDayOfMonth = cLine.blng__StartDate__c!=null?cLine.blng__StartDate__c.toStartOfMonth():cline.blng__CreditNoteLineDate__c.toStartOfMonth();
                    Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
                    String key=cLine.blng__BillingFinanceBook__c+'_'+cLine.blng__LegalEntity__c+'_'+lastDayOfMonth;
                    cLine.blng__FinancePeriod__c=financePeriodsMap.get(key)?.Id;
                }
                
            }
        }
        if(projectIds.size()>0){
            //For Stand alone Credit Note Lines,When Project Populated get it's Go Live date
            updateProjectGoLiveDate(projectIds,credLines);
        }
        if(standaloneLines.size()>0){
            populateCreditNoteInfoONCNlines(standaloneLines);
        }
    }
    public void afterInsertDirector(Map<Id, blng__CreditNoteLine__c> credLineNewMap){
        List<Id> elgibleLineForRevRec= new List<Id>();  
        for(blng__CreditNoteLine__c credLine:credLineNewMap.values()){
            elgibleLineForRevRec.add(credLine.Id);
        }
        prepareDataForRevRecGeneration(elgibleLineForRevRec);
    }
    public void beforeUpdateDirector(Map<Id, blng__CreditNoteLine__c> credLineNewMap, Map<Id, blng__CreditNoteLine__c> credLineOldMap){
        List<Id> projectIds= new List<Id>();
        for(blng__CreditNoteLine__c credline:credLineNewMap.values()){
            blng__CreditNoteLine__c oldLine =credLineOldMap.get(credline.Id);
            if(credline.NSP_Project__c!=oldLine.NSP_Project__c && oldLine.NSP_Project__c!=null){
                projectIds.add(credline.NSP_Project__c);
            }
        }
        if(projectIds.size()>0){
            //When Project lookup changes on Credit Note Line, updat Project Go Live Date to it;s corresponding project's go live date
            updateProjectGoLiveDate(projectIds,credLineNewMap.values());
        }
    }
    public void afterUpdateDirector(Map<Id, blng__CreditNoteLine__c> credLineNewMap, Map<Id, blng__CreditNoteLine__c> credLineOldMap){
        List<Id> clines= new List<Id>();
        for(blng__CreditNoteLine__c credline:credLineNewMap.values()){
            blng__CreditNoteLine__c oldLine =credLineOldMap.get(credline.Id);
            if(credline.NSP_Project_Go_Live_Date__c!=oldLine.NSP_Project_Go_Live_Date__c){
                clines.add(credline.Id);
            }
        }
        if(clines.Size()>0){
            NSP_CreditRevRecService.recreateCreditRevSchedules(clines);
        }
    }
    /**
* Method Name : prepareDataForRevRecGeneration 
* Description : Method to query required fields for rev rec geneation and call generate revenue method
* Author : CPQ      
* @param  List of Credit Note Lines.   
* @return void  
*/
    public static void prepareDataForRevRecGeneration(List<Id> elgibleLineForRevRec){
        List<blng__CreditNoteLine__c> creditNoteLines= [SELECT Id,blng__Subtotal__c,blng__LegalEntity__c,blng__InvoiceLine__c,blng__InvoiceLine__r.blng__OrderProduct__r.NSP_Revenue_Recognition_Rule_Credit__c,blng__StartDate__c,blng__EndDate__c,
                                                        blng__InvoiceLine__r.blng__OrderProduct__r.NSP_Revenue_Recognition_Rule_Credit__r.NSP_Rev_Rec_Model__c,blng__InvoiceLine__r.blng__OrderProduct__r.Order.NSP_Project_Go_Live_Date__c,blng__InvoiceLine__r.blng__Invoice__r.blng__InvoiceDate__c,
                                                        NSP_Revenue_Recognition_Rule_Credit__c,NSP_Revenue_Recognition_Rule_Credit__r.NSP_Rev_Rec_Model__c,NSP_Project_Go_Live_Date__c 
                                                        FROM blng__CreditNoteLine__c
                                                        WHERE Id IN :elgibleLineForRevRec];
        if(creditNoteLines.size()>0){
            NSP_CreditRevRecService.generateRevenue(creditNoteLines);
        }
        
    } 
    /**
* Method Name : getFinancePeriods 
* Description : Method to retrieve GL Treatments
* Author : CPQ         
* @return Map of Finance Periods  
*/
    private static Map<String,blng__FinancePeriod__c> getFinancePeriods(){
        Map<String,blng__FinancePeriod__c> financePeriodsMap= new Map<String,blng__FinancePeriod__c>();
        for(blng__FinancePeriod__c finPeriod:[SELECT Id,blng__FinanceBook__c,blng__LegalEntity__c,blng__PeriodEndDate__c FROM blng__FinancePeriod__c WHERE blng__FinanceBook__r.Name=:NSP_CPQConstants.FINBOOK AND blng__FinanceBook__r.blng__PeriodType__c=:NSP_CPQConstants.ACCOUNTING]){
            String key=finPeriod.blng__FinanceBook__c+'_'+finPeriod.blng__LegalEntity__c+'_'+finPeriod.blng__PeriodEndDate__c;
            financePeriodsMap.put(key,finPeriod);
        }
        return financePeriodsMap;
    }
    /**
* Method Name : updateProjectGoLiveDate 
* Description : Method to update project go live date on credit note lines
* Author : CPQ  
* @param  List of Credit Note Lines. 
* @return void 
*/
    private  void updateProjectGoLiveDate(List<Id>projectIds,List<blng__CreditNoteLine__c>newcreditNoteLines){
        Map<Id,Date> projectGoLiveDateMap= new Map<Id,Date>();
        for(pse__Proj__c proj:[SELECT Id,Go_Live_Date__c FROM pse__Proj__c WHERE Id IN:projectIds]){
            projectGoLiveDateMap.put(proj.Id,proj.Go_Live_Date__c);
        }
        for(blng__CreditNoteLine__c creditNoteLine:newcreditNoteLines){
            creditNoteLine.NSP_Project_Go_Live_Date__c=projectGoLiveDateMap.get(creditNoteLine.NSP_Project__c);
        }   
    }
    /**
* Method Name : populateCreditNoteInfoONCNlines 
* Description : Method to populate data from Credit Note to Credit Note Lines
* Author : CPQ 
* @param  List of Credit Note Lines. 
* @return void
*/
    private static void populateCreditNoteInfoONCNlines(List<blng__CreditNoteLine__c> standaloneLines){
        List<Id> creditNoteIds= new List<Id>();
        for(blng__CreditNoteLine__c cline:standaloneLines){
            creditNoteIds.add(cline.blng__CreditNote__c);
        }
        Map<Id,blng__CreditNote__c> creditNoteMap= new Map<Id,blng__CreditNote__c>([SELECT Id,blng__BillingFinanceBook__c,blng__BillingFinancePeriod__c,blng__TaxCity__c,blng__TaxCountry__c,blng__TaxZipCode__c,blng__TaxState__c,blng__TaxStreet__c,blng__TaxStreet2__c FROM blng__CreditNote__c WHERE Id IN:creditNoteIds]);
        for(blng__CreditNoteLine__c cline:standaloneLines){
            cline.blng__TaxCity__c=creditNoteMap.get(cline.blng__CreditNote__c)?.blng__TaxCity__c;
            cline.blng__TaxState__c=creditNoteMap.get(cline.blng__CreditNote__c)?.blng__TaxState__c;
            cline.blng__TaxCountry__c=creditNoteMap.get(cline.blng__CreditNote__c)?.blng__TaxCountry__c;
            cline.blng__TaxStreet__c=creditNoteMap.get(cline.blng__CreditNote__c)?.blng__TaxStreet__c;
            cline.blng__TaxZipCode__c=creditNoteMap.get(cline.blng__CreditNote__c)?.blng__TaxZipCode__c;
            cline.blng__FinancePeriod__c=creditNoteMap.get(cline.blng__CreditNote__c)?.blng__BillingFinancePeriod__c;
            cline.blng__BillingFinanceBook__c=creditNoteMap.get(cline.blng__CreditNote__c)?.blng__BillingFinanceBook__c;
            cline.blng__TaxStreet2__c=creditNoteMap.get(cline.blng__CreditNote__c)?.blng__TaxStreet2__c;
        }
    }
}