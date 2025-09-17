//
// Component Name : NSP_DisplayQliController class
// Version :  1.0
// Created Date :  28/06/2021
// Function :  This class is for DisplayQli visualforce component to display quote line date
// Story :  STY-00450
// Modification Log :
// Raksha 28/06/2021 First Iteration
//
// intentionally `without sharing` to ensure VF approval Email template custom controller display all records to be sent to approver's hierarchy. Approvals run in system context.
public without sharing class NSP_DisplayQliController {
    // test w/ NSP_DisplayQliControllerTest (93%)

    public String quoteId;
    public String quoteIdstr{get;set;}
    public list<QuotLinewrap> nonRecurringQLi{get;set;}
    public list<QuotLinewrap> nonRecurringTotalQLi{get;set;}
    public Boolean quoteList{get;set;}
    public Boolean pepmList{get;set;}
    public Boolean recruitingServiceList{get;set;}
    public Boolean recruitingQuote{get;set;}
    public Boolean approverCommentsList{get;set;}
    public String twoDecimal = '.00';
    public String appendDecimal = '0.00';
    public decimal formatString = 0.00;
    public Boolean regularQuoteType{get;set;}

    public NSP_DisplayQliController(){
        nonRecurringQLi = new list<QuotLinewrap>();
        nonRecurringTotalQLi = new list<QuotLinewrap>();
        quoteList = true;
        pepmList = true;
        recruitingServiceList = true;
        approverCommentsList = true;
        recruitingQuote = false;
        regularQuoteType = true;
    }

    //method for checking if the quote is for recruiting services product
    private boolean checkRecruitingQuote( String quoteId ) {
        Boolean isRecruiting = False;
        if ( String.isNotBlank( quoteId ) ) {
            List<SBQQ__Quote__c> quotes = [
                SELECT
                    Id ,
                    SBQQ__Opportunity2__r.NSP_PrimaryProduct__c ,
                    SBQQ__Type__c
                FROM SBQQ__Quote__c
                WHERE ( Id = :quoteId )
                LIMIT 1
            ];
            SBQQ__Quote__c quote = null;
            if ( ( quotes != null ) && !quotes.isEmpty() ) {
                quote = quotes[0];
            }
            if ( ( quote != null )
                && ( quote.SBQQ__Opportunity2__r != null )
                && ( quote.SBQQ__Opportunity2__r.NSP_PrimaryProduct__c != null )
                && ( quote.SBQQ__Opportunity2__r.NSP_PrimaryProduct__c == NSP_SalesConstants.PROD_RECRUITING )
                )
            {
                isRecruiting = True;
            }
            if ( quote.SBQQ__Type__c == 'Amendment' ) {
                regularQuoteType = false;
            }
        }
        return isRecruiting;
    }

    //
    // Method Name : getQliList 
    // Description : Method to get list of product and it's pricing on the approval email.
    // Author : Raksha
    // Date : 28/06/2021
    // @return List
    //
    public List<QuotLinewrap> getQliList() {
        List<QuotLinewrap> quotelinelist =  new List<QuotLinewrap>();
        for ( SBQQ__QuoteLine__c eachLine : [
                    SELECT
                        Id , SBQQ__ListPrice__c , SBQQ__Description__c , NSP_Total_12_Month_ListPrice__c ,
                        NSP_Total_12_Month_NetTotal__c , SBQQ__NetPrice__c , SBQQ__Discount__c ,
                        SBQQ__TotalDiscountAmount__c , Upfront_Fee_Payment_Percentage__c ,
                        Salary_Bracket_Percentage__c , Annual_Base_Salary__c
                    FROM SBQQ__QuoteLine__c
                    WHERE
                    (
                        ( SBQQ__Quote__c =:quoteIdstr ) 
                        AND ( SBQQ__Product__r.NSP_Show_On_Approval_Email__c = true )
                        AND ( NSP_Quoted_Quantity__c > 0 )
                        AND ( NSP_ActionType__c != '')
                    )
                    ORDER BY NSP_Sort_Order_QLI__c
                ]
            )
        {
            QuotLinewrap qliWarp = populateFields(eachLine,true);
            qliWarp.discountamout  = (eachLine.SBQQ__TotalDiscountAmount__c).setScale(2);
            qliWarp.formattedDiscPrice = qliWarp.unitprice > 0 ? formatDecimalField(qliWarp.discountamout) : appendDecimal;
            quotelinelist.add(qliWarp );
        }
        if ( quotelinelist.size() < 1 ) {
            quoteList = false;
        }
        recruitingQuote = checkRecruitingQuote( quoteIdstr );
        return quotelinelist;
    }

    //method to  populate Quote Line Wrapper Fields
    private QuotLinewrap populateFields( SBQQ__QuoteLine__c eachLine , Boolean useRecruitingFields ) {
        QuotLinewrap qliWarp = new QuotLinewrap();
        if ( eachLine != null ) {
            qliWarp.description = eachLine.SBQQ__Description__c;
            qliWarp.unitprice = extractValue(eachLine,'SBQQ__ListPrice__c');
            qliWarp.finalprice = extractValue(eachLine,'SBQQ__NetPrice__c');
            qliWarp.discount = extractValue(eachLine,'SBQQ__Discount__c');
            qliWarp.formattedUnitPrice = qliWarp.unitprice > 0 ? formatDecimalField(qliWarp.unitprice) : appendDecimal;
            qliWarp.formattedFinalPrice = qliWarp.unitprice > 0 ? formatDecimalField(qliWarp.finalprice) : appendDecimal;
            qliWarp = populateRecruitingFields(eachLine,useRecruitingFields,qliWarp);
            qliWarp = formatRecruitingFields(eachLine,useRecruitingFields,qliWarp);
        }
        return qliWarp;
    }
    
    //method to extract Decimal value from Fields
    private Decimal extractValue( SBQQ__QuoteLine__c eachLine , String fieldAPI ) {
        Decimal value = 0;
        if ( ( eachLine != null )
            && ( fieldAPI != null )
            && ( eachLine.get( fieldAPI ) != null )
            )
        {
            value = (Decimal)eachLine.get( fieldAPI );
        }
        value.setScale( 2 );
        return value;
    }

    //method to populate Recruiting Fields on Quote Line Wrapper
    private QuotLinewrap populateRecruitingFields( SBQQ__QuoteLine__c eachLine , Boolean useRecruitingFields , QuotLinewrap qliWarp ) {
        if ( ( eachLine != null ) && ( qliWarp != null ) ) {
            qliWarp.annualBaseSalary = (
                ( eachline.Annual_Base_Salary__c != null && useRecruitingFields )
                ? eachline.Annual_Base_Salary__c.setScale( 2 )
                : 0
            );
            qliWarp.salaryBracketPercent = (
                ( eachline.Salary_Bracket_Percentage__c != null && useRecruitingFields )
                ? eachline.Salary_Bracket_Percentage__c.setScale( 2 )
                : 0
            );
            qliWarp.upfrontPaymentPercent = (
                ( eachline.Upfront_Fee_Payment_Percentage__c != null && useRecruitingFields )
                ? eachline.Upfront_Fee_Payment_Percentage__c.setScale( 2 )
                : 0
            );
        }
        return qliWarp;
    }

    //method to format Recruiting Fields on Quote Line Wrapper
    private QuotLinewrap formatRecruitingFields( SBQQ__QuoteLine__c eachLine , Boolean useRecruitingFields , QuotLinewrap qliWarp ) {
        if ( ( eachLine != null ) && ( qliWarp != null ) ) {
            qliwarp.formattedUFP = (
                ( qliWarp.unitprice > 0 && useRecruitingFields )
                ? formatDecimalField( qliWarp.upfrontPaymentPercent )
                : appendDecimal
            );
            qliwarp.formattedABS = (
                ( qliWarp.unitprice > 0 && useRecruitingFields )
                ? formatDecimalField( qliWarp.annualBaseSalary )
                : appendDecimal
            );
            qliwarp.formattedSBP = (
                ( qliWarp.unitprice > 0 && useRecruitingFields )
                ? formatDecimalField( qliWarp.salaryBracketPercent )
                : appendDecimal
            );
        }
        return qliWarp;
    }

    //method to format decimal into string
    private String formatDecimalField( Decimal fieldValue ) {
        String retString ='';
        if ( fieldValue != null ) {
            retString = (
                fieldValue.format().contains( '.' )
                ? fieldValue.format()
                : ( fieldValue.format() + twoDecimal )
            );
        }
        return retString;
    }

    //
    // Method Name : getLastLine 
    // Description : Method to query quoteline records which should be visible on approval request email template
    // Author : Raksha
    // Date : 28/06/2021
    // @return List
    //
    public List<QuotLinewrap> getLastLine() {
        Decimal sumUnitPrice = 0;
        Decimal sumfinalprice = 0;
        Decimal sumdiscountamout = 0;
        String sumDescription = 'Total 12 Month Amounts';
        List<QuotLinewrap> lastLineList = new List<QuotLinewrap>();
        for ( SBQQ__QuoteLine__c eachLine : [
                    SELECT
                        Id , SBQQ__ListPrice__c , SBQQ__ProductName__c ,
                        SBQQ__Description__c , NSP_Total_12_Month_ListPrice__c ,
                        NSP_Total_12_Month_NetTotal__c , SBQQ__NetPrice__c ,
                        SBQQ__TotalDiscountRate__c , NSP_Net_Total_QQ__c ,
                        NSP_List_Total_QQ__c , SBQQ__Discount__c ,
                        NSP_Net_Total__c , SBQQ__TotalDiscountAmount__c ,
                        NSP_Quoted_Quantity__c , NSP_Max_Quantity__c ,
                        NSP_List_Minimum_Fee__c , NSP_Final_Minimum_Fee__c ,
                        NSP_Minimum_Fee_Discount__c
                    FROM SBQQ__QuoteLine__c
                    WHERE (
                        ( SBQQ__Quote__c = :quoteIdstr )
                        AND ( SBQQ__Product__r.NSP_Show_On_Approval_Email__c = true )
                        AND ( NSP_Quoted_Quantity__c > 0 )
                    )
                    ORDER BY NSP_Sort_Order_QLI__c
                ]
            )
        {
            //Update the Total 12 month price
            Decimal listPrice = extractValue(eachLine,'NSP_Total_12_Month_ListPrice__c');
            Decimal netPrice = extractValue(eachLine,'NSP_Total_12_Month_NetTotal__c');
            sumUnitPrice += listPrice;
            sumfinalprice += netPrice;
            sumdiscountamout += (listPrice - netPrice);
        }
        QuotLinewrap qliWarptotal = new QuotLinewrap();
        qliWarptotal.unitprice = sumUnitPrice.setScale(2);
        qliWarptotal.finalprice = sumfinalprice.setScale(2);
        qliWarptotal.discountamout = sumdiscountamout.setScale(2);
        qliWarptotal.discount = null;
        qliWarptotal.description = sumDescription ;
        qliWarptotal.annualBaseSalary = 0;
        qliWarptotal.salaryBracketPercent = 0;
        qliWarptotal.upfrontPaymentPercent = 0;
        qliWarptotal.formattedUFP = appendDecimal;
        qliWarptotal.formattedABS = appendDecimal;
        qliWarptotal.formattedSBP = appendDecimal;
        //Update the formatted Unit Price, Final Price after discount and the discounted price
        qliWarptotal.formattedUnitPrice = qliWarptotal.unitprice > 0 ? formatDecimalField(qliWarptotal.unitprice) : appendDecimal;
        qliWarptotal.formattedFinalPrice = qliWarptotal.unitprice > 0 ? formatDecimalField(qliWarptotal.finalprice) : appendDecimal;
        qliWarptotal.formattedDiscPrice = qliWarptotal.unitprice > 0 ? formatDecimalField(qliWarptotal.discountamout) : appendDecimal;
        lastLineList.add( qliWarptotal );
        if ( lastLineList.size() < 1 ) {
            quoteList = false;
        }
        return lastLineList;
    }

    //
    // Method Name : getQliPEPMList 
    // Description : Method to query quoteline records which has PEPM products and to be visible on approval request email template
    // Author : Raksha
    // Date : 28/06/2021
    // @return List
    //
    public List<QuotLinewrap> getQliPEPMList() {
        List<QuotLinewrap> quotelinelist = new List<QuotLinewrap>();
        for ( SBQQ__QuoteLine__c eachLine : [
                    SELECT
                        Id , SBQQ__ListPrice__c , SBQQ__ProductName__c ,
                        SBQQ__Description__c , NSP_Positions__c ,
                        SBQQ__NetPrice__c , SBQQ__TotalDiscountRate__c ,
                        SBQQ__Discount__c , SBQQ__NetTotal__c ,
                        SBQQ__ListTotal__c , NSP_Quoted_Quantity__c ,
                        SBQQ__TotalDiscountAmount__c , SBQQ__Quantity__c ,
                        NSP_Max_Quantity__c , NSP_List_Minimum_Fee__c ,
                        NSP_Final_Minimum_Fee__c , NSP_Minimum_Fee_Discount__c ,
                        Annual_Base_Salary__c , Salary_Bracket_Percentage__c ,
                        Upfront_Fee_Payment_Percentage__c
                    FROM SBQQ__QuoteLine__c
                    WHERE (
                        ( SBQQ__Quote__c = :quoteIdstr )
                        AND ( SBQQ__Product__r.NSP_Include_In_PEPM__c = true )
                        AND ( NSP_Quoted_Quantity__c > 0 )
                    )
                    ORDER BY NSP_Sort_Order_QLI__c
                ]
            )
        {
            QuotLinewrap qliWarp = new QuotLinewrap();
            
            qliWarp = populateFields(eachLine, false);
            qliWarp.discountamout  = (eachLine.SBQQ__ListPrice__c - eachLine.SBQQ__NetPrice__c).setScale(2);
            qliWarp.formattedDiscPrice = qliWarp.unitprice > 0 ? formatDecimalField(qliWarp.discountamout) : appendDecimal;
            qliWarp.position = ( eachLine.NSP_Positions__c != null ) ? Integer.valueOf(eachLine.NSP_Positions__c) : 0;
            qliWarp.numberOfEmployees = ( eachLine.NSP_Quoted_Quantity__c != null ) ? Integer.valueOf(eachLine.NSP_Quoted_Quantity__c) : 0;
            //Update the formatted Unit Price, Final Price after discount and the discounted price
            quotelinelist.add(qliWarp);
        }
        if ( quotelinelist.size() < 1 ) {
            pepmList = false;
        }
        return quotelinelist;
    }

    //
    // Method Name : getQliRecruitingList 
    // Description : Method to query quoteline records which has Recruiting products and to be visible on approval request email template
    // Author : Raksha
    // Date : 28/06/2021
    // @return List
    //
    public List<QuotLinewrap> getQliRecruitingList() {
        List<QuotLinewrap> quotelinelist = new List<QuotLinewrap>();
        for ( SBQQ__QuoteLine__c eachLine : [
                    SELECT
                        Id , SBQQ__ListPrice__c , SBQQ__ProductName__c ,
                        SBQQ__Description__c , NSP_Positions__c ,
                        SBQQ__NetPrice__c , SBQQ__TotalDiscountRate__c ,
                        SBQQ__Discount__c , SBQQ__NetTotal__c ,
                        SBQQ__ListTotal__c , SBQQ__TotalDiscountAmount__c ,
                        SBQQ__Quantity__c , NSP_Max_Quantity__c ,
                        NSP_List_Minimum_Fee__c , NSP_Final_Minimum_Fee__c ,
                        NSP_Minimum_Fee_Discount__c , Annual_Base_Salary__c ,
                        Salary_Bracket_Percentage__c , Upfront_Fee_Payment_Percentage__c
                    FROM SBQQ__QuoteLine__c
                    WHERE (
                        ( SBQQ__Quote__c = :quoteIdstr )
                        AND ( SBQQ__Product__r.NSP_Show_On_Recruitment_Template__c = true )
                        AND ( NSP_Quoted_Quantity__c > 0 )
                    )
                    ORDER BY NSP_Sort_Order_QLI__c
                ]
            )
        {
            QuotLinewrap qliWarp = new QuotLinewrap();
            if ( ( eachLine.SBQQ__Discount__c > 0 )
                || ( ( eachLine.NSP_Positions__c != null ) && ( eachLine.NSP_Positions__c > 0 ) )
                )
            {
                qliWarp = populateFields( eachLine , false );
                qliWarp.discountamout = ( eachLine.SBQQ__ListPrice__c - eachLine.SBQQ__NetPrice__c ).setScale( 2 );
                qliWarp.position = ( eachLine.NSP_Positions__c != null ) ? Integer.valueOf( eachLine.NSP_Positions__c ) : 0;
                quotelinelist.add( qliWarp );
            }
        }
        if ( quotelinelist.size() < 1 ) {
            recruitingServiceList = false;
        }
        return quotelinelist;
    }

    //
    // Method Name : getApproversComment 
    // Description : Method to query approver's comment and return the list to the approval request email template
    // Author : Raksha Date : 28/06/2021
    // @return List
    //
    public List<QuotLinewrap> getApproversComment() {
        List<QuotLinewrap> approvalList = new List<QuotLinewrap>();
        for ( sbaa__Approval__c approvalRec : [
                SELECT sbaa__CommentsLong__c 
                FROM sbaa__Approval__c
                WHERE Quote__c = :quoteIdstr
                ]
            )
        {
            QuotLinewrap qliWarp = new QuotLinewrap();
            if ( approvalRec != null && approvalRec.sbaa__CommentsLong__c != null ) {
                qliWarp.approverComment = approvalRec.sbaa__CommentsLong__c;
                approvalList.add( qliWarp );
            }
        }
        if ( approvalList.size() < 1 ) {
            approverCommentsList = false;
        }
        return approvalList;
    }

    //
    // Method Name : getProductBundleList 
    // Description : Method to query the bundle product from the quoteline which is used to display the product bundles
    // on Order creation notification email template.
    // Author : Raksha Date : 28/06/2021
    // @return List
    //
    public List<QuotLinewrap> getProductBundleList() {
        list<QuotLinewrap> quotelinelist =  new list<QuotLinewrap>();
        for ( SBQQ__QuoteLine__c eachLine : [
                    SELECT Id , SBQQ__ProductName__c , SBQQ__Product__r.Description
                    FROM SBQQ__QuoteLine__c
                    WHERE (
                        SBQQ__Quote__c = :quoteIdstr
                        AND NSP_Is_Bundle__c = true
                    )
                ]
            )
        {
            QuotLinewrap qliWarp = new QuotLinewrap();
            qliWarp.description = eachLine.SBQQ__ProductName__c;
            quotelinelist.add( qliWarp );
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
        public Decimal annualBaseSalary {get;set;}
        public Decimal salaryBracketPercent {get;set;}
        public Decimal upfrontPaymentPercent {get;set;}
        public String formattedABS {get;set;}
        public String formattedSBP {get;set;}
        public String formattedUFP {get;set;}
    }

}
//