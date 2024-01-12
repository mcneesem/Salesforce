/**
* Represents the Additional Payroll Contact helper which handles all the logic.
*/
public class NSP_AdditionalPayrollContactHelper {
    
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
    
    
}