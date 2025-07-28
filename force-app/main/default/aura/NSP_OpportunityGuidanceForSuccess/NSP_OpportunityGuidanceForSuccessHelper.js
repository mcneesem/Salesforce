({
    setGuidanceMessages: function (component, opportunityRecord) {

        component.set("v.guidanceMessage", "");
        if (opportunityRecord != null && opportunityRecord.StageName != null && opportunityRecord.NSP_PrimaryProduct__c != null) {

            let product = opportunityRecord.NSP_PrimaryProduct__c;
            let segment = product == "WX" && opportunityRecord.NSP_Account_Segment__c &&
                (opportunityRecord.NSP_Account_Segment__c == "MidMarket" || opportunityRecord.NSP_Account_Segment__c == "Enterprise") ? "MidMarket" : "";

            let action = component.get("c.getMessage");
            action.setParams({ stageName: opportunityRecord.StageName, productId: product, segmentId: segment });
            action.setCallback(this, function (response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.guidanceMessage", response.getReturnValue());
                }

            });
            $A.enqueueAction(action);
        }
    }
})