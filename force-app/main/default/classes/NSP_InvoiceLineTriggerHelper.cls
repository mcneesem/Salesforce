/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  September 05, 2022                                                             
Function             :   Represents the Invoive line trigger helper which handles all the logic.
Test class           :  NSP_InvoiceLineTriggerHelper
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*	CPQ Team          September 05, 2022          First Iteration
*
***************************************************************************************************/
public class NSP_InvoiceLineTriggerHelper {
    // test w/ NSP_InvoiceLineTriggerTest (81%)

    private NSP_InvoiceLineTriggerHelper(){}

    /***********************************************************************************************
* MethodName: afterUpdateDirector
* Description : This method is used to handle all the after update scenarios and routes to appropriate method as needed
* Params:       Map<Id, blng__InvoiceLine__c> invLineNewMap,Map<Id, blng__InvoiceLine__c> invLineOldMap
* ********************************************************************************************/ 
public static void afterUpdateDirector(Map<Id, blng__InvoiceLine__c> invLineNewMap,Map<Id, blng__InvoiceLine__c> invLineOldMap)  {
    List<Id> elgibleLineForRevRec= new List<Id>();
    List<Id> elgibleLinesForRecreateRevRec= new List<Id>();       
    for(blng__InvoiceLine__c invLine:invLineNewMap.values()){
        blng__InvoiceLine__c oldLine =invLineOldMap.get(invLine.Id);
        if(invLine.blng__InvoiceLineStatus__c!=oldLine.blng__InvoiceLineStatus__c && invLine.blng__InvoiceLineStatus__c=='Posted'){
            elgibleLineForRevRec.add(invLine.Id);
        }
        if(invLine.NSP_Go_Live_Date__c!=oldLine.NSP_Go_Live_Date__c){
            elgibleLinesForRecreateRevRec.add(invLine.Id);
        }
    }
    prepareForRevRecGeneration(elgibleLineForRevRec);
    if(elgibleLinesForRecreateRevRec.size()>0){
        NSP_RevRecService.recreateInvoiceRevSchedules(elgibleLinesForRecreateRevRec);
     }
}
        /***********************************************************************************************
* MethodName: beforeUpdateDirector
* Description : This method is used to handle all the before update scenarios and routes to appropriate method as needed
* Params:       Map<Id, blng__InvoiceLine__c> invLineNewMap,Map<Id, blng__InvoiceLine__c> invLineOldMap
* ********************************************************************************************/
public static void beforeUpdateDirector(Map<Id, blng__InvoiceLine__c> invLineNewMap,Map<Id, blng__InvoiceLine__c> invLineOldMap){
    List<Id> projectIds= new List<Id>();
    for(blng__InvoiceLine__c invLine:invLineNewMap.values()){
        blng__InvoiceLine__c oldLine =invLineOldMap.get(invLine.Id);
        if(invLine.NSP_Project__c!=oldLine.NSP_Project__c && oldLine.NSP_Project__c!=null){
            projectIds.add(invLine.NSP_Project__c);
        }
    }   
    if(projectIds.size()>0){
        //When Project lookup changes on Invoice Line, updat Go Live Date to it;s corresponding project's go live date
        updateProjectGoLiveDate(projectIds,invLineNewMap.values());
    }
}
public static void beforeInsertDirector(list<blng__InvoiceLine__c> newList)  {
    updateAddProductDescription(newList);
    populateBillingFinancePeriod(newList);
}

public static void afterInsertDirector(list<blng__InvoiceLine__c> newList)  {
    updateAddProductDescriptionOnOrderItem(newList);
}
/***********************************************************************************************
* MethodName: prepareForRevRecGeneration
* Description : This method is used to get all the invoice lines and make a call to rev rec service
* Params:       List<Id> elgibleLineForRevRec
* ********************************************************************************************/ 
public static void prepareForRevRecGeneration(List<Id> elgibleLineForRevRec){
    List<blng__InvoiceLine__c> invLines=[SELECT Id,blng__Subtotal__c,blng__LegalEntity__c,blng__OrderProduct__r.blng__RevenueRecognitionRule__c,blng__Invoice__r.blng__InvoiceDate__c,blng__OrderProduct__r.Order.NSP_Project_Go_Live_Date__c,blng__OrderProduct__r.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,NSP_Go_Live_Date__c 
                                         FROM blng__InvoiceLine__c 
                                         WHERE Id IN :elgibleLineForRevRec
                                         AND blng__OrderProduct__r.blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c NOT IN ('Immediate','12 Month')];
    if(invLines.size()>0){
        NSP_RevRecService.generateRevenue(invLines);
    }
}

/***********************************************************************************************
* MethodName: updateAddProductDescription
* Description : This method is used to update additional Product Description Field on before Insert. STY-03868
* Params:       List<blng__InvoiceLine__c> Boolean isInsert
* ********************************************************************************************/

public static void updateAddProductDescription(list<blng__InvoiceLine__c> invLineNew)  {
     Map<String,NSP_AdditionalProductDescription_Setting__mdt>  additionalProductDesSetMap = NSP_AdditionalProductDescription_Setting__mdt.getAll();
     
     for(blng__InvoiceLine__c newInvoiceLine: invLineNew){
        if(newInvoiceLine.NSP_Product_Code__c != null && additionalProductDesSetMap.containsKey(newInvoiceLine.NSP_Product_Code__c)) {
            NSP_AdditionalProductDescription_Setting__mdt descriptionSetting = additionalProductDesSetMap.get(newInvoiceLine.NSP_Product_Code__c);
            string prodDescStr = descriptionSetting.NSP_Product_Description_Syntex__c;
            Decimal perunitPrice = newInvoiceLine.NSP_Consumption_Rate_Per_Unit__c != null ? newInvoiceLine.NSP_Consumption_Rate_Per_Unit__c:newInvoiceLine.blng__UnitPrice__c;
             
            //DF-05546 -- updating prices with accounting format
             List<String> args = new String[]{'0','number','###,###,##0.00'};
             String pepm_Text = '$'+String.format(perunitPrice.setScale(2).format(), args);
             //monthly minimum should be removed if it's 0 or null
             String mm_Text = (newInvoiceLine.NSP_Consumption_Rate_Flat_Price__c!=null && newInvoiceLine.NSP_Consumption_Rate_Flat_Price__c!=0) ?
                                 '$'+String.format(newInvoiceLine.NSP_Consumption_Rate_Flat_Price__c.setScale(2).format(), args) :
                                 null;
            
             prodDescStr = (prodDescStr.contains('{Unit Price}') && perunitPrice != null) ? prodDescStr.replace('{Unit Price}',pepm_Text):prodDescStr;
         
             prodDescStr = (prodDescStr.contains('{Upper Tier_Flat Price}') && mm_Text != null) ? prodDescStr.replace('{Upper Tier_Flat Price}',mm_Text)
                             :prodDescStr.contains(', {Upper Tier_Flat Price} Monthly Minimum') ? prodDescStr.replace(', {Upper Tier_Flat Price} Monthly Minimum','')
                             :prodDescStr.contains('{Upper Tier_Flat Price} monthly minimum; ') ? prodDescStr.replace('{Upper Tier_Flat Price} monthly minimum; ',''):prodDescStr;
 
             prodDescStr = (prodDescStr.contains('{Qty}') && newInvoiceLine.blng__Quantity__c != null ) ? prodDescStr.replace('{Qty}',string.valueof(newInvoiceLine.blng__Quantity__c)):prodDescStr;
 
            if(newInvoiceLine.NSP_Product_Code__c == 'Lasso'   ){
                prodDescStr = newInvoiceLine.NSP_Order_Product_Account__c;
            }

            newInvoiceLine.NSP_Additional_Product_Description__c = prodDescStr;
             
        }
        else if(string.isNotBlank(newInvoiceLine.NSP_Order_Product_Type__c) && newInvoiceLine.NSP_Order_Product_Type__c == 'Lasso'){
            newInvoiceLine.NSP_Additional_Product_Description__c = newInvoiceLine.NSP_Order_Product_Account__c;
        }
        //updating desc to not contain '(See appendix)' - DF-03861
        String str = newInvoiceLine.NSP_Additional_Product_Description__c;
        String removal = '(See';
        String various = '(various';
        if(str!=null && (str.contains(removal) || str.contains(various))){
            String truncatedDesc = str.contains(removal)?str.substring(0,str.indexOf(removal,0)):str.substring(0,str.indexOf(various,0));
            newInvoiceLine.NSP_Additional_Product_Description__c = truncatedDesc;
        }
    }
}


/***********************************************************************************************
* MethodName: updateAddProductDescriptionOnOrderItem
* Description : This method is used to update additional Product Description Field on  orderitem after Insert. STY-03868
* Params:       List<blng__InvoiceLine__c> Boolean isInsert
* ********************************************************************************************/    
public static void updateAddProductDescriptionOnOrderItem(list<blng__InvoiceLine__c> invLineNew)  {
    Map<Id,OrderItem>  orderProductUpdateMap = new Map<Id,OrderItem>();
    for(blng__InvoiceLine__c newInvoiceLine: invLineNew){
        if(String.isNotBlank(newInvoiceLine.NSP_Additional_Product_Description__c) && newInvoiceLine.blng__OrderProduct__c != null ){
            OrderItem eachProduct = new OrderItem(Id = newInvoiceLine.blng__OrderProduct__c);
            eachProduct.NSP_Additional_Product_Description__c = newInvoiceLine.NSP_Additional_Product_Description__c;
            orderProductUpdateMap.put(eachProduct.id,eachProduct);
        }
    }
    
    if(orderProductUpdateMap.Size() > 0){
        List<Database.SaveResult> assetResults = Database.update(orderProductUpdateMap.values(),false);
        NSP_ErrorLogHandler.logSaveResultsException('NSP_InvoiceLineTriggerHelper', 'updateAddProductDescriptionOnOrderItem', assetResults ); //log the result
    }
}
public static void populateBillingFinancePeriod(list<blng__InvoiceLine__c> invLineNew){
    Map<String,blng__FinancePeriod__c> financePeriodsMap=getFinancePeriods();
    for(blng__InvoiceLine__c invLine:invLineNew){
        String key=invLine.blng__BillingFinanceBook__c+'_'+invLine.blng__LegalEntity__c+'_'+invLine.NSP_Invoice_Date_End_Of_Month__c;
        invLine.blng__BillingFinancePeriod__c=financePeriodsMap.get(key)?.Id;
    }
}
private static Map<String,blng__FinancePeriod__c> getFinancePeriods(){
    Map<String,blng__FinancePeriod__c> financePeriodsMap= new Map<String,blng__FinancePeriod__c>();
    for(blng__FinancePeriod__c finPeriod:[SELECT Id,blng__FinanceBook__c,blng__LegalEntity__c,blng__PeriodEndDate__c FROM blng__FinancePeriod__c WHERE blng__FinanceBook__r.Name=:NSP_CPQConstants.FINBOOK AND blng__FinanceBook__r.blng__PeriodType__c=:NSP_CPQConstants.ACCOUNTING]){
        String key=finPeriod.blng__FinanceBook__c+'_'+finPeriod.blng__LegalEntity__c+'_'+finPeriod.blng__PeriodEndDate__c;
        financePeriodsMap.put(key,finPeriod);
    }
    return financePeriodsMap;
}
    /***********************************************************************************************
* MethodName: updateProjectGoLiveDate
* Description : This method is used to update Go Live Date on Invoice line when Project changes on Invoice Line
* Params:       List<blng__InvoiceLine__c> newInvLines, List<Id>projectIds
* ********************************************************************************************/
private static void updateProjectGoLiveDate(List<Id>projectIds,List<blng__InvoiceLine__c>newInvLines){
    Map<Id,Date> projectGoLiveDateMap= new Map<Id,Date>();
    for(pse__Proj__c proj:[SELECT Id,Go_Live_Date__c FROM pse__Proj__c WHERE Id IN:projectIds]){
        projectGoLiveDateMap.put(proj.Id,proj.Go_Live_Date__c);
    }
    for(blng__InvoiceLine__c invLine:newInvLines){
       invLine.NSP_Go_Live_Date__c=projectGoLiveDateMap.get(invLine.NSP_Project__c);
    }

}
}