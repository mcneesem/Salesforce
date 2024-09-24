/**
* Represents the Additional Payroll Contact helper which handles all the logic.
*/
public class NSP_AdditionalPayrollContactHelper {
   // test w/ NSP_AdditionalPayrollContactHelperTest (91%)
    
    /**
* This method will populate Email, Phone, International Phone and Office Phone from selected Contact
* @param listOfAdditionalPayrollContact: List of Additional Payroll Contacts.
* @return void             
*                
*/
    public void updateContactEmailAndPhoneOnAdditionalPayrollContact(List<Additional_Payroll_Contact__c> listOfAdditionalPayrollContact){
        Map<Id, Contact> mapOfContactIdAndContact = new Map<Id, Contact>();
        Set<Id> setOfcontactId                    = new Set<Id>();
        
        
        for(Additional_Payroll_Contact__c AdditionalPayrollContact : listOfAdditionalPayrollContact){
            //When a Contect is selected on Additional Payroll Contact Record, Get the contact details.
            if(AdditionalPayrollContact.Contact__c != null){
                setOfContactId.add(AdditionalPayrollContact.Contact__c);
            }
        }
        
        for(Contact con : [SELECT NSP_Work_email__c, Phone, NSP_Work_Phone__c, MobilePhone FROM Contact WHERE ID IN : setOfContactId]){
            //When the Map does not contain the Key
            if(!mapOfContactIdAndContact.containsKey(con.id)){
                mapOfContactIdAndContact.put(con.id, con);
            }
        }
        
        for(Additional_Payroll_Contact__c AdditionalPayrollContact : listOfAdditionalPayrollContact){
            //When Contact is Selected on Additional Payroll Contact Record, Auto-Populate Email, Phone, International Phone and Office Phone of the Contact. 
            if(AdditionalPayrollContact.Contact__c != null && !mapOfContactIdAndContact.isEmpty()){
                if(AdditionalPayrollContact.NSP_Contact_Cell__c == null){
                   AdditionalPayrollContact.NSP_Contact_Cell__c = mapOfContactIdAndContact.get(AdditionalPayrollContact.Contact__c).MobilePhone;  
                }
                if(AdditionalPayrollContact.NSP_Contact_International_Phone__c == null){
                   AdditionalPayrollContact.NSP_Contact_International_Phone__c = mapOfContactIdAndContact.get(AdditionalPayrollContact.Contact__c).phone;                  
                }
                AdditionalPayrollContact.NSP_Contact_Email__c = mapOfContactIdAndContact.get(AdditionalPayrollContact.Contact__c).NSP_Work_email__c;
                AdditionalPayrollContact.NSP_Contact_Office_Phone__c = mapOfContactIdAndContact.get(AdditionalPayrollContact.Contact__c).NSP_Work_Phone__c;
            }
        }
    } 
    
    public void updateRelatedPayrollDataSheetRecords(List<Additional_Payroll_Contact__c> listOfAdditionalPayrollContact, Map<Id,Additional_Payroll_Contact__c> oldMap){
        Set<Id> setPayrollsId = new Set<Id>();
        List<NSP_Payroll__c> lstOfPayrolls = new List<NSP_Payroll__c>();
        if(listOfAdditionalPayrollContact != null){
            for(Additional_Payroll_Contact__c apContact : listOfAdditionalPayrollContact){
                Additional_Payroll_Contact__c oldMapAPC = null;
                if(oldMap != null){
                    oldMapAPC = oldMap.get(apContact.Id);
                }
                if ( (apContact.Payroll__c != null && apContact.View_Payroll_Paperwork__c)
                    || (
                        oldMapAPC != null
                        && (
                            (oldMapAPC.Payroll__c != apContact.Payroll__c)
                            || (oldMapAPC.View_Payroll_Paperwork__c != apContact.View_Payroll_Paperwork__c)
                            )
                        )
                    )
                {
                    setPayrollsId.add(apContact.Payroll__c);
                }
            }
            if(!setPayrollsId.isEmpty()){
                lstOfPayrolls = [
                    SELECT
                        Id, Name, NSP_Back_Up_Payroll_Contact__c, Back_Up_View_Payroll_Paperwork__c,
                        NSP_On_site_Supervisor__c, On_Site_View_Payroll_Paperwork__c,
                        NSP_Primary_Payroll_Contact__c, Primary_View_Payroll_Paperwork__c,
                        NSP_HR_Contact__c, View_Payroll_Paperwork__c, NSP_Sub_Client_Name__c, Account__c
                    FROM NSP_Payroll__c
                    WHERE Id IN :setPayrollsId
                ];
                if(lstOfPayrolls != null){
                    NSP_PayrollTriggerHelper payrollTriggerHelper = new NSP_PayrollTriggerHelper();
                    payrollTriggerHelper.fieldUpdatesAfterInsertUpdate(lstOfPayrolls , null , null , false);
                }
            }
        }
    }
    
}