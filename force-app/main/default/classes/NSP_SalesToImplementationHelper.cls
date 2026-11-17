// intentionally `without sharing` to preserve default sharing at api version 55...
public without sharing class NSP_SalesToImplementationHelper {
    // test w/ NSP_SalesToImplementationHelperTest (97%)

    public void afterInsert( List<NSP_Sales_to_Implementation__c> newList ) {
        Set < Id > setOfS2IIds = new Set < Id > ();
        Set < Id > planSubplanIDs = new Set < Id > ();
        Map < Id, NSP_Sales_to_Implementation__c > mapS2I= new Map < Id, NSP_Sales_to_Implementation__c > ();
        // Check if status date is populated
        for(NSP_Sales_to_Implementation__c S2I: newList) {
            if(S2I.NSP_Status_Date__c != null) {
                setOfS2IIds.add(S2I.Id);
                mapS2I.put(S2I.Id, S2I);
                if(S2I.NSP_Subplan_Plan_Details_Record__c!=null){
                    planSubplanIDs.add(S2I.NSP_Subplan_Plan_Details_Record__c);
                }
            }
        }
        if(!setOfS2IIds.isEmpty() ){
            createRETEd(setOfS2IIds,mapS2I,planSubplanIDs);
        }
    }

    public void afterUpdate( Map<Id,NSP_Sales_to_Implementation__c> newMap , Map<Id,NSP_Sales_to_Implementation__c> oldMap ) {
        Set < Id > setOfS2IIds = new Set < Id > ();
        Set < Id > planSubplanIDs = new Set < Id > ();
        Map < Id, NSP_Sales_to_Implementation__c > mapS2I= new Map < Id, NSP_Sales_to_Implementation__c > ();
        // Check if status date is populated for the first time
        for(NSP_Sales_to_Implementation__c S2I: newMap.values()){
            //check if Status date is filled for the first time
            if(S2I.NSP_Status_Date__c != null && oldMap.get(S2I.Id).NSP_Status_Date__c == null){
                setOfS2IIds.add(S2I.Id);
                mapS2I.put(S2I.Id, S2I);
                if(S2I.NSP_Subplan_Plan_Details_Record__c!=null){
                planSubplanIDs.add(S2I.NSP_Subplan_Plan_Details_Record__c);
                }
            }
        }
        if(!setOfS2IIds.isEmpty() ){
            createRETEd(setOfS2IIds,mapS2I,planSubplanIDs);
        }
    }

    //
    // MethodName: createRETEd
    // Description : Iterates through the map of updated S2I
    //
    public void createRETEd( Set<Id> setOfS2IIds , Map<Id,NSP_Sales_to_Implementation__c> mapS2I , Set<Id> planSubplanIDs ) {
        // query for any existing RET education records associated to S2I
        Map<Id,Id> mapS2IToRETEducation = new Map<Id,Id>();
        for ( NSP_RET_Education__c mappingRET : [
                    SELECT Id , Sales_to_Implementation__c
                    FROM NSP_RET_Education__c
                    WHERE ( Sales_to_Implementation__c IN :setOfS2IIds )
                ]
            )
        {
            mapS2IToRETEducation.put(
                mappingRET.Sales_to_Implementation__c ,
                mappingRET.Id
            );
        }
        //query plan subplan to get subplan ID
        Map<Id,String> plansubplanMap = new Map<Id,String>();
        for ( NSP_Plan_SubPlan__c mappingPlanSubplan : [
                    SELECT Id , NSP_Subplan_ID__c
                    FROM NSP_Plan_SubPlan__c
                    WHERE ( Id in : planSubplanIDs )
                ]
            )
        {
            plansubplanMap.put(
                mappingPlanSubplan.Id ,
                mappingPlanSubplan.NSP_Subplan_ID__c
            );
        }
        // create new RET education record and associate it to S2I
        List<NSP_RET_Education__c> listRETEdToInsert = NSP_SalesToImplementationHelper.populateInsertList(
            mapS2I.values() ,
            mapS2IToRETEducation
        );
        //insert RET education records
        List<Id> insertedIds = new List<Id>();
        if ( !listRETEdToInsert.isEmpty() ) {
            List<Database.SaveResult> srList = Database.insert( listRETEdToInsert , false );
            for ( Database.SaveResult sr : srList ) {
                insertedIds.add( sr.getId() );
            }
        }
        // send email to Education team for each RET education record created
        List<Messaging.SingleEmailMessage> lstEmailMessages = NSP_SalesToImplementationHelper.buildEmailMessages( insertedIds );
        if ( ( lstEmailMessages != null ) && !lstEmailMessages.isEmpty() ) {
            try {
                Messaging.sendEmail( lstEmailMessages );
            } catch ( Exception e ) {
                System.debug( ' ~ CATCH ~ e=' + e );
            }
        }
    }

    private static List<Messaging.SingleEmailMessage> buildEmailMessages( List<Id> whatIds ) {
        // send email to Education team for each RET education record created
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        if ( EmailDeliverabilityController.isEnabledOutbound
            && ( whatIds != null )
            && !whatIds.isEmpty()
            )
        {
            // Gets education Team email address for Recipient email
            NSP_Retirement_Services__mdt retirementServicemdt = NSP_Retirement_Services__mdt.getInstance( 'NSP_RET_Education_Team_Email_Address' );
            EmailTemplate template = NSP_SalesToImplementationHelper.getEmailTemplate();
            if ( ( retirementServicemdt != null ) && ( template != null ) ) {
                List<String> toAddresses = new List<String>();
                toAddresses.add( retirementServicemdt.NSP_Email_Address__c );
                for ( Id whatId : whatIds ) {
                    Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(
                        template.Id ,
                        null ,
                        whatId
                    );
                    message.setTemplateId( template.Id );
                    message.setToAddresses( toAddresses );
                    message.setWhatId( whatId );
                    messages.add( message );
                }
            }
        }
        return messages;
    }

    private static EmailTemplate getEmailTemplate() {
        List<EmailTemplate> templates = [
            SELECT
                Id ,
                BrandTemplateId ,
                Subject ,
                HTMLValue ,
                Body ,
                DeveloperName
            FROM EmailTemplate
            WHERE ( DeveloperName = 'NSP_RET_Education_Creation_Email' )
            LIMIT 1
        ];
        EmailTemplate template = null;
        if ( !templates.isEmpty() ) {
            template = templates[0];
        }
        return template;
    }

    // helper method to defeat sonar cognitive complexity...
    private static List<NSP_RET_Education__c> populateInsertList(
        List<NSP_Sales_to_Implementation__c> records ,
        Map<Id,Id> mapS2IToRETEducation
        )
    {
        List<NSP_RET_Education__c> response = new List<NSP_RET_Education__c>();
        if ( ( records != null )
            && !records.isEmpty()
            && ( mapS2IToRETEducation != null )
            )
        {
            for ( NSP_Sales_to_Implementation__c record : records ) {
                if ( !mapS2IToRETEducation.containsKey( record.Id ) ) {
                    NSP_RET_Education__c newRecord = new NSP_RET_Education__c();
                    newRecord.Name = 'RET Education Record';
                    newRecord.Sales_to_Implementation__c = record.Id;
                    response.add( newRecord );
                }
            }
        }
        return response;
    }

}
//