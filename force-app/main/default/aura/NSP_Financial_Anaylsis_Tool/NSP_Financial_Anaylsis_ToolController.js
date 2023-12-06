({
    financialAnaylsisTool : function(component, event, helper) {
        var eventParams=event.getParams();
        if(eventParams.changeType==='LOADED'){
            var action= component.get('c.navigateToFinancialAnaylsisTool');
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") { 
                    var AuthUserMap=response.getReturnValue();
                    var FTAUrl=$A.get("$Label.c.NSP_FTA_Base_URL")+$A.get("$Label.c.NSP_FTA_sessionId");
                    FTAUrl +=AuthUserMap.auth;
                    FTAUrl+=$A.get("$Label.c.NSP_FTA_userFullName");
                    FTAUrl+=AuthUserMap.UserName;
                    FTAUrl+=$A.get("$Label.c.NSP_FTA_externalId")+component.get("v.opportunityRecord.Account.Id");
                    FTAUrl+=$A.get("$Label.c.NSP_FTA_bidNumber");
                    var bidNumber=component.get("v.opportunityRecord.NSP_BidNumber__c");
                    var bidVersion=component.get("v.opportunityRecord.NSP_BidVersion__c");
                    if(bidNumber!=null){
                      FTAUrl+=bidNumber;
                    }
                    FTAUrl+=$A.get("$Label.c.NSP_FTA_bidVersion");
                     if(bidVersion!=null){
                      FTAUrl+=bidVersion;
                    }
                    FTAUrl+=$A.get("$Label.c.NSP_FTA_OppId")+component.get('v.recordId');
                    FTAUrl+=$A.get("$Label.c.NSP_FTA_userId")+AuthUserMap.UserId;
                    window.open(FTAUrl.replace(new RegExp(' ','g'),'+'));
                    $A.get("e.force:closeQuickAction").fire();
                }
            });
            $A.enqueueAction(action);
        }  
        
    }
})