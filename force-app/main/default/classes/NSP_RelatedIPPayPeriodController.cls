/**
* Represents the NSP_RelatedIPPayPeriodController for Related Implementation pay periods logic email Templates.
*/
public class NSP_RelatedIPPayPeriodController {
    // test w/ NSP_RelatedIPPayPeriodControllerTest (96%)

    public NSP_RelatedIPPayPeriodController(){
        
    }
    
    public static String recId;
    
    //set recordId
    public static void setrecId (String recordId) {
        recId = recordId;
    }
    //get recordId
    public static String getrecId() {
        return recId;
    }
    
    public static List<Implementation_Pay_Period__c> relatedIPpayPeriods {
        get{
            if ( recId != null ){
                List<Implementation_Pay_Period__c> local = [SELECT Id, 
                                    Frequency__c, 
                                    Final_pay_period_prior_to_Insperity__c, 
                                    Final_pay_date_prior_to_Insperity__c 
                                    FROM Implementation_Pay_Period__c 
                                    WHERE NSP_Implementation_Profile__c =: recId
                                    AND Final_pay_period_prior_to_Insperity__c!=NULL
                                    AND Final_pay_date_prior_to_Insperity__c!=NULL
                                    AND Does_the_client_have_prior_wages__c = :NSP_ServiceConstants.YES
                                    ];
                relatedIPpayPeriods = local;
                }
            return relatedIPpayPeriods;
        }
        set;
    }

    public static List<NSP_IP_Additional_Client_Contact__c> additionalClientContacts {
        get{
            if ( recId != null ){
                List<NSP_IP_Additional_Client_Contact__c> local = [SELECT Id, 
                                    NSP_Contact_Type__c, 
                                    Name, 
                                    NSP_Email_Address__c 
                                    FROM NSP_IP_Additional_Client_Contact__c 
                                    WHERE NSP_Implementation_Profile__c =: recId
                                    AND NSP_Contact_Type__c =:NSP_ServiceConstants.PC_TYPE
                                    ];
                additionalClientContacts = local;
                }
            return additionalClientContacts;
        }
        set;
    }

    public static List<Implementation_Pay_Period__c> additionalArrearageFrequency {
        get{
            if ( recId != null ){
                List<Implementation_Pay_Period__c> local = [SELECT Id, Frequency__c, Is_arrearage_7_days__c, 
                                    Have_credit_services_approved__c
                   					FROM Implementation_Pay_Period__c 
                                    WHERE NSP_Implementation_Profile__c =: recId AND
                                    Is_arrearage_7_days__c = :NSP_ServiceConstants.YES AND
									Have_credit_services_approved__c = :NSP_ServiceConstants.NO ];
                additionalArrearageFrequency = local;
                }
            return additionalArrearageFrequency;
        }
        set;
    }

}