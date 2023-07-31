/**
* @description  : Apex Class to process the termination form for the email template.
* @author Shruti Patil
* @date : 10/18/2021
* Name : NSP_TerminationFormTemplateController
*Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Rahul Singh                 03/23/23               DF-03218
*/

public with sharing class NSP_TerminationFormTemplateController {
    public List<wrapTermination> wrapTerminationList {get; set;}
    public List<NSP_Termination_Form__c> reinstatementList {get;set;}
   
    public NSP_TerminationFormTemplateController(){
        
        Map<Id, NSP_Termination_Form__c> accountWithTerminationMap = new Map<Id, NSP_Termination_Form__c>(); 
        Map<Id, List<NSP_Account_Team__c>> accountWithAccountTeammemberMap = new Map<Id, List<NSP_Account_Team__c>>(); 
        List<NSP_Termination_Form__c> terminationFormList = [SELECT Id, Name, NSP_Client_Term_Date__c, 
                                                             NSP_Status__c, NSP_Term_Code__c, NSP_Number_of_Active_Employees__c,
                                                             NSP_Benefit_Termination_Date__c, 
                                                             NSP_Project_Task__r.pse__Project__r.pse__Account__c,
                                                             NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name, 
                                                             NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c,  
                                                             NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c 
                                                             FROM NSP_Termination_Form__c 
                                                             WHERE NSP_Client_Term_Date__c = LAST_N_DAYS:22 AND NSP_Status__c = 'Term Team Approved' AND 
                                                             NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c != 'Complete'];

        reinstatementList = [SELECT Id, Name, NSP_Status__c,  
                            NSP_Project_Task__r.pse__Project__r.pse__Account__c,
                            NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name, 
                            NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c
                            FROM NSP_Termination_Form__c 
                            WHERE NSP_Client_Term_Date__c = LAST_N_DAYS:22 AND NSP_Status__c = 'Term Team Approved' AND 
                            NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c != 'Complete' AND  
                            NSP_Project_Task__r.Name = : NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK];

        if(wrapTerminationList == null) {
            wrapTerminationList = new List<wrapTermination>();
            for(NSP_Termination_Form__c termination: terminationFormList) {
                if(termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c != null){
                    accountWithTerminationMap.put(termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c, termination);
                }
            }
            if(!accountWithTerminationMap.isEmpty()){
                for(NSP_Account_Team__c AccTeamMember : [SELECT Id, NSP_Role__c, NSP_Account__c, NSP_Email__c,
                                                         NSP_First_Name__c, NSP_Last_Name__c
                                                         FROM NSP_Account_Team__c 
                                                         WHERE NSP_Account__c IN: accountWithTerminationMap.keySet()
                                                         AND NSP_Role__c != null]){
                    if(!accountWithAccountTeammemberMap.containsKey(AccTeamMember.NSP_Account__c)){
                        accountWithAccountTeammemberMap.put(AccTeamMember.NSP_Account__c, new List<NSP_Account_Team__c>());
                    } 
                    accountWithAccountTeammemberMap.get(AccTeamMember.NSP_Account__c).add(AccTeamMember); 
                }
            }
            if(!accountWithTerminationMap.isEmpty() && !accountWithAccountTeammemberMap.isEmpty()){
                for(NSP_Termination_Form__c termination : terminationFormList){
                    String PS;
                    String CL;
                     if(termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c != null){  // Added as part of DF-03218
                    for(NSP_Account_Team__c accTeamMember : accountWithAccountTeammemberMap.get(termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c)){
                        if(accTeamMember.NSP_Role__c != null){                    
                             if(accTeamMember.NSP_Role__c == 'Payroll Specialist'){
                                 PS = accTeamMember.NSP_First_Name__c+' '+accTeamMember.NSP_Last_Name__c;
                             }
                             if(accTeamMember.NSP_Role__c == 'Client Liaison'){
                                 CL = accTeamMember.NSP_First_Name__c+' '+accTeamMember.NSP_Last_Name__c;
                             }
                        }
                    }                     
                    wrapTerminationList.add(new wrapTermination(termination, PS, CL));              
                } 
                }
            }  
        }
    }
    
    // Getting the Document Id and creating a Document Url.
    public String getTopLogoUrl(){
        list<Document> lstDocument = [SELECT Id FROM Document WHERE DeveloperName = 'Insperity_Service_Operations'];
        String strOrgId = UserInfo.getOrganizationId();
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + 
                            '/servlet/servlet.ImageServer?id='+lstDocument[0].Id +
                            '&oid=' + strOrgId;
        return strLogoUrl;
    }
    
    // Getting the Document Id and creating a Document Url.
    public String getBottomLogoUrl(){
        list<Document> lstDocument = [SELECT Id FROM Document WHERE DeveloperName = 'Insperity_Copy_write_logo'];
        String strOrgId = UserInfo.getOrganizationId();
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + 
                            '/servlet/servlet.ImageServer?id='+lstDocument[0].Id +
                            '&oid=' + strOrgId;
        return strLogoUrl;
    }
    
    // Getting the Document Id and creating a Document Url.
    public String getAddressLogoUrl(){
        list<Document> lstDocument = [SELECT Id FROM Document WHERE DeveloperName = 'Insperity_HR_Logo'];
        String strOrgId = UserInfo.getOrganizationId();
        String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + 
                            '/servlet/servlet.ImageServer?id='+lstDocument[0].Id +
                            '&oid=' + strOrgId;
        return strLogoUrl;
    }
    
    // This is our wrapper/container class. A container class is a class, a data structure, or an abstract data type whose instances are collections of other objects. In this example a wrapper class contains both the standard salesforce object Account and a Boolean value
    public class wrapTermination {
        public String clinetName {get; set;}
        public String clinetNumber {get; set;}
        public Decimal eeNumber {get; set;}
        public String psName {get; set;}
        public String clName {get; set;}
        public Date csaTerm {get; set;}
        public Date beneterm {get; set;}
        public String reason {get; set;}
        
        //This is the contructor method. When we create a new wrapAccount object we pass a Account that is set to the acc property. We also set the selected value to false
        public wrapTermination(NSP_Termination_Form__c termination, String PS, String CL) {
            clinetName = termination.NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name;
            clinetNumber = termination.NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c;
            eeNumber = termination.NSP_Number_of_Active_Employees__c;
            psName = PS;
            clName = CL;
            csaTerm = termination.NSP_Client_Term_Date__c;
            beneterm = termination.NSP_Benefit_Termination_Date__c;
            reason = termination.NSP_Term_Code__c;
        }
    }
}