({
    setGuidanceMessages : function(component, opportunityRecord) {
        var guidanceForSuccessMdtRecords = component.get("v.guidanceForSuccessMdtRecords");
        /*if(opportunityRecord.StageName=='Discovery'){            
            component.set("v.guidanceMessage", guidanceForSuccessMdtRecords[0].Discovery__c);
        } else {
            component.set("v.guidanceMessage", "");
        }*/
        if(opportunityRecord != null){
            var nonTecnologyProducts = $A.get("$Label.c.NSP_Non_Technology_Primary_Products");
            var nonTecnologyProductsList = nonTecnologyProducts.split(",");
            
            var isNonTechnologyProduct = nonTecnologyProductsList.includes(opportunityRecord.NSP_PrimaryProduct__c);
            var isWXMidmarket = false;
            for(var i=0; i<guidanceForSuccessMdtRecords.length; i++) {
                
                var isSameProduct = (guidanceForSuccessMdtRecords[i].NSP_PrimaryProduct__c == opportunityRecord.NSP_PrimaryProduct__c 
                                     ||(!isNonTechnologyProduct && guidanceForSuccessMdtRecords[i].NSP_PrimaryProduct__c == "Technology") ) ? true : false;
                var isAtSameStage = guidanceForSuccessMdtRecords[i].NSP_StageName__c==opportunityRecord.StageName;
                var isSameSegment = opportunityRecord.NSP_Account_Segment__c == guidanceForSuccessMdtRecords[i].NSP_Account_Segment__c;
                
                if(opportunityRecord.NSP_PrimaryProduct__c != null 
                   && isAtSameStage && isSameProduct){
                    //alert('same prod');
                    if(opportunityRecord.NSP_PrimaryProduct__c!='WX'){    
                        if(isSameProduct || (!isNonTechnologyProduct && guidanceForSuccessMdtRecords[i].NSP_PrimaryProduct__c == "Technology")){
                            component.set("v.guidanceMessage", guidanceForSuccessMdtRecords[i].NSP_Message__c);
                            break;
                        }
                    }else if(opportunityRecord.NSP_PrimaryProduct__c=='WX'){
                        if(opportunityRecord.NSP_Number_of_Employees__c >=150 &&isSameSegment){
                            component.set("v.guidanceMessage", guidanceForSuccessMdtRecords[i].NSP_Message__c);
                            isWXMidmarket = true;
                            break;
                        }else if(opportunityRecord.NSP_Number_of_Employees__c <150 && !isWXMidmarket
                                 &&guidanceForSuccessMdtRecords[i].NSP_Account_Segment__c!=''){
                            component.set("v.guidanceMessage", guidanceForSuccessMdtRecords[i].NSP_Message__c);
                        }
                    }
                    
                }
                
                /*if(opportunityRecord.NSP_PrimaryProduct__c != null 
               && guidanceForSuccessMdtRecords[i].NSP_StageName__c==opportunityRecord.StageName
               && guidanceForSuccessMdtRecords[i].NSP_PrimaryProduct__c == opportunityRecord.NSP_PrimaryProduct__c
               && opportunityRecord.NSP_PrimaryProduct__c=='WX' && opportunityRecord.NSP_Number_of_Employees__c>=150
               && opportunityRecord.NSP_Account_Segment__c == guidanceForSuccessMdtRecords[i].NSP_Account_Segment__c){
                component.set("v.guidanceMessage", guidanceForSuccessMdtRecords[i].NSP_Message__c);
            }else if(opportunityRecord.NSP_PrimaryProduct__c != null 
               && guidanceForSuccessMdtRecords[i].NSP_StageName__c==opportunityRecord.StageName
               && (guidanceForSuccessMdtRecords[i].NSP_PrimaryProduct__c == opportunityRecord.NSP_PrimaryProduct__c 
                   || (!isNonTechnologyProduct && guidanceForSuccessMdtRecords[i].NSP_PrimaryProduct__c == "Technology"))){
                component.set("v.guidanceMessage", guidanceForSuccessMdtRecords[i].NSP_Message__c);
                alert("coresales, "+guidanceForSuccessMdtRecords[i].NSP_Message__c);
            } */
            }//end of for loop   
        }        
    },
 
 //557355 - get opportunity details and then select the appropriate guidance message for the opportunity
 getOpportunityDetails : function(component, opportunityRecordId) {
    var action = component.get("c.getOpportunityDetails");
     	action.setParams({recordId : opportunityRecordId});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var opportunityDetails = response.getReturnValue();                
                component.set("v.opportunityRecord", opportunityDetails);
            	this.setGuidanceMessages(component, component.get("v.opportunityRecord")); 
            }
            
        });
      $A.enqueueAction(action);
 }
})

//[{"MasterLabel":"AnalysisRetirement","Message__c":"1. Plan review, product options, design elements, testing etc.\r\n\r\n
//2. Generate price quote\r\n\r\n3. Send all signature-ready contracts","Id":"m0K0v0000008ZshEAE"},
//{"MasterLabel":"ClosingRetirement","Message__c":"All required documents received","Id":"m0K0v0000008ZsrEAE"},
//{"MasterLabel":"DiscoveryRetirement","Message__c":"1. BPA Debrief and Discovery call with prospect\r\n2. Qualify the prospect with CGQ or Sales Checklist\r\n3. Collect documents for Plan Review","Id":"m0K0v0000008ZscEAE"},
//{"MasterLabel":"ProposalRetirement","Message__c":"1. Finalize plan design with prospect\r\n\r\n2. Walk through contracts and check for accuracy","Id":"m0K0v0000008ZsmEAE"}]