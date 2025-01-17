public with sharing class CreateSeparateProjectOrderItem {
    // test w/ CreateSeparateProjectOrderItemTest (81%)

    @InvocableMethod(label='Create Separate Project' description='Create Separate Project for Order')
    public static void createSeparateProject(List<String> records) {
        Map<String,String> projectResponseMap = new Map<String,String>();
        List<OrderItem> oiUpdateList = new List<OrderItem>();
        
        Map<String,String> projectIdMap = new Map<String,String>();
        List<OrderItem> orderItemList = [
            SELECT
                Id , NSP_Project_Name_New_Sales__c , NSP_Project__c , SBQQ__RequiredBy__c ,
                SBQQ__RequiredBy__r.Product2.ProductCode , Product2.ProductCode , Order.AccountId ,
                NSP_Project_Name_Amendment__c , NSP_QL_ActionType__c , NSP_Transaction_for_Project__c ,
                NSP_ApplicableProductAmendNew__c , NSP_ApplicableProduct_AmendDowngrade__c ,
                NSP_ApplicableProduct_AmendUpsell__c , Order.NSP_Project_Name__c ,
                Order.Type , Order.NSP_Transaction_Type__c
            FROM OrderItem
            WHERE (
                ( OrderId IN :records )
                AND ( Separate_Project__c = true )
            )
        ];
        List<NSP_ProjectTemplateMapping__mdt> keyWithTemplateId = NSP_ProjectTemplateMapping__mdt.getAll().values();
        for(NSP_ProjectTemplateMapping__mdt projectMdt: keyWithTemplateId){
            projectIdMap.put(projectMdt.Key__c+projectMdt.Template_Name__c,projectMdt.Template_ID__c);
        }
        for ( OrderItem orderProdObj : orderItemList ) {
            String projName = createSeparateProjectNameAmend(orderProdObj);
            if ( projectIdMap.containsKey( orderProdObj.Product2.ProductCode+projName )
                && ( projName != null )
                && ( orderProdObj.NSP_Project__c == null )
                )
            {
                pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest =
                    new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(orderProdObj.Order.AccountId,projectIdMap.get(orderProdObj.Product2.ProductCode+projName), System.today());
                
                //Set OrderProd Id as Project Name in the request which helps while constructing the Map out of Create Project Response
                projRequest.ProjectName = orderProdObj.Id;
                //copy recordTypeId & Owner
                pse.SObjectCloneMapper.Field mapperFieldRT = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.RecordTypeId);
                pse.SObjectCloneMapper.Field mapperFieldOwner = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.OwnerId);
                Set<pse.SObjectCloneMapper.Field> setMapperFields = new Set<pse.SObjectCloneMapper.Field>{mapperFieldRT,mapperFieldOwner};
                pse.SObjectCloneMapper mapp = new pse.SObjectCloneMapper(pse__Proj__c.SObjectType, setMapperFields);
                projRequest.Mappers = new List<pse.SObjectCloneMapper> { mapp };

                //Call the service and create project
                List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
                    new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{ projRequest }
                );
                Id newProjectId = CreateProjectFromTemplateAction.handleCreateProjectResponse(
                    CreateSeparateProjectOrderItem.class.getName() ,
                    'createSeparateProject' ,
                    projResponse
                );
                if ( newProjectId != null ) {
                    projectResponseMap.put( projResponse[0].Request.ProjectName , newProjectId );
                }
                orderProdObj.NSP_Project__c = projectResponseMap.get(orderProdObj.Id);
                oiUpdateList.add(orderProdObj);
            }
        }
        if(oiUpdateList != null && oiUpdateList.size() > 0){
            List<Database.SaveResult> results = Database.update(oiUpdateList,false);
            NSP_ErrorLogHandler.logResults(
                CreateSeparateProjectOrderItem.class.getName() ,
                'createSeparateProject' ,
                results
            );
        }
    }

    private static string createSeparateProjectNameAmend(orderitem orderLine ) {
        String transactionType=null;
        Boolean isAmendment=false;
        if ( ( orderLine != null )
            && ( orderLine.Order != null )
            && ( orderLine.Order.Type == NSP_CPQConstants.ORDER_TYPE_AMENDMENT )
            && ( orderLine.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
            && String.isNotBlank( orderLine.NSP_QL_ActionType__c )
            )
        {
            String action = orderLine.NSP_QL_ActionType__c.replace('Amend/','');
            String requiredByProductCode = null;
            if ( ( orderLine.SBQQ__RequiredBy__c != null )
                && ( orderLine.SBQQ__RequiredBy__r.Product2 != null )
                && String.isNotBlank( orderLine.SBQQ__RequiredBy__r.Product2.ProductCode )
                )
            {
                requiredByProductCode = orderLine.SBQQ__RequiredBy__r.Product2.ProductCode;
            }
            if(action == NSP_CPQConstants.ACTION_NEW && String.isNotBlank(orderLine.NSP_ApplicableProductAmendNew__c)){
                if(orderLine.NSP_ApplicableProductAmendNew__c.replace(';',' ').contains(requiredByProductCode)){
                    isAmendment = true;
                }
            } else if(action == NSP_CPQConstants.ACTION_DOWNGRADE && String.isNotBlank( orderLine.NSP_ApplicableProduct_AmendDowngrade__c )){
                if(orderLine.NSP_ApplicableProduct_AmendDowngrade__c.replace(';',' ').contains(requiredByProductCode)){
                    isAmendment = true;
                } 
            } else if(action == NSP_CPQConstants.ACTION_UPSELL && String.isNotBlank( orderLine.NSP_ApplicableProduct_AmendUpsell__c )){
                if(orderLine.NSP_ApplicableProduct_AmendUpsell__c.replace(';',' ').contains(requiredByProductCode)){
                    isAmendment = true;
                } 
            } else if( String.isBlank( orderLine.NSP_ApplicableProduct_AmendUpsell__c )
                && String.isBlank( orderLine.NSP_ApplicableProduct_AmendDowngrade__c )
                && String.isBlank( orderLine.NSP_ApplicableProductAmendNew__c )
                )
            {
                if(String.isNotBlank( orderLine.NSP_Transaction_for_Project__c )){
                    transactionType = orderLine.NSP_Transaction_for_Project__c.replace(';',' ');
                }
                if(String.isNotBlank( orderLine.NSP_QL_ActionType__c )) {
                    action = orderLine.NSP_QL_ActionType__c.replace('Amend/','');
                    if(transactionType!=null && transactionType.contains(action)){
                        isAmendment = true;
                    }
                }
            }
        }
        String strProjName = orderLine.NSP_Project_Name_New_Sales__c;
        if(isAmendment == true){
            strProjName = orderLine.NSP_Project_Name_Amendment__c;
        }
        return  strProjName;
    }

}
//