({
    doInit : function(cmp, event, helper) {  
        var getRecId = cmp.get("v.recordId");
        sessionStorage.setItem('getParentRecId',getRecId);
    }
})