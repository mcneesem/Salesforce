public with sharing class NSP_ReportRequestWizardController {
    // test w/ NSP_ReportRequestWizardControllerTest (??%)

    public static final Id WO_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
    private static final String NOT_FOUND = 'Not Found';
    @AuraEnabled
    public static List<NSP_ReportRequest__c> getReportRequestList(String recordTypeIds ) {
        try {
         String userId = UserInfo.getUserId();
        return [SELECT Id,Name, NSP_ClientName__c, NSP_ClientName__r.Name,NSP_ReportPlace__c,NSP_columsToBeTotaled__c,NSP_ListAdditionalClients_subAccounts__c,NSP_ReportName__c,
        RecordTypeId,NSP_HowIsReportUsed__c,NSP_InternalClientReport__c,NSP_Existing_NewReport__c,NSP_NeedcolumnHeading__c,NSP_HowToSort__c,
        NSP_ReportType__c,RecordType.DeveloperName,CreatedDate,NSP_LastSavedPageNumber__c  FROM NSP_ReportRequest__c WHERE RecordTypeId = : recordTypeIds AND NSP_IsDraft__c = true  AND OwnerId =:userId WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 100 ];
         } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled
    public static list<contentversion> releatedFiles(String idParent){
        list<id> lstConDocs = new list<id>();
    try {
        for(ContentDocumentLink cntLink : [Select Id, ContentDocumentId From ContentDocumentLink WHERE LinkedEntityId =:idParent]) {
            lstConDocs.add(cntLink.ContentDocumentId);
        }
        if(!lstConDocs.isEmpty()) {
            return [SELECT Id, Title, ContentDocumentId ,PathOnClient,CreatedDate,FileExtension FROM ContentVersion WHERE ContentDocumentId IN :lstConDocs WITH SECURITY_ENFORCED LIMIT 100 ];
        }
        else {
            return new List<contentversion>();
        }
      } catch (Exception excep) {
        throw new AuraHandledException(excep.getMessage());
    }
    }

    @AuraEnabled(cacheable=true)
    public static String getInternalAccountId(){
        
        try {
            if( String.isNotBlank(System.Label.NSP_Insperity_Account)){
                Id insperityAccountId = test.isRunningTest() ? null : System.Label.NSP_Insperity_Account;
                return insperityAccountId;
            }
              return null;
          } catch (Exception excep) {
              throw new AuraHandledException(excep.getMessage());
          }
    }

    @AuraEnabled(cacheable=true)
    public static string getQueueByName(String queueLabel){
        try {
          String developmentQueue= [ SELECT ID,DeveloperName, Name FROM Group WHERE Name = : queueLabel  LIMIT 1 ].ID;
            return developmentQueue;
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    /**
	* @MethodName: getHRspecialistAndFinanceLevel
	* @Description: This method fetch HR specialist from Account team and Finance level, segment, service region from WO asset
	* @param : String accountID
	* @modifiedDate : 12/09/2022
	* @return Map<String,String>                          
	*/

    @AuraEnabled
    public static Map<String,String> getHRspecialistAndFinanceLevel(String accountID){
        
        try {
            
            Map<String,String> jSONmap =new Map<String,String>();
            String userId,financeLevel,segment,region;
            List <String> accountTeamFields = new List <String> {'Id', 'NSP_Primary__c', 'NSP_User__r.Name',
                												'NSP_User__c', 'NSP_Role__c','NSP_Account__c'};
            List <String> assetFields       = new List <String> {'Id', 'AccountId','NSP_Service_Region__c', 'NSP_Account_Status__c',
                												'toLabel(NSP_Financial_Guidelines__c)','NSP_Client_Segment_type__c'};
            //fetch Primary HR specialist from Account team associated with the accountid
            List<NSP_Account_Team__c> accountTeam = [SELECT Id,NSP_Primary__c,NSP_User__r.Name,NSP_User__c,NSP_Role__c,NSP_Account__c
                                                    FROM NSP_Account_Team__c WHERE NSP_Account__c=:accountID 
                                                    AND ( NSP_Role__c =: NSP_ServiceConstants.HRSpecialist OR NSP_Role__c =: NSP_ServiceConstants.BUS_TEAM_HRSP_CL)
                                                    AND NSP_User__c !=null   ];
            
            //Map HR specialist of wizard output to Account team HR Specialist
            if(accountTeam.size()>0){
                for(NSP_Account_Team__c accTeam : accountTeam){
                    if(accTeam.NSP_Primary__c==TRUE){
                        userId= accTeam.NSP_User__c;
                        break;
                    }
                    else{
                        userId= accTeam.NSP_User__c; 
                    }
                }
            }
            jSONmap.put('UserId', (userId != null?userId:NOT_FOUND) );
			// fetch credit level, service region and client segment type from wo asset associated with client name selected
			String assetQuery = new NSP_QueryBuilder(
                				'Asset',
                 				 assetFields)
                                 .addFilter('RecordTypeId', WO_ASSET)
                                 .addFilter('AccountId', accountID)
                                 .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.ASSET_ACTIVE_STATUS)
                                 .setSecurityEnforce(false)
                                 .build();
            assetQuery += ' AND (NSP_Financial_Guidelines__c!=NULL OR NSP_Client_Segment_type__c!=null OR NSP_Service_Region__c!=null) ' ;
            assetQuery += 'ORDER BY LastModifiedDate ASC LIMIT 1';
            Asset[] asset = Database.query(assetQuery);

            if(asset.size()>0){
                financeLevel= asset[0].NSP_Financial_Guidelines__c;
                segment=asset[0].NSP_Client_Segment_type__c;
                region = asset[0].NSP_Service_Region__c;
            } 
            //map finance level, region and segment of wizard output to credit level and segment type of wo asset respecitvely
            jSONmap.put('FinanceLevel', ( financeLevel!= null? financeLevel:NOT_FOUND) );
            jSONmap.put('segment', ( segment!= null? segment: NOT_FOUND) );
            jSONmap.put('region', ( region!= null? region: NOT_FOUND) );


            return jSONmap;
        } catch (Exception excep) {
              throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountContactRelation> retrieveContactRecords (String accountId ) {
        try {
        //Contact[] contacts  =  [SELECT Name, Email from Contact WHERE AccountId =:accountId];
        //fetch related contacts instead of direct contacts
        AccountContactRelation [] acrs = [SELECT ContactId, Contact.name, Contact.NSP_Work_email__c, NSP_Work_Email__c  from AccountContactRelation WHERE AccountId =:accountId];
        if(!acrs.isEmpty()){
            return acrs;
        }else {
            return new List<AccountContactRelation> () ;
        }
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    /**
	* @MethodName: getWSEEDetails
	* @Description: This method fetch DOB, WORK STATE, EMP STATE FROM WSEE SELECTED
	* @param : String contactID, String accountID
	* @modifiedDate : 12/09/2022
	* @return List<wizardOutputWrapper>                         
	*/

    
    @AuraEnabled
    public static List<wizardOutputWrapper> getWSEEDetails (String contactID, String accountId){
       
        try {
             List<String> sccAddressFields = new List <String> {'NSP_State__c', 'NSP_Sub_Client_Contact__c'};
             List<String> contactFields    = new List <String> {'Id', 'NSP_Date_of_Birth__c' , 'Name'};
             List<String> sccFields        = new List <String> {'Id','NSP_Is_Primary__c','NSP_Employee_Status__c',
                                                              'NSP_Status_Date__c','NSP_AIMS_Sub_Client__c', 
                                                              'NSP_Sub_Client__c', 'NSP_Sub_Client__r.NSP_Account__c'};
                                                                  
             List<wizardOutputWrapper> wizardOutputWrapperList = new List<wizardOutputWrapper>();
             wizardOutputWrapper wizOtWrapper = new wizardOutputWrapper();
            
            
            if(String.isNotBlank(contactID)){
                //fetch mailing state and date of birth from contactId (WSEE selected)
                
                String conQuery = new NSP_QueryBuilder(
                			      'Contact',
                				  contactFields)
                                  .addFilter('Id', String.escapeSingleQuotes(contactID))
                                  .setSecurityEnforce(false)
                                  .addLimit(1)
                                  .build();
                Contact[] conList = Database.query(conQuery);
                
                if(conList.size()>0 && conList[0].NSP_Date_of_Birth__c!=null){
					//Map the  date of birth of wizard output from WSEE details
                    wizOtWrapper.contactName =  conList[0].Name;
                    wizOtWrapper.dateOfBirth = conList[0].NSP_Date_of_Birth__c != null  ?conList[0].NSP_Date_of_Birth__c : null ;
                }
                
                if(String.isNotBlank(accountId)){
                    //fetch the sub client associated with account passed and fetch related primary sub client contact where WSEE is selected
                     String sccQuery =  new NSP_QueryBuilder(
                	 				    'NSP_Sub_Client_Contact__c',
                	 				    sccFields)
                     					.addFilter('NSP_Contact__c', String.escapeSingleQuotes(contactID))
                	 					.addFilter('NSP_Is_Primary__c', TRUE)
                     					.addFilter('NSP_Sub_Client__r.NSP_Account__c', String.escapeSingleQuotes(accountId))
                                        .setSecurityEnforce(false)
                     					.build();
                     sccQuery += ' AND NSP_Sub_Client__c!=null lIMIT 1 ' ;
                    
                    List<NSP_Sub_Client_Contact__c> accSubClientContList = Database.query(sccQuery);
                    if(accSubClientContList.size()>0){
                        
                        	//Map the employee status, trmination date, sub client number of wizard output from WSEE associated subclient contact
                            NSP_Sub_Client_Contact__c subClientContact = accSubClientContList[0];
                            wizOtWrapper.empStatus		 =  String.isNotBlank(subClientContact.NSP_Employee_Status__c) ? 
                                                     		subClientContact.NSP_Employee_Status__c : null;
                            wizOtWrapper.terminationDate =  subClientContact.NSP_Employee_Status__c == NSP_ServiceConstants.TERMINATED_STATUS ? 
                                                            subClientContact.NSP_Status_Date__c : null;
                            wizOtWrapper.subClientNum 	 =  subClientContact.NSP_AIMS_Sub_Client__c !=null ?
                                                        	subClientContact.NSP_AIMS_Sub_Client__c : null;
                            
                            String scaQuery = new NSP_QueryBuilder(
                                                                'NSP_Sub_Client_Contact_Address__c',
                                                                 sccAddressFields)
                                                                .addFilter('NSP_Sub_Client_Contact__r.NSP_Contact__c', String.escapeSingleQuotes(contactID))
                                                                .addFilter('NSP_Sub_Client_Contact__r.NSP_Is_Primary__c', TRUE)
                                                                .addFilter('NSP_Sub_Client_Contact__c',accSubClientContList[0].Id )
                                                                .setSecurityEnforce(false)
                                                                .build();
                            scaQuery += ' AND NSP_State__c!=null lIMIT 1 ' ;
                            NSP_Sub_Client_Contact_Address__c[] sccList =  Database.query(scaQuery);
                                              
                            if(sccList.size()>0 && String.isNotBlank(sccList[0].NSP_State__c)){
                                                              //Map the  work state of wizard output from WSEE details
                                                              wizOtWrapper.mailingState= sccList[0].NSP_State__c;
                            }                                

                    }else{
                            //if no values present for sub client contact pass null values for the below fields
                            wizOtWrapper.empStatus = null;
                            wizOtWrapper.terminationDate = null;
                            wizOtWrapper.subClientNum = null;   
                    }    
                }else{
                        wizOtWrapper.empStatus = null;
                        wizOtWrapper.terminationDate = null;
                        wizOtWrapper.subClientNum = null;
                }
                wizardOutputWrapperList.add(wizOtWrapper);
                
            }
        	return wizardOutputWrapperList;
        }catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    /**
	* @MethodName: getActiveEmployeeCount
	* @Description: This method fetch unique active employee count from WO asset 
	* @param :  String accountID
	* @createdDate : 12/14/2022
	* @return Boolean true if the employee count is greater than 45                       
	*/
    @AuraEnabled
    public static Boolean getActiveEmployeeCount ( String accountId){
        try{
            List<String> assetFields = new List<String> {'Id', 'AccountId',
                                    					'NSP_Unique_Active_Employee__c'};
            //return true if asset associated to account has unique active employees greater than or equal to 45
            String assetQuery = new NSP_QueryBuilder(
                	 			'Asset',
                	 			assetFields)
                     			.addFilter('AccountId', String.escapeSingleQuotes(accountID))
                	 			.addFilter('RecordTypeId', WO_ASSET)
                                .setSecurityEnforce(false)
                     			.build();
            assetQuery += ' AND NSP_Unique_Active_Employee__c!=NULL AND NSP_Unique_Active_Employee__c >=  10 ORDER BY LastModifiedDate ASC LIMIT 1' ;
            List<Asset> assetList = Database.query(assetQuery);
    
            if(assetList.size()>0){
                return true;
            }
            return false;
        }catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }
    
    public class wizardOutputWrapper{
        @AuraEnabled
        public String mailingState{get;set;}
        @AuraEnabled
        public Date dateOfBirth{get;set;}
        @AuraEnabled
        public String empStatus{get;set;}
        @AuraEnabled
        public Date terminationDate{get;set;}
        @AuraEnabled
        public String subClientNum{get;set;}
        @AuraEnabled
        public String contactName{get;set;}
    }


    @AuraEnabled
    public static String getHRspecialist(String accountID){
    try {
        String userId;
        NSP_Account_Team__c[] accountTeam =[SELECT Id, NSP_User__r.Name, NSP_User__c, NSP_Role__c,NSP_Account__c FROM NSP_Account_Team__c 
        WHERE NSP_Role__c ='HR Specialist' AND NSP_Account__c =:accountID AND NSP_User__c !=null  ORDER BY LastModifiedDate ASC LIMIT 1];
        if(accountTeam.size()>0){
            userId= accountTeam[0].NSP_User__c;
        }
    return userId;
      } catch (Exception excep) {
          throw new AuraHandledException(excep.getMessage());
      }
    }

    @AuraEnabled
    public static String getAIMSfromPEOasset(String accountID){
    try {
        String aimsNumb;
        Asset[] assetList =[SELECT NSP_Client__c, RecordType.DeveloperName, CreatedDate FROM Asset 
            WHERE NSP_Client__c != null AND RecordType.DeveloperName ='WO' AND AccountId =: accountID ORDER BY CreatedDate DESC  LIMIT 1];

            if(assetList.size()>0){
                aimsNumb= assetList[0].NSP_Client__c;
            }
        return aimsNumb;
          } catch (Exception excep) {
              throw new AuraHandledException(excep.getMessage());
          }

    }

    /**
	* @MethodName: getAccountWoAsset
	* @Description: This method fetch wo-asset associated to account 
	* @param :  String accountID
	* @createdDate : 03/23/2023
	* @return string assetId of wo-asset recordType assosiated with given accountId                      
	*/
    
    @AuraEnabled
    public static String getAccountWoAsset(String accountId){
    try {
         String woAsset = '';
           List<String> assetFields = new List<String> {'Id', 'AccountId', 'RecordTypeId'};
            //return true if recordtype of asset is wo-asset associated to account 
            String assetQuery = new NSP_QueryBuilder(
                	 			'Asset',
                	 			assetFields)
                     			.addFilter('AccountId', String.escapeSingleQuotes(accountId))
                	 			.addFilter('RecordTypeId', WO_ASSET)
                                .addLimit(1)
                                .setSecurityEnforce(false)
                     			.build();
            List<Asset> assetList = Database.query(assetQuery);
            if(assetList.size()>0){
                woAsset= assetList[0].Id;
            }
        return woAsset;
          } catch (Exception exc) {
              throw new AuraHandledException(exc.getMessage());
          }

    }
}