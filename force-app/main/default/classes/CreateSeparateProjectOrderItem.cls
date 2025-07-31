public with sharing class CreateSeparateProjectOrderItem {
    // test w/ CreateSeparateProjectOrderItemTest (82%)

    @InvocableMethod(label='Create Separate Project' description='Create Separate Project for Order')
    public static void createSeparateProject( List<String> records ) {
        List<OrderItem> opWithMatchingProducts = new List<OrderItem>();
        List<OrderItem> oiUpdateList = new List<OrderItem>();
        List<OrderItem> orderItemList = [
            SELECT
                Id , NSP_Project_Name_New_Sales__c , NSP_Project__c , SBQQ__RequiredBy__c ,
                SBQQ__RequiredBy__r.Product2.ProductCode , Product2.ProductCode , Order.AccountId ,
                NSP_Project_Name_Amendment__c , NSP_QL_ActionType__c , NSP_Transaction_for_Project__c ,
                NSP_ApplicableProductAmendNew__c , NSP_ApplicableProduct_AmendDowngrade__c ,
                NSP_ApplicableProduct_AmendUpsell__c , Order.NSP_Project_Name__c ,
                Order.Type , Order.NSP_Transaction_Type__c, Matching_Product_Code__c, OrderId, Order.NSP_Project__c, SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c
            FROM OrderItem
            WHERE (
                ( OrderId IN :records )
                AND ( Separate_Project__c = true ) 
                AND ( Quantity > 0 )
            )
            ORDER BY OrderId,Separate_Project_Sort__c
        ];
        //sorted OPs ensure priority wise evaluation
        for ( OrderItem orderProdObj : orderItemList ) {
            if ( ( orderProdObj.Matching_Product_Code__c == null )
                || String.isBlank( orderProdObj.Matching_Product_Code__c )
                )
            {
                if(
                    (
                        ( orderProdObj.Order.Type == 'Amendment' ) 
                        && (
                            ( orderProdObj.NSP_QL_ActionType__c == '' ) 
                            || ( orderProdObj.NSP_QL_ActionType__c == null )
                           )
                    ) 
                    || ( orderProdObj.NSP_Project__c != null )
                ){
                    //skip separate project creation if (for an amendment, action type is blank or null) OR (if project is populated on OP)
                    continue;
                }
                //separate project creation logic
                projectCreationService( oiUpdateList , orderProdObj );
            } else {
                //matching product logic
                opWithMatchingProducts.add( orderProdObj );
            }
        }
        if ( ( oiUpdateList != null )
            && !oiUpdateList.isEmpty()
            )
        {
            List<Database.SaveResult> results = Database.update( oiUpdateList , false );
            NSP_ErrorLogHandler.logResults(
                CreateSeparateProjectOrderItem.class.getName() ,
                'createSeparateProject' ,
                results
            );
        }
        if ( ( opWithMatchingProducts != null )
            && !opWithMatchingProducts.isEmpty()
            )
        {
            processMatchingOPs( opWithMatchingProducts );
        }
    }

    //method that creates separate project
    private static void projectCreationService( List<OrderItem> oiUpdateList , OrderItem orderProdObj ) {
        Map<String,String> projectIdMap = getProjectMapping();
        Map<String,String> projectResponseMap = new Map<String,String>();
        String projName = createSeparateProjectNameAmend( orderProdObj );
        if ( projectIdMap.containsKey( orderProdObj.Product2.ProductCode + projName )
            && ( projName != null )
            && ( orderProdObj.NSP_Project__c == null )
            )
        {
            pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(
                orderProdObj.Order.AccountId ,
                projectIdMap.get( orderProdObj.Product2.ProductCode + projName ) ,
                System.today()
            );
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
            orderProdObj.NSP_Project__c = projectResponseMap.get( orderProdObj.Id );
            oiUpdateList.add( orderProdObj );
        } else {
            //call logic for fetching project from order
            getProjectFromOrder(
                orderProdObj ,
                new Map<String, OrderItem>{
                    orderProdObj.Product2.ProductCode + '_' + orderProdObj.OrderId => orderProdObj
                }
            );
            oiUpdateList.add( orderProdObj );
        }
    }

    //method to fetch name of project
    private static string createSeparateProjectNameAmend( Orderitem orderLine ) {
        Boolean isAmendment = false;
        String strProjName = orderLine.NSP_Project_Name_New_Sales__c;
        if ( ( orderLine != null )
            && ( orderLine.Order != null )
            && ( orderLine.Order.Type == NSP_CPQConstants.ORDER_TYPE_AMENDMENT )
            && String.isNotBlank( orderLine.NSP_QL_ActionType__c )
            )
        {
            if ( orderLine.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION ) {
                //non termination
                isAmendment = checkAmendmentType( orderLine );
            } else {
                //termination
                strProjName = '';
            }
        }
        if ( isAmendment == true ) {
            strProjName = orderLine.NSP_Project_Name_Amendment__c;
        }
        if ( ( orderLine != null )
            && ( orderLine.Order.NSP_Transaction_Type__c == NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
            )
        {
            strProjName = '';
        }
        return  strProjName;
    }

    //method for checking Amendment type
    private static Boolean checkAmendmentType( OrderItem orderLine ) {
        String action = orderLine.NSP_QL_ActionType__c.replace('Amend/','');
        String requiredByProductCode = getReqProductCode( orderLine );
        String transactionType = null;
        Boolean isAmendment = false;
        if ( String.isBlank( orderLine.NSP_ApplicableProduct_AmendUpsell__c )
            && String.isBlank( orderLine.NSP_ApplicableProduct_AmendDowngrade__c )
            && String.isBlank( orderLine.NSP_ApplicableProductAmendNew__c )
            )
        {
            //neither upsell/downgrade/addProduct
            if ( String.isNotBlank( orderLine.NSP_Transaction_for_Project__c ) ) {
                transactionType = orderLine.NSP_Transaction_for_Project__c.replace(';',' ');
            }
            if ( String.isNotBlank( orderLine.NSP_QL_ActionType__c ) ) {
                action = orderLine.NSP_QL_ActionType__c.replace('Amend/','');
                if ( ( transactionType != null )
                    && transactionType.contains( action )
                    )
                {
                    //transaction type contains QL action type
                    isAmendment = true;
                }
            }
        } else {
            //either upsell/downgrade/addProduct
            isAmendment = processAmendType( orderLine , action , requiredByProductCode );
        }
        return isAmendment;
    }

    //method that fetches product code from req by product
    private static String getReqProductCode( Orderitem orderLine ) {
        String prodCode = null;
        if ( ( orderLine.SBQQ__RequiredBy__c != null )
            && ( orderLine.SBQQ__RequiredBy__r.Product2 != null )
            && String.isNotBlank( orderLine.SBQQ__RequiredBy__r.Product2.ProductCode )
           )
        {
            prodCode = orderLine.SBQQ__RequiredBy__r.Product2.ProductCode;
        }
        return prodCode;
    }

    //helper method for checkAmendmentType
    private static boolean processAmendType( OrderItem orderLine , String action , String requiredByProductCode ) {
        Boolean isAmendment = False;
        switch on action {
            when 'Add Product' {
                if ( orderLine.NSP_ApplicableProductAmendNew__c.replace(';',' ').contains(requiredByProductCode) ) {
                    isAmendment = true;
                }
            }
            when 'Downgrade' {
                if ( orderLine.NSP_ApplicableProduct_AmendDowngrade__c.replace(';',' ').contains(requiredByProductCode) ) {
                    isAmendment = true;
                }
            }
            when 'Upsell' {
                if ( orderLine.NSP_ApplicableProduct_AmendUpsell__c.replace(';',' ').contains(requiredByProductCode) ) {
                    isAmendment = true;
                }
            }
            when else {
                //do nothing
            }
        }
        return isAmendment;
    }

    //method that creates map from metadata
    private static Map<String,String> getProjectMapping(){
        Map<String,String> projectIdMap = new Map<String,String>();
        List<NSP_ProjectTemplateMapping__mdt> keyWithTemplateId = NSP_ProjectTemplateMapping__mdt.getAll().values();
        for ( NSP_ProjectTemplateMapping__mdt projectMdt: keyWithTemplateId ) {
            projectIdMap.put(
                projectMdt.Key__c+projectMdt.Template_Name__c ,
                projectMdt.Template_ID__c
            );
        }
        return projectIdMap;
    }

    //new method introduced for matching product logic
    public static void processMatchingOPs( List<OrderItem> opWithMatchingProducts ) {
        if ( ( opWithMatchingProducts != null )
            && !opWithMatchingProducts.isEmpty()
            )
        {
            Set<Id> orderSet = new Set<Id>();
            //extract orders
            for ( OrderItem item : opWithMatchingProducts ) {
                orderSet.add( item.OrderId );
            }
            //create Map of prodCode_OrderId and OrderItem
            Map<String,OrderItem> allOrderProductsMap = new Map<String,OrderItem>();
            for ( OrderItem item : [
                        SELECT Id , SBQQ__QuoteLine__r.SBQQ__ProductCode__c , NSP_Project__c , OrderId
                        FROM OrderItem
                        WHERE (
                            ( OrderId IN :orderSet )
                            AND ( SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c > 0 )
                        )
                    ]
                )
            {
                if ( ( item.SBQQ__QuoteLine__r.SBQQ__ProductCode__c != null )
                    && String.isNotBlank( item.SBQQ__QuoteLine__r.SBQQ__ProductCode__c )
                    && ( item.OrderId != null )
                    )
                {
                    String key = item.SBQQ__QuoteLine__r.SBQQ__ProductCode__c + '_' + item.OrderId;
                    allOrderProductsMap.put(key, item);
                }
            }
            findMatchingOP( opWithMatchingProducts , allOrderProductsMap );
            List<Database.SaveResult> results = Database.update( opWithMatchingProducts , false );
            NSP_ErrorLogHandler.logResults(
                CreateSeparateProjectOrderItem.class.getName() ,
                'processMatchingOPs' ,
                results
            );
        }
    }

    //method that finds proj on matching OPs
    private static void findMatchingOP( List<OrderItem> opWithMatchingProducts , Map<String,OrderItem> allOrderProductsMap ) {
        //find project from matching product
        for ( OrderItem item :opWithMatchingProducts ) {
            Boolean findMatch = false;
            if ( item.SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c > 0 ) {
                List<String> matchingProducts = new List<String>();
                //matching product = comma separated product codes
                if ( ( item.Matching_Product_Code__c != null )
                    && !String.isBlank( item.Matching_Product_Code__c )
                    )
                {
                    matchingProducts = item.Matching_Product_Code__c.split(',');
                }
                findMatch = iterateProducts(
                    matchingProducts ,
                    findMatch ,
                    item ,
                    allOrderProductsMap
                );
            }
            if ( !findMatch ) {
                getProjectFromOrder( item , allOrderProductsMap );
            }
        }
    }

    private static Boolean iterateProducts( List<String> matchingProducts , Boolean findMatch , OrderItem item , Map<String,OrderItem> allOrderProductsMap ) {
        for ( String prodCode : matchingProducts ) {
            if ( !findMatch ) {
                findMatch = populateProject(
                    prodCode.trim() ,
                    item ,
                    allOrderProductsMap
                );
            }
        }
        return findMatch;
    }

    //method to populate project on order item
    private static Boolean populateProject( String prodCode , OrderItem item , Map<String,OrderItem> allOrderProductsMap ) {
        Boolean matchFound = false;
        String findKey = prodCode + '_' + item.OrderId;
        if ( allOrderProductsMap.containsKey(findKey) ) {
            matchfound = true;
            //matching OP found
            if ( allOrderProductsMap.get(findKey).NSP_Project__c != null ) {
                //matching OP has project
                Id reqProject = allOrderProductsMap.get(findKey).NSP_Project__c;
                item.NSP_Project__c = reqProject;
                allOrderProductsMap.get(item.Product2.ProductCode + '_' + item.OrderId).NSP_Project__c = reqProject;
            } else {
                //matching OP doesnt have project
                getProjectFromOrder( item , allOrderProductsMap );
            }
        }
        return matchfound;
    }

    //method to fetch project from order
    private static void getProjectFromOrder( OrderItem item , Map<String,OrderItem> allOrderProductsMap) {
        if ( ( item != null )
            && ( allOrderProductsMap != null )
            )
        {
            if ( item.Order.NSP_Project__c != null ) {
                //project found on Order
                id ordProject = item.Order.NSP_Project__c;
                item.NSP_Project__c = ordProject;
                allOrderProductsMap.get(item.Product2.ProductCode + '_' + item.OrderId).NSP_Project__c = ordProject;
            } else {
                //project not found on order
                item.Matching_Product_Code__c = 'Match not found/has no Project';
            }
        }
    }

}
//