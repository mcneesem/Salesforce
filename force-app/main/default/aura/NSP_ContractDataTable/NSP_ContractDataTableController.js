({
    doInit : function(component, event, helper) {
         component.set('v.columns', [
            {label: 'STATUS', fieldName: 'Status', type: 'text'},
            {label: 'CONTRACT NUMBER', fieldName: 'ContractNumber', type: 'text'},
           // {label: 'Platform', fieldName: 'SYNT_LegacyPlatform__c', type: 'text'},
            {label: 'START DATE', fieldName: 'StartDate', type: 'date-local'},
            {label: 'END DATE', fieldName: 'EndDate', type: 'date-local'},]);
        
        var action=component.get('c.getContractRecord');
        action.setParams({
            "recordId": component.get("v.accID")
        });   
        action.setCallback(this, function(response){
             var state = response.getState();
             if (state === "SUCCESS") {  
                 var rows = response.getReturnValue();                
                 component.set("v.data", rows);
                 if(rows.length!=0){
                 	component.set("v.accName", rows[0].Account.Name);
        		}
    			component.set('v.spinner',false);
			}
            else if (state === "ERROR") { 
                component.set('v.spinner',false);
               
            }
		});
        $A.enqueueAction(action); 
    },    
    handleRowSelection: function (component, event,helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.selectedRow', selectedRows);
    }
})