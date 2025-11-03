public class NSP_IP_Automation_Helper {
    // test w/ NSP_IP_Automation_Helper_Test (87%)
    
    private Map<String,Case> caseToInsertSubjectIpList = new Map<String,Case>();
    private static Id ipFSORecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
    private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    
    @TestVisible private List<String> existingCases=new List<String>();
    @TestVisible private List<String> existingIpAutomations=new List<String>();
    
    
    public  NSP_Implementation_Profile_Automation__c createIPAutomation(Implementation_Profile__c ipRec, String automationName, String fnName, String section){
      NSP_Implementation_Profile_Automation__c ipAautomation = new NSP_Implementation_Profile_Automation__c();
      ipAautomation.Name = automationName;
      ipAautomation.NSP_Method_Name__c = fnName;
      ipAautomation.NSP_Section__c = section;
      ipAautomation.NSP_Implementation_Profile__c = ipRec.Id;
      ipAautomation.NSP_Class_Name__c=NSP_ServiceConstants.IP_CASE_AUTOMATIONCLASS;
      ipAautomation.NSP_Last_Run__c = System.now();
      if(ipRec.RecordTypeId==ipFSORecordTypeId){
          ipAautomation.NSP_Record_Type__c=NSP_ServiceConstants.FSOProfile;
      }
      if(ipRec.RecordTypeId==ipMMRecordTypeId){
          ipAautomation.NSP_Record_Type__c=NSP_ServiceConstants.MIDDLEMARKET;
      }
       
      return ipAautomation;
   }
   
   public  void getAllIPAutomation(Set<Id> ipIds){
      
      for (NSP_Implementation_Profile_Automation__c ipAutomation: [SELECT Id,NSP_Implementation_Profile__c,NSP_Record_Type__c, Name FROM NSP_Implementation_Profile_Automation__c 
               WHERE NSP_Implementation_Profile__c in:ipIds]){
                existingIpAutomations.add(ipAutomation.NSP_Implementation_Profile__c+'_'+ipAutomation.Name+'_'+ipAutomation.NSP_Record_Type__c);
      }
   }
    
   public List<NSP_Implementation_Profile_Automation__c> getnewAutomationListtoInsert(List<NSP_Implementation_Profile_Automation__c> ipAutomationList){
      
      List<NSP_Implementation_Profile_Automation__c> newipAutomationList=new List<NSP_Implementation_Profile_Automation__c>();

      for(NSP_Implementation_Profile_Automation__c ipa: ipAutomationList){
        if(existingIpAutomations.isEmpty()|| 
           !existingIpAutomations.contains(ipa.NSP_Implementation_Profile__c+'_'+ipa.Name+'_'+ipa.NSP_Record_Type__c)) {
            newipAutomationList.add(ipa);
           }
         
      }
      return newipAutomationList;
   }

   public void getAllCases( Set<Id> ipIds ) {
      for ( Case eachCase : [
               SELECT
                  Id ,
                  Subject ,
                  NSP_SubCategory__c ,
                  NSP_Category__c ,
                  NSP_Implementation_Profile__c
               FROM Case
               WHERE ( NSP_Implementation_Profile__c IN :ipIds )
            ]
         )
      {
         this.caseToInsertSubjectIpList.put(eachCase.Subject,eachCase);
         existingCases.add(eachCase.NSP_Implementation_Profile__c+'_'+eachCase.Subject+'_'+eachCase.NSP_Category__c+'_'+eachCase.NSP_SubCategory__c);
      }
   }

   public List<Case> getnewCasestoInsert(List<Case> caseList){
      
      List<Case> newCaseList=new List<Case>();

      for(Case cc: caseList){
          
         if(existingCases.isEmpty() || !existingCases.contains(cc.NSP_Implementation_Profile__c+'_'+cc.Subject+'_'+
         cc.NSP_Category__c+'_'+cc.NSP_SubCategory__c)){
              
            newCaseList.add(cc);
           
         }
         
      }

      return newCaseList;
   }
    
   public List<Case> getNewCasesToInsertSubjectIp( List<Case> caseList ) {
      List<Case> newCaseList = new List<Case>();
      if ( ( caseList != null ) && !caseList.isEmpty() ) {
         for ( Case cc : caseList ) {
            if ( this.caseToInsertSubjectIpList.isEmpty()
               || ( String.isNotBlank( cc.Subject )
                  && ( !this.caseToInsertSubjectIpList.containsKey( cc.Subject )
                     || ( ( this.caseToInsertSubjectIpList.get( cc.Subject ) != null )
                        && ( this.caseToInsertSubjectIpList.get( cc.Subject ).NSP_Implementation_Profile__c != cc.NSP_Implementation_Profile__c )
                        )
                     )
                  )
               )
            {
               newCaseList.add( cc );
            }
         }
      }
      return newCaseList;
   }

}
//