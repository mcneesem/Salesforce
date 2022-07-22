({
    fetchData: function (cmp, event, helper) {
 		var action = cmp.get("c.initData")
 		var relatedFieldApiName = cmp.get("v.relatedFieldApiName")
        var numberOfRecords = cmp.get("v.numberOfRecords")
        var jsonData = JSON.stringify({fields:cmp.get("v.fields"),
                                       relatedFieldApiName:cmp.get("v.relatedFieldApiName"),
                                       recordId:cmp.get("v.recordId"),
                                       numberOfRecords:numberOfRecords + 1,
                                       sobjectApiName: cmp.get("v.sobjectApiName"),
                                       sortedBy: cmp.get("v.sortedBy"),
                                       sortedDirection: cmp.get("v.sortedDirection")
        });
        action.setParams({jsonData : jsonData});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var jsonData = JSON.parse(response.getReturnValue())
                var records = jsonData.records
                if(records.length > numberOfRecords){
                    records.pop()
                    cmp.set('v.numberOfRecordsForTitle', numberOfRecords + "+")
                }else{
                    cmp.set('v.numberOfRecordsForTitle', Math.min(numberOfRecords,records.length))
                }
                records.forEach(record => {
                  record.LinkName = '/'+record.Id
                  for (const col in record) {
                    if(col == 'NSP_Modified_By__c')
                    	record[col] = record.NSP_Modified_By__r.Name;
                    const curCol = record[col];
                    if (typeof curCol === 'object') {
                      const newVal = curCol.Id ? ('/' + curCol.Id) : null;
                      helper.flattenStructure(helper,record, col + '_', curCol);
                      if (newVal !== null) {
                        record[col+ '_LinkName'] = newVal;
                      }
                    }
                  }
                });    
                //for sorting
                var cloneData = records.slice(0);
        		cloneData.sort((this.sortBy('NSP_Modified_Date__c', cmp.get("v.sortedDirection") === 'asc' ? 1 : -1)));
        
        
                cmp.set('v.records', cloneData)
                cmp.set('v.iconName', jsonData.iconName)
                cmp.set('v.sobjectLabel', jsonData.sobjectLabel)
                cmp.set('v.sobjectLabelPlural', jsonData.sobjectLabelPlural)
                cmp.set('v.parentRelationshipApiName', jsonData.parentRelationshipApiName)
            }else if (state === "ERROR") {
                var errors = response.getError();
            }
        });

        $A.enqueueAction(action);        
    },
    flattenStructure : function (helper,topObject, prefix, toBeFlattened) { 
      for (const prop in toBeFlattened) {
        const curVal = toBeFlattened[prop];
        if (typeof curVal === 'object') {
          helper.flattenStructure(helper, topObject, prefix + prop + '_', curVal);
        } else {
          topObject[prefix + prop] = curVal;
        }
      }
    },    
    
   initColumnsWithActions: function (cmp, event, helper) {
        var customActions = cmp.get('v.customActions')
        if( !customActions.length){
            customActions = [
                { label: 'Edit', name: 'edit' },
                { label: 'Delete', name: 'delete' }
	        ]         
        }
        
        var columns = cmp.get('v.columns')        
        var columnsWithActions = []
        columnsWithActions.push(...columns)
        columnsWithActions.push({ type: 'action', typeAttributes: { rowActions: customActions } })
        //cmp.set('v.columnsWithActions',  columnsWithActions);
         cmp.set('v.columnsWithActions',  [
            {label: 'Field Name', fieldName: 'NSP_Field_Name__c', type: 'text'},
              {label: 'Old Value', fieldName: 'NSP_Old_Value__c', type: 'longText'},
              {label: 'New Value', fieldName: 'NSP_New_Value__c', type: 'longText'},
              {label : 'Effective Date', fieldName: 'NSP_Effective_Date__c', type :'date',
             sortable:false,typeAttributes: {  
                                                                            day: 'numeric',  
                                                                            month: 'short',  
                                                                            year: 'numeric',  
                                                                            hour: '2-digit',  
                                                                            minute: '2-digit',  
                                                                            second: '2-digit',  
                                                                            hour12: true}},
              {label: 'Modified Date', fieldName: 'NSP_Modified_Date__c', type: 'date',
               sortable:false,typeAttributes: {  
                                                                            day: 'numeric',  
                                                                            month: 'short',  
                                                                            year: 'numeric',  
                                                                            hour: '2-digit',  
                                                                            minute: '2-digit',  
                                                                            second: '2-digit',  
                                                                            hour12: true}},
              {label: 'Modified By', fieldName: 'NSP_Modified_By__c', type: 'text'},
             //{ type: 'action', typeAttributes: { rowActions: customActions } }  
            ]);
    },    
    
    removeRecord: function (cmp, row) {
        var modalBody;
        var modalFooter;
        var sobjectLabel = cmp.get('v.sobjectLabel')
        $A.createComponents([
            ["c:deleteRecordContent",{sobjectLabel:sobjectLabel}],
            ["c:deleteRecordFooter",{record: row, sobjectLabel:sobjectLabel}]
        ],
        function(components, status){
            if (status === "SUCCESS") {
                modalBody = components[0];
                modalFooter = components[1];
                cmp.find('overlayLib').showCustomModal({
                   header: "Delete " + sobjectLabel,
                   body: modalBody, 
                   footer: modalFooter,
                   showCloseButton: true
               })
            }
        }
       );
        
    },
    
	editRecord : function (cmp, row) {
        var createRecordEvent = $A.get("e.force:editRecord");
        createRecordEvent.setParams({
            "recordId": row.Id
        });
        createRecordEvent.fire();
	}, 
    
    // Used to sort the 'Age' column
    sortBy: function(field, reverse, primer) {
        var key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) { 
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },
})