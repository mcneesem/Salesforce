public class NSP_OrderManagement {
    // test w/ NSP_OrderManagementTest (89%)

    @AuraEnabled
    public static List<Contract> getContractRecord(Id recordId){
        try{
            list<contract> lstTermContract = new list<contract>();
            List<Contract> contractList = [
                SELECT
                    Id , Status , ContractNumber , NSP_Product_Type__c ,
                    SBQQ__Evergreen__c , StartDate , EndDate, Account.Name ,
                    SBQQ__Order__c , SBQQ__Order__r.NSP_Transaction_Type__c ,
                    ( SELECT Id , NSP_Status__c FROM SBQQ__Subscriptions__r )
                FROM Contract
                WHERE (
                    ( AccountId = :recordId )
                    AND ( Status = 'Activated' )
                )
                LIMIT 50000
            ]; // Added Limit condition as part of code fix
            for (Contract cnt:contractList) {
                Boolean isTerminated = false;
                if(string.isNotBlank(cnt.SBQQ__Order__c)
                    && (cnt.SBQQ__Order__r.NSP_Transaction_Type__c == 'Termination')
                    )
                {
                    isTerminated = true;
                } else if (cnt.SBQQ__Subscriptions__r != null) {
                    isTerminated = true;
                    for ( SBQQ__Subscription__c sub : cnt.SBQQ__Subscriptions__r ) {
                        if (sub.NSP_Status__c != 'Terminated') {
                            isTerminated = false;
                            break;
                        }
                    }
                }
                if (isTerminated == false) {
                    lstTermContract.add(cnt);
                }
            }
            return lstTermContract;
        }catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static User getCurrentUserInfo() {
         User result = null;
        try{
            List<User> users = [
                SELECT Id , Name , Profile.Name
                FROM User
                WHERE ( Id = :Userinfo.getUserId() )
            ];
            if ( !users.isEmpty() ) {
                result = users[0];
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
        return result;
    }

    @AuraEnabled
    public static Boolean updateContract(Id contractId, String transactionType){
        Boolean isContractUpdated;
        try {
            //update contract record as per renewals and amendments
            Contract contract= new Contract (Id = contractId);
            contract.NSP_TransactionType__c=transactionType;
            contract.SBQQ__PreserveBundleStructureUponRenewals__c = true;
            contract.Auto_Termination_Email__c = UserInfo.getUserEmail();
            //DML on Contract
            update contract;
            isContractUpdated = true;
        }
        catch (Exception ex) {
            isContractUpdated = false;
            // "Convert" the exception into an AuraHandledException
            throw new AuraHandledException(ex.getMessage());
        }
        return isContractUpdated;
    }

    @AuraEnabled
    public static boolean checkAmendmentConditionsApex(String contractId){
        boolean noError = true;
        OrderManagementSettings__c triggerSwitch =  OrderManagementSettings__c.getInstance(UserInfo.getUserId());
        if(!triggerSwitch.CheckAmendmentConditions__c){
            try{
                if ( String.isNotBlank( contractId ) && ( contractId InstanceOf Id ) ) {
                    //fetch the contract and required fields using the contractId param
                    List<Contract> contracts = [
                        SELECT Id , NSP_Product_Type__c , AccountId
                        FROM Contract
                        WHERE Id = :contractId
                        LIMIT 1
                    ];
                    Contract contract = new Contract();
                    if(contracts != null && !contracts.isEmpty()){
                        contract = contracts[0];
                    }
                    if(contract !=null){
                        //get the required field accountId
                        id accountId = contract.AccountId;
                        //get multi-select picklist of product type and split
                        List<String> productTypeList = new List<String>();
                        if(contract.NSP_Product_Type__c != null){
                            String productType = contract.NSP_Product_Type__c;
                            productTypeList = productType.split(';',-2);
                        }
                        //get orders in draft/reviewed state and backout as false, with same product type and account
                        List<Order> listOfOrders = [
                            SELECT Id , Status , NSP_Back_Out__c , NSP_TerminationDate__c
                            FROM Order
                            WHERE (
                                Contract_Product_Type__c IN :productTypeList
                                AND AccountId = :accountId
                                AND Status IN ( 'Draft' , 'Reviewed' )
                                AND NSP_Back_Out__c = false
                                AND Subscription_Product_Count__c > 0
                            )
                        ];
                        //if no order returned then pass true(go ahead) otherwise false(error)
                        if(!listOfOrders.isEmpty()){
                            noError = False;
                        }
                    }
                }
            } catch ( Exception e ) {
                NSP_OrderManagement.handleException( e , 'checkAmendmentConditionsApex' );
                throw new AuraHandledException( e.getMessage() );
            }
        }
        return noError;
    }

    @AuraEnabled
    public static void runContractAutoTermination( Id contractId , Date terminationDate ) {
        ContractTerminationHandler.runContractTerminationHandler(
            contractId ,
            terminationDate ,
            UserInfo.getUserEmail()
        );
    }

    @AuraEnabled
    public static Boolean hasTerminationPermission() {
        return ContractTerminationHandler.isEnabledAutoTermination;
    }

    @AuraEnabled
    public static Boolean bypassTerminationDateValidation() {
        return CustomPermissionController.checkUserPermission(
            'Bypass_Quote_Termination_Date_Not_Before_Last_Month_End' ,
            UserInfo.getUserId()
        );
    }

    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_OrderManagement.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_OrderManagement.class.getName() ,
            methodName ,
            e
        );
    }

}
//