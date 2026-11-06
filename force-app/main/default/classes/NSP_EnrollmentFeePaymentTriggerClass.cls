// intentionally `without sharing` to preserve default sharing at api version 55...
public without sharing class NSP_EnrollmentFeePaymentTriggerClass {
    // test w/ NSP_EnrollmentFeePaymentTriggerClassTest (76%)

    public static void sumofEnrollmentFee( List<NSP_Enrollment_Fee_Payment__c> listOfEnrollmentFee ) {
        Set<Id> opportunityIds=new Set<Id>(); //Holds the opportunity id's
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>(); //Holds the opportunity details to update
        for ( NSP_Enrollment_Fee_Payment__c feepayment : listOfEnrollmentFee ) {
            if ( feepayment.NSP_Opportunity__c != null ) {
                opportunityIds.add( feepayment.NSP_Opportunity__c );
            }
        }
        List<Opportunity> opptyList = new List<Opportunity>();
        Opportunity opp;
        if ( !opportunityIds.isEmpty() ) {
            //Enrollment Fee Payment 1 field update on opportunity
            for ( AggregateResult aRes : [
                        SELECT NSP_Opportunity__c, SUM(NSP_Payment_Amount__c) TotalPayment1
                        FROM NSP_Enrollment_Fee_Payment__c
                        WHERE NSP_Opportunity__c IN :opportunityIds AND NSP_Payment_Number__c='1'  GROUP BY NSP_Opportunity__c
                    ]
                )
            {
                opp = new Opportunity();
                opp.Id = (Id)aRes.get('NSP_Opportunity__c');
                opp.NSP_Enrollment_Fee_Payment_1__c = (Decimal)aRes.get('TotalPayment1');
                oppMap.put((Id)aRes.get('NSP_Opportunity__c'), opp);
            }
            //Enrollment Fee Payment 2 field update on opportunity
            for ( AggregateResult aRes1 : [
                        SELECT NSP_Opportunity__c, SUM(NSP_Payment_Amount__c) TotalPayment2
                        FROM NSP_Enrollment_Fee_Payment__c
                        WHERE NSP_Opportunity__c IN :opportunityIds AND NSP_Payment_Number__c='2'  GROUP BY NSP_Opportunity__c
                    ]
                )
            {
                if((!oppMap.keySet().isEmpty()) && oppMap.keySet().contains((Id)aRes1.get('NSP_Opportunity__c'))){
                    oppMap.get((Id)aRes1.get('NSP_Opportunity__c')).NSP_Enrollment_Fee_Payment_2__c = (Decimal)aRes1.get('TotalPayment2');
                }else{
                    opp = new Opportunity();
                    opp.Id = (Id)aRes1.get('NSP_Opportunity__c');
                    opp.NSP_Enrollment_Fee_Payment_2__c = (Decimal)aRes1.get('TotalPayment2');
                    oppMap.put((Id)aRes1.get('NSP_Opportunity__c'), opp);
                }
            }
            //Enrollment Fee Payment 3 field update on opportunity
            for ( AggregateResult aRes2 : [
                        SELECT NSP_Opportunity__c, SUM(NSP_Payment_Amount__c) TotalPayment3
                        FROM NSP_Enrollment_Fee_Payment__c
                        WHERE NSP_Opportunity__c IN :opportunityIds AND NSP_Payment_Number__c='3'  GROUP BY NSP_Opportunity__c
                    ]
                )
            {
                if((!oppMap.keySet().isEmpty()) && oppMap.keySet().contains((Id)aRes2.get('NSP_Opportunity__c'))){
                    oppMap.get((Id)aRes2.get('NSP_Opportunity__c')).NSP_Enrollment_Fee_Payment_3__c = (Decimal)aRes2.get('TotalPayment3');
                }else{
                    opp = new Opportunity();
                    opp.Id = (Id)aRes2.get('NSP_Opportunity__c');
                    opp.NSP_Enrollment_Fee_Payment_3__c = (Decimal)aRes2.get('TotalPayment3');
                    oppMap.put((Id)aRes2.get('NSP_Opportunity__c'), opp);
                }
            }
            //Enrollment Fee Payment 4 field update on opportunity
            for ( AggregateResult aRes3 : [
                        SELECT NSP_Opportunity__c, SUM(NSP_Payment_Amount__c) TotalPayment4
                        FROM NSP_Enrollment_Fee_Payment__c
                        WHERE NSP_Opportunity__c IN :opportunityIds AND NSP_Payment_Number__c='4'  GROUP BY NSP_Opportunity__c
                    ]
                )
            {
                if((!oppMap.keySet().isEmpty()) && oppMap.keySet().contains((Id)aRes3.get('NSP_Opportunity__c'))){
                    oppMap.get((Id)aRes3.get('NSP_Opportunity__c')).NSP_Enrollment_Fee_Payment_4__c = (Decimal)aRes3.get('TotalPayment4');
                }else{
                    opp = new Opportunity();
                    opp.Id = (Id)aRes3.get('NSP_Opportunity__c');
                    opp.NSP_Enrollment_Fee_Payment_4__c = (Decimal)aRes3.get('TotalPayment4');
                    oppMap.put((Id)aRes3.get('NSP_Opportunity__c'), opp);
                }
            }
            //Enrollment Fee Payment 5 field update on opportunity
            for ( AggregateResult aRes4 : [
                        SELECT NSP_Opportunity__c, SUM(NSP_Payment_Amount__c) TotalPayment5
                        FROM NSP_Enrollment_Fee_Payment__c
                        WHERE NSP_Opportunity__c IN :opportunityIds AND NSP_Payment_Number__c='5'  GROUP BY NSP_Opportunity__c
                    ]
                )
            {
                if((!oppMap.keySet().isEmpty()) && oppMap.keySet().contains((Id)aRes4.get('NSP_Opportunity__c'))){
                    oppMap.get((Id)aRes4.get('NSP_Opportunity__c')).NSP_Enrollment_Fee_Payment_5__c = (Decimal)aRes4.get('TotalPayment5');
                }else{
                    opp = new Opportunity();
                    opp.Id = (Id)aRes4.get('NSP_Opportunity__c');
                    opp.NSP_Enrollment_Fee_Payment_5__c = (Decimal)aRes4.get('TotalPayment5');
                    oppMap.put((Id)aRes4.get('NSP_Opportunity__c'), opp);
                }
            }
            //Enrollment Fee Payment 6 field update on opportunity
            for ( AggregateResult aRes5 : [
                        SELECT NSP_Opportunity__c, SUM(NSP_Payment_Amount__c) TotalPayment6
                        FROM NSP_Enrollment_Fee_Payment__c
                        WHERE NSP_Opportunity__c IN :opportunityIds AND NSP_Payment_Number__c='6'  GROUP BY NSP_Opportunity__c
                    ]
                )
            {
                if((!oppMap.keySet().isEmpty()) && oppMap.keySet().contains((Id)aRes5.get('NSP_Opportunity__c'))){
                    oppMap.get((Id)aRes5.get('NSP_Opportunity__c')).NSP_Enrollment_Fee_Payment_6__c = (Decimal)aRes5.get('TotalPayment6');
                }else{
                    opp = new Opportunity();
                    opp.Id = (Id)aRes5.get('NSP_Opportunity__c');
                    opp.NSP_Enrollment_Fee_Payment_6__c = (Decimal)aRes5.get('TotalPayment6');
                    oppMap.put((Id)aRes5.get('NSP_Opportunity__c'), opp);
                }
            }
        }
        //Updating Opportunity
        try {
            if ( !oppMap.values().isEmpty() ) {
                Database.update( oppMap.values() );
            }
        } catch ( Exception e ) {
            System.debug( ' ~ CATCH ~ e=' + e );
        }
    }

    //
    // Method Name : createBillingPayment
    // Description : Method to create payment record once cusomer pays the amount
    // @param listOfEnrollmentFee list  of New Enrollment Fee.
    // @param enrollmentOldMap Map of Old New Enrollment Fee.
    // @return void
    //
    public static void createBillingPayment(
        List<NSP_Enrollment_Fee_Payment__c> listOfEnrollmentFee ,
        Map<Id,NSP_Enrollment_Fee_Payment__c> enrollmentOldMap
        )
    {
        List<blng__Payment__c> paymentsToCreate= new List<blng__Payment__c>();
        for(NSP_Enrollment_Fee_Payment__c fee: listOfEnrollmentFee){
            if(fee.NSP_WX_WA_Enrollment_Fee_Received__c!=null && fee.NSP_WX_WA_Enrollment_Fee_Received__c!=enrollmentOldMap.get(fee.Id).NSP_WX_WA_Enrollment_Fee_Received__c){
                blng__Payment__c currPayment = new blng__Payment__c();
                currPayment.blng__Account__c = fee.NSP_Account_Id__c;
                currPayment.blng__Amount__c = fee.NSP_WX_WA_Enrollment_Fee_Received__c;
                currPayment.NSP_Enrollment_Fee_Payment__c=fee.Id;
                currPayment.blng__GLRule__c=getGLruleInfo(NSP_CPQConstants.PAYMYENT_GL_RULE)?.blng__GLRule__c;
                currPayment.blng__GLTreatment__c=getGLruleInfo(NSP_CPQConstants.PAYMYENT_GL_RULE)?.Id;
                currPayment.blng__LegalEntity__c=getGLruleInfo(NSP_CPQConstants.PAYMYENT_GL_RULE)?.blng__GLLegalEntity__c;
                paymentsToCreate.add(currPayment);
            }
        }
        if ( !paymentsToCreate.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( paymentsToCreate , false );
            NSP_ErrorLogHandler.logResults(
                NSP_EnrollmentFeePaymentTriggerClass.class.getName() ,
                'createBillingPayment' ,
                results
            );
        }
    }

    private static blng__GLTreatment__c getGLruleInfo( String name ) {
        List<blng__GLTreatment__c> treatments = [
            SELECT Id , blng__GLLegalEntity__c , blng__GLRule__c
            FROM blng__GLTreatment__c
            WHERE ( Name = :name )
            LIMIT 1
        ];
        blng__GLTreatment__c treatment = null;
        if ( !treatments.isEmpty() ) {
            treatment = treatments[0];
        }
        return treatment;
    }

    //
    // MethodName: enrollmentFeeMidMarket
    // Description : This method will set NSP_Is_MidMarket__c as true upon insert of enrollment fee payment
    // Params:      List<NSP_Enrollment_Fee_Payment__c> listOfEnrollmentFee
    //
    public static void enrollmentFeeMidMarket( List<NSP_Enrollment_Fee_Payment__c> listOfEnrollmentFee ) {
        Set<Id> opportunityIds=new Set<Id>(); //Holds the opportunity id's
        Map<Id,Id> oppEnrollMap = new Map<Id,Id>();
        Set<Id> oppIdEnrollment=new Set<Id>();
        for ( NSP_Enrollment_Fee_Payment__c feepayment : listOfEnrollmentFee ) {
            if ( feepayment.NSP_Opportunity__c != null ) {
                opportunityIds.add( feepayment.NSP_Opportunity__c );
                oppEnrollMap.put( feepayment.Id , feepayment.NSP_Opportunity__c );
            }
        }
        if ( Trigger.isInsert ) {
            //Modified for user story 192368
            for ( Opportunity enrollId :[
                        SELECT Id
                        FROM Opportunity
                        WHERE (
                            ( Id IN :opportunityIds )
                            AND (
                                ( NSP_Number_of_Employees__c >= 150 )
                                OR ( NSP_MidMarketNationalAccount__c != null )
                            )
                        )
                    ]
                )
            {
                oppIdEnrollment.add( enrollId.Id );
            }
            if ( !oppIdEnrollment.isEmpty() ) {
                for ( NSP_Enrollment_Fee_Payment__c enrollId : listOfEnrollmentFee ) {
                    if ( oppIdEnrollment.contains( oppEnrollMap.get( enrollId.Id ) ) ) {
                        enrollId.NSP_Is_MidMarket__c = true;
                    }
                }
            }
        }
    }

}
//
