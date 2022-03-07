/* **************************************************************************************************   
Component Name :  NSP_DisplayQliController class
Version              :  1.0                                                                          
Created Date         :  28/06/2021                                                           
Function             :  This class is for DisplayQli visualforce component to display quote line date
Story                :  STY-00450                                                                           
Modification Log     :                                                                               
*	Raksha          28/06/2021          First Iteration
*
***************************************************************************************************
*/

public class NSP_DisplayQliController{
    public String quoteId;
    public String quoteIdstr{get;set;}
    
    public list<QuotLinewrap> nonRecurringQLi{get;set;}
    public list<QuotLinewrap> nonRecurringTotalQLi{get;set;}
    public Boolean quoteList{get;set;}
    public Boolean pepmList{get;set;}
    public Boolean recruitingServiceList{get;set;}
    public Boolean approverCommentsList{get;set;}
    public String twoDecimal = '.00';
    public String appendDecimal = '0.00';
    public decimal formatString = 0.00;
    
    
    public NSP_DisplayQliController(){
        
        nonRecurringQLi = new list<QuotLinewrap>();
        nonRecurringTotalQLi = new list<QuotLinewrap>();
        quoteList = true;
        pepmList = true;
        recruitingServiceList = true;
        approverCommentsList = true;
    }
    
 /**
* Method Name : getQliList 
* Description : Method to get list of product and it's pricing on the approval email.
* Author : Raksha       Date : 28/06/2021
* @return List  
*/ 
  public list<QuotLinewrap> getQliList(){
        
        decimal sumUnitPrice = 0;
        decimal sumfinalprice = 0;
        decimal sumdiscountamout = 0;
        
        list<QuotLinewrap> quotelinelist =  new list<QuotLinewrap>();
        
        for(SBQQ__QuoteLine__c eachLine : [select Id,SBQQ__ListPrice__c,SBQQ__ProductName__c,SBQQ__Description__c,NSP_Total_12_Month_ListPrice__c,NSP_Total_12_Month_NetTotal__c,
                                           SBQQ__NetPrice__c,SBQQ__TotalDiscountRate__c,NSP_Net_Total_QQ__c,NSP_List_Total_QQ__c,SBQQ__Discount__c,NSP_Net_Total__c,
                                           SBQQ__TotalDiscountAmount__c,NSP_Quoted_Quantity__c,NSP_Max_Quantity__c,NSP_List_Minimum_Fee__c,NSP_Final_Minimum_Fee__c,NSP_Minimum_Fee_Discount__c 
                                           from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =:quoteIdstr AND SBQQ__Product__r.NSP_Show_On_Approval_Email__c = true order by NSP_Sort_Order_QLI__c]) {
                                            
                                            QuotLinewrap qliWarp = new QuotLinewrap();
                                               if(eachLine.NSP_Max_Quantity__c == null || eachLine.NSP_Quoted_Quantity__c  > eachLine.NSP_Max_Quantity__c){
                                                   qliWarp.description    = eachLine.SBQQ__Description__c;
                                                   qliWarp.unitprice      = (eachLine.SBQQ__ListPrice__c).setScale(2);
                                                   qliWarp.finalprice     = eachLine.SBQQ__NetPrice__c.setScale(2);
                                                   if(eachLine.SBQQ__Discount__c != null) {
                                                       qliWarp.discount = eachLine.SBQQ__Discount__c.setScale(2);
                                                   }
                                                   else if(eachLine.SBQQ__Discount__c == null){
                                                       qliWarp.discount = 0.00;
                                                   }
                                                   qliWarp.discountamout  = (eachLine.SBQQ__TotalDiscountAmount__c).setScale(2);
                                               }
                                               else {
                                                qliWarp.description    = eachLine.SBQQ__Description__c + ''+ ' (Minimum Fee)';
                                                qliWarp.unitprice      = eachLine.NSP_List_Minimum_Fee__c != null ? eachLine.NSP_List_Minimum_Fee__c.setScale(2):formatString;
                                                qliWarp.finalprice     = eachLine.NSP_Final_Minimum_Fee__c != null ? eachLine.NSP_Final_Minimum_Fee__c.setScale(2) : formatString;
                                                qliWarp.discount       = eachLine.NSP_Minimum_Fee_Discount__c.setScale(2);
                                                qliWarp.discountamout  = (qliWarp.unitprice - qliWarp.finalprice).setScale(2);
                                            }
                                            qliWarp.formattedUnitPrice = qliWarp.unitprice > 0 ? (qliWarp.unitprice.format().contains('.')?qliWarp.unitprice.format():(qliWarp.unitprice.format()+twoDecimal)) : appendDecimal;
                                            qliWarp.formattedFinalPrice = qliWarp.unitprice > 0 ? (qliWarp.finalprice.format().contains('.')?qliWarp.finalprice.format():(qliWarp.finalprice.format()+twoDecimal)) : appendDecimal;
                                            qliWarp.formattedDiscPrice = qliWarp.unitprice > 0 ? (qliWarp.discountamout.format().contains('.')?qliWarp.discountamout.format():(qliWarp.discountamout.format()+twoDecimal)) : appendDecimal;
                                              //Update the Total 12 month price
                                               sumUnitPrice          += eachLine.NSP_Total_12_Month_ListPrice__c;
                                               sumfinalprice         += (eachLine.NSP_Total_12_Month_NetTotal__c);
                                               sumdiscountamout      += (eachLine.NSP_Total_12_Month_ListPrice__c - eachLine.NSP_Total_12_Month_NetTotal__c );
                                               quotelinelist.add(qliWarp );
                                               
                                           }
         if(quotelinelist.size() < 1) {
            quoteList = false;
        }      
        
        return quotelinelist;
        
    }
    
  /**
* Method Name : getLastLine 
* Description : Method to query quoteline records which should be visible on approval request email template
* Author : Raksha       Date : 28/06/2021
* @return List  
*/     
    public list<QuotLinewrap> getLastLine(){
        
        decimal sumUnitPrice = 0;
        decimal sumfinalprice = 0;
        decimal sumdiscountamout = 0;
        string sumDescription = 'Total 12 Month Amounts';
        
        list<QuotLinewrap> lastLineList =  new list<QuotLinewrap>();
        
        for(SBQQ__QuoteLine__c eachLine : [select Id,SBQQ__ListPrice__c,SBQQ__ProductName__c,SBQQ__Description__c,NSP_Total_12_Month_ListPrice__c,NSP_Total_12_Month_NetTotal__c,
                                           SBQQ__NetPrice__c,SBQQ__TotalDiscountRate__c,NSP_Net_Total_QQ__c,NSP_List_Total_QQ__c,SBQQ__Discount__c,NSP_Net_Total__c,
                                           SBQQ__TotalDiscountAmount__c,NSP_Quoted_Quantity__c,NSP_Max_Quantity__c,NSP_List_Minimum_Fee__c,NSP_Final_Minimum_Fee__c,NSP_Minimum_Fee_Discount__c 
                                           from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =:quoteIdstr AND SBQQ__Product__r.NSP_Show_On_Approval_Email__c = true order by NSP_Sort_Order_QLI__c]) {
                                            //Update the Total 12 month price
                                               sumUnitPrice          += eachLine.NSP_Total_12_Month_ListPrice__c;
                                               sumfinalprice         += (eachLine.NSP_Total_12_Month_NetTotal__c);
                                               sumdiscountamout      += (eachLine.NSP_Total_12_Month_ListPrice__c - eachLine.NSP_Total_12_Month_NetTotal__c );
                                               
                                               
                                           }
        QuotLinewrap qliWarptotal = new QuotLinewrap();
        qliWarptotal.unitprice   = sumUnitPrice.setScale(2);
        qliWarptotal.finalprice  = sumfinalprice.setScale(2);
        qliWarptotal.discountamout   = sumdiscountamout.setScale(2) ;
        qliWarptotal.discount   = null;
        qliWarptotal.description  = sumDescription ;
        //Update the formatted Unit Price, Final Price after discount and the discounted price
        qliWarptotal.formattedUnitPrice = qliWarptotal.unitprice > 0 ? (qliWarptotal.unitprice.format().contains('.')?qliWarptotal.unitprice.format():(qliWarptotal.unitprice.format()+twoDecimal)) : appendDecimal;
        qliWarptotal.formattedFinalPrice = qliWarptotal.unitprice > 0 ? (qliWarptotal.finalprice.format().contains('.')?qliWarptotal.finalprice.format():(qliWarptotal.finalprice.format()+twoDecimal)) : appendDecimal;
        qliWarptotal.formattedDiscPrice = qliWarptotal.unitprice > 0 ? (qliWarptotal.discountamout.format().contains('.')?qliWarptotal.discountamout.format():(qliWarptotal.discountamout.format()+twoDecimal)) : appendDecimal;
        
        lastLineList.add(qliWarptotal );
        if(lastLineList.size() < 1) {
            quoteList = false;
        }      
        
        return lastLineList;
        
    }
    
    /**
* Method Name : getQliPEPMList 
* Description : Method to query quoteline records which has PEPM products and to be visible on approval request email template
* Author : Raksha       Date : 28/06/2021
* @return List  
*/  
    public list<QuotLinewrap> getQliPEPMList(){
        list<QuotLinewrap> quotelinelist =  new list<QuotLinewrap>();
        for(SBQQ__QuoteLine__c eachLine : [select Id,SBQQ__ListPrice__c,SBQQ__ProductName__c,SBQQ__Description__c,NSP_Positions__c,
                                           SBQQ__NetPrice__c,SBQQ__TotalDiscountRate__c,SBQQ__Discount__c,SBQQ__NetTotal__c,SBQQ__ListTotal__c,NSP_Quoted_Quantity__c,
                                           SBQQ__TotalDiscountAmount__c,SBQQ__Quantity__c,NSP_Max_Quantity__c,NSP_List_Minimum_Fee__c,NSP_Final_Minimum_Fee__c,NSP_Minimum_Fee_Discount__c 
                                           from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =:quoteIdstr AND SBQQ__Product__r.NSP_Include_In_PEPM__c= true order by NSP_Sort_Order_QLI__c]) {
                                               
                                               QuotLinewrap qliWarp = new QuotLinewrap();
                                               
                                               qliWarp.description    = eachLine.SBQQ__Description__c;
                                               qliWarp.unitprice      = eachLine.SBQQ__ListPrice__c.setScale(2);
                                               qliWarp.finalprice     = eachLine.SBQQ__NetPrice__c.setScale(2);
                                               if(eachLine.SBQQ__Discount__c != null) {
                                                   qliWarp.discount = eachLine.SBQQ__Discount__c.setScale(2);
                                               }
                                               else if(eachLine.SBQQ__Discount__c == null){
                                                   qliWarp.discount = 0.00;
                                               }
                                               qliWarp.discountamout  = eachLine.SBQQ__ListPrice__c - eachLine.SBQQ__NetPrice__c.setScale(2);
                                               qliWarp.position       = Integer.valueOf(eachLine.NSP_Positions__c);
                                               qliWarp.numberOfEmployees = Integer.valueOf(eachLine.NSP_Quoted_Quantity__c);
                                                //Update the formatted Unit Price, Final Price after discount and the discounted price
                                               qliWarp.formattedUnitPrice = qliWarp.unitprice > 0 ? (qliWarp.unitprice.format().contains('.')?qliWarp.unitprice.format():(qliWarp.unitprice.format()+twoDecimal)) : appendDecimal;
                                               qliWarp.formattedFinalPrice = qliWarp.unitprice > 0 ? (qliWarp.finalprice.format().contains('.')?qliWarp.finalprice.format():(qliWarp.finalprice.format()+twoDecimal)) : appendDecimal;
                                               qliWarp.formattedDiscPrice = qliWarp.unitprice > 0 ? (qliWarp.discountamout.format().contains('.')?qliWarp.discountamout.format():(qliWarp.discountamout.format()+twoDecimal)) : appendDecimal;
                                               quotelinelist.add(qliWarp);
                                           }
        
        if(quotelinelist.size() < 1) {
            pepmList = false;
        }       
        return quotelinelist;
    }
    
    /**
* Method Name : getQliRecruitingList 
* Description : Method to query quoteline records which has Recruiting products and to be visible on approval request email template
* Author : Raksha       Date : 28/06/2021
* @return List  
*/ 
    
    public list<QuotLinewrap> getQliRecruitingList()
    {
        list<QuotLinewrap> quotelinelist =  new list<QuotLinewrap>();
        for(SBQQ__QuoteLine__c eachLine : [select Id,SBQQ__ListPrice__c,SBQQ__ProductName__c,SBQQ__Description__c,NSP_Positions__c,
                                           SBQQ__NetPrice__c,SBQQ__TotalDiscountRate__c,SBQQ__Discount__c,SBQQ__NetTotal__c,SBQQ__ListTotal__c,
                                           SBQQ__TotalDiscountAmount__c,SBQQ__Quantity__c,NSP_Max_Quantity__c,NSP_List_Minimum_Fee__c,NSP_Final_Minimum_Fee__c,NSP_Minimum_Fee_Discount__c 
                                           from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =:quoteIdstr AND SBQQ__Product__r.NSP_Show_On_Recruitment_Template__c= true order by NSP_Sort_Order_QLI__c]) {
                                               QuotLinewrap qliWarp = new QuotLinewrap();
                                               if(eachLine.SBQQ__Discount__c > 0 || eachLine.NSP_Positions__c > 0) {
                                                   qliWarp.description    = eachLine.SBQQ__Description__c;
                                                   qliWarp.unitprice      = eachLine.SBQQ__ListPrice__c.setScale(2);
                                                   qliWarp.finalprice     = eachLine.SBQQ__NetPrice__c.setScale(2);
                                                   if(eachLine.SBQQ__Discount__c != null) {
                                                       qliWarp.discount = eachLine.SBQQ__Discount__c.setScale(2);
                                                   }
                                                   else if(eachLine.SBQQ__Discount__c == null){
                                                       qliWarp.discount = 0.00;
                                                   }
                                                    //Update the formatted Unit Price, Final Price after discount and the discounted price
                                                   qliWarp.discountamout  = (eachLine.SBQQ__ListPrice__c - eachLine.SBQQ__NetPrice__c).setScale(2);
                                                   qliWarp.position       =Integer.valueOf(eachLine.NSP_Positions__c);
                                                   qliWarp.formattedUnitPrice = qliWarp.unitprice > 0 ? (qliWarp.unitprice.format().contains('.')?qliWarp.unitprice.format():(qliWarp.unitprice.format()+twoDecimal)) : appendDecimal;
                                                   qliWarp.formattedFinalPrice = qliWarp.unitprice > 0 ? (qliWarp.finalprice.format().contains('.')?qliWarp.finalprice.format():(qliWarp.finalprice.format()+twoDecimal)) : appendDecimal;
                                                   qliWarp.formattedDiscPrice = qliWarp.unitprice > 0 ? (qliWarp.discountamout.format().contains('.')?qliWarp.discountamout.format():(qliWarp.discountamout.format()+twoDecimal)) : appendDecimal;
                                                   
                                                   quotelinelist.add(qliWarp);
                                               } 
                                           } 
        if(quotelinelist.size() < 1) {
            recruitingServiceList = false;
        }   
        return quotelinelist;
    }
    
    /**
* Method Name : getApproversComment 
* Description : Method to query approver's comment and return the list to the approval request email template
* Author : Raksha       Date : 28/06/2021
* @return List  
*/ 
    public List<QuotLinewrap> getApproversComment() {
        List<QuotLinewrap> approvalList = new List<QuotLinewrap>();
        for(sbaa__Approval__c approvalRec : [SELECT sbaa__CommentsLong__c 
                                             FROM sbaa__Approval__c WHERE Quote__c =:quoteIdstr]){
                                                 QuotLinewrap qliWarp = new QuotLinewrap();
                                                 if(approvalRec != null && approvalRec.sbaa__CommentsLong__c != null){
                                                     qliWarp.approverComment = approvalRec.sbaa__CommentsLong__c;
                                                     approvalList.add(qliWarp);
                                                 }
                                             }
        
        if(approvalList.size() < 1){
            approverCommentsList = false;
        } 
        return approvalList;
    }
    
    /**
* Method Name : getProductBundleList 
* Description : Method to query the bundle product from the quoteline which is used to display the product bundles
* on Order creation notification email template.
* Author : Raksha       Date : 28/06/2021
* @return List  
*/ 
    public List<QuotLinewrap> getProductBundleList() {
        list<QuotLinewrap> quotelinelist =  new list<QuotLinewrap>();
        for(SBQQ__QuoteLine__c eachLine : [Select Id,SBQQ__ProductName__c,SBQQ__Product__r.description
                                           from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =:quoteIdstr AND NSP_Is_Bundle__c = true ]) {
                                               QuotLinewrap qliWarp = new QuotLinewrap();
                                               qliWarp.description    = eachLine.SBQQ__ProductName__c;
                                               quotelinelist.add(qliWarp);
                                           } 
        
        return quotelinelist;
    }
    
    public class QuotLinewrap{    
        public decimal unitprice {get;set;}
        public decimal discountamout {get;set;}
        public decimal finalprice {get;set;}
        public decimal discount {get;set;}
        public string  description {get;set;}
        public Integer position {get;set;}
        public String approverComment{get;set;}
        public Integer numberOfEmployees{get;set;}
        public String formattedUnitPrice{get;set;}
        public String formattedFinalPrice{get;set;}
        public String formattedDiscPrice{get;set;}
    }
    
}